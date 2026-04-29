classdef (Abstract) CommonStageProtocol < common.protocols.CommonProtocol
    
    properties
        interpulseInterval = 0.25          % Duration between Epochs (s)
    end

    properties (Hidden)
        stageClass
        frameRate
        canvasSize
        labName
    end
    
    % Hidden (default public Get/Set) instead of `Access = protected`
    % to avoid R2024b/macOS MCOS protected-property-read SEGV on the
    % .NET Engine API path. Same rationale as
    % symphonyui.core.Protocol's counters; see ADR-0007.
    properties (Hidden)
        waitingForHardwareToStart
    end

    properties (Dependent, Hidden, SetAccess = private)
        frameMonitor % Frame monitor
    end
    
    methods (Abstract)
        p = createPresentation(obj);
    end
    
    methods

        function prepareRun(obj)
            prepareRun@common.protocols.CommonProtocol(obj);
            
            % Get the frame rate. Need to check if it's a LCR rig.
            if ~isempty(strfind(obj.rig.getDevice('Stage').name, 'LightCrafter'))
                obj.frameRate = obj.rig.getDevice('Stage').getPatternRate();
                obj.stageClass = 'LightCrafter';
            elseif ~isempty(strfind(obj.rig.getDevice('Stage').name, 'LcrRGB'))
                obj.frameRate = obj.rig.getDevice('Stage').getMonitorRefreshRate();
                obj.stageClass = 'LcrRGB';
            else
                obj.frameRate = obj.rig.getDevice('Stage').getMonitorRefreshRate();
                obj.stageClass = 'Video';
            end
            
            rigDev = obj.rig.getDevices('rigProperty');
            if ~isempty(rigDev)
                obj.labName = rigDev{1}.getConfigurationSetting('laboratory');
            else
                obj.labName = 'RiekeLab';
            end
            
            % Get the canvas size.
            obj.canvasSize = obj.rig.getDevice('Stage').getCanvasSize();  
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@common.protocols.CommonProtocol(obj, epoch);

            obj.waitingForHardwareToStart = true;

            % Trigger / TTL synchronization is DAQ-pipeline only.
            % `epoch.shouldWaitForTrigger = true` writes through to
            % the .NET Symphony.Core.Epoch cobj, which doesn't exist
            % in a meaningful way on Mac/Linux. Same for the
            % projector_gain background poke below. See ADR-0007.
            if ispc
                epoch.shouldWaitForTrigger = true;
            end

            % Add the frame monitor response.
            if ~isempty(obj.frameMonitor)
                epoch.addResponse(obj.frameMonitor);
            end

            redSync = obj.rig.getDevices('Red Sync');
            if ~isempty(redSync)
                epoch.addResponse(redSync{1});
            end

            if ispc
                projector_gain = obj.rig.getDevices('Projector Gain');
                if ~isempty(projector_gain)
                    projector_gain{1}.background = symphonyui.core.Measurement(1, projector_gain{1}.background.displayUnits);
                    projector_gain{1}.applyBackground();
                end
            end
        end

        % Additional figures specific to Stage protocols.
        function prepareDefaultFigures(obj)
            prepareDefaultFigures@common.protocols.CommonProtocol(obj);

            % Add the frame monitor figure if it's in the rig config.
            if ~isempty(obj.frameMonitor)
                obj.showFigure('symphonyui.builtin.figures.FrameTimingFigure', obj.rig.getDevice('Stage'), obj.frameMonitor);
            end
        end

        function controllerDidStartHardware(obj)
            controllerDidStartHardware@common.protocols.CommonProtocol(obj);
            
            if obj.waitingForHardwareToStart
                obj.waitingForHardwareToStart = false;
                try
                    dev = obj.rig.getDevice('Stage');
                    dev.play(obj.createPresentation());
                catch ex
                    fprintf(2, 'Stage play FAILED: %s\n', ex.message);
                end
            end
        end
        
        function tf = shouldContinuePreloadingEpochs(obj) %#ok<MANU>
            tf = false;
        end
        
        function tf = shouldWaitToContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared > obj.numEpochsCompleted || obj.numIntervalsPrepared > obj.numIntervalsCompleted;
        end

        % Check for a frame monitor and set up if present in rig config.
        function a = get.frameMonitor(obj)
            a = obj.rig.getDevice('Frame Monitor');
        end
        
        function completeRun(obj)
            completeRun@common.protocols.CommonProtocol(obj);

            % Clearing the Stage device's memory only matters for a
            % real DAQ run; on Mac/Linux it can be skipped (the
            % Stage device's `clearMemory` reaches into the .NET
            % cobj). Wrap defensively.
            if ispc
                try
                    obj.rig.getDevice('Stage').clearMemory();
                catch
                end
            end
        end
        
        function [tf, msg] = isValid(obj)
            [tf, msg] = isValid@common.protocols.CommonProtocol(obj);
            if tf
                tf = ~isempty(obj.rig.getDevices('Stage'));
                msg = 'No stage';
            end
        end
        
    end
    
end

