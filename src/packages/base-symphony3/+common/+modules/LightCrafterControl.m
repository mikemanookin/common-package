classdef LightCrafterControl < symphonyui.ui.Module
    % Controls LightCrafter device settings: LED enables, pattern rate,
    % center offset, prerender, and LED currents.

    properties (Access = private)
        settings
        lightCrafter
        modeDropdown
        autoCheckbox
        redCheckbox
        greenCheckbox
        blueCheckbox
        patternRateLabel
        patternRateDropdown
        centerOffsetXField
        centerOffsetYField
        prerenderCheckbox
        ledCurrentRField
        ledCurrentGField
        ledCurrentBField
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'LightCrafter Control';
            figureHandle.Position(3:4) = [380 234];
            figureHandle.Resize = 'off';

            grid = uigridlayout(figureHandle, [6 2]);
            grid.ColumnWidth = {120, '1x'};
            grid.RowHeight = {28, 28, 28, 28, 28, 28};
            grid.Padding = [10 10 10 10];
            grid.RowSpacing = 6;

            % Row 1: Mode
            uilabel(grid, 'Text', 'Mode:', 'HorizontalAlignment', 'right');
            obj.modeDropdown = uidropdown(grid, ...
                'Items', {'Pattern', 'Video'}, ...
                'ItemsData', {'pattern', 'video'}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedMode());

            % Row 2: LED enables
            uilabel(grid, 'Text', 'LED enables:', 'HorizontalAlignment', 'right');
            cbGrid = uigridlayout(grid, [1 4]);
            cbGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            cbGrid.Padding = [0 0 0 0];
            obj.autoCheckbox = uicheckbox(cbGrid, 'Text', 'Auto', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedLedEnable());
            obj.redCheckbox = uicheckbox(cbGrid, 'Text', 'Red', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedLedEnable());
            obj.greenCheckbox = uicheckbox(cbGrid, 'Text', 'Green', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedLedEnable());
            obj.blueCheckbox = uicheckbox(cbGrid, 'Text', 'Blue', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedLedEnable());

            % Row 3: Pattern rate
            obj.patternRateLabel = uilabel(grid, 'Text', 'Pattern rate:', 'HorizontalAlignment', 'right');
            obj.patternRateDropdown = uidropdown(grid, ...
                'Items', {' '}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedPatternRate());

            % Row 4: Center offset
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

            % Row 5: Prerender
            uilabel(grid, 'Text', 'Prerender:', 'HorizontalAlignment', 'right');
            obj.prerenderCheckbox = uicheckbox(grid, 'Text', '', ...
                'ValueChangedFcn', @(~,~)obj.onSelectedPrerender());

            % Row 6: LED currents
            uilabel(grid, 'Text', 'LCR LED currents:', 'HorizontalAlignment', 'right');
            currGrid = uigridlayout(grid, [1 6]);
            currGrid.ColumnWidth = {'1x', 15, '1x', 15, '1x', 15};
            currGrid.Padding = [0 0 0 0];
            obj.ledCurrentRField = uieditfield(currGrid, 'text', ...
                'ValueChangedFcn', @(~,~)obj.onSetLedCurrents());
            uilabel(currGrid, 'Text', 'R');
            obj.ledCurrentGField = uieditfield(currGrid, 'text', ...
                'ValueChangedFcn', @(~,~)obj.onSetLedCurrents());
            uilabel(currGrid, 'Text', 'G');
            obj.ledCurrentBField = uieditfield(currGrid, 'text', ...
                'ValueChangedFcn', @(~,~)obj.onSetLedCurrents());
            uilabel(currGrid, 'Text', 'B');
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.LightCrafterControlSettings();
            devices = obj.configurationService.getDevices('LightCrafter');
            if isempty(devices)
                error('No LightCrafter device found');
            end
            obj.lightCrafter = devices{1};

            obj.populateMode();
            obj.populateLedEnables();
            obj.populatePatternRateList();
            obj.populateCenterOffset();
            obj.populatePrerender();
            obj.populateLedCurrents();
            obj.updatePatternRateEnabled();

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

        function populateMode(obj)
            obj.modeDropdown.Value = obj.lightCrafter.getMode();
        end

        function onSelectedMode(obj)
            obj.lightCrafter.setMode(obj.modeDropdown.Value);
            obj.populatePatternRateList();
            obj.updatePatternRateEnabled();
        end

        function updatePatternRateEnabled(obj)
            isPattern = strcmp(obj.lightCrafter.getMode(), 'pattern');
            if isPattern
                obj.patternRateLabel.Enable = 'on';
                obj.patternRateDropdown.Enable = 'on';
            else
                obj.patternRateLabel.Enable = 'off';
                obj.patternRateDropdown.Enable = 'off';
            end
        end

        function populateLedEnables(obj)
            [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
            obj.autoCheckbox.Value = auto;
            obj.redCheckbox.Value = red;
            obj.greenCheckbox.Value = green;
            obj.blueCheckbox.Value = blue;
        end

        function onSelectedLedEnable(obj)
            obj.lightCrafter.setLedEnables( ...
                obj.autoCheckbox.Value, obj.redCheckbox.Value, ...
                obj.greenCheckbox.Value, obj.blueCheckbox.Value);
        end

        function populatePatternRateList(obj)
            rates = obj.lightCrafter.availablePatternRates();
            if isempty(rates)
                obj.patternRateDropdown.Items = {'N/A'};
                obj.patternRateDropdown.ItemsData = {};
                return;
            end
            names = cellfun(@(r)[num2str(r) ' Hz'], rates, 'UniformOutput', false);
            obj.patternRateDropdown.Items = names;
            obj.patternRateDropdown.ItemsData = cell2mat(rates);
            currentRate = obj.lightCrafter.getPatternRate();
            if ~isempty(currentRate) && any(cell2mat(rates) == currentRate)
                obj.patternRateDropdown.Value = currentRate;
            end
        end

        function onSelectedPatternRate(obj)
            obj.lightCrafter.setPatternRate(obj.patternRateDropdown.Value);
        end

        function populateCenterOffset(obj)
            offset = obj.lightCrafter.pix2um(obj.lightCrafter.getCenterOffset());
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
            obj.lightCrafter.setCenterOffset(obj.lightCrafter.um2pix([x, y]));
        end

        function populatePrerender(obj)
            obj.prerenderCheckbox.Value = obj.lightCrafter.getPrerender();
        end

        function onSelectedPrerender(obj)
            obj.lightCrafter.setPrerender(obj.prerenderCheckbox.Value);
        end

        function populateLedCurrents(obj)
            [r, g, b] = obj.lightCrafter.getLedCurrents();
            obj.ledCurrentRField.Value = num2str(r);
            obj.ledCurrentGField.Value = num2str(g);
            obj.ledCurrentBField.Value = num2str(b);
        end

        function onSetLedCurrents(obj)
            r = str2double(obj.ledCurrentRField.Value);
            g = str2double(obj.ledCurrentGField.Value);
            b = str2double(obj.ledCurrentBField.Value);
            if isnan(r) || isnan(g) || isnan(b)
                uialert(obj.figureHandle, 'Could not parse R, G, or B to a valid scalar value.', 'Error');
                return;
            end
            obj.lightCrafter.setLedCurrents(r, g, b);
        end

    end

end
