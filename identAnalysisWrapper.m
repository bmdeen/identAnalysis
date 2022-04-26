
% Wrapper script for IDENT fMRI analysis

%% Functional modeling: volumetric modelArma

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
space = 'session';

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    maskPath = [funcDir '/sub-' subjID '_space-' space '_desc-brainNonZero_mask.nii.gz'];
    for t=1:length(tasks)
        task = tasks{t};
        for r=1:nRuns(t)
            inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-' space '_desc-preproc_bold.nii.gz'];
            eventsPath = [studyDir '/rawdata/sub-' subjID '/func/sub-' subjID '_task-'...
                task '_run-' fpp.util.numPad(r,2) '_events.tsv'];
            contrastMatrixPath = [studyDir '/derivatives/fpp/task-' task '_contrastmatrix.tsv'];
            fpp.func.modelArma(inputPath,eventsPath,contrastMatrixPath,'maskPath',maskPath);
        end
    end
end


%% Functional modeling: CIFTI modelArma

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
smSuffix = 'Sm2';

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    for t=1:length(tasks)
        task = tasks{t};
        for r=1:nRuns(t)
            inputPath = [funcDir '/sub-' subjID '_task-' task '_run-' fpp.util.numPad(r,2)...
                '_space-individual_res-2_den-32k_desc-preproc' smSuffix '_bold.dtseries.nii'];
            eventsPath = [studyDir '/rawdata/sub-' subjID '/func/sub-' subjID '_task-'...
                task '_run-' fpp.util.numPad(r,2) '_events.tsv'];
            contrastMatrixPath = [studyDir '/derivatives/fpp/task-' task '_contrastmatrix.tsv'];
            fpp.func.modelArma(inputPath,eventsPath,contrastMatrixPath,'outputSuffix',smSuffix);
        end
    end
end


%% Functional modeling: 2nd-level, volumetric Arma

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
space = 'session';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    for t=1:length(tasks)
        task = tasks{t};
        inputDirs = {};
        for r=1:nRuns(t)
            inputDirs{r} = [analysisDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-' space '_modelarma'];
        end
        fpp.func.model2ndLevel(inputDirs);
    end
end


%% Functional modeling: 2nd-level, CIFTI Arma

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
descStr = '_desc-Sm2';

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    for t=1:length(tasks)
        task = tasks{t};
        inputDirs = {};
        for r=1:nRuns(t)
            inputDirs{r} = [analysisDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-individual_res-2_den-32k' descStr '_modelarma'];
        end
        fpp.func.model2ndLevel(inputDirs);
    end
end


%% Functional modeling: 2nd-level, CIFTI Arma, across vis/sem/epi tasks (runs 2 and 4)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic'};
runList = [2 4];
descStr = '_desc-Sm2';
outputTask = 'famcombined';
outputSuffix = 'r2r4';
contrastNames = {'PersonVsPlace','PersonVsObject','PlaceVsObject'};

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    inputDirs = {};
    for t=1:length(tasks)
        task = tasks{t};
        for r=runList
            inputDirs{end+1} = [analysisDir '/sub-' subjID '_task-' task '_run-' ...
                fpp.util.numPad(r,2) '_space-individual_res-2_den-32k' descStr '_modelarma'];
        end
    end
    fpp.func.model2ndLevel(inputDirs,'outputTask',outputTask,'outputSuffix',...
        outputSuffix,'contrastNames',contrastNames);
end


%% Check FDR thresholds for PersonVsPlace, across famvisual/semantic/episodic.
% Note: this step is not necessary, just a check.

studyDir = '/path/to/data';
inputSpaceStr = 'space-individual_res-2_den-32k_desc-Sm2';
analysisType = 'arma';
fdrThresh = .01;
contrastName = 'PersonVsPlace';

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic'};

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    
    for t=1:length(tasks)
        task = tasks{t};
        model2Dir = [analysisDir '/sub-' subjID '_task-' task '_' inputSpaceStr '_model2arma'];
        fdrDesc = ['FDR' strrep(num2str(fdrThresh),'.','p')];
        fdrPath = [model2Dir '/sub-' subjID '_task-' task '_' inputSpaceStr contrastName fdrDesc '_fdrthresh'];
        zThresh(s,t) = load(fdrPath);
    end
end


%% CIFTI-resample model outputs: 32k, 2mm to native, .8mm (for visualization)

studyDir = '/path/to/data';
hemis = {'L','R'};
surfaces = {'midthickness','sphere'};
densities = {'32k','native'};
inputSpaceStr = 'space-individual_res-2_den-32k_desc-Sm2';
analysisType = 'arma';
fdrThresh = [.05 .01];

subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};

for s=1:length(subjects)
    subjID = subjects{s};
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    funcDir = [studyDir '/derivatives/fpp/sub-' subjID '/func'];
    
    % Define anatomical paths
    surfaceBasePath = [anatDir '/sub-' subjID '_hemi-R_space-individual_den-native_midthickness.surf.gii'];
    for h=1:2
        for su=1:length(surfaces)
            for d=1:length(densities)
                if strcmp(surfaces{su},'sphere') && strcmp(densities{d},'32k')
                    surfacePaths{h}{su}{d} = fpp.bids.changeName(surfaceBasePath,...
                        {'hemi','den','sub','space'},{hemis{h},densities{d},[],'fsLR'},surfaces{su});
                elseif strcmp(surfaces{su},'sphere') && strcmp(densities{d},'native')
                    surfacePaths{h}{su}{d} = fpp.bids.changeName(surfaceBasePath,...
                        {'hemi','den','desc'},{hemis{h},densities{d},'reg2fsLR'},surfaces{su});
                else
                    surfacePaths{h}{su}{d} = fpp.bids.changeName(surfaceBasePath,...
                        {'hemi','den'},{hemis{h},densities{d}},surfaces{su});
                end
            end
        end
        surfaceROIPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_desc-cortexAtlas_mask.shape.gii'];
        templateSurfPaths{h} = [anatDir '/sub-' subjID '_hemi-' hemis{h}...
            '_space-individual_den-native_thickness.shape.gii'];
    end
    subcortSegPath = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-subcortical_dseg.nii.gz'];
    
    templatePath = fpp.bids.changeName(surfaceBasePath,{'res','desc'},...
        {'p8','tmpResample10935173487'},'template','.dscalar.nii');
    templateVolPath = [anatDir '/sub-' subjID '_space-individual_res-p8_desc-preprocBrain_T1w.nii.gz'];
    fpp.wb.command('cifti-create-dense-scalar',[],[],templatePath,['-volume ' templateVolPath...
        ' ' subcortSegPath ' -left-metric ' templateSurfPaths{1} ' -roi-left ' surfaceROIPaths{1}...
        ' -right-metric ' templateSurfPaths{2} ' -roi-right ' surfaceROIPaths{2}]);
    
    for t=1:length(tasks)
        task = tasks{t};
        model2Dir = [analysisDir '/sub-' subjID '_task-' task '_' inputSpaceStr '_model2arma'];
        contrastList = dir([model2Dir '/*contrast.dscalar.nii']);
        for f=1:length(contrastList)
            zStatName = fpp.bids.changeName(contrastList(f).name,[],[],'zstat');
            zStatPath = [model2Dir '/' zStatName];
            zStatDesc = fpp.bids.checkNameValue(zStatName,'desc');
            outputCiftiPath = fpp.bids.changeName(zStatPath,{'res','den'},{'p8','native'},[],'.dscalar.nii');
            fpp.wb.command('cifti-resample',zStatPath,['COLUMN ' templatePath ' COLUMN ADAP_BARY_AREA TRILINEAR'],...
                outputCiftiPath,['-left-spheres ' surfacePaths{1}{2}{1} ' ' surfacePaths{1}{2}{2}...
                ' -left-area-surfs ' surfacePaths{1}{1}{1} ' ' surfacePaths{1}{1}{2}...
                ' -right-spheres ' surfacePaths{2}{2}{1} ' ' surfacePaths{2}{2}{2}...
                ' -right-area-surfs ' surfacePaths{2}{1}{1} ' ' surfacePaths{2}{1}{2}]);
            fpp.wb.command('cifti-palette',outputCiftiPath,'MODE_USER_SCALE',outputCiftiPath,...
                '-pos-user 3 6 -neg-user -3 -6 -palette-name FSL -disp-pos true');
            disp(zStatName);
            for fd = 1:length(fdrThresh)
                fdrDesc = [zStatDesc 'FDR' strrep(num2str(fdrThresh(fd)),'.','p')];
                outputCiftiFDRPath = fpp.bids.changeName(outputCiftiPath,'desc',fdrDesc);
                zThreshPath = fpp.bids.changeName(zStatPath,'desc',fdrDesc,'fdrthresh','');
                zThresh = load(zThreshPath);
                if zThresh==Inf, continue; end
                % Old method: zero out values below threshold
%                 fpp.wb.command('cifti-math',[],['z*((z>' num2str(zThresh) ')+(z<' num2str(-zThresh) '))'],...
%                     outputCiftiFDRPath,['-var z ' outputCiftiPath]);
                % New method: set wb_view threshold, but leave values, so
                % that zeros aren't interpolated into data in wb_view.
                fpp.wb.command('cifti-palette',outputCiftiPath,'MODE_USER_SCALE',outputCiftiFDRPath,...
                    ['-thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE -'...
                    num2str(zThresh) ' ' num2str(zThresh)]);
                disp(['FDR' num2str(fdrThresh(fd)) ': Z > ' num2str(zThresh)]);
            end
        end
        
    end
    
    fpp.util.deleteImageAndJson(templatePath);
end


%% Define search spaces (session/indiv) - mmpApex, mmpObject, mmpLng

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
searchNames = {'TPJ','TH','TP','ASTS','MPC','MPFC','SFG','IFS','Premotor','PF','PHT',...
    'PostTemp','AntTemp','MFG','IFG'};
[networkNames{1:7}] = deal('Apex'); % Network association
[networkNames{8:11}] = deal('Object');
[networkNames{12:15}] = deal('Lng');
networkNameOptions = unique(networkNames);
for i=1:length(networkNameOptions)
    networkInds{i} = find(strcmpi(networkNames,networkNameOptions{i}));
end
prefices = {'L','R',''};
spaces = {'session','fsLR_den-32k'};
inputExts = {'.nii.gz','.dlabel.nii'};
outputExts = {'.nii.gz','.dscalar.nii'};
imageTypes = {'volume','cifti'};

% ALL SEARCH SPACE MULTIMODAL PARCELLATION INDICES
% APEX NETWORK
% TPJ: PFm, PGi, PGs
searchInds{1}{1} = [329 330 331];     % left hem
searchInds{1}{2} = [149 150 151];     % right hem
% TH: PHA1, 2, 3
searchInds{2}{1} = [306 335 307];
searchInds{2}{2} = [126 155 127];
% TP: TGd
searchInds{3}{1} = 311;
searchInds{3}{2} = 131;
% ASTS: STSda, STSva, TE1a, STSdp, STSvp, TE1m
searchInds{4}{1} = [308 356 312 309 310 357];
searchInds{4}{2} = [128 176 132 129 130 177];
% MPC: RSC, POS1, v23ab, 7m, PCV, 31pv, 31pd, d23ab, 31a, 23d
searchInds{5}{1} = [194 211 213 210 207 215 341 214 342 212];
searchInds{5}{2} = [14 31 33 30 27 35 161 34 162 32];
% MPFC: 8BM, a32pr, p24, d32, 9m, a24, p32, 10d, 25, s32, 10r, 10v
searchInds{6}{1} = [243 359 360 242 249 241 244 252 344 345 245 268];
searchInds{6}{2} = [63 179 180 62 69 61 64 72 164 165 65 88];
% SFG: 9a, 9p, 8BL, 8Ad, 8Av
searchInds{7}{1} = [267 251 250 248 247];
searchInds{7}{2} = [87 71 70 68 67];

% OBJECT NETWORK
% IFS: IFSa
searchInds{8}{1} = 262;
searchInds{8}{2} = 82;
% Premotor: 6r
searchInds{9}{1} = 258;
searchInds{9}{2} = 78;
% PF: PF, PFop, PFt
searchInds{10}{1} = [328 327 296];
searchInds{10}{2} = [148 147 116];
% PHT
searchInds{11}{1} = 317;
searchInds{11}{2} = 137;


% LANGUAGE NETWORK
% PostTemp: TPOJ1, STV, STSdp, STSvp, PHT, TE1p, TE1m
searchInds{12}{1} = [319 208 309 310 317 313 357];
searchInds{12}{2} = [139 28 129 130 137 133 177];
% AntTemp: STSda, STSva, TE1a, TE2a, STGa, TGd
searchInds{13}{1} = [308 356 312 314 303 311];
searchInds{13}{2} = [128 176 132 134 123 131];
% MFG: FEF, 55b
searchInds{14}{1} = [190 192];
searchInds{14}{2} = [10 12];
% IFG: IFJa, IFSp, 44, 45, 47l
searchInds{15}{1} = [259 261 254 255 256];
searchInds{15}{2} = [79 81 74 75 76];

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
        for r=1:length(searchNames)
            for h=1:3
                outputDesc = ['mmp' networkNames{r} prefices{h} searchNames{r}];
                outputPath = fpp.bids.changeName(parcPath,'desc',outputDesc,'mask',outputExts{sp});
                if exist(outputPath,'file'), continue; end
                parcInds = searchInds{r}{h};
                fpp.util.label2ROI(parcPath,parcInds,outputPath);
                disp(['Wrote ' subjID ' - ' outputDesc '_space-' spaces{sp}]);
            end
        end
    end
end

% Generate summed masks (all regions) for each network
for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    for sp=1:length(spaces)
        subjStr = ['sub-' subjID '_'];
        if strcmp(spaces{sp}(1:4),'fsLR')
            subjStr = '';
        end
        parcPath = [anatDir '/' subjStr 'space-' spaces{sp} '_desc-MMP_dseg' inputExts{sp}];
        for n=1:length(networkNameOptions)
            outputDesc = ['mmp' networkNameOptions{n}];
            outputPath = fpp.bids.changeName(parcPath,'desc',outputDesc,'mask',outputExts{sp});
            if exist(outputPath,'file'), continue; end
            flagText = ''; equation = '';
            for r=networkInds{n}
                roiDesc = ['mmp' networkNames{r} searchNames{r}];
                roiPath = fpp.bids.changeName(parcPath,'desc',roiDesc,'mask',outputExts{sp});
                if r==networkInds{n}(1)
                    equation = [equation 'r' int2str(r)];
                else
                    equation = [equation '+r' int2str(r)];
                end
                flagText = [flagText ' -var r' int2str(r) ' ' roiPath];
            end
            fpp.wb.command([imageTypes{sp} '-math'],[],equation,outputPath,flagText);
            disp(['Wrote ' subjID ' ' outputDesc '_space-' spaces{sp}]);
        end
    end
end

