classdef NiDaqTest < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = NiDaqTest()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq_names = {'Dev2','Dev1','Dev3'};
            % daq_names = 'Dev2';
            % Dev2: Pcie-6323; Dev1,3: 6374
            daq = NiDaqController(daq_names); %daq = NiDaqController('Dev2');
            obj.daqController = daq;
            
            if iscell(daq_names)
                channel_prefix = [daq_names{1},'_'];
            else
                channel_prefix = '';
            end
            
            amp1 = MultiClampDevice('Amp1', 1, []).bindStream(daq.getStream([channel_prefix,'ao0'])).bindStream(daq.getStream([channel_prefix,'ai0']));
            obj.addDevice(amp1);

            % List the streams.
            % streams = daq.getStreams();
            % for i = 1:numel(streams)
            %     disp(streams{i});
            % end
            
            amp2 = MultiClampDevice('Amp2', 2, []).bindStream(daq.getStream([channel_prefix,'ao1'])).bindStream(daq.getStream([channel_prefix,'ai1']));
            obj.addDevice(amp2);
            
            green = UnitConvertingDevice('Green LED', 'V').bindStream(daq.getStream([channel_prefix,'ao2']));
            green.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            green.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(green);
            % 
            % blue = UnitConvertingDevice('Blue LED', 'V').bindStream(daq.getStream('ao3'));
            % blue.addConfigurationSetting('ndfs', {}, ...
            %     'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            % blue.addConfigurationSetting('gain', '', ...
            %     'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            % obj.addDevice(blue);
            
            % Digital streams represent digital ports not individual digital lines. A port is a collection of lines. A 
            % line is an individual signal that carries bit values (0s and 1s). To associate a device with a line you 
            % must first bind the device to the port (i.e. stream), and then associate the device with a bit position 
            % that signifies a line within the port.
            trigger1 = UnitConvertingDevice('Trigger1', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream([channel_prefix,'doport0']));
            daq.getStream([channel_prefix,'doport0']).setBitPosition(trigger1, 0);
            obj.addDevice(trigger1);
            
            trigger2 = UnitConvertingDevice('Trigger2', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream([channel_prefix,'doport0']));
            daq.getStream([channel_prefix,'doport0']).setBitPosition(trigger2, 2);
            obj.addDevice(trigger2);
        end
        
    end
    
end

