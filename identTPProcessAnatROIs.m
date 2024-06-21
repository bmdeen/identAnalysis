
% Scripts to generate hand-drawn TP, PR, aIT, and aSTS ROIs.
%
% Colors for TP, PRC, ASTS, AIT ROIs:
% [170 68 153]
% [136 204 238]
% [221 204 119]
% [153 153 51]

% First step: hand-draw TP and PRC ROIs on individual anatomical images at
% 2mm resolution.

%% Resample hand-modified TP/PR/PHC ROIs to surface and .8mm volume

studyDir = '/path/to/data';
hemis = {'L','R'};
surfaces = {'midthickness','white','pial'};
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
segNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLPHC','handDrawnRTP','handDrawnRPRC','handDrawnRPHC'};
segColors = {[170 68 153],[136 204 238],[170 68 153],[136 204 238]};   % Label colors by ROI type
% Additional colors: IT [153 153 51], STS [221 204 119]
templateSpace = 'individual_res-2';

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    for h=1:2
        for su=1:3
            inputSurfacePaths{h}{su} = fpp.bids.changeName(surfaceBasePath,'hemi',hemis{h},surfaces{su});
        end
        surfaceROIPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-cortexAtlas_mask.shape.gii'];
        surfaceROIFsLRPaths{h} = [anatDir '/hemi-' hemis{h}...
            '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
        sphereRegFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-reg2fsLR_sphere.surf.gii'];
        midthickFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-32k_midthickness.surf.gii'];
    end
    inputT1Path = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-preproc_T1w.nii.gz'];
    
    for r=1:length(segNames)
        
        inputPath = [anatDir '/sub-' subjID '_space-' templateSpace '_desc-' segNames{r} '_mask.nii.gz'];
        
        % Add label text file to volume
        inputDesc = fpp.bids.checkNameValue(inputPath,'desc');
        tmpLUTPath = fpp.bids.changeName(inputPath,'desc',[inputDesc...
            'tmpVolumeResample21093520813502'],'lut','.txt');
        fid = fopen(tmpLUTPath,'w');
        fprintf(fid,'%s\n',segNames{r});
        fprintf(fid,'%d %d %d %d %d\n',[1 segColors{r} 255]);
        fclose(fid);
        fpp.wb.command('volume-label-import',inputPath,tmpLUTPath,inputPath,'-drop-unused-labels');
        
        % Resample to 32k surface
        outputCiftiPath = fpp.bids.changeName(inputPath,{'space','res','den'},...
            {'fsLR',[],'32k'},'dseg','.dlabel.nii');
        fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIFsLRPaths,outputCiftiPath,...
            'sphereRegFsLRPaths',sphereRegFsLRPaths,'midthickFsLRPaths',midthickFsLRPaths,'isLabel',1);
        
        % Resample to native surface
        outputCiftiPath = fpp.bids.changeName(inputPath,{'space','res','den'},...
            {'individual',[],'native'},'dseg','.dlabel.nii');
        outputGiftiPaths{1} = fpp.bids.changeName(inputPath,{'space','res','den','hemi'},...
            {'individual',[],'native','L'},'dseg','.label.gii');
        outputGiftiPaths{2} = fpp.bids.changeName(inputPath,{'space','res','den','hemi'},...
            {'individual',[],'native','R'},'dseg','.label.gii');
        fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIPaths,outputCiftiPath,...
            'isLabel',1,'outputGiftiPaths',outputGiftiPaths);
        
        % Resample from native surface to .8mm volume
        outputPath = fpp.bids.changeName(inputPath,'res','p8');
        for h=1:2
            outputVolPaths{h} = fpp.bids.changeName(outputPath,'hemi',hemis{h},[],'.nii.gz');
        end
        for h=1:2
            fpp.wb.command('label-to-volume-mapping',outputGiftiPaths{h},...
                [inputSurfacePaths{h}{1} ' ' inputT1Path],outputVolPaths{h},['-ribbon-constrained '...
                inputSurfacePaths{h}{2} ' ' inputSurfacePaths{h}{3}]);
        end
        fpp.fsl.maths(outputVolPaths{1},['-add ' outputVolPaths{2}],outputPath);
        fpp.wb.command('volume-label-import',outputPath,tmpLUTPath,outputPath,'-drop-unused-labels');
        fpp.util.deleteImageAndJson([outputVolPaths outputGiftiPaths]);
        fpp.util.system(['rm -rf ' tmpLUTPath]);
        
        disp(['Finished ' subjID ' ' segNames{r}]);
    end
end



%% Generate aIT/aSTS seed ROIs, to draw over

% Define using MMP parcels, with hand-drawn TP/PR ROIs subtracted.

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
searchNames = {'AIT','ASTS'};
hdNames = {'handDrawnLTP','handDrawnLPRC','handDrawnRTP','handDrawnRPRC'};
prefices = {'L','R',''};
spaces = {'individual_res-2'};
inputExts = {'.nii.gz'};
outputExts = {'.nii.gz'};
imageTypes = {'volume'};

% aIT: TE1a
searchInds{1}{1} = 312;
searchInds{1}{2} = 132;

% aSTS: STSda, STSva
searchInds{2}{1} = [308 356];
searchInds{2}{2} = [128 176];

% Add indices for bilateral regions
for r=1:length(searchInds), searchInds{r}{3} = [searchInds{r}{1} searchInds{r}{2}]; end

% Define search space ROIs
for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    for sp=1:length(spaces)
        subjStr = ['sub-' subjID '_'];
        if strcmp(spaces{sp}(1:4),'fsLR')
            subjStr = '';
        end
        parcPath = [anatDir '/' subjStr 'space-' spaces{sp} '_desc-MMP_dseg' inputExts{sp}];
        for r=1:length(hdNames)
            hdPaths{r} = [anatDir '/' subjStr 'space-' spaces{sp}...
                '_desc-' hdNames{r} '_mask' inputExts{sp}];
        end
        for r=1:length(searchNames)
            for h=1:3
                outputDesc = ['mmp' prefices{h} searchNames{r}];
                outputPath = fpp.bids.changeName(parcPath,'desc',outputDesc,'mask',outputExts{sp});
                if exist(outputPath,'file'), continue; end
                parcInds = searchInds{r}{h};
                fpp.util.label2ROI(parcPath,parcInds,outputPath);
                % Subtract TP/PR ROIs.
                fpp.fsl.maths(outputPath,['-sub ' hdPaths{1} ' -sub ' hdPaths{2}...
                    ' -sub ' hdPaths{3} ' -sub ' hdPaths{4} ' -bin'],outputPath);
                disp(['Wrote ' subjID ' - ' outputDesc '_space-' spaces{sp}]);
            end
        end
    end
end



%% Resample hand-modified aIT/aSTS ROIs to surface and .8mm volume

studyDir = '/path/to/data';
hemis = {'L','R'};
surfaces = {'midthickness','white','pial'};
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
segNames = {'handDrawnLASTS','handDrawnLAIT','handDrawnRASTS','handDrawnRAIT'};
segColors = {[221 204 119],[153 153 51],[221 204 119],[153 153 51]};   % Label colors by ROI type
templateSpace = 'individual_res-2';

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    for h=1:2
        for su=1:3
            inputSurfacePaths{h}{su} = fpp.bids.changeName(surfaceBasePath,'hemi',hemis{h},surfaces{su});
        end
        surfaceROIPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-cortexAtlas_mask.shape.gii'];
        surfaceROIFsLRPaths{h} = [anatDir '/hemi-' hemis{h}...
            '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
        sphereRegFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-reg2fsLR_sphere.surf.gii'];
        midthickFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-32k_midthickness.surf.gii'];
    end
    inputT1Path = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-preproc_T1w.nii.gz'];
    
    for r=1:length(segNames)
        
        inputPath = [anatDir '/sub-' subjID '_space-' templateSpace '_desc-' segNames{r} '_mask.nii.gz'];
        
        % Add label text file to volume
        inputDesc = fpp.bids.checkNameValue(inputPath,'desc');
        tmpLUTPath = fpp.bids.changeName(inputPath,'desc',[inputDesc...
            'tmpVolumeResample21093520813502'],'lut','.txt');
        fid = fopen(tmpLUTPath,'w');
        fprintf(fid,'%s\n',segNames{r});
        fprintf(fid,'%d %d %d %d %d\n',[1 segColors{r} 255]);
        fclose(fid);
        fpp.wb.command('volume-label-import',inputPath,tmpLUTPath,inputPath,'-drop-unused-labels');
        
        % Resample to 32k surface
        outputCiftiPath = fpp.bids.changeName(inputPath,{'space','res','den'},...
            {'fsLR',[],'32k'},'dseg','.dlabel.nii');
        fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIFsLRPaths,outputCiftiPath,...
            'sphereRegFsLRPaths',sphereRegFsLRPaths,'midthickFsLRPaths',midthickFsLRPaths,'isLabel',1);
        
        % Resample to native surface
        outputCiftiPath = fpp.bids.changeName(inputPath,{'space','res','den'},...
            {'individual',[],'native'},'dseg','.dlabel.nii');
        outputGiftiPaths{1} = fpp.bids.changeName(inputPath,{'space','res','den','hemi'},...
            {'individual',[],'native','L'},'dseg','.label.gii');
        outputGiftiPaths{2} = fpp.bids.changeName(inputPath,{'space','res','den','hemi'},...
            {'individual',[],'native','R'},'dseg','.label.gii');
        fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIPaths,outputCiftiPath,...
            'isLabel',1,'outputGiftiPaths',outputGiftiPaths);
        
        % Resample from native surface to .8mm volume
        outputPath = fpp.bids.changeName(inputPath,'res','p8');
        for h=1:2
            outputVolPaths{h} = fpp.bids.changeName(outputPath,'hemi',hemis{h},[],'.nii.gz');
        end
        for h=1:2
            fpp.wb.command('label-to-volume-mapping',outputGiftiPaths{h},...
                [inputSurfacePaths{h}{1} ' ' inputT1Path],outputVolPaths{h},['-ribbon-constrained '...
                inputSurfacePaths{h}{2} ' ' inputSurfacePaths{h}{3}]);
        end
        fpp.fsl.maths(outputVolPaths{1},['-add ' outputVolPaths{2}],outputPath);
        fpp.wb.command('volume-label-import',outputPath,tmpLUTPath,outputPath,'-drop-unused-labels');
        fpp.util.deleteImageAndJson([outputVolPaths outputGiftiPaths]);
        fpp.util.system(['rm -rf ' tmpLUTPath]);
        
        disp(['Finished ' subjID ' ' segNames{r}]);
    end
end



%% Fill holes and remove islands in ROIs, generate border files

studyDir = '/path/to/data';
hemis = {'L','R'};
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
segNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLPHC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT','handDrawnRPHC'};
segHemis = [1 1 1 1 1 2 2 2 2 2];
spaces = {'individual_den-native','fsLR_den-32k'};
dens = {'native','32k'};

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    
    for sp=1:length(spaces)
    
        % Define anatomical paths
        for h=1:2
            surfacePaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h} '_space-'...
                strrep(spaces{sp},'fsLR','individual') '_midthickness.surf.gii'];
            if strcmpi(dens{sp},'32k')
                surfaceROIPaths{h} = [anatDir '/hemi-' hemis{h}...
                    '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
            else
                surfaceROIPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
                    '_space-' spaces{sp} '_desc-cortexAtlas_mask.shape.gii'];
            end
        end
        
        for r=1:length(segNames)
            
            % Input ROI path
            roiPath = [anatDir '/sub-' subjID '_space-' spaces{sp} '_desc-' segNames{r} '_dseg.dlabel.nii'];
            
            % Define intermediate/output paths
            roiScalarPath = fpp.bids.changeName(roiPath,[],[],'mask','.dscalar.nii');
            roiLUTPath = fpp.bids.changeName(roiScalarPath,[],[],'lut','.txt');
            for h=1:2
                roiMetricPaths{h} = fpp.bids.changeName(roiPath,'hemi',hemis{h},'mask','.shape.gii');
            end
            roiBorderPath = fpp.bids.changeName(roiPath,'hemi',hemis{segHemis(r)},[],'.border');
            
            % Split into metric files to apply metric-fill-hole, then recombine
            fpp.wb.command('cifti-label-export-table',roiPath,'1',roiLUTPath);
            fpp.wb.command('cifti-label-to-roi',roiPath,[],roiScalarPath,'-map 1 -key 1');
            fpp.wb.command('cifti-separate',roiScalarPath,'COLUMN',[],['-metric CORTEX_LEFT '...
                roiMetricPaths{1} ' -metric CORTEX_RIGHT ' roiMetricPaths{2}]);
            fpp.wb.command('metric-fill-holes',surfacePaths{segHemis(r)},...
                roiMetricPaths{segHemis(r)},roiMetricPaths{segHemis(r)});
            fpp.wb.command('metric-remove-islands',surfacePaths{segHemis(r)},...
                roiMetricPaths{segHemis(r)},roiMetricPaths{segHemis(r)});
            fpp.wb.command('cifti-create-dense-scalar',[],[],roiScalarPath,['-left-metric '...
                roiMetricPaths{1} ' -roi-left ' surfaceROIPaths{1} ' -right-metric '...
                roiMetricPaths{2} ' -roi-right ' surfaceROIPaths{2}]);
            fpp.wb.command('cifti-label-import',roiScalarPath,roiLUTPath,roiPath);
            
            % Convert label to border file
            fpp.wb.command('cifti-label-to-border',roiPath,[],[],['-border '...
                surfacePaths{segHemis(r)} ' ' roiBorderPath]);
            
            fpp.util.deleteImageAndJson([{roiScalarPath,roiLUTPath} roiMetricPaths]);
            fpp.util.system(['rm -rf ' roiLUTPath]);
            
            disp(['Finished ' subjID ' ' segNames{r}]);
        end
    end
end



%% Convert TP/PR/PHC/STS/IT ROIs from dlabel to dscalar for roiExtract

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
segNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLPHC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT','handDrawnRPHC'};
spaces = {'individual_den-native','fsLR_den-32k'};

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    
    for sp=1:length(spaces)
        
        for r=1:length(segNames)
            
            % Input ROI path
            roiPath = [anatDir '/sub-' subjID '_space-' spaces{sp} '_desc-' segNames{r} '_dseg.dlabel.nii'];
            
            % Output path
            outputPath = fpp.bids.changeName(roiPath,[],[],'mask','.dscalar.nii');
            
            fpp.wb.command('cifti-label-to-roi',roiPath,[],outputPath,'-key 1');
            
            disp(['Finished ' subjID ' ' segNames{r}]);
        end
    end
end



%% Combine left/right hemisphere dscalar files

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
segNames = {'TP','PRC','PHC','ASTS','AIT'};
spaces = {'individual_den-native','fsLR_den-32k'};

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    
    for sp=1:length(spaces)
        
        for r=1:length(segNames)
            
            outputPath = [anatDir '/sub-' subjID '_space-' spaces{sp} '_desc-handDrawn' segNames{r} '_mask.dscalar.nii'];
            roiLPath = fpp.bids.changeName(outputPath,'desc',['handDrawnL' segNames{r}]);
            roiRPath = fpp.bids.changeName(outputPath,'desc',['handDrawnR' segNames{r}]);
            
            fpp.wb.command('cifti-math','a+b',[],outputPath,['-var a ' roiLPath ' -var b ' roiRPath]);
            
            disp(['Finished ' subjID ' ' segNames{r}]);
        end
    end
end



%% Create and threshold probability map across participants of surface-based hand-drawn TP/PR/PHC ROIs

studyDir = '/path/to/data';
groupDir = [studyDir '/derivatives/fpp/group'];
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
%segNames = {'handDrawnLTP','handDrawnLPRC','handDrawnLPHC','handDrawnRTP','handDrawnRPRC','handDrawnRPHC'};
% NOTE: PHC not converted from dlabel to dscalar
segNames = {'handDrawnLTP','handDrawnLPRC','handDrawnRTP','handDrawnRPRC'};
fwhmSm = 3;   % Gradient smoothing kernel FWHM in mm
sigmaSm = fwhmSm/2.355; % Standard deviation of Gaussian kernel
probThresh = .7;
probThreshStr = 'P6';

for r=1:length(segNames)
    outputPath = [groupDir '/space-fsLR_den-32k_desc-' segNames{r} '_probseg.dscalar.nii'];
    outputPathSm = [groupDir '/space-fsLR_den-32k_desc-' segNames{r} 'Sm' int2str(fwhmSm) '_probseg.dscalar.nii'];
    outputPathThr = [groupDir '/space-fsLR_den-32k_desc-' segNames{r} 'Thr' probThreshStr '_mask.dscalar.nii'];
    
    % Sum ROIs across subjects to define probability map
    mathString = '(';
    varString = '';
    for s=1:length(subjects)
        subjID = subjects{s};
        anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];

        inputPath = [anatDir '/sub-' subjID '_space-fsLR_den-32k_desc-' segNames{r} '_mask.dscalar.nii'];
        if s==1
            mathString = [mathString 'r' int2str(s)];
        else
            mathString = [mathString ' + r' int2str(s)];
        end
        varString = [varString ' -var r' int2str(s) ' ' inputPath];
    end
    mathString = [mathString ')/' int2str(length(subjects))];
    fpp.wb.command('cifti-math',mathString,[],outputPath,varString);
    
    % Smooth probmap, using ident01 midthickness surface
    hemis = {'L','R'};
    for h=1:2
        anatDir = [studyDir '/derivatives/fpp/sub-ident01/anat'];
        surfacePaths{h} = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den'},...
            {'ident01',hemis{h},'individual','32k'},'midthickness','.surf.gii')];
    end
    fpp.wb.command('cifti-smoothing',outputPath,[num2str(sigmaSm) ' '...
        num2str(sigmaSm) ' COLUMN'],outputPathSm,['-left-surface '...
        surfacePaths{1} ' -right-surface ' surfacePaths{2}]);
    
    % Threshold probmap
    mathString = ['r > ' num2str(probThresh)];
    varString = [' -var r ' outputPathSm];
    fpp.wb.command('cifti-math',mathString,[],outputPathThr,varString);

    disp(['Wrote ' segNames{r}]);
end
