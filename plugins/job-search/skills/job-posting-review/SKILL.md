---
name: job-posting-review
description: Use when reviewing or ranking job postings from URLs, PDFs, or pasted text to decide whether to apply, which resume to use, and what salary to request.
license: MIT
metadata:
  version: "1.0.0"
---

# Job Posting Review

Read the [workspace and evidence contract](references/workspace-contract.md) when gathering candidate context. Existing repository routing remains supported; no new workspace map is required. For an explicit setup request, use the separate [setup contract](references/setup-contract.md). Whole-career discovery and requested reusable fact updates belong to the `career-context-builder` skill; do not start that interview or save facts during an ordinary review.

Review one or more job postings and produce one decision table. Use the rules in the reference files exactly, so two runs on the same posting agree. For a deep report on one posting, use the `job-description-analyzer` skill instead.

This skill recommends only. It never creates or edits a resume, submits an application, or writes personal facts into a skill.

## Workflow

1. **Collect postings.** Accept any mix of URLs, PDFs, screenshots, documents, and pasted text. Read them with [posting retrieval](references/posting-retrieval.md).
2. **Gather user context.** Use the current message first, then the records, supporting sources, and resume storage that repository instructions name. Find the user's location, relocation limits, experience, preferences, pay floor and target, resume catalog, and prior applications. Use established repository routing or the optional workspace map; do not create either during a review. Open only those sources. Never browse a folder for more, and never open financial, health, or personal administration files.
3. **Check pasted input.** Follow the pasted-input gate in [posting retrieval](references/posting-retrieval.md).
4. **Validate.** Run every check in [validation checks](references/validation-checks.md).
5. **Audit requirements.** Build and audit a ledger for every role with [requirement audit](references/requirement-audit.md), including low-ranked roles.
6. **Score.** Apply [scoring rules](references/scoring-rules.md) in order: Background Match, market pay, salary, Decision, then resume. When a market pay trigger applies, call the `job-market-pay-research` skill once for the whole batch.
7. **Report.** Use the output format below.

Ask at most one grouped question before analysis, and only about items that could change a Decision, plus any equivalent-experience degree row from the [requirement audit](references/requirement-audit.md#equivalent-experience-degree-rows). When the user can't answer, continue as the validation checks direct.

## Output

Use these columns in this order:

| # | Role | Pay Range | Background Match | Decision | Main reason | Main risk | Suggested Resume | Suggested Requested Salary |
|---|---|---|---|---|---|---|---|---|

- Write one row per role. Sort by Decision in the order the scoring rules give, then by Background Match, highest first.
- Write `Role` as the title and company linked to the actual posting URL when a link exists. Otherwise put the source in parentheses: `Title, Company (PDF)`, `(Pasted)`, `(Screenshot)`, or `(Email)`.
- Write `Pay Range` as the posted range for the user's location. With no posted range, write `Not listed; market $X-$YK (est.)`.
- In `Main reason`, spell out any failed validation check, such as "Limited to Washington, DC residents; you live in Texas."
- In `Main risk`, name every unmet required item, meaning each required row graded Partial, None, or Unverified. With more than three, name the three most serious and add the count, such as "+2 more". Also name any [floor gap](references/scoring-rules.md#floor-gap); it does not count toward the three.
- Use only the Suggested Resume formats in the scoring rules.

After the table, add:

1. **Check before applying.** Give each role except `Skip` and `Don't Apply` these lists, omitting any that are empty: unmet requirements, evidence to confirm, items not to claim, and pay conditions. Give `Skip` roles their pay conditions only. State a grade or a fact. Do not use words like "thin" or "light" in place of a grade.
2. **NEW resumes.** Give one line per NEW resume on why it is worth the effort.
3. **Method.** State what you could not verify and list sources for any market data.

## Stop conditions

- No posting text can be found: ask the user to paste the posting or export a PDF, and use the no-readable-posting row in the scoring rules. Do not score from a title.
- A ledger is missing a posting's tool, credential, domain, number, or condition: finish the ledger before you score.
