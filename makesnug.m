%
% This code will direct the motor to send a series of very small pulses
% These pulses are strong enough to move the hex tool, but not
% strong enough to move the screw if it is engaged.
%
%obj = serial('/dev/cu.usbmodem1411','BaudRate', 115200);
obj = serial('COM6', 'BaudRate', 115200);
fopen(obj);
pause(1)
Motor=1; % Motor to make snug
Positionindex=[2 6 10];
position=[];
k=1;
quitloop=0;
% Do this until the motor does not move for 100 pulses, or a max of 1000
% pulses
while (quitloop~=1 & k<1000), 
  fprintf(obj,'%s\n',['I',int2str(Motor),'1']);
  data = fgets(obj);
  dataarray = strsplit(data,char(9));
  position(k) = eval(dataarray{Positionindex(Motor)});
  if k>100,
      if sum(diff(position(k-100:k)))==0, quitloop=1; end;
  end;
  k=k+1;
end;
fclose(obj);
plot(position)
