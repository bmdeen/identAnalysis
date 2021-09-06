
% Wrapper script to preprocess IDENT data with FPP

%% Anatomical preproc

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    outputDir = [studyDir '/derivatives/fpp/sub-' subjID];
    for r=1:3
        inputT1Paths{r} = [studyDir '/rawdata/sub-' subjID '/anat/'...
            'sub-' subjID '_run-' fpp.util.numPad(r,2) '_T1w.nii.gz'];
        inputT2Paths{r} = [studyDir '/rawdata/sub-' subjID '/anat/'...
            'sub-' subjID '_run-' fpp.util.numPad(r,2) '_T2w.nii.gz'];
    end
    fpp.anat.preproc(inputT1Paths,inputT2Paths,outputDir);
end


%% Anatomical preproc - High-res coronal images

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    outputDir = [studyDir '/derivatives/fpp/sub-' subjID];
    for r=1:3
        inputCoronalPaths{r} = [studyDir '/rawdata/sub-' subjID '/anat/'...
            'sub-' subjID '_acq-HighResCoronal_run-' fpp.util.numPad(r,2) '_T2w.nii.gz'];
    end
    preprocT2Path = [studyDir '/derivatives/fpp/sub-' subjID '/anat/'...
        'sub-' subjID '_space-individual_res-p8_desc-preproc_T2w.nii.gz'];
    fpp.anat.preprocCoronal(inputCoronalPaths,preprocT2Path);
end


%% HERE: Run recon-all using the below bash command, for each participant.
%
% subject=sub-ident01
% anatDir=${studyDir}/derivatives/fpp/${subject}/anat
% optsFile=${fmriPermPipeDir}/data/recon-all.opts
% export SUBJECTS_DIR=${studyDir}/derivatives/freesurfer
% export FS_LICENSE=${pathToLicenseFileHere}
% 
% recon-all -s ${subject} -i ${anatDir}/${subject}_space-individual_res-p8_desc-preproc_T1w.nii.gz \
%     -all -hires -expert ${optsFile} -T2 ${anatDir}/${subject}_space-individual_res-p8_desc-preproc_T2w.nii.gz \
%     -T2pial -deface


%% Anatomical postproc (run after recon-all)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    inputT1Path = [studyDir '/derivatives/fpp/sub-' subjID '/anat/sub-' subjID...
        '_space-individual_res-p8_desc-preproc_T1w.nii.gz'];
    fsSubDir = [studyDir '/derivatives/freesurfer/sub-' subjID];
    fpp.anat.postproc(subjID,inputT1Path,fsSubDir);
end


%% Field map preproc

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    outputDir = [studyDir '/derivatives/fpp/sub-' subjID];
    for r=1:length(dir([studyDir '/rawdata/sub-' subjID '/fmap/'...
    	'sub-' subjID '_dir-AP_run-*_epi.nii.gz']))
        inputPaths{1} = [studyDir '/rawdata/sub-' subjID '/fmap/'...
        	'sub-' subjID '_dir-AP_run-' fpp.util.numPad(r,2) '_epi.nii.gz'];
        inputPaths{2} = [studyDir '/rawdata/sub-' subjID '/fmap/'...
        	'sub-' subjID '_dir-PA_run-' fpp.util.numPad(r,2) '_epi.nii.gz'];
        fpp.fmap.preproc(inputPaths,outputDir);
    end
end


%% Functional: define template

studyDir = '/path/to/data';
taskEntities = '_task-famvisual_run-01';    % Which task/run to use as template
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    outputDir = [studyDir '/derivatives/fpp/sub-' subjID];
    inputPath = [studyDir '/rawdata/sub-' subjID '/func/'...
        'sub-' subjID taskEntities '_echo-1_sbref.nii.gz'];
    fpp.func.defineTemplate(inputPath,outputDir);
end


%% Functional: register to anat

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    funcTemplatePath = [studyDir '/derivatives/fpp/sub-' subjID '/func/sub-' ...
        subjID '_echo-1_space-session_desc-template_sbref.nii.gz'];
    inputT1Path = [studyDir '/derivatives/fpp/sub-' subjID '/anat/sub-' ...
        subjID '_space-individual_res-p8_desc-preproc_T1w.nii.gz'];
    fsSubDir = [studyDir '/derivatives/freesurfer/sub-' subjID];
    fpp.func.register(subjID,funcTemplatePath,inputT1Path,fsSubDir);
end


%% Functional preproc

studyDir = '/path/to/data';
subjID = 'ident01';     % Run separately for each subject
templateType = 'func';
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc','rest'};
nRuns = [5 5 5 4 6 4 6];

for t=1:length(tasks)
    task = tasks{t};
    taskEntities = ['_task-' task];
    fdCutoff = .5;
    if strcmp(task,'rest'), fdCutoff = .25; end
    for r = 1:nRuns(t)
        for e=1:5
            inputPaths{e} = [studyDir '/rawdata/sub-' subjID '/func/sub-' subjID...
                taskEntities '_run-' fpp.util.numPad(r,2) '_echo-' int2str(e) '_bold.nii.gz'];
        end
        % Tedana parameters
        manAcc = [];
        tedPCA = 'mdl';
        % Certain datasets require less stringent PCA component selection
        % criterion to include BOLD components
        if (strcmp(subjID,'ident03') && strcmp(task,'dyloc') && r==5) ||...
                (strcmp(subjID,'ident05') && strcmp(task,'famsemantic') && r==4) ||...
                (strcmp(subjID,'ident10') && strcmp(task,'tomloc2') && r==4)
            tedPCA = 'aic';
        end
        % In some cases, manual reclassification of components was used to
        % avoid removing potentially BOLD-like signal
        if strcmp(subjID,'ident01') && strcmp(task,'tomloc2') && r==1
            manAcc = [0 1 3 4 7 8 2 5];
        elseif strcmp(subjID,'ident01') && strcmp(task,'tomloc2') && r==4
            manAcc = [0 1 2 6 7 3 4 5 8 9 10 11 12];
        elseif strcmp(subjID,'ident01') && strcmp(task,'langloc') && r==4
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 15 17 22 23 28 30 31 13];
        elseif strcmp(subjID,'ident01') && strcmp(task,'famepisodic') && r==3
            manAcc = [0 2 3 4 5 6 7 8 10 12 14 15 16 17 18 25 26 27 30 1];
        elseif strcmp(subjID,'ident01') && strcmp(task,'famepisodic') && r==4
            manAcc = [0 1 2 3 4 5 6 7 8 9 11 16 19 20 22 23 26 29 9];
        elseif strcmp(subjID,'ident01') && strcmp(task,'rest') && r==2
            manAcc = [0 2 3 8 9 10 12 14 15 17 18 21 25 26 29 30 1 4 5 6 7 11];
        elseif strcmp(subjID,'ident02') && strcmp(task,'dyloc') && r==3
            manAcc = [0 1 2 3 4 5 6 8 12 13 16 17 22 23 26 28 38 43 44 45 48 9 18];
        elseif strcmp(subjID,'ident02') && strcmp(task,'dyloc') && r==6
            manAcc = [0 1 2 3 4 5 6 10 12 13 14 16 17 26 29 31 7];
        elseif strcmp(subjID,'ident02') && strcmp(task,'tomloc2') && r==1
            manAcc = [0 1 2 3 6 9 12 13 14 5 7 8];
        elseif strcmp(subjID,'ident02') && strcmp(task,'tomloc2') && r==3
            manAcc = [0 1 2 3 5 6 7 8 9 10 12 14 18 22 23 29 32 34 40 46 4];
        elseif strcmp(subjID,'ident02') && strcmp(task,'tomloc2') && r==4
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 12 19 21 23 24 26 32 35 36 11];
        elseif strcmp(subjID,'ident02') && strcmp(task,'famsemantic') && r==1
            manAcc = [0 1 2 3 4 5 6 7 12 15 17 9 10];
        elseif strcmp(subjID,'ident02') && strcmp(task,'famepisodic') && r==1
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 11 12 14 20 22 23 25 26 31 36 38 39 41 18 19];
        elseif strcmp(subjID,'ident02') && strcmp(task,'famepisodic') && r==2
            manAcc = [0 1 2 3 4 5 6 7 8 9 11 13 14 15 16 17 18 19 20 23 25 29 37 39 21];
        elseif strcmp(subjID,'ident02') && strcmp(task,'rest') && r==2
            manAcc = [0 1 2 3 4 6 7 8 9 11 12 13 14 24 26 27 33 39 42 43 44 47 5];
        elseif strcmp(subjID,'ident02') && strcmp(task,'rest') && r==3
            manAcc = [2 3 4 5 6 7 8 10 11 12 16 22 24 25 33 34 36 39 0 1 9];
        elseif strcmp(subjID,'ident03') && strcmp(task,'dyloc') && r==2
            manAcc = [0 1 2 3 4 5 6 7 8 12 13 14 9 10];
        elseif strcmp(subjID,'ident03') && strcmp(task,'dyloc') && r==3
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 11 12 14 17 18 19 21 24 26 29 16];
        elseif strcmp(subjID,'ident03') && strcmp(task,'dyloc') && r==5
            manAcc = [5 16 17 18 20 22];
        elseif strcmp(subjID,'ident03') && strcmp(task,'tomloc2') && r==2
            manAcc = [0 1 2 3 13 14 17 21 22 24 25 4];
        elseif strcmp(subjID,'ident04') && strcmp(task,'famsemantic') && r==5
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 11 13 14 15 17 21 25 26 28 30 12];
        elseif strcmp(subjID,'ident05') && strcmp(task,'langloc') && r==2
            manAcc = [0 1 2 3 4 5 7 10 12 16 17 19 22 23 24 28 8 9];
        elseif strcmp(subjID,'ident05') && strcmp(task,'langloc') && r==3
            manAcc = [0 1 3 4 5 6 9 12 13 16 17 18 20 21 25 27 28 7];
        elseif strcmp(subjID,'ident05') && strcmp(task,'tomloc2') && r==1
            manAcc = [0 1 2 3 4 5 8 10 11 12 16 18 22 6];
        elseif strcmp(subjID,'ident05') && strcmp(task,'tomloc2') && r==2
            manAcc = [0 1 2 3 5 6 8 9 12 13 14 15 16 21 23 29 38 4];
        elseif strcmp(subjID,'ident05') && strcmp(task,'tomloc2') && r==3
            manAcc = [0 1 2 3 4 5 7 9 10 11 12 6 8];
        elseif strcmp(subjID,'ident05') && strcmp(task,'tomloc2') && r==4
            manAcc = [0 1 2 3 4 5 6 9 12 13 14 18 20 24 26 27 29 32 7];
        elseif strcmp(subjID,'ident05') && strcmp(task,'famsemantic') && r==4
            manAcc = [0 1 2 3 4 5 6 8 10 15 16 17 7 12];
        elseif strcmp(subjID,'ident05') && strcmp(task,'famepisodic') && r==2
            manAcc = [0 1 3 4 5 6 8 12 13 14 15 16 17 19 25 27 28 29 7];
        elseif strcmp(subjID,'ident05') && strcmp(task,'famepisodic') && r==4
            manAcc = [0 1 2 3 4 5 8 9 13 15 17 18 19 6];
        elseif strcmp(subjID,'ident05') && strcmp(task,'famepisodic') && r==5
            manAcc = [0 1 2 3 4 5 7 11 13 16 18 22 23 26 27 8];
        elseif strcmp(subjID,'ident06') && strcmp(task,'dyloc') && r==2
            manAcc = [0 1 2 3 4 5 6 9 10 12 13 18 19 20 21 23 28 29 31 32 11];
        elseif strcmp(subjID,'ident06') && strcmp(task,'dyloc') && r==6
            manAcc = [0 1 2 3 4 5 6 7 9 10 14 15 16 17 18 21 26 27 28 29 30 31 33 34 35 36 38 13];
        elseif strcmp(subjID,'ident06') && strcmp(task,'famvisual') && r==1
            manAcc = [1 2 3 4 5 6 7 8 17 18 21 22 25 29 30 31 32 33 39 0 16];
        elseif strcmp(subjID,'ident06') && strcmp(task,'famsemantic') && r==1
            manAcc = [0 1 2 3 4 6 7 10 11 14 16 17 20 21 22 24 25 27 29 31 33 34 35 18];
        elseif strcmp(subjID,'ident06') && strcmp(task,'famepisodic') && r==1
            manAcc = [0 1 2 3 4 7 8 9 10 12 14 15 21 24 27 30 31 5];
        elseif strcmp(subjID,'ident07') && strcmp(task,'dyloc') && r==2
            manAcc = [0 1 2 3 4 5 6 7 10 11 13 14 18 19 23 28 29 8 12 15];
        elseif strcmp(subjID,'ident07') && strcmp(task,'langloc') && r==4
            manAcc = [0 1 2 3 4 5 6 9 11 13 15 16 17 19 22 24 25 27 30 34 12];
        elseif strcmp(subjID,'ident07') && strcmp(task,'famvisual') && r==3
            manAcc = [0 2 3 4 5 6 7 8 9 10 11 12 13 15 19 20 27 1];
        elseif strcmp(subjID,'ident07') && strcmp(task,'famvisual') && r==5
            manAcc = [1 2 3 5 7 8 9 10 11 12 13 14 21 25 31 0 4 6];
        elseif strcmp(subjID,'ident07') && strcmp(task,'famsemantic') && r==4
            manAcc = [0 1 2 4 5 6 7 9 12 13 14 17 20 22 26 28 31 3];
        elseif strcmp(subjID,'ident07') && strcmp(task,'famsemantic') && r==5
            manAcc = [0 1 2 3 4 6 8 9 12 17 20 21 22 24 7];
        elseif strcmp(subjID,'ident08') && strcmp(task,'dyloc') && r==1
            manAcc = [0 1 5 7 9 15 16 18 24 25 26 27 28 29 30 2 3 4];
        elseif strcmp(subjID,'ident08') && strcmp(task,'dyloc') && r==4
            manAcc = [0 1 2 3 4 5 7 8 12 13 15 17 20 21 23 25 27 32 34 35 36 37 38 39 40 11];
        elseif strcmp(subjID,'ident08') && strcmp(task,'tomloc2') && r==1
            manAcc = [0 1 2 3 6 9 12 13 14 15 16 17 18 22 25 7];
        elseif strcmp(subjID,'ident08') && strcmp(task,'famsemantic') && r==3
            manAcc = [0 1 2 3 4 6 8 14 16 19 20 22 5 7];
        elseif strcmp(subjID,'ident08') && strcmp(task,'famsemantic') && r==4
            manAcc = [0 1 2 3 4 6 7 8 13 17 5];
        elseif strcmp(subjID,'ident09') && strcmp(task,'tomloc2') && r==1
            manAcc = [0 1 2 3 6 8 9 11 12 13 15 18 22 26 4];
        elseif strcmp(subjID,'ident10') && strcmp(task,'dyloc') && r==1
            manAcc = [0 1 2 3 4 5 6 7 8 9 10 13 15 19 25 26 27 31 35 21];
        elseif strcmp(subjID,'ident10') && strcmp(task,'dyloc') && r==3
            manAcc = [0 1 2 3 4 7 8 14 15 17 19 21 25 27 30 6];
        elseif strcmp(subjID,'ident10') && strcmp(task,'dyloc') && r==6
            manAcc = [0 1 2 4 5 6 7 8 12 16 17 18 21 23 25 30 31 33 34 35 36 38 39 41 43 45 11];
        elseif strcmp(subjID,'ident10') && strcmp(task,'tomloc2') && r==2
            manAcc = [0 1 2 3 6 7 8 9 10 14 15 16 23 25 4 5];
        elseif strcmp(subjID,'ident10') && strcmp(task,'famvisual') && r==3
            manAcc = [1 2 3 4 5 6 7 8 9 10 11 12 15 22 24 31 0];
        elseif strcmp(subjID,'ident10') && strcmp(task,'famsemantic') && r==3
            manAcc = [0 1 2 3 4 5 6 7 8 9 11 14 16 21 24 31 32 33 34 36 13];
        end
        overwrite = 0;
        if ~isempty(manAcc), overwrite = 1; end
        outputDir = [studyDir '/derivatives/fpp/sub-' subjID];
        fpp.func.preproc(inputPaths,outputDir,'fdCutoff',fdCutoff,'templateType',...
            templateType,'tedPCA',tedPCA,'manAcc',manAcc,'overwrite',overwrite);
    end
end



%% Resting data: remove global mean

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
templateSpace = 'session';
taskEntities = '_task-rest';
outputDescAddition = ' Global signal removed via linear regression.';

for s=1:length(subjects)
    subjID = subjects{s};
    for r=1:6
        inputPath = [studyDir '/derivatives/fpp/sub-' subjID '/func/sub-' subjID taskEntities...
            '_run-' fpp.util.numPad(r,2) '_space-' templateSpace '_desc-preproc_bold.nii.gz'];
        outputPath = fpp.bids.changeName(inputPath,'desc','preprocGSR');
        fpp.func.removeNuisance(inputPath,outputPath,'confoundNames',{'global_signal'},...
            'removeBadVols',0,'outputDescription',outputDescAddition,'appendDescription',1);
        disp(['Finished ' subjID ' run ' int2str(r)]);
    end
end


%% Define brainNonZero mask (across tasks/runs)
% Define volumetric brain mask that contains nonzero data in all runs of
% functional data.

studyDir = '/path/to/data';
subjID = 'ident01';
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc','rest'};
nRuns = [5 5 5 4 6 4 6];
space = 'session';
removeBidsDir = @(x) fpp.bids.removeBidsDir(x);

cmd = 'fslmaths ';
outputPath = [studyDir '/derivatives/fpp/sub-' subjID '/func/sub-' subjID...
    '_space-' space '_desc-brainNonZero_mask.nii.gz'];
inputPaths = {};
for t=1:length(tasks)
    for r=1:nRuns(t)
        inputPath = [studyDir '/derivatives/fpp/sub-' subjID '/func/sub-' subjID '_task-' tasks{t}...
            '_run-' fpp.util.numPad(r,2) '_space-' space '_desc-brainNonZero_mask.nii.gz'];
        inputPaths{end+1} = inputPath;
        if r==1 && t==1
            cmd = [cmd inputPath ' '];
        else
            cmd = [cmd '-mul ' inputPath ' '];
        end
    end
end
cmd = [cmd outputPath];
fpp.util.system(cmd);
fpp.bids.jsonReconstruct(inputPaths{1},outputPath);
fpp.bids.jsonChangeValue(outputPath,{'Type','Description','Sources','RawSources','SpatialRef','SkullStripped'},...
    {'Brain','Brain mask intersected with mask of nonzero voxels from all tasks/runs.',...
    cellfun(removeBidsDir,inputPaths,'UniformOutput',false),[],[],[]});


%% Transform brainNonZero from session to individual volume/CIFTI space

% NOTE: This script assumes that cortex is fully sampled, only includes
% zero values in CIFTI mask for subcortex.

studyDir = '/path/to/data';
hemis = {'L','R'};
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};

for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    surfaceROIBasePath = [anatDir '/hemi-L_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
    giftiBasePath = [anatDir '/hemi-L_space-fsLR_den-32k_desc-medialwallAtlas_mask.shape.gii'];
    for h=1:2
        surfacePaths{h} = fpp.bids.changeName(surfaceBasePath,'hemi',hemis{h});
        surfaceROIPaths{h} = fpp.bids.changeName(surfaceROIBasePath,'hemi',hemis{h});
        giftiPaths{h} = fpp.bids.changeName(giftiBasePath,'hemi',hemis{h});
        tmpGiftiPaths{h} = fpp.bids.changeName(giftiPaths{h},'desc','tmpAllOnes0851513498253280');
        fpp.wb.command('metric-math',[],'m*0+1',tmpGiftiPaths{h},['-var m ' giftiPaths{h}]);    % Make metric of all 1's
    end
    session2IndivXfm = [anatDir '/sub-' subjID '_from-session_to-individual_mode-image_xfm.mat'];
    subcortSegFuncResPath = [anatDir '/sub-' subjID '_space-individual_res-2_desc-subcortical_dseg.nii.gz'];
    
    % Input/output mask paths
    maskPath = [funcDir '/sub-' subjID '_space-session_desc-brainNonZero_mask.nii.gz'];
    maskPathIndiv = fpp.bids.changeName(maskPath,{'space','res'},{'individual','2'});
    maskPathCifti = fpp.bids.changeName(maskPathIndiv,'den','32k',[],'.dscalar.nii');
    
    % Move mask from session to individual volumetric space
    fpp.fsl.moveImage(maskPath,subcortSegFuncResPath,maskPathIndiv,session2IndivXfm,'interp','nn');
    
    % Generate CIFTI
    fpp.wb.command('cifti-create-dense-scalar',[],[],maskPathCifti,...
        ['-left-metric ' tmpGiftiPaths{1} ' -roi-left ' surfaceROIPaths{1}...
        ' -right-metric ' tmpGiftiPaths{2} ' -roi-right ' surfaceROIPaths{2}...
        ' -volume ' maskPathIndiv ' ' subcortSegFuncResPath]);
    
    fpp.util.deleteImageAndJson(tmpGiftiPaths);
end


%% Surface-resample functional data

studyDir = '/path/to/data';
hemis = {'L','R'};
surfaces = {'midthickness','white','pial'};
surfDilation = 30;      % Surface dilation distance (mm)
fwhm = 2;               % Surface and subcortical volume smoothing kernel (mm)

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc','rest'};
nRuns = [5 5 5 4 6 4 6];
templateSpace = 'session';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    for h=1:2
        for su=1:3
            inputSurfacePaths{h}{su} = fpp.bids.changeName(surfaceBasePath,'hemi',hemis{h},surfaces{su});
        end
        surfaceROIPaths{h} = [anatDir '/hemi-' hemis{h}...
            '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
        sphereRegFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-reg2fsLR_sphere.surf.gii'];
        midthickFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-32k_midthickness.surf.gii'];
    end
    subcortSegPath = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-subcortical_dseg.nii.gz'];
    subcortSegFuncResPath = [anatDir '/sub-' subjID '_space-individual_res-2_desc-subcortical_dseg.nii.gz'];
    session2IndivXfm = [anatDir '/sub-' subjID '_from-session_to-individual_mode-image_xfm.mat'];
    % Use task-independent mask, so that all CIFTI files have same nonzero grayordinates
    maskPath = [funcDir '/sub-' subjID '_space-' templateSpace '_desc-brainNonZero_mask.nii.gz'];
    
    for t=1:length(tasks)
        task = tasks{t};
        desc = 'preproc';
        if strcmp(task,'rest'), desc = [desc 'GSR']; end
        for r=1:nRuns(t)
            inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' fpp.util.numPad(r,2)...
                '_space-' templateSpace '_desc-' desc '_bold.nii.gz'];
            outputCiftiPath = fpp.bids.changeName(inputPath,{'space','res','den'},...
                {'individual','2','32k'},[],'.dtseries.nii');
            fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIPaths,outputCiftiPath,...
                'premat',session2IndivXfm,'fwhm',fwhm,'surfDilation',surfDilation,...
                'referencePath',subcortSegPath,'referenceFuncResPath',subcortSegFuncResPath,...
                'sphereRegFsLRPaths',sphereRegFsLRPaths,'midthickFsLRPaths',midthickFsLRPaths,...
                'subcortSegPath',subcortSegFuncResPath,'maskPath',maskPath);
            disp(['Finished ' subjID ' ' task ' run ' int2str(r)]);
        end
    end
end


%% Surface-resample resting-state data (cortex only)

studyDir = '/path/to/data';
hemis = {'L','R'};
surfaces = {'midthickness','white','pial'};
surfDilation = 30;      % Surface dilation distance (mm)
fwhm = 2;               % Surface-based smoothing kernel (mm)

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
task = 'rest';
nRuns = 6;
templateSpace = 'session';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    for h=1:2
        for su=1:3
            inputSurfacePaths{h}{su} = fpp.bids.changeName(surfaceBasePath,'hemi',hemis{h},surfaces{su});
        end
        surfaceROIPaths{h} = [anatDir '/hemi-' hemis{h}...
            '_space-fsLR_den-32k_desc-cortexAtlas_mask.shape.gii'];
        sphereRegFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-reg2fsLR_sphere.surf.gii'];
        midthickFsLRPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-32k_midthickness.surf.gii'];
    end
    subcortSegPath = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-subcortical_dseg.nii.gz'];
    session2IndivXfm = [anatDir '/sub-' subjID '_from-session_to-individual_mode-image_xfm.mat'];
    
    for r=1:nRuns
        inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' fpp.util.numPad(r,2)...
            '_space-' templateSpace '_desc-preprocGSR_bold.nii.gz'];
        maskPath = [funcDir '/sub-' subjID '_task-' task '_run-' fpp.util.numPad(r,2)...
            '_space-' templateSpace '_desc-brainNonZero_mask.nii.gz'];
        outputCiftiPath = fpp.bids.changeName(inputPath,{'space','den'},{'fsLR','32k'},[],'.dtseries.nii');
        fpp.func.surfaceResample(inputPath,inputSurfacePaths,surfaceROIPaths,outputCiftiPath,...
            'premat',session2IndivXfm,'referencePath',subcortSegPath,'fwhm',fwhm,'surfDilation',surfDilation,...
            'sphereRegFsLRPaths',sphereRegFsLRPaths,'midthickFsLRPaths',midthickFsLRPaths,'maskPath',maskPath);
        disp(['Finished ' subjID ' run ' int2str(r)]);
    end
end

