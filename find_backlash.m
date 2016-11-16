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
