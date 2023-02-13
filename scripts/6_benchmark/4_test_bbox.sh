### use mmd conda environment

cd ../..
cd ../mmdetection

# ###----------------------------------------------------------------
RUN_FILE='./tools/dist_test.sh'
RUN_VIS_FILE='./tools/test.py'
CONFIG_FILE='configs/faster_rcnn/faster_rcnn_x101_64x4d_fpn_2x_coco.py'
CHECKPOINT='checkpoints/faster_rcnn_x101_64x4d_fpn_2x_coco_20200512_161033-5961fa95.pth'

SEQUENCE_ROOT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/benchmark'

# ###------------------------------------------------------------------
SAVE_BIG_SEQUENCE_NAME='01_tagging:02_legoassemble:07_fencing2' ## save dir name for the annotations

# SEQUENCES='001_tagging:002_tagging:003_tagging:004_tagging'; DEVICES=0,1,2,
SEQUENCES='all'; DEVICES=0,1,2,

##-------------------------------------------------------------------
SEQUENCE_PATH=$SEQUENCE_ROOT_DIR/$SAVE_BIG_SEQUENCE_NAME/$SEQUENCES

PORT=29601
BATCH_SIZE=32

MODE='exo'
# MODE='ego_rgb'
# MODE='ego_slam'

ANNOTATION_FILE=$SEQUENCE_ROOT_DIR/$SAVE_BIG_SEQUENCE_NAME/$SEQUENCES/coco/person_keypoints_$MODE.json
# ANNOTATION_FILE='/media/rawalk/disk1/rawalk/mmdetection/data/coco/annotations/person_keypoints_val2017.json'

#----------------------------------------------------------------------
OUTPUT_DIR=$SEQUENCE_ROOT_DIR/$SAVE_BIG_SEQUENCE_NAME/$SEQUENCES/"output"/"bbox"/$MODE
OUTPUT_FILE=${OUTPUT_DIR}/'coco_bbox.pkl'
OPTIONS="data.test.img_prefix=''"
OPTIONS="$(echo "$OPTIONS data.test.ann_file=${ANNOTATION_FILE} data.samples_per_gpu=${BATCH_SIZE}")"

# # # # # # # # # ##-----------------------------------------------
NUM_GPUS_STRING_LEN=${#DEVICES}
NUM_GPUS=$((NUM_GPUS_STRING_LEN/2))

CUDA_VISIBLE_DEVICES=${DEVICES} PORT=${PORT} ${RUN_FILE} ${CONFIG_FILE} ${CHECKPOINT} $NUM_GPUS \
    --cfg-options $OPTIONS \
    --out $OUTPUT_FILE \
    --eval 'bbox'

# # ##----for visualization, single gpu------------------
# CUDA_VISIBLE_DEVICES=${DEVICES} python $RUN_VIS_FILE ${CONFIG_FILE} ${CHECKPOINT} \
#         --cfg-options $OPTIONS \
#         --show-dir $OUTPUT_DIR \
#         --eval 'bbox' \
