cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/manual_fix/2_check_ego_points_3d.py'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# SEQUENCE='calibration_fencing2'; DEVICES=0,


###------------------------------------------------------------------
BIG_SEQUENCE='06_volleyball'
SEQUENCE='calibration_volleyball'; DEVICES=0,


SEQUENCE_ROOT_DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE
OUTPUT_DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/'processed_data'

###----------------------------------------------------------------
DEVICES=0,
CONFIG_FILE='configs/wholebody/2d_kpt_sview_rgb_img/topdown_heatmap/coco-wholebody/hrnet_w48_coco_wholebody_384x288_dark_plus.py'
CHECKPOINT='https://download.openmmlab.com/mmpose/top_down/hrnet/hrnet_w48_coco_wholebody_384x288_dark-f5726563_20200918.pth'

###----------------------------------------------------------------
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$SEQUENCE
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR
