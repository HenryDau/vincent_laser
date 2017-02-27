function [posout, current_position, maxpower, done] = raster_search(power, pos)
%EncoderScaling = 2 * 3.141 / 1440
start = 0;
increment = 20*pi/180;
final = 40*pi/180;
%motors_to_use = [1 2 4 5];
motors_to_use = [1 2 3 4];   
persistent state
persistent k
persistent start_position;
persistent pattern;
persistent motor_shift;
persistent toppower;
persistent topposition;

done=0;
if (power<-.1) % initalization
    state=0;
    start_position = pos;
    topposition= pos;
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
    if (power>10),
        state=2;
    end;
end;

    

posout=start_position;
if (state==0),
    if (motor_shift>start)
        motor_shift=motor_shift-increment;
        posout(motors_to_use) = posout(motors_to_use) + motor_shift;
    else
        motor_shift=0;
        state=1;
    end;
end;

if (state==1),
    k=k+1;
    if k<=size(pattern,1),
        posout(motors_to_use) = posout(motors_to_use) + pattern(k,:)';
    else
        state=2;
        motor_shift=final;
    end;
end;

if (state==2)
 %   if (motor_shift>0);
 %       motor_shift = motor_shift - increment;
 %       posout(motors_to_use) = posout(motors_to_use) + motor_shift;
 %   else
        motor_shift=0;
        posout=topposition;
        done=1;
 %   end;
end;

state
current_position=posout
maxpower = toppower;