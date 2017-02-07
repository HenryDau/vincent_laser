function [posout, current_position, maxpower, done] = raster_search(power, pos)
start = -200;
increment = 100;
final = 200;
interval_up = 2;
time_stamp = 2;
%motors_to_use = [1 2 4 5];
motors_to_use = [1 2];   
persistent state
persistent k
persistent start_position;
persistent pattern;
persistent motor_shift;
persistent toppower;
persistent topposition;

done=0;
if (power<0) % initalization
    state=0;
    start_position = pos;
    k=0;
    toppower=0;
    pattern=[];
    motors=0;
    for i=1:length(motors_to_use),
       pattern=expand((start:increment:final)',pattern);
    end;
    motor_shift=0;
end;

if (power>toppower);
    toppower=power;
    topposition=pos;
end;

if (state==0),
    if (motor_shift>start)
        motor_shift=motor_shift-increment;
        posout=start_position;
        posout(motors_to_use) = posout(motors_to_use) + motor_shift;
    else
        motor_shift=0
        state=1
    end;
end;

if (state==1),
    k=k+1;
    if k<=size(pattern,1),
        posout=start_position;
        posout(motors_to_use) = posout(motors_to_use) + pattern(k,:);
    else
        state=2;
        motor_shift=final;
    end;
end;

if (state==2)
    if (motor_shift>0);
        motor_shift = motor_shift - increment;
        posout=start_position;
        posout(motors_to_use) = posout(motors_to_use) + motor_shift;
    else
        motor_shift=0;
        posout=topposition;
        done=1;
    end;
end;

current_position=posout;
maxpower = toppower;