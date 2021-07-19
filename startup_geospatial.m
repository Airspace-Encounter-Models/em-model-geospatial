% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Path
% Self (AEM_DIR_GEOSPATIAL)
if isempty(getenv('AEM_DIR_GEOSPATIAL'))
    error('startup:AEM_DIR_GEOSPATIAL','System environment variable, AEM_DIR_GEOSPATIAL, not found\n')
else
    addpath(genpath([getenv('AEM_DIR_GEOSPATIAL') filesep 'code']))
end

% AEM_DIR_CORE
if isempty(getenv('AEM_DIR_CORE'))
    error('startup:aem_dir_core','System environment variable, AEM_DIR_CORE, not found\n')
else
    addpath(genpath([getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-1stparty']))
    addpath(genpath([getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-3rdparty' filesep 'InPolygon-MEX']))
    addpath(genpath([getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-3rdparty' filesep 'arclength']))
    addpath(genpath([getenv('AEM_DIR_CORE') filesep 'matlab' filesep 'utilities-3rdparty' filesep 'interparc']))
end

%% Plotting defaults
% https://www.mathworks.com/help/matlab/creating_plots/default-property-values.html
myColorOrder = [0 114 178;... % Blue
    230 159 0;... % Orange
    0 158 155;... % Bluish green
    213 94 0;.... % Vermillion
    86 180 233;... % Sky Blue
    204 121 167] / 255; % Reddish purple

set(groot,'defaultFigureColor','white'); % Figure defaults
set(groot,'defaultAxesColorOrder',myColorOrder,'defaultAxesFontsize',12,'defaultAxesFontweight','bold','defaultAxesFontName','Arial'); % Axes defaults
set(groot,'defaultLineLineWidth',1.5); % Line defaults
set(groot,'defaultStairLineWidth',1.5); % Stair defaults (used in ecdf)

%% MathWorks Products
product_info = ver;
if ~any(strcmpi({product_info.Name},'Mapping Toolbox'))
    error('toolbox:shaperead',sprintf('Mapping Toolbox not found: em-model-geospatial use various functions from this toolbox.\nA non comprehensive list of Mapping Toolbox functions include distance(), legs(), scircle1(), shaperead() and wgs84Ellipsoid().\n'));
end

if ~any(strcmpi({product_info.Name},'Parallel Computing Toolbox'))
    warning('toolbox:parfor',sprintf('Parallel Computing Toolbox not found: em-model-geospatial use parfor from this toolbox\n'));
end

if ~any(strcmpi({product_info.Name},'Deep Learning Toolbox')) && ~any(strcmpi({product_info.Name},'Neural Network Toolbox'))
    warning('toolbox:combvec',sprintf('GenerateTracks() uses combvec(), a function from the MATLAB Deep Learning or Neural Network Toolbox\nAn alternative is to modify the code to use allcomb from file exchange:https://www.mathworks.com/matlabcentral/fileexchange/10064-allcomb-varargin\n'));
end
