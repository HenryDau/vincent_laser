function [thetaplus,thetaminus] = simultaneous_perturbation_stochastic_approximation(yplus,yminus)
p=2; % dimension of search space
persistent k
persistent theta
persistent delta
a=10;
c=10;
A=1;
alpha=.6;
gamma=.6;
startflag=0;
if (isempty(theta) | isempty(yplus)), 
    startflag=1;
    theta=[-20;-10]; 
    k=0
end;

if (startflag==0),
    ck=c/k^gamma;
    ak=a/(k+A)^alpha;
    ghat = (yplus - yminus)./(2*ck*delta);
    theta = theta + ak*ghat;
end;
k=k+1;
ck=c/k^gamma;
delta = 2*round(rand(p,1))-1;
thetaplus = theta + ck*delta;
thetaminus = theta - ck*delta;

