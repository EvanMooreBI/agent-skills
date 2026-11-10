---
name: job-description-analyzer
description: Analyze job postings, calculate match scores, identify gaps, and create application strategy
license: MIT
metadata:
  version: "1.0.0"
---

# Job Description Analyzer

Read the [workspace and evidence contract](../job-posting-review/references/workspace-contract.md) before using candidate context. Reuse routed factual owners before asking for documents. For whole-career discovery or requested reusable fact updates, use the `career-context-builder` skill; ordinary tasks may ask focused questions and return bounded drafts without onboarding or persistent fact writes.

Specific supported qualitative contributions or outcomes are sufficient; preserve supported numbers without requiring or inventing them. Current records and corrections outrank resumes. Examples are fictional and require their stated facts for reuse. Drafts do not authorize sending, publishing, submission, or edits to other targets.

## When to Use This Skill

Use this skill when the user:
- Wants to analyze a job posting
- Asks "should I apply to this job?"
- Wants to know their match percentage for a role
- Needs help understanding job requirements
- Wants to tailor their resume for a specific position
- Mentions: "analyze this job", "am I qualified", "match score", "should I apply"

Use this BEFORE resume tailoring to ensure effort is worth it.

To rank postings or get a decision table with resume and salary suggestions, use the `job-posting-review` skill instead. Use this skill for a deep report on one posting.

## Core Capabilities

- Extract and categorize job requirements (must-have vs nice-to-have)
- Calculate match score between user's experience and job requirements
- Identify skill gaps and strengths
- Detect red flags in job postings
- Prioritize which experiences to highlight
- Generate resume tailoring strategy
- Create cover letter talking points
- Assess company culture fit indicators

## The Strategic Problem

Most job seekers waste time on:
- Jobs they're under-qualified for (<60% match)
- Jobs they're over-qualified for (flight risk)
- Jobs with red flags (high turnover, toxic culture)
- Applying to 50+ jobs blindly hoping something sticks

Better approach:
- Apply to 10-15 jobs strategically
- Target 70-90% match jobs
- Customize deeply for each
- Higher response rate, less burnout

## Analysis Process

### Step 1: Extract Requirements

Break job description into categories:

**Required (Must-Have)**
- Education requirements
- Years of experience
- Specific technical skills
- Certifications/licenses
- Industry experience

**Preferred (Nice-to-Have)**
- "Bonus" skills
- Advanced certifications
- Domain expertise
- Specific tool experience

**Soft Skills/Culture**
- Communication style
- Work environment
- Team structure
- Company values

### Step 2: Keyword Extraction

Identify three types:

**Hard Skills** (Technical abilities)
- Tools: Salesforce, Python, AWS, Excel
- Methodologies: Agile, Six Sigma, SDLC
- Certifications: PMP, CPA, AWS Certified

**Soft Skills** (Interpersonal)
- Leadership, collaboration, communication
- Problem-solving, critical thinking
- Adaptability, initiative

**Industry/Domain Knowledge**
- B2B SaaS, healthcare, fintech
- Enterprise vs SMB
- Regulatory knowledge (HIPAA, SOX, GDPR)

### Step 3: Calculate Match Score

Build and grade the requirement ledger with the requirement audit in the `job-posting-review` skill before you score. It splits bundled requirements, grades each named item against the user's records, and calculates years of experience from dates. Then calculate the match with that skill's Background Match rules and read it against its score-based Decision bands. Do not count whole requirements as met, and do not soften an unmet item as "thin."

### Step 4: Gap Analysis

For each missing requirement:
- **Critical gap**: Deal-breaker (don't apply)
- **Major gap**: Significant but addressable (mention in cover letter)
- **Minor gap**: Easy to learn (downplay or emphasize related skills)

### Step 5: Red Flag Detection

Scan for warning signs:

**Workload Red Flags:**
- "Wear many hats"
- "Fast-paced environment"
- "Hit the ground running"
- "Self-starter in ambiguous situations"

**Culture Red Flags:**
- "Rockstar/Ninja/Guru"
- "We work hard, play hard"
- "Unlimited vacation"
- "Like a family"

**Compensation Red Flags:**
- "Competitive salary" (won't tell you range)
- "Equity-heavy" (low cash compensation)
- "Commission-based" (no base salary)
- "DOE" with no range

## Match Score Output Format

Use this report structure with the actual graded ledger and computed score. Never reuse a sample score, invented competition estimate, qualification, course, interview process, or deadline.

```markdown
# JOB ANALYSIS REPORT

**Position / company / source:** [Observed title, company, and source]
**Location / work arrangement / pay:** [Posted terms; unknowns labeled]
**Background Match:** [Computed with the review skill's rules]
**Recommendation:** [Computed Decision, including validation overrides]

## Requirements breakdown
[Ledger: exact requirement, type, evidence grade, source, and claim limit]

## Strengths and gaps
[Supported strengths; every unmet or unverified requirement and its limits]

## Resume customization strategy
[Actual catalog candidate; supported claims to emphasize; gaps not to claim]

## Application talking points
[Evidence-backed points; no invented interests, courses, or motivation]

## Risks and research
[Observed conditions, uncertainties, and cited company/pay facts]

## Next steps
[Actions appropriate to the Decision; only stated deadlines or interview steps]

## Method and limitations
[Source availability, ledger/scoring rules, unresolved evidence and history]
```

## Requirement Classification Guide

### Identifying "Must Have" vs "Nice to Have"

**Language indicating REQUIRED:**
- "Must have..."
- "Required: X years of..."
- "You have..."
- "Essential qualifications"
- Listed under "Requirements"
- Repetition alone does not turn a preferred item into a required one; use the shared requirement audit

**Language indicating PREFERRED:**
- "Nice to have..."
- "Bonus if you have..."
- "Preferred qualifications"
- "Ideally, you'd have..."
- "A plus if..."
- Frequency alone does not establish preference status

### Dealbreaker Detection

Use the `job-posting-review` skill's validation checks and Decision rules. Distinguish an explicit failed check from a background gap, a preference, or an unknown. Preserve degree-equivalence handling, exact experience thresholds, relocation exceptions, and prior-application outcomes. Do not replace those rules with blanket "apply anyway" or "don't apply" advice.

## Implementation Checklist

When analyzing a job:

1. ✅ Extract all requirements (required vs preferred)
2. ✅ Identify all keywords (hard skills, soft skills, industry terms)
3. ✅ Grade each requirement, then calculate match score
4. ✅ Identify strengths to emphasize
5. ✅ Identify gaps and strategies to address
6. ✅ Detect red flags
7. ✅ Create resume customization plan
8. ✅ Generate cover letter talking points
9. ✅ Research company
10. ✅ Provide application recommendation and timeline

## Edge Cases

### Posting Page Does Not Render
- A fetch can return an empty page, a page shell, or a closure notice with no job description
- Do not report the posting as missing or closed from that result
- Follow the posting retrieval rules in the `job-posting-review` skill: public ATS endpoints first, then the user's pasted or exported copy

### Vague Job Descriptions
- Flag as potential red flag
- Extract what keywords you can
- Recommend reaching out for clarity before applying
- Do not invent missing requirements from industry norms; label incomplete posting text and use the shared retrieval/validation rules

### Multiple Roles in One JD
- Identify the core role vs "other duties"
- Focus match score on primary responsibilities
- Flag scope creep concerns

### Internal Postings (Already Working There)
- Different strategy - emphasize internal knowledge
- Highlight cross-team relationships
- Reference specific company initiatives

### Reposted Jobs
- May indicate: Previous hire didn't work out, role expanded, or first search failed
- Worth applying, but research why it was reposted
- Check if requirements changed from original posting
