classdef DeviceCalibrator < symphonyui.ui.Module

    properties (Access = private)
        leds
        stage
        isLedOn
        isStageOn
        isCalibrating
        didShowWarning
        calibrations
        previousCalibrations
    end

    properties (Access = private)
        wizardTabGroup
        instructionsTab
        calibrationTab
        backButton
        nextButton
        cancelButton
    end

    properties (Access = private)
        calibrationCard
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'Device Calibrator';
            figureHandle.Position(3:4) = [500 450];

            mainLayout = uigridlayout(figureHandle, [2 1]);
            mainLayout.RowHeight = {'1x', 45};
            mainLayout.ColumnWidth = {'1x'};
            mainLayout.Padding = [0 0 0 0];
            mainLayout.RowSpacing = 0;

            % Wizard tab group (used as card panel).
            obj.wizardTabGroup = uitabgroup(mainLayout);
            obj.wizardTabGroup.Layout.Row = 1;
            obj.wizardTabGroup.Layout.Column = 1;

            % Instructions card (tab).
            obj.instructionsTab = uitab(obj.wizardTabGroup, 'Title', 'Instructions');
            instructionsLayout = uigridlayout(obj.instructionsTab, [1 1]);
            instructionsLayout.Padding = [11 11 11 11];
            uilabel(instructionsLayout, ...
                'Text', sprintf([...
                    'Instructions:\n' ...
                    '  1. Take all NDFs out of the light path.\n' ...
                    '  2. Make sure the spot is the correctly sized and reasonably well-centered.\n' ...
                    '  3. Tape the wand to the stage, face down.\n' ...
                    '  4. Connect the wand BNC cable to the light meter input on front of the box.\n' ...
                    '  5. Close the curtains and dim the lights.\n' ...
                    '  6. Turn on the power meter and set the gain to 10^-3.\n' ...
                    '  7. Make sure the current (background) reading is ~0.01 or lower.\n' ...
                    '  8. Turn on the stimulation device to a reasonably bright setting.\n' ...
                    '  9. Center and focus the wand relative to the spot:\n' ...
                    '      9.1. Move the stage in the X direction until you find the peak power reading.\n' ...
                    '      9.2. Move the stage in the Y direction until you find the peak power reading.\n' ...
                    '      9.3. Move the stage in the Z direction until the power reading stops increasing.\n' ...
                    '      9.4. Move the stage up a bit so the wand is not pushing on the condenser.\n' ...
                    '  10. Press "Next" to start calibrating.\n']), ...
                'FontWeight', 'bold', ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top');

            % Calibration card (tab).
            obj.calibrationTab = uitab(obj.wizardTabGroup, 'Title', 'Calibration');
            calibrationLayout = uigridlayout(obj.calibrationTab, [1 2]);
            calibrationLayout.ColumnWidth = {'1x', '2x'};
            calibrationLayout.Padding = [11 11 11 11];
            calibrationLayout.ColumnSpacing = 7;

            % Master list.
            obj.calibrationCard.deviceListBox = uilistbox(calibrationLayout, ...
                'Items', {}, ...
                'ItemsData', {}, ...
                'ValueChangedFcn', @obj.onSelectedDevice);
            obj.calibrationCard.deviceListBox.Layout.Row = 1;
            obj.calibrationCard.deviceListBox.Layout.Column = 1;

            % Detail card panel (tab group for LED vs Stage).
            detailLayout = uigridlayout(calibrationLayout, [1 1]);
            detailLayout.Layout.Row = 1;
            detailLayout.Layout.Column = 2;
            detailLayout.Padding = [0 0 0 0];

            obj.calibrationCard.detailCardPanel = uitabgroup(detailLayout);

            % --- LED calibration card ---
            ledTab = uitab(obj.calibrationCard.detailCardPanel, 'Title', 'LED');
            ledLayout = uigridlayout(ledTab, [9 3]);
            ledLayout.RowHeight = {23, 23, 17, 23, 23, 23, 23, 23, 23};
            ledLayout.ColumnWidth = {85, '1x', '1x'};
            ledLayout.RowSpacing = 7;
            ledLayout.ColumnSpacing = 5;
            ledLayout.Padding = [0 0 0 0];

            % Row 1: Use calibration
            uilabel(ledLayout, 'Text', 'Use calibration:', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.useCalibrationPopupMenu = uidropdown(ledLayout, ...
                'Items', {' '}, ...
                'ItemsData', {[]});
            obj.calibrationCard.ledCard.useCalibrationPopupMenu.Layout.Row = 1;
            obj.calibrationCard.ledCard.useCalibrationPopupMenu.Layout.Column = [2 3];

            % Row 2: View / Use buttons
            uilabel(ledLayout, 'Text', '');
            obj.calibrationCard.ledCard.viewButton = uibutton(ledLayout, ...
                'Text', 'View', ...
                'ButtonPushedFcn', @obj.onSelectedLedView);
            obj.calibrationCard.ledCard.viewButton.Layout.Row = 2;
            obj.calibrationCard.ledCard.viewButton.Layout.Column = 2;
            obj.calibrationCard.ledCard.useButton = uibutton(ledLayout, ...
                'Text', 'Use', ...
                'ButtonPushedFcn', @obj.onSelectedLedUse);
            obj.calibrationCard.ledCard.useButton.Layout.Row = 2;
            obj.calibrationCard.ledCard.useButton.Layout.Column = 3;

            % Row 3: Separator "Or"
            uilabel(ledLayout, 'Text', '--- Or ---', ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
            lbl = findobj(ledLayout.Children, 'Text', '--- Or ---');
            lbl.Layout.Row = 3;
            lbl.Layout.Column = [1 3];

            % Row 4: Calibrate using
            uilabel(ledLayout, 'Text', 'Calibrate using:');
            lbl4 = findobj(ledLayout.Children, 'Text', 'Calibrate using:');
            lbl4.Layout.Row = 4;
            lbl4.Layout.Column = 1;
            obj.calibrationCard.ledCard.calibrationIntensityField = uieditfield(ledLayout, 'text', ...
                'Value', '1', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.calibrationIntensityField.Layout.Row = 4;
            obj.calibrationCard.ledCard.calibrationIntensityField.Layout.Column = 2;
            obj.calibrationCard.ledCard.calibrationUnitsField = uieditfield(ledLayout, 'text', ...
                'Value', '', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.calibrationUnitsField.Layout.Row = 4;
            obj.calibrationCard.ledCard.calibrationUnitsField.Layout.Column = 3;

            % Row 5: Reset / LED On
            uilabel(ledLayout, 'Text', '');
            lbl5 = ledLayout.Children(1);
            lbl5.Layout.Row = 5;
            lbl5.Layout.Column = 1;
            obj.calibrationCard.ledCard.resetButton = uibutton(ledLayout, ...
                'Text', 'Reset', ...
                'ButtonPushedFcn', @obj.onSelectedLedReset);
            obj.calibrationCard.ledCard.resetButton.Layout.Row = 5;
            obj.calibrationCard.ledCard.resetButton.Layout.Column = 2;
            obj.calibrationCard.ledCard.ledOnButton = uibutton(ledLayout, 'state', ...
                'Text', 'LED On', ...
                'ValueChangedFcn', @obj.onSelectedLedOn);
            obj.calibrationCard.ledCard.ledOnButton.Layout.Row = 5;
            obj.calibrationCard.ledCard.ledOnButton.Layout.Column = 3;

            % Row 6: Spot diameter
            uilabel(ledLayout, 'Text', 'Spot diameter:');
            lbl6 = ledLayout.Children(1);
            lbl6.Layout.Row = 6;
            lbl6.Layout.Column = 1;
            obj.calibrationCard.ledCard.spotDiameterField = uieditfield(ledLayout, 'text', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.spotDiameterField.Layout.Row = 6;
            obj.calibrationCard.ledCard.spotDiameterField.Layout.Column = 2;
            obj.calibrationCard.ledCard.spotUnitsField = uieditfield(ledLayout, 'text', ...
                'Value', 'um', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.spotUnitsField.Layout.Row = 6;
            obj.calibrationCard.ledCard.spotUnitsField.Layout.Column = 3;

            % Row 7: Power reading
            uilabel(ledLayout, 'Text', 'Power reading:');
            lbl7 = ledLayout.Children(1);
            lbl7.Layout.Row = 7;
            lbl7.Layout.Column = 1;
            obj.calibrationCard.ledCard.powerReadingField = uieditfield(ledLayout, 'text', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.powerReadingField.Layout.Row = 7;
            obj.calibrationCard.ledCard.powerReadingField.Layout.Column = 2;
            obj.calibrationCard.ledCard.powerUnitsField = uieditfield(ledLayout, 'text', ...
                'Value', 'nW', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.powerUnitsField.Layout.Row = 7;
            obj.calibrationCard.ledCard.powerUnitsField.Layout.Column = 3;

            % Row 8: Note
            uilabel(ledLayout, 'Text', 'Note (optional):');
            lbl8 = ledLayout.Children(1);
            lbl8.Layout.Row = 8;
            lbl8.Layout.Column = 1;
            obj.calibrationCard.ledCard.noteField = uieditfield(ledLayout, 'text', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.ledCard.noteField.Layout.Row = 8;
            obj.calibrationCard.ledCard.noteField.Layout.Column = [2 3];

            % Row 9: Submit
            uilabel(ledLayout, 'Text', '');
            lbl9 = ledLayout.Children(1);
            lbl9.Layout.Row = 9;
            lbl9.Layout.Column = [1 2];
            obj.calibrationCard.ledCard.submitButton = uibutton(ledLayout, ...
                'Text', 'Submit', ...
                'ButtonPushedFcn', @obj.onSelectedLedSubmit);
            obj.calibrationCard.ledCard.submitButton.Layout.Row = 9;
            obj.calibrationCard.ledCard.submitButton.Layout.Column = 3;

            % --- Stage calibration card ---
            stageTab = uitab(obj.calibrationCard.detailCardPanel, 'Title', 'Stage');
            stageLayout = uigridlayout(stageTab, [9 3]);
            stageLayout.RowHeight = {23, 23, 17, 23, 23, 23, 23, 23, 23};
            stageLayout.ColumnWidth = {85, '1x', '1x'};
            stageLayout.RowSpacing = 7;
            stageLayout.ColumnSpacing = 5;
            stageLayout.Padding = [0 0 0 0];

            % Row 1: Use calibration
            uilabel(stageLayout, 'Text', 'Use calibration:', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.useCalibrationPopupMenu = uidropdown(stageLayout, ...
                'Items', {' '}, ...
                'ItemsData', {[]});
            obj.calibrationCard.stageCard.useCalibrationPopupMenu.Layout.Row = 1;
            obj.calibrationCard.stageCard.useCalibrationPopupMenu.Layout.Column = [2 3];

            % Row 2: View / Use buttons
            uilabel(stageLayout, 'Text', '');
            stLbl2 = stageLayout.Children(1);
            stLbl2.Layout.Row = 2;
            stLbl2.Layout.Column = 1;
            obj.calibrationCard.stageCard.viewButton = uibutton(stageLayout, ...
                'Text', 'View', ...
                'ButtonPushedFcn', @obj.onSelectedStageView);
            obj.calibrationCard.stageCard.viewButton.Layout.Row = 2;
            obj.calibrationCard.stageCard.viewButton.Layout.Column = 2;
            obj.calibrationCard.stageCard.useButton = uibutton(stageLayout, ...
                'Text', 'Use', ...
                'ButtonPushedFcn', @obj.onSelectedStageUse);
            obj.calibrationCard.stageCard.useButton.Layout.Row = 2;
            obj.calibrationCard.stageCard.useButton.Layout.Column = 3;

            % Row 3: Separator "Or"
            stSepLabel = uilabel(stageLayout, 'Text', '--- Or ---', ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
            stSepLabel.Layout.Row = 3;
            stSepLabel.Layout.Column = [1 3];

            % Row 4: Calibrate using
            stLbl4 = uilabel(stageLayout, 'Text', 'Calibrate using:');
            stLbl4.Layout.Row = 4;
            stLbl4.Layout.Column = 1;
            obj.calibrationCard.stageCard.calibrationIntensityField = uieditfield(stageLayout, 'text', ...
                'Value', '1', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.calibrationIntensityField.Layout.Row = 4;
            obj.calibrationCard.stageCard.calibrationIntensityField.Layout.Column = 2;
            obj.calibrationCard.stageCard.calibrationUnitsField = uieditfield(stageLayout, 'text', ...
                'Value', '_normalized_', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.calibrationUnitsField.Layout.Row = 4;
            obj.calibrationCard.stageCard.calibrationUnitsField.Layout.Column = 3;

            % Row 5: Spot diameter
            stLbl5 = uilabel(stageLayout, 'Text', 'Spot diameter:');
            stLbl5.Layout.Row = 5;
            stLbl5.Layout.Column = 1;
            obj.calibrationCard.stageCard.spotDiameterField = uieditfield(stageLayout, 'text', ...
                'Value', '500', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.spotDiameterField.Layout.Row = 5;
            obj.calibrationCard.stageCard.spotDiameterField.Layout.Column = 2;
            obj.calibrationCard.stageCard.spotUnitsField = uieditfield(stageLayout, 'text', ...
                'Value', 'um', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.spotUnitsField.Layout.Row = 5;
            obj.calibrationCard.stageCard.spotUnitsField.Layout.Column = 3;

            % Row 6: Reset / Stage On
            stLbl6 = uilabel(stageLayout, 'Text', '');
            stLbl6.Layout.Row = 6;
            stLbl6.Layout.Column = 1;
            obj.calibrationCard.stageCard.resetButton = uibutton(stageLayout, ...
                'Text', 'Reset', ...
                'ButtonPushedFcn', @obj.onSelectedStageReset);
            obj.calibrationCard.stageCard.resetButton.Layout.Row = 6;
            obj.calibrationCard.stageCard.resetButton.Layout.Column = 2;
            obj.calibrationCard.stageCard.stageOnButton = uibutton(stageLayout, 'state', ...
                'Text', 'Stage On', ...
                'ValueChangedFcn', @obj.onSelectedStageOn);
            obj.calibrationCard.stageCard.stageOnButton.Layout.Row = 6;
            obj.calibrationCard.stageCard.stageOnButton.Layout.Column = 3;

            % Row 7: Power reading
            stLbl7 = uilabel(stageLayout, 'Text', 'Power reading:');
            stLbl7.Layout.Row = 7;
            stLbl7.Layout.Column = 1;
            obj.calibrationCard.stageCard.powerReadingField = uieditfield(stageLayout, 'text', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.powerReadingField.Layout.Row = 7;
            obj.calibrationCard.stageCard.powerReadingField.Layout.Column = 2;
            obj.calibrationCard.stageCard.powerUnitsField = uieditfield(stageLayout, 'text', ...
                'Value', 'nW', ...
                'Editable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.powerUnitsField.Layout.Row = 7;
            obj.calibrationCard.stageCard.powerUnitsField.Layout.Column = 3;

            % Row 8: Note
            stLbl8 = uilabel(stageLayout, 'Text', 'Note (optional):');
            stLbl8.Layout.Row = 8;
            stLbl8.Layout.Column = 1;
            obj.calibrationCard.stageCard.noteField = uieditfield(stageLayout, 'text', ...
                'HorizontalAlignment', 'left');
            obj.calibrationCard.stageCard.noteField.Layout.Row = 8;
            obj.calibrationCard.stageCard.noteField.Layout.Column = [2 3];

            % Row 9: Submit
            stLbl9 = uilabel(stageLayout, 'Text', '');
            stLbl9.Layout.Row = 9;
            stLbl9.Layout.Column = [1 2];
            obj.calibrationCard.stageCard.submitButton = uibutton(stageLayout, ...
                'Text', 'Submit', ...
                'ButtonPushedFcn', @obj.onSelectedStageSubmit);
            obj.calibrationCard.stageCard.submitButton.Layout.Row = 9;
            obj.calibrationCard.stageCard.submitButton.Layout.Column = 3;

            % Select LED tab by default.
            obj.calibrationCard.detailCardPanel.SelectedTab = obj.calibrationCard.detailCardPanel.Children(1);

            % Select Instructions tab by default.
            obj.wizardTabGroup.SelectedTab = obj.instructionsTab;

            % Bottom controls layout.
            controlsLayout = uigridlayout(mainLayout, [1 5]);
            controlsLayout.Layout.Row = 2;
            controlsLayout.Layout.Column = 1;
            controlsLayout.ColumnWidth = {'1x', 75, 75, 7, 75};
            controlsLayout.Padding = [11 11 11 11];
            controlsLayout.ColumnSpacing = 0;

            uilabel(controlsLayout, 'Text', ''); % spacer
            obj.backButton = uibutton(controlsLayout, ...
                'Text', '< Back', ...
                'ButtonPushedFcn', @obj.onSelectedBack);
            obj.nextButton = uibutton(controlsLayout, ...
                'Text', 'Next >', ...
                'ButtonPushedFcn', @obj.onSelectedNext);
            uilabel(controlsLayout, 'Text', ''); % spacer
            obj.cancelButton = uibutton(controlsLayout, ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @obj.onSelectedCancel);
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.leds = obj.configurationService.getDevices('LED');
            stages = obj.configurationService.getDevices('Stage');
            if isempty(stages)
                obj.stage = [];
            else
                obj.stage = stages{1};
            end

            obj.isLedOn = false;
            obj.isStageOn = false;
            obj.isCalibrating = false;
            obj.didShowWarning = false;

            obj.calibrations = containers.Map();
            obj.previousCalibrations = containers.Map();
            for i = 1:numel(obj.allDevices)
                device = obj.allDevices{i};

                if ~any(strcmp('fluxFactorPaths', device.getResourceNames()))
                    continue;
                end
                paths = device.getResource('fluxFactorPaths');

                m = containers.Map();
                settings = paths.keys;
                for k = 1:numel(settings)
                    setting = settings{k};
                    if ~exist(paths(setting), 'file')
                        continue;
                    end
                    t = readtable(paths(setting), 'Format', '%s %s %f %f %f %f %s');
                    t.date = datetime(t.date);
                    t = sortrows(t, 'date', 'descend');
                    m(setting) = t;
                end

                obj.previousCalibrations(device.name) = m;
            end

            obj.populateDeviceList();
            obj.updateStateOfControls();
        end

        function onViewSelectedClose(obj, ~, ~)
            obj.close();
        end

    end

    methods (Access = private)

        function populateDeviceList(obj)
            settingToDevices = containers.Map();
            for i = 1:numel(obj.allDevices)
                device = obj.allDevices{i};

                if ~any(strcmp('fluxFactorPaths', device.getResourceNames()))
                    settings = {'none'};
                else
                    paths = device.getResource('fluxFactorPaths');
                    settings = paths.keys;
                end

                for k = 1:numel(settings)
                    setting = settings{k};
                    if settingToDevices.isKey(setting)
                        settingToDevices(setting) = [settingToDevices(setting) {device}];
                    else
                        settingToDevices(setting) = {device};
                    end
                end
            end

            % This allows the settings to be displayed in a preferred order.
            keys = settingToDevices.keys;
            settings = {'low', 'medium', 'high', 'auto', 'red', 'green', 'blue', 'none'};
            settings(cellfun(@(s)~any(strcmp(s, keys)), settings)) = [];
            for i = 1:numel(keys)
                if ~any(strcmp(keys{i}, settings))
                    settings{end + 1} = keys{i}; %#ok<AGROW>
                end
            end

            names = {};
            obj.calibrationCard.deviceSettingList = {};  % Store structs separately
            for i = 1:numel(settings)
                setting = settings{i};
                devices = settingToDevices(setting);
                for k = 1:numel(devices)
                    d = devices{k};
                    if obj.isDeviceCalibrated(d, setting)
                        n = [char(9989) ' ' d.name]; % checkmark for calibrated
                    else
                        n = d.name;
                    end
                    if ~strcmp(setting, 'none')
                        n = [n ' - ' setting]; %#ok<AGROW>
                    end
                    names{end + 1} = n; %#ok<AGROW>
                    obj.calibrationCard.deviceSettingList{end + 1} = struct('device', d, 'setting', setting);
                end
            end
            obj.calibrationCard.deviceListBox.Items = names;
            obj.calibrationCard.deviceListBox.ItemsData = 1:numel(names);
        end

        function d = allDevices(obj)
            d = obj.leds;
            if ~isempty(obj.stage)
                d = [{} d {obj.stage}];
            end
        end

        function onSelectedDevice(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            obj.selectDevice(device, setting);
        end

        function selectDevice(obj, device, setting)
            turnOn = obj.isLedOn || obj.isStageOn;
            obj.turnOffAllDevices();

            obj.setSelectedDevice(device, setting);
            if device == obj.stage
                if turnOn
                    intensity = str2double(obj.calibrationCard.stageCard.calibrationIntensityField.Value);
                    diameter = str2double(obj.calibrationCard.stageCard.spotDiameterField.Value);
                    obj.turnOnStage(device, setting, intensity, diameter);
                end
                obj.populateDetailsForStage(device, setting);
                focus(obj.calibrationCard.stageCard.powerReadingField);
            else
                if turnOn
                    intensity = str2double(obj.calibrationCard.ledCard.calibrationIntensityField.Value);
                    obj.turnOnLed(device, setting, intensity);
                end
                obj.populateDetailsForLed(device, setting);
                if isempty(obj.calibrationCard.ledCard.spotDiameterField.Value)
                    focus(obj.calibrationCard.ledCard.spotDiameterField);
                else
                    focus(obj.calibrationCard.ledCard.powerReadingField);
                end
            end
            obj.updateStateOfControls();
        end

        function selectNextDevice(obj)
            oldIdx = obj.calibrationCard.deviceListBox.Value;
            dsList = obj.calibrationCard.deviceSettingList;
            n = numel(dsList);
            if isempty(oldIdx) || n == 0
                return;
            end
            newIdx = mod(oldIdx, n) + 1;
            ds = dsList{newIdx};
            obj.selectDevice(ds.device, ds.setting);
        end

        function setSelectedDevice(obj, device, setting)
            % Find the index in deviceSettingList that matches this device+setting
            dsList = obj.calibrationCard.deviceSettingList;
            for i = 1:numel(dsList)
                ds = dsList{i};
                if ds.device == device && strcmp(ds.setting, setting)
                    obj.calibrationCard.deviceListBox.Value = i;
                    return;
                end
            end
        end

        function [device, setting] = getSelectedDevice(obj)
            idx = obj.calibrationCard.deviceListBox.Value;
            if isempty(idx)
                device = [];
                setting = [];
                return;
            end
            ds = obj.calibrationCard.deviceSettingList{idx};
            device = ds.device;
            setting = ds.setting;
        end

        function populateDetailsForLed(obj, led, setting)
            [names, values, tbl] = obj.getPreviousCalibrationDisplayNames(led, setting);
            obj.calibrationCard.ledCard.useCalibrationPopupMenu.Items = names;
            obj.calibrationCard.ledCard.useCalibrationPopupMenu.ItemsData = values;
            hasPrev = ~isempty(tbl);
            obj.calibrationCard.ledCard.useCalibrationPopupMenu.Enable = hasPrev;
            obj.calibrationCard.ledCard.viewButton.Enable = hasPrev;
            obj.calibrationCard.ledCard.useButton.Enable = hasPrev;
            if isempty(led)
                obj.calibrationCard.ledCard.calibrationUnitsField.Value = '';
            else
                obj.calibrationCard.ledCard.calibrationUnitsField.Value = led.background.displayUnits;
            end

            calibration = [];
            if ~isempty(led) && obj.calibrations.isKey(led.name) && obj.calibrations(led.name).isKey(setting)
                m = obj.calibrations(led.name);
                calibration = m(setting);
            end
            if isempty(calibration)
                obj.calibrationCard.ledCard.powerReadingField.Value = '';
                obj.calibrationCard.ledCard.noteField.Value = '';
            else
                obj.calibrationCard.ledCard.spotDiameterField.Value = num2str(calibration.diameter);
                obj.calibrationCard.ledCard.powerReadingField.Value = num2str(calibration.power);
                obj.calibrationCard.ledCard.noteField.Value = calibration.note;
            end

            obj.calibrationCard.detailCardPanel.SelectedTab = obj.calibrationCard.detailCardPanel.Children(1);
        end

        function populateDetailsForStage(obj, stageDevice, setting)
            [names, values, tbl] = obj.getPreviousCalibrationDisplayNames(stageDevice, setting);
            obj.calibrationCard.stageCard.useCalibrationPopupMenu.Items = names;
            obj.calibrationCard.stageCard.useCalibrationPopupMenu.ItemsData = values;
            hasPrev = ~isempty(tbl);
            obj.calibrationCard.stageCard.useCalibrationPopupMenu.Enable = hasPrev;
            obj.calibrationCard.stageCard.viewButton.Enable = hasPrev;
            obj.calibrationCard.stageCard.useButton.Enable = hasPrev;

            calibration = [];
            if obj.calibrations.isKey(stageDevice.name) && obj.calibrations(stageDevice.name).isKey(setting)
                m = obj.calibrations(stageDevice.name);
                calibration = m(setting);
            end
            if isempty(calibration)
                obj.calibrationCard.stageCard.powerReadingField.Value = '';
                obj.calibrationCard.stageCard.noteField.Value = '';
            else
                obj.calibrationCard.stageCard.powerReadingField.Value = num2str(calibration.power);
                obj.calibrationCard.stageCard.noteField.Value = calibration.note;
            end

            obj.calibrationCard.detailCardPanel.SelectedTab = obj.calibrationCard.detailCardPanel.Children(2);
        end

        function [n, v, t] = getPreviousCalibrationDisplayNames(obj, device, setting)
            t = obj.getPreviousCalibrationTable(device, setting);
            if isempty(t)
                n = {'(None)'};
                v = {[]};
            else
                n = cell(1, height(t));
                v = cell(1, height(t));
                for i = 1:height(t)
                    n{i} = [datestr(t.date(i), 'dd-mmm-yyyy HH:MM PM') ' (' t.user{i}];
                    if iscellstr(t.note(i)) && ~isempty(t.note{i})
                        n{i} = [n{i} ': ' t.note{i}];
                    end
                    n{i} = [n{i} ')'];
                    v{i} = t(i, :);
                end
            end
        end

        function t = getPreviousCalibrationTable(obj, device, setting)
            t = table;
            if ~isempty(device) && obj.previousCalibrations.isKey(device.name) && obj.previousCalibrations(device.name).isKey(setting)
                m = obj.previousCalibrations(device.name);
                t = m(setting);
            end
        end

        function viewPreviousCalibrationTable(obj, device, setting, selectedDate)
            if nargin < 4
                selectedDate = [];
            end

            f = uifigure( ...
                'Name', [device.name ' Previous Calibration Table'], ...
                'Position', [100 100 800 400], ...
                'Resize', 'on');

            tbl = obj.getPreviousCalibrationTable(device, setting);
            if isempty(selectedDate)
                selectedRow = [];
            else
                selectedRow = find(tbl.date == selectedDate, 1);
            end
            tbl.date = datestr(tbl.date, 'dd-mmm-yyyy HH:MM PM');
            tbl.factor = [];
            columnNames = cellfun(@(n)obj.humanize(n), tbl.Properties.VariableNames, 'UniformOutput', false);

            mainLayout = uigridlayout(f, [1 1]);
            mainLayout.Padding = [0 0 0 0];
            uit = uitable(mainLayout, ...
                'ColumnName', columnNames, ...
                'Data', table2cell(tbl), ...
                'ColumnEditable', false);
            if ~isempty(selectedRow)
                scroll(uit, 'row', selectedRow);
            end
        end

        function onSelectedLedView(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            entry = obj.calibrationCard.ledCard.useCalibrationPopupMenu.Value;
            obj.viewPreviousCalibrationTable(device, setting, entry.date);
        end

        function onSelectedLedUse(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            if device == obj.stage
                return;
            end

            entry = obj.calibrationCard.ledCard.useCalibrationPopupMenu.Value;
            success = obj.calibrateDevice(device, setting, entry.intensity, entry.diameter, entry.power, entry.note, true);
            if ~success
                return;
            end

            obj.selectNextDevice();
            obj.updateStateOfControls();
        end

        function success = calibrateDevice(obj, device, setting, intensity, diameter, power, note, reused)
            if nargin < 8
                reused = false;
            end

            if obj.isDeviceCalibrated(device, setting)
                result = uiconfirm(obj.figureHandle, ...
                    'This device has already been calibrated. Are you sure you want overwrite the current value?', ...
                    'Overwrite', ...
                    'Options', {'Cancel', 'Overwrite'}, ...
                    'DefaultOption', 'Cancel');
                if ~strcmp(result, 'Overwrite')
                    success = false;
                    return;
                end
            end

            ssize = pi * diameter * diameter / 4;
            factor = power / (ssize * intensity);

            prevTable = obj.getPreviousCalibrationTable(device, setting);
            if ~isempty(prevTable)
                old = prevTable.factor(1);
                diff = abs(factor - old) / ((factor + old) / 2);
                if diff > 0.1
                    percent = diff * 100;
                    result = uiconfirm(obj.figureHandle, ...
                        ['The calculated photon flux conversion factor is ' ...
                        num2str(round(10*percent)/10) '% different than the most recent calibrated value. ' ...
                        'Are you sure you want to submit this value?'], ...
                        'Warning', ...
                        'Options', {'Cancel', 'Submit'}, ...
                        'DefaultOption', 'Cancel');
                    if ~strcmp(result, 'Submit')
                        success = false;
                        return;
                    end
                end
            end

            if obj.calibrations.isKey(device.name)
                m = obj.calibrations(device.name);
            else
                m = containers.Map();
            end
            m(setting) = struct( ...
                'date', datetime(), ...
                'user', char(System.Environment.UserName), ...
                'intensity', intensity, ...
                'diameter', diameter, ...
                'power', power, ...
                'factor', factor, ...
                'note', note, ...
                'reused', reused);
            obj.calibrations(device.name) = m;
            obj.setDeviceCalibrated(device, setting);
            success = true;
        end

        function tf = isDeviceCalibrated(obj, device, setting)
            tf = any(strcmp('fluxFactors', device.getResourceNames())) || ...
                (obj.calibrations.isKey(device.name) && obj.calibrations(device.name).isKey(setting));
        end

        function setDeviceCalibrated(obj, device, setting)
            names = obj.calibrationCard.deviceListBox.Items;
            dsList = obj.calibrationCard.deviceSettingList;

            % Find the matching entry by device handle and setting
            for i = 1:numel(dsList)
                ds = dsList{i};
                if ds.device == device && strcmp(ds.setting, setting)
                    n = [char(9989) ' ' device.name];
                    if ~strcmp(setting, 'none')
                        n = [n ' - ' setting];
                    end
                    names{i} = n;
                    break;
                end
            end

            obj.calibrationCard.deviceListBox.Items = names;
            obj.calibrationCard.deviceListBox.ItemsData = 1:numel(names);
        end

        function onSelectedLedReset(obj, ~, ~)
            obj.turnOffAllDevices();
            obj.calibrationCard.ledCard.powerReadingField.Value = '';
            obj.isCalibrating = false;
            obj.updateStateOfControls();
        end

        function onSelectedLedOn(obj, ~, ~)
            obj.turnOffAllDevices();

            turnOn = obj.calibrationCard.ledCard.ledOnButton.Value;
            if turnOn
                [led, setting] = obj.getSelectedDevice();
                intensity = str2double(obj.calibrationCard.ledCard.calibrationIntensityField.Value);
                obj.turnOnLed(led, setting, intensity);
                obj.isCalibrating = true;
            end

            obj.updateStateOfControls();
        end

        function turnOnLed(obj, led, setting, intensity) %#ok<INUSL>
            try
                led.background = symphonyui.core.Measurement(intensity, led.background.displayUnits);
                led.applyBackground();
                obj.isLedOn = true;
            catch x
                uialert(obj.figureHandle, ['Unable to turn on LED: ' x.message], 'Error');
                if strcmp(led.background.baseUnits, 'V')
                    led.background = symphonyui.core.Measurement(-1, led.background.displayUnits);
                    led.applyBackground();
                else
                    led.background = symphonyui.core.Measurement(0, led.background.displayUnits);
                    led.applyBackground();
                end
                obj.isLedOn = false;
                return;
            end
        end

        function turnOffLeds(obj, force)
            if ~obj.isLedOn && ~force
                return;
            end
            for i = 1:numel(obj.leds)
                led = obj.leds{i};
                if strcmp(led.background.baseUnits, 'V')
                    led.background = symphonyui.core.Measurement(-1, led.background.displayUnits);
                    led.applyBackground();
                else
                    led.background = symphonyui.core.Measurement(0, led.background.displayUnits);
                    led.applyBackground();
                end
            end
            obj.isLedOn = false;
        end

        function onSelectedStageView(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            entry = obj.calibrationCard.stageCard.useCalibrationPopupMenu.Value;
            obj.viewPreviousCalibrationTable(device, setting, entry.date);
        end

        function onSelectedStageUse(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            if device ~= obj.stage
                return;
            end

            entry = obj.calibrationCard.stageCard.useCalibrationPopupMenu.Value;
            success = obj.calibrateDevice(device, setting, entry.intensity, entry.diameter, entry.power, entry.note, true);
            if ~success
                return;
            end

            obj.selectNextDevice();
            obj.updateStateOfControls();
        end

        function onSelectedStageReset(obj, ~, ~)
            obj.turnOffAllDevices();
            obj.calibrationCard.stageCard.powerReadingField.Value = '';
            obj.isCalibrating = false;
            obj.updateStateOfControls();
        end

        function onSelectedStageOn(obj, ~, ~)
            obj.turnOffAllDevices();

            turnOn = obj.calibrationCard.stageCard.stageOnButton.Value;
            if turnOn
                [device, setting] = obj.getSelectedDevice();
                intensity = str2double(obj.calibrationCard.stageCard.calibrationIntensityField.Value);
                diameter = str2double(obj.calibrationCard.stageCard.spotDiameterField.Value);
                obj.turnOnStage(device, setting, intensity, diameter);
                obj.isCalibrating = true;
            end

            obj.updateStateOfControls();
        end

        function turnOnStage(obj, device, setting, intensity, diameter)
            try
                if ~strcmpi(setting, 'none')
                    if ~isempty(regexpi(obj.stage.name, 'Microdisplay', 'once'))
                        obj.stage.setBrightness(setting);
                    elseif ~isempty(regexpi(obj.stage.name, 'LightCrafter', 'once'))
                        obj.stage.setSingleLedEnable(setting);
                    end
                end

                p = stage.core.Presentation(1/device.getMonitorRefreshRate()); %#ok<PROPLC>

                spot = stage.builtin.stimuli.Ellipse(); %#ok<PROPLC>
                spot.position = device.getCanvasSize()/2;

                % Set spot color based on the device setting.
                % For 'red', 'green', 'blue': use the corresponding RGB color
                % scaled by intensity. For 'auto', 'white', or anything else:
                % use white (grayscale intensity).
                switch lower(setting)
                    case 'red'
                        spot.color = [intensity 0 0];
                    case 'green'
                        spot.color = [0 intensity 0];
                    case 'blue'
                        spot.color = [0 0 intensity];
                    otherwise  % 'auto', 'white', 'none', etc.
                        spot.color = intensity;
                end

                spot.radiusX = device.um2pix(diameter/2);
                spot.radiusY = device.um2pix(diameter/2);
                p.addStimulus(spot);

                device.play(p);
                info = device.getPlayInfo();
                if isa(info, 'MException')
                    error(info.message);
                end
                obj.isStageOn = true;
            catch x
                uialert(obj.figureHandle, ['Unable to turn on stage: ' x.message], 'Error');
                device.play(stage.core.Presentation(1/device.getMonitorRefreshRate())); %#ok<PROPLC>
                device.getPlayInfo();
                obj.isStageOn = false;
                return;
            end
        end

        function turnOffStage(obj, force)
            if isempty(obj.stage) || (~obj.isStageOn && ~force)
                return;
            end
            if ~isempty(regexpi(obj.stage.name, 'Microdisplay', 'once'))
                obj.stage.setBrightness('minimum');
            elseif ~isempty(regexpi(obj.stage.name, 'LightCrafter', 'once'))
                obj.stage.setSingleLedEnable('auto');
            end
            obj.stage.play(stage.core.Presentation(1/obj.stage.getMonitorRefreshRate())); %#ok<PROPLC>
            obj.stage.getPlayInfo();
            obj.isStageOn = false;
        end

        function turnOffAllDevices(obj, force)
            if nargin < 2
                force = false;
            end
            obj.turnOffLeds(force);
            obj.turnOffStage(force);
        end

        function onSelectedLedSubmit(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            if device == obj.stage
                return;
            end

            intensity = str2double(obj.calibrationCard.ledCard.calibrationIntensityField.Value);
            diameter = str2double(obj.calibrationCard.ledCard.spotDiameterField.Value);
            power = str2double(obj.calibrationCard.ledCard.powerReadingField.Value);
            if isnan(intensity) || isnan(diameter) || isnan(power)
                uialert(obj.figureHandle, 'Could not parse intensity, diameter, or power to a valid scalar value.', 'Error');
                return;
            end
            note = obj.calibrationCard.ledCard.noteField.Value;

            obj.submit(device, setting, intensity, diameter, power, note);
        end

        function onSelectedStageSubmit(obj, ~, ~)
            [device, setting] = obj.getSelectedDevice();
            if device ~= obj.stage
                return;
            end

            intensity = str2double(obj.calibrationCard.stageCard.calibrationIntensityField.Value);
            diameter = str2double(obj.calibrationCard.stageCard.spotDiameterField.Value);
            power = str2double(obj.calibrationCard.stageCard.powerReadingField.Value);
            if isnan(intensity) || isnan(diameter) || isnan(power)
                uialert(obj.figureHandle, 'Could not parse intensity, diameter, or power to a valid scalar value.', 'Error');
                return;
            end
            note = obj.calibrationCard.stageCard.noteField.Value;

            obj.submit(device, setting, intensity, diameter, power, note);
        end

        function submit(obj, device, setting, intensity, diameter, power, note)
            success = obj.calibrateDevice(device, setting, intensity, diameter, power, note);
            if ~success
                return;
            end

            obj.selectNextDevice();
            obj.updateStateOfControls();
        end

        function onSelectedBack(obj, ~, ~)
            tabs = obj.wizardTabGroup.Children;
            currentTab = obj.wizardTabGroup.SelectedTab;
            idx = find(tabs == currentTab, 1);
            if idx > 1
                obj.wizardTabGroup.SelectedTab = tabs(idx - 1);
            end

            obj.updateStateOfControls();
        end

        function onSelectedNext(obj, ~, ~)
            tabs = obj.wizardTabGroup.Children;
            currentTab = obj.wizardTabGroup.SelectedTab;
            idx = find(tabs == currentTab, 1);

            if idx < numel(tabs)
                obj.wizardTabGroup.SelectedTab = tabs(idx + 1);
            end

            if strcmp(obj.nextButton.Text, 'Finish')
                obj.saveCalibration();
                obj.turnOffAllDevices();
                obj.stop();
            else
                obj.turnOffAllDevices(true);
                [device, setting] = obj.getSelectedDevice();
                obj.selectDevice(device, setting);
            end
        end

        function saveCalibration(obj)
            keys = obj.calibrations.keys;
            for i = 1:numel(keys)
                name = keys{i};
                device = obj.allDevices{cellfun(@(l)strcmp(l.name, name), obj.allDevices)};

                if any(strcmp('fluxFactors', device.getResourceNames()))
                    device.removeResource('fluxFactors');
                end
                if ~obj.calibrations.isKey(name)
                    continue;
                end
                cal = obj.calibrations(name);
                settings = cal.keys;
                factors = containers.Map();
                for k = 1:numel(settings)
                    factors(settings{k}) = cal(settings{k}).factor;
                end
                if device == obj.stage && ~isempty(regexpi(obj.stage.name, 'Microdisplay', 'once'))
                    factors('minimum') = 0;
                    factors('maximum') = 0;
                    factors = calculateFactorsFromSpectrum(factors, device.getResource('spectrum'));
                end
                device.addResource('fluxFactors', factors);

                if ~obj.previousCalibrations.isKey(name)
                    continue;
                end
                prevCal = obj.previousCalibrations(name);

                if ~any(strcmp('fluxFactorPaths', device.getResourceNames()))
                    continue;
                end
                paths = device.getResource('fluxFactorPaths');

                for k = 1:numel(settings)
                    setting = settings{k};
                    if prevCal.isKey(setting)
                        t = prevCal(setting);
                    else
                        t = table();
                    end
                    entry = struct2table(cal(setting), 'AsArray', true);
                    if entry.reused
                        continue;
                    end
                    entry.reused = [];
                    t(end + 1, :) = entry; %#ok<AGROW>
                    writetable(t, paths(setting), 'Delimiter', 'tab');
                    prevCal(setting) = t;
                end

                obj.previousCalibrations(name) = prevCal;
            end
        end

        function onSelectedCancel(obj, ~, ~)
            obj.close();
        end

        function close(obj)
            shouldClose = true;
            if ~isempty(obj.calibrations)
                result = uiconfirm(obj.figureHandle, ...
                    ['You have calibrated some devices. You will lose these values if you close the calibrator. ' ...
                    'Are you sure you want to close?'], 'Close', ...
                    'Options', {'Cancel', 'Close'}, ...
                    'DefaultOption', 'Cancel');
                shouldClose = strcmp(result, 'Close');
            end
            if shouldClose
                obj.stop();
            end
        end

        function updateStateOfControls(obj)
            device = obj.getSelectedDevice();

            hasDevice = ~isempty(device);
            tabs = obj.wizardTabGroup.Children;
            currentTab = obj.wizardTabGroup.SelectedTab;
            idx = find(tabs == currentTab, 1);
            isLastCard = idx >= numel(tabs);
            allCalibrated = all(cellfun(@(s)obj.isDeviceCalibrated(s.device, s.setting), ...
                obj.calibrationCard.deviceSettingList));

            obj.calibrationCard.ledCard.calibrationIntensityField.Editable = hasDevice && ~obj.isCalibrating;
            obj.calibrationCard.ledCard.resetButton.Enable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.ledCard.ledOnButton.Enable = hasDevice;
            obj.calibrationCard.ledCard.ledOnButton.Value = obj.isLedOn;
            obj.calibrationCard.ledCard.spotDiameterField.Editable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.ledCard.powerReadingField.Editable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.ledCard.noteField.Editable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.ledCard.submitButton.Enable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.stageCard.calibrationIntensityField.Editable = hasDevice && ~obj.isCalibrating;
            obj.calibrationCard.stageCard.resetButton.Enable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.stageCard.spotDiameterField.Editable = hasDevice && ~obj.isCalibrating;
            obj.calibrationCard.stageCard.stageOnButton.Enable = hasDevice;
            obj.calibrationCard.stageCard.stageOnButton.Value = obj.isStageOn;
            obj.calibrationCard.stageCard.powerReadingField.Editable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.stageCard.noteField.Editable = hasDevice && obj.isCalibrating;
            obj.calibrationCard.stageCard.submitButton.Enable = hasDevice && obj.isCalibrating;
            obj.backButton.Enable = isLastCard;
            obj.nextButton.Enable = ~isLastCard || allCalibrated;
            if isLastCard
                obj.nextButton.Text = 'Finish';
            else
                obj.nextButton.Text = 'Next >';
            end
        end

    end

    methods (Access = private, Static)

        function s = humanize(str)
            % Convert camelCase to Title Case with spaces.
            s = regexprep(str, '([a-z])([A-Z])', '$1 $2');
            s(1) = upper(s(1));
        end

    end

end

function factors = calculateFactorsFromSpectrum(factors, spectrum)

    r = spectrum('red');
    g = spectrum('green');
    b = spectrum('blue');

    r(:,2) = common.util.lowPassFilter(r(:,2), 25, 1/numel(r(:,2)));
    g(:,2) = common.util.lowPassFilter(g(:,2), 25, 1/numel(g(:,2)));
    b(:,2) = common.util.lowPassFilter(b(:,2), 25, 1/numel(b(:,2)));

    ri = trapz(r(:,1), r(:,2));
    gi = trapz(g(:,1), g(:,2));
    bi = trapz(b(:,1), b(:,2));
    wi = ri + gi + bi;

    keys = factors.keys;
    for i = 1:numel(keys)
        k = keys{i};
        f = factors(k);
        factors(k) = containers.Map( ...
            {'white', 'red', 'green', 'blue'}, ...
            {f*(wi/wi), f*(ri/wi), f*(gi/wi), f*(bi/wi)});
    end
end
