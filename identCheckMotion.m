
% Script to check and plot head motion (distribution of framewise
% displacement) for each participant in the IDENT study.
%
% Note: generated plot on Macbook pro 13.3in 2560x1600 display.

%% Load FD values

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc','rest'};
nRuns = [5 5 5 4 6 4 6];
fdAll = [];
outputPath = [bidsDir '/group/desc-AllFramewiseDisplacement_mat.mat'];

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [bidsDir '/sub-' subjID '/func'];
    fdSub = [];
    for t=1:length(tasks)
        for r=1:nRuns(t)
            confoundPath = [funcDir '/sub-' subjID '_task-' tasks{t} '_run-'...
                fpp.util.numPad(r,2) '_space-session_confounds.tsv'];
            confounds = bids.util.tsvread(confoundPath);
            fdSub = [fdSub; confounds.framewise_displacement(2:end)];
        end
    end
    fdAll = [fdAll fdSub];
    disp(subjID);
end

save(outputPath,'fdAll','subjects');

%% Determine outlier threshold
% Check proportion of values outside of outlier range for each participant
w = 5;    % Threshold of 5 -> less than 1% of values are outliers
outlierFrac = [];
for s=1:length(subjects)
    q = prctile(fdAll(:,s),[25 75]);    % Upper/lower quartiles
    outlierThresh = q(2)+w*(q(2)-q(1));
    outlierFrac(s) = sum(fdAll(:,s)>outlierThresh)/size(fdAll,1);
    disp([subjects{s} ' ' num2str(outlierFrac(s))]);
end
disp(mean(outlierFrac));

%% Plot data

for s=1:length(subjects)
    fdSub = fdAll(:,s);
    q = prctile(fdSub,[25 75]);    % Upper/lower quartiles
    outlierThresh = q(2)+w*(q(2)-q(1));
    fdCell{s} = fdSub(fdSub<outlierThresh);
    xCell{s} = int2str(s);
end
figure;
v = violin(fdCell,'mc',[],'medc','k','facecolor','w','plotlegend',0);
for i=1:length(v)
    set(v(i),'LineWidth',2);
end
set(gcf,'Color',[1 1 1]);
set(gca,'XTick',1:10,'XTickLabel',xCell,'FontSize',16,'LineWidth',2);
xlabel('Participant');
ylabel('Framewise Displacement (mm)');
