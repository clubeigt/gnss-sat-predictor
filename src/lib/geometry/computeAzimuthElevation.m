%This Function Compute Azimuth and Elevation of satellite from reciever 
%CopyRight By Moein Mehrtash
%************************************************************************
% Written by Moein Mehrtash, Concordia University, 3/21/2008            *
% Email: moeinmehrtash@yahoo.com                                        *
%************************************************************************           
%    ==================================================================
%    Input :                                                            *
%        PosR_ECEF [m] position of reciever                             *
%        PosT_ECEF [m] position of satellites                           *
%    Output:                                                            *
%        elevation [rad] Elevation                                      *
%        azimuth   [rad] Azimuth                                        *
%************************************************************************           
function [elevation,azimuth] = computeAzimuthElevation(PosR_ECEF,PosT_ECEF, deg_option)

if nargin == 3 && strcmp(deg_option,'deg')
    coeff = 180/pi;
else
    coeff = 1;
end

RT=PosT_ECEF-PosR_ECEF; % vector from Reciever to Satellite

llh = convert_ecef2llh(PosR_ECEF); % Latitude and Longitude of Receiver

ENU = [            -sin(llh(2))              cos(llh(2))           0;
       -sin(llh(1))*cos(llh(2)) -sin(llh(1))*sin(llh(2)) cos(llh(1));
        cos(llh(1))*cos(llh(2))  cos(llh(1))*sin(llh(2)) sin(llh(1))]*RT;
   
elevation = coeff*asin(ENU(3)/norm(ENU));
azimuth   = coeff*atan2(ENU(1)/norm(ENU),ENU(2)/norm(ENU));
end