function filename = web_update_tle(constellation)
%--------------------------------------------------------------------------
%         USAGE: web_update_tle()
%
%        AUTHOR: Corentin Lubeigt
%       CREATED: 02/10/2020
%   
%   DESCRIPTION: this function goes on the internet NORAD website and fetch
%   the last TLE of the GNSS constellations. If in the tle folder, there is
%   a tle recent tle file (less that a day old) then, there is no need to
%   update the file.
%
%        INPUTS: constellation  name of the constellation whose TLEs need 
%                               to be fetched ('gps' or 'galileo')
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

path_to_tle = [pwd filesep 'orbit_files'];

err     = false;
new_tle = true;

switch constellation
    case 'galileo'
        url = 'https://celestrak.com/NORAD/elements/galileo.txt';
    case 'gps'
        url = 'https://celestrak.com/NORAD/elements/gps-ops.txt'; 
    case 'glonass'
        url = 'https://celestrak.com/NORAD/elements/glo-ops.txt';
    case 'beidou'
        url = 'https://celestrak.com/NORAD/elements/beidou.txt';
    otherwise
        disp('[ERROR] web_update_tle: wrong constellation name. It must be ''gps'' or ''galileo''.');
        err = true;
        filename = -1;
end

if (~err)
    % is the data already loaded?
    tle_files = ls(path_to_tle);
    for i = 1:length(tle_files(:,1))
        if (contains(tle_files(i,:),[constellation '.tle'])) % there is a tle file for this constellation
            % criterion: if the file is more than a day old, let's take a new one
            t_now = datestr(datetime('now'),30);
            t_then = str2double(tle_files(i,1:8));
            if (str2double(t_now(1:8)) - t_then > 1)
                new_tle = true;
            else
                new_tle = false;
                % no need to update the tle file, return the path of the
                % existing file
                filename = tle_files(i,:);
            end
        end
    end
    
    if (new_tle)
        options = weboptions();
        data    = webread(url,options);
        time = datestr(datetime('now'),30);
        filename = [time '_' constellation '.tle'];
        fid = fopen([path_to_tle filesep filename],'w');
        fwrite(fid,data);
        fclose(fid);
    end
end
end % end of web_update_tle
