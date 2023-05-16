function [llh, J_ecef2llh] = convert_ecef2llh(xyz_ecef, unit)

% Convert WGS84 ECEF coordinates
% into corresponding WGS84 LLH coordinates
%
% Syntax :
% llh = convert_ecef2llh(xyz_ecef);
% llh = convert_ecef2llh(xyz_ecef, unit);
% [llh, J_ecef2llh] = convert_ecef2llh(...);
%
%
% Input :
%   xyz_ecef : WGS84 ECEF coordinates
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
%
%
% Output :
%   llh : Converted WGS84 LLH coordinates [latitude; longitude; heigth]
%         (same size as 'xyz_ecef')
%
%   J_ecef2llh : Jacobian matrix of the conversion
%                (only for the first position)
%
%
% External function:
%   none
%



%--------------------------------------------------------------------------
% From the function ecef2geodetic of the Aerospace Toolbox
% Copyright 2005-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/04/03 03:17:08 $

% Reference
% ---------
% Paul R. Wolf and Bon A. Dewitt, "Elements of Photogrammetry with
% Applications in GIS," 3rd Ed., McGraw-Hill, 2000 (Appendix F-3).

% Implementation Notes from Rob Comer
% -----------------------------------
% The implementation below follows Wolf and DeWitt quite literally,
% with a few important exceptions required to ensure good numerical
% behavior:
%
% 1) I used ATAN2 rather than ATAN in the formulas for beta and phi.  This
%    avoids division by zero (or a very small number) for points on (or
%    near) the Z-axis.
%
% 2) Likewise, I used ATAN2 instead of ATAN when computing beta from phi
%    (conversion from geodetic to parametric latitude), ensuring
%    stability even for points at very high latitudes.
%
% 3) Finally, I avoided dividing by cos(phi) -- also problematic at high
%    latitudes -- in the calculation of h, the height above the ellipsoid.
%    Wold and Dewitt give
%
%                   h = sqrt(X^2 + Y^2)/cos(phi) - N.
%
%    The trick is to notice an alternative formula that involves division
%    by sin(phi) instead of cos(phi), then take a linear combination of the
%    two formulas weighted by cos(phi)^2 and sin(phi)^2, respectively. This
%    eliminates all divisions and, because of the identity cos(phi)^2 +
%    sin(phi)^2 = 1 and the fact that both formulas give the same h, the
%    linear combination is also equal to h.
%
%    To obtain the alternative formula, we simply rearrange
%
%                   Z = [N(1 - e^2) + h]sin(phi)
%    into
%                   h = Z/sin(phi) - N(1 - e^2).
%
%    The linear combination is thus
%
%        h = (sqrt(X^2 + Y^2)/cos(phi) - N) cos^2(phi)
%            + (Z/sin(phi) - N(1 - e^2))sin^2(phi)
%
%    which simplifies to
%
%      h = sqrt(X^2 + Y^2)cos(phi) + Zsin(phi) - N(1 - e^2sin^2(phi)).
%
%    From here it's not hard to verify that along the Z-axis we have
%    h = Z - b and in the equatorial plane we have h = sqrt(X^2 + Y^2) - a.


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(xyz_ecef, 1) == 3)
    is_transpose = false;
else
    xyz_ecef = xyz_ecef';
    is_transpose = true;
end

if (size(xyz_ecef, 1) ~= 3)
    error('Input ''xyz_ecef'' must be a [3,N] matrix.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
coef_rad2unit = 1;
if (nargin > 1)
    if strncmpi(unit, 'deg', 3)
        coef_rad2unit = 180/pi;
    end
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates convertion
%--------------------------------------------------------------------------
% Ellipsoid constants
a = 6378137.0000;       % earth semimajor axis in meters
b = 6356752.3142;       % earth semiminor axis in meters
e2 = (1 - (b/a)^2);     % square excentricity
ep2 = e2 / (1 - e2);  	% square of second eccentricity
f = 1 - sqrt(1 - e2); 	% flattening

% ECEF coordinates
x = xyz_ecef(1,:);
y = xyz_ecef(2,:);
z = xyz_ecef(3,:);

% Longitude
lambda = atan2(y,x);

% Distance from Z-axis
rho = hypot(x,y);

% Bowring's formula for initial parametric (beta) and geodetic (phi) latitudes
beta = atan2(z, (1 - f) * rho);
phi = atan2(z   + b * ep2 * sin(beta).^3,...
            rho - a * e2  * cos(beta).^3);

% Fixed-point iteration with Bowring's formula
% (typically converges within two or three iterations)
betaNew = atan2((1 - f)*sin(phi), cos(phi));
count = 0;
while any(beta(:) ~= betaNew(:)) && count < 5
    beta = betaNew;
    phi = atan2(z   + b * ep2 * sin(beta).^3,...
                rho - a * e2  * cos(beta).^3);
    betaNew = atan2((1 - f)*sin(phi), cos(phi));
    count = count + 1;
end

% Calculate ellipsoidal height from the final value for latitude
sinphi = sin(phi);
N = a ./ sqrt(1 - e2 * sinphi.^2);
h = rho .* cos(phi) + (z + e2 * N .* sinphi) .* sinphi - N;

llh = [phi; lambda; h];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : latitude and longitude unit conversion and transposition
%--------------------------------------------------------------------------
llh(1:2, :) = llh(1:2, :) * coef_rad2unit;

if is_transpose
    llh = llh';
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Conversion matrix
%--------------------------------------------------------------------------
if (nargout > 1)
    tmp = 1 - (e2 * sinphi(1).^2);
    Rlat = (a * (1 - e2) ./ (tmp.^1.5)) + h(1);
    Rlon = (N(1) + h(1)) .* cos(phi(1));
    
    J_ecef2llh = [0   0    1/Rlat; ...
                  0 1/Rlon   0   ; ...
                  1   0      0   ] * rot_y(-phi(1)) * rot_z(lambda(1));
    
    J_ecef2llh(1:2, :) = J_ecef2llh(1:2, :) * coef_rad2unit;
end
%--------------------------------------------------------------------------

end %function



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

