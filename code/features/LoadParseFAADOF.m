function [S, airspace, BoundingBox_wgs84] = LoadParseFAADOF(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2');

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core
addOptional(p,'fileDOF',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof.mat']); % Output of RUN_readfaadof from em-core

% Optional - FAA DOF
addOptional(p,'obsTypes',{'antenna','lgthouse','met','monument','sign','silo','spire','stack','t-l twr','tank','tower','tramway','utility pole','windmill','windsock'},@iscell); % Obstacles types to use
addOptional(p,'minHeight_ft',50,@isnumeric); % Minimum height of obstacles

% Optional - Point insepection
addOptional(p,'pointHorz_ft',250,@isnumeric); 
addOptional(p,'pointVert_ft',50,@isnumeric); 

% Parse
parse(p,iso_3166_2,varargin{:});
pointHorz_ft = p.Results.pointHorz_ft;
pointVert_ft = p.Results.pointVert_ft;
obsTypes = p.Results.obsTypes;
minHeight_ft = p.Results.minHeight_ft;

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load data
load(p.Results.fileDOF,'Tdof');

% Filter data
% State, obstacle type, minimum height, location
l = strcmpi(Tdof.iso_3166_2,iso_3166_2) & contains(Tdof.obs_type,obsTypes) & Tdof.alt_ft_agl >= minHeight_ft & strcmpi(Tdof.verification_status,'verified');

%% Parse
if isempty(Tdof) | ~any(l)
    fprintf('No data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},'VariableNames',{'id','LAT_deg','LON_deg'});   
else
    % Create new streamlined table
    S = table(Tdof.obs_num(l), num2cell(Tdof.lat_deg(l)), num2cell(Tdof.lon_deg(l)),Tdof.alt_ft_agl(l),Tdof.obs_type(l),'VariableNames',{'id','LAT_deg','LON_deg','alt_ft_agl','type'});
    
    % Add vertical
    S.pointHeight_ft_agl = floor(pointVert_ft + S.alt_ft_agl);
    
    % Add horizontal
    obsRadius_ft = 0; % Unlike wind turbines, we don't have width information
    S.pointRadius_ft = round(obsRadius_ft + repmat(pointHorz_ft,size(S,1),1),0);
end
