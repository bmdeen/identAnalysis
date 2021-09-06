
% Wrapper for identROIExtract, across specific search spaces and defining
% contrasts. Currently all CIFTI.

%% Social/spatial, bilateral
% Extract ROI responses in apex network, regions defined with famsemantic
% PersonVsPlace contrast and inverse, across both hemispheres.
searchNames = {'TPJ','TH','TP','ASTS','MPC','MPFC','SFG'};
for s=1:length(searchNames)
    identROIExtract('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'inputSuffix','Sm2');
    identROIExtract('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'invertStats',1,'inputSuffix','Sm2');
end

%% Social/spatial, unilateral
% Extract ROI responses in apex network, regions defined with famsemantic
% PersonVsPlace contrast and inverse, unilaterally.
searchNames = {'LTPJ','LTH','LTP','LASTS','LMPC','LMPFC','LSFG',...
    'RTPJ','RTH','RTP','RASTS','RMPC','RMPFC','RSFG'};
for s=1:length(searchNames)
    identROIExtract('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'inputSuffix','Sm2');
    identROIExtract('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'invertStats',1,'inputSuffix','Sm2');
end

%% Object, bilateral
% Extract ROI responses in object network, regions defined with famsemantic
% PlaceVsObjectInverted contrast, across both hemispheres.
searchNames = {'IFS','Premotor','PF','PHT'};
for s=1:length(searchNames)
    identROIExtract('famsemantic','PlaceVsObject',['mmpObject' searchNames{s}],1,'invertStats',1,'inputSuffix','Sm2');
end

%% ToMLoc, bilateral
% Extract ROI responses in apex network, regions defined with tomloc2
% BeliefVsPhoto
searchNames = {'TPJ','TH','TP','ASTS','MPC','MPFC','SFG'};
for s=1:length(searchNames)
    identROIExtract('tomloc2','BeliefVsPhoto',['mmpApex' searchNames{s}],1,'inputSuffix','Sm2');
end

%% LangLoc
% Extract ROI responses in language network, regions defined with langloc
% SentencesVsNonwords
searchNames = {'mmpApexLTPJ','mmpLngLPostTemp','mmpLngLAntTemp','mmpLngLMFG','mmpLngLIFG'};
for s=1:length(searchNames)
    identROIExtract('langloc','SentencesVsNonwords',searchNames{s},1,'inputSuffix','Sm2');
end

%% Social/spatial, bilateral, across multiple ROI sizes
% Extract ROI responses in apex network, regions defined with famsemantic
% PersonVsPlace contrast and inverse, across both hemispheres.
searchNames = {'TPJ','TH','TP','ASTS','MPC','MPFC','SFG'};
for s=1:length(searchNames)
    identROIExtractBySize('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'inputSuffix','Sm2');
    identROIExtractBySize('famsemantic','PersonVsPlace',['mmpApex' searchNames{s}],1,'invertStats',1,'inputSuffix','Sm2');
end
