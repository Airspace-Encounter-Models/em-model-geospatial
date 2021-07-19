function [el_ft_msl, barometicAlt_ft, altRate_fps] = CorrectAltAGL(lat_deg,lon_deg,time_s,altCruise_ft_agl,climbRate_fps,descendRate_fps,alt_tol_ft,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input Parser
p = inputParser;

% Required
addRequired(p,'lat_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'lon_deg',@(x) isnumeric(x) | iscell(x));
addRequired(p,'time_s',@(x) isnumeric(x) | iscell(x));
addRequired(p,'altCruise_ft_agl',@isnumeric); % Cruise altitude ft
addRequired(p,'climbRate_fps',@isnumeric); % climb rate
addRequired(p,'descendRate_fps',@isnumeric); % descend rate
addRequired(p,'alt_tol_ft',@isnumeric); % Altitude tolerance for terrain following

% DEM / Elevation related
addOptional(p,'Z_m',@isnumeric);
addOptional(p,'refvec',@isnumeric);
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM1'],@isstr); % Directory containing DEM
addOptional(p,'dem','srtm1',@isstr); % Digital elevation model name

% Parse
parse(p,lat_deg,lon_deg,time_s,altCruise_ft_agl,climbRate_fps,descendRate_fps,alt_tol_ft,varargin{:});

%% Get elevation along track
if any(strcmpi(p.UsingDefaults,'Z_m'))
    [el_ft_msl,~] = msl2agl(lat_deg, lon_deg, p.Results.dem);
else
    [el_ft_msl,~] = msl2agl(lat_deg, lon_deg, p.Results.dem,'Z_m',p.Results.Z_m,'refvec',p.Results.refvec,'demDir',p.Results.demDir);
end
% Round elevation
el_ft_msl = round(el_ft_msl);

%% Preallocate
barometicAlt_ft = zeros(size(el_ft_msl));
altRate_fps = zeros(size(el_ft_msl));

% Set first element of MSL altitude
barometicAlt_ft(1) = el_ft_msl(1) +altCruise_ft_agl;
refAlt_ft = barometicAlt_ft(1);

%% Iterate over each point
for i=2:1:numel(el_ft_msl)
    % Calculate the current AGL w.r.t to refAlt_ft
    curAGL_ft = refAlt_ft - el_ft_msl(i);
    
    % Calculate difference from target altitude
    alt_diff_ft = altCruise_ft_agl - curAGL_ft;
    
    % If the difference is greater than tolerance, do something
    if abs(alt_diff_ft) > alt_tol_ft
        % Correct back to cruiseAlt_ft_agl
        barometicAlt_ft(i) = el_ft_msl(i) +altCruise_ft_agl;
        
        % Calculate timestep
        timestep_s = time_s(i) - time_s(i-1);
        
        % Calculate a vertical rate the previous timestep
        vrate = alt_diff_ft / timestep_s;
        
        % Determine if vertical rate is within limits
        % Correct vertical rate to maximum
        % Change altitude
        if vrate > 0 && vrate > climbRate_fps
            vrate = climbRate_fps;
            barometicAlt_ft(i) = barometicAlt_ft(i-1) + vrate;
        elseif vrate < 0 && vrate < descendRate_fps
            vrate = descendRate_fps;
            barometicAlt_ft(i) = barometicAlt_ft(i-1) + vrate;
        end
        
        % Assign
        altRate_fps(i-1) = vrate; % Vertical rate starts at previous waypoint
        altRate_fps(i) = 0; % I know its already zero, but piece of mind
        
        % Reset refAlt_ft
        refAlt_ft = barometicAlt_ft(i);
    else
        % No need to change MSL altitude, remain at currrent reference
        barometicAlt_ft(i) = refAlt_ft;
    end
end

% Debugging plotting code
% plot(barometicAlt_ft-el_ft_msl) % plots agl ft
% plot(1:numel(barometicAlt_ft), barometicAlt_ft,1:numel(el_ft_msl),el_ft_msl) % plots msl