
% Function to compute diffusion map embedding for IDENT functional
% connectivity data.
% 
% Load data, compute correlation maps (all cortical vertices), compute
% affinity map and diffusion map.

function identRestDiffusionMap(subjID)

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
spaceStr = '_space-fsLR_den-32k';
nRuns = 6;
nVols = 300;
inputDesc = 'GSRSm2';

% Define paths
subjDir = [bidsDir '/sub-' subjID];
funcDir = [subjDir '/func'];
analysisDir = [subjDir '/analysis'];

% Load resting-state data
dataMat = [];   % Vertex by time point matrix of resting data, across runs
for r=1:nRuns
    restPath = [funcDir '/sub-' subjID '_task-rest_run-' fpp.util.numPad(r,2)...
        spaceStr '_desc-preproc' inputDesc '_bold.dtseries.nii'];
    
    % Define outlier volumes
    outlierPath = fpp.bids.changeName(restPath,{'space','den','desc'},{'','',''},'outliers','.tsv');
    outlierInd = fpp.util.readOutlierTSV(outlierPath);
    goodInd = setdiff(1:nVols,outlierInd);
    
    % Load resting data, concatenate with prior runs
    [restMat,hdr] = fpp.util.readDataMatrix(restPath);
    restMat = zscore(restMat(:,goodInd),0,2);
    dataMat = [dataMat restMat];
end

X = dataMat';
[nTpts,nVox] = size(X);
% Parameters based on Margulies et al. (2016), "Situating the default mode
% network along a principle gradient of macroscale cortical organization."
affParams.kNN = round(nVox/10);         % Use top 10% of nearest neighbors
affParams.dist_type = 'correlation';    % Correlation distance
diffParams.normalization = 'fp';        % Fokker-Planck, i.e. alpha = .5
diffParams.t = 0;                       % Use Lambda -> Lambda/(1-Lambda)
diffParams.plotResults = 1;

%{
% Alternative method: truncated correlation similarity
% Gives qualitatively identical results

% Simplified version of calcAffinityMat
[Dis,Inds] = pdist2(X',X',affParams.dist_type,'Smallest',affParams.kNN);

% Dim info for sparse
rowInds = repmat((1:nVox),affParams.kNN,1);
rowInds = rowInds(:);
colInds = double(Inds(:));

% Convert distance to similarity
vals = 1-Dis(:);    % Assuming correlation distance
vals(vals<0) = 0;   % Remove negative correlations
vals = double(vals);

K = sparse(rowInds, colInds, vals, nVox, nVox);
K = (K + K')/2;
%}

% Margulies/Ghosh method: cosine similarity of truncated correlation matrix

Xnorm = zscore(X)/sqrt(nTpts-1);    % Cols have norm 1
Sim = Xnorm'*Xnorm;                 % Correlation matrix

% Only keep top 10% of values per row
for i=1:nVox
    [~,ind] = sort(Sim(i,:),'descend');
    Sim(i,ind(affParams.kNN+1:end)) = 0;
end

% Compute cosine similarity of rows
vals = double(Sim*Sim'./repmat(vecnorm(Sim,2,2),[1 nVox])./repmat(vecnorm(Sim,2,2)',[nVox 1]));

K = sparse(vals);

diffmap = calcDiffusionMap(K,diffParams)';

% Write diffusion gradients to CIFTI files
outputDir = [analysisDir '/sub-' subjID '_task-rest' spaceStr '_diffusion'];
if ~exist(outputDir,'dir'), mkdir(outputDir); end
for i=1:3
    outputPath = [outputDir '/sub-' subjID '_task-rest' spaceStr...
        '_desc-Gradient' int2str(i) '_diffusionmap.dscalar.nii'];
    fpp.util.writeDataMatrix(diffmap(:,i),hdr,outputPath);
end
outputMatPath = [outputDir '/sub-' subjID '_task-rest' spaceStr '_DiffusionData.mat'];
save(outputMatPath,'diffmap','affParams','diffParams');

end
