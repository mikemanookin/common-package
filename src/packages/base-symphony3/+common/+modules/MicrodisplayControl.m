classdef MicrodisplayControl < symphonyui.ui.Module
    % Controls Microdisplay device settings: brightness, center offset, prerender.

    properties (Access = private)
        settings
        microdisplay
        brightnessDropdown
        centerOffsetXField
        centerOffsetYField
        prerenderCheckbox
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'Microdisplay Control';
            figureHandle.Position(3:4) = [360 130];
            figureHandle.Resize = 'off';

            grid = uigridlayout(figureHandle, [3 2]);
            grid.ColumnWidth = {120, '1x'};
            grid.RowHeight = {28, 28, 28};
            grid.Padding = [10 10 10 10];
            grid.RowSpacing = 6;

            % Row 1: Brightness
            uilabel(grid, 'Text', 'Brightness:', 'HorizontalAlignment', 'right');
            obj.brightnessDropdown = uidropdown(grid, ...
                'Items', {' '}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedBrightness());

            % Row 2: Center offset
            uilabel(grid, 'Text', 'Center offset (um):', 'HorizontalAlignment', 'right');
            offsetGrid = uigridlayout(grid, [1 4]);
            offsetGrid.ColumnWidth = {'1x', 15, '1x', 15};
            offsetGrid.Padding = [0 0 0 0];
            obj.centerOffsetXField = uieditfield(offsetGrid, 'text', ...
                'ValueChangedFcn', @(~,~)obj.onSetCenterOffset());
            uilabel(offsetGrid, 'Text', 'X');
            obj.centerOffsetYField = uieditfield(offsetGrid, 'text', ...
                'ValueChangedFcn', @(~,~)obj.onSetCenterOffset());
            uilabel(offsetGrid, 'Text', 'Y');

            % Row 3: Prerender
            uilabel(grid, 'Text', 'Prerender:', 'HorizontalAlignment', 'right');
            obj.prerenderCheckbox = uicheckbox(grid, 'Text', '', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedPrerender());
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.MicrodisplayControlSettings();
            devices = obj.configurationService.getDevices('Microdisplay');
            if isempty(devices)
                error('No Microdisplay device found');
            end
            obj.microdisplay = devices{1};
            obj.populateBrightnessList();
            obj.populateCenterOffset();
            obj.populatePrerender();

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

        function populateBrightnessList(obj)
            import common.devices.MicrodisplayBrightness;

            names = {'Minimum', 'Low', 'Medium', 'High', 'Maximum'};
            values = [MicrodisplayBrightness.MINIMUM, MicrodisplayBrightness.LOW, ...
                      MicrodisplayBrightness.MEDIUM, MicrodisplayBrightness.HIGH, ...
                      MicrodisplayBrightness.MAXIMUM];
            obj.brightnessDropdown.Items = names;
            obj.brightnessDropdown.ItemsData = values;

            brightness = obj.microdisplay.getBrightness();
            obj.brightnessDropdown.Value = brightness;
        end

        function onSelectedBrightness(obj)
            brightness = obj.brightnessDropdown.Value;
            obj.microdisplay.setBrightness(brightness);
        end

        function populateCenterOffset(obj)
            offset = obj.microdisplay.pix2um(obj.microdisplay.getCenterOffset());
            obj.centerOffsetXField.Value = num2str(offset(1));
            obj.centerOffsetYField.Value = num2str(offset(2));
        end

        function onSetCenterOffset(obj)
            x = str2double(obj.centerOffsetXField.Value);
            y = str2double(obj.centerOffsetYField.Value);
            if isnan(x) || isnan(y)
                uialert(obj.figureHandle, 'Could not parse x or y to a valid scalar value.', 'Error');
                return;
            end
            obj.microdisplay.setCenterOffset(obj.microdisplay.um2pix([x, y]));
        end

        function populatePrerender(obj)
            obj.prerenderCheckbox.Value = obj.microdisplay.getPrerender();
        end

        function onSelectedPrerender(obj)
            obj.microdisplay.setPrerender(obj.prerenderCheckbox.Value);
        end

    end

end
