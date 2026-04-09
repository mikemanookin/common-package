classdef DeviceConfigurator < symphonyui.ui.Module
    % Configures NDFs, gain, and light path for LED and Stage devices.

    properties (Access = private)
        settings
        leds
        stage
        deviceListeners

        % UI sections
        ndfsPanel
        ndfsListboxes       % containers.Map: deviceName → uilistbox
        gainPanel
        gainButtonGroups    % containers.Map: deviceName → uibuttongroup
        lightPathPanel
        lightPathDropdown
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'Device Configurator';
            figureHandle.Position(3:4) = [340 350];

            mainGrid = uigridlayout(figureHandle, [3 1]);
            mainGrid.RowHeight = {'fit', 'fit', 'fit'};
            mainGrid.Padding = [6 6 6 6];
            mainGrid.RowSpacing = 4;

            % NDF section
            obj.ndfsPanel = uipanel(mainGrid, 'Title', 'NDFs');
            % Gain section
            obj.gainPanel = uipanel(mainGrid, 'Title', 'Gain');
            % Light Path section
            obj.lightPathPanel = uipanel(mainGrid, 'Title', 'Light Path');
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.DeviceConfiguratorSettings();
            obj.leds = obj.configurationService.getDevices('LED');
            stages = obj.configurationService.getDevices('Stage');
            obj.stage = [];
            if ~isempty(stages)
                obj.stage = stages{1};
            end

            obj.populateNdfsPanel();
            obj.populateGainPanel();
            obj.populateLightPathPanel();

            try
                if ~isempty(obj.settings.viewPosition)
                    obj.figureHandle.Position = obj.settings.viewPosition;
                end
            catch
            end
        end

        function willStop(obj)
            try
                obj.settings.viewPosition = obj.figureHandle.Position;
                obj.settings.save();
            catch
            end
        end

        function bind(obj)
            bind@symphonyui.ui.Module(obj);
            obj.bindDevices();
            c = obj.configurationService;
            obj.addListener(c, 'InitializedRig', @obj.onServiceInitializedRig);
        end

    end

    methods (Access = private)

        function d = allDevices(obj)
            d = obj.leds;
            if ~isempty(obj.stage)
                d = [d {obj.stage}];
            end
        end

        function bindDevices(obj)
            obj.deviceListeners = {};
            d = obj.allDevices();
            for i = 1:numel(d)
                obj.deviceListeners{end+1} = obj.addListener(d{i}, 'AddedConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
                obj.deviceListeners{end+1} = obj.addListener(d{i}, 'SetConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
                obj.deviceListeners{end+1} = obj.addListener(d{i}, 'RemovedConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
            end
        end

        function unbindDevices(obj)
            while ~isempty(obj.deviceListeners)
                obj.removeListener(obj.deviceListeners{1});
                obj.deviceListeners(1) = [];
            end
        end

        % ---- NDFs ----

        function populateNdfsPanel(obj)
            delete(obj.ndfsPanel.Children);
            obj.ndfsListboxes = containers.Map();

            devs = obj.allDevices();
            ndfDevices = {};
            for i = 1:numel(devs)
                desc = devs{i}.getConfigurationSettingDescriptors().findByName('ndfs');
                if ~isempty(desc)
                    ndfDevices{end+1} = devs{i}; %#ok<AGROW>
                end
            end

            if isempty(ndfDevices)
                return;
            end

            grid = uigridlayout(obj.ndfsPanel, [numel(ndfDevices) 2]);
            grid.ColumnWidth = {70, '1x'};
            grid.RowHeight = repmat({55}, 1, numel(ndfDevices));
            grid.Padding = [6 6 6 6];

            for i = 1:numel(ndfDevices)
                device = ndfDevices{i};
                desc = device.getConfigurationSettingDescriptors().findByName('ndfs');
                availableNdfs = desc.type.domain;
                activeNdfs = desc.value;

                % Annotate with attenuation values if available
                displayNdfs = availableNdfs;
                try
                    if any(strcmp('ndfAttenuations', device.getResourceNames()))
                        att = device.getResource('ndfAttenuations');
                        if att.isKey('white'), att = att('white');
                        elseif att.isKey('auto'), att = att('auto');
                        end
                        for k = 1:numel(displayNdfs)
                            if att.isKey(availableNdfs{k})
                                displayNdfs{k} = [availableNdfs{k} ' (' num2str(att(availableNdfs{k})) ')'];
                            end
                        end
                    end
                catch
                end

                % Find active indices
                activeIdx = find(cellfun(@(n)any(strcmp(n, activeNdfs)), availableNdfs));

                uilabel(grid, 'Text', [device.name ':'], 'HorizontalAlignment', 'right');
                lb = uilistbox(grid, ...
                    'Items', displayNdfs, ...
                    'ItemsData', 1:numel(availableNdfs), ...
                    'Multiselect', 'on', ...
                    'Value', activeIdx, ...
                    'ValueChangedFcn', @(src,~)obj.onSelectedNdfs(device, src, availableNdfs));
                obj.ndfsListboxes(device.name) = lb;
            end
        end

        function onSelectedNdfs(obj, device, src, availableNdfs)
            selectedIdx = src.Value;
            ndfs = availableNdfs(selectedIdx);
            try
                device.setConfigurationSetting('ndfs', ndfs);
            catch x
                uialert(obj.figureHandle, x.message, 'NDF Error');
                obj.populateNdfsPanel();
            end
        end

        % ---- Gain ----

        function populateGainPanel(obj)
            delete(obj.gainPanel.Children);
            obj.gainButtonGroups = containers.Map();

            gainLeds = {};
            for i = 1:numel(obj.leds)
                desc = obj.leds{i}.getConfigurationSettingDescriptors().findByName('gain');
                if ~isempty(desc)
                    gainLeds{end+1} = obj.leds{i}; %#ok<AGROW>
                end
            end

            if isempty(gainLeds)
                return;
            end

            grid = uigridlayout(obj.gainPanel, [numel(gainLeds) 2]);
            grid.ColumnWidth = {70, '1x'};
            grid.RowHeight = repmat({28}, 1, numel(gainLeds));
            grid.Padding = [6 6 6 6];

            for i = 1:numel(gainLeds)
                led = gainLeds{i};
                desc = led.getConfigurationSettingDescriptors().findByName('gain');
                availableGains = desc.type.domain;
                currentGain = desc.value;

                uilabel(grid, 'Text', [led.name ':'], 'HorizontalAlignment', 'right');

                bg = uibuttongroup(grid, 'BorderType', 'none', ...
                    'SelectionChangedFcn', @(~,evt)obj.onSelectedGain(led, evt));

                % Create radio buttons for each gain level
                gainNames = {'low', 'medium', 'high'};
                xPos = 0;
                for g = 1:numel(gainNames)
                    gn = gainNames{g};
                    isAvailable = any(strcmp(gn, availableGains));
                    rb = uiradiobutton(bg, 'Text', gn, ...
                        'Position', [xPos 2 75 22], ...
                        'Enable', isAvailable);
                    if strcmp(gn, currentGain)
                        bg.SelectedObject = rb;
                    end
                    xPos = xPos + 80;
                end

                obj.gainButtonGroups(led.name) = bg;
            end
        end

        function onSelectedGain(obj, led, event)
            gain = event.NewValue.Text;
            try
                led.setConfigurationSetting('gain', gain);
            catch x
                uialert(obj.figureHandle, x.message, 'Gain Error');
                obj.populateGainPanel();
            end
        end

        % ---- Light Path ----

        function populateLightPathPanel(obj)
            delete(obj.lightPathPanel.Children);

            % Find common light path across all LEDs
            commonPath = [];
            hasLightPath = false;
            for i = 1:numel(obj.leds)
                desc = obj.leds{i}.getConfigurationSettingDescriptors().findByName('lightPath');
                if isempty(desc)
                    commonPath = [];
                    break;
                end
                hasLightPath = true;
                if ~ischar(commonPath)
                    commonPath = desc.value;
                elseif ~strcmp(desc.value, commonPath)
                    commonPath = [];
                    break;
                end
            end

            grid = uigridlayout(obj.lightPathPanel, [1 2]);
            grid.ColumnWidth = {70, '1x'};
            grid.RowHeight = {28};
            grid.Padding = [6 6 6 6];

            uilabel(grid, 'Text', 'All:', 'HorizontalAlignment', 'right');
            obj.lightPathDropdown = uidropdown(grid, ...
                'Items', {'', 'below', 'above'}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedLightPath());

            if hasLightPath && ischar(commonPath)
                obj.lightPathDropdown.Value = commonPath;
                obj.lightPathDropdown.Enable = 'on';
            else
                obj.lightPathDropdown.Value = '';
                obj.lightPathDropdown.Enable = 'off';
            end
        end

        function onSelectedLightPath(obj)
            path = obj.lightPathDropdown.Value;
            for i = 1:numel(obj.leds)
                try
                    obj.leds{i}.setConfigurationSetting('lightPath', path);
                catch x
                    uialert(obj.figureHandle, x.message, 'Light Path Error');
                    obj.populateLightPathPanel();
                    return;
                end
            end
        end

        % ---- Events ----

        function onDeviceChangedConfigurationSetting(obj, ~, event)
            setting = event.data;
            switch setting.name
                case 'ndfs'
                    obj.populateNdfsPanel();
                case 'gain'
                    obj.populateGainPanel();
                case 'lightPath'
                    obj.populateLightPathPanel();
            end
        end

        function onServiceInitializedRig(obj, ~, ~)
            obj.unbindDevices();
            obj.leds = obj.configurationService.getDevices('LED');
            stages = obj.configurationService.getDevices('Stage');
            obj.stage = [];
            if ~isempty(stages)
                obj.stage = stages{1};
            end
            obj.populateNdfsPanel();
            obj.populateGainPanel();
            obj.populateLightPathPanel();
            obj.bindDevices();
        end

    end

end
