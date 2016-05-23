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

% Last Modified by GUIDE v2.5 18-May-2016 11:41:19

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


% --- Executes just before guiserial_v2 is made visible.
function guiserial_v2_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiserial_v2 (see VARARGIN)

% Choose default command line output for guiserial_v2
handles.output = hObject;
%handles.obj = [];
set(handles.Motor1Slider,'SliderStep',[1/1440 10/1440])
set(handles.Motor2Slider,'SliderStep',[1/1440 10/1440])
set(handles.Motor3Slider,'SliderStep',[1/1440 10/1440])

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes guiserial_v2 wait for user response (see UIRESUME)
% uiwait(handles.guiserial_v2);


% --- Outputs from this function are returned to the command line.
function varargout = guiserial_v2_OutputFcn(~, ~, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function Motor2Slider_Callback(hObject, ~, handles)

Pos2=get(hObject,'Value');
Time2=eval(get(handles.RampTime2,'String'));
set(handles.PositionSetpoint2,'Value',Pos2);
set(handles.PositionSetpoint2,'String',num2str(Pos2));
%doRamp = get(handles.rampcheckbox2,'Value');
if exist('handles'),
  if isfield(handles,'obj')
   obj=handles.obj;
   if(strcmp(get(obj,'Status'),'open'))
       if 1,      
          fprintf(obj,'%s\n',['P2',int2str(Pos2)])
       else
          fprintf(obj,'%s\n',['R2',int2str(Pos2),'T',num2str(Time2)])
       end;
   end;
  end;
end;

% --- Executes during object creation, after setting all properties.
function Motor2Slider_CreateFcn(hObject, ~, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function Motor1Slider_Callback(hObject, ~, handles)

Pos1=get(hObject,'Value');
Time1=eval(get(handles.RampTime1,'String'));
set(handles.PositionSetpoint1,'Value',Pos1);
set(handles.PositionSetpoint1,'String',num2str(Pos1));
%doRamp = get(handles.rampcheckbox1,'Value');
if exist('handles'),
  if isfield(handles,'obj')
   obj=handles.obj;
   if(strcmp(get(obj,'Status'),'open'))
       if 1,      
          fprintf(obj,'%s\n',['P1',int2str(Pos1)])
       else
          fprintf(obj,'%s\n',['R1',int2str(Pos1),'T',num2str(Time1)])
       end;
   end;
  end;
end;

% --- Executes during object creation, after setting all properties.
function Motor1Slider_CreateFcn(hObject, ~, ~)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, ~, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of startbutton
v=get(hObject,'Value');
switch(v)
case(1)
    % Reading from 'instr.txt'
    handles.position_setpoints = load('instr.txt');
    handles.index = 1;
    disp('Opening Arduino Connections: Starting timer object')
    %obj = serial('/dev/cu.usbmodem1451');
    %set(obj,'BaudRate',115200)
    obj = serial('COM6', 'BaudRate', 115200);
    %obj.BytesAvailableFcn = {@timer_callback,handles.guiserial};
    %obj.BytesAvailableFcnMode = 'terminator';
    t = timer('ExecutionMode', 'fixedRate', 'Period', .5);
    t.TimerFcn = { @timer_callback, handles.guiserial };
    handles.timer = t;
    obj.terminator = char(10);
    handles.obj = obj;
    handles.position_data =[];
    handles.time_stamp = [];
    if(strcmp(get(obj,'status'),'closed')),
      fopen(obj);
    end;
    
    %%Start the laser connections and start retrieving data
    try
        disp('Opening laser connections');
        ophirApp = actxserver('OphirLMMeasurement.CoLMMeasurement');
    catch COM_error
        disp(COM_error.message);
        error('Could not establist a link to OphirLMMeasurement');
    end

    % Use some of the methods of the object to modify some settings, do some
    % initialisation etc
    % Request the object scans for USB devices:
    SerialNumbers = ophirApp.ScanUSB;
    if(isempty(SerialNumbers))
        warndlg('No USB devices seem to be connected. Please check and try again',...
                'Ophir Measurement COM interface: ScanUSB error')
    end

    % Open the first USB device found:
    h_USB = ophirApp.OpenUSBDevice(SerialNumbers{1});

    % Instruct the sensor to start streaming measurements on the first channel:
    ophirApp.StartStream(h_USB(1),0);
    handles.ophir_app = ophirApp;
    handles.open_USB = h_USB;
    handles.power_data=[];
        
    % Start the timer (for some reason guidata must be updated here, 
    % probably because the timer starts before the code updates after the switch statement   
    guidata(hObject,handles);
    start(handles.timer);
case(0)
    %%Do all the arduino bookkeeping
    disp('Closing Arduino Connections')
    % Stop the timer
    stop(handles.timer);
    
    obj=handles.obj;
    if ~isempty(obj),
     if(strcmp(get(obj,'Status'),'open'))
       fclose(obj);
     end;
    end;
    
    % Outputs the arduino (motor) data to a file
    fileID = fopen('log.txt', 'w');
    [~,nrows] = size(handles.position_data);
    for row = 1:nrows
        fprintf(fileID,'%5.2f\t', handles.time_stamp(1, row));
        fprintf(fileID,'%3.5f\t',handles.power_data(2, row));
        fprintf(fileID,'%s', handles.position_data{1,row});
    end
    fclose(fileID);
    disp('Output to file: log.txt');
    
    %% Do all the laser bookeeping
    disp('Closing laser connections');
    ophir_app=handles.ophir_app;
    if ~isempty(ophir_app),
        % Close the laser connections
        ophir_app.StopAllStreams;
        ophir_app.CloseAll;
        ophir_app.delete;
        clear ophir_app
    end;
    data_log = load('log.txt');
    figure; plot(data_log(:, 1),data_log(:,2))

    %Delete the timer
    delete(handles.timer);
    clear('handles.timer');
end;
guidata(hObject,handles);

function timer_callback(obj,~,fighandle)
handles=guidata(fighandle);

[nrows, ~] = size(handles.position_setpoints);
if (handles.index < nrows)
    %This loop makes sure that if, for whatever reason, the current time is
    %greater than the index (which shouldn't happen), then the program will
    %increment the index until it reaches a time greater than the current time
    while (handles.index < nrows && handles.position_setpoints(handles.index, 1) < (handles.timer.TasksExecuted * handles.timer.AveragePeriod))
        handles.index = handles.index + 1;
    end

    % Look at the position_setpoints to see if motor instructions need to be
    % sent out (if true, then the motor needs to change position)
    if (handles.position_setpoints(handles.index, 1) == handles.timer.TasksExecuted * handles.timer.AveragePeriod)
        % Write new positions to the motors TODO: make sure motors are being
        % written to correctly
        %disp(['P1',int2str(handles.position_setpoints(handles.index, 2))]);
        fprintf(handles.obj,'%s\n',['P1',int2str(handles.position_setpoints(handles.index, 2))])
        pause(.015);
        fprintf(handles.obj,'%s\n',['P2',int2str(handles.position_setpoints(handles.index, 3))])
        pause(.015);
        fprintf(handles.obj,'%s\n',['P3',int2str(handles.position_setpoints(handles.index, 4))])
        pause(.015);
    end
end

% Read from the laser
[Value, Timestamp, ~]= handles.ophir_app.GetData(handles.open_USB(1),0);

%Check to see if the laser is read
if (~isempty(Value))
    
    %Request arduino data
    fprintf(handles.obj,'%s\n','R');

    handles.time_stamp(1, end+1) = handles.timer.TasksExecuted * handles.timer.AveragePeriod;
    handles.power_data(2,end+1) = Value(end); %Only log the last sample
    handles.power_data(1,end) = Timestamp(end); %Only log the last timestamp
    h=findobj(handles.guiserial,'Tag','laser_power');
    set(h,'String',Value(end));


    % Read the desired number of data bytes
    data = fgets(handles.obj);
    values=handles.position_data;
    handles.position_data{length(values)+1}=data;

    dataarray = strsplit(data,char(9));
    if length(dataarray)>=12,
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
    end
end
disp('data read')
guidata(fighandle,handles);

function PositionSetpoint2_Callback(hObject, eventdata, handles)
%Pos2=get(hObject,'Value');
%set(handles.Motor2Slider,'Value',Pos2);

% --- Executes during object creation, after setting all properties.
function PositionSetpoint2_CreateFcn(hObject, eventdata, ~)
%%

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Motor2Ramp.
function Motor2Ramp_Callback(hObject, eventdata, ~)


function RampTime2_Callback(hObject, eventdata, handles)
%%
% Hints: get(hObject,'String') returns contents of RampTime2 as text
%        str2double(get(hObject,'String')) returns contents of RampTime2 as a double


% --- Executes during object creation, after setting all properties.
function RampTime2_CreateFcn(hObject, eventdata, handles)
%%

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function guiserial_CreateFcn(~, ~, handles)
% hObject    handle to guiserial_v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in Set2.
function Set2_Callback(hObject, eventdata, handles)
%%

Pos2=eval(get(handles.PositionSetpoint2,'String'));
minset=get(handles.Motor2Slider,'Min');
maxset=get(handles.Motor2Slider,'Max');
set(handles.Motor2Slider,'Value',min(max(Pos2,minset),maxset));
% Hint: get(hObject,'Value') returns toggle state of Set2

% initiate callback of slider
Motor2Slider_Callback(handles.Motor2Slider, eventdata, guidata(hObject)) % run callback


% --- Executes on mouse press over figure background.
function guiserial_ButtonDownFcn(hObject, eventdata, handles)
%%
% hObject    handle to guiserial_v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function slider6_Callback(hObject, eventdata, handles)
% hObject    handle to Motor1Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider6_CreateFcn(hObject, eventdata, ~)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function PositionSetpoint1_Callback(hObject, ~, handles)
%%
% hObject    handle to PositionSetpoint1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function PositionSetpoint1_CreateFcn(hObject, ~, handles)
%%
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Motor1Ramp.
function Motor1Ramp_Callback(hObject, ~, handles)

% Hint: get(hObject,'Value') returns toggle state of Motor1Ramp



function RampTime1_Callback(hObject, eventdata, handles)

% Hints: get(hObject,'String') returns contents of RampTime1 as text
%        str2double(get(hObject,'String')) returns contents of RampTime1 as a double


% --- Executes during object creation, after setting all properties.
function RampTime1_CreateFcn(hObject, eventdata, ~)
%%
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Set1.
function Set1_Callback(hObject, eventdata, handles)

Pos1=eval(get(handles.PositionSetpoint1,'String'));
minset=get(handles.Motor1Slider,'Min');
maxset=get(handles.Motor1Slider,'Max');
set(handles.Motor1Slider,'Value',min(max(Pos1,minset),maxset));

% initiate callback of slider
Motor1Slider_Callback(handles.Motor1Slider, eventdata, guidata(hObject)) % run callback

% --- Executes on slider movement.
function Motor3Slider_Callback(hObject, ~, handles)

Pos3=get(hObject,'Value');
Time3=eval(get(handles.RampTime3,'String'));
set(handles.PositionSetpoint3,'Value',Pos3);
set(handles.PositionSetpoint3,'String',num2str(Pos3));
%doRamp = get(handles.rampcheckbox1,'Value');
if exist('handles'),
  if isfield(handles,'obj')
   obj=handles.obj;
   if(strcmp(get(obj,'Status'),'open'))
       if 1,      
          fprintf(obj,'%s\n',['P3',int2str(Pos3)])
       else
          fprintf(obj,'%s\n',['R3',int2str(Pos3),'T',num2str(Time3)])
       end;
   end;
  end;
end;


% --- Executes during object creation, after setting all properties.
function Motor3Slider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function PositionSetpoint3_Callback(~, eventdata, handles)

% Hints: get(hObject,'String') returns contents of PositionSetpoint3 as text
%        str2double(get(hObject,'String')) returns contents of PositionSetpoint3 as a double


% --- Executes during object creation, after setting all properties.
function PositionSetpoint3_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Motor3Ramp.
function Motor3Ramp_Callback(~, eventdata, ~)
% hObject    handle to Motor3Ramp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Motor3Ramp



function RampTime3_Callback(hObject, ~, handles)
% hObject    handle to RampTime3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RampTime3 as text
%        str2double(get(hObject,'String')) returns contents of RampTime3 as a double


% --- Executes during object creation, after setting all properties.
function RampTime3_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Set3.
function Set3_Callback(hObject, eventdata, handles)

Pos3=eval(get(handles.PositionSetpoint3,'String'));
minset=get(handles.Motor3Slider,'Min');
maxset=get(handles.Motor3Slider,'Max');
set(handles.Motor3Slider,'Value',min(max(Pos3,minset),maxset));

% initiate callback of slider
Motor3Slider_Callback(handles.Motor3Slider, eventdata, guidata(hObject)) % run callback

% --- Executes when user attempts to close guiserial.
function guiserial_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to guiserial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Terminate the Arduino connection
if exist('handles'),
  if isfield(handles,'obj')
   obj=handles.obj;
   if(strcmp(get(obj,'Status'),'open'))
      fclose(obj);
   end
  end
  if (isfield(handles, 'timer'))
      if (isvalid(handles.timer))
          stop(handles.timer);
          delete(handles.timer);
          clear('handles.timer');
      end
  end
end


delete(hObject);
