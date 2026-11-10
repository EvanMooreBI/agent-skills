# Validation checks

Six checks always run: location or residency, work arrangement, posting status, prior application, pay floor, and user dealbreakers. The others run only when the posting raises the subject. A posting that says nothing about clearance passes the clearance check.

Only explicit posting text can fail a check. Spell out a failed check in `Main reason`, for example: "Limited to Washington, DC residents; you live in Texas."

| Check | `Don't Apply` when | `Confirm First` when | List under evidence to confirm, with no Decision change |
|---|---|---|---|
| Location or residency | Limited to a state, metro, or country the user isn't in, unless the user said they would relocate | The eligible area is not stated, or the posting and application conflict | The user would relocate, and relocation terms are unstated |
| Work arrangement | On-site or hybrid exceeds the user's one-way driving-mile limit, unless the user said they would relocate | "Remote" appears beside hybrid wording, including application questions; or local eligibility cannot be verified under the [workspace contract](workspace-contract.md#preferences-and-commuting) | |
| Work authorization | Citizenship is required and the user is not a citizen; or sponsorship is needed and not offered | Citizenship is required and the user's status is unknown | "No sponsorship" or "must be authorized" when the user has US employment history |
| Clearance | An active clearance is required and the user has none | An active clearance is required and the user's status is unknown | Public Trust, or "able to obtain" a clearance |
| Licenses and certifications | A required credential the user lacks and can't get before starting | A professional license or certification with unknown status | A driver's license with unknown status |
| Education | A degree is mandatory, with no equivalent allowed, and the user has no degree | | The degree field differs, or "related field" is undefined, unless the user accepted an equivalent-experience clause under the [requirement audit](requirement-audit.md#equivalent-experience-degree-rows) |
| Minimum experience | The user has under 50% of required years | The user has 50-79% of required years | The user has 80-99% of required years; also grade the ledger row Partial |
| Posting status | The employer's own text says the role is closed or filled | The employer's page shows a not-found, inactive, or removed notice; a fetch tool shows closure; only an aggregator copy could be read; the application window passed; or the posting says it is a pipeline role or depends on a contract award | |
| Employment type | Contract, part-time, or temporary work the user ruled out | | The type is not stated |
| Schedule, time zone, travel | Requirements conflict with a stated user limit | | Requirements with no stated user limit |
| Pay floor | The top of the range is below the user's floor | The market high for an unposted range is below the user's floor | The user's floor is unknown |
| Prior application | The user already applied, and the employer bars reapplying | An earlier application is found | A resume made for this employer is newer than the application log |
| Legitimacy | Fee requests, or requests for bank details before an offer, or an employer domain that doesn't match | | Identity verification as a condition of employment |
| User dealbreakers | The posting breaks a dealbreaker the user stated | The posting may break one | |

## Default assumptions

Use the [workspace contract](workspace-contract.md#preferences-and-commuting) for setup defaults, explicit citizenship confirmation, private address storage, and verified driving distance. Do not infer citizenship or authorization from US employment history.

- If the user's location is known and they have not said they would relocate, assume they won't. Add "Tell me if you would relocate" to `Main reason`.
- A location in a resume header counts as the user's location.
- If the location is entirely unknown, ask for it.

## Preference conflicts

A preference conflict is not a failure. It gives `Confirm First` when the avoided work is in the job title, or the posting names it as a main tool or duty. A stated dealbreaker uses the dealbreaker row instead, and it takes precedence.

## `Confirm First` results

Finish every step for a `Confirm First` role, then state the outcome in `Main reason`, such as "If cleared: `Apply Now`." Use the score-based Decision from the scoring rules.
