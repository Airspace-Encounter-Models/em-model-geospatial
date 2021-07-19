function S = OSMLoad(iso_3166_2,layer,varargin)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'iso_3166_2',@isstr); % Examples: US-KS
addRequired(p,'layer',@isstr); % Examples: pois, railway, transport, etc.

% OSM extract
addOptional(p,'inDir',[getenv('AEM_DIR_GEOSPATIAL') filesep 'data' filesep 'OSM'],@isstr); % Directory containing OSM extracts

% Output table
addOptional(p,'varNames',{'Geometry','BoundingBox','Lon','Lat','osm_id','code','fclass','name'},@iscellstr); % Variable names, specified as a cell array of character vectors that are nonempty and distinct.
addOptional(p,'varTypes',{'string','double','double','double','string','double','string','string'},@iscellstr); % varTypes is a cell array of character vectors specifying data types

% Parse
parse(p,iso_3166_2,layer,varargin{:});

% Parse out optional variables routinely used for convenience
varNames = p.Results.varNames;
varTypes = p.Results.varTypes;

%% Find and Aggregate files
% Get filenames
listing = dir([p.Results.inDir filesep iso_3166_2 filesep '**' filesep 'gis*' layer '*.shp']);

% Preallocate table
S = table('Size',[0,length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);

% Aggregate files
for i=1:1:numel(listing)
    % Load file and get fieldnames
    temp = shaperead([listing(i).folder filesep listing(i).name],'UseGeoCoords',true);
    
    % Convert to table for easier column handling
    % Special handling if one row
    if numel(temp) > 1
        temp = struct2table(temp);
    else
        temp = struct2table(temp,'AsArray',true);
        temp.Lon = {temp.Lon};
        temp.Lat = {temp.Lat};
    end
    
    % Get variable names
    fn = temp.Properties.VariableNames;
    
    % Check if varNames and fn are an exact match
    % Do something if they don't match up
    if  ~isequal(fn,varNames)
        % Preallocate new temp overwrite (temp + ow)
        tempow = table('Size',[size(temp,1),length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
        
        % Iterate over variable names
        for j=1:1:numel(varNames)
            % Handle missing variables on case by case basis
            switch varNames{j}
                case 'BoundingBox'
                    if isa(temp.Lon,'cell')
                        x = cellfun(@(lon,lat)({[min(lon),min(lat);max(lon),max(lat)]}),temp.Lon,temp.Lat,'uni',true);
                    else
                        if numel(temp.Lon(1)) == 1
                            x = arrayfun(@(lon,lat)([lon,lat;lon,lat]),temp.Lon,temp.Lat,'uni',false);
                            
                        else
                            x = arrayfun(@(lon,lat)({[min(lon),min(lat);max(lon),max(lat)]}),temp.Lon,temp.Lat,'uni',true);
                            
                        end
                    end
                    tempow.(varNames{j}) = x;
                case 'Lon'
                    if ~isa(temp.Lon,'cell')
                        tempow.Lon = num2cell(temp.Lon);
                    else
                        tempow.Lon = temp.Lon;
                    end
                case 'Lat'
                    if ~isa(temp.Lat,'cell')
                        tempow.Lat = num2cell(temp.Lat);
                    else
                        tempow.Lat = temp.Lat;
                    end
                otherwise
                    tempow.(varNames{j}) = temp.(varNames{j});
            end
        end % End j loop
        % Overwrite temp with "temp overwrite" table
        temp = tempow;
    end
    
    % Concat
    S = [S; temp];
end % End i loop

%% Light Processing

% Remove any rows without lat / lon coordinates
S(cellfun(@isempty,S.Lon) | cellfun(@isempty,S.Lat),:) = [];

% Find unique osm_d
[~,ia,~] = unique(S.osm_id,'stable');
S = S(ia,:);

% Rename to include units
S.Properties.VariableNames{strcmp(S.Properties.VariableNames,'Lon')} = 'LON_DEG';
S.Properties.VariableNames{strcmp(S.Properties.VariableNames,'Lat')} = 'LAT_DEG';

% Transpore to columns
S.LAT_DEG = cellfun(@(x)(x'),S.LAT_DEG,'uni',false);
S.LON_DEG = cellfun(@(x)(x'),S.LON_DEG,'uni',false);

% Determine which features are polygons
isPolygon = strcmpi(S.Geometry,'Polygon');

%% Surface Area
% Preallaocate surface area column
S.area_ft = nan(size(S,1),1);

% Parse out lat / lon for performance
LAT_deg = S.LAT_DEG; LON_deg = S.LON_DEG;

% Define spheriod
spheroid = referenceEllipsoid('WGS84','ft');

if any(isPolygon)
    % Preallocate
    area_ft = nan(size(S.area_ft));
    
    % Find polygons that just have one shape
    % Some osm_ids may have multiple shapes within their geometry, a notional
    % example is an island in the middle of a lake. For a practical example see
    % osm_id = 7368112 the military 'Donnelly Training Area' in Alaska
    is1Shape = false(size(isPolygon));
    is1Shape(isPolygon) = (cellfun(@(x)(sum(isnan(x))),LON_deg(isPolygon)) == 1);
    l = isPolygon & is1Shape;
    
    % Calculate area for features with just 1 polygon
    area_ft(l) = areaint(cell2mat(LAT_deg(l))',cell2mat(LON_deg(l))',spheroid,'degrees');
    
    % Find features with mulitple polygons
    % Assign largest area, assuming that all other polygons are inside it
    idxMulti = find((~is1Shape) & isPolygon)';
    for i=idxMulti
        a_ft = areaint(LAT_deg{i},LON_deg{i},spheroid,'degrees');
        area_ft(i) = max(a_ft);
        % Code not used but here for food for thought
        % area_ft = sort(area_ft,'descend'); % Sort so largest element is first
        % area_ft(i) = area_ft(1) - sum(area_ft(2:end)); % Subtracts
    end
    
    % Assign to table
    S.area_ft = area_ft;
end

%% Regenerate table with fixed formatting and specific columns
S = table(S.fclass,S.code,S.name,S.osm_id,S.Geometry,S.BoundingBox,S.LAT_DEG,S.LON_DEG,S.area_ft,'VariableNames',{'fclass','code','name','osm_id','Geometry','BoundingBox','LAT_deg','LON_deg','AREA_ft'});
S = sortrows(S,{'code','osm_id'});

