
% Wrapper script for IDENT fMRI analysis - additional analyses for TP paper

%% Volumetric smoothing (visual data)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
space = 'session';
fwhm = 2;
smSuffix = 'Sm2';

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    templateName = ['sub-' subjID '_space-' space '_mask.nii.gz'];
    gmPath = [anatDir '/' fpp.bids.changeName(templateName,'desc','gm')];
    wmPath = [anatDir '/' fpp.bids.changeName(templateName,'desc','wm')];
    csfPath = [anatDir '/' fpp.bids.changeName(templateName,'desc','csf')];
    segmentPaths = {gmPath,wmPath,csfPath};
    for t=1
        task = tasks{t};
        for r=1:nRuns(t)
            inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-' space '_desc-preproc_bold.nii.gz'];
            outputPath = fpp.bids.changeName(inputPath,'desc',['preproc' smSuffix]);
            fpp.util.copyImageAndJson(inputPath,outputPath);
            for se=1:length(segmentPaths)
                fpp.util.smoothInMask(outputPath,segmentPaths{se},fwhm,outputPath);
            end
        end
    end
end


%% Functional modeling: volumetric modelArma (smoothed visual data)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
space = 'session';
smSuffix = 'Sm2';

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    maskPath = [funcDir '/sub-' subjID '_space-' space '_desc-brainNonZero_mask.nii.gz'];
    for t=1
        task = tasks{t};
        for r=1:nRuns(t)
            inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-' space '_desc-preproc' smSuffix '_bold.nii.gz'];
            eventsPath = [studyDir '/rawdata/sub-' subjID '/func/sub-' subjID '_task-'...
                task '_run-' fpp.util.numPad(r,2) '_events.tsv'];
            contrastMatrixPath = [studyDir '/derivatives/fpp/task-' task '_contrastmatrix.tsv'];
            fpp.func.modelArma(inputPath,eventsPath,contrastMatrixPath,...
                'maskPath',maskPath,'outputSuffix',smSuffix);
        end
    end
end


%% Functional modeling: 2nd-level, volumetric Arma (smoothed visual data)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
space = 'session';
descStr = '_desc-Sm2';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    for t=1
        task = tasks{t};
        inputDirs = {};
        for r=1:nRuns(t)
            inputDirs{r} = [analysisDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-' space descStr '_modelarma'];
        end
        fpp.func.model2ndLevel(inputDirs);
    end
end


%% Resample model outputs from session to high-res individual space

studyDir = '/path/to/data';
descStr = '_desc-Sm2';

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
space = 'session';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    
    anatPath = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-preproc_T1w.nii.gz'];
    session2IndivXfm = [anatDir '/sub-' subjID '_from-session_to-individual_mode-image_xfm.mat'];
    
    for t=1
        task = tasks{t};
        featDir = [analysisDir '/sub-' subjID '_task-' task '_space-' space descStr '_model2arma'];
        zStatList = dir([featDir '/*zstat.nii.gz']);
        for f=1:length(zStatList)
            zStatPath = [featDir '/' zStatList(f).name];
            outputPath = fpp.bids.changeName(zStatPath,{'space','res'},{'individual','p8'});
            disp(zStatList(f).name);
            fpp.fsl.moveImage(zStatPath,anatPath,outputPath,session2IndivXfm);
        end
        
    end
end
