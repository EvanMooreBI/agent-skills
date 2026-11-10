# Scoring rules

Apply these sections in order. Salary comes before Decision because a Decision move can depend on it.

## Background Match

This score measures background only. Preferences affect the Decision, not this number.

1. Average the credits in the required rows, the preferred rows, and the duty rows. Skip Unverified rows. A list with no scored rows counts as empty.
2. Score 55% required, 15% preferred, and 30% duties. If a list is empty, spread its weight across the others in proportion.
3. A core gap is a required row with 0 credit that names a specific tool, credential, or industry, or a topic in the job title or job summary. Traits are never core gaps. One core gap caps the score at 74%. Two or more cap it at 64%.
4. Round down to a whole percent. Do not credit learning intent or unsupported claims.
5. If the posting text is incomplete, add `(partial posting)` after the score.

## Market pay triggers

Call the `job-market-pay-research` skill once per batch, with every role that needs it, when any of these applies:

- The posting gives no pay range.
- The range spread is over 40%. Spread is (high - low) / low.
- The posted range doesn't cover the user's location.
- The user asks for it.

A posted range sets the salary, even when market data differs or the range doesn't name the user's location. An aggregator's range counts as posted if it quotes the posting. Note any large difference in the method section. Check each cited figure before you use it.

## Suggested Requested Salary

Start with the range for the user's location, then choose a position in it:

| Background Match | Position in range |
|---|---|
| 85% or more | 60% |
| 75-84% | 50% |
| 65-74% | 35% |
| Under 65% | 25% |

Apply these adjustments in order:

1. Core gap: subtract 25 points, with a minimum of 20%.
2. The posting ties the top of the range to something the user lacks: cap at 35%. State the condition in the pay conditions list for every Decision.
3. Range spread over 40%, or stated room for growth: cap at 50%.
4. Round to the nearest $1K, or the nearest $1 for hourly pay. Never exceed the top of the range.
5. If the result is below the user's floor but the range reaches it, use the floor. In the pay conditions list, give the fit-based figure and say the ask was raised to the floor.

Use base salary only. With a single posted figure, use that figure. To compare hourly pay with a floor, a target, or other roles, multiply by 2,080.

With no posted range, use the position table on the Low and High from the research helper, skip adjustments 2 and 3, and add `(market est.)`. With `low` confidence, add `(market est., low confidence)`. With no Low or High, write `Not set: no market data`.

For `Skip` roles, write `$XK if you apply`. For `Don't Apply`, write `N/A`. For a role with no readable posting, write `Not set`.

### Floor gap

A range midpoint is usually the employer's market rate for a fully proficient employee, and new hires usually start at or below it. A floor above the midpoint means the user needs above-market placement. That suggests the employer may not pay the floor, but it does not prove it. A range that spans several levels can have a midpoint that doesn't match the user's level.

- Use the posted range midpoint as the reference. With no posted range, use the market Median from the research helper. With neither, skip this check.
- If the floor is above the midpoint, write in `Main risk`: `Floor $ZK is above the range midpoint $MK; new hires usually start at or below it`. If the research helper also returned a Median for this role and the floor is above it, add `and the market median $NK`.
- If the floor is above the market Median for a role with no posted range, write `Floor $ZK is above the market median $NK`.
- If the floor is at or below the reference, add no floor gap, even when the ask was raised to the floor.
- A floor gap does not change the Decision.

## Decision

Start from the score. This is the score-based Decision:

| Background Match | Score-based Decision |
|---|---|
| 75% or more | `Apply Now` |
| 60-74% | `Apply, Low Effort` |
| 50-59% | `Long Shot` |
| Under 50% | `Skip` |

Then count how many of the scored duties match the user's stated target work. If the target work is unknown, skip the duty count.

- Move up one level when both of these hold: at least half of the duties match, and the Suggested Requested Salary, or the fit-based figure when adjustment 5 raised the ask to the floor, is above the user's target or the highest among roles without a failed check.
- Move down one level when one or none of the duties match, or when a department or label suggests the work may not be funded.
- If both apply, make no move. The ladder stops at `Apply Now` and `Skip`.

Then apply validation. Any failed check makes the final Decision `Don't Apply`. Otherwise, any `Confirm First` check makes it `Confirm First`, and `Main reason` gives the score-based Decision.

Sort order: `Apply Now`, `Confirm First`, `Apply, Low Effort`, `Long Shot`, `Skip`, `Don't Apply`.

## Suggested Resume

1. Build the catalog from resumes that actually exist. Read the full text of the two most likely candidates. Never invent a resume name. If no catalog is available, write `Unknown: no resume catalog`, ask for one, and finish the rest of the review.
2. A resume made for this employer and role is the exact match. Use it as is, unless it claims something the records don't support; then use the light edit format and name the claim. An exact match applies at any Decision except `Skip` and `Don't Apply`.
3. A resume made for a different employer can be a base for NEW. Use it directly only if its text names no employer or role target. Choose the resume with the highest coverage in step 4. Among equal choices, prefer the general resume, then the closest title, then the most recent.
4. Score coverage. Take the five required rows whose exact terms the posting repeats most, skipping degree rows and breaking ties in posting order, and fill any gap with duties. Count an item if it appears in the resume's summary, skills, or first role.
5. Find the fixable count. A missing item is fixable when the records hold Direct evidence that the resume doesn't show. The gap is fixable if coverage plus fixable items reaches 4.
6. Estimate effort. Low means summary and skills only, up to 30 minutes. Medium also reorders or rewrites up to five bullets, up to 60 minutes. High is anything over 60 minutes.
7. Apply the matrix, using the score-based Decision for `Confirm First` roles:

| Decision | Coverage 4-5 | Coverage 3 | Coverage 0-2, fixable | Coverage 0-2, not fixable |
|---|---|---|---|---|
| `Apply Now` | Existing, as is | Existing, light edit | NEW | Existing, light edit; note the gap |
| `Apply, Low Effort` | Existing, as is | Existing, as is | Existing, light edit | Existing, as is |
| `Long Shot` | Existing, as is | Existing, as is | Existing, as is | Existing, as is |
| `Skip` | None; name the best fit | Same | Same | Same |
| `Don't Apply` | None | None | None | None |

Three limits apply to NEW:

- A `Confirm First` role never gets NEW. Use the light edit format, and say to reassess NEW once confirmed.
- High effort changes NEW to a light edit, unless the role has the highest Suggested Requested Salary in the batch.
- Recommend at most three NEW resumes per batch, choosing the highest Suggested Requested Salary. The others get a light edit.

Use these formats. Always use the highest-coverage resume as the base for a NEW resume.

- ``NEW resume, based on `Resume_X` ``
- `` `Resume_X`, as is ``
- `` `Resume_X`, with a light edit ``
- `None`, or ``None; if you apply anyway, `Resume_X` ``

## Rows with no readable posting

If no posting text can be found, write `Unknown` for `Pay Range`, `Not scored` for `Background Match`, `Confirm First` for `Decision`, and `Not set` for salary. For `Suggested Resume`, name an exact match if one exists, and otherwise write `None`. Job-board fragments that lack the requirements don't count as posting text.
