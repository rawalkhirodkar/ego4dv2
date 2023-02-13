###----------------------------------------------------------------------------
BIG_SEQUENCE='06_volleyball'

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/${BIG_SEQUENCE}"

# # ###--------------------------------
CAMERAS="aria01--aria02--aria03--aria04" ## 4 arias
# START_TIMESTAMPS="02537--03062--02435--02845" ## this is the second throw, first bounce 
START_TIMESTAMPS="02361--02886--02258--02669" ## this is the first throw, first bounce 

# # # ###--------------------------------
# SEQUENCE='calibration_volleyball'

# ## pick the sequence start and end times with respect to an ego camera
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='03410:7500' ## this includes the image name
# SEQUENCE_END_TIMESTAMP='05410:9500' ## this is also inclusive

# # ###--------------------------------
SEQUENCE='001_volleyball'

## pick the sequence start and end times with respect to an ego camera
SEQUENCE_CAMERA_NAME='aria01'
SEQUENCE_START_TIMESTAMP='03410' ## this includes the image name
SEQUENCE_END_TIMESTAMP='04010' ## this is also inclusive


###----------------------------------------------------------------------------
OUTPUT_IMAGE_DIR=$OUTPUT_DIR/$SEQUENCE/'ego'

###----------------------------------------------------------------------------
cd ../../../tools/misc
python ego_time_sync_restructure.py --sequence $SEQUENCE --cameras $CAMERAS \
                            --start-timestamps $START_TIMESTAMPS \
                            --sequence-camera-name $SEQUENCE_CAMERA_NAME \
                            --sequence-start-timestamp $SEQUENCE_START_TIMESTAMP --sequence-end-timestamp $SEQUENCE_END_TIMESTAMP \
                            --data-dir $DATA_DIR --output-dir $OUTPUT_IMAGE_DIR \
