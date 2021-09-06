
% Function to compute graph distance matrix for a surface mesh.
%
% Arguments:
% - surfacePath (string): path to surf.gii file

function D = surfaceDistanceGraph(surfacePath)

% Load surface, compute distances between adjacent pairs.
g = gifti(surfacePath);
nVert = size(g.vertices,1);
D = zeros(nVert);

% Loop across indices, compute distances with neighbours
for i=1:nVert
    neighbors = [g.faces(find(g.faces(:,1)==i),2:3);
        g.faces(find(g.faces(:,2)==i),[1 3]);
        g.faces(find(g.faces(:,3)==i),1:2)];
    neighbors = unique(neighbors(:));
    neighborDist = pdist2(g.vertices(i,:),g.vertices(neighbors,:))';
    D(neighbors,i) = neighborDist;
end

end