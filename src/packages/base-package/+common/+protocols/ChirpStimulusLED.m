classdef ChirpStimulusLED < common.protocols.CommonProtocol
    % Presents a chirp stimulus ala Euler to a specified LED and records from a specified amplifier.
    
    properties
        led                             % Output LED
        amp                             % Input amplifier
        preTime     = 250           % Pre time in ms
        tailTime    = 250           % Tail time in ms
        stepTime = 500                  % Step duration (ms)
        frequencyTime = 15000           % Frequency sweep duration (ms)
        contrastTime = 8000             % Contrast sweep duration (ms)
        interTime = 500                % Duration between stimuli (ms)
        stepContrast = 1.0              % Step contrast (0 - 1)
        frequencyContrast = 1.0         % Contrast during frequency sweep (0-1)
        frequencyMin = 0.0              % Minimum temporal frequency (Hz)
        frequencyMax = 10.0             % Maximum temporal frequency (Hz)
        contrastMin = 0.02              % Minimum contrast (0-1)
        contrastMax = 1.0               % Maximum contrast (0-1)
        contrastFrequency = 2.0         % Temporal frequency of contrast sweep (Hz)
        backgroundIntensity = 1.0       % Background light intensity (0-5)
        psth = false;                   % Toggle psth in mean response figure
        onlineAnalysis = 'extracellular'         % Online analysis type.
    end
    
    properties
        numberOfAverages = uint16(3)    % Number of epochs
        interpulseInterval = 0          % Duration between pulses (s)
    end

    properties (Dependent) 
        stimTime
    end
    
    properties (Hidden)
        ledType
        onlineAnalysisType = symphonyui.core.PropertyType('char', 'row', {'none', 'extracellular', 'spikes_CClamp', 'subthresh_CClamp', 'analog'})
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@common.protocols.CommonProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
        end
        
        % function d = getPropertyDescriptor(obj, name)
        %     d = getPropertyDescriptor@common.protocols.CommonProtocol(obj, name);
        % 
        %     if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
        %         d.isHidden = true;
        %     end
        % end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createChirpStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@common.protocols.CommonProtocol(obj);
            
            device = obj.rig.getDevice(obj.led);
            device.background = symphonyui.core.Measurement(obj.backgroundIntensity, device.background.displayUnits);
        end
        
        function stim = createChirpStimulus(obj)
            gen = common.stimuli.ChirpStimulusGenerator();
                        
            gen.preTime = obj.preTime;
            gen.tailTime = obj.tailTime;
            gen.stepTime = obj.stepTime;
            gen.frequencyTime = obj.frequencyTime;
            gen.contrastTime = obj.contrastTime;
            gen.interTime = obj.interTime;
            gen.frequencyContrast = obj.frequencyContrast;
            gen.stepContrast = obj.stepContrast;
            gen.frequencyMin = obj.frequencyMin;
            gen.frequencyMax = obj.frequencyMax;
            gen.contrastMin = obj.contrastMin;
            gen.contrastMax = obj.contrastMax;
            gen.contrastFrequency = obj.contrastFrequency;
            gen.backgroundIntensity = obj.backgroundIntensity;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.led).background.displayUnits;
            
            stim = gen.generate();
        
        end
               
        function prepareEpoch(obj, epoch)
            prepareEpoch@common.protocols.CommonProtocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createChirpStimulus());
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@common.protocols.CommonProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.led);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end

        function stimTime = get.stimTime(obj)
            stimTime = obj.interTime*3 + obj.stepTime*2 + obj.frequencyTime + obj.contrastTime;
        end
    end
end
