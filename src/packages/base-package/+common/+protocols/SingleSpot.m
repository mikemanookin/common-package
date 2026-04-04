classdef SingleSpot < common.protocols.CommonStageProtocol
    % Presents a set of single spot stimuli to a Stage canvas and records from the specified amplifier.
    
    properties
        amp                             % Output amplifier
        preTime = 250                   % Spot leading duration (ms)
        stimTime = 250                  % Spot duration (ms)
        tailTime = 250                  % Spot trailing duration (ms)
        spotIntensity = 1.0             % Spot light intensity (0-1)
        spotDiameter = 300              % Spot diameter size (um)
        psth = true
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(5)    % Number of epochs
    end
    
    methods
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getCanvasSize());
        end
        
        function p = createPresentation(obj)
            device = obj.rig.getDevice('Stage');
            canvasSize = device.getCanvasSize();
            
            spotDiameterPix = device.um2pix(obj.spotDiameter);
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.color = obj.spotIntensity;
            spot.radiusX = spotDiameterPix/2;
            spot.radiusY = spotDiameterPix/2;
            spot.position = canvasSize/2;
            p.addStimulus(spot);
            
            spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', ...
                @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(spotVisible);
        end
    end
    
end

