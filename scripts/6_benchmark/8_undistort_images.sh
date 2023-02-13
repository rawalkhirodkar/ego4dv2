cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/benchmark/undistort_images.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

###------------------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# SEQUENCE='001_tagging'; DEVICES=0,
# SEQUENCE='002_tagging'; DEVICES=1,
# SEQUENCE='003_tagging'; DEVICES=0,
# SEQUENCE='004_tagging'; DEVICES=0,
# SEQUENCE='005_tagging'; DEVICES=0,
# SEQUENCE='006_tagging'; DEVICES=1,
# SEQUENCE='007_tagging'; DEVICES=1,
# SEQUENCE='008_tagging'; DEVICES=1,
# SEQUENCE='009_tagging'; DEVICES=1,
# SEQUENCE='010_tagging'; DEVICES=1,
# SEQUENCE='011_tagging'; DEVICES=0,
# SEQUENCE='012_tagging'; DEVICES=0,
# SEQUENCE='013_tagging'; DEVICES=1,
# SEQUENCE='014_tagging'; DEVICES=1,

# ###------------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'
# 
# SEQUENCE='001_legoassemble'; DEVICES=0,
# SEQUENCE='002_legoassemble'; DEVICES=1,
# SEQUENCE='003_legoassemble'; DEVICES=1,
# SEQUENCE='004_legoassemble'; DEVICES=1,
# SEQUENCE='005_legoassemble'; DEVICES=0,
# SEQUENCE='006_legoassemble'; DEVICES=1,

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'

# # SEQUENCE='001_fencing2'; DEVICES=0,
# # SEQUENCE='002_fencing2'; DEVICES=1,
# # SEQUENCE='003_fencing2'; DEVICES=1,
# # SEQUENCE='004_fencing2'; DEVICES=1,
# # SEQUENCE='005_fencing2'; DEVICES=0,
# # SEQUENCE='006_fencing2'; DEVICES=1,
# # SEQUENCE='007_fencing2'; DEVICES=1,
# # SEQUENCE='008_fencing2'; DEVICES=1,
# # SEQUENCE='009_fencing2'; DEVICES=0,
# # SEQUENCE='010_fencing2'; DEVICES=1,
# # SEQUENCE='011_fencing2'; DEVICES=1,
# # SEQUENCE='012_fencing2'; DEVICES=1,
# # SEQUENCE='013_fencing2'; DEVICES=0,
# SEQUENCE='014_fencing2'; DEVICES=1,

# # ###------------------------------------------------------------------
BIG_SEQUENCE='04_basketball'

SEQUENCE='001_basketball'; DEVICES=1,

# ###------------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

# ###----------------------------------------------------------------
mkdir -p ${OUTPUT_DIR}; 

# # # # # # # # ##-----------------------------------------------
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
