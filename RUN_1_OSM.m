% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% INPUTS
%iso_3166_2 = {'US-CA','US-AK','US-AL','US-AR','US-AZ','US-CO','US-CT','US-DE','US-FL','US-GA','US-HI','US-IA','US-ID','US-IL','US-IN','US-KS','US-KY','US-LA','US-MA','US-MD','US-ME','US-MI','US-MN','US-MO','US-MS','US-MT','US-NC','US-ND','US-NE','US-NH','US-NJ','US-NM','US-NV','US-NY','US-OH','US-OK','US-OR','US-PA','US-RI','US-SC','US-SD','US-TN','US-TX','US-UT','US-VA','US-VT','US-WA','US-WI','US-WV','US-WY','US-PR'};
iso_3166_2 = {'US-AK','US-CA','US-FL','US-KS','US-MA','US-MS','US-NC','US-ND','US-NH','US-NY','US-OK','US-PR','US-RI','US-TN','US-TX','US-VA'}; % dev cases

isSave = true;
isComputeElv = false;
dem = 'srtm1';

%% ITERATE
for i=1:1:numel(iso_3166_2)    
    OSMParse(iso_3166_2{i},'isSave',isSave,'isComputeElv',isComputeElv,'dem',dem);
    fprintf('%s COMPLETED: %i/%i\n', iso_3166_2{i},i,numel(iso_3166_2));
end
