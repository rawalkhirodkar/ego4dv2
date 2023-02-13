cd ../..

###------------note this has to be run inside the mmhuman docker---------------
###--------------------------------------------------------------------------
RUN_FILE='tools/process_smpl/5_get_smpl_trajectory.py'

SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

# ####-----------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# # SEQUENCE='008_tagging'; DEVICES=2,
# # SEQUENCE='009_tagging'; DEVICES=2,
# # SEQUENCE='010_tagging'; DEVICES=2,

# SEQUENCE='011_tagging'; DEVICES=2,

# ###------------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'

# # SEQUENCE='001_legoassemble'; DEVICES=2,
# # SEQUENCE='002_legoassemble'; DEVICES=0,
# # SEQUENCE='003_legoassemble'; DEVICES=0,
# # SEQUENCE='004_legoassemble'; DEVICES=0,
# # SEQUENCE='005_legoassemble'; DEVICES=0,

# SEQUENCE='006_legoassemble'; DEVICES=0,


# # ###------------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'; DEVICES=0,

# ###------------------------------------------------------------------
BIG_SEQUENCE='06_volleyball'
SEQUENCE='001_volleyball'; DEVICES=0,

# ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# # SEQUENCE='001_fencing2'; DEVICES=3,
# SEQUENCE='002_fencing2'; DEVICES=0,
# SEQUENCE='003_fencing2'; DEVICES=1,
# # SEQUENCE='004_fencing2'; DEVICES=2,

# # 
# # ###------------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='001_badminton'; DEVICES=3,


###----------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE
NUM_JOBS=4

###----------------------------------------------------------------
LOG_DIR="$(echo "${OUTPUT_DIR}/logs/smpl")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 


###----------------------------------------------------------
START_TIME=1
END_TIME=-1
LOG_FILE="$(echo "${LOG_DIR}/log_smpl_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}

CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --start_time $START_TIME \
                    --end_time $END_TIME | tee $LOG_FILE

# ###-------------------debug-------------------------
# CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
#                     --sequence_path ${SEQUENCE_PATH} \
#                     --output_path $OUTPUT_DIR \
#                     --start_time $START_TIME \
#                     --end_time $END_TIME 

