
% Function to plot results of identRestROICorrelation.
%
% Note: generated plot on Macbook pro 13.3in 2560x1600 display.

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
matPath = [bidsDir '/group/space-fsLR_den-32k_'...
    'desc-mmpSocialSpatialROIsTop5PctN10_ROICorrelationData.mat'];
load(matPath);
corrMatMean = mean(corrMat,3);
regions = {'LMPFC','RMPFC','LMPC','RMPC','LTPJ','RTPJ','LSTS','RSTS','LSFG','RSFG',...
    'LTP','RTP','LMPFC','RMPFC','LMPC','RMPC','LTPJ','RTPJ','LSFG','RSFG','LPHC','RPHC'};

% Hierarchical clustering
distMat = squareform(1-corrMatMean,'tovector');
Z = linkage(distMat);
leafOrder = optimalleaforder(Z,distMat);

% Plot correlation matrix
figure('Position',[200 200 250 250]);
imagesc(corrMatMean(leafOrder,leafOrder),[-1 1]);
%colorbar('FontSize',8);
set(gcf,'Color',[1 1 1]);
pbaspect([1 1 1]);
set(gca,'YTick',1:22,'YTickLabel',regions(leafOrder),'TickLength',[0 0],...
    'XTickLabel',[],'FontSize',8);

% Plot color bar
figure('Position',[200 200 150 150]);
imagesc(0,[-1 1]);
c=colorbar('YTick',[-1 -.5 0 .5 1],'FontSize',9);
set(gcf,'Color',[1 1 1]);

% Plot dendrogram
figure('Position',[200 200 125 248]);
h = dendrogram(Z,'Reorder',flip(leafOrder),'Orientation','right','ColorThreshold',.7);
set(gcf,'Color',[1 1 1]);
set(gca,'Visible','off');
redInd = [1:5 7:12];
blueInd = [6 13:20];
for i=redInd
    h(i).Color = 'r';
end
for i=blueInd
    h(i).Color = 'b';
end

% Compare within- and between-network correlations
corrByNetwork = nan(12*10,3);
withinSocial = tril(ones(22),-1);
withinSocial(13:end,:) = 0;
withinSpatial = tril(ones(22),-1);
withinSpatial(:,1:12) = 0;
between = zeros(22);
between(13:end,1:12) = 1;
corrByNetwork(1:sum(withinSocial(:)),1) = corrMatMean(withinSocial==1);
corrByNetwork(1:sum(withinSpatial(:)),2) = corrMatMean(withinSpatial==1);
corrByNetwork(:,3) = corrMatMean(between==1);

% Permutation test to compare within- and between-network correlations.
% Build null distribution of mean difference between within- and between-
% network correlations.
iters = 10000;
for i=1:iters
    areaPerm = randperm(22);
    corrMatMeanPerm = corrMatMean(areaPerm,areaPerm);
    socialDiffs(i) = mean(corrMatMeanPerm(withinSocial==1)) -...
        mean(corrMatMeanPerm(between==1));
    spatialDiffs(i) = mean(corrMatMeanPerm(withinSpatial==1)) -...
        mean(corrMatMeanPerm(between==1));
    if mod(i,100)==0, disp(i); end
end
spatialDiffs = sort(spatialDiffs);
ind = min(find(spatialDiffs>.4067));

% Social difference: real value is .6551. Larger than any of the permuted
% values. P < .0001.
% Spatial difference: real value is .4067. Only 4/10000 permuted values are
% larger. P < .001.

% Sig star info
groups = {[1 3],[2 3]};
stats = [0 .0004];

% Bar plot of within- and between-network correlations
% figure('Position',[200 200 140 250]);
barGraphLW = 3;     % Linewidth
barGraphFS = 28;    % Font size
figure('Position',[200 200 280 500]);
[b,e] = fpp.util.barColor(corrByNetwork,{'r','b','w'},1,[],0);
ylim([-.15 .69]);
h = identSigStarBigPlot(groups,stats);
set(gca,'LineWidth',barGraphLW,'FontSize',barGraphFS);
set(b,'LineWidth',barGraphLW);
set(b.BaseLine,'LineWidth',barGraphLW);
set(e,'LineWidth',barGraphLW);
set(h,'LineWidth',2);
