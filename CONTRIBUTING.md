# Contributing

## Layout

Each skill lives at `plugins/<plugin>/skills/<skill-name>/` with a `SKILL.md` that follows the [Agent Skills specification](https://agentskills.io/specification). Every plugin has a `.claude-plugin/plugin.json` and an entry in `.claude-plugin/marketplace.json`.

Every `SKILL.md` frontmatter needs:

- a `name` that matches the folder;
- a `description` of at most 1024 characters that says when to use the skill;
- `license: MIT`;
- `metadata.version`.

Add `compatibility` when a skill needs particular tools.

## Local resources

Never commit material someone else owns, such as rulebook text or tables, quick-reference sheets, scenarios, articles, map art, or fonts. When a skill can use such material, declare it in `local-resources.json` next to `SKILL.md`:

```json
{
  "skill": "<skill-name>",
  "resources": [
    {
      "id": "rules-quick-reference",
      "purpose": "What the skill uses it for.",
      "required": false,
      "whenMissing": "What the skill does without it.",
      "howToObtain": "Where a user gets their own copy.",
      "expectedFiles": ["*.pdf", "*.md"],
      "license": "Why it is not shipped."
    }
  ]
}
```

At run time, the skill looks for each resource in `$AGENT_SKILLS_LOCAL/<skill-name>/<id>/` first, then in `~/.agent-skills/local/<skill-name>/<id>/`. The `SKILL.md` needs a `## Local resources` section that tells the agent to check those folders and report what is missing.

- Without a **required** resource, the skill stops and tells the user how to obtain it.
- Without an **optional** resource, the skill continues and tells the user what its `whenMissing` says will change.

## Checks

Run these before opening a pull request:

```text
python tools/validate_repo.py
python -m unittest discover -s plugins/agent-workflow/skills/codex-plan-files/scripts
python -m unittest discover -s plugins/wargame-design/skills/wargame-scenario-map-making/assets/v32 -p test_presentation.py
pwsh ./scripts/Build-SkillZips.ps1
claude plugin validate .
```

The Fire and Fury skills list their own test commands in each skill's `README.md`. Their tests use invented generator tables, so they run without the rulebook.

`validate_repo.py` rejects:

- PDFs, fonts, archives and office documents;
- files over 2 MB;
- paths longer than 150 characters, which can break clones on Windows;
- broken relative links;
- personal paths;
- secret files such as `.env`;
- frontmatter that is not valid YAML, such as an unquoted value containing `: `. Install PyYAML for the full check.
