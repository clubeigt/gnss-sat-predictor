function skyplot(sv,azim_deg,elev)

% SKYPLOT	Produces satellite skyplot.
%           Input:
%             sv    = vector of PRN numbers 
%             azim  = azimuth in deg
%             elev  = elevation in deg
% Call: skyplot(sv,azim,elev,unit)
% http://www.geologie.ens.fr/~ecalais/teaching/gps-geodesy/solutions-to-gps-geodesy/

%--------------------------------------------------------------------------
% Azimuth unit conversion (rad)
%--------------------------------------------------------------------------
azim_rad = azim_deg * pi/180;
%--------------------------------------------------------------------------

figure, polarplot(0,90);
pax = gca;
pax.ThetaDir            = 'clockwise';
pax.ThetaZeroLocation   = 'top';
pax.ThetaTickLabels     = {'N' ,'30' ,'60' ,'E' ,'120' ,'150' ,'S' ,'210' ,'240' ,'W' ,'300' ,'330'};
pax.RMinorGrid          = 'on';
pax.RGrid               = 'on';
pax.RDir                = 'reverse';
pax.RLim                = [0 90];
hold on;


%disp(['-------------']);
%disp(['[skyplot]: Producing sky plot...']);


for i=1:length(sv)
    polarplot(azim_rad(i),elev(i),'.b','MarkerSize',25); hold on
    text(azim_rad(i)+0.1,elev(i),sv(i),'color','r','FontWeight','bold','FontSize',12);
end
%drawnow;