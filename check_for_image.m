function check_for_image(dst, time)
% This functio will check if an imag has been saved to the folder.
%    It will then saved the image to a new folder corresponding to the
%    current log and rename the image to the timestamp
try
    if (isnan(time))
        time = 0;
    end

    % Add the folder marker
    dst = [dst, '/'];

    % Constants to change if needed
    folder = 'Z:\adit\My Documents\BeamGage\Data\';
    filename = 'first_cap.binary.bgData';
    path = [folder, filename];

    % Check if the file exists
    if (exist(path, 'file') == 2)
        movefile(path, dst);

        % Give it the correct name
        movefile([dst, filename], [dst, [int2str(time), '.binary.bgdata']]);
    end
catch OSError
    % For now, ignore OS errors.
    
end
    


end

