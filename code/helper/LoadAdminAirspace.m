function [airspace, BoundingBox_wgs84] = LoadAdminAirspace(iso_3166_2,fileAdmin,fileAirspace)
% RUNHELPER2 is a helper function to streamline RUN_OSM_2_* scripts
% Loads natural earth adminstrative boundary and airspace class data
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

% Load Natural Earth Adminstrative Boundary
ne_admin = shaperead(fileAdmin);

% Create bounding box based on adminstrative boundary
BoundingBox_wgs84 = ne_admin(strcmp({ne_admin.iso_3166_2},iso_3166_2)).BoundingBox;

% Load airspace
load(fileAirspace,'airspace');

% Filter to include airspace only in bounding box
[~, ~, inAirspace] = filterboundingbox(airspace.LAT_deg,airspace.LON_deg,BoundingBox_wgs84);
airspace = airspace(inAirspace,:);
