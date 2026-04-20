# Symphony Common Package — Specifications Manifest

Normative specifications for Symphony Common Package. Each document defines a contract the system must uphold. Code that diverges from a spec is a bug in the code *or* the spec — in either case, one must be brought into alignment with the other.

| Spec | File | Covers |
|------|------|--------|
| Protocol Structure | [specs/protocol-structure.md](specs/protocol-structure.md) | Inheritance, required properties, lifecycle contracts, autonomy invariants |

## Adding a New Spec

1. Create a new file in `specs/` following the naming convention: `kebab-case-topic.md`.
2. Include: Status, Purpose, Definitions, Invariants (numbered INV-N), and Allowed Dependencies if relevant.
3. Add a row to the table above.
4. Write or update tests in `test/` that validate the invariants.

## Spec Lifecycle

- **Draft** — Under discussion; not yet enforceable.
- **Active** — The current truth. Tests must pass against it.
- **Deprecated** — Superseded by a newer spec. Kept for historical context.
