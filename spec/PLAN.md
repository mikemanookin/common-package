# Symphony Common Package — Architecture Plan

## Vision

A single, self-contained repository of Symphony protocols that any collaborating lab can clone and use without depending on riekelab-package or manookin-package. The common-package consolidates the best patterns from both source repositories into a clean inheritance hierarchy with comprehensive tests and documentation.

## Architecture

```
symphonyui.core.Protocol           (Symphony core; external)
  +-- CommonProtocol               (abstract; MEA/patch detection, amp wiring, figures)
        +-- CommonStageProtocol    (abstract; Stage integration, frame monitor, trigger sync)
              +-- [Stage protocols]
        +-- [Non-Stage protocols]
```

Key design decisions:

- Abstract properties (`amp`, `preTime`, `stimTime`, `tailTime`, `numberOfAverages`, `interpulseInterval`) enforce a uniform interface across all protocols.
- Dependent properties allow protocols to expose custom parameter names while satisfying the abstract contract.
- Base classes handle all rig-detection, amplifier wiring, MEA synchronization, and default figures so concrete protocols stay minimal.

## Roadmap

### Now (Current Sprint)

- Spec-driven development infrastructure (specs, tests, docs).
- Structure-validation test suite for all protocols.
- Dependency audit to verify autonomy from external repos.
- Protocol development documentation for new contributors.

### Next

- Migrate remaining protocols from manookin-package/StimulusPackages into common-package, organized by stimulus domain (adaptation, color, motion, etc.).
- Add stimulus-generation tests: instantiate protocols with mock objects, verify stimulus outputs.
- Add CI/CD via GitHub Actions to run tests on every push.

### Later

- Full lifecycle tests with mock rig and epoch orchestration.
- Protocol template generator (script that scaffolds a new protocol file from a template).
- Symphony3 compatibility layer (base-symphony3 modules already stubbed).
- Integration tests that validate rig configurations against protocol requirements.

## Constraints

- MATLAB R2020b or later (for `arguments` blocks and modern unittest features).
- Tests must run without a physical rig, Stage server, or Symphony installation (metaclass introspection only for structure tests).
- The `lib/` submodules (matlab-lcr, matlab-emagin) are the only allowed git dependencies beyond Symphony itself.
