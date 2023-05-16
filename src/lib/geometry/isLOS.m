function los = isLOS(posT, posR)
%--------------------------------------------------------------------------
%        AUTHOR: Corentin Lubeigt
%       CREATED: 05/15/2023
%   
%   DESCRIPTION: this function checks if the studied configuration the
%   receiver can see the transmitter in the sky.
%
%        INPUTS: posT [km]   3x1 satellite (Tx) ECEF position.
%                posR [km]   3x1 receiver (Rx) ECEF position.
%       OUTPUTS: los  [bool] 1 if the satellite is in direct line-of-sight
%                            from the receiver, 0 otherwise.
%--------------------------------------------------------------------------

% Earth semi_axes
A = 6378.137;       %[km]
B = 6378.137;       %[km]
C = 6356.7523142;   %[km]

los=1;
for a = 0:0.001:1
    M = posR + a*(posT-posR);
    normM = sqrt(M(1)^2 + M(2)^2 + M(3)^2);
    if normM<min([A,B,C])
        los = 0;
        break;
    end
end
end