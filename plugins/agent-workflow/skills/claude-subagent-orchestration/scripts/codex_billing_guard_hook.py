#!/usr/bin/env python3
"""Claude Code PreToolUse hook: keep Codex billed the way an administrator chose.

Codex's machine requirements file chooses ChatGPT plan or API billing, and
codex_guard.py applies that choice. This hook blocks, with exit code 2 and a
reason on stderr:
- a shell command that starts Codex directly instead of through codex_guard.py,
  except `codex login status`, `codex --version`, and help output,
- a shell command that sets CODEX_API_KEY, OPENAI_API_KEY, or CODEX_ACCESS_TOKEN,
  or signs Codex in with an API key or access token, because only the user does that,
- a shell command, Write, or Edit that changes the machine requirements file,
  forced_login_method, or ~/.codex/auth.json.

This hook catches mistakes. It reads command text, so it does not see a script
that starts Codex or writes a file itself. The machine requirements file written
by Set-CodexBillingLock.ps1 is what Codex itself enforces.
"""
from __future__ import annotations

import json
import re
import sys

WRAPPER = "codex_guard.py"

# A codex executable in command position: at the start, after a separator,
# after the PowerShell call operator, or after a launcher such as cmd /c.
_START = r"(?:^|[;\n|(){}`]|&&|\|\||(?<![\w-])&)\s*(?:&\s*)?"
_LAUNCHER = (r"(?:\b(?:cmd(?:\.exe)?\s+/[ck]|start-process(?:\s+-filepath)?|npx(?:\s+-y)?|"
             r"(?:ba|z)?sh\s+-c|pwsh(?:\.exe)?\s+(?:-\w+\s+)*-c(?:ommand)?|"
             r"powershell(?:\.exe)?\s+(?:-\w+\s+)*-c(?:ommand)?|exec|time|nohup|env(?:\s+\w+=\S*)*)\s+)")
_NAME = r"(?:@openai/)?codex(?:\.exe|\.cmd|\.ps1)?"
# A quoted path may contain spaces, such as 'C:\Program Files\Codex\codex.exe'.
# It may not contain $, a backtick, parentheses, or separators, so a command
# substitution such as "$(codex exec hi)/codex" is not taken for a path.
_PATH_CHAR = r"""[^'"\n$`()|;&]"""
_CODEX = (rf"""(?:'(?:{_PATH_CHAR}*[\\/])?{_NAME}'|"(?:{_PATH_CHAR}*[\\/])?{_NAME}"|['"]?(?:[^\s'"|;&$`()]*[\\/])?{_NAME}['"]?)"""
          # A ")" ends the command unless ":" or "!:" follows, as in the
          # commit scope "feat(codex): ...". "if(codex exec hi)" is still a run.
          r"(?=\s|$|[;|&]|\)(?!!?:))")
# The lookahead makes finditer try every position, so one match cannot hide
# another Codex call that overlaps it.
CODEX_CALL = re.compile(rf"(?=(?:{_START}|{_LAUNCHER})(?:{_LAUNCHER})?{_CODEX}(?P<rest>[^\n;|&]*))", re.IGNORECASE)

ALLOWED_REST = [
    re.compile(r"^\s*login\s+status\b", re.IGNORECASE),
    re.compile(r"^\s*(?:--version|-V)\s*$"),
    # Help only with nothing else: `codex exec 'text -h'` would run the prompt.
    re.compile(r"^\s*(?:[a-z][\w-]*\s+){0,2}(?:--help|-h)\s*$", re.IGNORECASE),
]

SECRET_NAMES = r"(?:CODEX_API_KEY|OPENAI_API_KEY|CODEX_ACCESS_TOKEN)"
SET_SECRET = [
    # Only an assignment: at the start of a command, after export, env, or set,
    # or as $env:NAME. A search such as rg 'CODEX_API_KEY=' stays allowed.
    re.compile(rf"(?:(?:^|[;\n&|(`{{]|\b(?:export|env|set))\s*(?:\w+=\S*\s+)*|\$env:){SECRET_NAMES}\s*=(?!=)",
               re.IGNORECASE),
    re.compile(rf"\bsetx\s+{SECRET_NAMES}\b", re.IGNORECASE),
    re.compile(rf"SetEnvironmentVariable\(\s*['\"]{SECRET_NAMES}['\"]\s*,(?!\s*\$null\b)", re.IGNORECASE),
    re.compile(rf"\b(?:Set-Item|New-Item|Set-Content)\b[^\n;|]*\bEnv:\\?{SECRET_NAMES}\b", re.IGNORECASE),
]
API_LOGIN = re.compile(r"--with-api-key|--with-access-token", re.IGNORECASE)
FORCED_API = re.compile(r"forced_login_method\s*=\s*['\"]?api\b|allowed_login_methods\s*=[^\n]*\bapi\b", re.IGNORECASE)
# In a command, API sign-in counts only as a -c override or a write to a .toml file.
CONFIG_OVERRIDE_API = re.compile(
    r"(?<![\w-])(?:-c|--config)(?:\s+|=)['\"]?(?:forced_login_method\s*=\s*['\"]?api\b|allowed_login_methods\s*=[^\n]*\bapi\b)",
    re.IGNORECASE)
TOML_PATH = re.compile(r"\.toml\b", re.IGNORECASE)

PROTECTED_FILE = re.compile(
    r"(?:programdata|program\s?data)[\\/]+openai[\\/]+codex|[\\/]etc[\\/]codex[\\/]requirements\.toml"
    r"|\.codex[\\/]+auth\.json", re.IGNORECASE)
CONFIG_FILE = re.compile(r"\.toml$|[\\/]\.codex[\\/]", re.IGNORECASE)
WRITE_VERB = re.compile(
    r"\b(?:Set-Content|Add-Content|Out-File|New-Item|Remove-Item|Move-Item|Copy-Item|Rename-Item|Clear-Content"
    r"|Set-Acl|icacls|takeown|cacls|del|erase|rm|mv|cp|tee|sed\s+-i|WriteAllText|WriteAllBytes|Delete)\b|>",
    re.IGNORECASE)


def check_command(command: str) -> str | None:
    """Return a reason to block the command, or None."""
    for match in CODEX_CALL.finditer(command):
        rest = match.group("rest")
        if not any(pattern.search(rest) for pattern in ALLOWED_REST):
            return ("Run Codex through the guard: python <claude-subagent-orchestration skill>/scripts/"
                    f"{WRAPPER} exec <arguments>. It applies the billing mode the machine lock sets.")
    if any(pattern.search(command) for pattern in SET_SECRET):
        return ("Do not set CODEX_API_KEY, OPENAI_API_KEY, or CODEX_ACCESS_TOKEN. Only the user supplies an API "
                "key, in their own terminal, after an administrator locks Codex to API billing.")
    if API_LOGIN.search(command):
        return "Do not sign Codex in. Ask the user to run codex login in their own terminal."
    if CONFIG_OVERRIDE_API.search(command) or (
            FORCED_API.search(command) and WRITE_VERB.search(command) and TOML_PATH.search(command)):
        return "Only an administrator chooses API billing, with the machine lock."
    if PROTECTED_FILE.search(command) and WRITE_VERB.search(command):
        return ("This command would change the Codex sign-in requirements or credentials. "
                "Ask the user to make that change.")
    return None


def check_file_edit(tool_input: dict) -> str | None:
    path = str(tool_input.get("file_path") or tool_input.get("notebook_path") or "")
    if PROTECTED_FILE.search(path):
        return "This file controls how Codex is billed or signed in. Ask the user to change it."
    # Only Codex configuration files can allow API sign-in. Tests and docs
    # that mention forced_login_method=api as an example stay editable.
    if not CONFIG_FILE.search(path):
        return None
    edits = tool_input.get("edits") or []
    text = " ".join([str(tool_input.get(key) or "") for key in ("content", "new_string", "new_source")]
                    + [str(edit.get("new_string") or "") for edit in edits if isinstance(edit, dict)])
    if FORCED_API.search(text):
        return "Only an administrator chooses API billing, with the machine lock."
    return None


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        print("Codex billing guard: could not read the tool call, so it is blocked.", file=sys.stderr)
        return 2
    tool = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}
    if tool in ("Bash", "PowerShell"):
        reason = check_command(str(tool_input.get("command") or ""))
    elif tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        reason = check_file_edit(tool_input)
    else:
        reason = None
    if reason:
        print(f"Codex billing guard: {reason}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
