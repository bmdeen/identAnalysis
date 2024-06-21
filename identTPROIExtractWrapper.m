
% Wrapper for identROIExtract, across specific search spaces and defining
% contrasts for the TP paper.

%% Main areas of interest: TP, PRC, aSTS, aIT
searchNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT'};
for s=1:length(searchNames)
    identTPROIExtract('famvisual','PersonVsPlace',searchNames{s},1,'inputSuffix','Sm2');
end

%% Main ROIs by size

searchNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT'};
for s=1:length(searchNames)
    identTPROIExtractBySize('famvisual','PersonVsPlace',searchNames{s},1,'inputSuffix','Sm2');
end

%% Face processing areas

searchNames = {'mmpLFus','mmpLPIT','mmpLPSTS','mmpRFus','mmpRPIT','mmpRPSTS'};
for s=1:length(searchNames)
    identTPROIExtract('famvisual','PersonVsPlace',searchNames{s},1,'inputSuffix','Sm2');
end

%% Social cognition areas

searchNames = {'mmpApexLTPJ','mmpApexLMPFC','mmpApexLMPC','mmpApexLSFG','mmpLMSTS',...
    'mmpApexRTPJ','mmpApexRMPFC','mmpApexRMPC','mmpApexRSFG','mmpRMSTS'};
for s=1:length(searchNames)
    identTPROIExtract('famvisual','PersonVsPlace',searchNames{s},1,'inputSuffix','Sm2');
end

%% Main areas of interest: TP, PRC (face versus object definition)
searchNames = {'handDrawnLTP','handDrawnLPRC',...
    'handDrawnRTP','handDrawnRPRC'};
for s=1:length(searchNames)
    identTPROIExtract('famvisual','PersonVsObject',searchNames{s},1,'inputSuffix','Sm2');
end