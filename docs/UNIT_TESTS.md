# Unit Testing Guide

This document describes the unit testing framework for the Symphony Common Package. Tests validate protocol structure at development time so that errors are caught before code reaches a physical rig.

## Quick Start

From MATLAB, navigate to the `common-package` directory and run:

```matlab
cd test
results = runProtocolTests();   % protocol structure validation
report = auditDependencies();   % external dependency check
```

No Symphony installation, physical rig, or Stage server is required. The tests use MATLAB metaclass introspection and source-file scanning only.

## Requirements

- MATLAB R2020b or later (uses `matlab.unittest` framework and modern metaclass features).
- The `common-package/src/packages/base-package` directory must contain the `+common` package.
- No external toolboxes are required.

## Test Files

All test files live in `common-package/test/`:

| File | Purpose |
|------|---------|
| `ProtocolStructureTest.m` | Parameterized test class that validates every protocol against the structural specification |
| `runProtocolTests.m` | Runner script that sets up the MATLAB path and executes the full suite |
| `auditDependencies.m` | Standalone script that scans for external namespace references |

## What Gets Tested

### ProtocolStructureTest

This test class auto-discovers every `.m` file in `+common/+protocols/`, skips the two abstract base classes (`CommonProtocol` and `CommonStageProtocol`), and runs the following checks against each concrete protocol:

**testClassParses** -- Loads the protocol through `meta.class.fromName()` and verifies MATLAB can parse the class file without errors. This catches syntax errors, unresolved references in the `classdef` line, and malformed property blocks.

**testInheritsFromCommonProtocol** -- Walks the full superclass hierarchy and verifies that `common.protocols.CommonProtocol` appears somewhere in the chain. This ensures every protocol inherits the shared rig-detection, amplifier-wiring, and figure-management logic.

**testRequiredPropertiesExist** -- Checks that all six required properties are present in the protocol's property list:

- `amp` -- recording amplifier device name
- `preTime` -- pre-stimulus duration (ms)
- `stimTime` -- stimulus duration (ms)
- `tailTime` -- post-stimulus duration (ms)
- `numberOfAverages` -- number of epochs
- `interpulseInterval` -- rest period between epochs (s)

Properties may be concrete (with a default value) or Dependent (with a getter method), but they must exist.

**testRequiredPropertiesNotAbstract** -- Verifies that none of the six required properties remain abstract. A protocol that inherits `CommonProtocol` but forgets to define `interpulseInterval`, for example, would still "have" the property (inherited as abstract) but could not be instantiated. This test catches that.

**testStageProtocolContract** -- For protocols that inherit from `CommonStageProtocol`, verifies that `createPresentation` is defined and is not abstract. Non-Stage protocols are skipped.

**testPropertyCommentsExist** -- Scans the source file for trailing `%` comments on required property declarations. In Symphony, these comments become the labels in the parameter editor UI. This is a soft check that logs suggestions rather than failing the test.

**testClassIsNotAbstract** -- Verifies that concrete protocol files are not accidentally marked `Abstract`. Only `CommonProtocol.m` and `CommonStageProtocol.m` should be abstract.

**testOneClassPerFile** -- Counts `classdef` declarations in the source file and verifies there is exactly one, and that its name matches the file name. This enforces the MATLAB convention that each class lives in its own file.

**testNoExternalNamespaceReferences** -- Scans the source file for references to external namespaces (`edu.washington.riekelab`, `manookinlab`). The common-package must be self-contained; any such reference is a dependency that needs to be replaced with a `common.*` equivalent.

### auditDependencies

A broader scan than the per-protocol namespace test. It checks every `.m` file under `src/` (not just protocols) for external namespace references. This covers devices, modules, figures, rigs, and utilities in addition to protocols.

The audit distinguishes code references from comments. Lines that are pure comments (starting with `%`) are excluded from violation reports, since they may document migration history.

Running the audit:

```matlab
report = auditDependencies();        % verbose: prints to console
report = auditDependencies(false);   % quiet: returns struct only
```

The returned struct contains:

- `report.clean` -- `true` if no violations were found.
- `report.totalFiles` -- number of `.m` files scanned.
- `report.violations` -- struct array with `file`, `line`, `match`, and `pattern` fields for each violation.

## How Protocol Discovery Works

`ProtocolStructureTest` uses a `TestParameter` property to parameterize all test methods. At test-suite construction time, the static method `discoverProtocols()` scans the filesystem:

1. Locates `+common/+protocols/` relative to the test file's location.
2. Lists all `.m` files in that directory.
3. Constructs fully qualified class names (e.g., `common.protocols.SingleSpot`).
4. Excludes `CommonProtocol` and `CommonStageProtocol` (the abstract bases).

Each remaining class name becomes a parameterized test case. This means adding a new protocol file to `+common/+protocols/` automatically includes it in the test suite with no additional configuration.

## Reading Test Output

A successful run looks like:

```
=== Symphony Common Package - Protocol Structure Tests ===
Source: /path/to/common-package/src/packages/base-package
Tests:  /path/to/common-package/test

Running ProtocolStructureTest
.......... .......... .......... ..........
..........
Done ProtocolStructureTest

=== Summary ===
Total:  72
Passed: 72
Failed: 0
```

The total count is (number of concrete protocols) x (number of test methods). With 8 protocols and 9 test methods, you would see 72 tests.

A failure includes a diagnostic message identifying exactly which protocol and which invariant was violated:

```
Verification failed in ProtocolStructureTest/testRequiredPropertiesExist(protocolName=common.protocols.MyNewProtocol).
    common.protocols.MyNewProtocol is missing required property 'interpulseInterval'.
```

## Adding Tests for a New Protocol

No action is required. When you add a new `.m` file to `+common/+protocols/`, the discovery mechanism picks it up automatically. Just run `runProtocolTests()` to validate it.

If you need to add an entirely new test method (a new structural invariant), add it to the `methods (Test)` block in `ProtocolStructureTest.m`. The method must accept `protocolName` as a parameter to participate in the parameterized test matrix. Document the corresponding invariant in `spec/specs/protocol-structure.md`.

## Relationship to Specifications

The tests are derived from the normative specification in `spec/specs/protocol-structure.md`. Each test method maps to one or more invariants:

| Test Method | Specification Invariant |
|---|---|
| `testInheritsFromCommonProtocol` | INV-1: Inheritance |
| `testRequiredPropertiesExist` | INV-2: Required Properties |
| `testRequiredPropertiesNotAbstract` | INV-2: Required Properties |
| `testStageProtocolContract` | INV-3: Stage Protocol Method |
| `testClassIsNotAbstract` | INV-7: Concrete Protocols Are Not Abstract |
| `testNoExternalNamespaceReferences` | INV-5: Autonomy |
| `testOneClassPerFile` | INV-6: One Class Per File |
| `testPropertyCommentsExist` | Property Comments (recommended, not required) |
| `testClassParses` | General validity |
| `auditDependencies` | INV-5: Autonomy (full-source scan) |

INV-4 (superclass calls) is not tested automatically because it would require runtime analysis or full AST parsing. It is enforced through code review.

## Continuous Integration

The test suite is designed to run in CI without special infrastructure. A future GitHub Actions workflow (see `spec/TASKS.md`, TASK-005) will execute both `runProtocolTests` and `auditDependencies` on every push to `main`.
