
% Wrapper for identRestROICorrelation script. TP paper version: computes
% correlations among TP/PR/STS/IT and other social/face areas.

outputDesc = 'tppaperSocialFaceROIsTop5Pct';

searchNames = {'handDrawnLTP','handDrawnRTP','handDrawnLPRC','handDrawnRPRC',...
    'handDrawnLASTS','handDrawnRASTS','handDrawnLAIT','handDrawnRAIT'...
    'mmpLFus','mmpRFus','mmpLPIT','mmpRPIT','mmpLPSTS','mmpRPSTS',...
    'mmpApexLMPFC','mmpApexRMPFC','mmpApexLMPC','mmpApexRMPC','mmpApexLTPJ','mmpApexRTPJ',...
    'mmpLMSTS','mmpRMSTS','mmpApexLSFG','mmpApexRSFG'};
taskContrast = 'famvisualSm2PersonVsPlace';
roiStr = 'Top5Pct';

for s=1:length(searchNames)
    roiDescs{s} = [searchNames{s} taskContrast roiStr];
end

identRestROICorrelation(roiDescs,outputDesc);
