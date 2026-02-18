#! /bin/bash
#
# Run script for flywheel/recon-all-clinical Gear.
#
# Authorship: Anastasia Smirnova, Niall Bourke
#
##############################################################################
# Define directory names and containers

SUBJ_ID=$1
SES_ID=$2
base_filename=$3

FLYWHEEL_BASE=/flywheel/v0
INPUT_DIR=$FLYWHEEL_BASE/input/
OUTPUT_DIR=$FLYWHEEL_BASE/output
WORKDIR=$FLYWHEEL_BASE/work
CONFIG_FILE=$FLYWHEEL_BASE/config.json
CONTAINER='[flywheel/recon-any]'
source /usr/local/freesurfer/SetUpFreeSurfer.sh

echo "permissions"
ls -ltra /flywheel/v0/

mkdir $FLYWHEEL_BASE/work
chmod 777 $FLYWHEEL_BASE/work
##############################################################################
# Parse configuration
function parse_config {

  CONFIG_FILE=$FLYWHEEL_BASE/config.json
  MANIFEST_FILE=$FLYWHEEL_BASE/manifest.json

  if [[ -f $CONFIG_FILE ]]; then
    echo "$(cat $CONFIG_FILE | jq -r '.config.'$1)"
  else
    CONFIG_FILE=$MANIFEST_FILE
    echo "$(cat $MANIFEST_FILE | jq -r '.config.'$1'.default')"
  fi
}

# define output choise:
config_output_nifti="$(parse_config 'output_nifti')"
config_output_mgh="$(parse_config 'output_mgh')"
config_rob="$(parse_config 'robust')"

##############################################################################
# Define brain and face templates

brain_template=$FLYWHEEL_BASE/talairach_mixed_with_skull.gca
face_template=$FLYWHEEL_BASE/face.gca

##############################################################################
# Handle INPUT file

# Find input file In input directory with the extension
input_file=`find $INPUT_DIR -iname '*.nii' -o -iname '*.nii.gz'`

# Check that input file exists
if [[ -e $input_file ]]; then
  echo "${CONTAINER}  Input file found: ${input_file}"

    # Determine the type of the input file
  if [[ "$input_file" == *.nii ]]; then
    type=".nii"
  elif [[ "$input_file" == *.nii.gz ]]; then
    type=".nii.gz"
  fi
  
else
  echo "${CONTAINER}: No inputs were found within input directory $INPUT_DIR"
  exit 1
fi

##############################################################################
# Run mri_synthseg algorithm

# Set initial exit status
recon_all_clinical_exit_status=0


if [[ $config_rob == 'true' ]]; then
  robust='--robust'
fi

# Run recon-any with options
if [[ -e $input_file ]]; then
  echo "Running recon-any..."
  
  tcsh /usr/local/freesurfer/bin/recon-any.sh -i $input_file -subjid $SUBJ_ID -threads 4 -side both -sdir $WORKDIR
  recon_all_clinical_exit_status=$?
fi

# Step 3: Copy output files to the output directory
#mri_convert $WORKDIR/$base_filename/mri/synthseg.mgz $OUTPUT_DIR/synthseg.nii
cp $WORKDIR/$SUBJ_ID/stats/synthseg.vol.csv $WORKDIR/synthseg.vol.csv
cp $WORKDIR/$SUBJ_ID/stats/synthseg.qc.csv $WORKDIR/synthseg.qc.csv
mri_convert --out_orientation RAS $WORKDIR/$SUBJ_ID/mri/synthSR.mgz $WORKDIR/synthSR.nii.gz
mri_convert --out_orientation RAS $WORKDIR/$SUBJ_ID/mri/aparc+aseg.mgz $WORKDIR/aparc+aseg.nii.gz
zip -r $OUTPUT_DIR/$SUBJ_ID.zip $WORKDIR/$SUBJ_ID


# Step 4: Extract cortical thickness measures
# Set SUBJECTS_DIR to the work directory
export SUBJECTS_DIR=$WORKDIR
aparcstats2table --subjects $SUBJ_ID --hemi lh --meas thickness --parc=aparc --tablefile=$WORKDIR/aparc_lh.csv
aparcstats2table --subjects $SUBJ_ID --hemi rh --meas thickness --parc=aparc --tablefile=$WORKDIR/aparc_rh.csv

# Step 5: Extract area measures
aparcstats2table --subjects $SUBJ_ID --hemi lh --meas area --parc=aparc --tablefile=$WORKDIR/aparc_area_lh.csv
aparcstats2table --subjects $SUBJ_ID --hemi rh --meas area --parc=aparc --tablefile=$WORKDIR/aparc_area_rh.csv

#Copy the file under docs to the output directory
cp $FLYWHEEL_BASE/docs/output-walkthrough.txt $OUTPUT_DIR/output-walkthrough.txt


# Handle Exit status
if [[ $recon_all_clinical_exit_status == 0 ]]; then
  echo -e "${CONTAINER} Success!"
  exit 0
else
  echo "${CONTAINER}  Something went wrong! recon-any exited non-zero!"
  exit 1
fi
