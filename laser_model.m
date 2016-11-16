function p = laser_model(pos)
c = [0;0];
sigma=100;
P=10;
noise_sigma=.1;
p = 10*exp(-0.5*norm(pos-c,2).^2/sigma)+noise_sigma*randn(1);