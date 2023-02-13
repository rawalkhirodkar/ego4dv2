###---------------assign recording------------------------------------------
# BIG_SEQUENCE='06_volleyball'
# # RECORDING=aria01
# # RECORDING=aria02
# # RECORDING=aria03
# # RECORDING=aria04

# BIG_SEQUENCE='unc_ego4d'
# RECORDING=aria01

# BIG_SEQUENCE='erwinwalk'
# RECORDING=aria01

BIG_SEQUENCE='erwinwalk2'
RECORDING=aria01

# BIG_SEQUENCE='kentawalk'
# RECORDING=aria01

##-------------------------------------------------------------------------------------------

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"

RECORDING_FILE=$DATA_DIR/$RECORDING/video.vrs
OUTPUT_DIR=$DATA_DIR/$RECORDING/vrs_images

# # ###---------------extract VRS------------------------------------------
vrs extract-all $RECORDING_FILE --to $OUTPUT_DIR

sudo chmod -R 777 $OUTPUT_DIR


###----up next, upload the vrs file to the MPS service on the aria Mac app
##-- download the trajectory data in the "trajectory" folder. Adjacent to the images folder
## -- the folder should contain: closed_loop_trajectory.csv, online_calibration.jsonl