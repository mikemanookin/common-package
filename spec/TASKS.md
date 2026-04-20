# Symphony Common Package — Active Tasks

## TASK-001 — Run dependency audit and fix violations

**Spec:** specs/protocol-structure.md § INV-5
**Status:** Open — 2026-04-20
**Priority:** P0

**Acceptance criteria:**
- [ ] `auditDependencies()` reports zero violations
- [ ] No `.m` file in `src/` contains non-comment references to `edu.washington.riekelab` or `manookinlab`

**Out of scope:** Migrating new protocols from external repos.

---

## TASK-002 — Validate all existing protocols pass structure tests

**Spec:** specs/protocol-structure.md § INV-1 through INV-7
**Status:** Open — 2026-04-20
**Priority:** P0

**Acceptance criteria:**
- [ ] `runProtocolTests()` returns 0 failures
- [ ] All 8 concrete protocols in `+common/+protocols/` pass all structural checks

**Out of scope:** Stimulus output validation; lifecycle testing.

---

## TASK-003 — Migrate adaptation-package protocols

**Spec:** specs/protocol-structure.md
**Status:** Open — 2026-04-20
**Priority:** P1

**Acceptance criteria:**
- [ ] All protocols from `manookin-package/StimulusPackages/adaptation-package` ported to `+common/+protocols/`
- [ ] Each ported protocol passes `ProtocolStructureTest`
- [ ] No references to `manookinlab` namespace in ported files

**Out of scope:** Other stimulus domains (color, motion, etc.).

---

## TASK-004 — Migrate general-package protocols

**Spec:** specs/protocol-structure.md
**Status:** Open — 2026-04-20
**Priority:** P1

**Acceptance criteria:**
- [ ] All protocols from `manookin-package/StimulusPackages/general-package` ported to `+common/+protocols/`
- [ ] Each ported protocol passes `ProtocolStructureTest`
- [ ] No references to external namespaces

**Out of scope:** Protocols that require lab-specific hardware not represented in common-package rigs.

---

## TASK-005 — Set up GitHub Actions CI

**Spec:** (none yet)
**Status:** Open — 2026-04-20
**Priority:** P2

**Acceptance criteria:**
- [ ] A `.github/workflows/test.yml` runs `runProtocolTests` and `auditDependencies` on push to main
- [ ] CI uses MATLAB GitHub Actions runner
- [ ] Badge in README reflects test status

**Out of scope:** Deployment or release automation.
