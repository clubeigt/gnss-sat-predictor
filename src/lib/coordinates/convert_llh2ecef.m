function [xyz_ecef, J_llh2ecef] = convert_llh2ecef(llh, unit)

% Convert WGS84 LLH coordinates
% into corresponding WGS84 ECEF coordinates
%
% Syntax :
% xyz_ecef = convert_llh2ecef(llh);
% xyz_ecef = convert_llh2ecef(llh, unit);
% [xyz_ecef, J_llh2ecef] = convert_llh2ecef(...);
%
%
% Input :
%   llh : WGS84 LLH coordinates [latitude; longitude; heigth]
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
%
%
% Output :
%   xyz_ecef : Converted WGS84 ECEF coordinates
%              (same size as 'llh')
%
%   J_llh2ecef : Jacobian matrix of the conversion
%                (only for the first position)
%
%
% External function:
%   none
%



%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(llh, 1) == 3)
    is_transpose = false;
else
    llh = llh';
    is_transpose = true;
end

if (size(llh, 1) ~= 3)
    error('Input ''llh'' must be a [3,N] matrix.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
coef_unit2rad = 1;
if (nargin > 1)
    if strncmpi(unit, 'deg', 3)
        coef_unit2rad = pi/180;
    end
end

llh(1:2,:) = llh(1:2,:) * coef_unit2rad;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion
%--------------------------------------------------------------------------
% WGS84 parameters
a = 6378137.0000;        % Earth semimajor axis in meters
b = 6356752.3142;        % Earth semiminor axis in meters
e2 = 1 - (b/a).^2;       % Earth square eccentricity

% LLH coordinates
lat = llh(1,:);
lon = llh(2,:);
h = llh(3,:);

% local Earth radius of curvature
tmp = 1 - (e2 .* sin(lat).^2);
R0lon = a ./ sqrt(tmp);  % transverse radius

xyz_ecef = [(R0lon + h) .* cos(lat) .* cos(lon); ...
            (R0lon + h) .* cos(lat) .* sin(lon); ...
            (R0lon*(1 - e2) + h) .* sin(lat) ];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : transposition
%--------------------------------------------------------------------------
if is_transpose
    xyz_ecef = xyz_ecef';
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Jacobian matrix
%--------------------------------------------------------------------------
if (nargout > 1)
    % local Earth radius of curvature
    Rlat = (a * (1 - e2) ./ (tmp(1).^1.5)) + h(1);
    Rlon = (R0lon(1) + h(1)) .* cos(lat(1));
    
    J_llh2ecef = rot_z(-lon(1)) * rot_y(lat(1)) * [0     0   1; ...
                                                   0    Rlon 0; ...
                                                   Rlat  0   0];
    
    J_llh2ecef(:, 1:2) = J_llh2ecef(:, 1:2) * coef_unit2rad;
end
%--------------------------------------------------------------------------


end %convert_llh2ecef




%--------------------------------------------------------------------------
% Sub-functions
%--------------------------------------------------------------------------

function R = rot_z(angle)
% Compute the rotation matrix of a rotation along the Z axis
%
% Input :
%   angle :     rotation angle (radian)
%
% Output :
%   R :         rotation matrix
%

R = [cos(angle) sin(angle) 0 ; ...
    -sin(angle) cos(angle) 0 ; ...
         0          0      1 ];
end %rot_z

%--------------------------------------------------------------------------

function R = rot_y(angle)
% Compute the rotation matrix of a rotation along the Y axis
%
% Input :
%   angle :     rotation angle (radian)
%
% Output :
%   R :         rotation matrix

R = [cos(angle) 0 -sin(angle) ; ...
         0      1      0      ; ...
     sin(angle) 0  cos(angle) ];

end %rot_y

%--------------------------------------------------------------------------


