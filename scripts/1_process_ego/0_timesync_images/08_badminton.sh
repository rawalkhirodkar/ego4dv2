###----------------------------------------------------------------------------
BIG_SEQUENCE='08_badminton' ## assemble

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/${BIG_SEQUENCE}"

# ###-------------for badminton---------------
# CAMERAS="aria01--aria02--aria03--aria04" ## 4 arias
# START_TIMESTAMPS="04244--04325--04153--04408" ##third throw, first bounce, by rawal


# SEQUENCE='calibration_badminton'
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='04250:20000' ## this includes the image name
# SEQUENCE_END_TIMESTAMP='06250:22000' ## this is also inclusive


###-------------for badminton---------------
CAMERAS="aria01--aria02--aria03--aria04" ## 4 arias
START_TIMESTAMPS="04244--04325--04153--04408" ##third throw, first bounce, by rawal

SEQUENCE='001_badminton'
SEQUENCE_CAMERA_NAME='aria01'
SEQUENCE_START_TIMESTAMP='06400' ## this includes the image name
SEQUENCE_END_TIMESTAMP='07000' ## this is also inclusive

###----------------------------------------------------------------------------
OUTPUT_IMAGE_DIR=$OUTPUT_DIR/$SEQUENCE/'ego'

###----------------------------------------------------------------------------
cd ../../../tools/misc
python ego_time_sync_restructure.py --sequence $SEQUENCE --cameras $CAMERAS \
                            --start-timestamps $START_TIMESTAMPS \
                            --sequence-camera-name $SEQUENCE_CAMERA_NAME \
                            --sequence-start-timestamp $SEQUENCE_START_TIMESTAMP --sequence-end-timestamp $SEQUENCE_END_TIMESTAMP \
                            --data-dir $DATA_DIR --output-dir $OUTPUT_IMAGE_DIR \
