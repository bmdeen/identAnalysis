
% Script to check for presence of whole-brain responses within specific
% subregions defined by the MMP parcellation: PHC, RSC, and TP.
%
% Specifically checks for responses to people > places in TP, and places >
% people in PHC and RSC, for visual, semantic, and episodic tasks.

studyDir = '/path/to/data';
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06','ident07','ident08','ident09','ident10'};
searchNames = {'TP','PHC','RSC'};
inversionFactor = [1 -1 -1];	% 1 fpr people > places, -1 for places > people, by region
prefices = {'L','R'};
hemiNames = {'Left','Right','Bilateral'};
parcSpace = 'fsLR_den-32k';
zStatSpace = 'space-individual_res-2_den-32k_desc-Sm2';
contrastName = 'PersonVsPlace';
tasks = {'famvisual','famsemantic','famepisodic'};
fdrDecimalStr = 'p';
fdrThresh = .01;
responseMatrix = [];    % Boolean matrix (whether response exists)
                        % Subject by task by area by hemi
subsWithResponse = [];  % # of subjects/tasks with significant response,
                        % area by hemi

% TP: TGd
searchInds{1}{1} = 311;
searchInds{1}{2} = 131;
% TH: PHA1, 2, 3
searchInds{2}{1} = [306 335 307];
searchInds{2}{2} = [126 155 127];
% RSC
searchInds{3}{1} = 194;
searchInds{3}{2} = 14;


for s=1:length(subjects)
    subjID = subjects{s};
    anatDir = [studyDir '/derivatives/fpp/sub-' subjID '/anat'];
    analysisDir = [studyDir '/derivatives/fpp/sub-' subjID '/analysis'];
    subjStr = ['sub-' subjID '_'];
    if strcmp(parcSpace(1:4),'fsLR')
        subjStr = '';
    end
    parcPath = [anatDir '/' subjStr 'space-' parcSpace '_desc-MMP_dseg.dlabel.nii'];
    
    mmp = fpp.util.readDataMatrix(parcPath);
    
    for t=1:length(tasks)
        task = tasks{t};
        model2Dir = [analysisDir '/sub-' subjID '_task-' task '_' zStatSpace '_model2arma'];
        
        fdrDesc = ['FDR' strrep(num2str(fdrThresh),'.',fdrDecimalStr)];
        zStatPath = [model2Dir '/sub-' subjID '_task-' task '_' zStatSpace...
            contrastName fdrDesc '_zstat.dscalar.nii'];
        
        zMap = fpp.util.readDataMatrix(zStatPath);
        
        for r=1:length(searchNames)
            for h=1:2
                % Check for presence of whole-brain response within parcel
                responseMatrix(s,t,r,h) = sum(inversionFactor(r)*...
                    zMap(ismember(mmp,searchInds{r}{h}))>0)>0;
            end
            responseMatrix(s,t,r,3) = responseMatrix(s,t,r,1) || responseMatrix(s,t,r,2);
        end
        disp(['Finished ' subjID ', ' task]);
    end
end

% Output results, summarized across subjects.
for h=1:length(hemiNames)
    for r = 1:length(searchNames)
        subsWithResponse(r,h) = sum(sum(responseMatrix(:,:,r,h)));
        disp([hemiNames{h} ' ' searchNames{r} ': ' int2str(subsWithResponse(r,h))]);
    end
end







