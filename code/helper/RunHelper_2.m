function [dem, demDir, demBackup, demDirBackup, outDirBase, Tdof] = RunHelper_2(iso_3166_2)
% RUNHELPER2 is a helper function to streamline RUN_OSM_2_* scripts
% It defines commonly used digital elevation models and output directory
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

% SRTM doesn't have great US-AK, so we use something else
if strcmp(iso_3166_2,'US-AK')
    dem = 'dted1';
    demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-DTED1'];
    
    demBackup = 'globe';
    demDirBackup  = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'];
else
    dem = 'srtm1';
    demDir = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM1'];
    
    demBackup = 'srtm3';
    demDirBackup  = [getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM3'];
end

% Output directory
outDirBase = [getenv('AEM_DIR_GEOSPATIAL') filesep 'output' filesep 'trajectories' filesep iso_3166_2];

% Load point obstacles
[~, Tdof] = gridDOF('inFile',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'dof.mat'],...
    'minHeight_ft',200,...
    'isVerified',true,...
    'obsTypes',{'antenna','lgthouse','met','monument','sign','silo','spire','stack','t-l twr','tank','tower','tramway','utility pole','windsock'});
