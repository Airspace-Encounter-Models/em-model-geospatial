% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
iso_3166_2 = {'US-MA','US-MS','US-NC','US-ND','US-NH','US-NY','US-PR','US-RI','US-TX','US-VA'}; % dev cases

% UAS variables
% https://www.technologyreview.com/s/610735/zipline-launches-the-worlds-fastest-commercial-delivery-drone/
% https://spectrum.ieee.org/robotics/drones/in-the-air-with-ziplines-medical-delivery-drones
%airspeed_kt = [55, 70]; % Approx. zipline cruise and max airspeeds
airspeed_kt = 50;
climbRate_fps = floor(1000 / 60);
descendRate_fps =  ceil(-1000/60);
alt_ft_agl = [250];

% Feature parameters
maxSpacing_ft = 50;

%% Iterate over iso_3166_2
for i=1:1:numel(iso_3166_2)
    % Define default DEMs and output directory
    [dem, demDir, demBackup, demDirBackup, outDirBase, Tdof] = RunHelper_2(iso_3166_2{i});
    
    % Load and parse feature data
    [S, ~, airspace] = LoadParseTransmissionLines(iso_3166_2{i});
    
    % Iterate over type
    u = unique(S(:,4:5),'rows');
    
    for k=1:1:size(u,1)
        % Filter
        l = strcmp(S.type,u.type(k)) & strcmp(S.volt_class,u.volt_class(k));
        
        % Filter to include airspace near features of interest
        % We do this because looking up airspace is slow
        buff_deg = nm2deg(1);
        bbox = [min(cellfun(@min,S.LON_deg(l)))-buff_deg, min(cellfun(@min,S.LAT_deg(l)))-buff_deg; max(cellfun(@max,S.LON_deg(l)))+buff_deg, max(cellfun(@max,S.LAT_deg(l)))+buff_deg];
        [~, ~, inAirK] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,bbox);
        
        % Filter DOF obstacles and create S_obstacle
        [~, ~, inDofK] = filterboundingbox(Tdof.lat_deg,Tdof.lon_deg,bbox);
        S_obstacle = table(Tdof.lat_acc_deg(inDofK),Tdof.lon_acc_deg(inDofK),Tdof.alt_ft_msl(inDofK) - Tdof.alt_ft_agl(inDofK),Tdof.alt_ft_msl(inDofK),'VariableNames',{'LAT_deg','LON_deg','FLOOR_ft_msl','CEILING_ft_msl'});
        
        % Display status
        fprintf('%i trajectories, %i potential airspace classes when i=%i, k=%i\n',sum(l),sum(inAirK),i,k);
        
        % Generate closed spaced waypoints trajectories
        outDir = [outDirBase filesep 'hifld_electrictransmission_'  strrep(matlab.lang.makeValidName(u.type{k}),'_','-') '_' strrep(u.volt_class{k},'_','-') '_spacing' num2str(maxSpacing_ft)];
        GenerateTracks(S(l,1:3),...
            outDir,...
            airspace(inAirK,:),...
            'trackMode','holdalt',...
            'maxSpacing_ft',maxSpacing_ft,...
            'alt_tol_ft',25,...
            'dem',dem,...
            'demDir',demDir,...
            'demBackup',demBackup,...
            'demDirBackup',demDirBackup,...
            'airspeed_kt',airspeed_kt,...
            'climbRate_fps',climbRate_fps,...
            'descendRate_fps',descendRate_fps,...
            'alt_ft_agl',alt_ft_agl,...
            'S_obstacle',S_obstacle,...
            'isCheckObstacle',true);
    end % End k loop
end % End i loop
