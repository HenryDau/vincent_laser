function [thetaout, current_position, maxpower] = simultaneous_perturbation_stochastic_approximation(power)
%thetaout = [1 + power / 3; 1+ power / 3];
%return;
p=2; % dimension of search space
persistent k
persistent ell
persistent theta
persistent lasttheta
persistent delta
persistent yplus
persistent ck
persistent toppower
a=1*pi/180;
c=5*pi/180;
A=1;
alpha=.5;
gamma=.25;
startflag=0;
yminus=0;

%
% power<0 indicates this is the first time this function has been called
%
if (power<0),
    disp('Search Initialized')
    theta=zeros(p,1);
    lasttheta=theta;
    toppower=0;
    yplus=0;
    k=0;
    ell=1;
    ck=c/(ell+1)^gamma;
    delta = ck*(2*round(rand(p,1))-1);
    thetaout = theta;
    return;
end;
k=k+1;
if (mod(k,3) == 0)
    yminus = power;
    ell=ell+1;
%
% Update theta
%
    ak=a/(ell+A)^alpha;
    ghat = (yplus - yminus)./delta;
    lasttheta = theta;
    theta = theta + ak*ghat;
%
% Choose new test direction
%
    ck=c/(ell+1)^gamma;
    delta = ck*(2*round(rand(p,1))-1);
    thetaout = theta;



elseif (mod(k,3)==2),
    yplus = power;
    thetaout = theta - delta;
else
    if power<.9*toppower,
        theta = lasttheta; % reject move if power is lower by significant amount
        disp(['Move rejected ', mat2str(theta)]);
    end;
    if power>toppower,
        toppower=power;
    end;
    thetaout = theta + delta;
end
current_position=theta;
maxpower=toppower;
thetaout
k
delta