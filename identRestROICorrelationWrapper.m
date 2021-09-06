
% Wrapper for identRestROICorrelation script

% All social/spatial ROIs, Top 5pct
outputDesc = 'mmpSocialSpatialROIsTop5Pct';

% Search space names for social network
searchNames{1} = {'mmpApexLMPFC','mmpApexRMPFC','mmpApexLMPC','mmpApexRMPC',...
    'mmpApexLTPJ','mmpApexRTPJ','mmpApexLASTS','mmpApexRASTS',...
    'mmpApexLSFG','mmpApexRSFG','mmpApexLTP','mmpApexRTP'};
% Search space names for spatial network
searchNames{2} = {'mmpApexLMPFC','mmpApexRMPFC','mmpApexLMPC','mmpApexRMPC',...
    'mmpApexLTPJ','mmpApexRTPJ','mmpApexLSFG','mmpApexRSFG','mmpApexLTH','mmpApexRTH'};
taskContrasts = {'famsemanticSm2PersonVsPlace','famsemanticSm2PersonVsPlaceInverted'};
roiStr = 'Top5Pct';
roiDescs = {};

for s=1:length(searchNames)
    for r=1:length(searchNames{s})
        roiDescs{end+1} = [searchNames{s}{r} taskContrasts{s} roiStr];
    end
end

identRestROICorrelation(roiDescs,outputDesc);