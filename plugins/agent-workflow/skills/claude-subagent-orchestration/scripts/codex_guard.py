#!/usr/bin/env python3
r"""Run `codex exec` billed only the way an administrator chose.

Usage:
  python codex_guard.py --status
  python codex_guard.py --check
  python codex_guard.py exec <codex exec arguments>

Codex's machine requirements file is the only switch:
  Windows        %ProgramData%\OpenAI\Codex\requirements.toml
  Linux, macOS   /etc/codex/requirements.toml

  allowed_login_methods = ["api"]   ->  the OpenAI API, per token
  anything else, or no file         ->  the ChatGPT plan (default)

"api" counts only when the file and its folders are owned by an administrator
account and no other account can write them. Before every run the guard:
1. removes API credentials from the environment Codex gets (in "api" mode it
   keeps CODEX_API_KEY, if the user set it),
2. pins the sign-in method and the openai provider with -c overrides,
3. refuses arguments that could pick another provider or sign-in,
4. checks that Codex will use the chosen sign-in,
5. prints one line saying who pays.

Exit code 3 means the guard refused; any other code is Codex's own.
"""
from __future__ import annotations

import glob
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

REFUSED = 3
DEFAULT_MODE = "chatgpt"
SCRIPTS = Path(__file__).resolve().parent
CHATGPT_STATUS = "Logged in using ChatGPT"
API_STATUS_PREFIX = "Logged in using an API key"

# Step 1 must happen before step 2. If CODEX_API_KEY is set when Codex sees
# forced_login_method=chatgpt, Codex deletes every stored credential,
# including the ChatGPT sign-in, and exits. In "api" mode the guard pins
# forced_login_method=api only when the API key is the credential Codex loads
# first, so a stored ChatGPT sign-in is never deleted either.
SCRUB_NAMES = {
    "CODEX_API_KEY",          # codex exec prefers it over any other sign-in
    "CODEX_ACCESS_TOKEN",
    "CODEX_REFRESH_TOKEN_URL_OVERRIDE",
    "CODEX_REVOKE_TOKEN_URL_OVERRIDE",
    "CODEX_APP_SERVER_LOGIN_CLIENT_ID",
}
# OPENAI_ covers OPENAI_API_KEY, OPENAI_BASE_URL, and the workload-identity
# variables, which skip Codex's own login restriction check.
SCRUB_PREFIXES = ("OPENAI_", "AZURE_OPENAI_")

# Bare values: Codex reads a value that is not valid TOML as a literal string,
# and an argument without quotes passes unchanged through a codex.cmd shim.
PINNED_ARGS = {
    "chatgpt": ["-c", "forced_login_method=chatgpt", "-c", "model_provider=openai"],
    "api": ["-c", "forced_login_method=api", "-c", "model_provider=openai"],
}

# --yolo is a hidden alias of --dangerously-bypass-approvals-and-sandbox.
REFUSED_FLAGS = {"--oss", "--local-provider", "-p", "--profile",
                 "--dangerously-bypass-approvals-and-sandbox", "--yolo"}
REFUSED_CONFIG_KEYS = {"model_provider", "model_providers", "forced_login_method",
                       "forced_chatgpt_workspace_id", "openai_base_url", "chatgpt_base_url",
                       "cli_auth_credentials_store", "profile", "profiles"}

_CMD_UNSAFE = set('&|<>^%!"\r\n')


class Refused(Exception):
    pass


def windows_folders() -> tuple[str, str]:
    """Return (ProgramData, System32) from Windows itself, never from environment variables.

    A process can set ProgramData or SystemRoot to a folder it controls, which
    would move the lock, or the PowerShell that checks it, somewhere it can write.
    """
    import ctypes

    program_data, system32 = r"C:\ProgramData", r"C:\Windows\System32"
    buffer = ctypes.create_unicode_buffer(260)
    if ctypes.windll.shell32.SHGetFolderPathW(None, 0x23, None, 0, buffer) == 0 and buffer.value:  # CSIDL_COMMON_APPDATA
        program_data = buffer.value
    buffer = ctypes.create_unicode_buffer(260)
    if ctypes.windll.kernel32.GetSystemDirectoryW(buffer, 260) and buffer.value:
        system32 = buffer.value
    return program_data, system32


def set_env(env: dict[str, str], name: str, value: str) -> None:
    """Set name in env, removing every other spelling first. Windows names ignore case."""
    for key in [key for key in env if key.upper() == name.upper()]:
        del env[key]
    env[name.upper()] = value


def lock_path() -> Path:
    if os.name == "nt":
        return Path(windows_folders()[0]) / "OpenAI" / "Codex" / "requirements.toml"
    return Path("/etc/codex/requirements.toml")


def read_lock(path: Path | None = None) -> list[str] | None:
    """Return the machine lock's allowed_login_methods, or None when there is no lock."""
    path = lock_path() if path is None else path
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    try:
        import tomllib  # Python 3.11 and later
    except ImportError:
        tomllib = None
    if tomllib is not None:
        try:
            value = tomllib.loads(text).get("allowed_login_methods")
        except tomllib.TOMLDecodeError:
            return None
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            return None
        return value
    # Without tomllib, accept only a plain top-level line of quoted strings, and
    # treat anything else, such as a value spread over several lines, as no lock.
    lines = text.splitlines()
    settings = [i for i, line in enumerate(lines) if re.match(r"^\s*allowed_login_methods\s*=", line)]
    if len(settings) != 1 or any(re.match(r"^\s*\[", line) for line in lines[:settings[0]]):
        return None
    match = re.match(r"""^\s*allowed_login_methods\s*=\s*\[((?:\s*(?:"[^"]*"|'[^']*')\s*,?)*)\]\s*(?:#.*)?$""",
                     lines[settings[0]])
    if not match:
        return None
    return [a or b for a, b in re.findall(r""""([^"]*)"|'([^']*)'""", match.group(1))]


def lock_ownership_problem() -> str | None:
    """Return why the lock may not grant API billing, or None when only an administrator can change it."""
    if os.name == "nt":
        # The lock script checks the owner and every write permission of the file
        # and both folders. Users can create folders in %ProgramData%, so a lock
        # without this check could have been planted by any program.
        program_data, system32 = windows_folders()
        powershell = Path(system32) / "WindowsPowerShell" / "v1.0" / "powershell.exe"
        command = [str(powershell), "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                   "-File", str(SCRIPTS / "Set-CodexBillingLock.ps1"), "-Check", "-Mode", "api"]
        # A small, fixed environment: the script finds the lock through
        # $env:ProgramData, and PSModulePath limits module loading to the
        # system folder, so a planted module cannot replace Get-Acl.
        windows = str(Path(system32).parent)
        env = {"SYSTEMROOT": windows, "WINDIR": windows, "PROGRAMDATA": program_data,
               "PATH": system32, "PSMODULEPATH": str(Path(system32) / "WindowsPowerShell" / "v1.0" / "Modules")}
        for name in ("TEMP", "TMP"):
            if os.environ.get(name):
                env[name] = os.environ[name]
        try:
            proc = subprocess.run(command, stdin=subprocess.DEVNULL, capture_output=True, text=True,
                                  encoding="utf-8", errors="replace", timeout=60, env=env)
        except (OSError, subprocess.TimeoutExpired) as exc:
            return f"the ownership check could not run ({exc})"
        if proc.returncode == 0:
            return None
        return (proc.stdout + proc.stderr).strip() or f"the ownership check exited {proc.returncode}"
    path = lock_path()
    try:
        if path.is_symlink():
            return f"{path} is a symbolic link"
        for item in (path, path.parent, path.parent.parent):
            info = item.stat()
            if info.st_uid != 0:
                return f"{item} is not owned by root"
            if info.st_mode & 0o022:
                return f"{item} can be written by accounts other than root"
    except OSError as exc:
        return f"the ownership check could not read {path} ({exc})"
    return None


def billing_mode() -> tuple[str, str]:
    """Return (mode, reason). Only an administrator-owned lock of exactly ["api"] gives "api"."""
    lock = read_lock()
    if lock is None:
        return DEFAULT_MODE, f"no machine lock at {lock_path()}"
    if lock != ["api"]:
        return DEFAULT_MODE, f"the machine lock at {lock_path()} allows {lock}"
    problem = lock_ownership_problem()
    if problem:
        return DEFAULT_MODE, f"the machine lock at {lock_path()} says ['api'], but {problem}, so it is ignored"
    return "api", f"the machine lock at {lock_path()} allows only ['api'] and only an administrator can change it"


def scrubbed_env(mode: str, environ=None) -> tuple[dict[str, str], list[str]]:
    """Return (environment for Codex, names removed)."""
    env = dict(os.environ if environ is None else environ)
    keep = {"CODEX_API_KEY"} if mode == "api" else set()
    removed = sorted(name for name in env
                     if name.upper() not in keep
                     and (name.upper() in SCRUB_NAMES or name.upper().startswith(SCRUB_PREFIXES)))
    for name in removed:
        del env[name]
    # VS Code sets this for its extension host; a Node-based shim would misbehave.
    env.pop("ELECTRON_RUN_AS_NODE", None)
    if os.name == "nt" and environ is None:
        # Codex must read the same machine lock the guard read.
        program_data, system32 = windows_folders()
        set_env(env, "ProgramData", program_data)
        set_env(env, "SystemRoot", str(Path(system32).parent))
    return env, removed


def find_codex() -> str | None:
    """Prefer the native binary in the npm package; codex.cmd re-parses arguments."""
    shim = shutil.which("codex")
    if shim:
        package = Path(shim).resolve().parent / "node_modules" / "@openai" / "codex" / "node_modules" / "@openai"
        for pattern in ("codex-win32-*", "codex-*"):
            for name in ("codex.exe", "codex"):
                native = sorted(glob.glob(str(package / pattern / "vendor" / "*" / "bin" / name)))
                if native:
                    return native[0]
    return shim


def _config_key(value: str) -> str:
    return value.split("=", 1)[0].strip().strip("'\"").split(".", 1)[0]


def check_args(args: list[str]) -> None:
    """Raise Refused for any argument that could change the sign-in or provider."""
    index = 0
    while index < len(args):
        arg = args[index]
        flag = arg.split("=", 1)[0]
        if flag in REFUSED_FLAGS or (arg.startswith("-p") and not arg.startswith("--") and len(arg) > 2):
            raise Refused(f"argument {arg!r} is not allowed")
        config = None
        if arg in ("-c", "--config"):
            if index + 1 >= len(args):
                raise Refused(f"{arg} needs a value")
            config = args[index + 1]
            index += 1
        elif arg.startswith("--config="):
            config = arg.split("=", 1)[1]
        elif arg.startswith("-c") and not arg.startswith("--") and len(arg) > 2:
            config = arg[2:].lstrip("=")
        if config is not None and _config_key(config) in REFUSED_CONFIG_KEYS:
            raise Refused(f"config override {config!r} is not allowed")
        index += 1


def _launch(codex: str) -> list[str]:
    # Tests replace find_codex with a Python stub, which runs under this interpreter.
    return [sys.executable, codex] if codex.lower().endswith(".py") else [codex]


def login_status(codex: str, mode: str, env: dict[str, str]) -> tuple[int | None, str]:
    """Return (exit code, status text) of `codex login status`, or (None, error)."""
    try:
        proc = subprocess.run([*_launch(codex), "login", "status", *PINNED_ARGS[mode]], env=env,
                              stdin=subprocess.DEVNULL, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return None, f"codex login status failed: {exc}"
    return proc.returncode, (proc.stdout + proc.stderr).strip() or "no output"


def billing_line(mode: str, codex: str, env: dict[str, str]) -> str:
    """Return the line that says who pays, or raise Refused when that sign-in is not in use."""
    if mode == "api" and env.get("CODEX_API_KEY", "").strip():
        # Codex loads CODEX_API_KEY before any stored sign-in.
        return f"Billing: OpenAI API, per token, key ending {env['CODEX_API_KEY'].strip()[-4:]}"
    code, status = login_status(codex, mode, env)
    lines = [line.strip() for line in status.splitlines()]
    if mode == "chatgpt":
        if code == 0 and CHATGPT_STATUS in lines:
            return "Billing: ChatGPT plan"
        raise Refused(f"Codex is not signed in with ChatGPT ({status})")
    api_lines = [line for line in lines if line.startswith(API_STATUS_PREFIX)]
    if code == 0 and api_lines:
        return f"Billing: OpenAI API, per token, key ending {api_lines[0][-4:]}"
    raise Refused(f"the machine lock selects API billing, but Codex has no API key sign-in ({status}). "
                  "In your own terminal, pipe the key to `codex login --with-api-key`. The README's key storage "
                  "section shows how to keep it in the system keyring")


ENV_KEY_WARNING = ("Warning: the API key comes from CODEX_API_KEY, so every command Claude runs can read it. "
                   "The README's key storage section shows how to keep it in the system keyring instead")


def key_warning(mode: str, env: dict[str, str]) -> str | None:
    """Return a warning when the API key sits in the environment that Claude's commands inherit."""
    return ENV_KEY_WARNING if mode == "api" and env.get("CODEX_API_KEY", "").strip() else None


def guard(args: list[str]) -> tuple[list[str], dict[str, str], str]:
    """Return the Codex command, its environment, and the billing line, or raise Refused."""
    if not args or args[0] not in ("exec", "--check"):
        raise Refused("only `exec`, `--check`, and `--status` are supported")
    check_args(args[1:])
    mode, _ = billing_mode()
    codex = find_codex()
    if not codex:
        raise Refused("codex executable not found")
    if codex.lower().endswith((".cmd", ".bat")):
        for argument in args[1:]:
            if set(argument) & _CMD_UNSAFE:
                raise Refused(f"argument {argument!r} would be re-parsed by cmd.exe for {codex}")
    env, removed = scrubbed_env(mode)
    if removed:
        print("codex_guard: removed from the Codex environment: " + ", ".join(removed), file=sys.stderr)
    line = billing_line(mode, codex, env)
    warning = key_warning(mode, env)
    if warning:
        print(f"codex_guard: {warning}", file=sys.stderr)
    return [*_launch(codex), "exec", *PINNED_ARGS[mode], *args[1:]], env, line


def status() -> int:
    """Print the billing setup and return 0 when Codex can run, otherwise REFUSED."""
    mode, reason = billing_mode()
    print(f"Billing mode: {mode}, because {reason}")
    codex = find_codex()
    if not codex:
        print("Codex: not found")
        return REFUSED
    env, _ = scrubbed_env(mode)
    try:
        print(billing_line(mode, codex, env))
    except Refused as exc:
        print(f"Codex cannot run: {exc}")
        return REFUSED
    warning = key_warning(mode, env)
    if warning:
        print(warning)
    return 0


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if args == ["--status"]:
        return status()
    try:
        command, env, line = guard(args)
    except Refused as exc:
        print(f"codex_guard: refused: {exc}", file=sys.stderr)
        return REFUSED
    if args[0] == "--check":
        print(line)
        return 0
    print(f"codex_guard: {line}", file=sys.stderr)
    # stdin, stdout, and stderr pass through, so `-` prompts, -o, and redirects work as with codex itself.
    try:
        return subprocess.run(command, env=env).returncode
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
