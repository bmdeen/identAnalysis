
% Function to compute resting-state correlations between a set of ROIs in
% IDENT data.
%
% Arguments:
% - roiDescs (cell array): BIDS descriptions of ROIs to correlation
% - outputDesc (string): BIDS description for output file

function identRestROICorrelation(roiDescs,outputDesc)

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
spaceStr = 'fsLR_den-32k';
nRuns = 6;
nVols = 300;
nROIs = length(roiDescs);
inputDesc = 'preprocGSR';
outputPath = [bidsDir '/group/space-' spaceStr '_desc-' outputDesc 'N' int2str(length(subjects)) '_ROICorrelationData.mat'];
corrMat = zeros(nROIs,nROIs,length(subjects));

for s=1:length(subjects)
    
    % Define paths
    subject = subjects{s};
    subjDir = [bidsDir '/sub-' subject];
    roiDir = [subjDir '/roi'];
    funcDir = [subjDir '/func'];
    
    % Load ROIs
    roiMat = [];
    roiAvgMat = [];
    for r=1:nROIs
        roiPaths = [roiDir '/sub-' subject '_space-' spaceStr '_desc-' roiDescs{r} '_mask.dscalar.nii'];
        roiMat(:,r) = fpp.util.readDataMatrix(roiPaths);
        roiAvgMat(:,r) = roiMat(:,r)/sum(roiMat(:,r));  % Dot product with this vector = mean across ROI
    end
    
    for r=1:nRuns
        restPath = [funcDir '/sub-' subject '_task-rest_run-' fpp.util.numPad(r,2)...
            '_space-' spaceStr '_desc-' inputDesc '_bold.dtseries.nii'];
        
        % Define outlier volumes
        %confoundPath = fpp.bids.changeName(restPath,'desc','','confounds','.tsv');
        outlierPath = fpp.bids.changeName(restPath,{'space','res','den','desc'},...
            {'','','',''},'outliers','.tsv');
        outlierInd = fpp.util.readOutlierTSV(outlierPath);
        goodInd = setdiff(1:nVols,outlierInd);
        
        % Load resting data
        restMat = fpp.util.readDataMatrix(restPath);
        restMat = restMat(:,goodInd);
        
        % Compute ROI-averaged time series
        roiAvgSeries = restMat'*roiAvgMat;  % Time point by ROI matrix of time series
        
        % Compute correlations
        corrMat(:,:,s) = corrMat(:,:,s) + corr(roiAvgSeries)/nRuns;
        
        disp(['Computed correlation matrix for ' subject ', run ' int2str(r)]);
    end
end

save(outputPath,'corrMat','roiDescs');

% Plot
figure;
imagesc(squeeze(mean(corrMat,3)),[-1 1]);
colorbar;
set(gcf,'Color',[1 1 1]);

end