function [satellites_pos, satellites_names, retval] = get_sat_positions(constellation, start_time, time_since)
%--------------------------------------------------------------------------
%        AUTHOR: Corentin Lubeigt
%       CREATED: 03/12/2020
%   
%   DESCRIPTION: this function uses an SGP4 obit propagator developped in 
%                reference [1] to provide the position of the specified
%                constellation at a given time (start_time + time_since).
%
%        INPUTS: constellation  [str] constellation studied ('gps',
%                                     'galileo', 'glonass' or 'beidou'). It
%                                     can be set as 'custom' and then
%                                     refers to a custom tle file that may
%                                     gather several constallations
%                start_time     [MJD] start time of the simulation in Modified Julian Date
%                time_since     [min] number of minutes since the begining
%                                     of the simulation
%           
%       OUTPUTS: satellites_pos       position in the ECEF frame
%                satellites_names     satellites constellation names
%                retval
%
%    REFERENCES: [1] Meysam Mahooti (2020). SGP4 (https://www.mathworks.com 
%                    /matlabcentral/fileexchange/62013-sgp4), MATLAB Central 
%                    File Exchange. Retrieved March 9, 2020.
%--------------------------------------------------------------------------

format long g

addpath(['lib' filesep 'web']);

global const
SAT_Const

%% I - Obtain TLE and convert its content

[satellites, retval] = generate_satellite_from_tle(constellation);

if (~retval)
%% II - position/velocity computation
    satellites_pos = nan(3,length(satellites));
    satellites_names = strings(1,length(satellites));
    % read Earth orientation parameters
    fname = web_update_eop();
    if isnumeric(fname) % fname is supposed to be a string, if not, something went wrong when fetching the EOP file
        disp("[ERROR] web_update_eop: retval = " + num2str(fname));
        retval = -3;
    else
        fid = fopen(['orbit_files' filesep fname],'r');
        %  ----------------------------------------------------------------------------------------------------
        % |  Date    MJD      x         y       UT1-UTC      LOD       dPsi    dEpsilon     dX        dY    DAT
        % |(0h UTC)           "         "          s          s          "        "          "         "     s 
        %  ----------------------------------------------------------------------------------------------------
        eopdata = fscanf(fid,'%i %d %d %i %f %f %f %f %f %f %f %f %i',[13 inf]);
        fclose(fid);

        for j=1:length(satellites)
            % we synchronize all the satellite at the same time 
            % (start_time + time_since)
            tsince = start_time - satellites(j).epoch + time_since/1440; %[day]
            %tsince = time_since/1440; %[day]
            
            
            [mon,day,hr,minute,sec] = days2mdh(satellites(j).year,satellites(j).doy+tsince);
            MJD_UTC = Mjday(satellites(j).year,mon,day,hr,minute,sec);

            % Earth Orientation Parameters
            [x_pole,y_pole,UT1_UTC,LOD,dpsi,deps,dx_pole,dy_pole,TAI_UTC] = IERS(eopdata,MJD_UTC,'l');
            [UT1_TAI,UTC_GPS,UT1_GPS,TT_UTC,GPS_UTC] = timediff(UT1_UTC,TAI_UTC);
            MJD_UT1 = MJD_UTC + UT1_UTC/86400;
            MJD_TT  = MJD_UTC + TT_UTC/86400;
            T = (MJD_TT-const.MJD_J2000)/36525;

            [rteme, vteme]  = sgp4(tsince*1440, satellites(j)); % /!\ first argument in minutes /!\
            [recef, ~]      = convert_teme2ecef(rteme,vteme,T,MJD_UT1+2400000.5,LOD,x_pole,y_pole,2);
            satellites_pos(:,j) = recef;
            satellites_names(j) = get_satellite_id(satellites(j).name);
        end
    end
end
end % function get_constellation_positions

%--------------------------------------------------------------------------
%       SUB FUNCTIONS
%--------------------------------------------------------------------------
% generate satellite from TLE. This function goes and rean tle files of the
% specified constellation and parses it to obtain the input variables of the 
% SGP4 orbit propagator algorithm 
function [satellites, retval] = generate_satellite_from_tle(constellation)

    ge = 398600.8; % Earth gravitational constant
    TWOPI = 2*pi;
    MINUTES_PER_DAY = 1440.;
    MINUTES_PER_DAY_SQUARED = (MINUTES_PER_DAY * MINUTES_PER_DAY);
    MINUTES_PER_DAY_CUBED = (MINUTES_PER_DAY * MINUTES_PER_DAY_SQUARED);

    satellites = [];
    retval = 0;
    if (constellation == "custom")
        fname = "custom_tle.tle";
    else
         fname = web_update_tle(constellation);
    end
    if isnumeric(fname) % fname is supposed to be a string, if not, something went wrong when fetching the EOP file
        disp("[ERROR] web_update_tle: retval = " + num2str(fname));
        retval = -2;
    else
        % Open the TLE file and read TLE elements
        fid = fopen(['orbit_files' filesep fname], 'r');


        % 19-32	04236.56031392	Element Set Epoch (UTC)
        % 3-7	25544           Satellite Catalog Number
        % 9-16	51.6335         Orbit Inclination (degrees)
        % 18-25	344.7760        Right Ascension of Ascending Node (degrees)
        % 27-33	0007976         Eccentricity (decimal point assumed)
        % 35-42	126.2523        Argument of Perigee (degrees)
        % 44-51	325.9359        Mean Anomaly (degrees)
        % 53-63	15.70406856     Mean Motion (revolutions/day)
        % 64-68	32890           Revolution Number at Epoch

        while (1)    
            % read first line (name)
            tline = fgetl(fid);
            if ~ischar(tline)
                break
            end
            satname = tline;

            % read second line
            tline = fgetl(fid);
            if ~ischar(tline)
                break
            end
            Cnum = tline(3:7);      			           % Catalog Number (NORAD)
            SC   = tline(8);					           % Security Classification
            ID   = tline(10:17);			               % Identification Number
            year = str2double(tline(19:20));               % Year
            doy  = str2double(tline(21:32));               % Day of year
            epoch = str2double(tline(19:32));              % Epoch
            TD1   = str2double(tline(34:43));              % first time derivative
            TD2   = str2double(tline(45:50));              % 2nd Time Derivative
            ExTD2 = tline(51:52);                          % Exponent of 2nd Time Derivative
            BStar = str2double(tline(54:59));              % Bstar/drag Term
            ExBStar = str2double(tline(60:61));            % Exponent of Bstar/drag Term
            BStar = BStar*1e-5*10^ExBStar;
            Etype = tline(63);                             % Ephemeris Type
            Enum  = str2double(tline(65:end));             % Element Number

            % read third line
            tline = fgetl(fid);
            if ~ischar(tline)
                break
            end
            i = str2double(tline(9:16));                   % Orbit Inclination (degrees)
            raan = str2double(tline(18:25));               % Right Ascension of Ascending Node (degrees)
            e = str2double(strcat('0.',tline(27:33)));     % Eccentricity
            omega = str2double(tline(35:42));              % Argument of Perigee (degrees)
            M = str2double(tline(44:51));                  % Mean Anomaly (degrees)
            no = str2double(tline(53:63));                 % Mean Motion
            a = ( ge/(no*2*pi/86400)^2 )^(1/3);            % semi major axis (m)
            rNo = str2double(tline(64:68));                % Revolution Number at Epoch

            satdata.name = satname;
            satdata.epoch = epoch;
            satdata.norad_number = Cnum;
            satdata.bulletin_number = ID;
            satdata.classification = SC; % almost always 'U'
            satdata.revolution_number = rNo;
            satdata.ephemeris_type = Etype;
            satdata.xmo = M * (pi/180);
            satdata.xnodeo = raan * (pi/180);
            satdata.omegao = omega * (pi/180);
            satdata.xincl = i * (pi/180);
            satdata.eo = e;
            satdata.xno = no * TWOPI / MINUTES_PER_DAY;
            satdata.xndt2o = TD1 * 1e-8 * TWOPI / MINUTES_PER_DAY_SQUARED;
            satdata.xndd6o = TD2 * TWOPI / MINUTES_PER_DAY_CUBED;
            satdata.bstar = BStar;

            satdata.doy = doy;

            if (year < 57)
                satdata.year = year + 2000;
            else
                satdata.year = year + 1900;
            end

            [mon,day,hr,minute,sec] = days2mdh(satdata.year,satdata.doy);
            satdata.epoch = Mjday(satdata.year,mon,day,hr,minute,sec);
            
            
            satellites = [satellites satdata];
        end
        fclose(fid);
    end
end % function generate_satellite_from_tle

% get_stallite_id collects the name of the satellite watever its
% constellation
% credit: Benoit Priot (benoit.priot@isae-supaero.fr
function id_str = get_satellite_id(sat_name)

    id_str = sat_name((strfind(sat_name,'(')+1):(strfind(sat_name,')')-1));
    N = length(id_str);
    
    if ((N > 5) && strncmpi(id_str, 'PRN E', 5)) % GALILEO
        id_str = id_str(5:end);
    elseif ((N > 4) && strncmpi(id_str, 'PRN ', 4)) % GPS
        id_str = ['G' id_str(5:end)];
    else % either BEIDOU or GLONASS
        if ~strcmp(id_str(1), 'C') % NOT BEIDOU -> GLONASS
            id_str = ['R' id_str];
        end
    end

end
