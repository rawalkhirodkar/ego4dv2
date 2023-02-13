cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/manual_fix/3_exo_calibration_3d.py'


# SEQUENCE_ROOT_DIR='/home/rawalk/Desktop/datasets/ego_exo/main'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# # SEQUENCE='001_tagging'
# # SEQUENCE='002_tagging'
# # SEQUENCE='003_tagging'
# # SEQUENCE='004_tagging'
# # SEQUENCE='005_tagging'
# # SEQUENCE='006_tagging'
# SEQUENCE='007_tagging'


# ###------------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# SEQUENCE='calibration_fencing2'

# ##----------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='calibration_badminton'

# ##----------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'

##----------------------------------------------------------------
BIG_SEQUENCE='06_volleyball'
SEQUENCE='calibration_volleyball'

####-----------------------------------------------------------------
# SEQUENCE='012_frisbee'
# SEQUENCE='013_lego'
# SEQUENCE='014_basketball'
# SEQUENCE='basketball_calibration'
# SEQUENCE='soccer1_calibration'
# SEQUENCE='volleyball_calibration'


OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

###----------------------------------------------------------------
DEVICES=0,
CONFIG_FILE='configs/wholebody/2d_kpt_sview_rgb_img/topdown_heatmap/coco-wholebody/hrnet_w48_coco_wholebody_384x288_dark_plus.py'
CHECKPOINT='https://download.openmmlab.com/mmpose/top_down/hrnet/hrnet_w48_coco_wholebody_384x288_dark-f5726563_20200918.pth'

###----------------------------------------------------------------
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR
