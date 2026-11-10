---
name: resume-quantifier
description: Finds supported resume measurements and defensible calculations when requested, while accepting qualitative evidence when no numeric basis exists.
license: MIT
metadata:
  version: "1.0.0"
---

# Resume Quantifier

Read the [workspace and evidence contract](../job-posting-review/references/workspace-contract.md) before using candidate context. Reuse routed factual owners before asking for documents. For whole-career discovery or requested reusable fact updates, use the `career-context-builder` skill; ordinary tasks may ask focused questions and return bounded drafts without onboarding or persistent fact writes.

Specific supported qualitative contributions or outcomes are sufficient; preserve supported numbers without requiring or inventing them. Current records and corrections outrank resumes. Examples are fictional and require their stated facts for reuse. Drafts do not authorize sending, publishing, submission, or edits to other targets.

## When to Use This Skill

Use this skill when the user:
- Needs to add metrics and numbers to their resume
- Has bullets without quantifiable results
- Doesn't know what numbers to include
- Says they "don't have metrics" or "can't measure impact"
- Mentions: "add metrics", "quantify", "add numbers", "measure impact", "no data"

## Core Capabilities

- Find supported measurements in the experience under discussion
- Explain estimates only from a documented basis and explicit user confirmation
- Create before/after comparisons
- Identify measurable impact points
- Clarify contributions with supported numbers or specific qualitative evidence
- Guide users to discover their metrics

## Why Quantification Matters

**The Problem:**
- "Managed projects" vs "Managed 12 projects worth $2M"
- "Improved processes" vs "Reduced cycle time by 40%"
- "Helped customers" vs "Resolved 50+ tickets daily with 98% satisfaction"

Numbers can clarify scale when known. A specific qualitative contribution or outcome is sufficient without them.

## The Quantification Framework

### Categories of Metrics

**1. Money**
- Revenue generated
- Costs reduced/saved
- Budget managed
- Deal sizes closed
- Profit margins improved

**2. Time**
- Hours saved
- Cycle time reduced
- Project duration
- Response times
- Time to market

**3. Percentages**
- Growth rates
- Improvement percentages
- Efficiency gains
- Error reduction
- Conversion rates

**4. Volume/Scale**
- Number of customers/users
- Projects managed
- Team size
- Transactions processed
- Items produced

**5. Quality**
- Satisfaction scores
- Error rates
- Accuracy rates
- Compliance rates
- SLA adherence

**6. Frequency**
- Per day/week/month
- Annual totals
- Meeting cadences
- Report cycles

## Finding Hidden Metrics

### The Discovery Questions

When the user requests measurement clarification for this experience, select only useful questions below. Read routed records first; these are optional scoped questions, not a whole-career intake or a requirement to find a number:

**Scale Questions:**
- How many people/projects/customers?
- What was the budget/revenue involved?
- How large was the team?
- How many locations/regions?

**Impact Questions:**
- What changed because of your work?
- What would have happened without you?
- What problems did you solve?
- What got better/faster/cheaper?

**Comparison Questions:**
- How was it before vs. after?
- How did you compare to others/previous results?
- What was the baseline you improved?

### Role-Specific Metric Discovery

**Sales:**
- Quota attainment percentage
- Revenue generated
- Number of deals closed
- Average deal size
- Pipeline generated
- New accounts acquired
- Retention rate

**Marketing:**
- Leads generated
- Campaign ROI
- Engagement rates
- Follower growth
- Website traffic increase
- Conversion rates
- Brand awareness metrics

**Customer Service:**
- Tickets resolved per day
- Customer satisfaction score
- Average response time
- First call resolution rate
- NPS score contribution

**Operations:**
- Efficiency improvements
- Cost reductions
- Process cycle times
- Error rate reductions
- Throughput increases

**Engineering:**
- System uptime
- Performance improvements
- Bug resolution rate
- Deployment frequency
- Code coverage

**Project Management:**
- Number of projects
- Budget sizes
- Team sizes
- On-time delivery rate
- Stakeholders managed

**HR/Admin:**
- Hiring numbers
- Time to fill
- Employee satisfaction scores
- Training completion rates
- Onboarding efficiency

## Estimation Techniques

Prefer specific qualitative evidence when no numeric basis exists. An estimate requires a stated measurement/calculation basis, assumptions and explicit user confirmation before external reuse; label it approximate. Arbitrarily lowering a guess is not evidence. Ranges and lower bounds below require supported endpoints or a verified minimum; they are not workarounds for unknown numbers. Never convert "retained most" to a percentage.

### Range Estimation

**Format:** "X-Y" or "X to Y"

**Examples:**
- "Managed team of 8-12"
- "Generated $100K-$150K in revenue"
- "Saved 20-30 hours weekly"

### Minimum Bound

**Format:** "X+" or "at least X"

**Examples:**
- "Served 100+ customers daily"
- "Managed at least 15 concurrent projects"
- "Generated $500K+ in annual revenue"

### Percentage of Activity

**Format:** Calculate from known totals

**Example:**
- Company had 1000 customers → You managed 20% → "Managed 200 customer accounts"
- Team had 10 people → You supervised 4 → "Supervised 40% of team"

### Time-Based Calculation

**Format:** Work backwards from frequency

**Example:**
- Met with 5 clients/week × 50 weeks = "Completed approximately 250 client consultations annually" (repeat clients may be included; confirm frequency and weeks)
- Processed 30 invoices/day × 250 days = "Processed 7,500+ invoices annually"

## Quantification Templates

### Before and After Template
```
"Improved [X] from [before number] to [after number], resulting in [Y]% improvement"

Example:
"Improved page load time from 8 seconds to 2 seconds, a 75% reduction; add engagement only if separately evidenced"
```

### Scale Template
```
"[Verb] [number] [things], resulting in [impact]"

Example:
"Managed 25 concurrent projects worth $3M, delivering 95% on-time with zero budget overruns"
```

### Volume + Impact Template
```
"Processed [number] [items] per [time period], achieving [quality metric]"

Example:
"Resolved 50+ customer tickets daily, maintaining 98% satisfaction rating and 4-hour average response time"
```

### Comparison Template
```
"Ranked #[X] out of [Y] in [metric], [context]"

Example:
"Ranked #2 out of 45 sales representatives nationally, generating $3.2M in annual revenue"
```

## When measurements are unavailable

- Team work: describe the user's supported contribution; do not assign a percentage of a team result without a basis.
- No business metrics: use known activities or a qualitative contribution. Never invent volume, a tool, savings or downstream effects.
- Documentation: "Documented agreed handoff owners" is usable without page counts or assumed onboarding savings.
- Confidential results: honor restrictions. Percentages and ranges do not authorize disclosure; use approved qualitative wording or omit the claim.
- Entry-level work: record actual tasks and supported context. Do not invent throughput, accuracy or comparison to peers.

## Output Format

When reviewing evidence, return:

```markdown
# RESUME EVIDENCE REVIEW

## Supported statements
[Original statement; supplied/routed facts and source status; improved qualitative or numeric wording]

## Measurements and calculations (only when supported)
[Values, units, period, calculation basis, assumptions and user confirmation]

## Unresolved questions
[Only material missing inputs; no requirement to find a number]
```

Fictional example: the user confirms approximately 40 accounts and approximately $2M ARR, and says "retained most". A bounded draft can state "Managed approximately 40 customer accounts representing about $2M ARR". Do not add "enterprise" or a retention percentage. Keep the approximate basis and confirmation in the record. If even those measurements are absent, describe the supported account work qualitatively.

## Evidence quality checklist

- The specific contribution or outcome matches its source and attribution.
- Qualitative evidence is accepted without a mandatory number or business result.
- Supported numbers retain units, period and relevant context.
- Estimates have a documented basis, assumptions and explicit confirmation.
- No unsupported confidentiality workaround or inferred ownership appears.

## Numbers to Avoid

- ❌ Numbers that make you look bad
- ❌ Numbers you can't explain or defend
- ❌ Numbers that reveal confidential information
- ❌ Exaggerated or inflated numbers
- ❌ Numbers without context (e.g., "increased by 300%" without baseline)
- ❌ Too many numbers in one bullet (2-3 max)

## Key Principle

Specific evidence matters. Supported qualitative contributions and outcomes are sufficient; numeric metrics are optional and must be defensible.
