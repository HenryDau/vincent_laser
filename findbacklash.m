obj = serial('/dev/cu.usbmodem1411','BaudRate', 115200);
fopen(obj);
pause(1)
Motor=1;
Pulselist=1*[-ones(200,1);ones(300,1);-ones(200,1);ones(300,1)];
Positionindex=[2 6 10];
for k=1:length(Pulselist),
  fprintf(obj,'%s\n',['I',int2str(Motor),int2str(Pulselist(k))]);
  data = fgets(obj);
  dataarray = strsplit(data,char(9));
  position(k) = eval(dataarray{Positionindex(Motor)});
end;


fclose(obj);
plot(position)
