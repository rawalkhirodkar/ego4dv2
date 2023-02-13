cd ../..

###------------note this has to be run inside the mmhuman docker---------------
###--------------------------------------------------------------------------
RUN_FILE='tools/process_smpl/4_get_init_smpl.py'

SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'


# ####-----------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# SEQUENCE='001_tagging_1'; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# SEQUENCE='002_tagging'; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# SEQUENCE='003_tagging'; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# SEQUENCE='004_tagging'; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# SEQUENCE='005_tagging'; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'

# SEQUENCE='011_tagging'; DEVICES=0; CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'

# # SEQUENCE='001_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# # SEQUENCE='002_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# # SEQUENCE='003_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# # SEQUENCE='004_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'
# # SEQUENCE='005_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'

# SEQUENCE='006_legoassemble'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'; DEVICES=1, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb'

# # ###------------------------------------------------------------------
BIG_SEQUENCE='06_volleyball'
SEQUENCE='001_volleyball'; DEVICES=1, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# # SEQUENCE='001_fencing2'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'
# # SEQUENCE='002_fencing2'; DEVICES=0, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'
# # SEQUENCE='003_fencing2'; DEVICES=1, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'
# # SEQUENCE='004_fencing2'; DEVICES=2, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='001_badminton'; DEVICES=3, CHOOSEN_CAMS='cam01:rgb---cam02:rgb---cam03:rgb---cam04:rgb---cam05:rgb---cam06:rgb---cam07:rgb---cam08:rgb---cam09:rgb---cam10:rgb---cam11:rgb---cam12:rgb---cam13:rgb---cam14:rgb---cam15:rgb'


# ###----------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

NUM_JOBS=4

# ###----------------------------------------------------------------


LOG_DIR="$(echo "${OUTPUT_DIR}/logs/init_smpl")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 

# # ##-----------------------------------------------
SEQUENCE_LENGTH=$(find $SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE/'exo'/'cam01'/'images' -maxdepth 1 -name '*.jpg' | wc -l)
PER_JOB=$((SEQUENCE_LENGTH/NUM_JOBS))
LAST_JOB_ITER=$((NUM_JOBS-1))

for (( i=0; i < $NUM_JOBS; ++i ))
do
    START_TIME=$((i*PER_JOB + 1))
    END_TIME=$((i*PER_JOB + PER_JOB))

    if [ $i == $LAST_JOB_ITER ]
    then
        END_TIME=-1
    fi
    
    ##--------------run-----------------------------
    LOG_FILE="$(echo "${LOG_DIR}/log_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}
    CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --start_time $START_TIME \
                    --end_time $END_TIME \
                    --choosen_cams $CHOOSEN_CAMS \
                    | tee ${LOG_FILE} &


done


# # # # # ###--------------------------debug------------------------------
# START_TIME=1
# END_TIME=5


# LOG_FILE="$(echo "${LOG_DIR}/log_init_start_${START_TIME}_end_${END_TIME}.txt")"; touch ${LOG_FILE}

# CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
#                     --sequence_path ${SEQUENCE_PATH} \
#                     --output_path $OUTPUT_DIR \
#                     --start_time $START_TIME \
#                     --end_time $END_TIME \
#                     --choosen_cams $CHOOSEN_CAMS \
#                     # | tee ${LOG_FILE}



