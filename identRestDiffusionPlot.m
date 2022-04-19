
% Function to plot resting-state diffusion map directions, with person,
% place, and object responses overlaid.

function identRestDiffusionPlot(subjID)

% Whether to average statistics across tasks (runs 2 and 4).
% Default: intersect stats across tasks.
avgStats = 0;
avgSuffix = 'Intersect';
if avgStats, avgSuffix = 'Average'; end

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
analysisDir = [bidsDir '/sub-' subjID '/analysis'];
spaceStr = '_space-fsLR_den-32k';
diffusionDir = [analysisDir '/sub-' subjID '_task-rest' spaceStr '_diffusion'];
diffusionMatPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr '_DiffusionData.mat'];
zThresh = 2.3;          % Z-stat threshold
zStatSuffix = ['Z' strrep(num2str(zThresh),'.','p')];
scatterSize = 5;        % Scatter plot dot size in points
figSize = 450;
fontSize = 14;
rotationAngle = 15;    % Apply this manual rotation (degrees CCW) before plotting

% Load diffusion map
load(diffusionMatPath);     % Key variable: diffmap
nCoords = size(diffmap,1);

% Rearrange diffmap indices so that principal gradient is dimension 2, apex
% network is at the top of graph, motor network on the bottom right, visual
% on the bottom left. For ident01, do this manually. For other subjects,
% use Proctustes transformation.
if ~exist('diffmapStd','var')
    if strcmp(subjID,'ident01')
        diffmap = diffmap(:,[2 1 3]);
        diffmap(:,2) = -diffmap(:,2);
    else
        diffusionMatPath1 = [bidsDir '/sub-ident01/analysis/sub-ident01_task-rest'...
            spaceStr '_diffusion/sub-ident01_task-rest' spaceStr '_DiffusionData.mat'];
        diffmap1 = load(diffusionMatPath1,'diffmap');
        diffmap1 = diffmap1.diffmap;
        diffmap1 = diffmap1(:,[2 1 3]);
        diffmap1(:,2) = -diffmap1(:,2);
        [~,diffmap] = procrustes(diffmap1,diffmap);
    end
    % Save standardized diffmap
    diffmapStd = diffmap;
    save(diffusionMatPath,'-append','diffmapStd');
    % Save standardized dimensions to CIFTI dscalar
    inputPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr...
        '_desc-Gradient1_diffusionmap.dscalar.nii'];
    [~,hdr] = fpp.util.readDataMatrix(inputPath);
    for i=1:3
        outputPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr...
            '_desc-GradientStd' int2str(i) '_diffusionmap.dscalar.nii'];
        fpp.util.writeDataMatrix(diffmap(:,i),hdr,outputPath);
    end
else
    diffmap = diffmapStd;
end

% Manually rotate diffmap, to align y-axis with apex gradient for
% visualization.
rotationAngle = 15;
R = [cosd(rotationAngle) -sind(rotationAngle) 0; sind(rotationAngle) cosd(rotationAngle) 0; 0 0 1];
diffmapRot = diffmap*R';

% Find indices of task-responsive coordinates
if avgStats
    % Load z-stat maps
    task = 'famcombined';
    contrasts = {'PersonVsPlaceObject','PlaceVsPersonObject','ObjectVsPersonPlace'};
    analysisSuffix = 'r2r4';
    for c=1:length(contrasts)
        zStatPath = [analysisDir '/sub-' subjID '_task-' task...
            '_space-individual_res-2_den-32k_desc-Sm2' analysisSuffix '_model2arma/sub-'...
            subjID '_task-' task '_space-individual_res-2_den-32k_desc-Sm2' analysisSuffix...
            contrasts{c} '_zstat.dscalar.nii'];
        zStatVec{c} = fpp.util.readDataMatrix(zStatPath);
        zStatVec{c} = zStatVec{c}(1:nCoords);   % Remove subcortical coordinates
    end
    
    % Find indices of coordinates with preferences for people, places, and
    % objects
    %if ~exist('personInd','var'), saveInd = 1; else saveInd = 0; end
    saveInd = 1;
    personInd = find(zStatVec{1}>zThresh);
    placeInd = find(zStatVec{2}>zThresh);
    objectInd = find(zStatVec{3}>zThresh);
else
    % Load z-stat maps
    tasks = {'famvisual','famsemantic','famepisodic'};
    contrasts = {'PersonVsPlaceObject','PlaceVsPersonObject','ObjectVsPersonPlace'};
    for t=1:length(tasks)
        for c=1:length(contrasts)
            zStatPath = [analysisDir '/sub-' subjID '_task-' tasks{t}...
                '_space-individual_res-2_den-32k_desc-Sm2_model2arma/sub-'...
                subjID '_task-' tasks{t} '_space-individual_res-2_den-32k_desc-Sm2'...
                contrasts{c} '_zstat.dscalar.nii'];
            zStatVec{t,c} = fpp.util.readDataMatrix(zStatPath);
            zStatVec{t,c} = zStatVec{t,c}(1:nCoords);   % Remove subcortical coordinates
        end
    end
    
    % Find indices of coordinates with preferences for people, places, and
    % objects
    if ~exist('personInd','var'), saveInd = 1; else saveInd = 0; end
    saveInd = 1;
    personInd = find(zStatVec{1,1}>zThresh & zStatVec{2,1}>zThresh & zStatVec{3,1}>zThresh);
    placeInd = find(zStatVec{1,2}>zThresh & zStatVec{2,2}>zThresh & zStatVec{3,2}>zThresh);
    objectInd = find(zStatVec{1,3}>zThresh & zStatVec{2,3}>zThresh & zStatVec{3,3}>zThresh);
end

allInd = sort(unique([personInd; placeInd; objectInd]));
noneInd = setdiff(1:nCoords,allInd);
if saveInd, save(diffusionMatPath,'-append','personInd','placeInd','objectInd'); end

% Display numbers of indices
disp(['# Person Coords: ' int2str(length(personInd))]);
disp(['# Place Coords: ' int2str(length(placeInd))]);
disp(['# Object Coords: ' int2str(length(objectInd))]);

% Write surface maps of person/place/object-responsive cortex
personOutputPath = [diffusionDir '/sub-' subjID spaceStr '_desc-PersonVsPlaceObjectResponsive' avgSuffix...
    zStatSuffix '_mask.dscalar.nii'];
placeOutputPath = [diffusionDir '/sub-' subjID spaceStr '_desc-PlaceVsPersonObjectResponsive' avgSuffix...
    zStatSuffix '_mask.dscalar.nii'];
objectOutputPath = [diffusionDir '/sub-' subjID spaceStr '_desc-ObjectVsPersonPlaceResponsive' avgSuffix...
    zStatSuffix '_mask.dscalar.nii'];
if ~exist(personOutputPath,'file')
    inputPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr...
        '_desc-GradientStd2_diffusionmap.dscalar.nii'];
    [~,hdr] = fpp.util.readDataMatrix(inputPath);
    zeroVec = zeros(nCoords,1);
    personVec = zeroVec; personVec(personInd)=1;
    fpp.util.writeDataMatrix(personVec,hdr,personOutputPath);
    placeVec = zeroVec; placeVec(placeInd)=1;
    fpp.util.writeDataMatrix(placeVec,hdr,placeOutputPath);
    objectVec = zeroVec; objectVec(objectInd)=1;
    fpp.util.writeDataMatrix(objectVec,hdr,objectOutputPath);
end

% Scatter plot colors
colorMat = zeros(nCoords,3);
colorMat(personInd,:) = repmat([1 0 0],[length(personInd) 1]);
colorMat(placeInd,:) = repmat([0 0 1],[length(placeInd) 1]);
colorMat(objectInd,:) = repmat([0 1 0],[length(objectInd) 1]);

% Scatter sizes
sizeVec = scatterSize*ones(nCoords,1);
sizeVec(allInd) = 2*scatterSize;

figure('Position',[200 200 figSize figSize]);
 % NOTE: Alpha properties require MATLAB >=2021a
s = scatter(100*diffmapRot(noneInd,1),100*diffmapRot(noneInd,2),sizeVec(noneInd),...
    colorMat(noneInd,:),'filled','MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5);
hold on;
s2 = scatter(100*diffmapRot(allInd,1),100*diffmapRot(allInd,2),sizeVec(allInd),...
    colorMat(allInd,:),'filled','MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5); % Put task responses on top
pbaspect([1 1 1]);
set(gca,'LineWidth',2,'FontSize',fontSize);
set(gcf,'Color',[1 1 1]);
xlim([-3.5 2.5]);

% For ident01, plot map with colored anatomical regions (apex, vis, motor)
if strcmp(subjID,'ident01')
    % Define median and corner points
    medianPoint = median(diffmap(:,1:2))';
    % Visual corner
    [~,ind] = min(diffmap(:,1));
    cornerPoints(:,1) = diffmap(ind,1:2);
    % Apex corner
    [~,ind] = max(diffmap(:,2));
    cornerPoints(:,2) = diffmap(ind,1:2);
    % Motor corner
    [~,ind] = min(diffmap(:,2));
    cornerPoints(:,3) = diffmap(ind,1:2);
    
    cornerVecs = cornerPoints-medianPoint;  % Corners as vectors with median at center
    diffmapVecs = diffmap(:,1:2)' - medianPoint;
    
    % Loop across corners. Compute distance from corner, define colors.
    for i=1:3
        distances = cornerVecs(:,i)'*diffmapVecs/norm(cornerVecs(:,i))^2;
        distances(distances<0) = 0;
        % RGB value 200 at center, 0 at corner. Yields magenta-cyan-yellow map.
        colorMat(:,i) = 200/255*(1-distances);
    end
    
    figure('Position',[300 300 figSize figSize]);
    s2 = scatter(100*diffmapRot(:,1),100*diffmapRot(:,2),scatterSize,colorMat,'filled',...
        'MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7);
    pbaspect([1 1 1]);
    set(gca,'LineWidth',2,'FontSize',fontSize);
    set(gcf,'Color',[1 1 1]);
    xlim([-3.5 2.5]);
    
    % Write whole-brain color map, as label file where each coordinate is a
    % distinct label
    colorOutputPath = [diffusionDir '/sub-' subjID spaceStr '_desc-DiffusionColorMap_dseg.dlabel.nii'];
    colorOutputScalarPath = [diffusionDir '/sub-' subjID spaceStr '_desc-DiffusionColorMap_dseg.dscalar.nii'];
    if ~exist(colorOutputPath,'file')
        inputPath = [diffusionDir '/sub-' subjID '_task-rest' spaceStr...
            '_desc-Gradient1_diffusionmap.dscalar.nii'];
        [~,hdr] = fpp.util.readDataMatrix(inputPath);
        hdr.diminfo{2}.maps(1).name = 'DiffusionColor';
        hdr.diminfo{2}.maps(1).metadata = struct('key',{},'value',{});
        colorVec = (1:nCoords)';
        fpp.util.writeDataMatrix(colorVec,hdr,colorOutputScalarPath);
        
        % Define LUT file
        colorLUTPath = [diffusionDir '/sub-' subjID spaceStr '_desc-DiffusionColorMap_lut.txt'];
        fid = fopen(colorLUTPath,'w');
        for i=1:nCoords
            fprintf(fid,'%s\n',['LABEL_' int2str(i)]);
            fprintf(fid,'%d %d %d %d %d\n',[i round(255*colorMat(i,:)) 255]);
        end
        fclose(fid);
        
        % Convert scalar to label
        fpp.wb.command('cifti-label-import',colorOutputScalarPath,colorLUTPath,colorOutputPath);
        fpp.util.system(['rm -rf ' colorOutputScalarPath]);
    end
end

end






