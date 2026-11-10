---
name: resume-version-manager
description: Organizes existing resume versions and their catalog, preserving factual owners and optional master drafting references.
license: MIT
metadata:
  version: "1.0.0"
---

# Resume Version Manager

Read the [workspace and evidence contract](../job-posting-review/references/workspace-contract.md) before using candidate context. Reuse routed factual owners before asking for documents. For whole-career discovery or requested reusable fact updates, use the `career-context-builder` skill; ordinary tasks may ask focused questions and return bounded drafts without onboarding or persistent fact writes.

Specific supported qualitative contributions or outcomes are sufficient; preserve supported numbers without requiring or inventing them. Current records and corrections outrank resumes. Examples are fictional and require their stated facts for reuse. Drafts do not authorize sending, publishing, submission, or edits to other targets.

## When to Use This Skill

Use this skill when the user:
- Has multiple resume versions to manage
- Needs to track tailored resumes
- Wants to maintain a master resume
- Is applying to many different roles
- Mentions: "resume versions", "master resume", "different versions", "track resumes", "which resume"

## Core Capabilities

- Create and maintain master resume document
- Track tailored resume versions
- Organize resume versions by role/industry
- Maintain a consistent resume catalog linked to factual owners
- Streamline resume updates
- Prevent version confusion

## The Version Management Problem

**Common Pain Points:**
- "Which version did I send to Company X?"
- "Where's my most recent resume?"
- "I have 15 resume files and don't know which is best"
- "I forgot to update my resume after that project"
- "I keep tailoring from different base versions"

**The Solution:**
A systematic approach with:
1. Existing factual owners and a resume catalog; an optional master drafting reference
2. Organized tailored versions
3. Clear naming conventions
4. Update workflow

## Master Resume Concept

### What is a Master Resume?

A comprehensive document containing:
- ALL your experiences (not just recent)
- ALL bullet points you've ever written
- Every achievement, project, skill
- Full details (even if they won't fit on one page)

**Purpose:** Optional drafting reference for tailoring. Current factual records and corrections remain authoritative; copying a resume claim does not verify it.

### Master Resume Structure

```markdown
# MASTER RESUME - [YOUR NAME]
Last Updated: [Date]

## CONTACT INFORMATION
[Full contact details]

## PROFESSIONAL SUMMARY VERSIONS
[Summary for Role Type A]
[Summary for Role Type B]
[Summary for Role Type C]

## ALL SKILLS
### Technical Skills
[Complete list by category]

### Soft Skills
[Complete list]

### Industry Knowledge
[All domains]

## PROFESSIONAL EXPERIENCE

### Company Name | Title | Dates

**All Bullets (choose best for each application):**
• Bullet 1 (leadership focused)
• Bullet 2 (technical focused)
• Bullet 3 (results focused)
• Bullet 4 (collaboration focused)
• Bullet 5 (additional achievement)
• Bullet 6 (additional achievement)

**Keywords this experience covers:**
[List of keywords this job demonstrates]

### Previous Company | Title | Dates
[Same format...]

## EDUCATION
[Complete education history]

## CERTIFICATIONS
[All certifications ever earned]

## PROJECTS
[All notable projects]

## VOLUNTEER / ADDITIONAL
[All other relevant experience]
```

## File Organization System

### Optional Folder Structure

Reuse the current local/Drive locations, catalog, names and formats. This example is not a migration or mandatory directory scheme.

```
Resume/
├── Master/
│   └── LastName_Master_Resume.docx
├── Tailored/
│   ├── ProductManagement/
│   │   ├── LastName_PM_Google_Jan2024.pdf
│   │   └── LastName_PM_Meta_Jan2024.pdf
│   ├── Engineering/
│   │   ├── LastName_SWE_Startup_Feb2024.pdf
│   │   └── LastName_SWE_Enterprise_Feb2024.pdf
│   └── General/
│       └── LastName_General_Resume.pdf
├── CoverLetters/
│   ├── Google_PM_CoverLetter.docx
│   └── Meta_PM_CoverLetter.docx
└── Applications/
    └── ApplicationTracker.xlsx
```

### Optional File Naming Convention

**Pattern:**
`[LastName]_[Role/Type]_[Company]_[Date].pdf`

**Examples:**
- `Smith_ProductManager_Google_Jan2024.pdf`
- `Smith_SWE_Stripe_Feb2024.pdf`
- `Smith_DataScience_General_2024.pdf`
- `Smith_Master_Resume_v3.docx`

## Version Categories

### By Target Role

**Product Management:**
- Emphasizes: Strategy, roadmap, metrics, stakeholders
- Skills highlight: Product tools, analytics, user research

**Software Engineering:**
- Emphasizes: Technical projects, systems, code
- Skills highlight: Languages, frameworks, tools

**Data Science:**
- Emphasizes: Analysis, ML, statistical methods
- Skills highlight: Python, SQL, ML libraries

### By Industry

**Tech/Startup:**
- Emphasizes: Innovation, growth, scrappiness
- Tone: Modern, direct, achievement-focused

**Enterprise/Corporate:**
- Emphasizes: Scale, process, collaboration
- Tone: Professional, structured, comprehensive

**Finance:**
- Emphasizes: Analysis, compliance, accuracy
- Tone: Conservative, precise, credentialed

### By Seniority Level

**Individual Contributor:**
- Focus on execution and technical skills
- Detailed project descriptions
- Technical accomplishments

**Manager:**
- Team leadership and development
- Cross-functional collaboration
- Business impact metrics

**Executive:**
- Strategic leadership
- P&L responsibility
- Organizational transformation

## Application Tracking

### Existing Application Log

Reuse the mapped log and its schema. Record an application only when the user requests it and confirms what actually occurred; tailoring a resume does not mean it was submitted. The table below is fictional.

```
| Company | Role | Version Used | Date Applied | Status | Notes |
|---------|------|--------------|--------------|--------|-------|
| Google | PM | PM_Google_Jan | 1/15/24 | Interview | 2nd round 2/1 |
| Meta | PM | PM_Meta_Jan | 1/18/24 | Applied | Referral from John |
| Startup | PM | PM_General | 1/20/24 | Rejected | Too senior |
```

### Information to Track

- Company name
- Job title
- Resume version used
- Cover letter version used
- Application date
- Application method (portal, referral, direct)
- Current status
- Follow-up dates
- Notes and contacts

## Update Workflow

### When experience changes

Use the `career-context-builder` skill for requested factual updates and reviewed batches in the existing owners. After confirmation, update only requested resume targets and catalog entries. A master drafting reference is optional. Do not schedule reviews, create a new log, or upload backups without a request.

### From records to a tailored version

1. Read the current factual owners and catalog; select an existing resume or optional master reference.
2. Follow the `resume-tailor` skill for the requested role, preserving supported claims and the identified target.
3. Save the requested version in its chosen location using the existing naming scheme, then read it back.
4. Update the catalog only as requested. An application-history entry requires a separate confirmed application event; preparation is not submission.

## Common Scenarios

### Scenario 1: Applying to Similar Roles

**Strategy:**
- Create one well-tailored version for the role type
- Make minor adjustments for each company
- Track which slight variation went where

### Scenario 2: Applying to Different Role Types

**Strategy:**
- Create separate base versions for each role type
- Maintain clear folder organization
- Each version agrees with the maintained factual owners

### Scenario 3: Rapid Application Volume

**Strategy:**
- Create 2-3 strong category versions
- Use "general" versions for quick applications
- Reserve deep tailoring for top choices

### Scenario 4: Career Transition

**Strategy:**
- Create transition-focused version
- Emphasize transferable skills
- Maintain original industry version as backup

## Version Control Best Practices

### DO:
- ✅ Check maintained facts before using an existing resume or optional master
- ✅ Use consistent naming conventions
- ✅ Track which version went where
- ✅ Update an optional master only when requested, from maintained facts
- ✅ Date your files
- ✅ Preserve the user-selected storage and backup approach

### DON'T:
- ❌ Edit master directly for applications
- ❌ Use vague names like "resume_final_v2"
- ❌ Forget which version you sent
- ❌ Treat an outdated resume as factual authority
- ❌ Have multiple "master" files
- ❌ Delete old versions (archive instead)

## Output Format

When managing resume versions:

```markdown
# RESUME VERSION MANAGEMENT

## Optional Drafting Reference Status
**Last Updated:** [Date]
**Location:** [File path]
**Factual Owners:** [Verified locations; master reference may be absent]
**Total Bullet Points Available:** [X]

## Active Versions

### Role Type: Product Management
**Base Version:** PM_General_2024.docx
**Tailored Versions:**
| Company | File Name | Date Created | Status |
|---------|-----------|--------------|--------|
| Google | PM_Google_Jan24 | 1/15/24 | Submitted |
| Meta | PM_Meta_Jan24 | 1/18/24 | Submitted |

### Role Type: Engineering
[Same structure]

## Update Queue
- [ ] Confirm requested project facts with their current owner before updating drafts
- [ ] Update skills with new certification
- [ ] Archive versions older than 6 months

## Recommended Actions
1. [Action 1]
2. [Action 2]
```

## Version Management Checklist

- ✅ Factual owners and current resume catalog are identified; no master prerequisite
- ✅ Folder structure is organized
- ✅ Naming convention is consistent
- ✅ Application tracker is maintained
- ✅ Know which version sent to each company
- ✅ All versions respect the same factual authority and restrictions
- ✅ Backup system in place
- ✅ Old versions archived (not deleted)
- ✅ Update workflow is established
- ✅ Optional review actions are proposed, never automatically scheduled
