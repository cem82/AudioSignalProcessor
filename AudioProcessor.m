classdef TermProject2 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        LeftPanel            matlab.ui.container.Panel
        DeleteButton         matlab.ui.control.StateButton
        soundList            matlab.ui.control.ListBox
        RecordedSoundsLabel  matlab.ui.control.Label
        Image                matlab.ui.control.Image
        btnRecord            matlab.ui.control.Button
        CenterPanel          matlab.ui.container.Panel
        knobAmp              matlab.ui.control.Knob
        AmplitudeKnobLabel   matlab.ui.control.Label
        knobSpeed            matlab.ui.control.Knob
        SpeedKnobLabel       matlab.ui.control.Label
        Lamp                 matlab.ui.control.Lamp
        editBox              matlab.ui.control.EditField
        StatusLabel          matlab.ui.control.Label
        swReverse            matlab.ui.control.ToggleSwitch
        ReverseSwitchLabel   matlab.ui.control.Label
        axGraph              matlab.ui.control.UIAxes
        RightPanel           matlab.ui.container.Panel
        downloadButton       matlab.ui.control.Button
        pauseResumeButton    matlab.ui.control.Button
        btnStopPlay          matlab.ui.control.Button
        btnPlay              matlab.ui.control.Button
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end

    
    properties (Access = private)
        audioInput % The variable that holds the audio
        sampleRate = 44100 % This is the number of Samples that are taken from the audio to create a digital signal

        playerObj % This is the audio that's going to play with all the changes
        recObj % This is the sound that is recorded
        
        % Empty lists to store sounds and their names
        RecordedSounds = {}
        SoundNames = string.empty
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: btnRecord
        function btnRecordButtonPushed(app, event)
            if ~isempty(app.recObj) && isrecording(app.recObj)
                % First, this if statement checks the conditions for
                % whether "recObj" is empty and than it checks if it's
                % recording or not because if it's not recording in the
                % first place, "recObj" is a double therefore we cannot use
                % "isrecording()" function with it. 

                %The reason it checks if it's recording or not is that this
                %single button works for both starting and stopping the
                %recording process
                
                %It stops recording
                stop(app.recObj);
                
                % It gets the data from the sound and creates a graph
                % according to it.
                app.audioInput = getaudiodata(app.recObj);
                plot(app.axGraph, app.audioInput);


                % Changes for user feedback
                app.editBox.Value = "Recording Stopped";
                app.btnRecord.Text = "Record";
                app.Lamp.Color = 'green';   

               
                app.audioInput = getaudiodata(app.recObj);
                
                % Adding the new sound to the list, getting its name by
                % adding one to the end of the list which creates something
                % like Recording + 1 (+1) 
                newName = "Recording " + string(numel(app.SoundNames) + 1);
                app.SoundNames(end+1) = newName;
                app.RecordedSounds{end+1} = app.audioInput;
                
                % Updating the listBox
                app.soundList.Items = app.SoundNames;
                app.soundList.Value = newName; 
                return
            else 
                %Changes for user feedback
                app.editBox.Value = "Recording...";
                app.Lamp.Color = 'red';
                app.btnRecord.Text = "Stop Recording";
                drawnow
                
                % It starts recording
                app.recObj = audiorecorder(app.sampleRate, 16, 1);
                record(app.recObj);
            end
        end

        % Button pushed function: btnPlay
        function btnPlayButtonPushed(app, event)

            % Checks if there is a sound or not
            if isempty(app.audioInput)
                app.editBox.Value = "Please Record a Sound.";
                return
            end
            
            
            audioPlay = app.audioInput;
            
            % It changes the values of the sound before playing it
            % depending on user input
            if app.swReverse.Value == "On"
                audioPlay = flipud(audioPlay);
            end
        
            audioPlay = app.knobAmp.Value .* audioPlay;
            newSampleRate = app.sampleRate * app.knobSpeed.Value;
        
            app.playerObj = audioplayer(audioPlay, newSampleRate);
            play(app.playerObj);
        
            app.editBox.Value = "Playing...";
        end

        % Button pushed function: btnStopPlay
        function btnStopPlayButtonPushed(app, event)
            if isempty(app.playerObj)
                return
            end
        
            stop(app.playerObj);
        
            app.editBox.Value = "Playback Stopped";

            % There is a stop playing button only because there is also a
            % resume/pause button for the sound.
         
        end

        % Button pushed function: pauseResumeButton
        function pauseResumeButtonPushed(app, event)
            if isempty(app.playerObj)
                return
            end
        
            if isplaying(app.playerObj)
                pause(app.playerObj);
                app.pauseResumeButton.Text = "▶";
                app.editBox.Value = "Paused";
            else
                resume(app.playerObj);
                app.pauseResumeButton.Text = "||"; 
                app.editBox.Value = "Playing";
            end
        end

        % Button pushed function: downloadButton
        function downloadButtonPushed(app, event)
            if isempty(app.audioInput)
                app.editBox.Value = "Please Record a Sound";
                return
            end

            audioToSave = app.audioInput;
            
            % Since it's going to download the altered sound, it changes
            % the values for the variable "audioToSave"
            if app.swReverse.Value == "On"
                audioToSave = flipud(audioToSave);           
            end

            audioToSave = app.knobAmp.Value .* audioToSave;
            newSampleRate = app.sampleRate * app.knobSpeed.Value;


            % uipufile() function opens the windows to save the audio
            [file, path] = uiputfile('Recording.wav', 'Save Audio As');
            % If there is no file or a path, saving process gets cancelled
            if isequal(file,0) || isequal(path,0)
                app.editBox.Value = "Save cancelled";
                return
            end
            % fullfile() makes the name of the .wav file come after the
            % path
            fullFileName = fullfile(path, file);
            %audiowrite creates the file itself, it rounds the sample rate
            %because wav files require integers
            audiowrite(fullFileName, audioToSave, round(newSampleRate));
            % Feedback
            app.editBox.Value = "Audio saved!";

        end

        % Value changed function: soundList
        function soundListValueChanged(app, event)
            

            selectedName = app.soundList.Value;
            % Finding the order of the sound that is chosen 
                idx = find(app.SoundNames == selectedName);
                
                if ~isempty(idx)
                    app.audioInput = app.RecordedSounds{idx};
                    plot(app.axGraph, app.audioInput);
                end
        end

        % Value changed function: DeleteButton
        function DeleteButtonValueChanged(app, event)
        % Getting the chosen sound
            selectedName = app.soundList.Value;
            
            % If list is empty, return
            if isempty(selectedName) || isempty(app.SoundNames)
                app.editBox.Value = "There is no sound to delete.";
                return;
            end
            
            % Finding the index of the chosen sound
            idx = find(app.SoundNames == selectedName);
            
            % Removing the sound from arrays
            app.SoundNames(idx) = [];    
            app.RecordedSounds(idx) = [];     
            
            % Updating ListBox
            app.soundList.Items = app.SoundNames;
            
            % Unless the list is empty, return to the one that is at the
            % end of the list
            if ~isempty(app.SoundNames)
                app.soundList.Value = app.SoundNames(end);
                app.audioInput = app.RecordedSounds{end};
                plot(app.axGraph, app.audioInput);
            else
                app.soundList.Value = {};
                app.audioInput = [];
                cla(app.axGraph);
            end
            
            app.editBox.Value = "Sound has been removed";
                    
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {480, 480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x', 215};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 860 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x', 215};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.BorderColor = [0.149 0.149 0.149];
            app.LeftPanel.HighlightColor = [0.149 0.149 0.149];
            app.LeftPanel.BackgroundColor = [0.149 0.149 0.149];
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create btnRecord
            app.btnRecord = uibutton(app.LeftPanel, 'push');
            app.btnRecord.ButtonPushedFcn = createCallbackFcn(app, @btnRecordButtonPushed, true);
            app.btnRecord.BackgroundColor = [0.149 0.149 0.149];
            app.btnRecord.FontSize = 24;
            app.btnRecord.FontAngle = 'italic';
            app.btnRecord.FontColor = [1 1 1];
            app.btnRecord.Position = [11 212 189 58];
            app.btnRecord.Text = 'Record';

            % Create Image
            app.Image = uiimage(app.LeftPanel);
            app.Image.Position = [56 64 100 100];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'SoundLogoPng.png');

            % Create RecordedSoundsLabel
            app.RecordedSoundsLabel = uilabel(app.LeftPanel);
            app.RecordedSoundsLabel.HorizontalAlignment = 'right';
            app.RecordedSoundsLabel.FontColor = [1 1 1];
            app.RecordedSoundsLabel.Position = [11 370 62 50];
            app.RecordedSoundsLabel.Text = 'History';

            % Create soundList
            app.soundList = uilistbox(app.LeftPanel);
            app.soundList.Items = {};
            app.soundList.ValueChangedFcn = createCallbackFcn(app, @soundListValueChanged, true);
            app.soundList.FontColor = [1 1 1];
            app.soundList.BackgroundColor = [0.149 0.149 0.149];
            app.soundList.Position = [88 348 100 74];
            app.soundList.Value = {};

            % Create DeleteButton
            app.DeleteButton = uibutton(app.LeftPanel, 'state');
            app.DeleteButton.ValueChangedFcn = createCallbackFcn(app, @DeleteButtonValueChanged, true);
            app.DeleteButton.Text = 'Delete';
            app.DeleteButton.BackgroundColor = [0.149 0.149 0.149];
            app.DeleteButton.FontColor = [1 1 1];
            app.DeleteButton.Position = [88 319 100 22];

            % Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.BackgroundColor = [0.149 0.149 0.149];
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create axGraph
            app.axGraph = uiaxes(app.CenterPanel);
            title(app.axGraph, 'Sound Signal')
            xlabel(app.axGraph, 'X')
            ylabel(app.axGraph, 'Y')
            zlabel(app.axGraph, 'Z')
            app.axGraph.XColor = [1 1 1];
            app.axGraph.YColor = [1 1 1];
            app.axGraph.ZColor = [1 1 1];
            app.axGraph.Color = [0.149 0.149 0.149];
            app.axGraph.GridColor = [1 1 1];
            app.axGraph.MinorGridColor = [1 1 1];
            app.axGraph.Box = 'on';
            app.axGraph.Position = [6 166 413 241];

            % Create ReverseSwitchLabel
            app.ReverseSwitchLabel = uilabel(app.CenterPanel);
            app.ReverseSwitchLabel.HorizontalAlignment = 'center';
            app.ReverseSwitchLabel.FontSize = 14;
            app.ReverseSwitchLabel.FontColor = [1 1 1];
            app.ReverseSwitchLabel.Position = [197 8 57 22];
            app.ReverseSwitchLabel.Text = 'Reverse';

            % Create swReverse
            app.swReverse = uiswitch(app.CenterPanel, 'toggle');
            app.swReverse.FontSize = 14;
            app.swReverse.FontColor = [1 1 1];
            app.swReverse.Position = [215 66 20 45];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.CenterPanel);
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.FontColor = [1 1 1];
            app.StatusLabel.Position = [95 421 42 22];
            app.StatusLabel.Text = 'Status:';

            % Create editBox
            app.editBox = uieditfield(app.CenterPanel, 'text');
            app.editBox.FontName = 'Century Gothic';
            app.editBox.FontColor = [1 1 1];
            app.editBox.BackgroundColor = [0.149 0.149 0.149];
            app.editBox.Position = [152 421 177 22];
            app.editBox.Value = 'Ready';

            % Create Lamp
            app.Lamp = uilamp(app.CenterPanel);
            app.Lamp.Position = [336 423 20 20];

            % Create SpeedKnobLabel
            app.SpeedKnobLabel = uilabel(app.CenterPanel);
            app.SpeedKnobLabel.HorizontalAlignment = 'center';
            app.SpeedKnobLabel.FontSize = 14;
            app.SpeedKnobLabel.FontColor = [1 1 1];
            app.SpeedKnobLabel.Position = [73 8 45 22];
            app.SpeedKnobLabel.Text = 'Speed';

            % Create knobSpeed
            app.knobSpeed = uiknob(app.CenterPanel, 'continuous');
            app.knobSpeed.Limits = [0.5 2];
            app.knobSpeed.MajorTicks = [0 1 2 3 4 5];
            app.knobSpeed.FontSize = 14;
            app.knobSpeed.FontColor = [1 1 1];
            app.knobSpeed.Position = [65 58 60 60];
            app.knobSpeed.Value = 1;

            % Create AmplitudeKnobLabel
            app.AmplitudeKnobLabel = uilabel(app.CenterPanel);
            app.AmplitudeKnobLabel.HorizontalAlignment = 'center';
            app.AmplitudeKnobLabel.FontSize = 14;
            app.AmplitudeKnobLabel.FontColor = [1 1 1];
            app.AmplitudeKnobLabel.Position = [314 8 67 22];
            app.AmplitudeKnobLabel.Text = 'Amplitude';

            % Create knobAmp
            app.knobAmp = uiknob(app.CenterPanel, 'continuous');
            app.knobAmp.Limits = [0 5];
            app.knobAmp.MajorTicks = [0 1 2 3 4 5];
            app.knobAmp.FontSize = 14;
            app.knobAmp.FontColor = [1 1 1];
            app.knobAmp.Position = [315 64 60 60];
            app.knobAmp.Value = 1;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.BorderColor = [0.149 0.149 0.149];
            app.RightPanel.HighlightColor = [0.149 0.149 0.149];
            app.RightPanel.BackgroundColor = [0.149 0.149 0.149];
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create btnPlay
            app.btnPlay = uibutton(app.RightPanel, 'push');
            app.btnPlay.ButtonPushedFcn = createCallbackFcn(app, @btnPlayButtonPushed, true);
            app.btnPlay.BackgroundColor = [0.149 0.149 0.149];
            app.btnPlay.FontSize = 24;
            app.btnPlay.FontAngle = 'italic';
            app.btnPlay.FontColor = [1 1 1];
            app.btnPlay.Position = [13 385 189 58];
            app.btnPlay.Text = 'Play';

            % Create btnStopPlay
            app.btnStopPlay = uibutton(app.RightPanel, 'push');
            app.btnStopPlay.ButtonPushedFcn = createCallbackFcn(app, @btnStopPlayButtonPushed, true);
            app.btnStopPlay.BackgroundColor = [0.149 0.149 0.149];
            app.btnStopPlay.FontSize = 24;
            app.btnStopPlay.FontAngle = 'italic';
            app.btnStopPlay.FontColor = [1 1 1];
            app.btnStopPlay.Position = [13 38 189 58];
            app.btnStopPlay.Text = 'Stop Playing';

            % Create pauseResumeButton
            app.pauseResumeButton = uibutton(app.RightPanel, 'push');
            app.pauseResumeButton.ButtonPushedFcn = createCallbackFcn(app, @pauseResumeButtonPushed, true);
            app.pauseResumeButton.BackgroundColor = [0.149 0.149 0.149];
            app.pauseResumeButton.FontSize = 24;
            app.pauseResumeButton.FontColor = [1 1 1];
            app.pauseResumeButton.Position = [23 219 56 51];
            app.pauseResumeButton.Text = '▶';

            % Create downloadButton
            app.downloadButton = uibutton(app.RightPanel, 'push');
            app.downloadButton.ButtonPushedFcn = createCallbackFcn(app, @downloadButtonPushed, true);
            app.downloadButton.BackgroundColor = [0.149 0.149 0.149];
            app.downloadButton.FontSize = 36;
            app.downloadButton.FontColor = [1 1 1];
            app.downloadButton.Position = [144 216 58 54];
            app.downloadButton.Text = '⬇';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TermProject2

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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