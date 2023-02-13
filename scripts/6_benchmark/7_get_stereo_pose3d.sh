cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/benchmark/get_stereo_pose3d.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

###------------------------------------------------------------------
# SEQUENCE='001_tagging'; DEVICES=0,
# SEQUENCE='002_tagging'; DEVICES=1,
# SEQUENCE='003_tagging'; DEVICES=2,
SEQUENCE='004_tagging'; DEVICES=3,


# SEQUENCE='005_tagging'; DEVICES=0,
# SEQUENCE='006_tagging'; DEVICES=2,
# SEQUENCE='007_tagging'; DEVICES=1,
# SEQUENCE='008_tagging'; DEVICES=3,
# SEQUENCE='009_tagging'; DEVICES=1,
# SEQUENCE='010_tagging'; DEVICES=3,
# SEQUENCE='011_tagging'; DEVICES=0,

# SEQUENCE='012_frisbee'; DEVICES=3,
# SEQUENCE='013_lego'; DEVICES=3,
# SEQUENCE='014_basketball'; DEVICES=3,
# SEQUENCE='015_soccer1'; DEVICES=3,

# SEQUENCE='002_pro_soccer_1'

OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/benchmark/$SEQUENCE"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$SEQUENCE

# ##----------------------------------------------------------------
# NUM_JOBS=5
NUM_JOBS=4 ## if using fasterrcnn

# ###----------------------------------------------------------------
LOG_DIR="$(echo "${OUTPUT_DIR}/logs/bbox")"
mkdir -p ${OUTPUT_DIR}; mkdir -p ${LOG_DIR}; 

# # # # # # # # ##-----------------------------------------------
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
