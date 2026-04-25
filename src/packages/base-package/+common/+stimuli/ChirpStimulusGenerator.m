% Generates a 'chirp' stimulus as used by Thomas Euler - light increments
% and decrements, followed by frequency sweep, followed by contrast sweep

classdef ChirpStimulusGenerator < symphonyui.core.StimulusGenerator

    
    properties
        preTime % Pre-stimulus duration (ms)
        tailTime % Post-stimulus duration (ms)
        stepTime                   % Step duration (ms)
        frequencyTime           % Frequency sweep duration (ms)
        contrastTime             % Contrast sweep duration (ms)
        interTime               % Duration between stimuli (ms)
        stepContrast              % Step contrast (0 - 1)
        frequencyContrast        % Contrast during frequency sweep (0-1)
        frequencyMin            % Minimum temporal frequency (Hz)
        frequencyMax             % Maximum temporal frequency (Hz)
        contrastMin             % Minimum contrast (0-1)
        contrastMax              % Maximum contrast (0-1)
        contrastFrequency         % Temporal frequency of contrast sweep (Hz)
        backgroundIntensity        % Background light intensity (0-1)
        
        sampleRate          % Sample rate of generated stimulus (Hz)
        units               % Units of generated stimulus
        
    end

    methods
        
        function obj = ChirpStimulusGenerator(map)
            if nargin < 1
                map = containers.Map();
            end
            obj@symphonyui.core.StimulusGenerator(map);
        end
        
    end

    methods (Access = protected)
        
        function s = generateStimulus(obj)
            
            import Symphony.Core.*;

            timeToPts = @(t)(round(t / 1e3 * obj.sampleRate));
            ptsToTime = @(p)(p / obj.sampleRate); % in sec
                       
            totTime = obj.preTime+obj.tailTime+obj.interTime*3 + obj.stepTime*2 + obj.frequencyTime + obj.contrastTime;
            totPts = timeToPts(totTime);
            stim = ones(1, totPts);
            stim(1:totPts) = obj.backgroundIntensity;

            prePts = timeToPts(obj.preTime);
            tailPts = timeToPts(obj.tailTime);
            interPts = timeToPts(obj.interTime);
            stepPts = timeToPts(obj.stepTime);
            freqPts = timeToPts(obj.frequencyTime);
            contrastPts = timeToPts(obj.contrastTime);

            frequencyDelta = (obj.frequencyMax - obj.frequencyMin)/freqPts/2; % not sure why factor of 2 needed but gets frequencies right
            contrastDelta = (obj.contrastMax - obj.contrastMin)/contrastPts;

            % increment and decrement steps
            stim(prePts+(1:stepPts)) = stim(prePts+(1:stepPts)) + obj.stepContrast * obj.backgroundIntensity;
            stim(prePts+interPts+stepPts+(1:stepPts)) = stim(prePts+interPts+stepPts+(1:stepPts)) - obj.stepContrast * obj.backgroundIntensity;

            % frequency sweep
            for t = 1:freqPts
                stim(t + prePts+interPts*2+stepPts*2) = obj.frequencyContrast*obj.backgroundIntensity*sin(2*pi*ptsToTime(t)*(obj.frequencyMin+frequencyDelta*t)) + obj.backgroundIntensity;
            end
            
            % contrast sweep
            for t = 1:contrastPts
                stim(t + prePts + interPts*3+stepPts*2+freqPts) = (obj.contrastMin+t*contrastDelta)*obj.backgroundIntensity*sin(2*pi*ptsToTime(t)*obj.contrastFrequency) + obj.backgroundIntensity;
            end               
            
            parameters = obj.dictionaryFromMap(obj.propertyMap);
            measurements = Measurement.FromArray(stim, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
                        
            cobj = RenderedStimulus(class(obj), parameters, output);
            s = symphonyui.core.Stimulus(cobj);
        end
        
    end
    
end
