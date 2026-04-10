classdef FilterWheelControl < symphonyui.ui.Module
    % Controls the NDF filter wheel position.

    properties (Access = private)
        settings
        filterWheel
        ndfDropdown
    end

    methods

        function createUi(obj, figureHandle)
            figureHandle.Name = 'ND Wheel Control';
            figureHandle.Position(3:4) = [200 100]; % Width, Height

            grid = uigridlayout(figureHandle, [1 2]);
            grid.RowHeight = {25};
            grid.ColumnWidth = {80, '1x'};
            grid.Padding = [10 10 10 10];

            uilabel(grid, 'Text', 'NDF value:', 'HorizontalAlignment', 'right');
            obj.ndfDropdown = uidropdown(grid, ...
                'Items', {' '}, ...
                'ValueChangedFcn', @(~,~)obj.onSelectedNdfSetting());
        end

    end

    methods (Access = protected)

        function willGo(obj)
            obj.settings = common.modules.settings.FilterWheelControlSettings();
            devices = obj.configurationService.getDevices('FilterWheel');
            if isempty(devices)
                error('No FilterWheel device found');
            end
            obj.filterWheel = devices{1};
            obj.populateNdfSettingList();

            % Set the NDF to 4.0 on startup (use the numeric value matching ItemsData)
            try
                obj.filterWheel.setNDF(4);
                obj.ndfDropdown.Value = 4;
            catch
                % If 4.0 isn't in the list, select the last (highest) NDF
                if ~isempty(obj.ndfDropdown.ItemsData)
                    lastVal = obj.ndfDropdown.ItemsData(end);
                    obj.filterWheel.setNDF(lastVal);
                    obj.ndfDropdown.Value = lastVal;
                end
            end

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

        function populateNdfSettingList(obj)
            ndfValues = obj.filterWheel.getNdfValues();
            items = cell(1, numel(ndfValues));
            numericData = zeros(1, numel(ndfValues));
            for i = 1:numel(ndfValues)
                items{i} = num2str(ndfValues(i));
                numericData(i) = ndfValues(i);
            end
            obj.ndfDropdown.Items = items;
            obj.ndfDropdown.ItemsData = numericData;
        end

        function onSelectedNdfSetting(obj)
            position = obj.ndfDropdown.Value;
            obj.filterWheel.setNDF(position);
        end

    end

end
