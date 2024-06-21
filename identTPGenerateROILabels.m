
% Script to generate surface label files containing search spaces and ROIs
% from IDENT ROI analysis.

bidsDir = '/path/to/data/derivatives/fpp';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
space = 'fsLR'; % ROI space
den = '32k';    % ROI den
overwrite = 0;

% Define ROI descriptions
% Search space name for TP
searchNames{1} = {'handDrawnLTP','handDrawnRTP'};
% Search space name for PRC
searchNames{2} = {'handDrawnLPRC','handDrawnRPRC'};
% Search space name for ASTS
searchNames{3} = {'handDrawnLASTS','handDrawnRASTS'};
% Search space name for AIT
searchNames{4} = {'handDrawnLAIT','handDrawnRAIT'};
% Search space names for social network
searchNames{5} = {'mmpApexLTPJ','mmpApexLMPFC','mmpApexLMPC','mmpApexLSFG','mmpLMSTS',...
    'mmpApexRTPJ','mmpApexRMPFC','mmpApexRMPC','mmpApexRSFG','mmpRMSTS'};
% Search space names for face areas
searchNames{6} = {'mmpLFus','mmpLPIT','mmpLPSTS','mmpRFus','mmpRPIT','mmpRPSTS'};
searchNames{7} = {'mmpLEVC','mmpLPIPS','mmpLAIPS','mmpLFEF','mmpREVC','mmpRPIPS','mmpRAIPS','mmpRFEF'};
searchNames{8} = {'mmpLVVC','mmpLLOSmall','mmpRVVC','mmpRLOSmall'};
searchHemis = {[1 2],[1 2],[1 2],[1 2],[1 1 1 1 1 2 2 2 2 2],[1 1 1 2 2 2],[1 1 1 1 2 2 2 2],[1 1 2 2]};
% All search spaces
searchNamesAll = horzcat(searchNames{:});
searchHemisAll = horzcat(searchHemis{:});
taskContrasts = {'famvisualSm2PersonVsPlace','famvisualSm2PersonVsPlace','famvisualSm2PersonVsPlace',...
    'famvisualSm2PersonVsPlace','famvisualSm2PersonVsPlace','famvisualSm2PersonVsPlace','AllVsRest','famvisualSm2PlaceVsObjectInverted'};
roiColors = {[170 68 153],[136 204 238],[221 204 119],[153 153 51],[136 34 85],[204 102 119],[125 0 198],[0 255 0]}; % Label colors by ROI type
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
    for s=8
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
        if ismember(s,[9:12 14:17 25:32]) % Remove sub from name for mmpApex ROIs
            subjStr = [];
        else
            subjStr = subject;
        end
        roiPath = [anatDir '/' fpp.bids.changeName('',{'sub','space','den','desc'},...
            {subjStr,space,den,searchNamesAll{s}},'mask','.dscalar.nii')];
        roiLabelPath = fpp.bids.changeName(roiPath,[],[],'dseg','.dlabel.nii');
        if exist(roiLabelPath,'file'), continue; end
        
        % Import label text file
        if ~exist(roiLabelPath,'file') && ~overwrite
            txtPath = [roiDir '/tmpLabel20395823.txt'];
            fid = fopen(txtPath,'w');
            fprintf(fid,'%s\n',searchNamesAll{s});
            fprintf(fid,'%d %d %d %d %d\n',[1 0 0 0 255]);
            fclose(fid);
            fpp.wb.command('cifti-label-import',roiPath,txtPath,roiLabelPath);
            fpp.util.system(['rm -rf ' txtPath]);
        end
        
        % Convert to border
        h = searchHemisAll(s);
        roiBorderPath = fpp.bids.changeName(roiLabelPath,'hemi',hemis{h},[],'.border');
        if ~exist(roiBorderPath,'file')
            fpp.wb.command('cifti-label-to-border',roiLabelPath,[],[],['-border ' surfacePaths{h} ' ' roiBorderPath]);
        end
        
        disp(roiLabelPath);
    end
end

