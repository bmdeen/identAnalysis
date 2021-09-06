
% Script to generate surface label files containing search spaces and ROIs
% from IDENT ROI analysis.

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
space = 'fsLR'; % ROI space
den = '32k';    % ROI surface density

% Define ROI descriptions
% Search space names for social network
searchNames{1} = {'mmpApexMPFC','mmpApexMPC','mmpApexTPJ','mmpApexASTS','mmpApexSFG','mmpApexTP'};
% Search space names for spatial network
searchNames{2} = {'mmpApexMPFC','mmpApexMPC','mmpApexTPJ','mmpApexASTS','mmpApexSFG','mmpApexTH'};
% Search space names for object network
searchNames{3} = {'mmpObjectIFS','mmpObjectPremotor','mmpObjectPF','mmpObjectPHT'};
% Search space names for ToM effect
searchNames{4} = {'mmpApexMPFC','mmpApexMPC','mmpApexTPJ','mmpApexASTS','mmpApexSFG','mmpApexTP'};
% Search space names for langloc SentencesVsNonwords
searchNames{5} = {'mmpApexLTPJ','mmpLngLPostTemp','mmpLngLAntTemp','mmpLngLMFG','mmpLngLIFG'};
% All search spaces
searchNamesAll = unique(horzcat(searchNames{:}));
taskContrasts = {'famsemanticSm2PersonVsPlace','famsemanticSm2PersonVsPlaceInverted','famsemanticSm2PlaceVsObjectInverted'...
    'tomloc2Sm2BeliefVsPhoto','langlocSm2SentencesVsNonwords'};
roiColors = {[255 0 0],[0 0 255],[0 255 0],[255 150 0],[255 255 0]};   % Label colors by ROI type
roiStr = 'Top5Pct';
smStr = 'Sm2';

for sub=1:length(subjects)
    subject = subjects{sub};
    
    % Directories and names
    subjDir = [bidsDir '/sub-' subject];
    roiDir = [subjDir '/roi'];
    funcDir = [subjDir '/func'];
    anatDir = [subjDir '/anat'];
    
    roiDescs = {};
    for s=1:length(searchNames)
        for r=1:length(searchNames{s})
            roiDescs{s}{r} = [searchNames{s}{r} taskContrasts{s} roiStr];
        end
    end
    
    % Midthickness surface paths
    hemis = {'L','R'};
    for h=1:2
        surfacePaths{h} = [anatDir '/' fpp.bids.changeName('',{'sub','hemi','space','den'},...
            {subject,hemis{h},'individual',den},'midthickness','.surf.gii')];
    end
    
    % Loop through ROIs, generate label surface
    for s=1:length(searchNames)
        for r=1:length(searchNames{s})
            roiPath = [roiDir '/' fpp.bids.changeName('',{'sub','space','den','desc'},...
                {subject,space,den,roiDescs{s}{r}},'mask','.dscalar.nii')];
            roiLabelPath = fpp.bids.changeName(roiPath,[],[],'dseg','.dlabel.nii');
            if exist(roiLabelPath,'file'), continue; end
            
            % Import label text file
            txtPath = [roiDir '/tmpLabel20395823.txt'];
            fid = fopen(txtPath,'w');
            fprintf(fid,'%s\n',roiDescs{s}{r});
            fprintf(fid,'%d %d %d %d %d\n',[1 roiColors{s} 255]);
            fclose(fid);
            fpp.wb.command('cifti-label-import',roiPath,txtPath,roiLabelPath);
            fpp.util.system(['rm -rf ' txtPath]);
            
            disp(roiLabelPath);
        end
    end
    
    % Loop through search spaces, generate label surface
    for s=1:length(searchNamesAll)
        roiPath = [anatDir '/' fpp.bids.changeName('',{'space','den','desc'},...
            {space,den,searchNamesAll{s}},'mask','.dscalar.nii')];
        roiLabelPath = fpp.bids.changeName(roiPath,[],[],'dseg','.dlabel.nii');
        if exist(roiLabelPath,'file'), continue; end
        
        % Import label text file
        txtPath = [roiDir '/tmpLabel20395823.txt'];
        fid = fopen(txtPath,'w');
        fprintf(fid,'%s\n',searchNamesAll{s});
        fprintf(fid,'%d %d %d %d %d\n',[1 0 0 0 255]);
        fclose(fid);
        fpp.wb.command('cifti-label-import',roiPath,txtPath,roiLabelPath);
        fpp.util.system(['rm -rf ' txtPath]);
        
        % Convert to CIFTI
        disp(roiLabelPath);
        
        % Convert to border
        roiBorderPaths{1} = fpp.bids.changeName(roiLabelPath,'hemi','L',[],'.border');
        roiBorderPaths{2} = fpp.bids.changeName(roiLabelPath,'hemi','R',[],'.border');
        fpp.wb.command('cifti-label-to-border',roiLabelPath,[],[],['-border ' surfacePaths{1}...
            ' ' roiBorderPaths{1} ' -border ' surfacePaths{2} ' ' roiBorderPaths{2}]);
    end
end

