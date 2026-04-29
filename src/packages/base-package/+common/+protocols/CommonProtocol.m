% CommonProtocol.m

classdef (Abstract) CommonProtocol < symphonyui.core.Protocol
    
    % These properties are imposed across all protocols that inherit from
    % this master protocol. The reason is that they are required for
    % successfully synchronizing the DAQ clocks across both patch and MEA
    % rigs and also for maintaining continuity (e.g., to run on a patch
    % rig, an Amplifier (amp) must be defined).
    properties (Abstract)
        amp
        preTime
        stimTime
        tailTime
        numberOfAverages
        interpulseInterval
    end

    properties (Hidden, SetAccess = private)
        meaFileName
        isMeaRig
        startedRun
    end

    properties (Hidden)
        ampType
    end

    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
    
    methods

        function didSetRig(obj)
            didSetRig@symphonyui.core.Protocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end

        function prepareRun(obj)
            prepareRun@symphonyui.core.Protocol(obj);

            obj.startedRun = false;

            obj.isMeaRig = false; % Default
            % Check if this is an MEA rig.
            mea = obj.rig.getDevices('MEA');
            if ~isempty(mea)
                obj.isMeaRig = true;
            end

            % Default figures (Response, MeanResponse, Progress, etc.)
            % depend on captured DAQ responses, which only exist on
            % Windows where the rig actually acquires. Skip on
            % Mac/Linux — those platforms are protocol-development /
            % data-review-only (see ADR-0007).
            if ispc
                obj.prepareDefaultFigures();
            end
        end

        function prepareEpoch(obj, epoch)
            prepareEpoch@symphonyui.core.Protocol(obj, epoch);

            if ~ispc
                return;
            end

            % Add device reponses to the Epoch.
            obj.addDeviceReponsesToEpoch(epoch);

            % Amp DC stimulus + response: DAQ-pipeline only. Reading
            % `device.background` inside addAmpResponsesToEpoch
            % evaluates the amp device's .NET cobj.Background getter,
            % which has SEGV'd MATLAB R2024b on macOS. Mac/Linux are
            % protocol-development platforms with no DAQ acquisition;
            % skip the whole branch (see ADR-0007 platform-roles).
            if ispc
                obj.addAmpResponsesToEpoch(epoch);
            end

            % This is for the MEA setup. Check if this is an MEA rig on the
            % first epoch.
            if ~obj.startedRun
                obj.startedRun = true;
                obj.isMeaRig = false; % Default
                obj.meaFileName = ''; % Default

                % MEA detection touches a real hardware device — skip
                % off-Windows (no MEA on a development laptop).
                if ispc
                    mea = obj.rig.getDevices('MEA');
                    if ~isempty(mea)
                        obj.isMeaRig = true;

                        mea = mea{1};
                        % Try to pull the output file name from the server.
%                         fname = mea.getFileName(30);

                        % New tests:
                        mea.start();
                        fname = char(mea.fileName);

                        if ~isempty(fname)
                            obj.meaFileName = char(fname);
                        else
                            obj.meaFileName = '';
                        end

                        % Persist the file name
                        if ~isempty(fname) && ~isempty(obj.persistor)
                            try
                                eb = obj.persistor.currentEpochBlock;
                                if ~isempty(eb)
                                    eb.setProperty('dataFileName', char(fname))
                                end
                            catch
                            end
                        end
                    end
                end
            end

            % Persist the file name to the epoch if it's an MEA rig.
            if obj.isMeaRig
                try
                    epoch.addParameter('dataFileName', obj.meaFileName);

                    % Create the external trigger to the MEA DAQ.
                    triggers = obj.rig.getDevices('ExternalTrigger');
                    if ~isempty(triggers)
                        epoch.addStimulus(triggers{1}, obj.createTriggerStimulus(triggers{1}));
                    end
                catch ME
                    disp(ME.message);
                end
            end
        end

        %------------------------------------------------------------------
        % Set up the amplifiers for recording.
        % 
        % Override this method to do something special with the amps.
        function addAmpResponsesToEpoch(obj, epoch)
            % Get amplifier names.
            % amps = obj.rig.getDeviceNames('Amp');
            amps = obj.rig.getDevices('Amp');
            
            % Add each amplifier
            for k = 1 : numel(amps)
                device = amps{k};
                epoch.addDirectCurrentStimulus(device, device.background, ...
                    (obj.preTime + obj.stimTime + obj.tailTime) * 1e-3, obj.sampleRate);
                epoch.addResponse( device );
            end
        end

        % Add responses to the Epoch from other devices. Customize as
        % desired.
        function addDeviceReponsesToEpoch(obj, epoch)
            controllers = obj.rig.getDevices('Temperature Controller');
            if ~isempty(controllers)
                epoch.addResponse(controllers{1});
            end
            
            wvfrm = obj.rig.getDevices('Waveform Generator');
            if ~isempty(wvfrm)
                epoch.addResponse(wvfrm{1});
            end
        end
        
        % Add interval stimuli (between Epochs) to the Amps. Override to do
        % something special.
        function prepareInterval(obj, interval)
            prepareInterval@symphonyui.core.Protocol(obj, interval);

            % DAQ-only — see addAmpResponsesToEpoch comment in
            % prepareEpoch above. Skip on Mac/Linux.
            if ~ispc
                return;
            end

            % Get the amplfiers.
            amps = obj.rig.getDevices('Amp');

            % Add each amplifier
            for k = 1 : length(amps)
                device = obj.rig.getDevice(amps{k}.name);
                interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
            end
        end

        % Prepare the default analysis figures. Override this method with
        % an empty method to prevent figures from showing.
        function prepareDefaultFigures(obj)
            % Common Figure Handlers.
            if ~obj.isMeaRig
                if numel(obj.rig.getDeviceNames('Amp')) < 2
                    try
                        dev = obj.rig.getDevice(obj.amp);
                        obj.showFigure('symphonyui.builtin.figures.ResponseFigure', dev);
                    catch ex
                        fprintf(2, 'prepareDefaultFigures: ResponseFigure failed: %s\n', ex.message);
                    end
                    try
                        dev = obj.rig.getDevice(obj.amp);
                        obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', dev);
                    catch ex
                        fprintf(2, 'prepareDefaultFigures: MeanResponseFigure failed: %s\n', ex.message);
                    end
                else
                    try
                        obj.showFigure('symphonyui.builtin.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                    catch ex
                        fprintf(2, 'prepareDefaultFigures: DualResponseFigure failed: %s\n', ex.message);
                    end
                    try
                        obj.showFigure('symphonyui.builtin.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                    catch ex
                        fprintf(2, 'prepareDefaultFigures: DualMeanResponseFigure failed: %s\n', ex.message);
                    end
                end
            end
            % Show the progress bar.
            obj.showFigure('symphonyui.builtin.figures.ProgressFigure', obj.numberOfAverages);
        end

        % This method generates a trigger that goes high throughout the
        % course of an Epoch and is sent to the Litke/MEA DAQ board to
        % synchronize the MEA and Symphony DAQ clocks.
        function stim = createTriggerStimulus(obj, trigger_device)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            if strcmp(trigger_device.background.displayUnits,'V') 
                amplitude = 5;
                units = 'V';
            else
                amplitude = 1;
                units = symphonyui.core.Measurement.UNITLESS;
            end
            
            % Ensure that pre/stim/tail time are defined.
            if isprop(obj, 'preTime')
                preT = obj.preTime;
            else
                preT = 50;
            end
            
            if isprop(obj, 'tailTime')
                tailT = obj.tailTime;
            else
                tailT = 50;
            end
            
            if isprop(obj, 'stimTime')
                stimT = obj.stimTime;
            else
                stimT = 0;
            end
            total_time = max(100, preT + stimT + tailT);
            
            gen.preTime = 0;
            gen.stimTime = total_time - 1;
            gen.tailTime = 1;
            gen.amplitude = amplitude;
            gen.mean = 0;
            gen.sampleRate = obj.sampleRate;
            gen.units = units; %symphonyui.core.Measurement.UNITLESS;
            
            stim = gen.generate();
        end

        % Check for second amplifier and set up if present in rig config.
        function a = get.amp2(obj)
            amps = obj.rig.getDeviceNames('Amp');
            if numel(amps) < 2
                a = '(None)';
            else
                i = find(~ismember(amps, obj.amp), 1);
                a = amps{i};
            end
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@symphonyui.core.Protocol(obj, epoch);

            % Reading captured response data is DAQ-only — Mac/Linux
            % don't acquire, so there's nothing to read.
            if ~ispc
                return;
            end

            controllers = obj.rig.getDevices('Temperature Controller');
            if ~isempty(controllers) && epoch.hasResponse(controllers{1})
                response = epoch.getResponse(controllers{1});
                [quantities, units] = response.getData();
                if ~strcmp(units, 'V')
                    error('Temperature Controller must be in volts');
                end

                % Temperature readout from Warner TC-324B controller 100 mV/degree C.
                temperature = mean(quantities) * 1000 * (1/100);
                temperature = round(temperature * 10) / 10;
                epoch.addProperty('bathTemperature', temperature);

                epoch.removeResponse(controllers{1});
            end
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
    end
    
end

