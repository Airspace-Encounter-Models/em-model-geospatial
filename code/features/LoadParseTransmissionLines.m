function [S, S_raw, airspace, BoundingBox_wgs84] = LoadParseTransmissionLines(iso_3166_2, varargin)
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

% Parse
parse(p,iso_3166_2,varargin{:});

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
[~, S_raw] = LoadMapProjData([getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'HIFLD-ElectricPowerTransmissionLines' filesep 'Electric_Power_Transmission_Lines.shp'],BoundingBox_wgs84);

% Filters
% in service, verified, and avaiable
l = strcmpi(S_raw.STATUS,'IN SERVICE') & ~strcmpi(S_raw.VAL_METHOD,'UNVERIFIED') & ~strcmpi(S_raw.VOLT_CLASS,'NOT AVAILABLE');

%% Parse
if isempty(S_raw) | ~any(l)
    fprintf('No raw data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},strings(0),'VariableNames',{'id','LAT_deg','LON_deg','type','volt_class'});
else
    
    % Create new streamlined table
    S = table(string(S_raw.ID(l)), S_raw.LAT_deg(l), S_raw.LON_deg(l),S_raw.TYPE(l),S_raw.VOLT_CLASS(l),'VariableNames',{'id','LAT_deg','LON_deg','type','volt_class'});
    
    
    % Filter to points within bounding box
    [outLat_deg, outLon_deg, inBox] = filterboundingbox(S.LAT_deg,S.LON_deg,BoundingBox_wgs84);
    S = S(inBox,:); S.LAT_deg = outLat_deg; S.LON_deg = outLon_deg;
    
    % Make sure there is at least 2 points
    S = S(cellfun(@numel,S.LAT_deg) >= 2,:);
    
    % Calculate distance traveled for each vector
    dist_ft = cellfun(@(y,x)(sum(distance(y(1:end-1), x(1:end-1),y(2:end), x(2:end),wgs84Ellipsoid('ft')))),S.LAT_deg,S.LON_deg,'uni',true);
    
    % Assign distance to table
    S.dist_ft = dist_ft;
    
    % Remove features that don't meet minimum distance
    S(S.dist_ft < p.Results.minDist_ft,:) = [];
    
    % Replace volt class with numeric range for consistency
    S.volt_class = strrep(lower(S.volt_class),lower('UNDER 100'),'0-99');
    S.volt_class = strrep(lower(S.volt_class),lower('735 and above'),'735-765');
end
