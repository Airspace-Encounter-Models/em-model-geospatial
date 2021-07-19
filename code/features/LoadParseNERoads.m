function [S, S_raw, airspace, BoundingBox_wgs84] = LoadParseNERoads(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); % Location

% Optional - File
addOptional(p,'fileAdmin',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'NE-Adminstrative' filesep 'ne_10m_admin_1_states_provinces.shp']);
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat']); % Output of RUN_Airspace_1 from em-core
addOptional(p,'fileRoads',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'NE-Roads-NA' filesep 'ne_10m_roads_north_america.shp']);

% Optional - Natural Earth Roads
addOptional(p,'roadTypes',{'freeway','primary'},@iscell); % Road types to use
addOptional(p,'step',10000,@isnumeric); % polymerge iterative step counter

% Optional - Minimum distance criteria for feature
addOptional(p,'minDist_ft',round(90*10*(unitsratio('ft','nm') / 3600),-1),@isnumeric); % % 90 seconds at 10 knots

% Parse
parse(p,iso_3166_2,varargin{:});
step = p.Results.step;

%% Helper function
[airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,p.Results.fileAdmin,p.Results.fileAirspace);

%% Load raw data
% Load raw data
% https://www.naturalearthdata.com/downloads/10m-cultural-vectors/roads/
S_raw = shaperead(p.Results.fileRoads,'BoundingBox',BoundingBox_wgs84,'UseGeoCoords',true);
S_raw = struct2table(S_raw);

% Create filter for state / federal freeway / primary roads
l = contains(S_raw.class,{'state','federal'},'IgnoreCase',true) & contains(S_raw.type,p.Results.roadTypes,'IgnoreCase',true);

% Filter to points within bounding box
[outLat_deg, outLon_deg, inBox] = filterboundingbox(S_raw.Lat(l),S_raw.Lon(l),BoundingBox_wgs84);

%% Parse
if isempty(S_raw) | ~any(inBox)
    fprintf('No raw data for %s', iso_3166_2);
    
    % Create empty output
    S = table(strings(0),{},{},'VariableNames',{'id','LAT_deg','LON_deg'});
else
    
    % Merge line segments with matching endpoints
    % If there are too many segments (i.e. US-CA), just iterate in batches
    n = numel(outLon_deg);
    if n > step;
        % Set counters
        s = 0;
        e = 0;
        keepIterate = true;
        
        % Preallocate
        latMerged = {};
        lonMerged = {};
        
        % Iterate
        while keepIterate
            % Advance counters
            s = e +1;
            e = s + step;
            if e > n
                e = n;
                keepIterate = false;
            end
            
            % Merge
            [latm, lonm] = polymerge(outLat_deg(s:e), outLon_deg(s:e));
            
            % Aggregate
            latMerged = [latMerged; latm];
            lonMerged = [lonMerged; lonm];
        end
    else
        [latMerged, lonMerged] = polymerge(outLat_deg, outLon_deg);
    end
    
    % Create new streamlined table
    S = table((1:1:numel(latMerged))', latMerged, lonMerged,'VariableNames',{'id','LAT_deg','LON_deg'});
    %[y,x] = polyjoin(latMerged,lonMerged); geoshow(y,x);
    
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
