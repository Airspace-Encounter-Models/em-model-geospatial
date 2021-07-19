function [traj, el_ft_msl, isCFIT,isViolate,idxViolate] = CalcTrack(lat_deg,lon_deg,altTarget_ft_agl,airspeed_kt,climbRate_fps,descendRate_fps,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% SEE ALSO: GENERATETRACKS

%% Input parser
p = inputParser;

% Required
addRequired(p,'lat_deg',@isnumeric); % Latitude
addRequired(p,'lon_deg',@isnumeric); % Longitude
addRequired(p,'altTarget_ft_agl',@isnumeric); % Target altitude ft agl
addRequired(p,'airspeed_kt',@isnumeric); % cruise airspeed
addRequired(p,'climbRate_fps',@isnumeric); % climb rate
addRequired(p,'descendRate_fps',@isnumeric); % descend rate

% Altitude mode
addOptional(p,'altMode','terrainfollow',@(x) ischar(x) && any(strcmpi(x,{'terrainfollow','mslhold','ring','spiral'})));
addOptional(p,'alt_tol_ft',25,@isnumeric); % Altitude tolerance for terrain following

% DEM related
addOptional(p,'Z_m',@isnumeric);
addOptional(p,'refvec',@isnumeric);
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'],@isstr); % Directory containing DEM
addOptional(p,'dem','globe',@isstr); % Digital elevation model name
addOptional(p,'ocean',struct,@isstruct);

% Point Inspection (ring and spiral)
addOptional(p,'pointRadius_ft',250,@isnumeric); % Lateral distance away from point being inspected
addOptional(p,'vertLeg_ft',25,@isnumeric); % Vertical distance traveled once around spiral / ring
addOptional(p,'pointPts',25,@isnumeric); % Number of points when using spiral / ring

% Spacing and Interpolation
addOptional(p,'maxSpacing_ft',2000,@isnumeric); % Maximum allowable spacing between sequential coordinates, default is 2000 feet
%addOptional(p,'interpSpacing_ft',25,@isnumeric); % Thinking about another value to use when interpolating

% Obstacles
addOptional(p,'S_obstacle',[]);

% Parse
parse(p,lat_deg,lon_deg,altTarget_ft_agl,airspeed_kt,climbRate_fps,descendRate_fps,varargin{:});

%% Create spiral or ring if appropriate
if contains(p.Results.altMode,{'ring','spiral'})
    % Generate circle waypoints around input coordinate
    [latc_deg,lonc_deg] = scircle1(lat_deg,lon_deg,p.Results.pointRadius_ft,[],wgs84Ellipsoid('ft'),'degrees',p.Results.pointPts);
    
    % Calculate elevation (ft MSL) of coordinate and waypoints
    % We concat the coordinate and circle so we only call msl2agl() once
    [el_ft_msl,~,~,~] = msl2agl([lat_deg;latc_deg],[lon_deg;lonc_deg], p.Results.dem,'Z_m',p.Results.Z_m,'refvec',p.Results.refvec,'isFillAverage',true,'isCheckOcean',true,'ocean',p.Results.ocean);
    
    % Round elevation
    el_ft_msl = round(el_ft_msl);
    
    if any(isnan(el_ft_msl))
        warning('CalcTracks:alt_ft_msl','el_ft_msl or alt_ft_msl has NaN elements, using last ditcth NOAA GLOBE DEM\n');
        [el_ft_msl,~,~,~] = msl2agl([lat_deg;latc_deg],[lon_deg;lonc_deg], 'globe','isFillAverage',true,'isCheckOcean',true,'ocean',p.Results.ocean);
    end
    
    % Calculate height in msl ft
    pointHeight_ft_msl = floor(altTarget_ft_agl + el_ft_msl(1));
    
    % Overwrite with input with circle around
    lat_deg = latc_deg;
    lon_deg = lonc_deg;
    el_ft_msl(1) = []; % Remove first elevation because that is of the input coordinates
    
    % Find highest elevation
    [~,I] = max(el_ft_msl);
    
    % Reorder waypoints so that highest elevation is first
    % We do this to minimize CFIT risk when climbing or descending
    lat_deg = [lat_deg(I:end); lat_deg(1:I-1)];
    lon_deg = [lon_deg(I:end); lon_deg(1:I-1)];
    el_ft_msl = [el_ft_msl(I:end); el_ft_msl(1:I-1)];
    
    % Vertical distance required to travel
    vertDist_ft = pointHeight_ft_msl - el_ft_msl(1);
    
    % Number of spirals to complete
    nSpirals = ceil(vertDist_ft / p.Results.vertLeg_ft);
    
    % Replicate coordinates for each spiral
    lat_deg = repmat(lat_deg,nSpirals,1);
    lon_deg = repmat(lon_deg,nSpirals,1);
    el_ft_msl = repmat(el_ft_msl,nSpirals,1);
end

%% Interpolate if needed
% Calculate distance between coordinates
d_ft = distance(lat_deg(1:end-1),lon_deg(1:end-1),lat_deg(2:end),lon_deg(2:end),wgs84Ellipsoid('ft'));
isCloseEnough = (d_ft <= p.Results.maxSpacing_ft);

% Do something if needed
if ~all(isCloseEnough)
    % Preallocate
    lat_interp_deg = [];
    lon_interp_deg = [];
    
    c = 1; % Counter
    for i=1:1:numel(lat_deg)-1
        if isCloseEnough(i)
            lat_interp_deg(c) = lat_deg(i);
            lon_interp_deg(c) = lon_deg(i);
            c = c + 1;
        else
            % Calculate new segement
            [lat_seg_deg,lon_seg_deg] = interp2fixed(lat_deg(i:i+1),lon_deg(i:i+1),p.Results.maxSpacing_ft*unitsratio('nm','ft'),'linear');
            
            len = numel(lat_seg_deg{1});
            lat_interp_deg(c:c+len-1) = lat_seg_deg{1};
            lon_interp_deg(c:c+len-1) = lon_seg_deg{1};
            c = c + len;
        end
    end
    
    % Handle edge case at end of trajectory
    if lat_interp_deg(end) ~= lat_deg(end)
        lat_interp_deg(end+1) = lat_deg(end);
        lon_interp_deg(end+1) = lon_deg(end);
    end
    
    % Overwrite input and continue
    lat_deg = lat_interp_deg; lon_deg = lon_interp_deg;
    
    % Debugging
    %     figure(100);
    %     worldmap([min(lat_deg), max(lat_deg)],[min(lon_deg), max(lon_deg)]);
    %     ax = get(gcf,'CurrentAxes');
    %     setm(ax,'mapprojection','lambertstd');
    %     geoshow(lat_deg,lon_deg,'Marker','s','MarkerSize',6,'Color','b')
    %     geoshow(lat_interp_deg,lon_interp_deg,'Marker','s','MarkerSize',3,'Color','r','LineStyle','-')
end

%% Make sure coordinates are column vectors
if ~iscolumn(lat_deg); lat_deg = lat_deg'; end
if ~iscolumn(lon_deg); lon_deg = lon_deg'; end

%% No lat / lon repeats when following track
if contains(p.Results.altMode,{'terrainfollow','mslhold'});
    A = unique([lat_deg, lon_deg],'rows','stable');
    lat_deg = A(:,1); lon_deg = A(:,2);
end

%% Calculate lat / lon and time_s
% returns the azimuths (course) and distances (dist) between navigational waypoints, which are specified by the column vectors lat and lon.
[course,dist] = legs(lat_deg,lon_deg,'rh');

% Calculate time for each leg
t_legs_hr = dist / airspeed_kt;
t_legs_s = t_legs_hr * 3600;
time_s = cumsum(t_legs_s);

%% Corrrect altitude and vertical rate
% Terrain following to maintain a constant AGL but output will still be MSL
% MSL just sets a constant

switch p.Results.altMode
    case 'terrainfollow'
        [el_ft_msl, alt_ft_msl, altRate_fps] = CorrectAltAGL(lat_deg,lon_deg,[0; time_s],altTarget_ft_agl,climbRate_fps,descendRate_fps,p.Results.alt_tol_ft,'Z_m',p.Results.Z_m,'refvec',p.Results.refvec,'dem',p.Results.dem,'demDir',p.Results.demDir);
        
        % Make sure that terrain and altitude have all NaN points, try to
        % correct using NOAA GLOBE if needed
        l=isnan(el_ft_msl) | isnan(alt_ft_msl);
        if any(l)
            warning('CalcTracks:alt_ft_msl','el_ft_msl or alt_ft_msl has %i NaN elements, filling in gaps with NOAA GLOBE DEM\n',sum(l));
            
            tt = [0; time_s];
            [el_ft_msl(l), alt_ft_msl(l), altRate_fps(l)] = CorrectAltAGL(lat_deg(l),lon_deg(l),tt(l),altTarget_ft_agl,climbRate_fps,descendRate_fps,p.Results.alt_tol_ft,'dem','globe');
            
            if any(isnan(alt_ft_msl))
                error('CalcTracks:el_ft_msl','Filling in gaps with NOAA GLOBE failed\n');
            end
        end
    case 'mslhold'
        [el_ft_msl,~] = msl2agl(lat_deg,lon_deg, p.Results.dem,'Z_m',p.Results.Z_m,'refvec',p.Results.refvec,'isCheckOcean',true,'ocean',p.Results.ocean); % Just get elevation along trajectory
        alt_ft_msl = repmat(altTarget_ft_agl,size(lat_deg)); % Set barometric altitude to input
        altRate_fps = zeros(size(lat_deg)); % Don't command vertical rate during flight
    case 'ring'
        altRate_fps = zeros(size(lat_deg,1),1);
        
        % Time required for each climb
        climbTime_s = p.Results.vertLeg_ft / climbRate_fps;
        
        % Find first index of spiral for each altitude ring
        idxClimb = find(lat_deg == lat_deg(1) & lon_deg == lon_deg(1),nSpirals,'first');
        
        % Climb at first index for each spiral
        %altRate_fps(idxClimb) = climbRate_fps;
        
        % Add coordinates for climbing
        for i=1:1:nSpirals-1
            sidx = idxClimb(i); % Start index
            eidx = idxClimb(i+1); % End index
            
            % Add additional coordinate for climbing
            time_s = [time_s(1:eidx); time_s(eidx)+climbTime_s; time_s(eidx:end)+climbTime_s+climbTime_s];
            el_ft_msl = [el_ft_msl(1:eidx); el_ft_msl(eidx); el_ft_msl(eidx:end)];
            course = [course(1:eidx); course(eidx); course(eidx:end)];
            lat_deg = [lat_deg(1:eidx); lat_deg(eidx); lat_deg(eidx:end)];
            lon_deg = [lon_deg(1:eidx); lon_deg(eidx); lon_deg(eidx:end)];
            altRate_fps = [altRate_fps(1:eidx); 0; altRate_fps(eidx:end)];
            
            % Climb index is immedaitely after the end index of the spiral
            % Issue vertical rate at climb index
            altRate_fps(eidx) = climbRate_fps;
            
            % We've added a coordinate, so advance all climb indices by
            % one, add another one to start / end at same point in spiral
            idxClimb(i+1:end) = idxClimb(i+1:end) + 1 + 1;
        end
        
        % Calculate altitude now that all coordinates are set
        alt_ft_msl = zeros(size(lat_deg,1),1);
        for i=1:1:nSpirals-1
            sidx = idxClimb(i); % Start index
            eidx = idxClimb(i+1)-1; % End index
            alt_ft_msl(sidx:eidx) = el_ft_msl(1) + (i*p.Results.vertLeg_ft);
        end
        alt_ft_msl(eidx+1:end) = el_ft_msl(1) + (nSpirals*p.Results.vertLeg_ft);
        
    case 'spiral'
        altRate_fps = zeros(size(lat_deg,1),1);
        altRate_fps(1) = (nSpirals * p.Results.vertLeg_ft) / max(time_s);
        
        alt_ft_msl = [el_ft_msl(1); el_ft_msl(1) + altRate_fps(1) * time_s];
end

% Notify if maximum vertical rate used
% Nothing is adjusted but since we assume instantaneous vertical rate change,
% it could be good to notify the user
%if any(altRate_fps >= climbRate_fps | altRate_fps <= descendRate_fps)
    % warning('CalcTracks:altRate_fps','altRate_fps == climbRate_fps or descendRate_fps\n');
    %fprintf('altRate_fps == climbRate_fps or descendRate_fps\n');
% end

%% Create local...Duplicate start and end to account for take-off and landing
% Calculate the number of total legs
nlegs = numel(lat_deg);

% Position
if isrow(el_ft_msl)
    el_ft_msl = [el_ft_msl(1); el_ft_msl'; el_ft_msl(end)];
    alt_ft_msl = [el_ft_msl(1); alt_ft_msl'; el_ft_msl(end)];
    heading_deg = [course(1); course(1); course; course(end)];
    lat_out_deg = [lat_deg(1); lat_deg'; lat_deg(end)];
    lon_out_deg = [lon_deg(1); lon_deg'; lon_deg(end)];
else
    el_ft_msl = [el_ft_msl(1); el_ft_msl; el_ft_msl(end)];
    alt_ft_msl = [el_ft_msl(1); alt_ft_msl; el_ft_msl(end)];
    heading_deg = [course(1); course(1); course; course(end)];
    lat_out_deg = [lat_deg(1); lat_deg; lat_deg(end)];
    lon_out_deg = [lon_deg(1); lon_deg; lon_deg(end)];
end

% Vertical rate
if ~iscolumn(altRate_fps); altRate_fps = altRate_fps'; end
altRate_fps = [climbRate_fps; altRate_fps(1:end-1);descendRate_fps; 0];

% Ground Speed
groundspeed_kt = [0; repmat(airspeed_kt,nlegs,1); 0];

% Set ground speed to zero when climbing during a ring
if contains(p.Results.altMode,{'ring'})
    groundspeed_kt(altRate_fps~=0) = 0;
end

%% Write to output table
% Preallocate table output
traj = array2table(zeros(nlegs+2,9),'VariableNames',{'time_s','heading_deg','groundspeed_kt','el_ft_msl','alt_ft_msl','alt_ft_agl','altRate_fps','lat_deg','lon_deg'});

% Position and heading
traj.heading_deg = heading_deg;
traj.el_ft_msl = el_ft_msl;
traj.alt_ft_msl = alt_ft_msl;
traj.alt_ft_agl = alt_ft_msl - el_ft_msl;
traj.lat_deg = lat_out_deg;
traj.lon_deg = lon_out_deg;

% Velocities and rates
traj.altRate_fps = altRate_fps;
traj.groundspeed_kt = groundspeed_kt;

% Time
traj.time_s(2) = (alt_ft_msl(2)-el_ft_msl(2)) / abs(climbRate_fps);
traj.time_s(3:end-1) = (traj.time_s(2) + time_s);
traj.time_s(end) = traj.time_s(end-1) + ((alt_ft_msl(end-1)-el_ft_msl(end)) / abs(descendRate_fps));

%% Remove duplicate time_s = 0
% The inital vertical rate and position will vary based on altMode, this
% can be handled better when creating local...Duplicate start and end to account for take-off and landing
sidx = find(traj.time_s == 0, 1,'last');
traj = traj(sidx:end,:);

%% Check if controlled flight in terrain (CFIT)
isCFIT = traj.alt_ft_agl < 0;
if any(isCFIT); warning('CalcTracks:isCFIT','isCFIT=true\n'); end

%% Obstacles
% Preallocate
isViolate = false(size(isCFIT));
idxViolate = cell(size(traj,1),1);

% Only do something if there are obstacles
if ~isempty(p.Results.S_obstacle)
    % Identify for each obstacle, which trajectory points are within the grid
    xv = p.Results.S_obstacle.LON_deg;
    yv = p.Results.S_obstacle.LAT_deg;
    
    % Determine if trajectory even flies over any obstacles
    % Assumes that trajectory points are no greater than 1 minute apart (~6068 ft, 1.15 miles).
    % If trajectory points are far apart then InPolygon() may skip over LAANC grids
    % https://www.usgs.gov/faqs/how-much-distance-does-a-degree-minute-and-second-cover-your-maps
    isObs = cellfun(@(xv,yv)(InPolygon(traj.lon_deg,traj.lat_deg,xv,yv)),xv,yv,'uni',false);
    isObs = cell2mat(isObs'); % Rows are trajectories, columns are obstacles
    isViolate2D = any(isObs,2);
    
    % Iterate over trajectory
    for i=1:1:numel(isViolate2D)
        % Only do something if trajectory flies over obstacle
        if isViolate2D(i)
            % Find all obstacle row indicies that trajectory flies over
            idx = find(isObs(i,:) == true);
            % Filter obstacles table
            s_obs = p.Results.S_obstacle(idx,:);
            
            % Iterate over obstacles
            for j=1:1:size(s_obs,1)
                % Check if trajectory is below permitted floor or above ceiling
                isViolateFloor = traj.alt_ft_msl(i) < s_obs.FLOOR_ft_msl(j);
                isViolateCeil = traj.alt_ft_msl(i) > s_obs.CEILING_ft_msl(j);
                
                % Determine if any violation occured
                isV = any(isViolateFloor|isViolateCeil);
                
                % If violation occured, record row index of obstacle
                if isV;idxViolate{i} = [idx(j); idxViolate{i}]; end
                
                % Set output flag only if it hasn't been set yet and that the
                % jth obstacle has isV = true. It is possible that there are
                % multiple elements to idxViolate but we want isViolate so
                % summarize all obstacles
                if ~isViolate(i) && isV; isViolate(i) = isV; end
            end % End j for loop
        end
    end % End i for loop
end

