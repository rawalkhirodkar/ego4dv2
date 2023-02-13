cd ../..
cd ../mmpose

# ###----------------------------------------------------------------
RUN_FILE='./tools/dist_test.sh'
RUN_VIS_FILE='./demo/custom_vis.py'
CONFIG_FILE='configs/body/2d_kpt_sview_rgb_img/topdown_heatmap/coco/res50_coco_256x192.py'
CHECKPOINT='https://download.openmmlab.com/mmpose/top_down/resnet/res50_coco_256x192-ec54d7f3_20200709.pth'

SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/benchmark'

# ###------------------------------------------------------------------
DEVICES=1,2,3,

# SAVE_BIG_SEQUENCE_NAME='01_tagging:02_legoassemble:07_fencing2' ## save dir name for the annotations
# SEQUENCES='all'


# SAVE_BIG_SEQUENCE_NAME='07_fencing2' ## save dir name for the annotations
# SEQUENCES='001_fencing2'

SAVE_BIG_SEQUENCE_NAME='01_tagging' ## save dir name for the annotations
SEQUENCES='005_tagging'

# SAVE_BIG_SEQUENCE_NAME='02_legoassemble' ## save dir name for the annotations
# SEQUENCES='004_legoassemble'

# SAVE_BIG_SEQUENCE_NAME='08_badminton' ## save dir name for the annotations
# SEQUENCES='001_badminton'

###---------------------------------------------------------------------
PORT=29609
BATCH_SIZE=16

MODE='exo'
# MODE='ego_rgb'
# MODE='ego_slam'

ANNOTATION_FILE=$SEQUENCE_ROOT_DIR/$SAVE_BIG_SEQUENCE_NAME/$SEQUENCES/coco/person_keypoints_$MODE.json

#----------------------------------------------------------------------
OUTPUT_DIR=$SEQUENCE_ROOT_DIR/$SAVE_BIG_SEQUENCE_NAME/$SEQUENCES/"output"/"pose2d"/$MODE
OUTPUT_FILE=${OUTPUT_DIR}/'coco.yml'
OPTIONS="data.test.data_cfg.use_gt_bbox=True data.test.img_prefix=''" ## if use gt bbox
# OPTIONS="data.test.data_cfg.use_gt_bbox=False data.test.img_prefix=''" ## if do not use gt bbox
OPTIONS="$(echo "$OPTIONS data.test.ann_file=${ANNOTATION_FILE} data.samples_per_gpu=${BATCH_SIZE}")"

# # # ##----------------------------------------------------------------
mkdir -p ${OUTPUT_DIR}; 

# # # # # # # # # # # ##-----------------------------------------------
# NUM_GPUS_STRING_LEN=${#DEVICES}
# NUM_GPUS=$((NUM_GPUS_STRING_LEN/2))

# CUDA_VISIBLE_DEVICES=${DEVICES} PORT=${PORT} ${RUN_FILE} ${CONFIG_FILE} ${CHECKPOINT} $NUM_GPUS \
#     --cfg-options $OPTIONS \
#     --out $OUTPUT_FILE \
#     --eval mAP \


# # ##----for visualization, single gpu------------------
THICKNESS=3
RADIUS=4

CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_VIS_FILE ${CONFIG_FILE} ${CHECKPOINT} \
        --json-file $ANNOTATION_FILE \
        --out-img-root $OUTPUT_DIR \
        --radius $RADIUS \
        --thickness $THICKNESS \
