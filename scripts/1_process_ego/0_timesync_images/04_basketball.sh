###----------------------------------------------------------------------------
BIG_SEQUENCE='04_basketball'

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/${BIG_SEQUENCE}"

###-------------for basketball---------------
CAMERAS="aria01--aria02--aria03--aria04" ## 4 arias
START_TIMESTAMPS="01688--01815--01777--01818" ##this 00001.jpg for the exo cameras

# # ###--------------------------------
# # SEQUENCE='basketball_calibration'

# ## pick the sequence start and end times with respect to an ego camera
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='04320' ## this includes the image name
# # SEQUENCE_END_TIMESTAMP='05320' ## this is also inclusive

## the crash happens at 5360-5400

# ###--------------------------------
SEQUENCE='001_basketball'

## pick the sequence start and end times with respect to an ego camera
SEQUENCE_CAMERA_NAME='aria01'
SEQUENCE_START_TIMESTAMP='02800' ## this includes the image name
SEQUENCE_END_TIMESTAMP='03400' ## this is also inclusive


# # ###--------------------------------
# SEQUENCE='001_basketball'

# ## pick the sequence start and end times with respect to an ego camera
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='04320' ## this includes the image name
# SEQUENCE_END_TIMESTAMP='04520' ## this is also inclusive


###----------------------------------------------------------------------------
OUTPUT_IMAGE_DIR=$OUTPUT_DIR/$SEQUENCE/'ego'


###----------------------------------------------------------------------------
cd ../../../tools/misc
python ego_time_sync_restructure.py --sequence $SEQUENCE --cameras $CAMERAS \
                            --start-timestamps $START_TIMESTAMPS \
                            --sequence-camera-name $SEQUENCE_CAMERA_NAME \
                            --sequence-start-timestamp $SEQUENCE_START_TIMESTAMP --sequence-end-timestamp $SEQUENCE_END_TIMESTAMP \
                            --data-dir $DATA_DIR --output-dir $OUTPUT_IMAGE_DIR \
