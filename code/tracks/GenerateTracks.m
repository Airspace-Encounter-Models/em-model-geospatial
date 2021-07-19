function GenerateTracks(S,outDirBase,airspace,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% SEE ALSO: CalcTrack

%% tic
tic

%% Input parser
p = inputParser;

% Required
addRequired(p,'S'); % Source
addRequired(p,'outDirBase',@isstr); % Output directory
addRequired(p,'airspace'); % Airspace table

% Elevation related
addOptional(p,'alt_tol_ft',25,@isnumeric); % Altitude tolerance for terrain following
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM1'],@isstr); % Directory containing DEM
addOptional(p,'dem','srtm1',@isstr); % Digital elevation model name
addOptional(p,'demDirBackup',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'],@isstr); % Directory containing DEM
addOptional(p,'demBackup','globe',@isstr); % Digital elevation model name
addOptional(p,'inFileOcean',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Ocean' filesep 'ne_10m_ocean'],@ischar);

% UAS related
addOptional(p,'alt_ft_agl',400,@isnumeric); % Cruise altitude ft AGL
addOptional(p,'airspeed_kt',60,@isnumeric); % cruise airspeed
addOptional(p,'climbRate_fps',1000/60,@isnumeric); % climb rate
addOptional(p,'descendRate_fps',-1000/60,@isnumeric); % descent rate
addOptional(p,'maxSpacing_ft',2000,@isnumeric); % Maximum allowable spacing between sequential coordinates (used in CalcTrack)

% Track mode
addOptional(p,'trackMode','holdalt',@(x) ischar(x) && any(strcmpi(x,{'holdalt','point-ring','point-spiral'})));

% Obstacle related
addOptional(p,'S_obstacle',table(),@istable); % Obstacles, such as UAS facility maps
addOptional(p,'isCheckObstacle',false,@islogical); % If true, check if track collides with an obstacle

% Point obstacle inspection (ring and spiral) 
addOptional(p,'pointRadius_ft',250,@isnumeric); % Lateral distance away from point being inspected
addOptional(p,'pointHeight_ft_agl',50,@isnumeric); % Vertical distance traveled once around spiral / ring
addOptional(p,'pointPts',100,@isnumeric); % Number of points when using spiral / ring
addOptional(p,'vertLeg_ft',25,@isnumeric); % Vertical distance traveled once around spiral

% Load balancing
% Target maximum of items per director, LLSC team recommends <= 1000
addOptional(p,'filesPerDir', 1000, @isnumeric);

% Parse
parse(p,S,outDirBase,airspace,varargin{:});

%% Create output directory if it doesn't exist
if exist(outDirBase) ~=7
    mkdir(outDirBase);
end

%% Parse required inputs
% Geospatial features
id = S.id;
LAT_deg = S.LAT_deg;
LON_deg = S.LON_deg;

% Filter airspace based on altitude ceiling
isAir = cellfun(@min,airspace.LOWALT_ft_agl) <= max(p.Results.alt_ft_agl);

% Airspace
airB = airspace(airspace.CLASS == 'B' & isAir,:);
airC = airspace(airspace.CLASS == 'C' & isAir,:);
airD = airspace(airspace.CLASS == 'D' & isAir,:);
airE = airspace(airspace.CLASS == 'E' & isAir,:);
airF = airspace(airspace.CLASS == 'F' & isAir,:);

% Load ocean polygon for msl2agl()
ocean = shaperead(p.Results.inFileOcean,'UseGeoCoords',true);

%% Calculate combinations
%fprintf('Number of trajectories to generate: %i\n',size(S,1));

% UAS parameters
uasidx = combvec(1:numel(p.Results.alt_ft_agl),1:numel(p.Results.airspeed_kt),1:numel(p.Results.climbRate_fps),1:numel(p.Results.descendRate_fps))';
%fprintf('UAS Combinations: %i\n',size(uasidx,1));

%% Generate tracks
for i=1:1:size(uasidx,1)
    % Directory overhead
    g = 1; % group directory
    gc = 0; % counter for directory
    
    % Parse current UAS parameters
    alt_ft = p.Results.alt_ft_agl(uasidx(i,1));
    speed_kt = p.Results.airspeed_kt(uasidx(i,2));
    climb_fps = p.Results.climbRate_fps(uasidx(i,3));
    descend_fps = p.Results.descendRate_fps(uasidx(i,4));
    
    % Number of subdirectories for load balance
    gn = ceil(size(S,1) / p.Results.filesPerDir);
    
    % Assign subdirectory for each src / dest combinations
    g = repmat([1:gn]',ceil(size(S,1) / gn),1);
    g = string(sort(g));
    
    % Create output directory if it doesn't exist
    outDir = [outDirBase filesep sprintf('%0.2f_%0.2f_%0.2f_%0.2f',alt_ft,speed_kt,climb_fps,descend_fps)];
    if exist(outDir) ~=7
        mkdir(outDir);
    end
    
    % Create output subdirectories if they doesn't exist
    for j=unique(g)'
        if exist([outDir filesep char(j)]) ~=7
            mkdir([outDir filesep char(j)]);
        end
    end
    
    % Iterate over src / dest combinations
    parfor j=1:1:size(S,1)
        traj = table;
        isCFIT = false;
        isViolate = false;
        
        % Bounding Box, [lonmin,latmin;lonmax,latmax]
        lonmin = min(LON_deg{j});
        lonmax = max(LON_deg{j});
        latmin = min(LAT_deg{j});
        latmax = max(LAT_deg{j});
        
        % Scale buffer for bounding box based on point radius, if using
        % Assuming msl2agl() deafult buff_deg = 0.1
        switch p.Results.trackMode
            case 'point-spiral'
                buff_deg = 2*round(nm2deg(p.Results.pointRadius_ft(j)*unitsratio('nm','ft')),6);
                if buff_deg < 0.1
                    buff_deg = 0.1;
                end
            otherwise
                buff_deg = 0.1;
        end
        
        % Load DEM
        dem = p.Results.dem;
        demDir = p.Results.demDir;
        [~,~,Z_m,refvec] = msl2agl([latmin,latmax], [lonmin,lonmax],...
            dem,'demDir',demDir,'buff_deg',buff_deg,...
            'ocean',ocean,'isCheckOcean',true);
        
        % If DEM is empty, overwrite and try backup
        if isempty(Z_m)
            warning('z_m:empty','Z_m is empty when i=%i, j=%i\nTrying %s instead\n',i,j,p.Results.demBackup);
            dem = p.Results.demBackup;
            demDir = p.Results.demDirBackup;
            [~,~,Z_m,refvec] = msl2agl({latmin,latmax}, {lonmin,lonmax}, dem,'demDir',demDir,'ocean',ocean,'isCheckOcean',true);
        end
        if isempty(Z_m)
            warning('z_m:empty','Z_m is still empty when i=%i, j=%i\nSkipping trajectory via CONTINUE\n',i,j);
            continue
        end
        if any(isnan(Z_m(:)))
            warning('z_m:nan','Z_m has NaN elements when i=%i, j=%i',i,j);
        end
        
        % Calculate trajectory without any avoidance or rerouting
        l = ~isnan(LAT_deg{j}); % Sometimes NaN is the last element, sometimes its not
        
        switch p.Results.trackMode
            case 'holdalt'
                [traj, ~, isCFIT,isViolate,~] = CalcTrack(LAT_deg{j}(l),...
                    LON_deg{j}(l),...
                    alt_ft,...
                    speed_kt,...
                    climb_fps,...
                    descend_fps,...
                    'altMode','terrainfollow',...
                    'maxSpacing_ft',p.Results.maxSpacing_ft,...
                    'alt_tol_ft',p.Results.alt_tol_ft,...
                    'Z_m',Z_m,...
                    'refvec',refvec,...
                    'S_obstacle',p.Results.S_obstacle,...
                    'dem',dem,...
                    'demDir',demDir,...
                    'ocean',ocean);
            case 'point-ring'
                [traj, ~, isCFIT,isViolate,~] = CalcTrack(LAT_deg{j}(l),...
                    LON_deg{j}(l),...
                    alt_ft,...
                    speed_kt,...
                    climb_fps,...
                    descend_fps,...
                    'altMode', 'ring',...
                    'pointRadius_ft',p.Results.pointRadius_ft(j),...
                    'vertLeg_ft',p.Results.vertLeg_ft,...
                    'pointPts',p.Results.pointPts,...
                    'maxSpacing_ft',p.Results.maxSpacing_ft,...
                    'Z_m',Z_m,...
                    'refvec',refvec,...
                    'S_obstacle',p.Results.S_obstacle,...
                    'dem',dem,...
                    'demDir',demDir,...
                    'ocean',ocean);
            case 'point-spiral'
                [traj, ~, isCFIT,isViolate,~] = CalcTrack(LAT_deg{j}(l),...
                    LON_deg{j}(l),...
                    alt_ft,...
                    speed_kt,...
                    climb_fps,...
                    descend_fps,...
                    'altMode', 'spiral',...
                    'pointRadius_ft',p.Results.pointRadius_ft(j),...
                    'vertLeg_ft',p.Results.vertLeg_ft,...
                    'pointPts',p.Results.pointPts,...
                    'maxSpacing_ft',p.Results.maxSpacing_ft,...
                    'Z_m',Z_m,...
                    'refvec',refvec,...
                    'S_obstacle',p.Results.S_obstacle,...
                    'dem',dem,...
                    'demDir',demDir,...
                    'ocean',ocean);
        end
        
        % Check if obstacles are violated
        if p.Results.isCheckObstacle
            isObstacle = false; % Reset logicals
            isObstacle = any(isViolate);
        else
            isObstacle = false;
        end
        if isObstacle
            fprintf('id=%s, i=%i, j=%i VIOLATION OBSTACLE\n',id{j},i,j);
        end
        
        % Identify airspace class and Write to file
        if (~any(isCFIT) && ~isObstacle)
            % Identify airspace class
            % This is slow
            [isF,namesF] = identifyairspace(airF, traj.lat_deg, traj.lon_deg, traj.alt_ft_msl,'msl');
            [isE,namesE] = identifyairspace(airE, traj.lat_deg, traj.lon_deg, traj.alt_ft_msl,'msl');
            [isD,namesD] = identifyairspace(airD, traj.lat_deg, traj.lon_deg, traj.alt_ft_msl,'msl');
            [isC,namesC] = identifyairspace(airC, traj.lat_deg, traj.lon_deg, traj.alt_ft_msl,'msl');
            [isB,namesB] = identifyairspace(airB, traj.lat_deg, traj.lon_deg, traj.alt_ft_msl,'msl');
            
            % Default is other which can either be A or G
            traj.AirspaceClass = repmat('O',size(traj,1),1);
            traj.AirspaceClass(isB) = 'B';
            traj.AirspaceClass(isC) = 'C';
            traj.AirspaceClass(isD) = 'D';
            traj.AirspaceClass(isE) = 'E';
            
            traj.AirspaceName = strings(size(traj,1),1);
            traj.AirspaceName(isB) = namesB(isB);
            traj.AirspaceName(isC) = namesC(isC);
            traj.AirspaceName(isD) = namesD(isD);
            traj.AirspaceName(isE) = namesE(isE);
            
            % Create outfile name
            outFile = sprintf('GEOSPATIAL_id%s_lonmin%0.3f_lonmax%0.3f_latmin%0.3f_latmax%0.3f_class%s_%0.2f_%0.2f_%0.2f_%0.2f',id{j},min(traj.lon_deg),max(traj.lon_deg),min(traj.lat_deg),max(traj.lat_deg),strcat(unique(traj.AirspaceClass))',alt_ft,speed_kt,climb_fps,descend_fps);
            
            % Open file
            fileId = fopen([outDir filesep g{j} filesep outFile '.csv'],'w+','native','UTF-8');
            
            % Write header
            colNames = traj.Properties.VariableNames;
            fprintf(fileId,[repmat('%s,',1,numel(colNames)-1) '%s\n'],colNames{:});
            
            % Write variables
            % We need to convert to cell because traj.Variable will not
            % output with the full precision, which results in the lat /
            % lon coordinates getting rounded, which is bad
            tc = table2cell(traj)';
            fprintf(fileId,[repmat('%0.3f,',1,7) '%0.16f,%0.16f,' '%s,%s' '\n'],tc{:,:});
            
            % Close file
            fclose(fileId);
        else
            fprintf('Track not generated when i=%i, j=%i\n',i,j);
        end % isGood_traj
    end
    % Display status to screen
    %fprintf('%i / %i, %.0f seconds elapsed\n',i,size(uasidx,1), toc);
end
