cd ../..

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


echo "Processing" $RECORDING
DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"


SOURCE_IMAGES_DIR=$DATA_DIR/$RECORDING/'vrs_images'
SOURCE_CALIB_DIR=$DATA_DIR/$RECORDING/'vrs_calib'

TARGET_IMAGES_DIR=$DATA_DIR/$RECORDING/'images'
TARGET_CALIB_DIR=$DATA_DIR/$RECORDING/'calib'

python tools/vrs_calibration/1_process_data.py --source_images_dir $SOURCE_IMAGES_DIR --source_calib_dir $SOURCE_CALIB_DIR \
									 --target_images_dir $TARGET_IMAGES_DIR --target_calib_dir $TARGET_CALIB_DIR \

									 