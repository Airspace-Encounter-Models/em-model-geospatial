% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
iso_3166_2 = {'US-KS','US-MA','US-MS','US-NC','US-ND','US-NH','US-NV','US-NY','US-OK','US-PR','US-RI','US-TN','US-TX','US-VA'}; % dev cases

% UAS variables
airspeed_kt = 50;
climbRate_fps = floor(1000 / 60);
descendRate_fps =  ceil(-1000/60);
alt_ft_agl = [250];

% Feature parameters
maxSpacing_ft = 50;

%% Iterate over iso_3166_2
for i=1:1:numel(iso_3166_2)
    % Define default DEMs, output directory, obstacles
    [dem, demDir, demBackup, demDirBackup, outDirBase, Tdof] = RunHelper_2(iso_3166_2{i});
    
    % Load and parse feature data
    [S, ~, airspace] = LoadParseWaterways(iso_3166_2{i});
    
    % Filter to include airspace near features of interest
    % We do this because looking up airspace is slow
    buff_deg = nm2deg(1);
    bbox = [min(cellfun(@min,S.LON_deg))-buff_deg, min(cellfun(@min,S.LAT_deg))-buff_deg; max(cellfun(@max,S.LON_deg))+buff_deg, max(cellfun(@max,S.LAT_deg))+buff_deg];
    [~, ~, inAirK] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,bbox);
    
    % Filter DOF obstacles and create S_obstacle
    [~, ~, inDofK] = filterboundingbox(Tdof.lat_deg,Tdof.lon_deg,bbox);
    S_obstacle = table(Tdof.lat_acc_deg(inDofK),Tdof.lon_acc_deg(inDofK),Tdof.alt_ft_msl(inDofK) - Tdof.alt_ft_agl(inDofK),Tdof.alt_ft_msl(inDofK),'VariableNames',{'LAT_deg','LON_deg','FLOOR_ft_msl','CEILING_ft_msl'});
    
    % Display status
    fprintf('%i potential airspace classes when i=%i\n',sum(inAirK),i);
    
    % Generate closed spaced waypoints trajectories
    GenerateTracks(S,...
        [outDirBase filesep 'osm_waterway_spacing' num2str(maxSpacing_ft)],...
        airspace(inAirK,:),...
        'trackMode','holdalt',...
        'maxSpacing_ft',maxSpacing_ft,...
        'alt_tol_ft',25,...
        'dem',dem,...
        'demBackup',demBackup,...
        'airspeed_kt',airspeed_kt,...
        'climbRate_fps',climbRate_fps,...
        'descendRate_fps',descendRate_fps,...
        'alt_ft_agl',alt_ft_agl,...
        'S_obstacle',S_obstacle,...
        'isCheckObstacle',true);
end
