function [latMid,lonMid] = CalcLatLonMid(lat1,lon1,lat2,lon2)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause
% https://www.mathworks.com/matlabcentral/answers/229312-how-to-calculate-the-middle-point-between-two-points-on-the-earth-in-matlab#answer_185647

Bx = cosd(lat2) * cosd(lon2-lon1);
By = cosd(lat2) * sind(lon2-lon1);
latMid = atan2d(sind(lat1) + sind(lat2), sqrt( (cosd(lat1)+Bx)*(cosd(lat1)+Bx) + By*By ) );
lonMid = lon1 + atan2d(By, cosd(lat1) + Bx);
