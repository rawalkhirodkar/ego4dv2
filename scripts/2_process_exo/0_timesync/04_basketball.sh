###----------------------------------------------------------------------------
BIG_SEQUENCE='04_basketball'

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo/${BIG_SEQUENCE}/exo"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/${BIG_SEQUENCE}"

###-------------for basketball---------------
CAMERAS="aria01--cam01--cam02--cam03--cam04--cam05--cam06--cam07--cam08"
START_TIMESTAMPS="01688--11649--10755--10179--11206--10351--10011--11018--10591" 


# # ###--------------------------------
SEQUENCE='001_basketball'

## pick the sequence start and end times with respect to an ego camera
SEQUENCE_CAMERA_NAME='aria01'
SEQUENCE_START_TIMESTAMP='02800' ## this includes the image name
SEQUENCE_END_TIMESTAMP='03400' ## this is also inclusive

###----------------------------------------------------------------------------
OUTPUT_IMAGE_DIR=$OUTPUT_DIR/$SEQUENCE/'exo'

###----------------------------------------------------------------------------
cd ../../../tools/misc
python exo_time_sync_restructure.py --sequence $SEQUENCE --cameras $CAMERAS \
                            --start-timestamps $START_TIMESTAMPS \
                            --sequence-camera-name $SEQUENCE_CAMERA_NAME \
                            --sequence-start-timestamp $SEQUENCE_START_TIMESTAMP --sequence-end-timestamp $SEQUENCE_END_TIMESTAMP \
                            --data-dir $DATA_DIR --output-dir $OUTPUT_IMAGE_DIR \