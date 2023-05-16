function filename = web_update_eop()
%--------------------------------------------------------------------------
%         USAGE: web_update_eop()
%
%        AUTHOR: Corentin Lubeigt
%       CREATED: 03/12/2020
%   
%   DESCRIPTION: this function goes on the internet NORAD website and fetch
%   the last EOP file. If in the eop folder, there is
%   a recent eop file (less that a day old) then, there is no need to
%   update the file.
%
%        INPUTS: None
% 
%       OUTPUTS: filename to read in the tle folder. filename is a negative 
%                         integer if an error occurs:
%                        string | name of the TLE file to be found in
%                               | the tle directory
%                        -------+------------------------------------------
%                            -1 | wrong constellation name, it must be one
%                               | of those: - 'gps'
%                               |           - 'galileo'
%                               |           - 'beidou'
%                               |           - 'glonass'
%--------------------------------------------------------------------------

path_to_eop = [pwd filesep 'orbit_files'];

url = 'https://celestrak.com/SpaceData/eop19620101.txt';

eop_files = ls(path_to_eop);
for i = 1:length(eop_files(:,1))
    if (contains(eop_files(i,:),'_19620101.eop')) % there is an eop file for this constellation
        % criterion: if the file is more than a day old, let's update it
        t_now = datestr(datetime('now'),30);
        t_then = str2double(eop_files(i,1:8));
        if (str2double(t_now(1:8)) - t_then > 1)
            new_eop = true;
        else
            new_eop = false;
            % no need to update the eop file, return the path of the
            % existing file
            filename = eop_files(i,:);
        end
    else
        new_eop = true;
    end
end

if (new_eop)
    options = weboptions();
    data    = webread(url,options);
    time = datestr(datetime('now'),30);
    filename = [time '_19620101.eop'];
    fid = fopen([path_to_eop filesep filename],'w');
    idx_obs_begin = strfind(data,'BEGIN OBSERVED');
    idx_obs_end = strfind(data,'END OBSERVED');
    idx_pre_begin = strfind(data,'BEGIN PREDICTED');
    idx_pre_end = strfind(data,'END PREDICTED');
    fwrite(fid,strcat(data(idx_obs_begin+16:idx_obs_end-3),data(idx_pre_begin+16:idx_pre_end-3)));
    fclose(fid);
end
end

