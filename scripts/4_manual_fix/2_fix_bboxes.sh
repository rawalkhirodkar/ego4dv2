cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/manual_fix/0_fix_bboxes.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# # SEQUENCE='001_tagging'; DEVICES=0,
# # SEQUENCE='002_tagging'; DEVICES=1,
# # SEQUENCE='003_tagging'; DEVICES=2,
# # SEQUENCE='004_tagging'; DEVICES=3,
# # SEQUENCE='005_tagging'; DEVICES=3,
# # SEQUENCE='006_tagging'; DEVICES=2,
# # SEQUENCE='007_tagging'; DEVICES=1,

# # ###------------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'

# # SEQUENCE='001_legoassemble'; DEVICES=2,
# # SEQUENCE='002_legoassemble'; DEVICES=3,
# # SEQUENCE='003_legoassemble'; DEVICES=3,
# # SEQUENCE='004_legoassemble'; DEVICES=3,
# # SEQUENCE='005_legoassemble'; DEVICES=3,

# SEQUENCE='006_legoassemble'; DEVICES=3,

# ###------------------------------------------------------------------
BIG_SEQUENCE='08_badminton'
SEQUENCE='001_badminton'; DEVICES=2,

###------------------------------------------------------------------
# SEQUENCE='012_frisbee'; DEVICES=3,
# SEQUENCE='013_lego'; DEVICES=3,
# SEQUENCE='014_basketball'; DEVICES=3,
# SEQUENCE='015_soccer1'; DEVICES=3,

# SEQUENCE='002_pro_soccer_1'

###------------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

# ###----------------------------------------------------------------
LOG_DIR="$(echo "${OUTPUT_DIR}/logs/fix_bbox")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 


# # # # # # # # ###--------------debug-----------------------------
# CAMERAS='4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4:4'
# TIMESTAMPS="543:544:545:546:547:548:549:550:551:552:553:554:555:556:557:558:559:560:561:562:563:564:565:566:567:568:569:570"

###---------------------------------------------------------------------------
# CAMERAS='1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1'
# CAMERAS='2:2'
# CAMERAS='3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3'
# CAMERAS='5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5:5'
# CAMERAS='6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6'
# CAMERAS='7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7'
# CAMERAS='8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8:8'

###---------------------------------------------------------------------------

# CAMERAS='2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2:2'
# CAMERAS='3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3'
# CAMERAS='6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6:6'
# CAMERAS='7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7:7'

# CAMERAS='3:3:3:3:3'
# TIMESTAMPS="28:29:30:31:32"

# CAMERAS='3:3'
# TIMESTAMPS="100:107"

CAMERAS='11:11:11:11:11:11:11:11:11:11:11:11'
TIMESTAMPS="132:133:134:135:136:137:138:139:140:141"

LOG_FILE="$(echo "${LOG_DIR}/log_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --timestamps $TIMESTAMPS \
                    --camera $CAMERAS \

