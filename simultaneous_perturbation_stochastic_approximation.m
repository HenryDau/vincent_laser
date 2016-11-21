function [thetaout] = simultaneous_perturbation_stochastic_approximation(power)
%thetaout = [1 + power / 3; 1+ power / 3];
%return;
p=2; % dimension of search space
persistent k
persistent theta
persistent delta
persistent yplus
persistent ck
a=.5*pi/180;
c=5*pi/180;
A=1;
alpha=.6;
gamma=.6;
startflag=0;
yminus=0;

%
% power<0 indicates this is the first time this function has been called
%
if (power<0), 
    disp('Search Initialized')
    theta=[0;0];
    yplus=0;
    k=0;
    ck=c/(k+1)^gamma;
    delta = ck*(2*round(rand(p,1))-1);
    thetaout = theta + delta;
    return;
end;
k=k+1
if (mod(k,2) == 0)
    yminus = power;
%
% Update theta
%
    ak=a/(k+A)^alpha;
    ghat = (yplus - yminus)./delta;
    theta = theta + ak*ghat;
%
% Update thetaout
% 
    ck=c/k^gamma;
    delta = ck*(2*round(rand(p,1))-1);
    thetaout = theta + delta;

else
    yplus = power;
    thetaout = theta - delta;
end
%theta
%thetaout
%delta
%ck
%ak
%yplus
%yminus
%ghat