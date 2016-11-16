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
