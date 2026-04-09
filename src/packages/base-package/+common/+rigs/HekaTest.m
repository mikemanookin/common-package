classdef HekaTest < symphonyui.core.descriptions.RigDescription
    
    methods
        function obj = HekaTest()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController();
            obj.daqController = daq;
            daq = obj.daqController;

            %% Streaming tests
            % Enable streaming for long epochs (add at end of constructor)
            daq.cobj.StreamingThreshold = System.TimeSpan.FromSeconds(5);
            
            % Disable streaming entirely (optional)
            % daq.cobj.StreamingThreshold = [];

            % disp(obj.daqController.cobj.StreamingThreshold);
            %%
            
            % MultiClamp device.
            amp1 = MultiClampDevice('Amp1', 1).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);

            green = UnitConvertingDevice('Green LED', 'V').bindStream(daq.getStream('ao2'));
            green.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'E1', 'E2', 'E3', 'E4', 'E5', 'E8', 'E9', 'E12'}));
            green.addResource('ndfAttenuations', containers.Map( ...
                {'E1', 'E2', 'E3', 'E4', 'E5', 'E8', 'E9', 'E12'}, ...
                {0.26, 0.58, 0.93, 2.19, 4.11, 1.85, 3.8, 0.3}));
            green.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            green.addConfigurationSetting('lightPath', '', ...
                'type', PropertyType('char', 'row', {'', 'below', 'above'}));
            obj.addDevice(green);

            % Water bath.
            temperature = UnitConvertingDevice('Temperature Controller', 'V', 'manufacturer', 'Warner Instruments').bindStream(daq.getStream('ai7'));
            obj.addDevice(temperature);
            
            % Add the frame monitor
            frameMonitor = UnitConvertingDevice('Frame Monitor', 'V').bindStream(obj.daqController.getStream('ai2'));
            obj.addDevice(frameMonitor);
            
            trigger = UnitConvertingDevice('Oscilloscope Trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
            
            
            % Add the red syncs (240 Hz)
%             red_sync = UnitConvertingDevice('Red Sync', 'V').bindStream(obj.daqController.getStream('ai4'));
%             obj.addDevice(red_sync);
            
            % SciScan Trigger.
%             trigger2 = UnitConvertingDevice('SciScan Trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
%             daq.getStream('doport1').setBitPosition(trigger2, 1);
%             obj.addDevice(trigger2);
        end
    end
    
end
