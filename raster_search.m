function [posout, current_position, maxpower, done] = raster_search(power, pos)
%EncoderScaling = 2 * 3.141 / 1440
start = -1*pi/180;
increment = 1*pi/180;
max_increment = 1*pi/180;
final = 1*pi/180;
motors_to_use = [1 2];   
STOP_ON_POWER=0;
GO_TO_MAX=1;
%start = 0;
%increment = 20*pi/180;
%final = 40*pi/180;
%motors_to_use = [1 2 3 4];   
persistent state
persistent k
persistent start_position;
persistent stop_position;
persistent pattern;
persistent motor_shift;
persistent toppower;
persistent topposition;
persistent final_increment;

done=0;
if (power<-.1) % initalization
    state=0;
    start_position = pos;
    topposition= pos;
    k=1;
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
    if (power>10 & STOP_ON_POWER),
        state=2;
    end;
end;

    

posout=start_position;
if (state==0),
    if (motor_shift<1)
        motor_shift=motor_shift+1/ceil(abs(start/max_increment));
        posout(motors_to_use) = posout(motors_to_use) + motor_shift*pattern(k,:)';
    else
        state=1;
        motor_shift=0;
        k=k+1;
    end;
end;

if (state==1),
    if (motor_shift>=1)
        k=k+1;
        motor_shift=0;
    end;
    if k<=size(pattern,1),
        motor_shift=motor_shift+1/ceil(abs(increment/max_increment));
        posout(motors_to_use) = posout(motors_to_use) + (1-motor_shift)*pattern(k-1 ,:)' + motor_shift*pattern(k,:)';
    else
        state=2;
        if (~GO_TO_MAX),
            topposition=start_position;
        end;
        final_increment = min(1./ceil(abs(topposition(motors_to_use) - pattern(k-1,:)' - start_position(motors_to_use))/max_increment));
        motor_shift=0;
    end;
end;


if (state==2)
       disp('Finishing')
       if (motor_shift<1),
           motor_shift=motor_shift+final_increment;
           posout(motors_to_use) = (1-motor_shift)*(start_position(motors_to_use) + pattern(k-1,:)') + motor_shift*topposition(motors_to_use);
       else % make snug at the end
           posout(motors_to_use) = topposition(motors_to_use);
           done=1;
       end;
end;
disp([int2str(k),'/',int2str(size(pattern,1)+1)])
disp(['top position:',mat2str(topposition)])
disp(['max power:',mat2str(toppower)])
disp(['position setpoint:',mat2str(posout)])
current_position=posout;
maxpower = toppower;