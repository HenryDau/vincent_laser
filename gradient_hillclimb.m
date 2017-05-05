function [posout, current_position, maxpower, done] = gradient_hillclimb(power, pos)
%thetaout = [1 + power / 3; 1+ power / 3];
%return;
pos_index=[1 2 3 4];
p=length(pos_index); % dimension of search space
maxchange = 5*pi/180;
persistent k
persistent ell
persistent theta
persistent delta
persistent motors
persistent ck
persistent motor_sign
persistent toppower
persistent toppower_position
persistent lastpower
persistent first_step
persistent state
persistent grad
c=2*pi/180;
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
    toppower_position=pos;
    k=1;
    first_step=0;
    ell=0;
    motors=1:p;
    grad=zeros(p,1);
    motor_sign = ones(1,p);
    delta = zeros(p,1)
    thetaout = theta;
    current_position=theta;
    maxpower=toppower;  
    state=1;
    return;
end;

if (power>toppower),
    toppower = power;
    toppower_position = pos;
end;


if (state==2),
   k=k+1;
   if (power>lastpower)
     theta = theta+grad;
   else
     state=1;
     grad=zeros(p,1);
   end;
end;


if (state==1),
   ell=ell+1;
   ck=c/(k+A)^gamma;
   
   if ell>1,
       grad(motors(1)) = (power-lastpower)/delta(motors(1));
   end;
   
   if ell>p,
%
% Change order for next time
%
        [index]=randperm(length(motors));
        motors=motors(index);
        motor_sign = motor_sign(index);
        ell=0;
        state=2;
        grad = grad*maxchange/max(abs(grad))*(1/(k)^gamma);
        theta = theta+grad;
   else  
%
% perturbation
%
      motors=circshift(motors,[0,-1]);
      motor_sign=circshift(motor_sign,[0,-1]);

      delta = zeros(p,1)
      delta(motors(1)) = ck*motor_sign(1);
      motor_sign(1)=-motor_sign(1);
      theta = theta + delta;
   end;

end;
lastpower=power;
    
posout(pos_index,1)=theta;
current_position=theta;
maxpower=toppower;
disp(['state=',int2str(state)]);
disp(['k=',int2str(k)])
disp(['ell=',int2str(ell)])
disp(['delta=',mat2str(delta)]);
disp(['motors=',mat2str(motors)]);