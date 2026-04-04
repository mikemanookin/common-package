classdef NiDaqWithSimulatedAmp < symphonyui.core.descriptions.RigDescription
    % Example rig configuration using a simulated amplifier device.
    %
    % The simulated amp allows protocols that expect an 'Amp' device to run
    % without consuming physical analog I/O channels. Only the LED uses
    % real DAQ channels.
    %
    % This is useful for:
    %   - Rigs where the amplifier is not connected but you still want to
    %     run LED protocols that reference an amp for response recording
    %   - Testing/development without hardware
    %   - Freeing up analog channels for other uses
    
    methods
        
        function obj = NiDaqWithSimulatedAmp()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            % Initialize the DAQ controller (works with NI or Heka)
            daq = NiDaqController('Dev2');
            obj.daqController = daq;
            
            % Simulated amplifier — no physical channels used.
            % Protocols can call rig.getDevice('Amp1') and it works normally.
            % Stimuli sent to this device are discarded.
            % Responses from this device are zero-valued.
            amp1 = SimulatedAmplifierDevice('Amp1', daq);
            obj.addDevice(amp1);
            
            % Real LED on a physical output channel
            green = UnitConvertingDevice('Green LED', 'V').bindStream(daq.getStream('ao0'));
            green.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            green.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(green);
            
            blue = UnitConvertingDevice('Blue LED', 'V').bindStream(daq.getStream('ao1'));
            blue.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            blue.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(blue);
            
            % Digital trigger — real hardware
            trigger1 = UnitConvertingDevice('Trigger1', Measurement.UNITLESS).bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(trigger1, 0);
            obj.addDevice(trigger1);
        end
        
    end
    
end
