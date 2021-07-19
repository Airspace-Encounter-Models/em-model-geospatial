function [S, S_raw] = LoadMapProjData(filename,BoundingBox,mstruct)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

% Load
S_raw = shaperead(filename,'BoundingBox',BoundingBox);

% Check if any data exists
if isempty(S_raw)
   S_raw = struct2table(S_raw);
   S = S_raw;
   warning('No features within bounding box for %s\nExiting via return\n',filename);
   return; 
end

if numel(S_raw) > 1
    S_raw = struct2table(S_raw);
else
    S_raw = struct2table(S_raw,'AsArray',true);
    S_raw.X = {S_raw.X};
    S_raw.Y = {S_raw.Y};
end

%S_raw.id = arrayfun(@num2str,(S_raw.id),'uni',false); % Convert id to string

if ~isempty(S_raw) 
    % Convert to lat / lon
    if nargin > 2
        [S_raw.LAT_deg,S_raw.LON_deg] = cellfun(@(x,y)(minvtran(mstruct,x,y)),S_raw.X,S_raw.Y,'uni',false);
    else
        S_raw.LON_deg = S_raw.X;
        S_raw.LAT_deg = S_raw.Y;
    end
    
    % Merge line segments with matching endpoints
    [latMerged,lonMerged] = polymerge(S_raw.LAT_deg,S_raw.LON_deg);
    
    % Create new streamlined table
    S = table((1:1:numel(latMerged))', latMerged, lonMerged,'VariableNames',{'id','LAT_deg','LON_deg'});
    S.id = arrayfun(@num2str,(S.id),'uni',false); % Convert id to string
else
    warning('No features within BoundingBox for %s',filename);
    S = table;
end
