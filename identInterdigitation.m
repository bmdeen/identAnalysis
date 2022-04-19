
% Script to extract responses along geodesics between person- and place-
% responsive surface coordinates in medial parietal and frontal cortex, in
% IDENT dataset.
% 
% Uses gifti and cifti matlab toolboxes, and Freesurfer matlab tools, for
% dijk and pred2path.

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic'};
condNames = {'FamPerson','Object','FamPlace'};
runList = [1 3 5];
nTasks = length(tasks); nConds = length(condNames); nRuns = length(runList); nSubs = length(subjects);
hemis = {'L','R'};
modelType = 'arma';
space = 'individual';
res = '2';
den = '32k';        % 32k or native
modelDesc = 'Sm2';
outputPath = [studyDir '/derivatives/fpp/group/task-famcombined_space-' space...
    '_den-' den '_desc-' modelDesc '_GeodesicResponses.mat'];
areas = {'Left Parietal','Right Parietal','Left Frontal','Right Frontal'};
nAreas = length(areas);
hemisByArea = [1 2 1 2];

% Outputs:
% - responsePath: area by subject cell array of condition by task by run by
%   coordinate matrices of PSC.
% - responsePathStd: by-area cell array of cond x task x run x subj x coord
%   matrices of PSC, interpolated to a standard spatial position measure
%   across subjects.

% anchorCoords: cell array of surface coordinate matrices (subject by
% position), defining ventral to dorsal paths through left/right medial
% parietal/frontal cortex. Coords are zero-indexed, converted to
% one-indexing below. Picked by hand based on PersonVsPlace contrast in
% runs 2 and 4, across tasks (visual, semantic, episodic).

% Left parietal
anchorCoords{1} = [ 26072	26246	4088	2209
                    26002	1720	1843	2303
                    26093	13353	3908	2306
                    25984	13330	13380	1948
                    26050	11807	3946	2207
                    26091	13353	3762	2161
                    26052	13361	1728	2305
                    26091	11808	3857	2256
                    26024	13344	3903	2161
                    26091	13282	3810	2306];

% Right parietal
anchorCoords{2} = [ 26025	13308	3703	2213
                    26088	13330	3900	2210
                    26109	13371	3954	2212
                    26006	13331	3488	2004
                    26090	11806	3852	2257
                    26093	13313	3661	2106
                    26073	13352	3897	2350
                    26113	13343	3543	2161
                    26109	13305	3547	2211
                    26145	13298	3661	2011];

% Left frontal
anchorCoords{3} = [ 21352	21209	20975	27950	28348	28832
                    21342	28116	28524	28832	29039	29210
                    21377	27958	28477	28959	29140	29282
                    21394	21246	20998	28395	28645	29045
                    21370	27905	28491	28870	29054	29147
                    21344	21136	28346	28769	29081	29232
                    21399	21228	27963	28396	28896	29103
                    21333	21156	28525	28800	29024	29207
                    21270	21203	19808	28493	28773	28870
                    21363	21268	21222	28770	29024	29190];

% Right frontal
anchorCoords{4} = [ 21276	21163	21134	28215	28617	28933
                    19823	27958	28563	28931	29116	29171
                    21392	21206	28273	28654	28825	29071
                    21383	21264	27906	28731	29195	29313
                    21302	28071	28358	28691	28840	29099
                    21374	21208	19818	28693	29055	29148
                    21399	21246	28121	28574	28830	29125
                    21345	19815	28403	28691	28993	29093
                    21385	21370	19819	28532	29076	29143
                    21393	21228	28063	28531	28771	29023];

% Convert wb_view zero-indexed coordinates to one-indexed coords for MATLAB
for r=1:nAreas, anchorCoords{r} = anchorCoords{r}+1; end

% Interpolation info: "x" grid to resample to, measured in label id 1 to nAnchors
pointsBetweenAnchors = 7;   % Number of points between anchors to interpolate to
for a=1:nAreas
    xPosByArea{a} = linspace(1,size(anchorCoords{a},2),(size(anchorCoords{a},2)-1)*(pointsBetweenAnchors+1)+1);
end

for s=1:nSubs
    
    subjID = subjects{s};
    subjDir = [studyDir '/derivatives/fpp/sub-' subjID];
    anatDir = [subjDir '/anat'];
    analysisDir = [subjDir '/analysis'];
    
    for h=1:2
        surfacePaths{h} = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den'},...
            {subjID,hemis{h},space,den},'midthickness','.surf.gii')];
        surfaceData{h} = gifti(surfacePaths{h});
        if strcmp(den,'32k')
            medialWallPaths{h} = [anatDir '/' fpp.bids.changeName('',{'hemi','space','den','desc'},...
                {hemis{h},'fsLR','32k','medialwallAtlas'},'mask','.shape.gii')];
        elseif strcmp(den,'native')
            medialWallPaths{h} = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den','desc'},...
                {subjID,hemis{h},space,den,'medialwallAtlas'},'mask','.shape.gii')];
        end
        medialWallData{h} = gifti(medialWallPaths{h});
        D{h} = surfaceDistanceGraph(surfacePaths{h});
        D{h}(medialWallData{h}.cdata==1,:) = 0;
        D{h}(:,medialWallData{h}.cdata==1) = 0;       % Remove connections with medial wall vertices
    end
    
    % Compute geodesic paths between anchors, for each area
    for a=1:nAreas
        pathCoords{a,s} = [];   % Coordinates on path
        pathXPos{a,s} = [];     % X-position (resample to this, to match distances between anchors)
        
        % Compute shortest paths between anchors, combine
        for c=1:length(anchorCoords{a}(s,:))-1
            [~,rte] = dijk(D{hemisByArea(h)},anchorCoords{a}(s,c),anchorCoords{a}(s,c+1));   % Inefficient within c loop, but works
            pathCoords{a,s} = [pathCoords{a,s} rte(1:end-1)];
            xPos = linspace(c,c+1,length(rte));
            pathXPos{a,s} = [pathXPos{a,s} xPos(1:end-1)];  % Assuming roughly evenly spaced vertices
        end
        pathCoords{a,s} = [pathCoords{a,s} rte(end)];
        pathXPos{a,s} = [pathXPos{a,s} xPos(end)];
        disp(['Computed path coords for ' subjID ', ' areas{a}]);
    end
    
    % Loop across tasks, runs, and conditions, to extract PSC along paths
    for t=1:nTasks
        task = tasks{t};
        for r=1:nRuns
            run = runList(r);
            modelName = fpp.bids.changeName('',...
                {'sub','task','run','space','res','den','desc'},...
                {subjID,task,fpp.util.numPad(run,2),space,res,den,modelDesc},...
                ['model' modelType],'');
            modelDir = [analysisDir '/' modelName];
            for c=1:nConds
                % Load PSC file
                pscPath = [modelDir '/' fpp.bids.changeName(modelName,'desc',...
                    [modelDesc condNames{c}],'psc','.dscalar.nii')];
                pscData = cifti_read(pscPath);
                
                for a=1:nAreas
                    % Convert gifti to cifti coordinates
                    h = hemisByArea(a);
                    pathCoordsCifti = [];
                    for c2=1:length(pathCoords{a,s})
                        pathCoordsCifti(c2) = find(pathCoords{a,s}(c2)-1==pscData.diminfo{1}.models{h}.vertlist)...
                            + pscData.diminfo{1}.models{1}.count*(h-1);
                    end
                    responsePath{a,s}(c,t,r,:) = pscData.cdata(pathCoordsCifti);
                    % Resample to cross-subject standard coordinates
                    responsePathStd{a}(c,t,r,s,:) = interp1(pathXPos{a,s},...
                        pscData.cdata(pathCoordsCifti),xPosByArea{a});
                    
                    disp(['Extract data for ' subjID ', ' task '-' int2str(run)...
                        ', ' condNames{c} ', ' areas{a}]);
                end
            end
        end
    end
end

save(outputPath,'subjects','tasks','condNames','anchorCoords','hemisByArea',...
    'xPosByArea','pathCoords','pathXPos','responsePath','responsePathStd',...
    'nTasks','nConds','nRuns','nAreas','nSubs','areas');

%%% Plotting

% Reshape matrices for plotting
for a=1:nAreas
    responsePathStdPlot{a} = permute(reshape(responsePathStd{a},...
        [nConds nTasks nRuns*nSubs length(xPosByArea{a})]),[4 3 1 2]);  % Coord by run/sub by cond by task
    responsePathStdPlotTaskAvg{a} = squeeze(mean(responsePathStdPlot{a},4));    % Conditions averaged across tasks
    responsePathStdPlotConByTask{a} = squeeze(responsePathStdPlot{a}(:,:,1,:) - ...
        responsePathStdPlot{a}(:,:,3,:));   % Person versus place by task
end

% Line plot with std error across runs
% Within hemisphere
for a=1:nAreas
    % Person, object, and place responses, averaged across tasks
    if a<3, xTicks = 1:4;
    else xTicks = 1:6; end
    figure('Position',[500 500 340 250]);
    linProps.col = {'r','b'};
    mseb(xPosByArea{a},squeeze(mean(responsePathStdPlotTaskAvg{a},2))',...
        squeeze(std(responsePathStdPlotTaskAvg{a},0,2))'/sqrt(nRuns*nSubs),...
        linProps,1);
    if a<3
        xTicks = 1:4;
        ylim([-1 1.5]);
        set(gca,'YTick',[-1 0 1]);
    else
        xTicks = 1:6;
        ylim([-.5 .7]);
        set(gca,'YTick',[-.5 0 .5]);
    end
    set(gca,'linewidth',2,'FontSize',20);
    set(gca,'XTickLabel',[],'XTick',xTicks,'XLim',[1 max(xPosByArea{a})]);
    set(gcf,'Color',[1 1 1]);
    
    % Person versus place responses, for each task
    if a<3, xTicks = 1:4;
    else xTicks = 1:6; end
    figure('Position',[500 500 340 250]);
    linProps.col = {[240 200 160]/255, [132 143 162]/255, [45 49 66]/255};
    mseb(xPosByArea{a},squeeze(mean(responsePathStdPlotConByTask{a},2))',...
        squeeze(std(responsePathStdPlotConByTask{a},0,2))'/sqrt(nRuns*nSubs),...
        linProps,1);
    if a<3
        xTicks = 1:4;
        ylim([-1.6 1.5]);
        set(gca,'YTick',[-1 0 1]);
    else
        xTicks = 1:6;
        ylim([-.5 1.25]);
        set(gca,'YTick',[-.5 0 .5 1]);
    end
    set(gca,'linewidth',2,'FontSize',20);
    set(gca,'XTickLabel',[],'XTick',xTicks,'XLim',[1 max(xPosByArea{a})]);
    set(gcf,'Color',[1 1 1]);
end

% Average across hemispheres
areasToAvg = {1:2,3:4};
for a=1:2
    % Person, object, and place responses, averaged across tasks
    if a==2, xTicks = 1:4;
    else xTicks = 1:6; end
    figure('Position',[500 500 340 250]);
    linProps.col = {'r','b'};
    mseb(xPosByArea{areasToAvg{a}(1)},squeeze(mean([responsePathStdPlotTaskAvg{areasToAvg{a}(1)}...
        responsePathStdPlotTaskAvg{areasToAvg{a}(2)}],2))',...
        squeeze(std([responsePathStdPlotTaskAvg{areasToAvg{a}(1)}...
        responsePathStdPlotTaskAvg{areasToAvg{a}(2)}],0,2))'/sqrt(nRuns*nSubs),...
        linProps,1);
    if a==1
        xTicks = 1:4;
        ylim([-1 1.5]);
        set(gca,'YTick',[-1 0 1]);
    else
        xTicks = 1:6;
        ylim([-.5 .7]);
        set(gca,'YTick',[-.5 0 .5]);
    end
    set(gca,'linewidth',2,'FontSize',20);
    set(gca,'XTickLabel',[],'XTick',xTicks,'XLim',[1 max(xPosByArea{areasToAvg{a}(1)})]);
    set(gcf,'Color',[1 1 1]);
    
    % Person versus place responses, for each task
    if a==2, xTicks = 1:4;
    else xTicks = 1:6; end
    figure('Position',[500 500 340 250]);
    linProps.col = {[240 200 160]/255, [132 143 162]/255, [45 49 66]/255};
    mseb(xPosByArea{areasToAvg{a}(1)},squeeze(mean([responsePathStdPlotConByTask{areasToAvg{a}(1)}...
        responsePathStdPlotConByTask{areasToAvg{a}(2)}],2))',...
        squeeze(std([responsePathStdPlotConByTask{areasToAvg{a}(1)}...
        responsePathStdPlotConByTask{areasToAvg{a}(2)}],0,2))'/sqrt(nRuns*nSubs),...
        linProps,1);
    if a==1
        xTicks = 1:4;
        ylim([-1.6 1.5]);
        set(gca,'YTick',[-1 0 1]);
    else
        xTicks = 1:6;
        ylim([-.5 1.25]);
        set(gca,'YTick',[-.5 0 .5 1]);
    end
    set(gca,'linewidth',2,'FontSize',20);
    set(gca,'XTickLabel',[],'XTick',xTicks,'XLim',[1 max(xPosByArea{areasToAvg{a}(1)})]);
    set(gcf,'Color',[1 1 1]);
end

%% Write data for border file defined by geodesic path.

% Pick area and subject to generate path for
a = 1;
s = 1;

% Path resolution: # of points between vertices
ptsBetweenVerts = 10;

% Constants
studyDir = '/Freiwald/bdeen/IDENT';
space = 'individual';
den = '32k';        % 32k or native
modelDesc = 'Sm2';
hemis = {'L','R'};
outputPath = [studyDir '/derivatives/fpp/group/task-famcombined_space-' space...
    '_den-' den '_desc-' modelDesc '_GeodesicResponses.mat'];
load(outputPath);
h = hemisByArea(a);

subjID = subjects{s};
subjDir = [studyDir '/derivatives/fpp/sub-' subjID];
anatDir = [subjDir '/anat'];

% Load surface
surfacePath = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den'},...
    {subjID,hemis{h},space,den},'midthickness','.surf.gii')];
g = gifti(surfacePath);

% OLD METHOD: Path points at vertices only, nothing in between
% Loop through path vertices, find a face with that vertex to define border
% point
% faces = [];
% for c=1:length(pathCoords{a,s})
%     ind = find(g.faces(:,1)==pathCoords{a,s}(c));
%     faces(end+1,:) = g.faces(ind(1),:)-1;       % Output zero-index vertex IDs
% end
% weights = zeros(size(faces));
% weights(:,1) = 1;

% Add points on path between vertices
faces = [];
weights = [];
for c=1:length(pathCoords{a,s})-1
    % Find faces connecting two vertices on the path
    ind = find(sum(g.faces==pathCoords{a,s}(c),2)==1 & sum(g.faces==pathCoords{a,s}(c+1),2)==1);
    faces = [faces; repmat(g.faces(ind(1),:)-1,[ptsBetweenVerts+1 1])];    % Output zero-index vertex IDs
    
    % Define weights to draw a line bewteen vertices
    newWeights1 = linspace(1,0,ptsBetweenVerts+2)';  % Weights for (c) vertex
    newWeights2 = linspace(0,1,ptsBetweenVerts+2)';  % Weights for (c+1) vertex
    newWeights = zeros(ptsBetweenVerts+1,3);
    newWeights(:,g.faces(ind(1),:)==pathCoords{a,s}(c)) = newWeights1(1:end-1);
    newWeights(:,g.faces(ind(1),:)==pathCoords{a,s}(c+1)) = newWeights2(1:end-1);
    weights = [weights; newWeights];
end
% Add last vertex
 ind = find(g.faces(:,1)==pathCoords{a,s}(end));
 faces(end+1,:) = g.faces(ind(1),:)-1;       % Output zero-index vertex IDs
 weights(end+1,:) = [1 0 0];


% These face and weight matrices can now be displayed and copied into a
% border file, in the <vertices></vertices> and <weights></weights> flags.

fprintf('\n');
disp('Vertices: ');
fprintf('%d %d %d\n',faces');
fprintf('\n');
disp('Weights: ');
fprintf('%f %f %f\n',weights');
fprintf('\n');

