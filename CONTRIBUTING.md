# Contributing

## Layout

Each skill lives at `plugins/<plugin>/skills/<skill-name>/` with a `SKILL.md` that follows the [Agent Skills specification](https://agentskills.io/specification). Every plugin has a `.claude-plugin/plugin.json` and an entry in `.claude-plugin/marketplace.json`.

Every `SKILL.md` frontmatter needs:

- a string `name` of 1-64 lowercase letters/numbers and single hyphens that matches the folder;
- a `description` of at most 1024 characters that describes the capability and when to use it;
- `license: MIT`;
- `metadata.version`.

Add `compatibility` when a skill needs particular tools.

## Local resources

Do not commit private material or third-party content without redistribution rights, such as rulebook text or tables, quick-reference sheets, scenarios, articles, map art, or fonts. Compatible permissively licensed skill source may ship after provenance review, with required notices retained in each derived folder and its bundles. When a skill can use such material, declare it in `local-resources.json` next to `SKILL.md`:

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
python -m pip install pyyaml
python tools/validate_repo.py
python -m unittest discover -s tools/tests
python -m unittest discover -s plugins/agent-workflow/skills/codex-plan-files/scripts
python -m unittest discover -s plugins/wargame-design/skills/wargame-scenario-map-making/assets/v32 -p test_presentation.py
pwsh ./scripts/Build-SkillZips.ps1 -Target repo
claude plugin validate .
```

The Fire and Fury skills list their own test commands in each skill's `README.md`. Their tests use invented generator tables, so they run without the rulebook.

`validate_repo.py` rejects:

- PDFs, fonts, archives and office documents, except the exact validated `bundles/career-workbench.zip` generated from its allowlisted public sources;
- files over 2 MB;
- paths longer than 150 characters, which can break clones on Windows;
- broken relative links;
- personal paths and email addresses, plus any patterns passed with `--deny-file`;
- secret files such as `.env`;
- frontmatter that is not valid YAML, such as an unquoted value containing `: `. PyYAML is required; validation cannot pass without its strict parser. Duplicate keys and invalid field types are findings too.

## Metadata targets and behavioral evidence

The default `--target repo` permits documented Claude Code plugin fields such as
`context` and `effort`. Use `--target portable` for six-field upload metadata; it
rejects Code-only extensions rather than stripping them. The release validator
retains this repository's MIT, version and private-resource checks for both
targets. Portable metadata does not prove a skill's dependencies or body work on
every host. Consult the [Claude Code skills reference](https://code.claude.com/docs/en/skills)
for the distinction between plugin and upload formats.

The ZIP builder also accepts `-Target repo|portable`, defaulting to `repo` for
Code source archives. It validates the whole input before creating any archive.
Use `-Target portable` for uploads. The current Fire and Fury packages contain
`effort`, and `claude-subagent-orchestration` uses a reserved upload name. These
packages are incompatible with that target. Adaptation requires a
separate source decision; the builder does not silently remove fields.

Structural validation is separate from trust and behavior. Review package code
and dependencies before execution. Compare edited skills with a preserved old
package on realistic prompts, including activation, near misses and neighboring
skills. Inspect outputs separately from procedural traces, record model and
package identities, and report inconclusive runs. Advisory quality scores do
not approve a release.

## Career Workbench production bundle

Develop and maintain skills and this tooling in Dev Center. Its publisher installs all 23 canonical career skills into the public `job-search` plugin, verifies release/bundle membership, and generates the committed archive before validation. There is no second binary in Dev Center's distribution scaffold.

After an intentional public-source edit, `python tools/build_career_bundle.py` regenerates the archive; `python tools/build_career_bundle.py --check` compares exact bytes. CI runs the check and package tests. The builder uses ZIP_STORED, fixed timestamps/permissions, sorted entries and normalized text. Any exported file change requires archive regeneration; changing an allowlisted blank template also requires reviewing and updating its hash in `plugins/job-search/bundle.json`.

`Build-SkillZips.ps1` preserves existing individual builds for other plugins. Career Workbench requires all 23 sibling folders, so its combined repository-install archive replaces individual career ZIP outputs. It is not a single-skill web upload.
