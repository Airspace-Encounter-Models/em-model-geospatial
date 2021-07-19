function [S, S_raw, airspace, BoundingBox_wgs84] = LoadParsePatterns(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% SEE ALSO: RUN_1_OSM, CreatePatterns

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); % Location

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core

% Optional - OSM Types
addOptional(p,'landuseTypes',{'beach','cliff','farm','orchard','quarry','spring','vineyard','volcano'},@iscell); % Landuse types to use
addOptional(p,'poisTypes',{'golf_course'},@iscell); % POIS types to use

% Optional - Pattern parameters for CreatePatterns()
addOptional(p,'alt_ft_agl',400,@isnumeric);
addOptional(p,'bufwidth_deg',nm2deg(50 * unitsratio('nm','ft')),@isnumeric);
addOptional(p,'camTheta_deg',90,@isnumeric);
addOptional(p,'pattern','line',@ischar);

% Optional - Minimum distance criteria for feature
addOptional(p,'minDist_ft',round(90*10*(unitsratio('ft','nm') / 3600),-1),@isnumeric); % % 90 seconds at 10 knots

% Parse
parse(p,iso_3166_2,varargin{:});
alt_ft_agl = p.Results.alt_ft_agl;
bufwidth_deg = p.Results.bufwidth_deg;
camTheta_deg = p.Results.camTheta_deg;
pattern = p.Results.pattern;
minDist_ft = p.Results.minDist_ft;

%% Preallocate empty output
S = table(strings(0),{},{},[],strings(0),'VariableNames',{'id','LAT_deg','LON_deg','dist_ft','fclass'});

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
% Load and filterdata from step 1

% Landuse
if ~isempty(p.Results.landuseTypes)
    load([getenv('AEM_DIR_GEOSPATIAL') filesep 'output' filesep 'OSM_1_' iso_3166_2 '.mat'],'S_landuse');
    
    % Filter based on type
    l = contains(S_landuse.fclass,p.Results.landuseTypes);
    S_landuse(~l,:) = [];
    
    % Only keep columns we need
    l = contains(S_landuse.Properties.VariableNames,{'fclass','code','LAT_deg','LON_deg'});
    S_landuse = S_landuse(:,l);
end

% POIS
if ~isempty(p.Results.poisTypes)
    load([getenv('AEM_DIR_GEOSPATIAL') filesep 'output' filesep 'OSM_1_' iso_3166_2 '.mat'],'S_pois');
    
    % Filter based on type
    l = contains(S_pois.fclass,p.Results.poisTypes);
    S_pois(~l,:) = [];
    
    % Only keep columns we need
    l = contains(S_pois.Properties.VariableNames,{'fclass','code','LAT_deg','LON_deg'});
    S_pois = S_pois(:,l);
end

% Aggregate
S_raw = [S_landuse; S_pois]; clear S_landuse S_pois;

%% Parse
if isempty(S_raw)
    fprintf('No raw data for %s', iso_3166_2);
else
    % Find unique types
    [uCode, ~, ic] = unique(S_raw.code,'stable');
    
    % Iterate over unique types
    for i=1:1:size(uCode,1)
        % Create logical filter
        li = (ic == i);
        
        % Create patterns
        [si,pgonunion] = CreatePatterns(S_raw.LAT_deg(li),S_raw.LON_deg(li),pattern,...
            'BoundingBox_wgs84',BoundingBox_wgs84,'minDist_ft',minDist_ft,'bufwidth_deg',bufwidth_deg,...
            'alt_ft_agl',alt_ft_agl,'camTheta_deg',camTheta_deg,'isPlot',false);
        
        % Do somethign if not empty
        if ~isempty(si)
            % Record type
            fclass = S_raw.fclass(find(li==true,1,'first'));
            si.fclass = repmat(fclass,size(si,1),1);
            
            % Concat
            S = [S; si];
        end
    end
    
    % Redo id
    S.id = (1:1:size(S,1))';
    S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string
end
