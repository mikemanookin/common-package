classdef SimulatedStage < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = SimulatedStage()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            % daq = HekaDaqController();
            obj.daqController = daq;
            
            % Rig name and laboratory.
            rigDev = RigPropertyDevice('ManookinLab','SimulatedStage');
            obj.addDevice(rigDev);
            
            % Simulated device to bypass Multiclamp on MEA or simulation
            % amp1 =  SimulatedAnalogDevice('Amp1', 1).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            % MultiClamp device.
            amp1 = MultiClampDevice('Amp1', 1).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);

            % Stage
            % stage = VideoDevice(...
            %     'host', 'ELMATADOR-PC', ...
            %     'micronsPerPixel', 1.0);
            stage = VideoDevice(...
                'host', 'localhost',...
                'micronsPerPixel', 1.0);
            obj.addDevice(stage);

            % Add an analog trigger device to simulate the MEA.
            trigger = UnitConvertingDevice('ExternalTrigger', 'V').bindStream(daq.getStream('ao1'));
            obj.addDevice(trigger);
            
            green = UnitConvertingDevice('Green LED', 'V').bindStream(daq.getStream('ao2'));
            green.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            green.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(green);
            
            blue = UnitConvertingDevice('Blue LED', 'V').bindStream(daq.getStream('ao3'));
            blue.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            blue.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(blue);
            
%              trigger1 = UnitConvertingDevice('Trigger1', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
%             daq.getStream('doport1').setBitPosition(trigger1, 0);
%             obj.addDevice(trigger1);
%             
%             trigger2 = UnitConvertingDevice('Trigger2', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
%             daq.getStream('doport1').setBitPosition(trigger2, 2);
%             obj.addDevice(trigger2);
            
            frameMonitor = UnitConvertingDevice('Frame Monitor', 'V').bindStream(obj.daqController.getStream('ai2'));
            obj.addDevice(frameMonitor);
            
            
            
        end
    end
    
end

