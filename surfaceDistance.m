
% Function to compute geodesic path between two points on a cortical
% surface reconstruction.
%
% Uses the implementation of the Dijkstra algorithm packaged with the
% Freesurfer matlab tools (dijk and pred2path)
%
% NOTE: I've encountered some errors when startCoords and endCoords are the
% same, and more than one coordinate.
%
% Arguments:
% - surfacePath (string): path to surf.gii file
% - startCoords (vector): surface coords (one-indexed) of path start points
% - endCoords (vector): surface coords (one-indexed) of path end points

function [distance,pathCoords] = surfaceDistance(surfacePath,startCoords,endCoords)

D = surfaceDistanceGraph(surfacePath);
[distance,pathCoords] = dijk(D,startCoords,endCoords);
if ~(length(startCoords)==1 && length(endCoords)==1)
    % Convert predecessor indices to path
    pathCoords = pred2path(pathCoords,startCoords,endCoords);
end

end