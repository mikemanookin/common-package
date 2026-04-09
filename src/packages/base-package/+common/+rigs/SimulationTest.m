classdef SimulationTest < symphonyui.core.descriptions.RigDescription
    
    methods
        function obj = SimulationTest()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;

            daq = HekaSimulationDaqController();
            obj.daqController = daq;
            daq = obj.daqController;
            
            % Simulated device to bypass Multiclamp on MEA or simulation
            amp1 =  SimulatedAnalogDevice('Amp1', 1).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            % MultiClamp device.
            % amp1 = MultiClampDevice('Amp1', 1).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);

            green = UnitConvertingDevice('Green LED', 'V').bindStream(daq.getStream('ao1'));
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
