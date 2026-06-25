# Release notes
0.4.2 : Working version of recon-any
0.4.5 : Output derivatives to directory after making changes reflecting recon-any output (that is different from recon-all-clinical; e.g.: capitalisation of filenames)
0.4.6 and 0.4.7: attempted fixes to output but visibly still problems with paths, and non-existing columnn names ('subject' in synthseg vols)
0.4.8: final working version (hopefully) with fixed bugs
0.4.9: Added a walltime of 6 hours (in start.sh)
0.4.10: ZIP not being output to the output directory. Reordered steps so ZIP captures everything at the end.
0.4.13:  Fix volumetric output (pivot and have structure labels as columns instead of rows)
0.4.14-0.4.17: Changes to the Dockerfile and Freesurfer build (moved from dev to 8.1.0)
0.4.18: Fixed the mri_convert issue which corrupte aparc+aseg file being output in the analysis output folder. This does not affect previous or future analyses. It was purely a post-processing/export issue
0.4.19: Scanner software version values can be probmematic when of type 'list', change this to cast to string to avoid error 'unhashable type list'.