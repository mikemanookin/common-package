# ADR-0001: Adopt Spec-Driven Development

## Status
Accepted — 2026-04-20

## Context
The common-package consolidates protocols from two separate repositories (riekelab-package and manookin-package). Without a formal specification of what constitutes a valid protocol, contributors must reverse-engineer the contract from existing code. This leads to inconsistent implementations, broken protocols discovered only at runtime on physical rigs, and difficulty onboarding new lab members.

## Decision
We adopt spec-driven development (SDD). Every structural contract (required properties, inheritance rules, naming conventions, dependency constraints) is written as a normative specification in `spec/specs/`. Tests in `test/` are derived directly from these specs. Code changes that affect a documented invariant must update the spec first.

## Consequences
+ Protocol contracts are explicit and testable without a physical rig.
+ New contributors can write correct protocols by reading docs and running tests locally.
+ Regressions are caught before code reaches the rig.
- Adds overhead: spec documents must be maintained alongside code.
- Initial setup cost to write specs for existing conventions.
