
% Wrapper script for identRestDiffusionMap, identRestDiffusionPlot
%
% NOTE: Some of the plotting functionality requires MATLAB >=2021a. If
% you're using an earlier version, the MarkerFaceAlpha and MarkerEdgeAlpha
% flags will need to be removed.

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    identRestDiffusionMap(subjects{s});
    disp(['Computed diffusion embedding for ' subjects{s}]);
end

for s=1:length(subjects)
    identRestDiffusionPlot(subjects{s});
    disp(['Plotted diffusion embedding for ' subjects{s}]);
end