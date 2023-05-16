classdef main < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        LoadButton                matlab.ui.control.Button
        HistoryTextArea           matlab.ui.control.TextArea
        PlotgeneratorPanel        matlab.ui.container.Panel
        SkyplotButton             matlab.ui.control.Button
        ElevationplotButton       matlab.ui.control.Button
        ConstellationTree         matlab.ui.container.CheckBoxTree
        ConstellationNode         matlab.ui.container.TreeNode
        ConfgurationPanel         matlab.ui.container.Panel
        ReceiverpositionLLHPanel  matlab.ui.container.Panel
        HeightEditField           matlab.ui.control.NumericEditField
        HeightEditFieldLabel      matlab.ui.control.Label
        LongitudeEditField        matlab.ui.control.NumericEditField
        LongitudeEditFieldLabel   matlab.ui.control.Label
        LatitudeEditField         matlab.ui.control.NumericEditField
        LatitudeEditFieldLabel    matlab.ui.control.Label
        TimeUTCPanel              matlab.ui.container.Panel
        TimewindowDropDown        matlab.ui.control.DropDown
        TimewindowDropDownLabel   matlab.ui.control.Label
        MinuteSpinner             matlab.ui.control.Spinner
        MinuteSpinnerLabel        matlab.ui.control.Label
        HourSpinner               matlab.ui.control.Spinner
        HourSpinnerLabel          matlab.ui.control.Label
        DaySpinner                matlab.ui.control.Spinner
        DaySpinnerLabel           matlab.ui.control.Label
        MonthSpinner              matlab.ui.control.Spinner
        MonthSpinnerLabel         matlab.ui.control.Label
        YearSpinner               matlab.ui.control.Spinner
        YearSpinnerLabel          matlab.ui.control.Label
        ConstellationButtonGroup  matlab.ui.container.ButtonGroup
        GLONASSButton             matlab.ui.control.RadioButton
        BEIDOUButton              matlab.ui.control.RadioButton
        GALILEOButton             matlab.ui.control.RadioButton
        GPSButton                 matlab.ui.control.RadioButton
    end

    
    methods (Access = private)
        
        function updateCommandWindow(app,newString)
            oldString = app.HistoryTextArea.Value; % The string as it is now.
            app.HistoryTextArea.Value = [{newString};oldString];
        end
        
        function updateConstellationTree(app, satellitesNames,losTable)
            global losTable
            clearConstellationTree(app);
            
            % update node name
            app.ConstellationNode.Text = app.ConstellationButtonGroup.SelectedObject.Text;
            app.ConstellationTree.CheckedNodes = [];
            
            % list all satellites
            for i = 1:length(satellitesNames)
                if sum(losTable(:,i)) % if this satellite is visible...
                    % add it to the tree list
                    newNode      = uitreenode(app.ConstellationNode);
                    newNode.Text = satellitesNames(i);
                end
            end
        end
        
        function clearConstellationTree(app)
            nNodes = length(app.ConstellationNode.Children);
            if nNodes
                for i = 1:nNodes
                    app.ConstellationNode.Children(1).delete();
                end
            end
        end
        
        % output: -1 if no satellite checked, list of string otherwise
        function checkedSatellites = checkCheckedSatellites(app)
            nodes = app.ConstellationTree.CheckedNodes;
            
            if ~isempty(nodes)
                checkedSatellites = strings(length(nodes),1);
                for i = 1:length(nodes)
                    checkedSatellites(i) = nodes(i).Text;
                end
            else
                checkedSatellites = -1;
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            warning('off');
            addpath('orbit_files');
            addpath('src');
            addpath(['src' filesep 'lib' filesep 'coordinates']);
            addpath(['src' filesep 'lib' filesep 'web']);
            addpath(['src' filesep 'lib' filesep 'geometry']);
            addpath(['src' filesep 'sgp4']);
            
            % preset UTC to now
            [currentYear, currentMonth, currentDay, currentHour, currentMinute, ~] = datevec(datetime('now','TimeZone','UTC'));
            
            app.YearSpinner.Value   = currentYear;
            app.MonthSpinner.Value  = currentMonth;
            app.DaySpinner.Value    = currentDay;
            app.HourSpinner.Value   = currentHour;
            app.MinuteSpinner.Value = currentMinute;
            
        end

        % Value changed function: MonthSpinner
        function MonthSpinnerValueChanged(app, event)
            newMonthValue = app.MonthSpinner.Value;
            yearValue = app.YearSpinner.Value;
            
            switch newMonthValue
                case 2 % february
                    if ( (mod(yearValue,4)==0 & mod(yearValue,100)>0) | mod(yearValue,400)==0 )
                        app.DaySpinner.Limits = [1 29];
                    else
                        app.DaySpinner.Limits = [1 28];
                    end
                case {4, 6, 9, 11} % april, june, september, november 
                    app.DaySpinner.Limits = [1 30];
                otherwise % january, march, may, july, august, october, december
                    app.DaySpinner.Limits = [1 31];
            end
        end

        % Value changed function: YearSpinner
        function YearSpinnerValueChanged(app, event)
            newYearValue = app.YearSpinner.Value;
            
            if app.MonthSpinner.Value == 2
                if ( (mod(newYearValue,4)==0 & mod(newYearValue,100)>0) | mod(newYearValue,400)==0 )
                    app.DaySpinner.Limits = [1 29];
                else
                    app.DaySpinner.Limits = [1 28];
                end
            end
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            global elaz losTable satellitesNames startTime timeSince
            nSatellitesMax = 36;
            
            updateCommandWindow(app,'loading satellites...');
            
            % 1- load configuration parameters
            
            % time
            year    = app.YearSpinner.Value;  
            month   = app.MonthSpinner.Value; 
            day     = app.DaySpinner.Value;   
            hour    = app.HourSpinner.Value;  
            minute  = app.MinuteSpinner.Value;
            
            startTime = Mjday(year, month, day, hour, minute, 0);
            
            % time window
            timeWindowValue = app.TimewindowDropDown.Value;
            
            switch timeWindowValue
                case 'now!'
                    timeSince = 0;
                case '1h'
                    timeSince = 0:15:1*60;
                case '3h'
                    timeSince = 0:15:3*60;
                case '6h'
                    timeSince = 0:15:6*60;
                case '12h'
                    timeSince = 0:15:12*60;
            end
            
            % receiver position
            latitudeRx = app.LatitudeEditField.Value;
            longitudeRx = app.LongitudeEditField.Value;
            heightRx = app.HeightEditField.Value;
            
            positionRx = convert_llh2ecef([latitudeRx;longitudeRx;heightRx], 'deg')/1000; % [km]
            
            % constellation
            constellation = lower(app.ConstellationButtonGroup.SelectedObject.Text);
            
            updateCommandWindow(app,['TLE loaded for ' constellation ' constellation']);
            
            updateCommandWindow(app,'computing satellite positions...');
            tic

            losTable = zeros(length(timeSince),nSatellitesMax);
            elaz = nan(length(timeSince),nSatellitesMax,2);
            
            for i = 1:length(timeSince)
                % a - get all the satellites positions
                [satellitesPositions, satellitesNames, retval] = get_sat_positions(constellation, startTime, timeSince(i));
                if (~retval)
                    
                    for j=1:length(satellitesPositions(1,:))
                        % b - for each satellite, is it visible?
                        losTable(i,j) = isLOS(satellitesPositions(:,j), positionRx);
                        if losTable(i,j)
                            [el,az] = computeAzimuthElevation(positionRx*1000,satellitesPositions(:,j)*1000);
                            elaz(i,j,1) = el*180/pi; %[°]
                            elaz(i,j,2) = mod(az*180/pi, 360); %[°] 
                        end
                    end
                end
            end
            
            t=toc;
            updateCommandWindow(app,['satellite positions computed (' num2str(t) 's).']);
            
            
            updateConstellationTree(app, satellitesNames);
            
            
        end

        % Button pushed function: SkyplotButton
        function SkyplotButtonPushed(app, event)
            global satellitesNames elaz losTable timeSince startTime
            cmap = colormap('lines');
            checkedSatellites = checkCheckedSatellites(app);

            if ((isnumeric(checkedSatellites(1))) && (checkedSatellites(1) == -1) )
                % no satellite checked, nothing to plot.
                updateCommandWindow(app,'no satellite checked, nothing to plot.');
            else
                polarplot(0,90,'HandleVisibility','off');
                pax = gca;
                pax.ThetaDir            = 'clockwise';
                pax.ThetaZeroLocation   = 'top';
                pax.ThetaTickLabels     = {'N' ,'30' ,'60' ,'E' ,'120' ,'150' ,'S' ,'210' ,'240' ,'W' ,'300' ,'330'};
                pax.RMinorGrid          = 'on';
                pax.RGrid               = 'on';
                pax.RDir                = 'reverse';
                pax.RLim                = [0 90];
                hold on;
                
                indexSatellites = [];
                indexColor = 1;
                
                for i = 1:length(satellitesNames)
                    if sum(strcmp(satellitesNames(i),checkedSatellites))
                        % 1- plot sky trajectory
                        polarplot(elaz(:,i,2)*pi/180,elaz(:,i,1),'LineWidth',2, 'Color', cmap(indexColor,:));
                        
                        % 2- mark start and end time
                        idx = find(losTable(:,i)==1);
                        prev_idx = 0;
                        visible = 0;
                        for j = 1:length(idx)
                            if ( (idx(j) == (prev_idx+1)) && (visible == 0)) 
                                % start of visibility: print time
                                visible = 1;
                                polarplot(elaz(idx(j),i,2)*pi/180, elaz(idx(j),i,1), 'Color', cmap(indexColor,:), 'Marker', '^', 'MarkerSize', 10, 'LineWidth',2, 'HandleVisibility','off');
                                text(elaz(idx(j),i,2)*pi/180 + 0.1, elaz(idx(j),i,1), string(duration(seconds(timeSince(idx(j))*60 + mod(startTime,1)*24*60*60),'Format','hh:mm')),'color','k','FontWeight','bold','FontSize',12);
                            elseif ((idx(j) ~= (prev_idx+1)) && (visible == 1))
                                % end of visibility: print time
                                visible = 0;
                                polarplot(elaz(idx(j-1),i,2)*pi/180, elaz(idx(j-1),i,1), 'Color', cmap(indexColor,:), 'Marker', 'o', 'MarkerSize', 10, 'LineWidth', 2, 'HandleVisibility','off');
                                text(elaz(idx(j-1),i,2)*pi/180 + 0.1, elaz(idx(j-1),i,1), string(duration(seconds(timeSince(idx(j-1))*60 + mod(startTime,1)*24*60*60),'Format','hh:mm')),'color','k','FontWeight','bold','FontSize',12);
                            elseif (idx(j) == idx(end))
                                polarplot(elaz(idx(j),i,2)*pi/180, elaz(idx(j),i,1), 'Color', cmap(indexColor,:), 'Marker', 'o', 'MarkerSize', 10, 'LineWidth', 2, 'HandleVisibility','off');
                                text(elaz(idx(j),i,2)*pi/180 + 0.1, elaz(idx(j),i,1), string(duration(seconds(timeSince(idx(j))*60 + mod(startTime,1)*24*60*60),'Format','hh:mm')),'color','k','FontWeight','bold','FontSize',12);
                            end
                            prev_idx = idx(j);
                        end
                        indexSatellites = [indexSatellites, i];
                        indexColor = indexColor + 1;
                    end
                end
                legend(satellitesNames(indexSatellites));
                hold off
            end
        end

        % Button pushed function: ElevationplotButton
        function ElevationplotButtonPushed(app, event)
            global satellitesNames startTime timeSince elaz
            
            checkedSatellites = checkCheckedSatellites(app);

            if ((isnumeric(checkedSatellites(1))) && (checkedSatellites(1) == -1) )
                % no satellite checked, nothing to plot.
                updateCommandWindow(app,'no satellite checked, nothing to plot.');
            else
                indexSatellites = [];
                figure; hold on;
                for i=1:length(satellitesNames)
                    if sum(strcmp(satellitesNames(i),checkedSatellites))
                        plot(seconds(timeSince*60 + mod(startTime,1)*24*60*60),elaz(:,i,1),'DurationTickFormat','hh:mm','LineWidth', 2);
                        indexSatellites = [indexSatellites, i];
                    end
                end
                legend(satellitesNames(indexSatellites));
                grid on
                hold off
                xlabel('UTC Time of the day [hh:mm]', 'FontSize', 12);
                ylabel('Satellites elevation [°]', 'FontSize', 12);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 550 574];
            app.UIFigure.Name = 'GNSS Satellite Predictor';

            % Create ConfgurationPanel
            app.ConfgurationPanel = uipanel(app.UIFigure);
            app.ConfgurationPanel.Title = 'Confguration';
            app.ConfgurationPanel.Position = [23 268 510 287];

            % Create ConstellationButtonGroup
            app.ConstellationButtonGroup = uibuttongroup(app.ConfgurationPanel);
            app.ConstellationButtonGroup.Title = 'Constellation';
            app.ConstellationButtonGroup.Position = [260 18 235 86];

            % Create GPSButton
            app.GPSButton = uiradiobutton(app.ConstellationButtonGroup);
            app.GPSButton.Text = 'GPS';
            app.GPSButton.Position = [27 38 58 22];
            app.GPSButton.Value = true;

            % Create GALILEOButton
            app.GALILEOButton = uiradiobutton(app.ConstellationButtonGroup);
            app.GALILEOButton.Text = 'GALILEO';
            app.GALILEOButton.Position = [27 7 73 22];

            % Create BEIDOUButton
            app.BEIDOUButton = uiradiobutton(app.ConstellationButtonGroup);
            app.BEIDOUButton.Text = 'BEIDOU';
            app.BEIDOUButton.Position = [121 38 68 22];

            % Create GLONASSButton
            app.GLONASSButton = uiradiobutton(app.ConstellationButtonGroup);
            app.GLONASSButton.Text = 'GLONASS';
            app.GLONASSButton.Position = [121 7 80 22];

            % Create TimeUTCPanel
            app.TimeUTCPanel = uipanel(app.ConfgurationPanel);
            app.TimeUTCPanel.Title = 'Time (UTC)';
            app.TimeUTCPanel.Position = [13 18 235 238];

            % Create YearSpinnerLabel
            app.YearSpinnerLabel = uilabel(app.TimeUTCPanel);
            app.YearSpinnerLabel.HorizontalAlignment = 'right';
            app.YearSpinnerLabel.Position = [58 179 30 22];
            app.YearSpinnerLabel.Text = 'Year';

            % Create YearSpinner
            app.YearSpinner = uispinner(app.TimeUTCPanel);
            app.YearSpinner.Limits = [1970 2100];
            app.YearSpinner.ValueChangedFcn = createCallbackFcn(app, @YearSpinnerValueChanged, true);
            app.YearSpinner.Position = [103 179 100 22];
            app.YearSpinner.Value = 2023;

            % Create MonthSpinnerLabel
            app.MonthSpinnerLabel = uilabel(app.TimeUTCPanel);
            app.MonthSpinnerLabel.HorizontalAlignment = 'right';
            app.MonthSpinnerLabel.Position = [49 147 39 22];
            app.MonthSpinnerLabel.Text = 'Month';

            % Create MonthSpinner
            app.MonthSpinner = uispinner(app.TimeUTCPanel);
            app.MonthSpinner.Limits = [1 12];
            app.MonthSpinner.ValueChangedFcn = createCallbackFcn(app, @MonthSpinnerValueChanged, true);
            app.MonthSpinner.Position = [103 147 100 22];
            app.MonthSpinner.Value = 1;

            % Create DaySpinnerLabel
            app.DaySpinnerLabel = uilabel(app.TimeUTCPanel);
            app.DaySpinnerLabel.HorizontalAlignment = 'right';
            app.DaySpinnerLabel.Position = [61 116 27 22];
            app.DaySpinnerLabel.Text = 'Day';

            % Create DaySpinner
            app.DaySpinner = uispinner(app.TimeUTCPanel);
            app.DaySpinner.Limits = [1 31];
            app.DaySpinner.Position = [103 116 100 22];
            app.DaySpinner.Value = 1;

            % Create HourSpinnerLabel
            app.HourSpinnerLabel = uilabel(app.TimeUTCPanel);
            app.HourSpinnerLabel.HorizontalAlignment = 'right';
            app.HourSpinnerLabel.Position = [56 85 32 22];
            app.HourSpinnerLabel.Text = 'Hour';

            % Create HourSpinner
            app.HourSpinner = uispinner(app.TimeUTCPanel);
            app.HourSpinner.Limits = [0 23];
            app.HourSpinner.Position = [103 85 100 22];

            % Create MinuteSpinnerLabel
            app.MinuteSpinnerLabel = uilabel(app.TimeUTCPanel);
            app.MinuteSpinnerLabel.HorizontalAlignment = 'right';
            app.MinuteSpinnerLabel.Position = [46 54 42 22];
            app.MinuteSpinnerLabel.Text = 'Minute';

            % Create MinuteSpinner
            app.MinuteSpinner = uispinner(app.TimeUTCPanel);
            app.MinuteSpinner.Limits = [0 59];
            app.MinuteSpinner.Position = [103 54 100 22];

            % Create TimewindowDropDownLabel
            app.TimewindowDropDownLabel = uilabel(app.TimeUTCPanel);
            app.TimewindowDropDownLabel.HorizontalAlignment = 'right';
            app.TimewindowDropDownLabel.Position = [14 12 75 22];
            app.TimewindowDropDownLabel.Text = 'Time window';

            % Create TimewindowDropDown
            app.TimewindowDropDown = uidropdown(app.TimeUTCPanel);
            app.TimewindowDropDown.Items = {'now!', '1h', '3h', '6h', '12h'};
            app.TimewindowDropDown.Position = [104 12 100 22];
            app.TimewindowDropDown.Value = 'now!';

            % Create ReceiverpositionLLHPanel
            app.ReceiverpositionLLHPanel = uipanel(app.ConfgurationPanel);
            app.ReceiverpositionLLHPanel.Title = 'Receiver position (LLH)';
            app.ReceiverpositionLLHPanel.Position = [260 115 235 141];

            % Create LatitudeEditFieldLabel
            app.LatitudeEditFieldLabel = uilabel(app.ReceiverpositionLLHPanel);
            app.LatitudeEditFieldLabel.HorizontalAlignment = 'right';
            app.LatitudeEditFieldLabel.Position = [39 82 48 22];
            app.LatitudeEditFieldLabel.Text = 'Latitude';

            % Create LatitudeEditField
            app.LatitudeEditField = uieditfield(app.ReceiverpositionLLHPanel, 'numeric');
            app.LatitudeEditField.Limits = [-90 90];
            app.LatitudeEditField.Position = [102 82 100 22];
            app.LatitudeEditField.Value = 43.08;

            % Create LongitudeEditFieldLabel
            app.LongitudeEditFieldLabel = uilabel(app.ReceiverpositionLLHPanel);
            app.LongitudeEditFieldLabel.HorizontalAlignment = 'right';
            app.LongitudeEditFieldLabel.Position = [29 50 58 22];
            app.LongitudeEditFieldLabel.Text = 'Longitude';

            % Create LongitudeEditField
            app.LongitudeEditField = uieditfield(app.ReceiverpositionLLHPanel, 'numeric');
            app.LongitudeEditField.Limits = [-180 180];
            app.LongitudeEditField.Position = [102 50 100 22];
            app.LongitudeEditField.Value = 3.05;

            % Create HeightEditFieldLabel
            app.HeightEditFieldLabel = uilabel(app.ReceiverpositionLLHPanel);
            app.HeightEditFieldLabel.HorizontalAlignment = 'right';
            app.HeightEditFieldLabel.Position = [47 18 40 22];
            app.HeightEditFieldLabel.Text = 'Height';

            % Create HeightEditField
            app.HeightEditField = uieditfield(app.ReceiverpositionLLHPanel, 'numeric');
            app.HeightEditField.Position = [102 18 100 22];
            app.HeightEditField.Value = 25;

            % Create PlotgeneratorPanel
            app.PlotgeneratorPanel = uipanel(app.UIFigure);
            app.PlotgeneratorPanel.Title = 'Plot generator';
            app.PlotgeneratorPanel.Position = [23 18 510 135];

            % Create ConstellationTree
            app.ConstellationTree = uitree(app.PlotgeneratorPanel, 'checkbox');
            app.ConstellationTree.Position = [15 14 345 87];

            % Create ConstellationNode
            app.ConstellationNode = uitreenode(app.ConstellationTree);
            app.ConstellationNode.Text = 'Constellation';

            % Create ElevationplotButton
            app.ElevationplotButton = uibutton(app.PlotgeneratorPanel, 'push');
            app.ElevationplotButton.ButtonPushedFcn = createCallbackFcn(app, @ElevationplotButtonPushed, true);
            app.ElevationplotButton.Position = [385 27 100 22];
            app.ElevationplotButton.Text = 'Elevation plot';

            % Create SkyplotButton
            app.SkyplotButton = uibutton(app.PlotgeneratorPanel, 'push');
            app.SkyplotButton.ButtonPushedFcn = createCallbackFcn(app, @SkyplotButtonPushed, true);
            app.SkyplotButton.Position = [384 60 100 22];
            app.SkyplotButton.Text = 'Skyplot';

            % Create HistoryTextArea
            app.HistoryTextArea = uitextarea(app.UIFigure);
            app.HistoryTextArea.Position = [37 166 349 85];
            app.HistoryTextArea.Value = {'Welcome to the GNSS Sat Predictor!'};

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [407 197 100 22];
            app.LoadButton.Text = 'Load';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end