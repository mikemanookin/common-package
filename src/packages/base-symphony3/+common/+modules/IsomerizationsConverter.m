classdef IsomerizationsConverter < symphonyui.ui.Module

    properties (Access = private)
        settings
        leds
        stage
        deviceListeners
        epochGroup
        epochGroupListeners
        species
        speciesListeners
        preparation
        preparationListeners
    end

    properties (Access = private)
        mainLayout
        parametersControls
        converterControls
        converterLayout
    end

    methods

        function obj = IsomerizationsConverter()
            obj.settings = common.modules.settings.IsomerizationsConverterSettings();
        end

        function createUi(obj, figureHandle)
            figureHandle.Name = 'Isomerizations Converter';
            figureHandle.Position(3:4) = [273 313];
            figureHandle.Resize = 'off';

            obj.mainLayout = uigridlayout(figureHandle, ...
                'RowHeight', {'fit', 'fit'}, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [0 0 0 0], ...
                'RowSpacing', 0);

            % --- Parameters Panel ---
            parametersPanel = uipanel(obj.mainLayout, ...
                'Title', 'Parameters', ...
                'BorderType', 'none');
            parametersPanel.Layout.Row = 1;
            parametersPanel.Layout.Column = 1;

            parametersGrid = uigridlayout(parametersPanel, ...
                'RowHeight', {23, 23, 23, 23, 23, 23}, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [11 11 11 11], ...
                'RowSpacing', 7);

            % Device row
            deviceGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            deviceGrid.Layout.Row = 1;
            deviceGrid.Layout.Column = 1;
            uilabel(deviceGrid, 'Text', 'Device:');
            obj.parametersControls.devicePopupMenu = uidropdown(deviceGrid, ...
                'Items', {' '}, ...
                'ItemsData', {[]}, ...
                'ValueChangedFcn', @obj.onSelectedDevice);
            uibutton(deviceGrid, ...
                'Text', '?', ...
                'Tooltip', 'Device Help', ...
                'ButtonPushedFcn', @obj.onSelectedDeviceHelp);

            % NDFs row
            ndfsGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            ndfsGrid.Layout.Row = 2;
            ndfsGrid.Layout.Column = 1;
            uilabel(ndfsGrid, 'Text', 'NDFs:');
            obj.parametersControls.ndfsField = uieditfield(ndfsGrid, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(ndfsGrid, ...
                'Text', '?', ...
                'Tooltip', 'NDFs Help', ...
                'ButtonPushedFcn', @obj.onSelectedNdfsHelp);

            % Gain/Brightness card area - use a grid with two panels, show/hide
            settingGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [0 0 0 0]);
            settingGrid.Layout.Row = 3;
            settingGrid.Layout.Column = 1;

            % Gain panel
            obj.parametersControls.gainPanel = uigridlayout(settingGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            obj.parametersControls.gainPanel.Layout.Row = 1;
            obj.parametersControls.gainPanel.Layout.Column = 1;
            uilabel(obj.parametersControls.gainPanel, 'Text', 'Gain:');
            obj.parametersControls.gainField = uieditfield(obj.parametersControls.gainPanel, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(obj.parametersControls.gainPanel, ...
                'Text', '?', ...
                'Tooltip', 'Gain Help', ...
                'ButtonPushedFcn', @obj.onSelectedGainHelp);

            % Brightness panel
            obj.parametersControls.brightnessPanel = uigridlayout(settingGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            obj.parametersControls.brightnessPanel.Layout.Row = 1;
            obj.parametersControls.brightnessPanel.Layout.Column = 1;
            uilabel(obj.parametersControls.brightnessPanel, 'Text', 'Brightness:');
            obj.parametersControls.brightnessField = uieditfield(obj.parametersControls.brightnessPanel, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(obj.parametersControls.brightnessPanel, ...
                'Text', '?', ...
                'Tooltip', 'Brightness Help', ...
                'ButtonPushedFcn', @obj.onSelectedBrightnessHelp);

            % Default: show gain, hide brightness
            obj.parametersControls.gainPanel.Visible = 'on';
            obj.parametersControls.brightnessPanel.Visible = 'off';

            % Light Path row
            pathGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            pathGrid.Layout.Row = 4;
            pathGrid.Layout.Column = 1;
            uilabel(pathGrid, 'Text', 'Light Path:');
            obj.parametersControls.lightPathField = uieditfield(pathGrid, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(pathGrid, ...
                'Text', '?', ...
                'Tooltip', 'Light Path Help', ...
                'ButtonPushedFcn', @obj.onSelectedLightPathHelp);

            % Species row
            speciesGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            speciesGrid.Layout.Row = 5;
            speciesGrid.Layout.Column = 1;
            uilabel(speciesGrid, 'Text', 'Species:');
            obj.parametersControls.speciesField = uieditfield(speciesGrid, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(speciesGrid, ...
                'Text', '?', ...
                'Tooltip', 'Species Help', ...
                'ButtonPushedFcn', @obj.onSelectedSpeciesHelp);

            % Preparation row
            prepGrid = uigridlayout(parametersGrid, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {70, '1x', 22}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 7);
            prepGrid.Layout.Row = 6;
            prepGrid.Layout.Column = 1;
            uilabel(prepGrid, 'Text', 'Preparation:');
            obj.parametersControls.preparationField = uieditfield(prepGrid, ...
                'HorizontalAlignment', 'left', ...
                'Editable', 'off');
            uibutton(prepGrid, ...
                'Text', '?', ...
                'Tooltip', 'Preparation Help', ...
                'ButtonPushedFcn', @obj.onSelectedPreparationHelp);

            % --- Converter Panel ---
            obj.converterControls.panel = uipanel(obj.mainLayout, ...
                'Title', 'Converter', ...
                'BorderType', 'none');
            obj.converterControls.panel.Layout.Row = 2;
            obj.converterControls.panel.Layout.Column = 1;
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
            if obj.documentationService.hasOpenFile()
                obj.epochGroup = obj.documentationService.getCurrentEpochGroup();
            else
                obj.epochGroup = [];
            end
            obj.species = obj.findSpecies();
            obj.preparation = obj.findPreparation();

            obj.populateParametersBox();
            obj.populateConverterBox();

            try
                obj.loadSettings();
            catch x %#ok<NASGU>
                % Failed to load settings, ignore
            end

            obj.pack();
        end

        function willStop(obj)
            try
                obj.saveSettings();
            catch x %#ok<NASGU>
                % Failed to save settings, ignore
            end
        end

        function bind(obj)
            bind@symphonyui.ui.Module(obj);

            obj.bindDevices();
            obj.bindEpochGroup();
            obj.bindSpecies();
            obj.bindPreparation();

            d = obj.documentationService;
            obj.addListener(d, 'BeganEpochGroup', @obj.onServiceBeganEpochGroup);
            obj.addListener(d, 'EndedEpochGroup', @obj.onServiceEndedEpochGroup);
            obj.addListener(d, 'ClosedFile', @obj.onServiceClosedFile);

            c = obj.configurationService;
            obj.addListener(c, 'InitializedRig', @obj.onServiceInitializedRig);
        end

    end

    methods (Access = private)

        function bindDevices(obj)
            d = obj.allDevices;
            for i = 1:numel(d)
                obj.deviceListeners{end + 1} = obj.addListener(d{i}, 'AddedConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
                obj.deviceListeners{end + 1} = obj.addListener(d{i}, 'SetConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
                obj.deviceListeners{end + 1} = obj.addListener(d{i}, 'RemovedConfigurationSetting', @obj.onDeviceChangedConfigurationSetting);
                obj.deviceListeners{end + 1} = obj.addListener(d{i}, 'AddedResource', @obj.onDeviceAddedResource);
            end

            if ~isempty(obj.stage) && ~isempty(regexpi(obj.stage.name, 'Microdisplay', 'once'))
                obj.deviceListeners{end + 1} = obj.addListener(d{i}, 'SetBrightness', @obj.onStageSetBrightness);
            end
        end

        function unbindDevices(obj)
            while ~isempty(obj.deviceListeners)
                obj.removeListener(obj.deviceListeners{1});
                obj.deviceListeners(1) = [];
            end
        end

        function d = allDevices(obj)
            d = obj.leds;
            if ~isempty(obj.stage)
                d = [{} d {obj.stage}];
            end
        end

        function populateParametersBox(obj)
            obj.populateDeviceList();
            obj.populateNdfs();
            obj.populateGainOrBrightness();
            obj.populateLightPath();
            obj.populateSpecies();
            obj.populatePreparation();
        end

        function populateDeviceList(obj)
            names = cell(1, numel(obj.leds));
            values = cell(1, numel(obj.leds));
            for i = 1:numel(obj.leds)
                led = obj.leds{i};
                names{i} = led.name;
                values{i} = struct('device', led, 'setting', 'none');
            end

            if ~isempty(obj.stage)
                if ~isempty(regexpi(obj.stage.name, 'Microdisplay', 'once'))
                    colors = {'white', 'red', 'green', 'blue'};
                elseif ~isempty(regexpi(obj.stage.name, 'LightCrafter', 'once'))
                    colors = {'auto', 'red', 'green', 'blue'};
                elseif ~isempty(regexpi(obj.stage.name, 'LcrVideo', 'once'))
                    colors = {'auto', 'red', 'green', 'blue'};
                else
                    colors = {'none'};
                end
                for i = 1:numel(colors)
                    c = colors{i};
                    names{end + 1} = [obj.stage.name ' - ' c]; %#ok<AGROW>
                    values{end + 1} = struct('device', obj.stage, 'setting', c); %#ok<AGROW>
                end
            end

            if numel(obj.allDevices) > 0
                obj.parametersControls.devicePopupMenu.Items = names;
                obj.parametersControls.devicePopupMenu.ItemsData = values;
                obj.parametersControls.devicePopupMenu.Enable = 'on';
            else
                obj.parametersControls.devicePopupMenu.Items = {'(None)'};
                obj.parametersControls.devicePopupMenu.ItemsData = {[]};
                obj.parametersControls.devicePopupMenu.Enable = 'off';
            end
        end

        function onSelectedDevice(obj, ~, ~)
            obj.populateNdfs();
            obj.populateGainOrBrightness();
            obj.populateLightPath();
            obj.populateConverterBox();
            obj.pack();
        end

        function onSelectedDeviceHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['Select the device for which to perform isomerizations conversions. This popup menu ' ...
                'is populated based on the devices in the currently initialized rig.'], 'Device Help', ...
                'Icon', 'info');
        end

        function populateNdfs(obj)
            v = obj.parametersControls.devicePopupMenu.Value;
            if isempty(v)
                obj.parametersControls.ndfsField.Value = '';
            else
                ndfs = v.device.getConfigurationSetting('ndfs');
                obj.parametersControls.ndfsField.Value = strjoin(ndfs, '; ');
            end
        end

        function onSelectedNdfsHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The ndfs field is auto-populated by the value of the ''ndfs'' configuration ' ...
                'setting on the selected device. Device configuration settings may be changed through the ''Device ' ...
                'Configurator'' module.'], 'NDFs Help', ...
                'Icon', 'info');
        end

        function populateGainOrBrightness(obj)
            v = obj.parametersControls.devicePopupMenu.Value;
            if isempty(v)
                obj.parametersControls.brightnessField.Value = '';
                obj.parametersControls.gainField.Value = '';
                obj.parametersControls.gainPanel.Visible = 'off';
                obj.parametersControls.brightnessPanel.Visible = 'on';
            elseif v.device == obj.stage
                obj.parametersControls.gainField.Value = '';
                if ismethod(v.device, 'getBrightness')
                    obj.parametersControls.brightnessField.Value = char(v.device.getBrightness());
                else
                    obj.parametersControls.brightnessField.Value = 'N/A';
                end
                obj.parametersControls.gainPanel.Visible = 'off';
                obj.parametersControls.brightnessPanel.Visible = 'on';
            else
                if v.device.hasConfigurationSetting('gain')
                    obj.parametersControls.gainField.Value = v.device.getConfigurationSetting('gain');
                else
                    obj.parametersControls.gainField.Value = 'N/A';
                end
                obj.parametersControls.brightnessField.Value = '';
                obj.parametersControls.gainPanel.Visible = 'on';
                obj.parametersControls.brightnessPanel.Visible = 'off';
            end
        end

        function onStageSetBrightness(obj, handle, ~)
            v = obj.parametersControls.devicePopupMenu.Value;
            if handle ~= v.device
                return;
            end

            obj.populateGainOrBrightness();
            obj.populateConverterBox();
            obj.pack();
        end

        function onSelectedGainHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The gain field is auto-populated by the value of the ''gain'' configuration ' ...
                'setting on the selected device. Device configuration settings may be changed through the ''Device ' ...
                'Configurator'' module.'], 'Gain Help', ...
                'Icon', 'info');
        end

        function onSelectedBrightnessHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The brightness field is auto-populated by the value of the ''brightness'' ' ...
                'setting on the Stage device. Brightness settings may be changed through the specific ''Stage ' ...
                'Control'' module.'], 'Brightness Help', ...
                'Icon', 'info');
        end

        function populateLightPath(obj)
            v = obj.parametersControls.devicePopupMenu.Value;
            if isempty(v)
                obj.parametersControls.lightPathField.Value = '';
            else
                path = v.device.getConfigurationSetting('lightPath');
                obj.parametersControls.lightPathField.Value = path;
            end
        end

        function onSelectedLightPathHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The light path field is auto-populated by the value of the ''lightPath'' configuration ' ...
                'setting on the selected device. Device configuration settings may be changed through the ''Device ' ...
                'Configurator'' module.'], 'Light Path Help', ...
                'Icon', 'info');
        end

        function bindEpochGroup(obj)
            if ~obj.documentationService.hasOpenFile()
                return;
            end
            group = obj.documentationService.getCurrentEpochGroup();
            if ~isempty(group)
                obj.epochGroupListeners{end + 1} = obj.addListener(group, 'source', 'PostSet', @obj.onEpochGroupSetSource);
            end
        end

        function unbindEpochGroup(obj)
            while ~isempty(obj.epochGroupListeners)
                obj.removeListener(obj.epochGroupListeners{1});
                obj.epochGroupListeners(1) = [];
            end
        end

        function onEpochGroupSetSource(obj, ~, ~)
            obj.unbindSpecies();
            obj.species = obj.findSpecies();
            obj.bindSpecies();

            obj.unbindPreparation();
            obj.preparation = obj.findPreparation();
            obj.bindPreparation();

            obj.populateSpecies();
            obj.populatePreparation();
            obj.populateConverterBox();

            obj.pack();
        end

        function populateSpecies(obj)
            if isempty(obj.species)
                obj.parametersControls.speciesField.Value = '';
            else
                obj.parametersControls.speciesField.Value = obj.species.label;
            end
        end

        function s = findSpecies(obj)
            s = [];
            if isempty(obj.epochGroup)
                return;
            end

            source = obj.epochGroup.source;
            while ~isempty(source) && ~any(strcmp(source.getResourceNames(), 'photoreceptors'))
                source = source.parent;
            end
            s = source;
        end

        function bindSpecies(obj)
            if ~isempty(obj.species)
                obj.speciesListeners{end + 1} = obj.addListener(obj.species, 'label', 'PostSet', @obj.onSpeciesSetLabel);
            end
        end

        function unbindSpecies(obj)
            while ~isempty(obj.speciesListeners)
                obj.removeListener(obj.speciesListeners{1});
                obj.speciesListeners(1) = [];
            end
        end

        function onSpeciesSetLabel(obj, ~, ~)
            obj.populateSpecies();
        end

        function onSelectedSpeciesHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The species field is auto-populated based on the species of the source of the ' ...
                'current epoch group. If there is no current epoch group, this field will be empty.'], 'Species Help', ...
                'Icon', 'info');
        end

        function populatePreparation(obj)
            if isempty(obj.preparation) || isempty(obj.preparation.getProperty('preparation'))
                obj.parametersControls.preparationField.Value = '';
            else
                obj.parametersControls.preparationField.Value = obj.preparation.getProperty('preparation');
            end
        end

        function s = findPreparation(obj)
            s = [];
            if isempty(obj.epochGroup)
                return;
            end

            source = obj.epochGroup.source;
            while ~isempty(source) ...
                    && isempty(source.getPropertyDescriptors().findByName('preparation')) ...
                    && ~any(strcmp(source.getResourceNames(), 'photoreceptorOrientations'))
                source = source.parent;
            end
            s = source;
        end

        function bindPreparation(obj)
            if ~isempty(obj.preparation)
                obj.preparationListeners{end + 1} = obj.addListener(obj.preparation, 'SetProperty', @obj.onPreparationSetProperty);
            end
        end

        function unbindPreparation(obj)
            while ~isempty(obj.preparationListeners)
                obj.removeListener(obj.preparationListeners{1});
                obj.preparationListeners(1) = [];
            end
        end

        function onPreparationSetProperty(obj, ~, event)
            property = event.data;
            if strcmp(property.name, 'preparation')
                obj.populatePreparation();
                obj.populateConverterBox();
                obj.pack();
            end
        end

        function onSelectedPreparationHelp(obj, ~, ~)
            uialert(obj.figureHandle, ...
                ['The preparation field is auto-populated based on the preparation of the source of the ' ...
                'current epoch group. If there is no current epoch group, this field will be empty.'], 'Preparation Help', ...
                'Icon', 'info');
        end

        function populateConverterBox(obj)
            % Clear existing converter layout
            if ~isempty(obj.converterLayout) && isvalid(obj.converterLayout)
                delete(obj.converterLayout);
            end

            obj.converterLayout = uigridlayout(obj.converterControls.panel, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [11 11 11 11], ...
                'RowSpacing', 7);

            obj.converterControls.fields = containers.Map();

            [tf, msg] = obj.isValid();
            if ~tf
                obj.converterLayout.RowHeight = {23};
                uilabel(obj.converterLayout, ...
                    'Text', msg, ...
                    'HorizontalAlignment', 'center');
                return;
            end

            v = obj.parametersControls.devicePopupMenu.Value;
            units = v.device.background.baseUnits;
            if strcmp(units, 'V')
                units = 'volts';
            else strcmp(units, symphonyui.core.Measurement.UNITLESS);
                units = 'intensity';
            end

            photoreceptors = obj.species.getResource('photoreceptors');
            keys = [{} {units} photoreceptors.keys];
            rowHeights = cell(1, numel(keys));
            for i = 1:numel(keys)
                rowHeights{i} = 23;
            end
            obj.converterLayout.RowHeight = rowHeights;

            for i = 1:numel(keys)
                k = keys{i};
                rowGrid = uigridlayout(obj.converterLayout, ...
                    'RowHeight', {'1x'}, ...
                    'ColumnWidth', {70, '1x', 22}, ...
                    'Padding', [0 0 0 0], ...
                    'ColumnSpacing', 7);
                rowGrid.Layout.Row = i;
                rowGrid.Layout.Column = 1;

                if i == 1
                    label = [obj.capitalize(obj.humanize(k)) ':'];
                else
                    label = [obj.capitalize(obj.humanize(k)) ' R*/s:'];
                end
                uilabel(rowGrid, 'Text', label);
                f.control = uieditfield(rowGrid, ...
                    'Value', '0', ...
                    'HorizontalAlignment', 'left', ...
                    'ValueChangedFcn', @(h,d)obj.onFieldValueChanged(h, struct('fieldName', k)));
                obj.converterControls.fields(k) = f;
                uibutton(rowGrid, ...
                    'Text', '', ...
                    'Tooltip', 'Copy To Clipboard', ...
                    'ButtonPushedFcn', @(h,d)obj.onSelectedCopy(h, struct('fieldName', k)));
            end
        end

        function [tf, msg] = isValid(obj)
            msg = '';
            v = obj.parametersControls.devicePopupMenu.Value;
            if isempty(v) || isempty(v.device)
                msg = 'Device must not be empty';
            elseif ~any(strcmp('spectrum', v.device.getResourceNames()))
                msg = 'Device is missing spectrum';
            elseif ~any(strcmp('ndfAttenuations', v.device.getResourceNames()))
                msg = 'Device is missing ndf attenuations';
            elseif ~any(strcmp('fluxFactors', v.device.getResourceNames()))
                msg = 'Device must be calibrated';
            elseif ~v.device.hasConfigurationSetting('ndfs')
                msg = 'Device is missing ndfs setting';
            elseif v.device.hasConfigurationSetting('gain') && isempty(v.device.getConfigurationSetting('gain'))
                msg = 'Gain must not be empty';
            elseif ~v.device.hasConfigurationSetting('lightPath')
                msg = 'Device is missing light path setting';
            elseif isempty(v.device.getConfigurationSetting('lightPath'))
                msg = 'Light path must not be empty';
            elseif isempty(obj.species)
                msg = 'Species must not be empty';
            elseif isempty(obj.preparation) || isempty(obj.preparation.getProperty('preparation'))
                msg = 'Preparation must not be empty';
            end
            tf = isempty(msg);
        end

        function onFieldValueChanged(obj, handle, event)
            value = handle.Value;

            v = obj.parametersControls.devicePopupMenu.Value;
            spectrum = v.device.getResource('spectrum');
            attenuations = v.device.getResource('ndfAttenuations');
            fluxFactors = v.device.getResource('fluxFactors');
            ndfs = v.device.getConfigurationSetting('ndfs');
            path = v.device.getConfigurationSetting('lightPath');
            photoreceptors = obj.species.getResource('photoreceptors');
            prep = obj.preparation.getProperty('preparation');
            orientations = obj.preparation.getResource('photoreceptorOrientations');
            if orientations.isKey(prep)
                orientation = orientations(prep);
            else
                orientation = '';
            end
            units = v.device.background.baseUnits;
            if strcmp(units, 'V')
                units = 'volts';
            else strcmp(units, symphonyui.core.Measurement.UNITLESS);
                units = 'intensity';
            end

            if v.device == obj.stage
                spectrum = spectrum(v.setting);
                attenuations = attenuations(v.setting);
                if ismethod(v.device, 'getBrightness')
                    fluxFactors = fluxFactors(char(v.device.getBrightness));
                end
                factor = fluxFactors(v.setting);
            else
                if v.device.hasConfigurationSetting('gain')
                    factor = fluxFactors(v.device.getConfigurationSetting('gain'));
                else
                    factor = fluxFactors('none');
                end
            end

            function a = getCollectingArea(map, path, orientation)
                if (strcmpi(path, 'below') && any(strcmpi(orientation, {'down', 'lateral'}))) ...
                        || (strcmpi(path, 'above') && any(strcmpi(orientation, {'up', 'lateral'})))
                    a = map('photoreceptorSide');
                elseif (strcmpi(path, 'below') && strcmpi(orientation, 'up')) ...
                        || (strcmpi(path, 'above') && strcmpi(orientation, 'down'))
                    a = map('ganglionCellSide');
                else
                    warning('Unexpected light path or photoreceptor orientation. Using 0 for collecting area.');
                    a = 0;
                end
            end

            if strcmp(event.fieldName, units)
                voltsOrIntensity = str2double(value);
            else
                isom = str2double(value);
                collectingArea = getCollectingArea(photoreceptors(event.fieldName).collectingArea, path, orientation);
                voltsOrIntensity = common.util.convisom(isom, 'isom', factor, spectrum, ...
                    photoreceptors(event.fieldName).spectrum, collectingArea, ndfs, attenuations);
                obj.converterControls.fields(units).control.Value = num2str(voltsOrIntensity, '%.4f');
            end

            names = photoreceptors.keys;
            names(strcmp(names, event.fieldName)) = [];
            for i = 1:numel(names)
                n = names{i};
                collectingArea = getCollectingArea(photoreceptors(n).collectingArea, path, orientation);
                isom = common.util.convisom(voltsOrIntensity, units, factor, spectrum, ...
                    photoreceptors(n).spectrum, collectingArea, ndfs, attenuations);
                obj.converterControls.fields(n).control.Value = num2str(isom, '%.0f');
            end
        end

        function onSelectedCopy(obj, ~, event)
            field = obj.converterControls.fields(event.fieldName);
            value = field.control.Value;
            clipboard('copy', value);
        end

        function pack(obj)
            f = obj.figureHandle;
            p = f.Position;
            % Estimate height based on content
            numParamRows = 6;
            paramHeight = 25 + 11 + numParamRows * 23 + (numParamRows - 1) * 7 + 11;

            [tf, ~] = obj.isValid();
            if tf
                v = obj.parametersControls.devicePopupMenu.Value;
                unitsKey = v.device.background.baseUnits;
                if strcmp(unitsKey, 'V')
                    unitsKey = 'volts'; %#ok<NASGU>
                end
                photoreceptors = obj.species.getResource('photoreceptors');
                numConverterRows = 1 + numel(photoreceptors.keys);
            else
                numConverterRows = 1;
            end
            converterHeight = 25 + 11 + numConverterRows * 23 + max(0, (numConverterRows - 1) * 7) + 11;

            totalHeight = paramHeight + converterHeight;
            delta = p(4) - totalHeight;
            f.Position = [p(1) p(2)+delta p(3) totalHeight];
        end

        function onDeviceChangedConfigurationSetting(obj, handle, event)
            v = obj.parametersControls.devicePopupMenu.Value;
            if handle ~= v.device
                return;
            end

            setting = event.data;
            if any(strcmp(setting.name, {'ndfs', 'gain', 'lightPath'}))
                obj.populateNdfs();
                obj.populateGainOrBrightness();
                obj.populateLightPath();
                obj.populateConverterBox();
                obj.pack();
            end
        end

        function onDeviceAddedResource(obj, handle, event)
            v = obj.parametersControls.devicePopupMenu.Value;
            if handle ~= v.device
                return;
            end

            resource = event.data;
            if strcmp(resource.name, 'fluxFactors')
                obj.populateConverterBox();
                obj.pack();
            end
        end

        function onServiceBeganEpochGroup(obj, ~, ~)
            obj.unbindEpochGroup();
            obj.epochGroup = obj.documentationService.getCurrentEpochGroup();
            obj.bindEpochGroup();

            obj.unbindSpecies();
            obj.species = obj.findSpecies();
            obj.bindSpecies();

            obj.unbindPreparation();
            obj.preparation = obj.findPreparation();
            obj.bindPreparation();

            obj.populateSpecies();
            obj.populatePreparation();
            obj.populateConverterBox();

            obj.pack();
        end

        function onServiceEndedEpochGroup(obj, ~, ~)
            obj.unbindEpochGroup();
            obj.epochGroup = obj.documentationService.getCurrentEpochGroup();
            obj.bindEpochGroup();

            obj.unbindSpecies();
            obj.species = obj.findSpecies();
            obj.bindSpecies();

            obj.unbindPreparation();
            obj.preparation = obj.findPreparation();
            obj.bindPreparation();

            obj.populateSpecies();
            obj.populatePreparation();
            obj.populateConverterBox();

            obj.pack();
        end

        function onServiceClosedFile(obj, ~, ~)
            obj.unbindEpochGroup();
            obj.epochGroup = [];

            obj.unbindSpecies();
            obj.species = [];

            obj.unbindPreparation();
            obj.preparation = [];

            obj.populateSpecies();
            obj.populatePreparation();
            obj.populateConverterBox();

            obj.pack();
        end

        function onServiceInitializedRig(obj, ~, ~)
            obj.unbindDevices();
            obj.leds = obj.configurationService.getDevices('LED');
            stages = obj.configurationService.getDevices('Stage');
            if isempty(stages)
                obj.stage = [];
            else
                obj.stage = stages{1};
            end

            obj.populateParametersBox();
            obj.populateConverterBox();

            obj.pack();

            obj.bindDevices();
        end

        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                obj.figureHandle.Position = obj.settings.viewPosition;
            end
        end

        function saveSettings(obj)
            obj.settings.viewPosition = obj.figureHandle.Position;
            obj.settings.save();
        end

    end

    methods (Static, Access = private)

        function s = capitalize(str)
            if isempty(str)
                s = str;
                return;
            end
            s = [upper(str(1)) str(2:end)];
        end

        function s = humanize(str)
            % Convert camelCase to space-separated words
            s = regexprep(str, '([a-z])([A-Z])', '$1 $2');
            s = lower(s);
        end

    end

end
