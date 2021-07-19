% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
% Locations to iterate over
iso_3166_2 = {'US-MA','US-MS','US-NC','US-ND','US-NH','US-NY','US-PR','US-RI','US-TX','US-VA'}; % dev cases

% UAS variables
airspeed_kt = 10; % About 1 meter per second, ref https://doi.org/10.1179/1743289815Y.0000000003
climbRate_fps = 10; % About 3 meters per second
descendRate_fps = -10; % About 3 meters per second
alt_ft_agl = [250];

% Feature parameters
maxSpacing_ft = 50;

% FAA DOF
obsTypes = {'antenna','lgthouse','met','monument','sign','silo','spire','stack','t-l twr','tank','tower','tramway','utility pole','windsock'};
minHeight_ft = 50;

% Point Obstacle
pointHorz_ft = 250; % Horizontal
pointVert_ft = 50; % Vertical
trackMode = 'point-ring';

%% Iterate over iso_3166_2
for i=1:1:numel(iso_3166_2)
    % Define default DEMs and output directory
    [dem, demDir, demBackup, demDirBackup, outDirBase, ~] = RunHelper_2(iso_3166_2{i});
    
    % Set random seed
    rng(i,'twister');
    
    % Load and parse feature data
    [S, airspace] = LoadParseFAADOF(iso_3166_2{i},...
        'obsTypes',obsTypes,'minHeight_ft',minHeight_ft,...
        'pointHorz_ft',pointHorz_ft,'pointVert_ft',pointVert_ft);
    
    % Generate trajectories organized by height
    u = unique(S(:,5:6),'rows');
    
    % Iterate
    for k=1:1:size(u,1)
        % Logical index of heights
        lk = find(S.type == u.type(k) & S.pointHeight_ft_agl == u.pointHeight_ft_agl(k));
        
        minLon = cellfun(@min,S.LON_deg(lk));
        minLat = cellfun(@min,S.LAT_deg(lk));
        maxLon = cellfun(@max,S.LON_deg(lk));
        maxLat = cellfun(@max,S.LAT_deg(lk));
        
        % Bounding box of all features
        buff_deg = nm2deg(1);
        bbox = [min(minLon)-buff_deg, min(minLat)-buff_deg; max(maxLon)+buff_deg, max(maxLat)+buff_deg];
        
        % Cluster if needed to help prevent loading a computationally intense DEM
        if numel(lk) == 1
            idx = 1;
        else
            if 100 < distance(bbox(1,2),bbox(1,1),bbox(2,2),bbox(2,1),wgs84Ellipsoid('nm'))
                % Determine number of clusters
                if numel(lk) > 4
                    numClust = ceil(numel(lk) * .25);
                else
                    numClust = 2;
                end
                
                fprintf('Very large bounding box, creating %i kmeans clusters when i=%i, k=%i\n',numClust,i,k);
                [idx,~,~] = kmeans([minLat,minLon,maxLat,maxLon],numClust);
            else
                idx = ones(size(lk));
            end
        end
        uidx = unique(idx);
        
        % Iterate over clusters
        for j=1:1:numel(uidx)
            % Filter on cluster
            lj = (uidx(j) == idx);
            
            % Filter to include airspace near features of interest
            % We do this because looking up airspace is slow
            [~, ~, inAirK] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,[min(minLon(lj))-buff_deg, min(minLat(lj))-buff_deg; max(maxLon(lj))+buff_deg, max(maxLat(lj))+buff_deg]);
            
            % No filtering on obstacles
            
            % Display status
            fprintf('%i trajectories, %i potential airspace classes when i=%i, k=%i, j=%i\n',sum(lj),sum(inAirK),i,k,j);
            
            outDir = [outDirBase filesep 'dof_' strrep(matlab.lang.makeValidName(u.type{k}),'_','-') '_' trackMode '_pointHorz' num2str(pointHorz_ft) '_pointVert' num2str(pointVert_ft) '_minHeight' num2str(minHeight_ft) '_spacing' num2str(maxSpacing_ft)];
            GenerateTracks(S(lk(lj),1:3),...
                outDir,...
                airspace(inAirK,:),...
                'trackMode',trackMode,...
                'pointRadius_ft',S.pointRadius_ft(lk(lj)),...
                'pointHeight_ft_agl',S.pointHeight_ft_agl(lk(lj)),...
                'maxSpacing_ft',maxSpacing_ft,...
                'dem',dem,...
                'demDir',demDir,...
                'demBackup',demBackup,...
                'demDirBackup',demDirBackup,...
                'airspeed_kt',airspeed_kt,...
                'climbRate_fps',climbRate_fps,...
                'descendRate_fps',descendRate_fps,...
                'alt_ft_agl',u.pointHeight_ft_agl(k),...
                'isCheckObstacle',false);
        end
    end
end
