function [outName,S_landuse,S_pois,S_railway,S_transport,S_waterway,S_road] = OSMParse(iso_3166_2, varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2'); % Source

% Optional - Save
addOptional(p,'outName',[getenv('AEM_DIR_GEOSPATIAL') filesep 'output' filesep 'OSM_1_' iso_3166_2 '.mat']); % Output filename
addOptional(p,'isSave',true,@islogical); % If true, save to file

% Optional - DEM
addOptional(p,'isComputeElv',false,@islogical); % If true, estimate elevation for each latitude / longitude coordinates
addOptional(p,'dem','globe',@(x) isstr(x) && any(strcmpi(x,{'dted1','dted2','globe','gtopo30','srtm1','srtm3','srtm30'}))); % DEM used when estimate elevation

% Parse
parse(p,iso_3166_2,varargin{:});

% Start timer
tic

%% Load base OSM
S_landuse = OSMLoad(iso_3166_2,'landuse'); fprintf('LOADED OSM Land Use: %.1f sec\n',toc);
S_pois = OSMLoad(iso_3166_2,'pois'); fprintf('LOADED OSM Points of Interest: %.1f sec\n',toc);
S_railway = OSMLoad(iso_3166_2,'railway'); fprintf('LOADED OSM Railway: %.1f sec\n',toc);
S_transport = OSMLoad(iso_3166_2,'transport'); fprintf('LOADED OSM Transport: %.1f sec\n',toc);
S_waterway = OSMLoad(iso_3166_2,'waterways'); fprintf('LOADED OSM Waterway: %.1f sec\n',toc);
S_road = OSMLoad(iso_3166_2,'roads'); fprintf('LOADED OSM Roads: %.1f sec\n',toc);

%% Aggregate base with other OSM files
% Only keep major roads or paths unsuitable for cars
% S_road = S_road(S_road.code >= 5150 | S_road.code < 5120,:);

% Load Water
S_water = OSMLoad(iso_3166_2,'water'); fprintf('LOADED OSM Water: %.1f sec\n',toc);

% Aggregate "wetland" of water into landuse
S_landuse = [S_landuse; S_water(S_water.code == 8201,:) ];

% Aggregate reserviovr into waterway
S_water_reservoir = S_water(S_water.code==8201,:);
S_waterway = [S_waterway;S_water_reservoir  ]; % Aggregate

% Aggregate "river" of water into waterway
S_water_river = S_water(S_water.code == 8202,:); % Filter
S_waterway = [S_waterway;S_water_river  ]; % Aggregate

% Aggregate lakes & ponds into waterway
S_water_lake = S_water(contains(S_water.name,'lake','IgnoreCase',true),:); % Filter
S_water_lake.fclass = repmat({'water-lake'},size(S_water_lake.fclass)); % Rename
S_water_pond = S_water(contains(S_water.name,'pond','IgnoreCase',true),:); % Filter
S_water_pond.fclass = repmat({'water-pond'},size(S_water_pond.fclass)); % Rename
S_waterway = [S_waterway;S_water_lake;S_water_pond  ]; % Aggregate

% Clear S_water variables
clear S_water S_water_reservoir S_water_river S_water_lake S_water_pond;

% Aggregate "beach" of natural into landuse
S_natural = OSMLoad(iso_3166_2,'natural'); fprintf('LOADED OSM Natural: %.1f sec\n',toc);
S_landuse = [S_landuse; S_natural(S_natural.code == 4141 | strcmp(S_natural.Geometry,'Polygon'),:) ];
clear S_natural;

% Aggregate "service" and surface "parking_site" into pois
S_traffic = OSMLoad(iso_3166_2,'traffic'); fprintf('LOADED OSM Traffic: %.1f sec\n',toc);
S_pois = [S_pois; S_traffic(S_traffic.code == 5251 | S_traffic.code == 5261,:)]; %
% Aggregate "parking"
S_traffic_parking = S_traffic(S_traffic.code == 5260 & ~strcmp(S_traffic.name,''),:);
S_traffic_parking(contains(S_traffic_parking.name,'garage','IgnoreCase',true),:) = []; % Remove garages
S_pois = [S_pois; S_traffic_parking];
clear S_traffic S_traffic_parking;

%% Sort and Parse Code
% Sort by code
%2xxx pois Points of Interest, therein:
%20xx Public facilities such as government offices, post office, police, ...
%21xx Hospitals, pharmacies, ...
%22xx Culture, Leisure, ...
%23xx Restaurants, pubs, cafes, ...
%24xx Hotel, motels, and other places to stay the night
%25xx Supermarkets, bakeries, ...
%26xx Tourist information, sights, museums, ...
%29xx Miscellaneous points of interest
S_pois = sortrows(S_pois,{'code','name'},{'ascend','ascend'});
S_pois.isPublic = (S_pois.code >=2000 & S_pois.code < 2100);
S_pois.isHealth = (S_pois.code >=2100 & S_pois.code < 2200);
S_pois.isLeisure = (S_pois.code >=2200 & S_pois.code < 2300);
S_pois.isCatering = (S_pois.code >=2300 & S_pois.code < 2400);
S_pois.isAccomodation = (S_pois.code >=2400 & S_pois.code < 2500);
S_pois.isShopping = (S_pois.code >=2500 & S_pois.code < 2600);
S_pois.isTourism = (S_pois.code >=2600 & S_pois.code < 2900);
S_pois.isMisc = (S_pois.code >=2900);

% Expected land use codes
S_landuse = sortrows(S_landuse,{'code','name'},{'ascend','ascend'});
S_landuse.isAgr = cellfun(@(x)(any(strcmp(x,{'farm','orchard','vineyard'}))),S_landuse.fclass);
S_landuse.isCom = cellfun(@(x)(any(strcmp(x,{'commercial','retail','parking','parking_site','service'}))),S_landuse.fclass);
S_landuse.isCon = cellfun(@(x)(any(strcmp(x,{'forest','grass','heath','meadow','reservoir','scrub','wetland'}))),S_landuse.fclass);
S_landuse.isInd = cellfun(@(x)(any(strcmp(x,{'industrial','quarry'}))),S_landuse.fclass);
S_landuse.isMil = cellfun(@(x)(any(strcmp(x,{'military'}))),S_landuse.fclass);
S_landuse.isRec = cellfun(@(x)(any(strcmp(x,{'beach','nature_reserve','park','recreation_ground','national_park'}))),S_landuse.fclass);
S_landuse.isRes = cellfun(@(x)(any(strcmp(x,{'residential','cemetery','allotments'}))),S_landuse.fclass);

% Railway
S_railway = sortrows(S_railway,{'code','name'},{'ascend','ascend'});

% Transport
S_transport = sortrows(S_transport,{'code','name'},{'ascend','ascend'});

% Waterway
S_waterway = sortrows(S_waterway,{'code','name'},{'ascend','ascend'});

% Road
S_road = sortrows(S_road,{'code','name'},{'ascend','ascend'});

%% Calculate MSL elevation
% This is computationally and time intensive,
% For large areas, like US-AK, MSL2AGL() may run out memory, this is a
% known bug and I haven't fixed it yet
if p.Results.isComputeElv
    % Don't allow processing of large geospatial areas,
    % MSL2AGL() may run out memory, this is a known bug and I haven't fixed it yet
    if any(strcmpi(iso_3166_2,{'US-AK','US-CA','US-TX'}))
        fprintf('%s is too large, will not calculate MSL elevation\n',iso_3166_2);
    else
        [S_landuse.ELEVATION_ft_msl,~,~,~] = msl2agl(S_landuse.LAT_deg,S_landuse.LON_deg,p.Results.dem);
        S_landuse.ELEVATION_src = repmat(p.Results.dem,size(S_landuse.ELEVATION_ft_msl));
        disp('CALCULATED elevation - landuse');
        
        [S_pois.ELEVATION_ft_msl,~,~,~] = msl2agl(S_pois.LAT_deg,S_pois.LON_deg,p.Results.dem);
        S_pois.ELEVATION_src = repmat(p.Results.dem,size(S_pois.ELEVATION_ft_msl));
        disp('CALCULATED elevation - pois');
        
        [S_railway.ELEVATION_ft_msl,~,~,~] = msl2agl(S_railway.LAT_deg,S_railway.LON_deg,p.Results.dem);
        S_railway.ELEVATION_src = repmat(p.Results.dem,size(S_railway.ELEVATION_ft_msl));
        disp('CALCULATED elevation - railway');
        
        [S_transport.ELEVATION_ft_msl,~,~,~] = msl2agl(S_transport.LAT_deg,S_transport.LON_deg,p.Results.dem);
        S_transport.ELEVATION_src = repmat(p.Results.dem,size(S_transport.ELEVATION_ft_msl));
        disp('CALCULATED elevation - transport');
        
        [S_waterway.ELEVATION_ft_msl,~,~,~] = msl2agl(S_waterway.LAT_deg,S_waterway.LON_deg,p.Results.dem);
        S_waterway.ELEVATION_src = repmat(p.Results.dem,size(S_waterway.ELEVATION_ft_msl));
        disp('CALCULATED elevation - waterway');
        
        [S_road.ELEVATION_ft_msl,~,~,~] = msl2agl(S_road.LAT_deg,S_road.LON_deg,p.Results.dem);
        S_road.ELEVATION_src = repmat(p.Results.dem,size(S_road.ELEVATION_ft_msl));
        disp('CALCULATED elevation - road');
    end
end

%% Save
if p.Results.isSave
    save(p.Results.outName,'iso_3166_2','S_landuse','S_pois','S_railway','S_transport','S_waterway','S_road');%,'-v7.3','-nocompression');
    fprintf('SAVED: %.1f sec\n',toc);
end
