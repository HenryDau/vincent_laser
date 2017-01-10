%% Make fake power data based on current positions
function p = laser_model(pos)
pos = pos(1,[1,2,4,5])';
c = [0;0;.175;-.175];
sigma=sqrt(200)*pi/180;
P=10;
noise_sigma=.1;
p = P*exp(-0.5*norm(pos-c,2).^2/sigma^2)+noise_sigma*randn(1);
p = max(p,0);