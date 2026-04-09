classdef LedSPDTControl < symphonyui.ui.Module
    % Controls the LED SPDT (single-pole double-throw) switch device.

    properties (Access = private)
        settings
        led_switch
        led_names
        ledDropdown
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'LED Switch Control';
            figureHandle.Position(3:4) = [280 80];

            grid = uigridlayout(figureHandle, [1 2]);
            grid.ColumnWidth = {80, '1x'};
            grid.Padding = [10 10 10 10];

            uilabel(grid, 'Text', 'LED value:', 'HorizontalAlignment', 'right');
            obj.ledDropdown = uidropdown(grid, ...
                'Items', {' '}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedSetting());
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.LedSPDTControlSettings();
            devices = obj.configurationService.getDevices('LedSPDTDevice');
            if isempty(devices)
                error('No LED switch device found');
            end
            obj.led_switch = devices{1};
            obj.led_names = obj.led_switch.get_LED_names();
            obj.populateSettingList();

            % Set to first channel on startup
            obj.led_switch.set_LED(obj.led_names{1});
            obj.ledDropdown.Value = obj.led_names{1};

            try
                if ~isempty(obj.settings.viewPosition)
                    p = obj.settings.viewPosition;
                    obj.figureHandle.Position(1:2) = p(1:2);
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

    end

    methods (Access = private)

        function populateSettingList(obj)
            obj.ledDropdown.Items = obj.led_names;
            obj.ledDropdown.ItemsData = 1:numel(obj.led_names);
        end

        function onSelectedSetting(obj)
            position = obj.ledDropdown.Value;
            obj.led_switch.set_LED(obj.led_names{position});
        end

    end

end
