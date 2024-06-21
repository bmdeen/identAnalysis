
% Wrapper for identRestSurfConn, to compute seed-based functional
% connectivity maps in individual CIFTI space. TP paper version: uses ROIs
% defined by visual contrast, in social and face processing systems.

bidsDir = '/path/to/data/derivatives/fpp';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};

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

roiSpaceStr = '_space-fsLR_den-32k';
for s=1:length(subjects)
    subjID = subjects{s};
    roiDir = [bidsDir '/sub-' subjID '/roi'];
    for r=1:length(roiDescs)
        seedPath = [roiDir '/sub-' subjID roiSpaceStr '_desc-' roiDescs{r} '_mask.dscalar.nii'];
        identRestSurfConn(seedPath);
        disp(['Finished ' subjID ', ' roiDescs{r}]);
    end
end
