
% Wrapper for identRestSurfConn, to compute seed-based functional
% connectivity maps in individual CIFTI space.

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

% Functional ROIs
roiDescs = {'mmpApexLSFGfamsemanticSm2PersonVsPlaceTop5Pct','mmpApexLSFGfamsemanticSm2PersonVsPlaceInvertedTop5Pct',...
    'mmpApexLMPCfamsemanticSm2PersonVsPlaceTop5Pct','mmpApexLMPCfamsemanticSm2PersonVsPlaceInvertedTop5Pct'};
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
