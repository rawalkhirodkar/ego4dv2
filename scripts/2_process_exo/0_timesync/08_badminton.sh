###----------------------------------------------------------------------------
BIG_SEQUENCE='08_badminton' ## assemble

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo/${BIG_SEQUENCE}/exo"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/${BIG_SEQUENCE}"

# ###-------------for fencing without masks on---------------
# CAMERAS="aria01--cam01--cam02--cam03--cam04--cam05--cam06--cam07--cam08--cam09--cam10--cam11--cam12--cam13--cam14--cam15"
# START_TIMESTAMPS="04244--03439--03824--03006--03139--02546--01690--02696--03744--01580--02452--02864--03073--02635--03246--03364" 

# SEQUENCE='calibration_badminton'
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='04250' ## this includes the image name
# SEQUENCE_END_TIMESTAMP='06250' ## this is also inclusive

# SEQUENCE='calibration_badminton'
# SEQUENCE_CAMERA_NAME='aria01'
# SEQUENCE_START_TIMESTAMP='04250:20000' ## this includes the image name
# SEQUENCE_END_TIMESTAMP='06250:22000' ## this is also inclusive

###-------------for badminton---------------
CAMERAS="aria01--cam01--cam02--cam03--cam04--cam05--cam06--cam07--cam08--cam09--cam10--cam11--cam12--cam13--cam14--cam15"
START_TIMESTAMPS="04244--03439--03824--03006--03139--02546--01690--02696--03744--01580--02452--02864--03073--02635--03246--03364" 

SEQUENCE='001_badminton'
SEQUENCE_CAMERA_NAME='aria01'
SEQUENCE_START_TIMESTAMP='06400' ## this includes the image name
SEQUENCE_END_TIMESTAMP='07000' ## this is also inclusive


###----------------------------------------------------------------------------
OUTPUT_IMAGE_DIR=$OUTPUT_DIR/$SEQUENCE/'exo'

###----------------------------------------------------------------------------
cd ../../../tools/misc
python exo_time_sync_restructure.py --sequence $SEQUENCE --cameras $CAMERAS \
                            --start-timestamps $START_TIMESTAMPS \
                            --sequence-camera-name $SEQUENCE_CAMERA_NAME \
                            --sequence-start-timestamp $SEQUENCE_START_TIMESTAMP --sequence-end-timestamp $SEQUENCE_END_TIMESTAMP \
                            --data-dir $DATA_DIR --output-dir $OUTPUT_IMAGE_DIR \
