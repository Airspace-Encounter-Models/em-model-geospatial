% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
% Locations to iterate over
iso_3166_2 = {'US-CA','US-AL','US-AR','US-AZ','US-CO','US-CT','US-DE','US-FL','US-GA','US-HI','US-IA','US-ID','US-IL','US-IN','US-KS','US-KY','US-LA','US-MA','US-MD','US-ME','US-MI','US-MN','US-MO','US-MS','US-MT','US-NC','US-ND','US-NE','US-NH','US-NJ','US-NM','US-NV','US-NY','US-OH','US-OK','US-OR','US-PA','US-RI','US-SC','US-SD','US-TN','US-TX','US-UT','US-VA','US-VT','US-WA','US-WI','US-WV','US-WY','US-PR'};

% UAS variables
% https://doi.org/10.1109/OSES.2019.8867145
% https://youtu.be/5v2dQS1tU9w
airspeed_kt = round(1 * (3600/unitsratio('m','nm')),0); % About 1 meter per second, ref https://doi.org/10.1179/1743289815Y.0000000003
climbRate_fps = round(1*unitsratio('ft','m'),1);
descendRate_fps = round(-1*unitsratio('ft','m'),1);
alt_ft_agl = [250];

% Point Obstacle
% Tower diameter = 14 ft, ref http://www.acua.com/uploadedFiles/Site/About_Us/WindFarm.pdf
% Tower diamter = 13 ft, ref https://www.sciencedirect.com/science/article/pii/S0143974X13000047
% Distance from tower = 5 meters / 17 feet, ref https://doi.org/10.1109/OSES.2019.8867145
obstacleWidthMode = {'tower','blade'}; obstacleWidthMode = obstacleWidthMode{2};
pointHorz_ft = 250; % Horizontal, i.e. tower radius + distance from tower)
pointVert_ft = 50; % Vertical

% Feature parameters
maxSpacing_ft = 50;

%% Iterate over iso_3166_2
for i=1:1:numel(iso_3166_2)
    % Define default DEMs, output directory, obstacles
    [dem, demDir, demBackup, demDirBackup, outDirBase, Tdof] = RunHelper_2(iso_3166_2{i});
    
    % Load and parse feature data
    [S, ~, airspace, ~] = LoadParseUSWTDB(iso_3166_2{i},...
        'obstacleWidthMode',obstacleWidthMode,'pointHorz_ft',pointHorz_ft,'pointVert_ft',pointVert_ft);
    
    % Generate trajectories organized by height
    % Unique heights
    uHeight = unique(S.pointHeight_ft_agl);
    
    % Iterate
    for k=1:1:numel(uHeight)
        % Logical index of heights
        l = S.pointHeight_ft_agl == uHeight(k);
        
        % Filter to include airspace near features of interest
        % We do this because looking up airspace is slow
        buff_deg = 2*nm2deg(max(S.pointRadius_ft)*unitsratio('nm','ft'));
        bbox = [min(cellfun(@min,S.LON_deg(l)))-buff_deg, min(cellfun(@min,S.LAT_deg(l)))-buff_deg; max(cellfun(@max,S.LON_deg(l)))+buff_deg, max(cellfun(@max,S.LAT_deg(l)))+buff_deg];
        [~, ~, inAirK] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,bbox);
        
        % Filter DOF obstacles and create S_obstacle
        [~, ~, inDofK] = filterboundingbox(Tdof.lat_deg,Tdof.lon_deg,bbox);
        S_obstacle = table(Tdof.lat_acc_deg(inDofK),Tdof.lon_acc_deg(inDofK),Tdof.alt_ft_msl(inDofK) - Tdof.alt_ft_agl(inDofK),Tdof.alt_ft_msl(inDofK),'VariableNames',{'LAT_deg','LON_deg','FLOOR_ft_msl','CEILING_ft_msl'});
        
        % Display status
        fprintf('%i trajectories, %i potential airspace classes when i=%i/%i, k=%i/%i\n',sum(l),sum(inAirK),i,numel(iso_3166_2),k,numel(uHeight));
        
        GenerateTracks(S(l,:),...
            [outDirBase filesep 'uswtdb_' obstacleWidthMode '_pointHorz' num2str(pointHorz_ft) '_pointVert' num2str(pointVert_ft) '_spacing' num2str(maxSpacing_ft)],...
            airspace(inAirK,:),...
            'trackMode','point-spiral',...
            'pointRadius_ft',S.pointRadius_ft(l),...
            'pointHeight_ft_agl',S.pointHeight_ft_agl(l),...
            'maxSpacing_ft',maxSpacing_ft,...
            'dem',dem,...
            'demDir',demDir,...
            'demBackup',demBackup,...
            'demDirBackup',demDirBackup,...
            'airspeed_kt',airspeed_kt,...
            'climbRate_fps',climbRate_fps,...
            'descendRate_fps',descendRate_fps,...
            'alt_ft_agl',uHeight(k),...
            'S_obstacle',S_obstacle,...
            'isCheckObstacle',true);
    end
end

%% Plot
% Create CONUS map
% f = figure(100);
% worldmap([24 50],[-125 -66]);
% ax = get(f,'CurrentAxes');
% setm(ax,'mapprojection','lambertstd');
% setm(ax,'fontsize',16,'fontweight','bold');
%
% % Plot states
% states = shaperead('usastatehi', 'UseGeoCoords', true);
% geoshow(states,'FaceColor',[0 0 0]);
%
% % Plot wind turbines
% S_all = shaperead(['data' filesep 'USGS-WindTurbineDB' filesep inFile '.shp'],'UseGeoCoords',true);
% l = [S.t_conf_loc] >= 3 & [S.t_ttlh] ~= -9999;
% geoshow(S_all(l),'DisplayType','point','MarkerSize',3,'Marker','*');

