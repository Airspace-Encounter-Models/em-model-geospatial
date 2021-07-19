function [S, S_raw, airspace, BoundingBox_wgs84] = LoadParseGSHHG(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); % Source

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core

% Optional - Minimum distance criteria for feature
addOptional(p,'minDist_ft',round(90*10*(unitsratio('ft','nm') / 3600),-1),@isnumeric); % % 90 seconds at 10 knots

% Optional - % GSHHG variables
addOptional(p,'lvl','1',@ischar); % Shoreline data are distributed in 6 levels
addOptional(p,'res','f',@ischar);% All data sets come in 5 different resolutions

% Parse
parse(p,iso_3166_2,varargin{:});
lvl = p.Results.lvl;
res = p.Results.res;

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
[S, S_raw] = LoadMapProjData([getenv('AEM_DIR_CORE') filesep 'data' filesep 'GSHHG' filesep 'GSHHS_shp' filesep res filesep  'GSHHS_' res '_L' lvl '.shp'],BoundingBox_wgs84);

% Filter to points within bounding box
[outLat_deg, outLon_deg, inBox] = filterboundingbox(S.LAT_deg,S.LON_deg,BoundingBox_wgs84);

%% Parse
if isempty(S_raw) | ~any(inBox)
    fprintf('No raw data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},'VariableNames',{'id','LAT_deg','LON_deg'});
else
    % Filter
    S = S(inBox,:); S.LAT_deg = outLat_deg; S.LON_deg = outLon_deg;

    % Make sure there is at least 2 points
    S = S(cellfun(@numel,S.LAT_deg) >= 2,:);
    
    % Calculate distance traveled for each vector
    dist_ft = cellfun(@(y,x)(sum(distance(y(1:end-1), x(1:end-1),y(2:end), x(2:end),wgs84Ellipsoid('ft')))),S.LAT_deg,S.LON_deg,'uni',true);
    
    % Assign distance to table
    S.dist_ft = dist_ft;
    
    % Remove features that don't meet minimum distance
    S(S.dist_ft < p.Results.minDist_ft,:) = [];
    
    % Sort by distance
    S = sortrows(S,'dist_ft','desc');
    
    % Redo id after filtering
    S.id = (1:1:size(S,1))';
    S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string
end
