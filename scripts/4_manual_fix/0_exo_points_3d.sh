cd ../..
##--------------need atleast 6 points------------------
###----------------------------------------------------------------
RUN_FILE='tools/manual_fix/2_exo_get_points_3d.py'
SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/main'

# ###------------------------------------------------------------------
# BIG_SEQUENCE='01_tagging'

# # SEQUENCE='001_tagging'
# # SEQUENCE='002_tagging'
# # SEQUENCE='003_tagging'
# # SEQUENCE='006_tagging'

# SEQUENCE='007_tagging'

# TARGET_CAMERA_NAME='6' ## cam0N
# CAMERAS="1:5"
# TIMESTAMP="1"



###------------------------------------------------------------------
# # ###----------------------------------------------------------------
BIG_SEQUENCE='02_legoassemble'
SEQUENCE='004_legoassemble'; DEVICES=1,

TARGET_CAMERA_NAME='6' ## cam0N
CAMERAS="4:8"
TIMESTAMP="400"

# ##----------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# SEQUENCE='calibration_fencing2'


# ##----------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='calibration_badminton'

# TARGET_CAMERA_NAME='05' ## cam0N
# CAMERAS="7:11:13" ## 6?

# TIMESTAMP="1"


# ##----------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'

# # TARGET_CAMERA_NAME='01' ## cam0N
# # CAMERAS="4:6" 

# TARGET_CAMERA_NAME='03' ## cam0N
# CAMERAS="1:3" 

# TIMESTAMP="140"
# # # TIMESTAMP="414"

# ##----------------------------------------------------------------
# BIG_SEQUENCE='06_volleyball'
# SEQUENCE='calibration_volleyball'

# TARGET_CAMERA_NAME='12' ## cam0N
# CAMERAS="9:11" 

# TIMESTAMP="1"
# TIMESTAMP="414"

##----------------------------------------------------------------
OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data"
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$BIG_SEQUENCE/$SEQUENCE

###----------------------------------------------------------------
DEVICES=0,
CONFIG_FILE='configs/wholebody/2d_kpt_sview_rgb_img/topdown_heatmap/coco-wholebody/hrnet_w48_coco_wholebody_384x288_dark_plus.py'
CHECKPOINT='https://download.openmmlab.com/mmpose/top_down/hrnet/hrnet_w48_coco_wholebody_384x288_dark-f5726563_20200918.pth'

###----------------------------------------------------------------
CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_FILE \
                    --sequence_path ${SEQUENCE_PATH} \
                    --output_path $OUTPUT_DIR \
                    --target_camera_name $TARGET_CAMERA_NAME \
                    --cameras $CAMERAS \
                    --timestamp $TIMESTAMP \
