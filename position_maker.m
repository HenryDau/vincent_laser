start = -200;
increment = 100;
final = 200;
interval_up = 2;
time_stamp = 2;
motors_to_use = [1 2 4 5];
%data_size = ((start - final) / increment) * (start - final) / increment));
data = [];

data(1, :) = [0, 0, 0, 0, 0, 0, 0];
    
for motors = 0:-increment:start
    %data(end + 1, :) = [time_stamp, motors, motors, 0, motors, motors, 0];
    data(end + 1, 1) = [time_stamp];
    data(end, motors_to_use+1) = motors;
    time_stamp = time_stamp + interval_up;
end

%data(end + 1, :) = [time_stamp, start, start, 0, start, start, 0];
data(end + 1, 1) = time_stamp;
data(end, motors_to_use+1) = start;
time_stamp = time_stamp + interval_up;

pattern=[];
for i=1:length(motors_to_use),
    pattern=expand((start:increment:final)',pattern);
end;

for i=1:size(pattern,1),
    data(end+1,1) = time_stamp;
    data(end,motors_to_use+1) = pattern(i,:);
    time_stamp = time_stamp + interval_up;
end;


% for second_motor = start:increment:final
%     for first_motor = start:increment:final
% 
%         data(end + 1, :) = [time_stamp, first_motor, second_motor, 0, 0, 0, 0];
%         time_stamp = time_stamp + interval_up;
%     end
%     
%     for first_motor = final - increment:-increment:start + increment
% 
%         data(end + 1, :) = [time_stamp, first_motor, second_motor, 0, 0, 0, 0];
%         time_stamp = time_stamp + interval_back;
%     end
%     
% 
%     data(end + 1, :) = [time_stamp, start, second_motor, 0, 0, 0, 0];
%     time_stamp = time_stamp + interval_up;
% 
%     data(end + 1, :) = [time_stamp, start, second_motor, 0, 0, 0, 0];
%     time_stamp = time_stamp + interval_up;
% end


current_sign = sign(pattern(end,:))*sign(start);
for motors = start:increment:0
        %data(end + 1, :) = [time_stamp, motors,  0, -motors, motors, -motors, 0];
        data(end + 1, 1 ) = time_stamp;
        data(end, motors_to_use + 1 ) = current_sign*motors;
        time_stamp = time_stamp + interval_up;
end

data(end + 1, :) = [time_stamp, 0, 0, 0, 0, 0, 0];
time_stamp = time_stamp + interval_up;
data(end + 1, :) = [time_stamp, 0, 0, 0, 0, 0, 0];
time_stamp = time_stamp + interval_up;

% Outputs the position data to a file
fileID = fopen('test_data_1245_s200.txt', 'w');
%fprintf(fileID,'%5.0f\t\n', data(:,:));
[nrows,~] = size(data);
for row = 1:nrows
    fprintf(fileID,'%5.1f\t', data(row, :));
    fprintf(fileID,'\n');
end
fclose(fileID);