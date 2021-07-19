function [S, S_raw, airspace, BoundingBox_wgs84] = LoadParseUSWTDB(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); 

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core
addOptional(p,'fileUSWTDB',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'USGS-WindTurbineDB' filesep 'uswtdb_v2_3_20200109' '.shp']); % https://eerscmap.usgs.gov/uswtdb/data/

% Optional - Point insepection
% Tower diameter = 14 ft, ref http://www.acua.com/uploadedFiles/Site/About_Us/WindFarm.pdf
% Tower diamter = 13 ft, ref https://www.sciencedirect.com/science/article/pii/S0143974X13000047
% Distance from tower = 5 meters / 17 feet, ref https://doi.org/10.1109/OSES.2019.8867145
addOptional(p,'obstacleWidthMode','blade',@ischar); % Set horizontal radius based on tower diameter or blades
addOptional(p,'pointHorz_ft',250,@isnumeric); 
addOptional(p,'pointVert_ft',50,@isnumeric); % 

% Parse
parse(p,iso_3166_2,varargin{:});
pointHorz_ft = p.Results.pointHorz_ft;
pointVert_ft = p.Results.pointVert_ft;

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
[~, S_raw] = LoadMapProjData(p.Results.fileUSWTDB,BoundingBox_wgs84);

% Filters
l = contains(S_raw.t_state,iso_3166_2(end-1:end)) & S_raw.t_conf_loc >= 3 & S_raw.t_ttlh ~= -9999;

%% Parse
if isempty(S_raw) | ~any(l)
    fprintf('No raw data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},'VariableNames',{'id','LAT_deg','LON_deg'});
else
    % Create new streamlined table
    if size(S_raw,1) > 1
        S = table(S_raw.case_id(l), num2cell(S_raw.LAT_deg(l)), num2cell(S_raw.LON_deg(l)),'VariableNames',{'id','LAT_deg','LON_deg'});
    else
        S = table(S_raw.case_id(l), num2cell(S_raw.LAT_deg{l}), num2cell(S_raw.LON_deg{l}),'VariableNames',{'id','LAT_deg','LON_deg'});
    end
    
    % Redo id after filtering
    S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string
    
    % https://eerscmap.usgs.gov/uswtdb/assets/data/uswtdb_v2_3_20200109.xml
    % t_hh =  turbine hub height in meters (m). Data from AWEA, manufacturer data, and/or other internet resources; -9999 values in the shapefile and blank values in the csv are unknown
    % t_rd = turbine rotor diameter in meters (m); -9999 values in the shapefile and blank values in the csv are unknown
    % t_ttlh = turbine total height - height of entire wind turbine from ground to tip of a vertically extended blade above the tower. Computed as the hub height plus half of the rotor diameter, in meters, when t_hh and t_rd are non-missing. Otherwise, the total height as provided by the FAA DOF or FAA OE/AAA is used, which can be considered a maximum height; -9999 values in the shapefile and blank values in the csv are unknown
    pointHeight_ft_agl = S_raw.t_ttlh(l) * unitsratio('ft','m');
    
    % Add vertical
    S.pointHeight_ft_agl = floor(pointHeight_ft_agl + pointVert_ft);
    
    % Add horizontal
    switch p.Results.obstacleWidthMode
        case 'tower'
            % Tower itself
            % Tower diameter = 14 ft, ref http://www.acua.com/uploadedFiles/Site/About_Us/WindFarm.pdf
            obsRadius_ft = 14/2;
        case 'blade'
            % Turbine radius
            obsRadius_ft = (S_raw.t_rd(l) / 2) * unitsratio('ft','m');
    end
    S.pointRadius_ft = round(obsRadius_ft + repmat(pointHorz_ft,size(S,1),1),0);
end
