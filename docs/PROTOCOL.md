# Symphony Protocol Development Guide

This document describes how to write protocols for the Symphony Common Package. It is the authoritative reference for protocol structure, lifecycle, and conventions.

## Table of Contents

1. [Overview](#overview)
2. [Class Hierarchy](#class-hierarchy)
3. [Required Properties](#required-properties)
4. [Protocol Lifecycle](#protocol-lifecycle)
5. [Writing a Non-Stage Protocol](#writing-a-non-stage-protocol)
6. [Writing a Stage (Visual) Protocol](#writing-a-stage-visual-protocol)
7. [Advanced Patterns](#advanced-patterns)
8. [Conventions and Best Practices](#conventions-and-best-practices)
9. [Validation and Testing](#validation-and-testing)

---

## Overview

A *protocol* is a MATLAB class that defines a single experimental stimulus and recording paradigm. Protocols inherit from base classes in `common.protocols` which handle rig detection, amplifier setup, online analysis figures, MEA synchronization, and epoch flow control. This means a concrete protocol is typically short: it declares its parameters and implements the stimulus-specific logic.

There are two categories of protocol:

- **Non-Stage protocols** inherit from `CommonProtocol` and drive amplifier-based stimuli (current injection) or LED-based stimuli. They do not use the Stage visual display system.
- **Stage protocols** inherit from `CommonStageProtocol` and present visual stimuli on a monitor/projector via the Stage framework while recording electrophysiology responses.

---

## Class Hierarchy

```
symphonyui.core.Protocol              (Symphony core -- do not modify)
  +-- common.protocols.CommonProtocol       (abstract; shared across all rigs)
        +-- common.protocols.CommonStageProtocol  (abstract; visual stimulus support)
              +-- SingleSpot, SparseNoise, ...    (concrete Stage protocols)
        +-- Pulse, LedPulse, ChannelTest, ...     (concrete non-Stage protocols)
```

`CommonProtocol` extends Symphony's core `Protocol` class and adds:
- Abstract properties that every protocol must define (see below).
- Automatic MEA vs. patch rig detection.
- Default online analysis figures (ResponseFigure, MeanResponseFigure, ProgressFigure).
- Amplifier and device response wiring.
- Temperature controller readout.
- External trigger generation for MEA clock synchronization.

`CommonStageProtocol` extends `CommonProtocol` and adds:
- An abstract `createPresentation()` method for defining visual stimuli.
- Frame monitor synchronization.
- Automatic Stage memory cleanup.
- A `shouldWaitForTrigger` mechanism to sync DAQ and Stage clocks.
- Stage validation (`isValid` checks for a Stage device in the rig).

---

## Required Properties

Every protocol that inherits from `CommonProtocol` **must** define the following properties. They are declared `Abstract` in the base class, so MATLAB will error at class loading time if any are missing.

| Property | Type | Description |
|---|---|---|
| `amp` | char | Name of the recording amplifier device. Populated by `didSetRig`. |
| `preTime` | double | Duration before stimulus onset, in milliseconds. |
| `stimTime` | double | Duration of the stimulus, in milliseconds. |
| `tailTime` | double | Duration after stimulus offset, in milliseconds. |
| `numberOfAverages` | uint16 | Number of epochs (trials) to run. |
| `interpulseInterval` | double | Rest period between epochs, in seconds. |

These properties enforce a uniform interface across all protocols and are used by the base class for epoch timing, amplifier stimulus duration, progress tracking, and flow control.

### Using Dependent Properties for Custom Timing

If your stimulus does not map cleanly to a single `stimTime` window, you can implement `stimTime` as a Dependent property while using your own timing parameters:

```matlab
properties
    amp
    preTime = 250
    flashTime1 = 100
    interFlashTime = 500
    flashTime2 = 100
    tailTime = 1000
    numberOfAverages = uint16(10)
    interpulseInterval = 0
end

properties (Dependent)
    stimTime
end

methods
    function t = get.stimTime(obj)
        t = obj.flashTime1 + obj.interFlashTime + obj.flashTime2;
    end
end
```

This satisfies the abstract contract while giving the user more meaningful parameter names. The computed `stimTime` is still used by the base class for epoch duration and amplifier stimulus generation.

---

## Protocol Lifecycle

When Symphony runs a protocol, it calls methods in the following order. Methods marked with **(base)** are handled by `CommonProtocol` or `CommonStageProtocol` and typically do not need to be overridden.

### Initialization

1. **`didSetRig(obj)`** **(base)** -- Called when a rig is assigned. The base class uses this to populate `obj.amp` and `obj.ampType` from available Amp devices. Override only if you need additional device handles (e.g., an LED):
   ```matlab
   function didSetRig(obj)
       didSetRig@common.protocols.CommonProtocol(obj);
       [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
   end
   ```

### Run Start

2. **`prepareRun(obj)`** **(base)** -- Called once before the first epoch. The base class detects MEA vs. patch rig and shows default analysis figures. Override to add protocol-specific figures:
   ```matlab
   function prepareRun(obj)
       prepareRun@common.protocols.CommonProtocol(obj);
       obj.showFigure('symphonyui.builtin.figures.ResponseStatisticsFigure', ...
           obj.rig.getDevice(obj.amp), {@mean, @var}, ...
           'baselineRegion', [0 obj.preTime], ...
           'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
   end
   ```

### Epoch Loop

The following methods repeat for each epoch (trial):

3. **`prepareEpoch(obj, epoch)`** **(base)** -- Wires amplifier responses, device responses, MEA triggers, and (for Stage protocols) the frame monitor. Override to add protocol-specific stimuli:
   ```matlab
   function prepareEpoch(obj, epoch)
       prepareEpoch@common.protocols.CommonProtocol(obj, epoch);
       epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
   end
   ```

4. **`controllerDidStartHardware(obj)`** **(base, Stage only)** -- For Stage protocols, this is where the visual presentation is played on the Stage device. You do not need to override this.

5. **`completeEpoch(obj, epoch)`** **(base)** -- Reads temperature controller data and stores bath temperature. Override only for special post-epoch processing.

### Flow Control

6. **`shouldContinuePreparingEpochs(obj)`** **(base)** -- Returns `true` while `numEpochsPrepared < numberOfAverages`. Override only for protocols with dynamic epoch counts.

7. **`shouldContinueRun(obj)`** **(base)** -- Returns `true` while `numEpochsCompleted < numberOfAverages`.

### Run End

8. **`completeRun(obj)`** **(base, Stage only)** -- Clears Stage memory after the run finishes.

### Between Epochs

9. **`prepareInterval(obj, interval)`** **(base)** -- Adds a direct-current hold stimulus during the inter-pulse interval. Override if your protocol needs a different inter-epoch behavior.

---

## Writing a Non-Stage Protocol

Non-Stage protocols inherit directly from `CommonProtocol`. They are used for current injection, LED stimulation, or any paradigm that does not use the Stage visual display.

### Minimal Example: Pulse

```matlab
classdef Pulse < common.protocols.CommonProtocol
    % Rectangular pulse stimulus delivered to the amplifier.

    properties
        amp                             % Output amplifier
        preTime = 50                    % Leading duration (ms)
        stimTime = 500                  % Pulse duration (ms)
        tailTime = 50                   % Trailing duration (ms)
        pulseAmplitude = 100            % Amplitude (mV or pA)
        numberOfAverages = uint16(5)    % Number of epochs
        interpulseInterval = 0          % Rest between epochs (s)
    end

    methods
        function stim = createAmpStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.pulseAmplitude;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            stim = gen.generate();
        end

        function prepareEpoch(obj, epoch)
            prepareEpoch@common.protocols.CommonProtocol(obj, epoch);
            epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
        end
    end
end
```

**Key points:**
- All six abstract properties are defined in the `properties` block.
- `prepareEpoch` calls the superclass first, then adds the protocol-specific stimulus.
- The base class handles amplifier responses, device responses, flow control, and figures.

### LED Protocol Pattern

For LED-based protocols, override `didSetRig` to get the LED device handle:

```matlab
classdef LedPulse < common.protocols.CommonProtocol
    properties
        led                             % Output LED
        preTime = 500
        stimTime = 500
        tailTime = 500
        lightAmplitude = 0              % Pulse amplitude (V)
        lightMean = 0                   % LED background (V)
        amp                             % Recording amplifier
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end

    properties (Hidden)
        ledType
    end

    methods
        function didSetRig(obj)
            didSetRig@common.protocols.CommonProtocol(obj);
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
        end

        function prepareEpoch(obj, epoch)
            prepareEpoch@common.protocols.CommonProtocol(obj, epoch);
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
        end

        function stim = createLedStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.lightAmplitude;
            gen.mean = obj.lightMean;
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            stim = gen.generate();
        end
    end
end
```

---

## Writing a Stage (Visual) Protocol

Stage protocols inherit from `CommonStageProtocol` and must implement the abstract method `createPresentation()`, which returns a `stage.core.Presentation` object.

### Minimal Example: SingleSpot

```matlab
classdef SingleSpot < common.protocols.CommonStageProtocol
    % Presents a single spot stimulus on the Stage display.

    properties
        amp                             % Output amplifier
        preTime = 250                   % Leading duration (ms)
        stimTime = 250                  % Spot duration (ms)
        tailTime = 250                  % Trailing duration (ms)
        spotIntensity = 1.0             % Spot light intensity (0-1)
        spotDiameter = 300              % Spot diameter (um)
        backgroundIntensity = 0.5       % Background intensity (0-1)
        numberOfAverages = uint16(5)    % Number of epochs
    end

    methods
        function p = createPresentation(obj)
            device = obj.rig.getDevice('Stage');
            canvasSize = device.getCanvasSize();
            spotDiameterPix = device.um2pix(obj.spotDiameter);

            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);

            spot = stage.builtin.stimuli.Ellipse();
            spot.color = obj.spotIntensity;
            spot.radiusX = spotDiameterPix / 2;
            spot.radiusY = spotDiameterPix / 2;
            spot.position = canvasSize / 2;
            p.addStimulus(spot);

            spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', ...
                @(state)state.time >= obj.preTime * 1e-3 && ...
                        state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(spotVisible);
        end
    end
end
```

**Key points:**
- `interpulseInterval` is inherited from `CommonStageProtocol` (default 0.25 s), so you do not need to declare it unless you want a different default.
- `createPresentation()` must return a `stage.core.Presentation` with the total epoch duration.
- Use `device.um2pix()` to convert from microns to pixels.
- Visibility timing is controlled by `PropertyController` callbacks that receive a `state` struct with a `time` field (in seconds).
- The base class handles playing the presentation, waiting for the trigger, recording the frame monitor, and clearing Stage memory.

### Presentation Building Blocks

| Stage Class | Purpose |
|---|---|
| `stage.core.Presentation` | Container for stimuli and controllers; set duration and background. |
| `stage.builtin.stimuli.Ellipse` | Circle or ellipse stimulus. Set `radiusX`, `radiusY`, `color`, `position`. |
| `stage.builtin.stimuli.Rectangle` | Rectangle stimulus. Set `size`, `color`, `position`, `orientation`. |
| `stage.builtin.stimuli.Image` | Image stimulus from a matrix or file. |
| `stage.builtin.controllers.PropertyController` | Animate any stimulus property over time via a callback function. |

### Visibility Pattern

The standard pattern for controlling when a stimulus is visible during pre/stim/tail windows:

```matlab
visibleController = stage.builtin.controllers.PropertyController(stimulus, 'visible', ...
    @(state) state.time >= obj.preTime * 1e-3 && ...
             state.time < (obj.preTime + obj.stimTime) * 1e-3);
p.addController(visibleController);
```

---

## Advanced Patterns

### Parameterized Epochs (Varying a Parameter Across Trials)

Override `prepareEpoch` to cycle through parameter values:

```matlab
properties
    orientations = 0:30:330  % Degrees
end

methods
    function prepareEpoch(obj, epoch)
        prepareEpoch@common.protocols.CommonStageProtocol(obj, epoch);

        idx = mod(obj.numEpochsPrepared - 1, numel(obj.orientations)) + 1;
        epoch.addParameter('orientation', obj.orientations(idx));
    end

    function tf = shouldContinuePreparingEpochs(obj)
        tf = obj.numEpochsPrepared < obj.numberOfAverages * numel(obj.orientations);
    end

    function tf = shouldContinueRun(obj)
        tf = obj.numEpochsCompleted < obj.numberOfAverages * numel(obj.orientations);
    end
end
```

### Preview Support

Implement `getPreview` to show a stimulus preview in the Symphony UI:

```matlab
function p = getPreview(obj, panel)
    % For Stage protocols:
    p = io.github.stage_vss.previews.StagePreview(panel, ...
        @()obj.createPresentation(), ...
        'windowSize', obj.rig.getDevice('Stage').getCanvasSize());

    % For amplifier-based protocols:
    p = symphonyui.builtin.previews.StimuliPreview(panel, ...
        @()obj.createAmpStimulus());
end
```

### Overriding Default Figures

To suppress the default figures and show only your own:

```matlab
function prepareDefaultFigures(obj)
    % Empty: no default figures
end

function prepareRun(obj)
    prepareRun@common.protocols.CommonProtocol(obj);
    % Show only custom figures
    obj.showFigure('my.custom.Figure', obj.rig.getDevice(obj.amp));
end
```

### Dual Amplifier Support

The base class automatically detects a second amplifier. Access it via `obj.amp2`:

```matlab
if ~strcmp(obj.amp2, '(None)')
    epoch.addResponse(obj.rig.getDevice(obj.amp2));
end
```

---

## Conventions and Best Practices

1. **Property comments become UI labels.** The text after `%` on a property line is displayed in the Symphony parameter editor. Keep it short and include units.

2. **Time properties are in milliseconds.** `preTime`, `stimTime`, and `tailTime` are always in ms. Convert to seconds (`* 1e-3`) when passing to Stage or stimulus generators.

3. **Spatial properties are in microns.** Use `device.um2pix()` for conversion to screen pixels.

4. **Always call the superclass method first.** When overriding `prepareRun`, `prepareEpoch`, `didSetRig`, etc., always call the parent method before your own logic.

5. **Use `uint16` for `numberOfAverages`.** This makes it render as an integer spinner in the Symphony UI rather than a floating-point text box.

6. **Namespace your protocol.** Place protocol files in `+common/+protocols/` so they are accessible as `common.protocols.YourProtocol`.

7. **One protocol per file.** The file name must match the class name.

8. **Keep protocols focused.** Each protocol should implement one stimulus paradigm. Share common logic by extracting it into the base class or utility functions in `+common/+util/`.

---

## Validation and Testing

The common-package includes a unit testing framework in `test/`. Before committing a new protocol, run:

```matlab
cd test
runProtocolTests
```

The test suite validates that every protocol in `+common/+protocols/`:
- Can be instantiated without errors (using MATLAB metaclass introspection).
- Defines all required abstract properties (`amp`, `preTime`, `stimTime`, `tailTime`, `numberOfAverages`, `interpulseInterval`).
- Inherits from `common.protocols.CommonProtocol`.
- Stage protocols additionally inherit from `CommonStageProtocol` and implement `createPresentation`.

See `spec/specs/protocol-structure.md` for the full structural specification that tests are derived from.
