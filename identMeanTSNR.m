
% Script to generate mean tSNR maps for each subject, and across group, for
% IDENT study.
%
% Note: not including resting-state data, because I've only
% surface-resampled resting-state data with global mean removed, which will
% influence tSNR.

studyDir = '/path/to/data';
bidsDir = [studyDir '/derivatives/fpp'];
subjects = {'ident01','ident02','ident03','ident04','ident05','ident06',...
    'ident07','ident08','ident09','ident10'};
tasks = {'famvisual','famsemantic','famepisodic','tomloc2','dyloc','langloc'};
nRuns = [5 5 5 4 6 4];
snrMeanAllPath = [bidsDir '/group/space-fsLR_den-32k_desc-preprocSm2_tsnr.dscalar.nii'];
mathCmd2 = '(';
mathVars2 = '';

for s=1:length(subjects)
    subjID = subjects{s};
    funcDir = [bidsDir '/sub-' subjID '/func'];
    anatDir = [bidsDir '/sub-' subjID '/anat'];
    templatePath = [anatDir '/sub-' subjID '_space-fsLR_den-32k_curv.dscalar.nii'];
    snrMeanPath = [funcDir '/sub-' subjID '_space-fsLR_den-32k_desc-preprocSm2_tsnr.dscalar.nii'];
    mathCmd = '(';
    mathVars = '';
    mapCount = 0;
    for t=1:length(tasks)
        for r=1:nRuns(t)
            dataPath = [funcDir '/' fpp.bids.changeName('',{'sub','task','run','space',...
                'res','den','desc'},{subjID,tasks{t},fpp.util.numPad(r,2),'individual',...
                '2','32k','preprocSm2'},'bold','.dtseries.nii')];
            snrPath = fpp.bids.changeName(dataPath,[],[],'tsnr','.dscalar.nii');
            snrFsLRPath = fpp.bids.changeName(snrPath,{'space','res'},{'fsLR',''});
            fpp.util.tsnrMap(dataPath,snrPath);     % Compute tSNR map
            fpp.wb.command('cifti-create-dense-from-template',templatePath,[],...
                snrFsLRPath,['-cifti ' snrPath]);   % Remove volume components
            % Modify wb_command variables to add map to average
            mapCount = mapCount+1;
            if mapCount==1
                mathCmd = [mathCmd 'x' int2str(mapCount)];
            else
                mathCmd = [mathCmd '+x' int2str(mapCount)];
            end
            mathVars = [mathVars '-var x' int2str(mapCount) ' ' snrFsLRPath ' '];
            
            disp([subjID ' ' tasks{t} '-' int2str(r)]);
        end
    end
    % Average all tSNR maps for a given subject
    mathCmd = [mathCmd ')/' int2str(mapCount)];
    fpp.wb.command('cifti-math',[],mathCmd,snrMeanPath,mathVars);
    % Modify wb_command variables to add map to average
    if s==1
        mathCmd2 = [mathCmd2 'x' int2str(s)];
    else
        mathCmd2 = [mathCmd2 '+x' int2str(s)];
    end
    mathVars2 = [mathVars2 '-var x' int2str(s) ' ' snrMeanPath ' '];
end

% Average tSNR maps across subjects
mathCmd2 = [mathCmd2 ')/' int2str(length(subjects))];
fpp.wb.command('cifti-math',[],mathCmd2,snrMeanAllPath,mathVars2);

