cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/process_smpl/get_aria_locations.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

# ###------------------------------------------------------------------
BIG_SEQUENCE='uncego4d' 
SEQUENCE='calibration_uncego4d'
# SEQUENCE='001_uncego4d'

###---------------------------------------------------------------------
BIG_SEQUENCE='erwinwalk2' 
SEQUENCE='001_erwinwalk2'

###---------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

###----------------------------------------------------------------
CONFIG_FILE='configs/wholebody/2d_kpt_sview_rgb_img/topdown_heatmap/coco-wholebody/hrnet_w48_coco_wholebody_384x288_dark_plus.py'
CHECKPOINT='https://download.openmmlab.com/mmpose/top_down/hrnet/hrnet_w48_coco_wholebody_384x288_dark-f5726563_20200918.pth'

###----------------------------------------------------------------
CHOOSEN_TIME=":::" ## default
# CHOOSEN_TIME="150:151:152:153:154:155:156:157:158:159:160:161:162:163:164:165"

CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --choosen_time $CHOOSEN_TIME \
