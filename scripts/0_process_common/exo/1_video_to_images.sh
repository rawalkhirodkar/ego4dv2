###---------------------------------------------------------------------------
DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo"
OUTPUT_DIR='/media/rawalk/disk1/rawalk/datasets/ego_exo/common/time_synced_exo'

# SUPER_SEQUENCE='01_tagging'
# SUPER_SEQUENCE='02_lego_assemble'
# SUPER_SEQUENCE='03_lego_disassemble'
# SUPER_SEQUENCE='04_basketball'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08')
SUPER_SEQUENCE='05_frisbee'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08' 'cam09' 'cam10')

# SUPER_SEQUENCE='06_volleyball'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08' 'cam09' 'cam10' 'cam11' 'cam12' 'cam13' 'cam14' 'cam15')
# SUPER_SEQUENCE='06_volleyball'; CAMERAS=('cam09' 'cam10' 'cam11' 'cam12' 'cam13' 'cam14' 'cam15')

# SUPER_SEQUENCE='unclego4d'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04')
# SUPER_SEQUENCE='erwinwalk'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08')
# SUPER_SEQUENCE='erwinwalk2'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08')
# SUPER_SEQUENCE='kentawalk'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08')


# SUPER_SEQUENCE='07_fencing2'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08' 'cam09' 'cam10' 'cam11' 'cam12' 'cam13' 'cam14' 'cam15')
# SUPER_SEQUENCE='08_badminton'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08' 'cam09' 'cam10' 'cam11' 'cam12' 'cam13' 'cam14' 'cam15') 
# SUPER_SEQUENCE='11_tennis'; CAMERAS=('cam01' 'cam02' 'cam03' 'cam04' 'cam05' 'cam06' 'cam07' 'cam08' 'cam09' 'cam10' 'cam11' 'cam12' 'cam13' 'cam14' 'cam15')


###---------------------------------------------------------------------------
SEQUENCE_PATH="$(echo "${DATA_DIR}/${SUPER_SEQUENCE}")"
OUTPUT_SEQUENCE_PATH="$(echo "${OUTPUT_DIR}/${SUPER_SEQUENCE}/exo")"

mkdir -p ${OUTPUT_SEQUENCE_PATH}

## everything at the 20 fps
FPS=20

###---------------------------------------------------------------------------
for CAMERA in "${CAMERAS[@]}"
do

  CAM_SEQUENCE_PATH="$(echo "${SEQUENCE_PATH}/${CAMERA}.mp4")" 
  # CAM_SEQUENCE_PATH="$(echo "${SEQUENCE_PATH}/${CAMERA}.MP4")" 

  OUTPUT_CAM_SEQUENCE_PATH="$(echo "${OUTPUT_SEQUENCE_PATH}/${CAMERA}/images")"
  mkdir -p ${OUTPUT_CAM_SEQUENCE_PATH}
  
  ffmpeg -i ${CAM_SEQUENCE_PATH} -vf fps=$FPS ${OUTPUT_CAM_SEQUENCE_PATH}/%05d.jpg & ## run in background

done
###---------------------------------------------------------------------------


#### for mobile video image extraction, copy the video to the folder and use the command
# ffmpeg -i mobile.MP4 -vf fps=20 %05d.jpg
# ffmpeg -i mobile.MP4 -vf fps=30 %05d.jpg ## for ego4d