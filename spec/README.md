# Symphony Common Package - Spec Directory

This directory implements spec-driven development (SDD) for the Symphony Common Package. Every non-trivial change should start here: read the relevant spec, update it if needed, record an Architecture Decision Record (ADR) if the change is architectural, then break the work into tasks.

## Navigation

| File | Purpose |
|------|---------|
| [SPECS.md](SPECS.md) | Manifest of all normative specifications |
| [PLAN.md](PLAN.md) | Architecture direction + roadmap (Now / Next / Later) |
| [TASKS.md](TASKS.md) | Active work queue with acceptance criteria |
| [specs/](specs/) | Individual specification documents |
| [decisions/](decisions/) | Architecture Decision Records (ADRs) |

## Document Roles

Each document answers one question. Keeping these boundaries clean is what makes SDD work.

| Document | Answers | Lifetime |
|----------|---------|----------|
| **Specs** | *What is true?* — behaviors, formats, contracts, invariants | Long (changes with requirements) |
| **Plan** | *What's the strategy?* — architecture, roadmap, trade-offs | Medium (changes with priorities) |
| **Tasks** | *What's next?* — actionable items with acceptance criteria | Short (items get completed and removed) |
| **ADRs** | *Why did we decide this?* — one decision, with context and consequences | Permanent (record, never edit) |

## Workflow

For any non-trivial change:

1. **Read** the relevant spec(s) in `specs/`.
2. If the change modifies a documented invariant, **update the spec first**, before writing code.
3. If it's a new architectural direction, **propose an ADR** in `decisions/`.
4. **Break the work into tasks** in `TASKS.md` with explicit acceptance criteria.
5. **Implement** against the spec.
6. If reality diverged from the spec during implementation, **update the spec**.

The test: a spec is specific enough if someone unfamiliar with the codebase could write tests from it.

## ADR format

New ADRs follow this template:

```markdown
# ADR-NNNN: <short title>

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXXX — YYYY-MM-DD

## Context
What forces this decision? Technical constraints, bugs, requirements.

## Decision
The choice made. One paragraph.

## Consequences
+ Positive outcomes
− Trade-offs / negative outcomes
```

Number ADRs sequentially (0001, 0002, ...). Never renumber. If a decision is reversed, write a new ADR that supersedes the old one; do not delete the original.

## Task format

Tasks live in [TASKS.md](TASKS.md) and follow this format:

```markdown
## TASK-NNN — <short imperative title>

**Spec:** specs/<file>.md § <section>
**ADR:** decisions/NNNN-<slug>.md (if relevant)
**Status:** Open | In Progress | Blocked | Done — YYYY-MM-DD
**Priority:** P0 | P1 | P2

**Acceptance criteria:**
- [ ] Testable condition 1
- [ ] Testable condition 2

**Out of scope:** What this task explicitly does not cover
```

