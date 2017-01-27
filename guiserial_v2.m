function varargout = guiserial_v2(varargin)
% GUISERIAL_V2 MATLAB code for guiserial_v2.fig
%      GUISERIAL_V2, by itself, creates a new GUISERIAL_V2 or raises the existing
%      singleton*.
%
%      H = GUISERIAL_V2 returns the handle to a new GUISERIAL_V2 ort the handle to
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

% Last Modified by GUIDE v2.5 20-Jan-2017 10:08:50

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
handles.COMS = {'COM4', 'COM5'};
%handles.COMS = {'/dev/cu.usbmodem1411', '/dev/cu.usbmodem1421'};
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
         fprintf(obj,'%s\n',['P', int2str(motor) ,int2str(pos)]);
      end
  end
end

%% Executes every period (.5 by default) when either 'Start' button is pressed
function timer_callback(~,~,fighandle)
try
    % Grab the figure handle
    handles=guidata(fighandle);
    
    % Update the position setpoints if needed
    if ((get(handles.calc_next_pos,'Value') == 1 ) && ...
        mod(handles.timer.TasksExecuted, handles.timeout_delay) == 0)
    
        % Update positions because the flag is set
        handles = update_positions(handles);
       
        %handles.position_setpoints
    end

    % If there are more rows than the current index
    [nrows, ~] = size(handles.position_setpoints);
    
    % Get power data
    if (~handles.fake_power)
        % Read from the laser
        [handles.Value, handles.Timestamp, ~] = handles.ophir_app.GetData(handles.open_USB(1),0);
    else
        % Don't read from the laser
        %handles.Value = laser_model(get_current_position(handles));
        handles.Value = laser_model(get_current_screw_positions(handles));
        handles.Timestamp = handles.timer.TasksExecuted * handles.timer.AveragePeriod;
    end
    
    if (handles.index < nrows )%&& (get(handles.calc_next_pos,'Value') == 0))
        
        
        
        %This loop makes sure that if, for whatever reason, the current time is
        %greater than the index (which shouldn't happen), then the program will
        %increment the index until it reaches a time greater than the current time
        while (handles.index < nrows && handles.position_setpoints(handles.index, 1) ...
                < (handles.timer.TasksExecuted * handles.timer.AveragePeriod))
            handles.index = handles.index + 1;
        end
        
        %
        % Write new positions to the motors
        %
        
        %% Position stuff for assembly 1
        % Write to motor 1 assembly 1
        write_to_arduino_with_backlash(handles.screw_pos_1, handles.backlash_1, ...
            handles, 1, 1, 2);

        % Write to motor 2 assembly 1
        write_to_arduino_with_backlash(handles.screw_pos_2, handles.backlash_2, ...
            handles, 1, 2, 3);

        % Write to motor 3 assembly 1
        write_to_arduino_with_backlash(handles.screw_pos_3, handles.backlash_3, ...
            handles, 1, 3, 4);

        %% Position stuff for assembly 2
        % Write to motor 1 assembly 2
        write_to_arduino_with_backlash(handles.screw_pos_1_2, handles.backlash_1_2, ...
            handles, 2, 1, 5);

        % Write to motor 2 assembly 2
        write_to_arduino_with_backlash(handles.screw_pos_2_2, handles.backlash_2_2, ...
            handles, 2, 2, 6);

        % Write to motor 3 assembly 2
        write_to_arduino_with_backlash(handles.screw_pos_3_2, handles.backlash_3_2, ...
            handles, 2, 3, 7);
    end

  
    pause(.01)
    
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
        set(0,'CurrentFigure',handles.PowerFig);
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
            if (dataarray{14}(1) ~= 48)
                disp(['Error in assembly 1 motor: ',dataarray{14}])
            end
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
            if (dataarray{14}(1) ~= 48)
                disp(['Error in assembly 2 motor: ',dataarray{14}])
            end
        end
    end
    disp('data read')
    guidata(fighandle,handles);
catch me
    %me
    disp 'If this message shows up once, ignore it.'
end

%% Function to update positions of the motor based on power changes
function [handles] = update_positions(handles)
try
    disp 'Updating position'
    actual_pos = [eval(get(handles.Pos1Set,'String')); eval(get(handles.Pos2Set,'String'));
                  eval(get(handles.Pos1Set_2,'String')); eval(get(handles.Pos2Set_2,'String'))];
    %[pos, current_setpoint, maxpower] = simultaneous_perturbation_stochastic_approximation(eval(get(handles.laser_power, 'String')), actual_pos);

    % TODO: Add a done indicator to the function output
    % Execute the desired function
    if (handles.functions_initialized(handles.function_index) == 0)
        disp('first call')
        eval(['[pos, current_setpoint, maxpower, done] = ',handles.functions_array{handles.function_index},'(-1,', mat2str(actual_pos),');'])
        handles.functions_initialized(handles.function_index) = 1;
    else
        eval(['[pos, current_setpoint, maxpower, done] = ',handles.functions_array{handles.function_index},'(',get(handles.laser_power, 'String'),', ', mat2str(actual_pos),');'])
        if (done)
            % Update the function index
            handles.function_index = mod(handles.function_index, length(handles.functions_array)) + 1;
        end
    end

    % Print the current function index
    handles.function_index

    % TODO: Add done functionality
    %if (done)
    %   do new stuff 
    %end
    
    % Active plotting
    set(0,'CurrentFigure',handles.AuxFig);
    a=get(gca,'children');
    delete(a);
    text(.5,.5,mat2str(current_setpoint ));
    text(.5,.25,num2str(maxpower));
    
    % Save the new positions
    formatter = [pos(1), pos(2), 0, pos(3) , pos(4) ,0];
    EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
    handles.position_setpoints(end+1, :) = [(handles.timer.TasksExecuted * handles.timer.AveragePeriod), formatter / EncoderScaling];
catch me
    me
    disp 'Error in stochastic function'
end

%% Function to get the setpoints based on current data
function return_this = get_next_setpoints(handles)

EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
return_this = get_current_position(handles) / EncoderScaling + 1;

%% --- Function to get the current positions
function positions = get_current_position(handles)
try
    %current_pos1 = eval(get(handles.Pos1Set,'String')); 
    %current_pos2 = eval(get(handles.Pos2Set,'String'));
    %current_pos3 = eval(get(handles.Pos3Set,'String'));
    %current_pos1_2 = eval(get(handles.Pos1Set_2,'String'));
    %current_pos2_2 = eval(get(handles.Pos2Set_2,'String'));
    %current_pos3_2 = eval(get(handles.Pos3Set_2,'String'));
    
    %current_pos1 = eval(get(handles.Pos1,'String')); 
    %current_pos2 = eval(get(handles.Pos2,'String'));
    %current_pos3 = eval(get(handles.Pos3,'String'));
    %current_pos1_2 = eval(get(handles.Pos1_2,'String'));
    %current_pos2_2 = eval(get(handles.Pos2_2,'String'));
    %current_pos3_2 = eval(get(handles.Pos3_2,'String'));
    
    current_pos1 = eval(get(handles.screw_pos_1,'String')); 
    current_pos2 = eval(get(handles.screw_pos_2,'String'));
    current_pos3 = eval(get(handles.screw_pos_3,'String'));
    current_pos1_2 = eval(get(handles.screw_pos_1_2,'String'));
    current_pos2_2 = eval(get(handles.screw_pos_2_2,'String'));
    current_pos3_2 = eval(get(handles.screw_pos_3_2,'String'));
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

%% --- Function to get the current screw positions
function positions = get_current_screw_positions(handles)
try
    current_pos1 = eval(get(handles.screw_pos_1,'String')); 
    current_pos2 = eval(get(handles.screw_pos_2,'String'));
    current_pos3 = eval(get(handles.screw_pos_3,'String'));
    current_pos1_2 = eval(get(handles.screw_pos_1_2,'String'));
    current_pos2_2 = eval(get(handles.screw_pos_2_2,'String'));
    current_pos3_2 = eval(get(handles.screw_pos_3_2,'String'));
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


%% --- Executes on button press in calc_next_pos.
function calc_next_pos_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox6

if (get(hObject,'Value') == 1)
    try
        actual_pos = [eval(get(handles.Pos1Set,'String')); eval(get(handles.Pos2Set,'String'));
                  eval(get(handles.Pos1Set_2,'String')); eval(get(handles.Pos2Set_2,'String'))];
              
        [pos] = simultaneous_perturbation_stochastic_approximation(-1, actual_pos);
        filler = [pos(1), pos(2), 0, 0,0,0];
        EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
        
        handles.position_setpoints = [0,0,0,0,0,0,0];
        handles.position_setpoints(end+1, :) = [0,0,0,0,0,0,0];
        handles.position_setpoints(end+1, :) = [0,0,0,0,0,0,0];
        
        % Save the new positions
        handles.position_setpoints(end+1, :) = [(handles.timer.TasksExecuted * handles.timer.AveragePeriod), filler / EncoderScaling];
    
    catch me
        me
        %disp 'Check this box after the program starts running'
        set(handles.calc_next_pos, 'Value', 0);
    end
    
    guidata(hObject,handles);
end


%% Write to an arduino using backlash data
function write_to_arduino_with_backlash(object, object2, handles, port, motor, value_index)
EncoderScaling = 2 * 3.141 / 1440; % Encoder counts to radians
set(object, 'String', handles.position_setpoints(handles.index, value_index) * EncoderScaling);    
if (handles.position_setpoints(handles.index, value_index) - handles.position_setpoints(handles.index - 1, value_index) >= 0)
    write_to_arduino(handles, port, motor, handles.position_setpoints(handles.index, value_index));
else
    write_to_arduino(handles, port, motor, ...
        handles.position_setpoints(handles.index, value_index) - eval(get(object2,'String')));
end

%% Writes a value to an arduino
function write_to_arduino(handles, port, motor, value)

fprintf(handles.objs(port),'%s\n',['P', int2str(motor), int2str(value)]);
pause(.015);
%%

%%%
%%% Bookeeping functions
%%%

%% Writes the run data to a file
function write_to_file(handles)
% Outputs the data to a new file of the name 'log_runX.txt' where x
% makes the file_name unique
counter = 1;
while (exist(['log_run', int2str(counter), '.txt']) == 2)
    counter = counter + 1;
end
fileID = fopen(['log_run', int2str(counter), '.txt'], 'w');
[~,nrows] = size(handles.position_data);
handles.power_data(:,end+1) = -1;
for row = 1:nrows
    if (~isempty(handles.position_data{1,row}))
        fprintf(fileID,'%5.2f\t', handles.time_stamp(1, row));
        fprintf(fileID,'%3.5f\t',handles.power_data(2, row+1));
        fprintf(fileID,'%5.5f\t', handles.pos_command_with_backlash(row, :));
        fprintf(fileID,'%s', handles.position_data{1,row});
    end
end
fclose(fileID);
disp(['Output to file: log_run', int2str(counter), '.txt']);

%% Open arduino connections
function [handles] = open_arduino_connections(handles)

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

%% Start the laser connections and start retrieving data
function [handles, is_ok] = open_laser_connections(hObject, handles)
is_ok = true;

% Open the laser connections first (fail if unable to open)
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
        handles = close_arduino_connections(handles);

        % Save changes made to handles
        guidata(hObject,handles);
        is_ok = false;
    end
end

% Save changes made to handles
guidata(hObject,handles);

%% Close all arduino connections
function [handles] = close_arduino_connections(handles)
disp('Closing Arduino Connections')
    
% Close the arduino connection if it is active
for i = 1:length(handles.objs)
    obj=handles.objs(i);
    if ~isempty(obj)
        if(strcmp(get(obj,'Status'),'open'))
          fclose(obj);
        end
    end
end

%% Close all existing laser connections
function [handles] = close_laser_connections(handles)
disp('Closing laser connections');
try
    ophir_app=handles.ophir_app;
    if ~isempty(ophir_app),
        % Close the laser connections
        ophir_app.StopAllStreams;
        ophir_app.CloseAll;
        ophir_app.delete;
        clear ophir_app
    end
catch COM_error
    
end

%% Delete the timer
function [handles] = delete_timer(handles)
delete(handles.timer);
clear('handles.timer');
%%

%%% ------------------------------------------------------------------- %%%
%%% GUI functions. Most of these are empty
%%% Think very carefully if you need to go past this point
%%% Half a joke, only reason to come down here is to change a callback.
%%% ------------------------------------------------------------------- %%%

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

%%%
%%% Starter functions
%%%

%% --- Executes on button press in startbutton - main start button
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
        handles.position_setpoints = load('test_data_14.txt');
    else
        pause(1)
    end
    handles.index = 2;
    
    % Open the arduino connections
    handles = open_arduino_connections(handles);
    
    % Open the laser connections
    pause (1)
    [handles, ok] = open_laser_connections(hObject, handles);
    pause (1)
    if (~ok)
        return
    end
    
    % Make a timer that executes every .5 seconds
    t = timer('ExecutionMode', 'fixedRate', 'Period', .5);
    t.TimerFcn = { @timer_callback, handles.guiserial };
    handles.timer = t;
    
    % Reset the calc_next_position checkbox
    set(handles.calc_next_pos, 'Value', 0);
    
    % Data for each run
    handles.time_stamp = [];
    handles.position_data = [];
    handles.pos_command_with_backlash = [];
    handles.power_data=[];
    handles.Value = [];
    handles.Timestamp = [];
    handles.timeout_delay = 5;
    handles.function_index = 1;
    handles.functions_array = {'simultaneous_perturbation_stochastic_approximation', 'test_function'};
    handles.functions_initialized = zeros(1, length(handles.functions_array));
    
    
    % Make the motos snug against the bolt
    %for i = 1:3
    %    make_snug(i, handles);
    %end
    
    % Make a new figure for graphing during operation
    figure(1);
    clf
    handles.PowerFig=gcf;
    figure(2)
    clf
    axis([0 1 0 1])
    handles.AuxFig=gcf;
        
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
    handles = close_arduino_connections(handles);
    
    %% Save the data
    write_to_file(handles)
    
    %% Do all the laser bookeeping
    handles = close_laser_connections(handles);
    
    %Delete the timer
    handles = delete_timer(handles);
    
    % Ensure this bool is default (for proper operation)
    handles.read_from_file = true;
    handles.fake_power = false;
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

%%%
%%% Backlash functions
%%%
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
disp('Done with Backlash for motor 1')


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
disp('Done with Backlash for motor 2')


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
disp('Done with Backlash for motor 3')

%% --- Executes on button press in backlash_all.
function backlash_all_Callback(hObject, eventdata, handles)
value=eval(get(handles.backlash_1,'String'));
set(handles.backlash_2, 'String', value);
set(handles.backlash_3, 'String', value);
value=eval(get(handles.backlash_1_2,'String'));
set(handles.backlash_2_2, 'String', value);
set(handles.backlash_3_2, 'String', value);

%%%
%%% Slider Callbacks
%%%

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

%%%
%%% Create and delete functions
%%%

%% --- Executes during object creation, after setting all properties.
function guiserial_CreateFcn(~, ~, handles)


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


% --- Executes on button press in set_defaults.
function set_defaults_Callback(hObject, eventdata, handles)
% hObject    handle to set_defaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.backlash_1, 'String', 6);
set(handles.backlash_2, 'String', 52);
set(handles.backlash_1_2, 'String', 46);
set(handles.backlash_2_2, 'String', 32);
