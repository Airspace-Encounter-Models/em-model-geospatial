function path = UAScreatePath(ty,alt,area,camtheta)
% UASCREATEPATH
% [pos,ty, sPath] = simPath(p, q ,alt,a, vmax, ct)
% p - initial position
% q - final position
% ty - type of pattern
% alt - altitude
% a - area being searched (x,y)
% vmax - maximum velocity (x, zdown, zup)
% ct - camera theta (in degrees)
% Copyright 2018 - 2021, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%%
x = area(1);
y = area(2);

cam = 2*alt*tan(camtheta*(pi()/180)/2);

if cam > x || cam > y
    path = [x/2,y/2];
    return;
end

hsw = [0,0;0,1;2,1;2,0;4,0];
vsw = [hsw(:,2),hsw(:,1)];
path = [];

%%
switch ty
    case 1 % Creeping line
        p = (y)/cam;
        direction = 1;
        yloc = linspace(cam/2,y-cam/2,p);
        path = [];
        for ii = 1:(p-1)
            if direction == 1
                path = [path;cam/2,yloc(ii);x-cam/2,yloc(ii);x-cam/2,yloc(ii+1)];
            else
                path = [path;x-cam/2,yloc(ii);cam/2,yloc(ii);cam/2,yloc(ii+1)];
            end
            direction = direction * -1;
        end
        if direction == -1
            path = [path;cam/2,yloc(end)];
        else
            path = [path;x-cam/2,yloc(end)];
        end
    case 2 % Parallel Line
        p = (x)/cam;
        direction = 1;
        yloc = linspace(cam/2,x-cam/2,p);
        path = [];
        for ii = 1:(p-1)
            if direction == 1
                path = [path;cam/2,yloc(ii);y-cam/2,yloc(ii);y-cam/2,yloc(ii+1)];
            else
                path = [path;y-cam/2,yloc(ii);cam/2,yloc(ii);cam/2,yloc(ii+1)];
            end
            direction = direction * -1;
        end
        if direction == -1
            path = [path;cam,yloc(end)];
        else
            path = [path;y-cam,yloc(end)];
        end
        path(:,3)=path(:,1);
        path = path(:,2:3);
    case 3 % Sector
        sspts = [0.5  0.5000
            1.0000    0.5000
            0.7500    0.0670
            0.2500    0.9330
            0.7500    0.9330
            0.2500    0.0670
            0         0.5000
            0.5000    0.5000];
        sspts = [sspts;sspts([5,2,7,4,3,6,1],:)];
        path = (min(area)-cam)*sspts;
        path = path + cam;
        path(:,1) = path(:,1) + x/2 - (max(path(:,1))+min(path(:,1)))/2;
        path(:,2) = path(:,2) + y/2 - (max(path(:,2))+min(path(:,2)))/2;
    case 4 % Spiral    
        v = cam;
        c = min(x,y);
        
        div = ceil(c/v);
        pts = [1:div;1:div;div:-1:1;div:-1:1];
        %pts = [linspace(0,div,div),linspace(0,div,div),linspace(div,0,div),linspace(div,0,div)];
        pts = pts(:);
        xs = pts(1:floor(end/2));
        t = pts(1:end-2);
        t = circshift(t,1);
        ys = t(1:(floor(end/2)+1));
        vals = linspace(alt,c-alt-1,div);
        xs = vals(xs);
        ys = vals(ys);
        path = [reshape(xs,length(xs),1),reshape(ys,length(ys),1)];
        path = flipud(path);
        
        path(:,1) = path(:,1) - min(path(:,1));
        path(:,2) = path(:,2) - min(path(:,2));
        path(:,1) = path(:,1)/max(path(:,1));
        path(:,2) = path(:,2)/max(path(:,2));
        path(:,1) = path(:,1) * (x-cam);
        path(:,2) = path(:,2) * (y-cam);
        path = path + cam/2;
        path(:,1) = path(:,1) + x/2 - (max(path(:,1))+min(path(:,1)))/2;
        path(:,2) = path(:,2) + y/2 - (max(path(:,2))+min(path(:,2)))/2;
        
    case 5
        p = ceil(chipy/(2*alt));
        direction = 1;
        yloc = linspace(alt+1,chipy-alt,p);
        path = [];
        for ii = 1:(p-1)
            if direction == 1
                path = [path;alt+1,yloc(ii);chipx-alt,yloc(ii);chipx-alt,yloc(ii+1)];
            else
                path = [path;chipx-alt,yloc(ii);alt+1,yloc(ii);alt+1,yloc(ii+1)];
            end
            direction = direction * -1;
        end
        if direction == -1
            path = [path;chipx-alt,yloc(end);alt+1,yloc(end)];
        else
            path = [path;alt+1,yloc(end);chipx-alt,yloc(end)];
        end
        path = mirror(mirror(path,'h'),'v');
    case 6
        p = ceil(chipx/(2*alt));
        direction = 1;
        xloc = linspace(alt+1,chipx-alt,p);
        path = [];
        for ii = 1:(p-1)
            if direction == 1
                path = [path;xloc(ii),alt+1;xloc(ii),chipy-alt;xloc(ii+1),chipy-alt];
            else
                path = [path;xloc(ii),chipy-alt;xloc(ii),alt+1;xloc(ii+1),alt+1];
            end
            direction = direction * -1;
        end
        if direction == -1
            path = [path;xloc(end),chipy-alt;xloc(end),alt+1];
        else
            path = [path;xloc(end),alt+1;xloc(end),chipy-alt];
        end
        path = mirror(mirror(path,'h'),'v');
end

%%
mask = ones(size(path,1),1);
for ii = 1:(size(path,1)-1)
    p = path(ii,:);
    q = path(ii+1,:);
    if p(1)-q(1) == 0 && p(2)-q(2) == 0
        mask(ii) = 0;
    end
end
path = path(mask == 1,:);
