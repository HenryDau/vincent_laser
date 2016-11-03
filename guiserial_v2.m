%{
Notes:
TODO: Function that takes power and positions as an input and 
outputs next set the position (CONTROLLER FUNCTION)


TODO: Option to 'fake' power data. Option to read from Ophir or to fake power
data
UPDATE: Done, called spoof_power(), but right now looks at set points. For
real data, change 'Pos1Set' to 'Pos1', etc. for all positions.

%}
function varargout = guiserial_v2(varargin)
% GUISERIAL_V2 MATLAB code for guiserial_v2.fig
%      GUISERIAL_V2, by itself, creates a new GUISERIAL_V2 or raises the existing
%      singleton*.
%
%      H = GUISERIAL_V2 returns the handle to a new GUISERIAL_V2 or the handle to
%      the existing singleton*.
%
%      GUISERIAL_V2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUISERIAL_V2.M with the given input arguments.
%
%      GUISERIAL_V2('Property','Value',...) creates a new GUISERIAL_V2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guiserial_v2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guiserial_v2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiserial_v2

% Last Modified by GUIDE v2.5 01-Nov-2016 11:32:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiserial_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @guiserial_v2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   [] , ...
                   'gui_CloseRequestFcn', @guiserial_v2_ClosingFcn);
               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%% --- Executes just before guiserial_v2 is made visible.
function guiserial_v2_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiserial_v2 (see VARARGIN)

% Choose default command line output for guiserial_v2
handles.output = hObject;
handles.COMS = {'COM6', 'COM7'};
set(handles.Motor1Slider,'SliderStep',[1/1440 10/1440])
set(handles.Motor2Slider,'SliderStep',[1/1440 10/1440])
set(handles.Motor3Slider,'SliderStep',[1/1440 10/1440])
set(handles.Motor1Slider_2,'SliderStep',[1/1440 10/1440])
set(handles.Motor2Slider_2,'SliderStep',[1/1440 10/1440])
set(handles.Motor3Slider_2,'SliderStep',[1/1440 10/1440])

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes guiserial_v2 wait for user response (see UIRESUME)
% uiwait(handles.guiserial_v2);


%% --- Outputs from this function are returned to the command line.
function varargout = guiserial_v2_OutputFcn(~, ~, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%% The function that changes a slider
function change_slider(handles, index, pos, motor)
if exist('handles'),
  if isfield(handles,'objs')
      obj=handles.objs(index);
      if(strcmp(get(obj,'Status'),'open'))    
         fprintf(obj,'%s\n',['P', int2str(motor) ,int2str(pos)])
      end
  end
end

%% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, ~, handles)

if (~isfield(handles, 'read_from_file'))
    handles.read_from_file = true;
end

if (~isfield(handles, 'fake_power'))
    handles.fake_power = false;
end

v=get(hObject,'Value');
switch(v)
% If case(1), all conenctions are closed, so open Arduino COM conncetions
% and OPHIR laser connection
case(1)
        
    
    % Ensure the button states always match
    set(handles.startbutton_no_file, 'Value', 1);
    set(handles.startbutton_fake_power, 'Value', 1);
    
    handles.position_setpoints = [];
    if (handles.read_from_file)
        % Reading from input file
        handles.position_setpoints = load('test_data.txt');
    end
    handles.index = 2;
        
    
    disp('Opening Arduino Connections: Starting timer object')
    % Make sure there is no connection over the USB for all COMS.
    % (This should only execute if there was an error on the previous run)
    for i = 1:length(handles.COMS)
        if (~isempty(instrfind('Port',handles.COMS(i))))
            disp 'Closing irrelavent connections'
            x=instrfind('Port',handles.COMS(i));
            fclose(x);
        end
    end
    
    % Add a COMS object for every COM listed
    for i = 1:length(handles.COMS)
        obj = serial(handles.COMS(i), 'BaudRate', 115200 ,'Timeout',.015);
        obj.terminator = char(10);
        handles.objs(i) = obj;
        fopen(handles.objs(i));
    end
    
    % Make a timer that executes every .5 seconds
    % TODO: tinker with period to stop GUI gettign overwritten by active
    % plotting
    t = timer('ExecutionMode', 'fixedRate', 'Period', .5);
    t.TimerFcn = { @timer_callback, handles.guiserial };
    handles.timer = t;
    
    % Data for each run
    handles.time_stamp = [];
    handles.position_data = [];
    handles.pos_command_with_backlash = [];
    
    %% Make the motos snug against the bolt
    %for i = 1:3
    %    make_snug(i, handles);
    %end
    
    [handles, ok] = open_laser_connections(hObject, handles);
    
    if (~ok)
        return
    end
    
    handles.power_data=[];
    handles.Value = [];
    handles.Timestamp = [];
    
    % Make a new figure for graphing during operation
    figure;
        
    % Start the timer (for some reason guidata must be updated here, 
    % probably because the timer starts before the code updates after the switch statement   
    guidata(hObject,handles);
    start(handles.timer);

% If case(0), then close all existing connections and output the data    
case(0)
    
    % Stop the timer
    stop(handles.timer);
    
    % Ensure the 'Start' button states match
    set(handles.startbutton_no_file, 'Value', 0);
    set(handles.startbutton_fake_power, 'Value', 0);
    
    %% Do all the arduino bookkeeping
    disp('Closing Arduino Connections')
    
    % Close the arduino connection if it is active
    for i = 1:length(handles.objs)
        obj=handles.objs(i);
        if ~isempty(obj),
            if(strcmp(get(obj,'Status'),'open'))
              fclose(obj);
            end
        end
    end
    
    % Outputs the data to a new file of the name 'log_runX.txt' where x
    % makes the file_name unique
    counter = 1;
    while (exist(['log_run', int2str(counter), '.txt']) == 2)
        counter = counter + 1;
    end
    fileID = fopen(['log_run', int2str(counter), '.txt'], 'w');
    [~,nrows] = size(handles.position_data);
    for row = 1:nrows
        if (~isempty(handles.position_data{1,row}))
            fprintf(fileID,'%5.2f\t', handles.time_stamp(1, row));
            fprintf(fileID,'%3.5f\t',handles.power_data(2, row));
            %fprintf(fileID,'%5.5f\t', handles.pos_command_with_backlash(row, :));
            fprintf(fileID,'%s', handles.position_data{1,row});
        end
    end
    fclose(fileID);
    disp(['Output to file: log_run', int2str(counter), '.txt']);
    
    %% Do all the laser bookeeping
    if (~handles.fake_power)
        disp('Closing laser connections');
        ophir_app=handles.ophir_app;
        if ~isempty(ophir_app),
            % Close the laser connections
            ophir_app.StopAllStreams;
            ophir_app.CloseAll;
            ophir_app.delete;
            clear ophir_app
        end
    end
    
    %Plot the laser data (Commented because of active_plotting)
    %data_log = load(['log_run', int2str(counter), '.txt']);
    %if (~isempty(data_log))
    %    figure; plot(data_log(:, 1),data_log(:,2))
    %end
    
    %Delete the timer
    delete(handles.timer);
    clear('handles.timer');
    
    % Ensure this bool is default (for proper operation)
    handles.read_from_file = true;
end

% Save changes made to handles
guidata(hObject,handles);

function [handles, is_ok] = open_laser_connections(hObject, handles)
is_ok = true;

% Open the laser connections first (fail if unable to open)
if (1)%(~handles.fake_power) %TODO: Figure out why this line is slow when faking power data
    %% Start the laser connections and start retrieving data
    try
        disp('Opening laser connections');
        ophirApp = actxserver('OphirLMMeasurement.CoLMMeasurement');
        % Use some of the methods of the object to modify some settings, do some
        % initialisation etc
        % Request the object scans for USB devices:
        SerialNumbers = ophirApp.ScanUSB;
        if(isempty(SerialNumbers))
            disp ('No USB devices seem to be connected. Please check and try again',...
                    'Ophir Measurement COM interface: ScanUSB error')
        end
        % Open the first USB device found:
        h_USB = ophirApp.OpenUSBDevice(SerialNumbers{1});

        % Instruct the sensor to start streaming measurements on the first channel:
        ophirApp.StartStream(h_USB(1),0);
        handles.ophir_app = ophirApp;
        handles.open_USB = h_USB;

    catch COM_error
        %disp(COM_error.message);
        %error('Could not establish a link to OphirLMMeasurement');
        if (~handles.fake_power)
            disp 'No laser connection detected. Please use the Start (fake_power).'
            set(handles.startbutton, 'Value', 0);
            set(handles.startbutton_no_file, 'Value', 0);
            set(handles.startbutton_fake_power, 'Value', 0);

            % Close the arduino connections
            for i = 1:length(handles.objs)
                obj=handles.objs(i);
                if ~isempty(obj),
                    if(strcmp(get(obj,'Status'),'open'))
                      fclose(obj);
                    end
                end
            end

            % Save changes made to handles
            guidata(hObject,handles);
            is_ok = false;
        end
    end
end

% Save changes made to handles
guidata(hObject,handles);


%% --- Executes on button press in startbutton_no_file.
function startbutton_no_file_Callback(hObject, ~, handles)
% Ensure the state of the two start buttons is always the same
v=get(hObject,'Value');
switch(v)
case(1)
    set(handles.startbutton, 'Value', 1);
    set(handles.startbutton_fake_power, 'Value', 1);
    handles.read_from_file = false;
    handles.fake_power = false;
case(0)
    set(handles.startbutton, 'Value', 0);  
    set(handles.startbutton_fake_power, 'Value', 0); 
end


% Update handles structure
guidata(hObject, handles);

%Call the main start button (which won't read from a filenow)
startbutton_Callback(hObject, [], handles);

%% --- Executes on button press in startbutton_fake_power.
function startbutton_fake_power_Callback(hObject, eventdata, handles)
% Ensure the state of the two start buttons is always the same
v=get(hObject,'Value');
switch(v)
case(1)
    set(handles.startbutton, 'Value', 1);
    set(handles.startbutton_no_file, 'Value', 1);
    handles.fake_power = true;
    handles.read_from_file = false;
case(0)
    set(handles.startbutton, 'Value', 0);
    set(handles.startbutton_no_file, 'Value', 0);
end


% Update handles structure
guidata(hObject, handles);

%Call the main start button (which won't read from a filenow)
startbutton_Callback(hObject, [], handles);

%% Executes every period (.5 by default) when either 'Start' button is pressed
function timer_callback(~,~,fighandle)

try
    % Grab the figure handle
    handles=guidata(fighandle);

    % If there are more rows than the current index
    [nrows, ~] = size(handles.position_setpoints);
    if (handles.index < nrows )%&& (get(handles.calc_next_pos,'Value') == 0))
        %This loop makes sure that if, for whatever reason, the current time is
        %greater than the index (which shouldn't happen), then the program will
        %increment the index until it reaches a time greater than the current time
        while (handles.index < nrows && handles.position_setpoints(handles.index, 1) ...
                < (handles.timer.TasksExecuted * handles.timer.AveragePeriod))
            handles.index = handles.index + 1;
        end

        % Look at the position_setpoints to see if motor instructions need to be
        % sent out (if true, then the motor needs to change position)

        % Write new positions to the motors
        % disp(['P1',int2str(handles.position_setpoints(handles.index, 2))]);
        EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians

        %% Position stuff for assembly 1

        % Write to motor 1 assembly 1
        set(handles.screw_pos_1, 'String', handles.position_setpoints(handles.index, 2) * EncoderScaling);    
        if (handles.position_setpoints(handles.index, 2) - handles.position_setpoints(handles.index - 1, 2) >= 0)
            fprintf(handles.objs(1),'%s\n',['P1',int2str(handles.position_setpoints(handles.index, 2))])
        else
            fprintf(handles.objs(1),'%s\n',['P1', ...
                   (int2str((handles.position_setpoints(handles.index, 2)) - eval(get(handles.backlash_1,'String'))))])
        end
        pause(.015);

        % Write to motor 2 assembly 1
        set(handles.screw_pos_2, 'String', handles.position_setpoints(handles.index, 3) * EncoderScaling);
        if (handles.position_setpoints(handles.index, 3) - handles.position_setpoints(handles.index - 1, 3) >= 0)
            % Write motor 2 to the position specified in position setpoints
            % without backlash
            fprintf(handles.objs(1),'%s\n',['P2',int2str(handles.position_setpoints(handles.index, 3))])
        else
            % Write motor 2 to the position specified in position setpoints
            % with backlash
            fprintf(handles.objs(1),'%s\n',['P2', ...
                   (int2str((handles.position_setpoints(handles.index, 3)) - eval(get(handles.backlash_2,'String'))))])
        end
        pause(.015);

        % Write to motor 3 assembly 1
        set(handles.screw_pos_3, 'String', handles.position_setpoints(handles.index, 4) * EncoderScaling);
        if (handles.position_setpoints(handles.index, 4) - handles.position_setpoints(handles.index - 1, 4) >= 0)
            fprintf(handles.objs(1),'%s\n',['P3',int2str(handles.position_setpoints(handles.index, 4))])
        else
            fprintf(handles.objs(1),'%s\n',['P3', ...
                   (int2str((handles.position_setpoints(handles.index, 4)) - eval(get(handles.backlash_3,'String'))))])
        end
        pause(.015);

        %% Position stuff for assembly 2
        % Write to motor 1 assembly 2
        set(handles.screw_pos_1_2, 'String', handles.position_setpoints(handles.index, 5) * EncoderScaling);    
        if (handles.position_setpoints(handles.index, 5) - handles.position_setpoints(handles.index - 1, 5) >= 0)
            fprintf(handles.objs(2),'%s\n',['P1',int2str(handles.position_setpoints(handles.index, 5))])
        else
            fprintf(handles.objs(2),'%s\n',['P1', ...
                   (int2str((handles.position_setpoints(handles.index, 5)) - eval(get(handles.backlash_1_2,'String'))))])
        end
        pause(.015);

        % Write to motor 2 assembly 2
        set(handles.screw_pos_2_2, 'String', handles.position_setpoints(handles.index, 6) * EncoderScaling);
        if (handles.position_setpoints(handles.index, 6) - handles.position_setpoints(handles.index - 1, 6) >= 0)
            % Write motor 2 to the position specified in position setpoints
            % without backlash
            fprintf(handles.objs(2),'%s\n',['P2',int2str(handles.position_setpoints(handles.index, 6))])
        else
            % Write motor 2 to the position specified in position setpoints
            % with backlash
            fprintf(handles.objs(2),'%s\n',['P2', ...
                   (int2str((handles.position_setpoints(handles.index, 6)) - eval(get(handles.backlash_2_2,'String'))))])
        end
        pause(.015);

        % Write to motor 3 assembly 2
        set(handles.screw_pos_3_2, 'String', handles.position_setpoints(handles.index, 7) * EncoderScaling);
        if (handles.position_setpoints(handles.index, 7) - handles.position_setpoints(handles.index - 1, 7) >= 0)
            fprintf(handles.objs(2),'%s\n',['P3',int2str(handles.position_setpoints(handles.index, 7))])
        else
            fprintf(handles.objs(2),'%s\n',['P3', ...
                   (int2str((handles.position_setpoints(handles.index, 7)) - eval(get(handles.backlash_3_2,'String'))))])
        end
        pause(.015);
    end

    if (get(handles.calc_next_pos,'Value') == 1)
        % Comment this try catch if you like, it is copied from writ_next_positions
        try
            pos = get_next_setpoints(handles);
            handles.position_setpoints(end+1, :) = [(handles.timer.TasksExecuted * handles.timer.AveragePeriod), pos];
        catch
            pos = get_next_setpoints(handles);
            handles.position_setpoints(end+1, :) = [0, pos];
        end
        %write_next_positions(fighandle, handles, get_next_setpoints(handles));
    end

    if (~handles.fake_power)
        % Read from the laser
        [handles.Value, handles.Timestamp, ~] = handles.ophir_app.GetData(handles.open_USB(1),0);
    else
        % Don't read from the laser
        handles.Value = spoof_power(handles);
        handles.Timestamp = handles.timer.TasksExecuted * handles.timer.AveragePeriod;
    end
    
    %Check to see if the laser value is valid (Ensure the number of data points
    %is consistent
    if (~isempty(handles.Value))
        pause(.015);

        %Request arduino data
        fprintf(handles.objs(1),'%s\n','D');
        fprintf(handles.objs(2),'%s\n','D');
        pause(.015);

        % Save the gathered data
        if (~isnan(handles.Timestamp(end)))
            handles.time_stamp(1, end+1) = handles.timer.TasksExecuted * handles.timer.AveragePeriod;
            handles.power_data(2,end+1) = handles.Value(end); %Only log the last sample
            handles.power_data(1,end) = handles.Timestamp(end); %Only log the last timestamp
        end

        % Update the GUI laser_power object
        h=findobj(handles.guiserial,'Tag','laser_power');
        set(h,'String',handles.Value(end));

        % Activly plot the power data (comment line to stop active graphing)
        plot(handles.time_stamp(1, :),handles.power_data(2, :));

        % Take into account backlash for these data points
        handles.pos_command_with_backlash(end + 1,1) = eval(get(handles.screw_pos_1, 'String'));
        handles.pos_command_with_backlash(end,2) = eval(get(handles.screw_pos_2, 'String'));
        handles.pos_command_with_backlash(end,3) = eval(get(handles.screw_pos_3, 'String'));
        handles.pos_command_with_backlash(end,4) = eval(get(handles.screw_pos_1_2, 'String'));
        handles.pos_command_with_backlash(end,5) = eval(get(handles.screw_pos_2_2, 'String'));
        handles.pos_command_with_backlash(end,6) = eval(get(handles.screw_pos_3_2, 'String'));

        % Read the desired number of data bytes
        data = fgets(handles.objs(1));
        data_2 = fgets(handles.objs(2));
        values=handles.position_data;
        data_1 = data(1:length(data)-9);
        handles.position_data{length(values)+1}=[data_1, ' ', data_2];

        % Assembly 1
        dataarray = strsplit(data,char(9));
        if length(dataarray)>=14,
            h=findobj(handles.guiserial,'Tag','Pos1Set');
            set(h,'String',dataarray{1});
            h=findobj(handles.guiserial,'Tag','Pos1');
            set(h,'String',dataarray{2});
            h=findobj(handles.guiserial,'Tag','MotorCommand1');
            set(h,'String',dataarray{3});
            h=findobj(handles.guiserial,'Tag','IntErr1');
            set(h,'String',dataarray{4});
            h=findobj(handles.guiserial,'Tag','Pos2Set');
            set(h,'String',dataarray{5});
            h=findobj(handles.guiserial,'Tag','Pos2');
            set(h,'String',dataarray{6});
            h=findobj(handles.guiserial,'Tag','MotorCommand2');
            set(h,'String',dataarray{7});
            h=findobj(handles.guiserial,'Tag','IntErr2');
            set(h,'String',dataarray{8});
            h=findobj(handles.guiserial,'Tag','Pos3Set');
            set(h,'String',dataarray{9});
            h=findobj(handles.guiserial,'Tag','Pos3');
            set(h,'String',dataarray{10});
            h=findobj(handles.guiserial,'Tag','MotorCommand3');
            set(h,'String',dataarray{11});
            h=findobj(handles.guiserial,'Tag','IntErr3');
            set(h,'String',dataarray{12});
            h=findobj(handles.guiserial,'Tag','is_error');
            set(h,'String',dataarray{14});
        end

        % Assembly 2
        dataarray = strsplit(data_2,char(9));
        if length(dataarray)>=14,
            h=findobj(handles.guiserial,'Tag','Pos1Set_2');
            set(h,'String',dataarray{1});
            h=findobj(handles.guiserial,'Tag','Pos1_2');
            set(h,'String',dataarray{2});
            h=findobj(handles.guiserial,'Tag','MotorCommand1_2');
            set(h,'String',dataarray{3});
            h=findobj(handles.guiserial,'Tag','IntErr1_2');
            set(h,'String',dataarray{4});
            h=findobj(handles.guiserial,'Tag','Pos2Set_2');
            set(h,'String',dataarray{5});
            h=findobj(handles.guiserial,'Tag','Pos2_2');
            set(h,'String',dataarray{6});
            h=findobj(handles.guiserial,'Tag','MotorCommand2_2');
            set(h,'String',dataarray{7});
            h=findobj(handles.guiserial,'Tag','IntErr2_2');
            set(h,'String',dataarray{8});
            h=findobj(handles.guiserial,'Tag','Pos3Set_2');
            set(h,'String',dataarray{9});
            h=findobj(handles.guiserial,'Tag','Pos3_2');
            set(h,'String',dataarray{10});
            h=findobj(handles.guiserial,'Tag','MotorCommand3_2');
            set(h,'String',dataarray{11});
            h=findobj(handles.guiserial,'Tag','IntErr3_2');
            set(h,'String',dataarray{12});
        end
    end
    disp('data read')
    guidata(fighandle,handles);
catch
    disp 'If this message shows up once, ignore it.'
end


%% --- Executes on slider movement.
function Motor1Slider_Callback(hObject, ~, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint1,'Value',Pos);
set(handles.PositionSetpoint1,'String',num2str(Pos));
change_slider(handles, 1, Pos, 1)

%% --- Executes during object creation, after setting all properties.
function Motor1Slider_CreateFcn(hObject, ~, ~)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% --- Executes on slider movement.
function Motor2Slider_Callback(hObject, ~, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint2,'Value',Pos);
set(handles.PositionSetpoint2,'String',num2str(Pos));
change_slider(handles, 1, Pos, 2)

%% --- Executes during object creation, after setting all properties.
function Motor2Slider_CreateFcn(hObject, ~, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% Useless but necessary
function PositionSetpoint2_Callback(hObject, eventdata, handles)
%Pos2=get(hObject,'Value');
%set(handles.Motor2Slider,'Value',Pos2);

%% --- Executes during object creation, after setting all properties.
function PositionSetpoint2_CreateFcn(hObject, eventdata, ~)
%%

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% --- Executes during object creation, after setting all properties.
function guiserial_CreateFcn(~, ~, handles)


%% --- Executes on button press in Set2.
function Set2_Callback(hObject, eventdata, handles)
Pos2=eval(get(handles.PositionSetpoint2,'String'));
minset=get(handles.Motor2Slider,'Min');
maxset=get(handles.Motor2Slider,'Max');
set(handles.Motor2Slider,'Value',min(max(Pos2,minset),maxset));
% Hint: get(hObject,'Value') returns toggle state of Set2

% initiate callback of slider
Motor2Slider_Callback(handles.Motor2Slider, eventdata, guidata(hObject)) % run callback


%% --- Executes on mouse press over figure background.
function guiserial_ButtonDownFcn(hObject, eventdata, handles)
%%
% hObject    handle to guiserial_v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Useless but neccessary
function PositionSetpoint1_Callback(hObject, ~, handles)
%%
% hObject    handle to PositionSetpoint1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% --- Executes during object creation, after setting all properties.
function PositionSetpoint1_CreateFcn(hObject, ~, handles)
%%
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes on button press in Set1.
function Set1_Callback(hObject, eventdata, handles)

Pos1=eval(get(handles.PositionSetpoint1,'String'));
minset=get(handles.Motor1Slider,'Min');
maxset=get(handles.Motor1Slider,'Max');
set(handles.Motor1Slider,'Value',min(max(Pos1,minset),maxset));

% initiate callback of slider
Motor1Slider_Callback(handles.Motor1Slider, eventdata, guidata(hObject)) % run callback

%% --- Executes on slider movement.
function Motor3Slider_Callback(hObject, ~, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint3,'Value',Pos);
set(handles.PositionSetpoint3,'String',num2str(Pos));
change_slider(handles, 1, Pos, 3)

%% --- Executes during object creation, after setting all properties.
function Motor3Slider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function PositionSetpoint3_Callback(~, eventdata, handles)

% Hints: get(hObject,'String') returns contents of PositionSetpoint3 as text
%        str2double(get(hObject,'String')) returns contents of PositionSetpoint3 as a double


%% --- Executes during object creation, after setting all properties.
function PositionSetpoint3_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% --- Executes on button press in Set3.
function Set3_Callback(hObject, eventdata, handles)

Pos3=eval(get(handles.PositionSetpoint3,'String'));
minset=get(handles.Motor3Slider,'Min');
maxset=get(handles.Motor3Slider,'Max');
set(handles.Motor3Slider,'Value',min(max(Pos3,minset),maxset));

% initiate callback of slider
Motor3Slider_Callback(handles.Motor3Slider, eventdata, guidata(hObject)) % run callback

%% --- Executes when user attempts to close guiserial.
function guiserial_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to guiserial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Terminate the Arduino connections and Timer object
if exist('handles')
    
  % Terminate the Arduino connections
  if isfield(handles,'objs')
      for i = 1:length(handles.objs)
          obj=handles.objs(i);
          if(strcmp(get(obj,'Status'),'open'))
             fclose(obj);
          end
      end
  end
  
  % Terminate the timer
  if (isfield(handles, 'timer'))
      if (isvalid(handles.timer))
          stop(handles.timer);
          delete(handles.timer);
          clear('handles.timer');
      end
  end
end
delete(hObject);


function backlash_1_Callback(hObject, eventdata, handles)

%% --- Executes during object creation, after setting all properties.
function backlash_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes on button press in backlash_calculate_1.
function backlash_calculate_1_Callback(hObject, eventdata, handles)
disp('Calculating backlash for motor 1...')
EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
difference = find_backlash(1, handles, 1);
set(handles.backlash_1, 'String', difference / EncoderScaling);
difference = find_backlash(1, handles, 2);
set(handles.backlash_1_2, 'String', difference / EncoderScaling);


function backlash_2_Callback(hObject, eventdata, handles)

%% --- Executes during object creation, after setting all properties.
function backlash_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes on button press in backlash_calculate_2.
function backlash_calculate_2_Callback(hObject, eventdata, handles)
disp('Calculating backlash for motor 2...')
EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
difference = find_backlash(2, handles, 1);
set(handles.backlash_2, 'String', difference / EncoderScaling);
difference = find_backlash(2, handles, 2);
set(handles.backlash_2_2, 'String', difference / EncoderScaling);


function backlash_3_Callback(hObject, eventdata, handles)

%% --- Executes during object creation, after setting all properties.
function backlash_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes on button press in backlash_calculate_3.
function backlash_calculate_3_Callback(hObject, eventdata, handles)
% hObject    handle to backlash_calculate_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Calculating backlash for motor 3...')
EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
difference = find_backlash(3, handles, 1);
set(handles.backlash_3, 'String', difference / EncoderScaling);
difference = find_backlash(3, handles, 2);
set(handles.backlash_3_2, 'String', difference / EncoderScaling);


%% --- Executes on button press in backlash_all.
function backlash_all_Callback(hObject, eventdata, handles)
value=eval(get(handles.backlash_1,'String'));
set(handles.backlash_2, 'String', value);
set(handles.backlash_3, 'String', value);
value=eval(get(handles.backlash_1_2,'String'));
set(handles.backlash_2_2, 'String', value);
set(handles.backlash_3_2, 'String', value);

%% Finds the amount of play between the allen key and the bolt.
function [difference] = find_backlash(Motor, handles, index)
obj = [];
if exist('handles'),
    active = false;
    close_handles = false;
    if (isfield(handles,'objs'))
        active = true;
        if(strcmp(get(handles.objs(index),'Status'),'open'))
            obj=handles.objs(index);
        else
            close_handles = true;
            fopen(handles.objs(index));
            obj=handles.objs(index);
        end
    else
        obj = serial(handles.COMS(index), 'BaudRate', 115200);
        fopen(obj);
    end
    pause(1)

    % Define the positions the motors will move to
    Pulselist=1*[-ones(200,1);ones(300,1);-ones(200,1);ones(300,1)];
    position = zeros(1,length(Pulselist));
    Positionindex=[2 6 10];
    
    % Send impulses to the motor to find the backlash
    for k=1:length(Pulselist),
        fprintf(obj,'%s\n',['I',int2str(Motor),int2str(Pulselist(k))]);
        data = fgets(obj);
        dataarray = strsplit(data,char(9));
        if (length(dataarray) >= 12)
            position(k) = eval(dataarray{Positionindex(Motor)});
        end
    end
end
if (~active || close_handles)
    fclose(obj);
end
if (close_handles)
    fclose(handles.objs(index));
end
difference = max(position) - min(position);

%% Make the motos tight aginst the alen bolt
function make_snug(Motor, handles, index)
%
% This code will direct the motor to send a series of very small pulses
% These pulses are strong enough to move the hex tool, but not
% strong enough to move the screw if it is engaged.

disp(['Making motor ', int2str(Motor),' on assembly ', int2str(index), ' snug']);
active = false;
close_handles = false;
if exist('handles'),
    if (isfield(handles,'objs'))
        active = true;
        if(strcmp(get(handles.objs(index),'Status'),'open'))
            obj=handles.objs(index);
        else
            close_handles = true;
            fopen(handles.objs(index));
            obj=handles.objs(index);
        end
    else
        obj = serial(handles.COMS(index), 'BaudRate', 115200);
        fopen(obj);
    end
    pause(1)
    
    % Make some reference points
    Positionindex=[2 6 10];
    position = zeros(1,1000);
    k=1;
    
    % Do this until the motor does not move for 50 pulses, or a max of 1000
    % pulses
    while (k<1000), 
        fprintf(obj,'%s\n',['I',int2str(Motor),'1']);
        
        data = fgets(obj);
        dataarray = strsplit(data,char(9));
        if length(dataarray)>=12,
            position(k) = eval(dataarray{Positionindex(Motor)});
            %disp(position(k)); %Uncomment to see if motors are moving
        end
        if k>100,
            if sum(diff(position(k-50:k)))==0, break; end
        end;
        k=k+1;
    end
end

if (active)
    % Make the setpoint equal to the snug_position
    fprintf(handles.objs(index),'%s\n',['R', int2str(Motor)]);
end

% Take care of bookkeeping (close connections if they weren't previously
% active)
if (~active || close_handles)
    fclose(obj);
end
if (close_handles)
    fclose(handles.obj);
end

%% Function to spoof the Power data for testing purposes
function [power] = spoof_power(handles)

try
    pos1 = eval(get(handles.Pos1Set,'String'));
    pos2 = eval(get(handles.Pos2Set,'String'));
    pos3 = eval(get(handles.Pos3Set,'String'));
catch
    pos1 = 0;
    pos2 = 0;
    pos3 = 0;
end

power = 12 * (mod(pos1, 2) + mod(pos2, 2) + mod(pos3, 2));

%% --- Executes on button press in snug.
function snug_Callback(hObject, eventdata, handles)
% Make the motos snug against the bolt
for i = 1:3
    make_snug(i, handles, 1);
    make_snug(i, handles, 2);
end

disp('Done making motors snug');

% Save the data (probably unneeded)
guidata(hObject,handles);


% --- Executes on slider movement.
function Motor2Slider_2_Callback(hObject, eventdata, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint2_2,'Value',Pos);
set(handles.PositionSetpoint2_2,'String',num2str(Pos));
change_slider(handles, 2, Pos, 2)


% --- Executes during object creation, after setting all properties.
function Motor2Slider_2_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function PositionSetpoint2_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function PositionSetpoint2_2_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Set2_2.
function Set2_2_Callback(hObject, eventdata, handles)
Pos2=eval(get(handles.PositionSetpoint2_2,'String'));
minset=get(handles.Motor2Slider_2,'Min');
maxset=get(handles.Motor2Slider_2,'Max');
set(handles.Motor2Slider_2,'Value',min(max(Pos2,minset),maxset));
% Hint: get(hObject,'Value') returns toggle state of Set2

% initiate callback of slider
Motor2Slider_2_Callback(handles.Motor2Slider_2, eventdata, guidata(hObject)) % run callback


% --- Executes on slider movement.
function Motor1Slider_2_Callback(hObject, eventdata, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint1_2,'Value',Pos);
set(handles.PositionSetpoint1_2,'String',num2str(Pos));
change_slider(handles, 2, Pos, 1)

% --- Executes during object creation, after setting all properties.
function Motor1Slider_2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function PositionSetpoint1_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function PositionSetpoint1_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Set1_2.
function Set1_2_Callback(hObject, eventdata, handles)
Pos2=eval(get(handles.PositionSetpoint1_2,'String'));
minset=get(handles.Motor1Slider_2,'Min');
maxset=get(handles.Motor1Slider_2,'Max');
set(handles.Motor1Slider_2,'Value',min(max(Pos2,minset),maxset));
% Hint: get(hObject,'Value') returns toggle state of Set2

% initiate callback of slider
Motor1Slider_2_Callback(handles.Motor1Slider_2, eventdata, guidata(hObject)) % run callback


% --- Executes on slider movement.
function Motor3Slider_2_Callback(hObject, eventdata, handles)
Pos=get(hObject,'Value');
set(handles.PositionSetpoint3_2,'Value',Pos);
set(handles.PositionSetpoint3_2,'String',num2str(Pos));
change_slider(handles, 2, Pos, 3)


% --- Executes during object creation, after setting all properties.
function Motor3Slider_2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function PositionSetpoint3_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function PositionSetpoint3_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Set3_2.
function Set3_2_Callback(hObject, eventdata, handles)
Pos2=eval(get(handles.PositionSetpoint3_2,'String'));
minset=get(handles.Motor3Slider_2,'Min');
maxset=get(handles.Motor3Slider_2,'Max');
set(handles.Motor3Slider_2,'Value',min(max(Pos2,minset),maxset));
% Hint: get(hObject,'Value') returns toggle state of Set2

% initiate callback of slider
Motor3Slider_2_Callback(handles.Motor3Slider_2, eventdata, guidata(hObject)) % run callback

function backlash_1_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function backlash_1_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function backlash_2_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function backlash_2_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function backlash_3_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function backlash_3_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Function to get the setpoints based on current data
function return_this = get_next_setpoints(handles)

EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians

return_this = get_current_position(handles) / EncoderScaling + 1;

% --- Function to get the current positions
function positions = get_current_position(handles)
try
    current_pos1 = eval(get(handles.Pos1Set,'String')); 
    current_pos2 = eval(get(handles.Pos2Set,'String'));
    current_pos3 = eval(get(handles.Pos3Set,'String'));
    current_pos1_2 = eval(get(handles.Pos1Set_2,'String'));
    current_pos2_2 = eval(get(handles.Pos2Set_2,'String'));
    current_pos3_2 = eval(get(handles.Pos3Set_2,'String'));
catch
    current_pos1 = 0;
    current_pos2 = 0;
    current_pos3 = 0;
    current_pos1_2 = 0;
    current_pos2_2 = 0;
    current_pos3_2 = 0;
end

positions = [current_pos1, current_pos2, current_pos3, ...
    current_pos1_2, current_pos2_2, current_pos3_2];

% --- Executes on button press in calc_next_pos.
function calc_next_pos_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox6

% Writes the current screw position for setting next position
function write_next_positions(fighandle, handles, pos)
try
    handles.position_setpoints(end+1, :) = [(handles.timer.TasksExecuted * handles.timer.AveragePeriod), pos];
catch
    handles.position_setpoints(end+1, :) = [0, pos];
end
guidata(fighandle,handles)
