###---------------------------------------------------------------------------
DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo"
OUTPUT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo'

SUPER_SEQUENCE='erwinwalk'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08')

###---------------------------------------------------------------------------
SEQUENCE_PATH="$(echo "${DATA_DIR}/${SUPER_SEQUENCE}")"
OUTPUT_SEQUENCE_PATH="$(echo "${OUTPUT_DIR}/${SUPER_SEQUENCE}/exo")"

mkdir -p ${OUTPUT_SEQUENCE_PATH}

## everything at the 30
FPS=30

###---------------------------------------------------------------------------
for CAMERA in "${CAMERAS[@]}"
do

  # CAM_SEQUENCE_PATH="$(echo "${SEQUENCE_PATH}/${CAMERA}.mp4")" 
  CAM_SEQUENCE_PATH="$(echo "${SEQUENCE_PATH}/${CAMERA}.MP4")" 

  OUTPUT_CAM_SEQUENCE_PATH="$(echo "${OUTPUT_SEQUENCE_PATH}/${CAMERA}/images")"
  mkdir -p ${OUTPUT_CAM_SEQUENCE_PATH}
  
  ffmpeg -i ${CAM_SEQUENCE_PATH} -vf fps=$FPS ${OUTPUT_CAM_SEQUENCE_PATH}/%05d.jpg & ## run in background

done
###---------------------------------------------------------------------------


#### for mobile video image extraction, copy the video to the folder and use the command
# ffmpeg -i mobile.MP4 -vf fps=20 %05d.jpg
# ffmpeg -i mobile.MP4 -vf fps=30 %05d.jpg ## for ego4d