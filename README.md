# IDENT study analysis scripts

This repo contains fMRI preprocessing/analysis scripts for the IDENT study, in which participants performed a variety of tasks engaging reasoning and memory about close familiar people and places (IDENT = identification).

Links to data and further information:
* [Methods](https://osf.io/5yjgh/)
* [Data](https://openneuro.org/datasets/ds003814)
* [Preprint](https://www.biorxiv.org/content/10.1101/2021.09.23.461550v2)

Note: scripts for behavioral data analysis are not yet included. Behavioral data first needs to be reformatted to the BIDS spec, and added to the public dataset.

## Usage

The scripts make heavy use of [fmriPermPipe v2.0.1](https://github.com/bmdeen/fmriPermPipe/releases/tag/v2.0.1). This package and its dependences must be installed and sourced for these scripts to run. In each of the scripts included here, the variable studyDir must be changed to reflect the location of the data on your local machine. The directory specified by studyDir should contain a subdirectory "rawdata" with the BIDS-formatted raw dataset. The scripts will produce an additional subdirectory named "derivatives," where derivative outputs will be written.

The scripts should be run in the following order:

_Preprocessing and whole-brain analysis_
* `identPreprocWrapper` - Preprocess anatomical, spin echo "field map," and functional data. Contains multiple sections that run individual steps, across participants. Some of these steps (e.g. functional preprocessing and surface resampling) are highly computationally demanding, and you may want to split these jobs across multiple processes for efficiency.
* `identAnalysisWrapper` - Perform first and second-level whole-brain analyses, and search space definition for region-of-interest (ROI) analysis. Also contains multiple sections that run individual steps. Before running this script, the .tsv files in the contrasts directory must be copied into the derivatives/fpp directory generated by identPreprocWrapper.

_Additional analyses_
* `identInterdigitation` - extract responses (from odd runs) along paths between person- and place-preferring anchor coordinates (identified in even runs).
* `identROIExtractWrapper` - extract responses across all tasks/conditions from functionally defined ROIs.
* `identGenerateROILabels` - generate Connectome Workbench surface label CIFTI files for ROIs generated by identROIExtract, for visualization
* `identRestROICorrelationWrapper` - compute matrix of resting-state correlations between functionally-defined ROIs.
* `identRestSurfConnWrapper` - compute whole-brain resting-state correlation maps using functionally-defined ROIs as seeds.
* `identRestDiffusionMapWrapper` - compute and visualize diffusion embedding of resting-state functional connectivity data.

_Data quality checks_
* `identMeanTSNR` - compute tSNR maps for task-based functional data, as well as mean tSNR within and across participants.
* `identCheckMotion` - compute distributions of framewise displacement values for each participant, and plot.
