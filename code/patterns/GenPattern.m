function [lat_deg,lon_deg] = GenPattern(bbox,patId,alt_ft,camTheta_deg)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Define Geodetic of local origin
lon0 = bbox(1,1); lon1 = bbox(2,1);
lat0 = bbox(1,2); lat1 = bbox(2,2);

% Calculate length and width of search area, convert to feet
arclen_width_ft = distance('gc',bbox(1,2),bbox(1,1),bbox(1,2),bbox(2,1),referenceEllipsoid('WGS84','feet'),'degrees');
arclen_length_ft = distance('gc',bbox(1,2),bbox(1,1),bbox(2,2),bbox(1,1),referenceEllipsoid('WGS84','feet'),'degrees');
areas_ft = [arclen_width_ft, arclen_length_ft];

%% Generate trajectory in local NED coordinates
sPath = UAScreatePath(patId,alt_ft,areas_ft,camTheta_deg);

%% Convert from Local Cartesian NED to geodetic
if size(sPath,1) == 1
    % Preallocate
    lat_deg = zeros(2,1);
    lon_deg = zeros(2,1);
    
    % Scenario where camera footprint is too large or small and
    % UAScreatePath tells the path to just goto the middle
    % This needs to be fixed...what happens here is that we
    % create a straight line trajectory through the middle of
    % the polygon
    [lat_deg(1),lon_deg(1)] = CalcLatLonMid(lat0,lon0,lat0,lon1);
    [lat_deg(2),lon_deg(2)] = CalcLatLonMid(lat0,lon0,lat1,lon0);
else
    h0 = alt_ft;
    
    % Define Local NED
    xNorth = sPath(:,2); %* unitsratio('m','ft');
    yEast = sPath(:,1); %* unitsratio('m','ft');
    zDown = repmat(alt_ft,size(sPath,1),1);
    
    % Convert from Local Cartesian NED to geodetic
    [lat_deg,lon_deg, ~] = ned2geodetic(xNorth,yEast,zDown,lat0,lon0,h0,referenceEllipsoid('WGS84','ft'));
end
