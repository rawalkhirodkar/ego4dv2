cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/vis/refine_poses3d.py'
# SEQUENCE_ROOT_DIR='/home/rawalk/Desktop/datasets/ego_exo/main'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

SEQUENCE='001_tagging'; DEVICES=0,
# SEQUENCE='002_tagging'; DEVICES=1,
# SEQUENCE='003_tagging'; DEVICES=2,
# SEQUENCE='004_tagging'; DEVICES=3,
# SEQUENCE='005_tagging'; DEVICES=0,
# SEQUENCE='006_tagging'; DEVICES=3,
# SEQUENCE='007_tagging'; DEVICES=2,
# SEQUENCE='008_tagging'; DEVICES=3,
# SEQUENCE='009_tagging'; DEVICES=0,
# SEQUENCE='010_tagging'; DEVICES=1,
# SEQUENCE='011_tagging'; DEVICES=2,
# SEQUENCE='012_frisbee'; DEVICES=3,
# SEQUENCE='013_lego'; DEVICES=3,


# OUTPUT_DIR="/home/rawalk/Desktop/datasets/ego_exo/main/$SEQUENCE/processed_data"
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$SEQUENCE/processed_data"

##----------------------------------------------------------------
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$SEQUENCE
LOG_DIR="$(echo "${OUTPUT_DIR}/logs/refine_poses3d")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 


# # # ###--------------------------debug------------------------------
START_TIME=1
END_TIME=-1

LOG_FILE="$(echo "${LOG_DIR}/log_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --start_time $START_TIME \
                    --end_time $END_TIME \



