function [posout, current_position, maxpower, done] = simultaneous_perturbation_stochastic_approximation(power, pos)
%thetaout = [1 + power / 3; 1+ power / 3];
%return;
p=4; % dimension of search space
pos_index=[1 2 3 4];
persistent k
persistent ell
persistent theta
persistent delta
persistent motors
persistent ck
persistent motor_sign
persistent toppower
persistent lastpower
persistent first_step
c=20*pi/180;
A=9;
gamma=.5;
startflag=0;
done = false;

posout=pos;
pos=pos(pos_index);

%
% power<0 indicates this is the first time this function has been called
%
if (power<-.1),
    disp('Search Initialized')
    theta=pos;
    lastpower=0;
    toppower=0;
    k=0;
    first_step=0;
    ell=1;
    motors=1:p;
    motor_sign = ones(1,p);
    ck=c/(ell+A)^gamma;
    delta = zeros(p,1)
    delta(1) = ck;
    thetaout = theta;
    current_position=theta;
    maxpower=toppower;    
    return;
end;
pos=pos(pos_index);
k=k+1;
if (power>toppower),
    toppower = power;
end;
if (power>lastpower)
    first_step=0;
    theta = theta+delta;
else
    ell=ell+1;
    motor_sign(1)=-motor_sign(1);
%
% every 8 steps, randomly sort the motors
%
    if mod(ell,8)==1;
        [index]=randperm(length(motors));
        motors=motors(index);
        motor_sign = motor_sign(index);
    else         
      motors=circshift(motors,[0,-1]);
      motor_sign=circshift(motor_sign,[0,-1]);
    end;
    
    delta = zeros(p,1);
    ck=c/(ell+A)^gamma;
    delta(motors(1)) = ck*motor_sign(1);
    theta = theta + delta;
    first_step=1;
end;
lastpower=power;
    
posout(pos_index,1)=theta;
current_position=theta;
maxpower=toppower;
disp(['k=',int2str(k)])
disp(['ell=',int2str(ell)])
disp(['delta=',mat2str(delta)]);
disp(['motors=',mat2str(motors)]);