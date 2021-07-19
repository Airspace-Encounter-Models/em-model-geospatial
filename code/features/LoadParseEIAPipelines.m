function [S, airspace, BoundingBox_wgs84] = LoadParseEIAPipelines(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); % Source

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core
addOptional(p,'fileCrude',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'EIA-CrudeOilPipelines' filesep 'CrudeOil_Pipelines_US_201802.shp']); % Crude oil
addOptional(p,'fileHGL',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'EIA-HydrocarbonGasLiquidPipelines' filesep 'HGL_Pipelines_US_201804_v2.shp']); % HGL
addOptional(p,'fileNG',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'EIA-NaturalGasPipelines' filesep 'NaturalGas_Pipelines_US_201804_v3.shp']); % Natural Gas (NG)
addOptional(p,'filePetro',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'EIA-PetroProductPipeline' filesep 'PetroleumProduct_Pipelines_US_201801.shp']); % Petroleum Product

% Optional - Minimum distance criteria for feature
addOptional(p,'minDist_ft',round(90*10*(unitsratio('ft','nm') / 3600),-1),@isnumeric); % % 90 seconds at 10 knots

% Parse
parse(p,iso_3166_2,varargin{:});

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
% HGL and Natural Gas Pipelines - DOE EIA
% For UAS M&S, I assume a pipeline is a pipeline...going for coverage
% and completness rather than use case nuance
% https://www.eia.gov/maps/layer_info-m.php
% https://www.eia.gov/maps/map_data/HGL_Pipelines_US_EIA.zip
% https://www.eia.gov/maps/map_data/NaturalGas_InterIntrastate_Pipelines_US_EIA.zip
% https://www.eia.gov/maps/map_data/PetroleumProduct_Pipelines_US_EIA.zip
% https://pipeline101.org/How-Do-Pipelines-Work
[S_crude, ~] = LoadMapProjData(p.Results.fileCrude,BoundingBox_wgs84);
[S_hgl, ~] = LoadMapProjData(p.Results.fileHGL,BoundingBox_wgs84);
[S_ng, ~] = LoadMapProjData(p.Results.fileNG,BoundingBox_wgs84);
[S_petro, ~] = LoadMapProjData(p.Results.filePetro,BoundingBox_wgs84);

% Aggregate and check there is data
S = [];
if ~isempty(S_crude); S_crude.type = repmat("crude",size(S_crude,1),1); S = [S; S_crude]; end
if ~isempty(S_hgl); S_hgl.type = repmat("hgl",size(S_hgl,1),1); S = [S; S_hgl]; end
if ~isempty(S_ng); S_ng.type = repmat("ng",size(S_ng,1),1); S = [S; S_ng]; end
if ~isempty(S_petro); S_petro.type = repmat("petro",size(S_petro,1),1); S = [S; S_petro]; end

% Filter to points within bounding box
[outLat_deg, outLon_deg, inBox] = filterboundingbox(S.LAT_deg,S.LON_deg,BoundingBox_wgs84);

%% Parse
if isempty(S) | ~any(inBox)
    fprintf('No raw data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},'VariableNames',{'id','LAT_deg','LON_deg'});
else
    % Filter based on bounding box
    S = S(inBox,:); S.LAT_deg = outLat_deg; S.LON_deg = outLon_deg;
    
    % Make sure there is at least 2 points
    S = S(cellfun(@numel,S.LAT_deg) >= 2,:);
    
    % Calculate distance traveled for each vector
    dist_ft = cellfun(@(y,x)(sum(distance(y(1:end-1), x(1:end-1),y(2:end), x(2:end),wgs84Ellipsoid('ft')))),S.LAT_deg,S.LON_deg,'uni',true);
    
    % Assign distance to table
    S.dist_ft = dist_ft;
    
    % Remove features that don't meet minimum distance
    S(S.dist_ft < p.Results.minDist_ft,:) = [];
    
    % Redo id after filtering
    S.id = (1:1:size(S,1))';
    S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string
    
end
