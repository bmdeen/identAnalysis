
% identROIExtractBySize(defineROITask,contrastName,searchName,isCifti,varargin)
%
% Function to plot ROI by size results from macbook pro. Optimized for
% plots in paper - relatively small size! Not ideal for talks.
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

function identTPROIExtractBySizePlot(defineROITask,contrastName,searchName,isCifti,varargin)

% Define constants
fppDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};

% Color array: colors for person/place contrasts
colorArray = {[250 95 65]/255,[96 164 208]/255};

if ~exist('isCifti','var') || isempty(isCifti)
    isCifti = 1;
end
if isCifti
    searchSpace = 'fsLR_den-32k';
    statSpace = 'individual_res-2_den-32k';
    imageExt = '.dscalar.nii';
else
    searchSpace = 'session';
    statSpace = 'session';
    imageExt = '.nii.gz';
end

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
outDir = '/Users/ben/Dropbox/NeuroscienceResearch/IDENT/results_tp/ROIBarPlot/BySize';
if ~exist(groupDir,'dir'), mkdir(groupDir); end
outputDesc = [searchName defineROITask inputSuffix contrastName invertSuffix numSuffix subSuffix];
outputPath = [groupDir '/space-' statSpace '_desc-' outputDesc '_roiData.mat'];
outputFigurePath = [outDir '/space-' statSpace '_desc-' outputDesc '_responseplot.png'];
outputFigurePathFam = [outDir '/space-' statSpace '_desc-' outputDesc 'Familiarity_responseplot.png'];
if ~exist(outputPath,'file'), error(['Data .mat file does not exist: ' outputPath]); end
%if exist(outputFigurePath,'file') && ~overwrite, return; end

load(outputPath);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STEP 3: Plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Position',[200 200 400 200]);
xTicks = 5:5:40;
linProps.col = {'r'};
if invertStats, linProps.col = {'b'}; end
mseb(xTicks,mean(psc),pscRunwiseStdErr,linProps,1);
set(gca,'linewidth',2,'FontSize',16,'XTickLabel',xTicks,'XTick',xTicks);
xlim([5 40]);
set(gcf,'Color',[1 1 1]);

% Set y axis limits and tick positions
switch searchName
    case 'handDrawnLTP'
        ylim([0 .4]);
        set(gca,'YTick',0:.2:.4);
    case 'handDrawnLPRC'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
    case 'handDrawnLASTS'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
    case 'handDrawnLAIT'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
    case 'handDrawnRTP'
        ylim([0 .4]);
        set(gca,'YTick',0:.2:.4);
    case 'handDrawnRPRC'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
    case 'handDrawnRASTS'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
    case 'handDrawnRAIT'
        ylim([0 .6]);
        set(gca,'YTick',0:.2:.6);
end

saveas(gcf,outputFigurePath);

if exist('pscFam','var')
    figure('Position',[200 200 400 200]);
    xTicks = 5:5:40;
    linProps.col = {'r'};
    if invertStats, linProps.col = {'b'}; end
    mseb(xTicks,mean(pscFam),pscFamRunwiseStdErr,linProps,1);
    set(gca,'linewidth',2,'FontSize',16,'XTickLabel',xTicks,'XTick',xTicks);
    xlim([5 40]);
    set(gcf,'Color',[1 1 1]);
    
    ylim([0 .2]);
    set(gca,'YTick',0:.1:.2);
    
    %{
    switch searchName
        case 'handDrawnLTP'
            ylim([0 .12]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnLPRC'
            ylim([0 .1]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnLASTS'
            ylim([0 .2]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnLAIT'
            ylim([0 .1]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnRTP'
            ylim([0 .2]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnRPRC'
            ylim([0 .1]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnRASTS'
            ylim([0 .2]);
            set(gca,'YTick',0:.1:.2);
        case 'handDrawnRAIT'
            ylim([0 .2]);
            set(gca,'YTick',0:.1:.2);
    end
    %}
    
    saveas(gcf,outputFigurePathFam);
end

end