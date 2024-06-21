
% Plot histograms of face response and familiarity effect across subjects
% for TP and PR.

% Compute face selectivity for all areas: TP, PR, ASTS, AI, FFA, OFA, PSTS

groupDir = '/path/to/data';
outputDir = '/path/to/output';

rois = {'handDrawnLTP','handDrawnLPRC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT'};

faceSelectivity = [];

for r=1:length(rois)
    roiDataPath = [groupDir '/space-individual_res-2_den-32k_desc-' rois{r} ...
        'famvisualSm2PersonVsPlaceTop5PctN10_roiData.mat'];
    load(roiDataPath);
    outputFigurePath = [outputDir '/space-individual_res-2_den-32k_desc-' rois{r} ...
        'famvisualSm2PersonVsPlaceTop5PctN10FaceAndFamiliarity_dotplot.png'];
    
    % Compute familiarity effect and face effect
    familiarityEffect = squeeze(pscBySub(:,1)-pscBySub(:,2)); % FF - UF
    faceEffect = squeeze(pscBySub(:,2)-pscBySub(:,3)); % UF - O
    
    % Compute % familiarity effect
    familiarityEffectPct = squeeze((pscBySub(:,1)-pscBySub(:,2))./abs(pscBySub(:,2))); % (FF - UF)/abs(UF)
    disp(['Familiarity ' rois{r} ': ' num2str(mean(familiarityEffectPct)*100)]);
    
    % Compute face selectivity: (UF - O)/(abs(UF) + abs(O))
    faceSelectivity(:,r) = squeeze((pscBySub(:,2)-pscBySub(:,3))./(abs(pscBySub(:,2))+abs(pscBySub(:,3))));
    
    figure('Position',[200 200 140 140]);   % saveas increases size; resize to 320x320 for photoshop Fig 1
    b = fpp.util.barColor([faceEffect familiarityEffect],{[1 1 1],[1 1 1]},0,[],1,20);
    set(b,'EdgeColor','none','FaceAlpha',0);    % Remove bars
    %line([0 3],[0 0],'LineWidth',2,'Color','k');
    set(gca,'FontSize',20,'LineWidth',2);
    set(b,'LineWidth',2);
    set(b.BaseLine,'LineWidth',2);
    %set(gca,'XTick',[1 2],'XTickLabel',{},'TickLength',[.03 .03]);
    set(gca,'TickLength',[.03 .03]);
    switch rois{r}
        case 'handDrawnLTP'
            ylim([-.1 .4]);
            set(gca,'YTick',0:.2:.4);
        case 'handDrawnRTP'
            ylim([-.1 .4]);
            set(gca,'YTick',0:.2:.4);
        case 'handDrawnLPRC'
            ylim([-.1 .8]);
            set(gca,'YTick',0:.4:.8);
        case 'handDrawnRPRC'
            ylim([-.1 .8]);
            set(gca,'YTick',0:.4:.8);
        otherwise
            ylim([-.1 .6]);
            set(gca,'YTick',0:.3:.6);
    end
    
    saveas(gcf,outputFigurePath);
end


% Plot face selectivity across ATL and face areas
colorArray = {[1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1],...
    [1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1],[1 1 1]};
roiInd = [1 5 2 6 3 7 4 8 9 12 10 13 11 14];
figure;
b = fpp.util.barColor(faceSelectivity(:,roiInd),colorArray,0,[],1,20);

%% Check parcel size by participant

% Compute size (# coordinate in fsLR space) of anatomical parcel for each
% participant

fppDir = '/Users/ben/NeuroscienceResearch/IDENT/derivatives/fpp';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
roiNames = {'LTP','LPRC','LASTS','LAIT','RTP','RPRC','RASTS','RAIT',...
    'LFFA','LOFA','LPSTS','RFFA','ROFA','RPSTS'};
rois = {'handDrawnLTP','handDrawnLPRC','handDrawnLASTS','handDrawnLAIT',...
    'handDrawnRTP','handDrawnRPRC','handDrawnRASTS','handDrawnRAIT'};
roiInd = [1 5 2 6 3 7 4 8];
parcelSize = zeros(length(subjects),length(rois));

for s=1:length(subjects)
    for r=1:length(rois)
        roiPath = [fppDir '/sub-' subjects{s} '/anat/sub-' subjects{s}...
            '_space-fsLR_den-32k_desc-' rois{r} '_dseg.dlabel.nii'];
        cmd = ['wb_command -cifti-stats ' roiPath ' -reduce COUNT_NONZERO'];
        [~, cmdVal] = fpp.util.system(cmd);
        parcelSize(s,r) = str2num(strtrim(cmdVal));
        disp([subjects{s} ' - ' rois{r}]);
    end
end

plotData = [min(parcelSize); median(parcelSize); max(parcelSize)];
plotData = plotData(:,roiInd);

sprintf('%d %d %d\n',plotData);

