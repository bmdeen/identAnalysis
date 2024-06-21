
% identTPROIExtractBySize(defineROITask,contrastName,searchName,isCifti,varargin)
%
% Function to extract ROI responses to people vs places across a range of
% ROI sizes, from 5 to 40%.
%
% Arguments:
% - defineROITask (string): name of task used to define ROIs / extract
%       responses
% - contrastName (string): name of contrast used to define ROIs
% - searchName (string): name of search space used to define ROIs
% - isCifti (boolean): whether to use CIFTI inputs, or volumetric
% 
% Variable arguments:
% - overwrite (boolean): whether to overwrite output data and ROIs
% - invertStats (boolean, default = 0): whether to invert statistical map
% - inputSuffix (string): suffix for input modelarma directories
%
% Outputs to save: psc, subNums, runNums

function identTPROIExtractBySize(defineROITask,contrastName,searchName,isCifti,varargin)

% Define constants
fppDir = '/Freiwald/bdeen/IDENT/derivatives/fpp';
fppDir = '/Users/ben/NeuroscienceResearch/IDENT/derivatives/fpp';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};

% Color array: colors for person/place contrasts
colorArray = {[250 95 65]/255,[96 164 208]/255};

if ~exist('isCifti','var') || isempty(isCifti)
    isCifti = 1;
end
if isCifti
    searchSpace = 'individual_den-32k';
    statSpace = 'individual_res-2_den-32k';
    imageExt = '.dscalar.nii';
else
    searchSpace = 'session';
    statSpace = 'session';
    imageExt = '.nii.gz';
end

% If famvisual task is used, check familiar face response across size
computeFamiliarity = 0;

% Variable argument defaults
roiSize = 5:5:40;
sizeType = 'pct';
invertStats = 0;
inputSuffix = '';
overwrite = 0;

% Edit variable arguments.  Note: optInputs checks for proper input.
varArgList = {'invertStats','inputSuffix','overwrite'};
for i=1:length(varArgList)
    argVal = fpp.util.optInputs(varargin,varArgList{i});
    if ~isempty(argVal)
        eval([varArgList{i} ' = argVal;']);
    end
end

% Define output suffices based on variable arguments
numSuffix = 'BySize';
if invertStats
    invertSuffix = 'Inverted';
else
    invertSuffix = '';
end

% Subject number suffix
subSuffix = ['N' num2str(length(subjects))];

% Define output path
groupDir = [fppDir '/group'];
if ~exist(groupDir,'dir'), mkdir(groupDir); end
outputDesc = [searchName defineROITask inputSuffix contrastName invertSuffix numSuffix subSuffix];
outputPath = [groupDir '/space-' statSpace '_desc-' outputDesc '_roiData.mat'];
outputFigurePath = [groupDir '/space-' statSpace '_desc-' outputDesc '_responseplot.png'];
outputFigurePathFam = [groupDir '/space-' statSpace '_desc-' outputDesc 'Familiarity_responseplot.png'];
if exist(outputPath,'file') && ~overwrite, return; end

% Initialize outputs
[psc,pscFam,pscBySub,pscBySubFam,subNums,runNums] = deal([],[],[],[],[],[]);

% Define person vs place (or reverse) contrast
switch defineROITask
    case {'famsemantic','famepisodic','dyloc'}
        contrast = [1 0 -1];
    case 'famvisual'
        contrast = [1 0 0 -1 0];
        computeFamiliarity = 1;
        contrastFam = [1 -1 0 0 0];
    otherwise
        error('Specified task does not have person versus place contrast!');
end
if invertStats, contrast = -contrast; end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STEP 1: Extract ROI responses across
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for s=1:length(subjects)
    subject = subjects{s};
    subjDir = [fppDir '/sub-' subject];
    anatDir = [subjDir '/anat'];
    funcDir = [subjDir '/func'];
    analysisDir = [subjDir '/analysis'];
    maskPath = [funcDir '/sub-' subject '_space-' statSpace '_desc-brainNonZero_mask' imageExt];
    subjStr = ['sub-' subject '_'];
    searchPath = [anatDir '/' subjStr 'space-' searchSpace '_desc-' searchName '_mask' imageExt];
    
%     % Hack for subcortical ROIs, in individual CIFTI space
%     if ~exist(searchPath,'file')
%         searchPath1 = [anatDir '/sub-' subject '_space-' statSpace '_desc-' searchName '_mask' imageExt];
%         if ~exist(searchPath1,'file')
%             error(['Search path does not exist: ' searchPath]);
%         else
%             searchPath = searchPath1;
%         end
%     end

    % Hack for search spaces in fsLR or individual space
    if ~exist(searchPath,'file') && isCifti
        searchPath1 = [anatDir '/sub-' subject '_space-fsLR_den-32k_desc-' searchName '_mask' imageExt];
        if ~exist(searchPath1,'file')
            searchPath2 = fpp.bids.changeName(searchPath1,'sub',[]);
            if ~exist(searchPath2,'file')
                error(['Search path does not exist: ' searchPath]);
            else
                searchPath = searchPath2;
            end
        else
            searchPath = searchPath1;
        end
    end
    
    defineROIDir = fpp.bids.changeName([analysisDir '/sub-' subject '_task-'...
        defineROITask '_run-01_space-' statSpace '_modelarma'],'desc',inputSuffix);
    extractResponseDir = defineROIDir;  % Extract responses from the same task
    
    conTmp = [];
    conTmpFam = [];
    for r=1:length(roiSize)
        [pscTmp,~,runNames] = fpp.func.roiExtract(extractResponseDir,...
            defineROIDir,contrastName,searchPath,'maskPath',maskPath,'roiSize',...
            roiSize(r),'sizeType',sizeType,'invertStats',invertStats,'overwrite',overwrite);
        conTmp = [conTmp pscTmp*contrast'];
        if computeFamiliarity
            conTmpFam = [conTmpFam pscTmp*contrastFam'];
        end
    end
    psc = [psc; conTmp];
    
    runNums = [runNums; cellfun(@str2num,runNames)'];
    subNums = [subNums; s*ones(length(runNames),1)];
    pscBySub(s,:) = mean(conTmp);
    
    if computeFamiliarity
        pscFam = [pscFam; conTmpFam];
        pscBySubFam(s,:) = mean(conTmpFam);
    end
    
    disp(['Extracted data for sub-' subject]);
    
end
% Compute run-wise standard error
pscRunwiseStdErr = std(psc)/sqrt(size(psc,1));

save(outputPath,'psc','runNums','subNums','pscBySub','subjects','colorArray',...
    'pscRunwiseStdErr','invertStats');

if computeFamiliarity
    pscFamRunwiseStdErr = std(pscFam)/sqrt(size(pscFam,1));
    save(outputPath,'-append','pscFam','pscFamRunwiseStdErr','pscBySubFam');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STEP 3: Plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[200 200 800 400]);
xTicks = 5:5:40;
linProps.col = {'r'};
if invertStats, linProps.col = {'b'}; end
mseb(xTicks,mean(psc),pscRunwiseStdErr,linProps,1);
set(gca,'linewidth',2,'FontSize',16);
set(gca,'XTickLabel',xTicks,'XTick',xTicks);
set(gcf,'Color',[1 1 1]);
saveas(gcf,outputFigurePath);

if computeFamiliarity
    figure('Position',[200 200 800 400]);
    xTicks = 5:5:40;
    linProps.col = {'r'};
    if invertStats, linProps.col = {'b'}; end
    mseb(xTicks,mean(pscFam),pscFamRunwiseStdErr,linProps,1);
    set(gca,'linewidth',2,'FontSize',16);
    set(gca,'XTickLabel',xTicks,'XTick',xTicks);
    set(gcf,'Color',[1 1 1]);
    saveas(gcf,outputFigurePathFam);
end

end