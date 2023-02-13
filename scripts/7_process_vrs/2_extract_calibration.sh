cd ../..

##-------------------------------------------------------------------------------------------
## use the aria app to get the trajectory files and put in the 'trajectory' folder

# BIG_SEQUENCE='06_volleyball'
# # RECORDING=aria01
# # RECORDING=aria02
# # RECORDING=aria03
# RECORDING=aria04

# BIG_SEQUENCE='unc_ego4d'
# RECORDING=aria01

# BIG_SEQUENCE='erwinwalk'
# RECORDING=aria01

BIG_SEQUENCE='erwinwalk2'
RECORDING=aria01

# BIG_SEQUENCE='kentawalk'
# RECORDING=aria01

##-------------------------------------------------------------------------------------------
echo "Processing" $RECORDING
DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"

##-------------------------------------------------------------------------------------------
IMAGES_DIR=$DATA_DIR/$RECORDING/vrs_images
TRAJECTORY_DIR=$DATA_DIR/$RECORDING/trajectory
VRS_CALIB_DIR=$DATA_DIR/$RECORDING/vrs_calib

python tools/vrs_calibration/0_process_vrs_calibration.py --trajectory_dir $TRAJECTORY_DIR --images_dir $IMAGES_DIR --vrs_calib_dir $VRS_CALIB_DIR