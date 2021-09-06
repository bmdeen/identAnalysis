
% Function to compute CIFTI-based resting-state functional connectivity map
% from a seed ROI input.
%
% Arguments:
% - seedPath (string): path to seed ROI CIFTI file

function identRestSurfConn(seedPath)

bidsDir = fpp.bids.checkBidsDir(seedPath);
spaceStr = '_space-individual_res-2_den-32k';
nRuns = 6;
inputDesc = 'GSRSm2';
subjID = fpp.bids.checkNameValue(seedPath,'sub');
seedDesc = fpp.bids.checkNameValue(seedPath,'desc');
seedDen = fpp.bids.checkNameValue(seedPath,'den');

if ~strcmp(seedDen,'32k'), error('Seed must be defined in 32k fsLR space.'); end

% Define paths
subjDir = [bidsDir '/sub-' subjID];
funcDir = [subjDir '/func'];
analysisDir = [subjDir '/analysis'];

% Load seed
seedMat = fpp.util.readDataMatrix(seedPath);

% Loop across runs, compute correlations
for r=1:nRuns
    % Load data
    restPath = [funcDir '/sub-' subjID '_task-rest_run-' fpp.util.numPad(r,2)...
        spaceStr '_desc-preproc' inputDesc '_bold.dtseries.nii'];
    [restMat,hdr] = fpp.util.readDataMatrix(restPath);
    
    % If seed doesn't have subcortical CIFTI components, zero-pad
    if r==1 && size(restMat,1)>size(seedMat,1)
        seedMat = [seedMat; zeros(size(restMat,1)-size(seedMat,1),1)];
    end
    
    % Define outlier volumes
    outlierPath = fpp.bids.changeName(restPath,{'space','res','den','desc'},{'','','',''},'outliers','.tsv');
    [outlierInd,nVols] = fpp.util.readOutlierTSV(outlierPath);
    goodInd = setdiff(1:nVols,outlierInd);
    nTpts = length(goodInd);
    
    % Load resting data, concatenate with prior runs
    restMat = fpp.util.readDataMatrix(restPath);
    restMat = zscore(restMat(:,goodInd),0,2)/sqrt(nTpts-1); % Mean zero, norm 1
    
    seedSeries = zscore(mean(restMat(seedMat==1,:)))/sqrt(nTpts-1);
    corrMat(:,r) = restMat*seedSeries';
end

% Average correlations across runs
corrMat = mean(corrMat,2);

% Write output
outputDir = [analysisDir '/sub-' subjID '_task-rest' spaceStr '_funcconn'];
if ~exist(outputDir,'dir'), mkdir(outputDir); end
outputPath = [outputDir '/sub-' subjID '_task-rest' spaceStr '_desc-' inputDesc...
    'Seed' seedDesc '_rstat.dscalar.nii'];
fpp.util.writeDataMatrix(corrMat,hdr,outputPath);

end