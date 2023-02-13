cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/benchmark/concatenate_coco_format.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo'

# ##---------------------------------------------------------
# BIG_SEQUENCES='01_tagging:01_tagging:01_tagging:01_tagging'
# SEQUENCES='001_tagging:002_tagging:003_tagging:004_tagging'; 
# DEVICES=0,
# OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/benchmark/$BIG_SEQUENCE/$SEQUENCES"

###-----------------for all----------------------------
SAVE_BIG_SEQUENCE_NAME='01_tagging:02_legoassemble:07_fencing2' ## save dir name for the annotations

BIG_SEQUENCES='01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging:01_tagging'
SEQUENCES='001_tagging:002_tagging:003_tagging:004_tagging:005_tagging:006_tagging:007_tagging:008_tagging:009_tagging:010_tagging:011_tagging:012_tagging:013_tagging:014_tagging'

BIG_SEQUENCES+=':'
SEQUENCES+=':'
BIG_SEQUENCES+='02_legoassemble:02_legoassemble:02_legoassemble:02_legoassemble:02_legoassemble:02_legoassemble'
SEQUENCES+='001_legoassemble:002_legoassemble:003_legoassemble:004_legoassemble:005_legoassemble:006_legoassemble'

BIG_SEQUENCES+=':'
SEQUENCES+=':'
BIG_SEQUENCES+='07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2:07_fencing2'
SEQUENCES+='001_fencing2:002_fencing2:003_fencing2:004_fencing2:005_fencing2:006_fencing2:007_fencing2:008_fencing2:009_fencing2:010_fencing2:011_fencing2:012_fencing2:013_fencing2:014_fencing2'


DEVICES=0,
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/benchmark/"$SAVE_BIG_SEQUENCE_NAME/"all"

# # ###----------------------------------------------------------------
mkdir -p ${OUTPUT_DIR}; 

# # # # # # # # ##-----------------------------------------------
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --big_sequences ${BIG_SEQUENCES} \
                    --sequences ${SEQUENCES} \
                    --root_dir $SEQUENCE_ROOT_DIR \
                    --output_path $OUTPUT_DIR \
