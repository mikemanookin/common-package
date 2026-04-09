classdef BackgroundControl < symphonyui.ui.Module
    % Displays and controls the background values for all output devices.
    % Adapted from the Symphony3 example BackgroundControl with the
    % "Turn LEDs Off" feature from the Symphony2 version.

    properties (Access = private)
        settings
        devices
        deviceListeners
        deviceTable             % uitable for editing background values
        turnLedsOffBtn          % uibutton for turning all LEDs off
        hideUnitlessCheckbox    % uicheckbox for hiding unitless devices
        visibleDeviceIndices    % maps table rows to obj.devices indices
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'Background Control';
            figureHandle.Position(3:4) = [340 220];

            mainGrid = uigridlayout(figureHandle, [2 1]);
            mainGrid.RowHeight = {30, '1x'};
            mainGrid.Padding = [6 6 6 6];
            mainGrid.RowSpacing = 4;

            % Toolbar row
            toolbarGrid = uigridlayout(mainGrid, [1 3]);
            toolbarGrid.ColumnWidth = {110, '1x', 'fit'};
            toolbarGrid.Padding = [0 0 0 0];
            obj.turnLedsOffBtn = uibutton(toolbarGrid, ...
                'Text', 'Turn LEDs Off', ...
                'ButtonPushedFcn', @(~,~)obj.onSelectedTurnLedsOff());
            uilabel(toolbarGrid, 'Text', ''); % spacer
            obj.hideUnitlessCheckbox = uicheckbox(toolbarGrid, ...
                'Text', 'Hide unitless devices', ...
                'Value', true, ...
                'ValueChangedFcn', @(~,~)obj.onHideUnitlessChanged());

            % Device table
            obj.deviceTable = uitable(mainGrid, ...
                'ColumnName', {'Device', 'Background', 'Units'}, ...
                'ColumnEditable', [false true false], ...
                'ColumnWidth', {'1x', 80, 60}, ...
                'CellEditCallback', @(src, evt)obj.onCellEdit(src, evt));
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.BackgroundControlSettings();
            obj.devices = obj.configurationService.getOutputDevices();
            obj.populateTable();
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

        function bindDevices(obj)
            obj.deviceListeners = {};
            for i = 1:numel(obj.devices)
                obj.deviceListeners{end + 1} = obj.addListener( ...
                    obj.devices{i}, 'background', 'PostSet', @obj.onDeviceSetBackground);
            end
        end

        function unbindDevices(obj)
            while ~isempty(obj.deviceListeners)
                obj.removeListener(obj.deviceListeners{1});
                obj.deviceListeners(1) = [];
            end
        end

        function populateTable(obj)
            n = numel(obj.devices);
            obj.visibleDeviceIndices = [];
            if n == 0
                obj.deviceTable.Data = {};
                return;
            end
            data = {};
            for i = 1:n
                d = obj.devices{i};
                if obj.hideUnitlessCheckbox.Value && strcmp(d.background.displayUnits, '_unitless_')
                    continue;
                end
                obj.visibleDeviceIndices(end + 1) = i;
                row = numel(obj.visibleDeviceIndices);
                data{row, 1} = d.name;
                data{row, 2} = d.background.quantity;
                data{row, 3} = d.background.displayUnits;
            end
            obj.deviceTable.Data = data;
        end

        function onCellEdit(obj, ~, evt)
            row = evt.Indices(1);
            col = evt.Indices(2);
            if col ~= 2
                return;
            end
            newVal = evt.NewData;
            if ischar(newVal) || isstring(newVal)
                newVal = str2double(newVal);
            end
            if isnan(newVal)
                obj.populateTable();
                return;
            end

            device = obj.devices{obj.visibleDeviceIndices(row)};
            oldBackground = device.background;
            device.background = symphonyui.core.Measurement(newVal, device.background.displayUnits);
            try
                device.applyBackground();
            catch x
                device.background = oldBackground;
                obj.populateTable();
                uialert(obj.figureHandle, x.message, 'Background Error');
                return;
            end

            % Update background for all modes if the device supports modes
            if ismethod(device, 'availableModes')
                for i = 1:numel(device.availableModes)
                    mode = device.availableModes{i};
                    b = device.getBackgroundForMode(mode);
                    device.setBackgroundForMode(mode, ...
                        symphonyui.core.Measurement(newVal, b.displayUnits));
                end
            end
        end

        function onSelectedTurnLedsOff(obj, ~, ~)
            % Turn off all LED devices by setting background to -1V or 0.
            leds = obj.configurationService.getDevices('LED');
            for i = 1:numel(leds)
                led = leds{i};
                if strcmp(led.background.baseUnits, 'V')
                    led.background = symphonyui.core.Measurement(-1, led.background.displayUnits);
                else
                    led.background = symphonyui.core.Measurement(0, led.background.displayUnits);
                end
                try
                    led.applyBackground();
                catch
                end
            end
        end

        function onHideUnitlessChanged(obj)
            obj.populateTable();
        end

        function onServiceInitializedRig(obj, ~, ~)
            obj.unbindDevices();
            obj.devices = obj.configurationService.getOutputDevices();
            obj.populateTable();
            obj.bindDevices();
        end

        function onDeviceSetBackground(obj, ~, ~)
            obj.populateTable();
        end

    end

end
