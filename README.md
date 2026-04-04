# common-package
Common package for Symphony protocols to be shared across collaborating labs.


## Protocol Class Structure
```md
Symphony Core Protocol (symphonyui.core.Protocol)
└── Common Lab Protocols (common.protocols.CommonProtocol)
    ├── Non-Stage Protocols (e.g. LED stimulus; current injection)
    └── Stage Protocols (common.protocols.CommonStageProtocol)
```

## Philosophy
All protocols that run on both patch and MEA rigs havce common needs and properties. These commonalities should be instantiated at the highest level possible so that they are inherited by protocols lower in the hierarchy. If done properly, this can significantly reduce the burden for the end user who is trying to create a protocol.

All shared Symphony protocols need to implement several common elements. For example:

* Detect whether the protocol is being run on an MEA or patch rig.
* Implement the appropriate online analysis figures.

Furthermore, several common Protocol properties need to be used in order to maintain continuity between the patch and MEA data acquisition pipelines. These properties have been implemented as abstract properties which forces all inheriting classes to implement them.

```matlab
    properties (Abstract)
        amp
        preTime
        stimTime
        tailTime
        numberOfAverages
        interpulseInterval
    end
```
If a user wants to use other designations, they are free to do so, but they must still implement the abstract parameters. A common example of this is 'stimTime'. If I wanted to use another set of properties for designating how the stimulus was delivered, such as paired flashes with a time in between, I could implement 'stimTime' as a dependent property. For example:

```matlab
    properties
        amp
        preTime = 250
        flashTime1 = 100
        interFlashTime = 500
        flashTime2 = 100
        tailTime = 1000
        numberOfAverages = 10
    end
    properties (Dependent)
        stimTime
    end
    methods
        % Getter method for stimTime
        function t = get.stimTime(obj)
            t = obj.flashTime1 + obj.interFlashTime + obj.flashTime2;
        end
    end
```

Similarly, all Stage (visual stimulus) protocols share commonalities, which should be implemented in the superclass for those protocols. These commonalities include:

* Check for and record the frame monitor.
* Confirm that Stage is connected to the rig.
* Pass the visual stimulus to Stage
* Clear Stage memory of stimulus following presentation.

All of these functions *could* be implemented in individual protocols, but they *should* be implemented in a superclass and inherited if done properly. 

I have combined much of the functionality in RiekeLabProtocol, RiekeLabStageProtocol, and ManookinLabProtocol. I have also cleaned up that code and added more functionality.

For example, the new `SingleSpot` stimulus, which maintains exactly the same functionality as the old protocol, has gone from 106 lines of code to 49 lines (including spaces). It now consists essentially of (1) defining a set of protocol parameters and (2) implementing the `createPresentation` method to implement the stimulus.
