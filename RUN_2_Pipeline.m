% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
iso_3166_2 = {'US-KS','US-MA','US-MS','US-NC','US-ND','US-NH','US-NV','US-NY','US-OK','US-PR','US-RI','US-TN','US-TX','US-VA'}; % dev cases

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
    
    % Set random seed
    rng(i,'twister');
    
    % Load and parse feature data
    [S, airspace] = LoadParseEIAPipelines(iso_3166_2{i});
    
    % Iterate over type
    u = unique(S.type);
    
    for k=1:1:size(u,1)
        % Filter on type
        lk = find(strcmp(S.type,u{k}));
        
        minLon = cellfun(@min,S.LON_deg(lk));
        minLat = cellfun(@min,S.LAT_deg(lk));
        maxLon = cellfun(@max,S.LON_deg(lk));
        maxLat = cellfun(@max,S.LAT_deg(lk));
        
        % Bounding box of all features
        buff_deg = nm2deg(1);
        bbox = [min(minLon)-buff_deg, min(minLat)-buff_deg; max(maxLon)+buff_deg, max(maxLat)+buff_deg];
        
        % Cluster if needed to help prevent loading a computationally intense DEM
        if numel(lk) > 10
            numClust = 10;
        else
            numClust = 2;
        end
        if 100 < distance(bbox(1,2),bbox(1,1),bbox(2,2),bbox(2,1),wgs84Ellipsoid('nm'))
            fprintf('Very large bounding box, creating %i kmeans clusters when i=%i, k=%i\n',numClust,i,k);
            [idx,~,~] = kmeans([minLat,minLon,maxLat,maxLon],numClust);
        else
            idx = ones(size(lk));
        end
        uidx = unique(idx);
        
        % Iterate over clusters
        for j=1:1:numel(uidx)
            % Filter on cluster
            lj = (uidx(j) == idx);
            
            % Filter to include airspace near features of interest
            % We do this because looking up airspace is slow
            bbox = [min(minLon(lj))-buff_deg, min(minLat(lj))-buff_deg; max(maxLon(lj))+buff_deg, max(maxLat(lj))+buff_deg];
            [~, ~, inAirK] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,bbox);
            
            % Filter DOF obstacles and create S_obstacle
            [~, ~, inDofK] = filterboundingbox(Tdof.lat_deg,Tdof.lon_deg,bbox);
            S_obstacle = table(Tdof.lat_acc_deg(inDofK),Tdof.lon_acc_deg(inDofK),Tdof.alt_ft_msl(inDofK) - Tdof.alt_ft_agl(inDofK),Tdof.alt_ft_msl(inDofK),'VariableNames',{'LAT_deg','LON_deg','FLOOR_ft_msl','CEILING_ft_msl'});
            
            % Display status
            fprintf('%i trajectories, %i potential airspace classes when i=%i, k=%i, j=%i\n',sum(lj),sum(inAirK),i,k,j);
            
            % Generate closed spaced waypoints trajectories
            outDir = [outDirBase filesep 'eia_pipeline_' u{k} '_spacing' num2str(maxSpacing_ft)];
            GenerateTracks(S(lk(lj),1:3),...
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
        end
    end
end

