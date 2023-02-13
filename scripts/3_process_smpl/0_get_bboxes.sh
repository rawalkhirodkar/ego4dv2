cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/process_smpl/0_get_bboxes.py'
SEQUENCE_ROOT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main"

###------------------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# SEQUENCE='001_tagging'; DEVICES=0,
# SEQUENCE='002_tagging'; DEVICES=1,

# ###------------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'

# # SEQUENCE='001_legoassemble'; DEVICES=0,
# SEQUENCE='002_legoassemble'; DEVICES=1,


# # ###------------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'; DEVICES=0,

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='06_volleyball'
# SEQUENCE='001_volleyball'; DEVICES=1,

# ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# # SEQUENCE='001_fencing2'; DEVICES=3,
# # SEQUENCE='002_fencing2'; DEVICES=0,
# # SEQUENCE='003_fencing2'; DEVICES=1,
# # SEQUENCE='004_fencing2'; DEVICES=2,

# # ###------------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='001_badminton'; DEVICES=3,

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='11_tennis'
# SEQUENCE='001_tennis'; DEVICES=0,

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='uncego4d'
# SEQUENCE='001_uncego4d'; DEVICES=0,

# ####---------------------------------------------------
# BIG_SEQUENCE='13_frisbee'
# SEQUENCE='001_frisbee'; DEVICES=0,


# # ####---------------------------------------------------
# BIG_SEQUENCE='erwinwalk2'
# # SEQUENCE='001_erwinwalk2'; DEVICES=0,
# # SEQUENCE='002_erwinwalk2'; DEVICES=0,
# # SEQUENCE='003_erwinwalk2'; DEVICES=0,
# SEQUENCE='004_erwinwalk2'; DEVICES=0,


# ####---------------------------------------------------
BIG_SEQUENCE='kentawalk'
# SEQUENCE='001_kentawalk'; DEVICES=0,
# SEQUENCE='002_kentawalk'; DEVICES=0,
# SEQUENCE='003_kentawalk'; DEVICES=0,
SEQUENCE='004_kentawalk'; DEVICES=1,

###-------------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

# ##----------------------------------------------------------------
# NUM_JOBS=4 ## if using fasterrcnn, issues when using odd number of jobs, for eg: 5 is glitchy.
NUM_JOBS=2 ## if using fasterrcnn, issues when using odd number of jobs, for eg: 5 is glitchy.

# ###----------------------------------------------------------------
LOG_DIR="$(echo "${OUTPUT_DIR}/logs/bbox")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 

# # # # # # # # ##-----------------------------------------------
# SEQUENCE_LENGTH=$(find $SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE/'exo'/'cam01'/'images' -maxdepth 1 -name '*.jpg' | wc -l)

# PER_JOB=$((SEQUENCE_LENGTH/NUM_JOBS))
# LAST_JOB_ITER=$((NUM_JOBS-1))

# for (( i=0; i < $NUM_JOBS; ++i ))
# do
#     START_TIME=$((i*PER_JOB + 1))
#     END_TIME=$((i*PER_JOB + PER_JOB))

#     if [ $i == $LAST_JOB_ITER ]
#     then
#         END_TIME=-1
#     fi
    
#     # ##--------------run-----------------------------
#     LOG_FILE="$(echo "${LOG_DIR}/log_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}
#     CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
#                         --sequence_path ${SEQUENCE_PATH} \
#                         --output_path $OUTPUT_DIR \
#                         --start_time $START_TIME \
#                         --end_time $END_TIME  | tee ${LOG_FILE} &


# done

# # # # # # # # # # # # # # # # # # # # ###--------------debug-----------------------------
# START_TIME=1
# END_TIME=3

# TIMESTAMPS=":::"

START_TIME=-1
END_TIME=-1
TIMESTAMPS="1:2"
# TIMESTAMPS="3:4:5"

LOG_FILE="$(echo "${LOG_DIR}/log_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --start_time $START_TIME \
                    --end_time $END_TIME \
                    --choosen_time $TIMESTAMPS \