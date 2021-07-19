function [S,pgonunion] = CreatePatterns(LAT_deg,LON_deg,pattern,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'LAT_deg');
addRequired(p,'LON_deg');
addRequired(p,'pattern',@ischar);

% Optional - Features
addOptional(p,'bufwidth_deg',0.00015,@isnumeric); % bufferwidth for bufferm()
addOptional(p,'minDist_ft',1520,@isnumeric); % 90 seconds at 10 knots
addOptional(p,'BoundingBox_wgs84',[-124.848974, 24.396308; -66.885444, 49.384358],@isnumeric); % Bounding Box

% Optional - Pattern Parameters
addOptional(p,'alt_ft_agl',250,@isnumeric); % Bounding Box
addOptional(p,'camTheta_deg',90,@isnumeric); % Bounding Box

% Optional - Plotting
addOptional(p,'isPlot',false,@islogical);
addOptional(p,'fignum',10,@isnumric);

% Parse
parse(p,LAT_deg,LON_deg,pattern,varargin{:});

%% Create buffer
% Reduce density of points in vector data
[latr_deg, lonr_deg] = cellfun(@(lat,lon)(reducem(lat,lon,p.Results.bufwidth_deg)),LAT_deg, LON_deg,'uni',false);

% Remove empty cells
l = cellfun(@isempty,latr_deg);
latr_deg(l) = []; lonr_deg(l) = [];

% Buffer zones for latitude-longitude polygons
latb_deg = cell(size(latr_deg)); lonb_deg = cell(size(latr_deg));
fprintf('Calculating buffers for %i features\n',numel(latb_deg));
for j=1:1:numel(latb_deg)
    [latb_deg{j}, lonb_deg{j}] = bufferm(latr_deg{j}, lonr_deg{j}, p.Results.bufwidth_deg,'outPlusInterior');
end

%% Create Polygons
% Filter to points within bounding box
[latf_deg, lonf_deg, inBox] = filterboundingbox(latb_deg,lonb_deg,p.Results.BoundingBox_wgs84);

% Create polyshape, remove holes, union regions, and split regions
[lat,lon] = polyjoin(latf_deg,lonf_deg);

pgon = polyshape(lon,lat);
pgon = rmholes(pgon);
pgonunion = rmholes(union(pgon,'KeepCollinearPoints',true));
[latcells,loncells] = polysplit(pgonunion.Vertices(:,2),pgonunion.Vertices(:,1));

% Create new streamlined table
S = table((1:1:numel(latcells))', latcells, loncells,'VariableNames',{'id','LAT_deg','LON_deg'});

if isempty(S)
    warning('No data after filtering, exiting via RETURN\n');
    return
end

%% Create Patterns
minLon = cellfun(@min,S.LON_deg);
minLat = cellfun(@min,S.LAT_deg);
maxLon = cellfun(@max,S.LON_deg);
maxLat = cellfun(@max,S.LAT_deg);

rangeLat_deg = abs(maxLat-minLat);
rangeLon_deg = abs(maxLon-minLon);

% Preallocate
patLat_deg = cell(size(S,1),1);
patLon_deg = cell(size(S,1),1);

% Generate pattern
for j=1:1:size(S,1)
    switch pattern
        case 'line'
            if rangeLat_deg(j) >= rangeLon_deg
                % Feature is taller / more vertical
                [patLat_deg{j} ,patLon_deg{j} ] = GenPattern([minLon(j),minLat(j);maxLon(j),maxLat(j)],2,p.Results.alt_ft_agl, p.Results.camTheta_deg);
            else
                % Feature is wider / more horizontal
                [patLat_deg{j} ,patLon_deg{j} ] = GenPattern([minLon(j),minLat(j);maxLon(j),maxLat(j)],1,p.Results.alt_ft_agl, p.Results.camTheta_deg);
            end
        case 'sector'
            [patLat_deg{j} ,patLon_deg{j} ] = GenPattern([minLon(j),minLat(j);maxLon(j),maxLat(j)],3,p.Results.alt_ft_agl, p.Results.camTheta_deg);
        case 'spiral'
            [patLat_deg{j} ,patLon_deg{j} ] = GenPattern([minLon(j),minLat(j);maxLon(j),maxLat(j)],4,p.Results.alt_ft_agl, p.Results.camTheta_deg);
        case 'random'
            [patLat_deg{j} ,patLon_deg{j} ] = GenPattern([minLon(j),minLat(j);maxLon(j),maxLat(j)],randi(4,1),p.Results.alt_ft_agl, p.Results.camTheta_deg);
    end
end
% Reassign
S.LAT_deg = patLat_deg;
S.LON_deg = patLon_deg;

%% Filter based on distance traveled
% Make sure there is at least 2 points
S = S(cellfun(@numel,S.LAT_deg) >= 2,:);

% Calculate distance traveled for each vector
dist_ft = cellfun(@(y,x)(sum(distance(y(1:end-1), x(1:end-1),y(2:end), x(2:end),wgs84Ellipsoid('ft')))),S.LAT_deg,S.LON_deg,'uni',true);

% Assign distance to table
S.dist_ft = dist_ft;

% Remove features that don't meet minimum distance
S(S.dist_ft < p.Results.minDist_ft,:) = [];

if isempty(S)
    warning('No data after filtering, exiting via RETURN\n');
    return
end

% Redo id after filtering
S.id = (1:1:size(S,1))';
S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string

%% Plot
if p.Results.isPlot
    figure(p.Results.fignum); set(gcf,'name','createpatterns');
    [y,x] = polyjoin(S.LAT_deg,S.LON_deg);
    geoshow(y,x);
    hold on;
    plot(pgonunion);
end
