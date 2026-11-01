"""Tests for codex_billing_guard_hook.py, fed the PreToolUse JSON Claude Code sends."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

HOOK = Path(__file__).resolve().parent.parent / "codex_billing_guard_hook.py"


def run_hook(event: dict) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(HOOK)], input=json.dumps(event),
                          capture_output=True, text=True, timeout=30)


def shell(command: str, tool: str = "PowerShell") -> dict:
    return {"tool_name": tool, "tool_input": {"command": command}}


BLOCKED_COMMANDS = [
    "codex exec -m gpt-6-luna 'hello'",
    "$null | codex exec -s read-only 'hello' *> out.log",
    "codex e 'hello'",
    "codex review --base main",
    "codex",
    "cd repo && codex exec hello",
    "& 'C:\\npm\\node_modules\\@openai\\codex\\bin\\codex.exe' exec hello",
    "C:/tools/codex.exe exec hello",
    "& 'C:\\Program Files\\Codex\\codex.exe' exec hello",
    "& \"C:\\Program Files\\Codex\\codex.exe\" exec hello",
    "'codex' exec hello",
    '"$(codex exec hi)/codex" --version',
    '& "$(codex exec hi)\\codex.exe" login status',
    "echo `codex exec hi`",
    "x=$(codex exec hi)",
    "(codex)",
    "if(codex exec hi) { }",
    "while(codex exec hi) { }",
    "Write-Output(codex exec hi)",
    "$(codex)",
    "echo hi; (codex exec hi)",
    "cmd /c codex exec hello",
    "Start-Process codex -ArgumentList 'exec','hello'",
    "npx @openai/codex exec hello",
    "bash -c 'codex exec hello'",
    "env FOO=1 codex exec hello",
    "codex app-server",
    "codex exec 'summarize -h output'",
    "codex exec --help 'then run this'",
    "codex exec -m x --help",
    "$env:CODEX_API_KEY = 'sk-123'",
    "CODEX_API_KEY=sk-123 python run.py",
    "export OPENAI_API_KEY=sk-123",
    "setx OPENAI_API_KEY sk-123",
    "[Environment]::SetEnvironmentVariable('CODEX_API_KEY', 'sk-1', 'User')",
    "Set-Item Env:CODEX_ACCESS_TOKEN tok",
    "printenv OPENAI_API_KEY | codex login --with-api-key",
    "python codex_chatgpt.py exec -c forced_login_method=api hello",
    "python codex_chatgpt.py exec --config 'forced_login_method=\"api\"' hello",
    "FOO=1 CODEX_API_KEY=sk-123 python run.py",
    "set CODEX_API_KEY=sk-123",
    "Add-Content ~/.codex/config.toml 'forced_login_method = \"api\"'",
    "Remove-Item C:\\ProgramData\\OpenAI\\Codex\\requirements.toml",
    "Set-Content -Path \"$env:ProgramData\\OpenAI\\Codex\\requirements.toml\" -Value x",
    "icacls C:\\ProgramData\\OpenAI\\Codex /grant Users:F",
    "echo '{}' > ~/.codex/auth.json",
    "Set-Content C:/ProgramData/OpenAI/Codex/requirements.toml 'allowed_login_methods = [\"api\"]'",
]

ALLOWED_COMMANDS = [
    "codex login status",
    "codex --version",
    "codex exec --help",
    "codex exec review -h",
    "codex --help",
    "python skills/claude/claude-subagent-orchestration/scripts/codex_chatgpt.py --check",
    "$null | python C:\\s\\codex_chatgpt.py exec -m gpt-6-luna -c agents.max_depth=0 -s read-only 'hello' *> out.log",
    "(Get-Content (Join-Path $HOME '.codex/models_cache.json') -Raw | ConvertFrom-Json).models.slug",
    "Get-CimInstance Win32_Process -Filter \"Name like 'codex%'\" | Where-Object CommandLine -like '*exec*'",
    "git log --oneline -5 -- skills/codex",
    "Get-Content C:\\ProgramData\\OpenAI\\Codex\\requirements.toml",
    "Remove-Item Env:CODEX_API_KEY",
    "[Environment]::SetEnvironmentVariable('CODEX_API_KEY', $null, 'User')",
    "[Environment]::SetEnvironmentVariable('OPENAI_API_KEY',$null,'User')",
    "grep -rn CODEX_API_KEY skills/",
    "rg -n 'CODEX_API_KEY=' scripts/",
    "grep -rn 'forced_login_method=api' scripts/",
    "git log -S 'OPENAI_API_KEY=' --oneline",
    "pwsh -File scripts/codex/Set-CodexChatGptOnly.ps1 -Check",
    "ls ~/.codex",
    "git commit -q -m 'feat(codex): pin the sign-in'",
    "git commit -q -m 'fix(codex)!: drop the setting file'",
    "python skills/claude/claude-subagent-orchestration/scripts/codex_guard.py --status",
]


@pytest.mark.parametrize("command", BLOCKED_COMMANDS)
def test_blocks(command):
    result = run_hook(shell(command))
    assert result.returncode == 2, command
    assert "Codex billing guard" in result.stderr


@pytest.mark.parametrize("command", ALLOWED_COMMANDS)
def test_allows(command):
    result = run_hook(shell(command))
    assert result.returncode == 0, (command, result.stderr)


def test_bash_tool_is_checked_too():
    assert run_hook(shell("codex exec hello", tool="Bash")).returncode == 2


@pytest.mark.parametrize("event", [
    {"tool_name": "Write", "tool_input": {"file_path": "C:\\ProgramData\\OpenAI\\Codex\\requirements.toml", "content": "x"}},
    {"tool_name": "Edit", "tool_input": {"file_path": "/etc/codex/requirements.toml",
                                         "old_string": "chatgpt", "new_string": "api"}},
    {"tool_name": "Edit", "tool_input": {"file_path": "C:\\Users\\me\\.codex\\auth.json", "old_string": "a", "new_string": "b"}},
    {"tool_name": "Edit", "tool_input": {"file_path": "C:\\Users\\me\\.codex\\config.toml", "old_string": "a",
                                         "new_string": 'forced_login_method = "api"'}},
    {"tool_name": "MultiEdit", "tool_input": {"file_path": "x.toml", "edits": [{"new_string": 'forced_login_method = "api"'}]}},
])
def test_blocks_file_edits(event):
    assert run_hook(event).returncode == 2


def test_allows_ordinary_edits_and_other_tools():
    assert run_hook({"tool_name": "Write", "tool_input": {"file_path": "notes.md", "content": "codex exec"}}).returncode == 0
    example = {"file_path": "tests/test_guard.py", "content": '["-c", "forced_login_method=api"]'}
    assert run_hook({"tool_name": "Write", "tool_input": example}).returncode == 0
    assert run_hook({"tool_name": "Read", "tool_input": {"file_path": "C:\\Users\\me\\.codex\\auth.json"}}).returncode == 0


def test_bad_input_blocks():
    result = subprocess.run([sys.executable, str(HOOK)], input="not json", capture_output=True, text=True, timeout=30)
    assert result.returncode == 2
