
% Function to define surface mask of coordinates within cortical apex, and
% border around those coordinates.

function identRestDiffusionApexMask(subjID)

% Diffusion gradient threshold
diffusionPctThresh = 70;    % Percentile threshold for apex network definition
diffusionSuffix = ['ThreshTop' int2str(100-diffusionPctThresh) 'Pct'];
rotationAngle = 15;     % Apply this manual rotation (degrees CCW) to top
                        % two gradient dirs to align apex grad with y-axis

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
subjDir = [bidsDir '/sub-' subjID];
analysisDir = [subjDir '/analysis'];
anatDir = [subjDir '/anat'];
spaceStr = '_space-fsLR_den-32k';
diffusionDir = [analysisDir '/sub-' subjID '_task-rest' spaceStr '_diffusion'];
diffusionMatPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr '_DiffusionData.mat'];
%apexGradientPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr '_desc-GradientStd2_diffusionmap.dscalar.nii'];
apexGradientRotPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr '_desc-GradientStd2Rotated_diffusionmap.dscalar.nii'];
fwhmSm = 8;   % Gradient smoothing kernel FWHM in mm
sigmaSm = fwhmSm/2.355; % Standard deviation of Gaussian kernel
apexGradientRotSmPath = fpp.bids.changeName(apexGradientRotPath,'desc',['GradientStd2RotatedSm' int2str(fwhmSm)]);
exampleLabelPath = [anatDir '/space-fsLR_den-32k_desc-mmpApexMPC_dseg.dlabel.nii'];
exampleScalarPath = [anatDir '/' spaceStr(2:end) '_desc-mmpApexASTS_mask.dscalar.nii'];
apexLabelPath = [diffusionDir '/sub-' subjID spaceStr '_desc-RestDiffusionApexNetwork' diffusionSuffix '_dseg.dlabel.nii'];
apexScalarPath = [diffusionDir '/sub-' subjID spaceStr '_desc-RestDiffusionApexNetwork' diffusionSuffix '_mask.dscalar.nii'];
apexLUTPath = fpp.bids.changeName(apexScalarPath,[],[],'lut','.txt');
hemis = {'L','R'};
for h=1:2
    surfacePaths{h} = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den'},...
        {subjID,hemis{h},'individual','32k'},'midthickness','.surf.gii')];
    apexBorderPaths{h} = fpp.bids.changeName(apexLabelPath,'hemi',hemis{h},[],'.border');
    apexMetricPaths{h} = fpp.bids.changeName(apexLabelPath,'hemi',hemis{h},'mask','.shape.gii');
    cortexMaskPaths{h} = [anatDir '/hemi-' hemis{h} '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
end

% Write rotated gradient file
[~,hdr] = fpp.util.readDataMatrix(exampleScalarPath);
d = load(diffusionMatPath);
diffmapStd = d.diffmapStd;
R = [cosd(rotationAngle) -sind(rotationAngle) 0; sind(rotationAngle) cosd(rotationAngle) 0; 0 0 1];
diffmapRot = diffmapStd*R';
apexGradVec = diffmapRot(:,2);
fpp.util.writeDataMatrix(apexGradVec,hdr,apexGradientRotPath);
diffusionThresh = prctile(apexGradVec,diffusionPctThresh);

% Smooth apex gradient
fpp.wb.command('cifti-smoothing',apexGradientRotPath,[num2str(sigmaSm) ' '...
    num2str(sigmaSm) ' COLUMN'],apexGradientRotSmPath,['-left-surface '...
    surfacePaths{1} ' -right-surface ' surfacePaths{2}]);

% Load apex gradient, define apex network mask
apexGradVec = fpp.util.readDataMatrix(apexGradientRotSmPath);
apexMaskVec = apexGradVec>diffusionThresh;

% Load example dlabel file
[~,hdr] = fpp.util.readDataMatrix(exampleLabelPath);
% Write mask to dlabel file
fpp.util.writeDataMatrix(apexMaskVec,hdr,apexLabelPath);

% Split into metric files to apply metric-fill-hole, then recombine
fpp.wb.command('cifti-label-to-roi',apexLabelPath,[],apexScalarPath,'-map 1 -key 1');
fpp.wb.command('cifti-separate',apexScalarPath,'COLUMN',[],['-metric CORTEX_LEFT '...
    apexMetricPaths{1} ' -metric CORTEX_RIGHT ' apexMetricPaths{2}]);
for h=1:2
    fpp.wb.command('metric-fill-holes',surfacePaths{h},apexMetricPaths{h},apexMetricPaths{h});
end
fpp.wb.command('cifti-create-dense-scalar',[],[],apexScalarPath,['-left-metric '...
    apexMetricPaths{1} ' -roi-left ' cortexMaskPaths{1} ' -right-metric '...
    apexMetricPaths{2} ' -roi-right ' cortexMaskPaths{2}]);
fpp.wb.command('cifti-label-export-table',apexLabelPath,'1',apexLUTPath);
fpp.wb.command('cifti-label-import',apexScalarPath,apexLUTPath,apexLabelPath);

% Convert label to border files
fpp.wb.command('cifti-label-to-border',apexLabelPath,[],[],['-border ' surfacePaths{1}...
    ' ' apexBorderPaths{1} ' -border ' surfacePaths{2} ' ' apexBorderPaths{2}]);

end
