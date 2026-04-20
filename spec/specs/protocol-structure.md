# SPEC: Protocol Structure

**Status:** Active
**Last updated:** 2026-04-20

## Purpose

Defines the structural contract that every Symphony protocol in common-package must satisfy. Tests in `test/ProtocolStructureTest.m` are derived directly from this specification.

## Definitions

- **Protocol**: A MATLAB class that defines a single experimental stimulus and recording paradigm.
- **Concrete protocol**: A non-abstract protocol that can be instantiated and run in Symphony.
- **Stage protocol**: A protocol that presents visual stimuli via the Stage display framework.
- **Non-Stage protocol**: A protocol that does not use Stage (e.g., current injection, LED stimulation).

## Invariants

### INV-1: Inheritance

Every concrete protocol in `+common/+protocols/` MUST inherit (directly or indirectly) from `common.protocols.CommonProtocol`.

Stage protocols MUST inherit from `common.protocols.CommonStageProtocol`, which itself inherits from `CommonProtocol`.

### INV-2: Required Properties

Every concrete protocol MUST define the following six properties. They may be ordinary properties with default values, or Dependent properties with getter methods, but they MUST NOT remain abstract.

| Property | Type | Units | Purpose |
|---|---|---|---|
| `amp` | char | — | Recording amplifier device name |
| `preTime` | double | milliseconds | Pre-stimulus duration |
| `stimTime` | double | milliseconds | Stimulus duration |
| `tailTime` | double | milliseconds | Post-stimulus duration |
| `numberOfAverages` | uint16 | — | Number of epochs to run |
| `interpulseInterval` | double | seconds | Rest between epochs |

### INV-3: Stage Protocol Method

Every concrete Stage protocol (inheriting from `CommonStageProtocol`) MUST implement a non-abstract `createPresentation` method that returns a `stage.core.Presentation` object.

### INV-4: Superclass Calls

When a protocol overrides any lifecycle method (`didSetRig`, `prepareRun`, `prepareEpoch`, `completeEpoch`, `prepareInterval`, `completeRun`), it MUST call the corresponding superclass method before its own logic.

### INV-5: Autonomy

No file in `src/` SHALL contain non-comment references to external namespaces (`edu.washington.riekelab`, `manookinlab`). The common-package must be self-contained. The only external dependency is the Symphony core framework (`symphonyui.*`, `stage.*`).

### INV-6: One Class Per File

Each `.m` file in `+common/+protocols/` MUST contain exactly one `classdef` whose name matches the file name.

### INV-7: Concrete Protocols Are Not Abstract

Files in `+common/+protocols/` other than `CommonProtocol.m` and `CommonStageProtocol.m` MUST NOT be declared `Abstract`.

## Timing Convention

All time properties (`preTime`, `stimTime`, `tailTime`) are specified in **milliseconds**. Code that passes these to Symphony or Stage APIs must convert to seconds using `* 1e-3`.

`interpulseInterval` is specified in **seconds** (it is passed directly to Symphony's interval mechanism).

## Property Comments

Property declarations SHOULD include a trailing `%` comment that serves as the label in Symphony's parameter editor UI. Format: `propertyName = defaultValue  % Human-readable label (units)`.

## Allowed Dependencies

The following namespaces are considered internal and are allowed:

- `common.*` — this package
- `symphonyui.*` — Symphony core framework
- `stage.*` — Stage visual stimulus framework
- `io.github.stage_vss.*` — Stage VSS extensions

All other namespaces are external and violate INV-5.
