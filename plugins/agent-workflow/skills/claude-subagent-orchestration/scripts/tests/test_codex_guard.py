"""Tests for codex_guard.py. A local stub stands in for Codex; nothing reaches a network."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import codex_guard  # noqa: E402

STUB = '''
import json, os, sys
state = os.environ["STUB_STATE"]
record = {"argv": sys.argv[1:], "env": {k: v for k, v in os.environ.items()
          if k.startswith(("OPENAI_", "AZURE_OPENAI_", "CODEX_"))}}
with open(state, "a", encoding="utf-8") as f:
    f.write(json.dumps(record) + "\\n")
if sys.argv[1:3] == ["login", "status"]:
    print(os.environ.get("STUB_LOGIN", "Logged in using ChatGPT"), file=sys.stderr)
    sys.exit(int(os.environ.get("STUB_LOGIN_CODE", "0")))
sys.exit(int(os.environ.get("STUB_EXEC_CODE", "0")))
'''

CHATGPT_ARGS = codex_guard.PINNED_ARGS["chatgpt"]
API_ARGS = codex_guard.PINNED_ARGS["api"]


@pytest.fixture
def lock(tmp_path, monkeypatch):
    """A scratch machine lock, absent until written, owned by an administrator unless a test says otherwise."""
    path = tmp_path / "lock" / "requirements.toml"
    monkeypatch.setattr(codex_guard, "lock_path", lambda: path)
    monkeypatch.setattr(codex_guard, "lock_ownership_problem", lambda: None)

    def write(text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    return write


@pytest.fixture
def stub(tmp_path, monkeypatch, lock):
    script = tmp_path / "codex_stub.py"
    script.write_text(STUB, encoding="utf-8")
    state = tmp_path / "calls.jsonl"
    monkeypatch.setattr(codex_guard, "find_codex", lambda: str(script))
    monkeypatch.setenv("STUB_STATE", str(state))
    for name in list(os.environ):
        if name.startswith(("OPENAI_", "AZURE_OPENAI_")) or name in codex_guard.SCRUB_NAMES:
            monkeypatch.delenv(name)

    def calls():
        if not state.exists():
            return []
        return [json.loads(line) for line in state.read_text(encoding="utf-8").splitlines()]
    return calls


# The machine lock is the only switch

API_LOCK = 'allowed_login_methods = ["api"]\n'


@pytest.mark.parametrize("text, mode", [
    (None, "chatgpt"),
    ('allowed_login_methods = ["chatgpt"]\n', "chatgpt"),
    ('allowed_login_methods = ["chatgpt", "api"]\n', "chatgpt"),
    ('allowed_login_methods = ["api", "chatgpt"]\n', "chatgpt"),
    ('allowed_login_methods = ["api"]\n', "api"),
    ('# managed\nallowed_login_methods = ["api"] # per token\n[features]\nx = 1\n', "api"),
    ('allowed_login_methods = ["api"]\nallowed_login_methods = ["chatgpt"]\n', "chatgpt"),
    ('ALLOWED_LOGIN_METHODS = ["api"]\n', "chatgpt"),
    ("allowed_login_methods = [\"api\", 'chatgpt']\n", "chatgpt"),
    ("allowed_login_methods = ['api']\n", "api"),
    ('allowed_login_methods = [\n  "api",\n  "chatgpt",\n]\n', "chatgpt"),
    ('[features]\nallowed_login_methods = ["api"]\n', "chatgpt"),
    ('allowed_login_methods = "api"\n', "chatgpt"),
    ('allowed_login_methods = ["api"\n', "chatgpt"),
    ("", "chatgpt"),
])
def test_only_an_api_only_lock_selects_api(lock, text, mode):
    if text is not None:
        lock(text)
    assert codex_guard.billing_mode()[0] == mode


@pytest.mark.parametrize("text, expected", [
    ('allowed_login_methods = ["api"]\n', ["api"]),
    ("allowed_login_methods = ['api', \"chatgpt\"] # both\n", ["api", "chatgpt"]),
    ('allowed_login_methods = [\n  "api",\n]\n', None),
    ('[features]\nallowed_login_methods = ["api"]\n', None),
    ('allowed_login_methods = ["api"]\nallowed_login_methods = ["api"]\n', None),
])
def test_lock_parser_without_tomllib(lock, monkeypatch, text, expected):
    monkeypatch.setitem(sys.modules, "tomllib", None)
    lock(text)
    assert codex_guard.read_lock() == expected


def test_unreadable_lock_means_chatgpt(lock):
    lock("")
    codex_guard.lock_path().write_bytes(b"\xff\xfe\x00bad")
    assert codex_guard.billing_mode()[0] == "chatgpt"


def test_an_api_lock_that_a_user_could_write_is_ignored(lock, monkeypatch):
    lock(API_LOCK)
    monkeypatch.setattr(codex_guard, "lock_ownership_problem", lambda: "Users can write to the file")
    mode, reason = codex_guard.billing_mode()
    assert mode == "chatgpt" and "Users can write" in reason and "ignored" in reason


def test_the_ownership_check_runs_only_for_an_api_lock(lock, monkeypatch):
    calls = []
    monkeypatch.setattr(codex_guard, "lock_ownership_problem", lambda: calls.append(1))
    lock('allowed_login_methods = ["chatgpt"]\n')
    codex_guard.billing_mode()
    assert calls == []


def test_user_files_and_environment_never_select_api(stub, lock, tmp_path, monkeypatch):
    repo = tmp_path / "repo" / ".agent-skills"
    repo.mkdir(parents=True)
    (repo / "codex-billing.toml").write_text('billing = "api"\n', encoding="utf-8")
    monkeypatch.chdir(tmp_path / "repo")
    for name in ("CODEX_BILLING", "AGENT_SKILLS_CODEX_BILLING"):
        monkeypatch.setenv(name, "api")
    monkeypatch.setenv("CODEX_API_KEY", "sk-fake-test-1234")
    assert codex_guard.billing_mode()[0] == "chatgpt"
    assert codex_guard.main(["exec", "hello"]) == 0
    assert stub()[-1]["argv"][:5] == ["exec", *CHATGPT_ARGS]
    assert "CODEX_API_KEY" not in stub()[-1]["env"]


@pytest.mark.skipif(os.name == "nt", reason="POSIX ownership check")
def test_posix_ownership_check_rejects_a_lock_the_user_owns(tmp_path, monkeypatch):
    path = tmp_path / "etc" / "codex" / "requirements.toml"
    path.parent.mkdir(parents=True)
    path.write_text(API_LOCK, encoding="utf-8")
    monkeypatch.setattr(codex_guard, "lock_path", lambda: path)
    if os.geteuid() != 0:
        assert "not owned by root" in codex_guard.lock_ownership_problem()


@pytest.mark.skipif(os.name != "nt", reason="Windows ownership check")
def test_windows_ownership_check_rejects_a_lock_outside_programdata(tmp_path, monkeypatch):
    """The lock script checks only the real %ProgramData% path, which holds no api lock here."""
    assert codex_guard.lock_ownership_problem() is not None


# chatgpt mode

def test_scrub_removes_api_credentials_and_keeps_codex_home():
    env, removed = codex_guard.scrubbed_env("chatgpt", {
        "CODEX_API_KEY": "k", "OPENAI_API_KEY": "k", "OPENAI_BASE_URL": "u",
        "OPENAI_FEDERATION_RULE_ID": "r", "AZURE_OPENAI_API_KEY": "k", "CODEX_ACCESS_TOKEN": "t",
        "codex_api_key": "k", "CODEX_HOME": "h", "PATH": "p"})
    assert env == {"CODEX_HOME": "h", "PATH": "p"}
    assert "CODEX_API_KEY" in removed and "codex_api_key" in removed


def test_exec_runs_with_pinned_args_and_scrubbed_env(stub, monkeypatch, capsys):
    monkeypatch.setenv("CODEX_API_KEY", "sk-fake")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-fake")
    assert codex_guard.main(["exec", "-m", "gpt-test", "-s", "read-only", "hello"]) == 0
    login, run = stub()
    assert login["argv"] == ["login", "status", *CHATGPT_ARGS]
    assert run["argv"][:5] == ["exec", *CHATGPT_ARGS]
    assert run["argv"][-1] == "hello"
    assert login["env"] == {} and run["env"] == {}
    assert "codex_guard: Billing: ChatGPT plan" in capsys.readouterr().err


def test_pinned_args_go_before_review(stub):
    assert codex_guard.main(["exec", "-s", "read-only", "review", "--base", "main"]) == 0
    run = stub()[-1]
    assert run["argv"] == ["exec", *CHATGPT_ARGS, "-s", "read-only", "review", "--base", "main"]


@pytest.mark.parametrize("status", [
    "Logged in using an API key - sk-proj-***ABCD",
    "Logged in using access token",
    "Logged in using personal access token",
    "Logged in using workload identity",
    "Not logged in",
    "Not logged in to ChatGPT",
])
def test_chatgpt_mode_refuses_any_other_sign_in(stub, monkeypatch, status):
    monkeypatch.setenv("STUB_LOGIN", status)
    assert codex_guard.main(["exec", "hello"]) == codex_guard.REFUSED
    assert [c["argv"][0] for c in stub()] == ["login"]


def test_failed_status_command_is_refused(stub, monkeypatch):
    monkeypatch.setenv("STUB_LOGIN_CODE", "1")
    assert codex_guard.main(["exec", "hello"]) == codex_guard.REFUSED


def test_missing_codex_is_refused(lock, monkeypatch):
    monkeypatch.setattr(codex_guard, "find_codex", lambda: None)
    assert codex_guard.main(["exec", "hello"]) == codex_guard.REFUSED


def test_environment_cannot_redirect_the_executable(monkeypatch, tmp_path):
    for name in ("CODEX_GUARD_EXECUTABLE", "P2E_CODEX"):
        monkeypatch.setenv(name, str(tmp_path / "evil.exe"))
    found = codex_guard.find_codex()
    assert found is None or "evil" not in found


# api mode

def test_api_mode_keeps_only_the_users_codex_api_key():
    env, removed = codex_guard.scrubbed_env("api", {
        "CODEX_API_KEY": "sk-user", "OPENAI_API_KEY": "k", "CODEX_ACCESS_TOKEN": "t",
        "OPENAI_FEDERATION_RULE_ID": "r", "PATH": "p"})
    assert env == {"CODEX_API_KEY": "sk-user", "PATH": "p"}
    assert "OPENAI_API_KEY" in removed and "CODEX_ACCESS_TOKEN" in removed


def test_api_mode_with_env_key_runs_without_a_status_check(stub, lock, monkeypatch, capsys):
    lock(API_LOCK)
    monkeypatch.setenv("CODEX_API_KEY", "sk-fake-test-1234")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-other")
    assert codex_guard.main(["exec", "hello"]) == 0
    calls = stub()
    assert [c["argv"][0] for c in calls] == ["exec"]
    assert calls[0]["argv"][:5] == ["exec", *API_ARGS]
    assert calls[0]["env"] == {"CODEX_API_KEY": "sk-fake-test-1234"}
    err = capsys.readouterr().err
    assert "Billing: OpenAI API, per token, key ending 1234" in err
    assert codex_guard.ENV_KEY_WARNING in err
    assert "sk-fake-test" not in err


def test_status_warns_when_the_api_key_is_in_the_environment(stub, lock, monkeypatch, capsys):
    lock(API_LOCK)
    monkeypatch.setenv("CODEX_API_KEY", "sk-fake-test-1234")
    assert codex_guard.main(["--status"]) == 0
    out = capsys.readouterr().out
    assert "key ending 1234" in out and codex_guard.ENV_KEY_WARNING in out


def test_api_mode_accepts_a_stored_api_key_sign_in(stub, lock, monkeypatch, capsys):
    lock(API_LOCK)
    monkeypatch.setenv("STUB_LOGIN", "Logged in using an API key - sk-proj-***WXYZ")
    assert codex_guard.main(["exec", "hello"]) == 0
    login, run = stub()
    assert login["argv"] == ["login", "status", *API_ARGS]
    assert run["argv"][:5] == ["exec", *API_ARGS]
    err = capsys.readouterr().err
    assert "key ending WXYZ" in err
    assert codex_guard.ENV_KEY_WARNING not in err


@pytest.mark.parametrize("status", ["Logged in using ChatGPT", "Not logged in", "Logged in using access token"])
def test_api_mode_refuses_without_an_api_key(stub, lock, monkeypatch, status):
    """With only a ChatGPT sign-in, Codex never sees forced_login_method=api, so it cannot log anyone out."""
    lock(API_LOCK)
    monkeypatch.setenv("STUB_LOGIN", status)
    assert codex_guard.main(["exec", "hello"]) == codex_guard.REFUSED
    assert [c["argv"][0] for c in stub()] == ["login"]


# Arguments

@pytest.mark.parametrize("args", [
    ["--oss"], ["--local-provider", "ollama"], ["--local-provider=ollama"],
    ["-p", "work"], ["-pwork"], ["--profile", "work"], ["--profile=work"],
    ["--dangerously-bypass-approvals-and-sandbox"], ["--yolo"],
    ["-c", 'model_provider="mine"'], ["-c", "model_providers.mine.env_key=MY_KEY"],
    ["-c", 'forced_login_method="api"'], ["--config", "openai_base_url=http://x"],
    ["--config=chatgpt_base_url=http://x"], ["-ccli_auth_credentials_store=file"],
    ["-c", '"model_provider"="mine"'], ["-c", "profiles.x.model_provider=y"],
])
def test_risky_arguments_are_refused_before_codex_runs(stub, args):
    assert codex_guard.main(["exec", *args, "hello"]) == codex_guard.REFUSED
    assert stub() == []


def test_config_flag_without_value_is_refused(stub):
    assert codex_guard.main(["exec", "-c"]) == codex_guard.REFUSED
    assert stub() == []


def test_cmd_shim_refuses_arguments_cmd_would_reparse(stub, monkeypatch, tmp_path):
    shim = tmp_path / "codex.cmd"
    shim.write_text("@exit /b 0\r\n", encoding="utf-8")
    monkeypatch.setattr(codex_guard, "find_codex", lambda: str(shim))
    assert codex_guard.main(["exec", "a & calc"]) == codex_guard.REFUSED


def test_ordinary_config_overrides_are_allowed(stub):
    args = ["-c", 'model_reasoning_effort="high"', "-c", "agents.max_depth=0", "--disable", "apps"]
    assert codex_guard.main(["exec", *args, "hello"]) == 0


def test_only_exec_check_and_status_are_supported(stub):
    assert codex_guard.main(["login", "--with-api-key"]) == codex_guard.REFUSED
    assert codex_guard.main(["review"]) == codex_guard.REFUSED
    assert codex_guard.main([]) == codex_guard.REFUSED
    assert stub() == []


# --check and --status

def test_check_prints_the_billing_line_without_running_exec(stub, capsys):
    assert codex_guard.main(["--check"]) == 0
    assert [c["argv"][:2] for c in stub()] == [["login", "status"]]
    assert capsys.readouterr().out.strip() == "Billing: ChatGPT plan"


def test_status_reports_mode_reason_and_billing(stub, capsys):
    assert codex_guard.main(["--status"]) == 0
    out = capsys.readouterr().out
    assert "Billing mode: chatgpt, because no machine lock" in out
    assert "Billing: ChatGPT plan" in out


def test_status_explains_why_codex_cannot_run(stub, lock, capsys):
    lock(API_LOCK)
    assert codex_guard.main(["--status"]) == codex_guard.REFUSED
    out = capsys.readouterr().out
    assert "Billing mode: api" in out and "Codex cannot run" in out and "codex login --with-api-key" in out
    assert "keyring" in out and "set CODEX_API_KEY" not in out


def test_codex_exit_code_passes_through(stub, monkeypatch):
    monkeypatch.setenv("STUB_EXEC_CODE", "7")
    assert codex_guard.main(["exec", "hello"]) == 7


@pytest.mark.skipif(os.name != "nt", reason="Windows folders")
def test_windows_paths_ignore_environment_overrides(monkeypatch, tmp_path):
    real_lock, real_folders = codex_guard.lock_path(), codex_guard.windows_folders()
    monkeypatch.setenv("ProgramData", str(tmp_path))
    monkeypatch.setenv("SystemRoot", str(tmp_path))
    assert codex_guard.lock_path() == real_lock
    assert codex_guard.windows_folders() == real_folders
    env, _ = codex_guard.scrubbed_env("chatgpt")
    assert [key for key in env if key.upper() == "PROGRAMDATA"] == ["PROGRAMDATA"]
    assert [key for key in env if key.upper() == "SYSTEMROOT"] == ["SYSTEMROOT"]
    assert env["PROGRAMDATA"] == real_folders[0]
    assert str(tmp_path) not in env["SYSTEMROOT"]


def test_set_env_replaces_every_spelling():
    env = {"ProgramData": "a", "PROGRAMDATA": "b", "programdata": "c", "PATH": "p"}
    codex_guard.set_env(env, "ProgramData", "real")
    assert env == {"PROGRAMDATA": "real", "PATH": "p"}
