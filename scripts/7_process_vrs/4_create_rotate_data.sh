CURRENT_DIR=$PWD

# BIG_SEQUENCE='06_volleyball'
# # RECORDING=aria01
# # RECORDING=aria02
# # RECORDING=aria03
# RECORDING=aria04

# BIG_SEQUENCE='unc_ego4d'
# RECORDING=aria01

# BIG_SEQUENCE='erwinwalk'
# RECORDING=aria01

BIG_SEQUENCE='erwinwalk2'
RECORDING=aria01

# BIG_SEQUENCE='kentawalk'
# RECORDING=aria01

DATA_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/${BIG_SEQUENCE}"

##---------------------------------------------------
IMAGE_DIR=$DATA_DIR/$RECORDING/images

RGB_IMAGE_DIR=$IMAGE_DIR/'rotated_rgb'
LEFT_IMAGE_DIR=$IMAGE_DIR/'rotated_left'
RIGHT_IMAGE_DIR=$IMAGE_DIR/'rotated_right'
						
##---------------------------------------------------
RGB_ROTATED_IMAGE_DIR=$IMAGE_DIR/'rgb'
LEFT_ROTATED_IMAGE_DIR=$IMAGE_DIR/'left'
RIGHT_ROTATED_IMAGE_DIR=$IMAGE_DIR/'right'


# ##---------------------------------------------------
echo "copying " $RGB_IMAGE_DIR
cp -r $RGB_IMAGE_DIR $RGB_ROTATED_IMAGE_DIR

echo "copying " $LEFT_IMAGE_DIR
cp -r $LEFT_IMAGE_DIR $LEFT_ROTATED_IMAGE_DIR

echo "copying " $RIGHT_IMAGE_DIR
cp -r $RIGHT_IMAGE_DIR $RIGHT_ROTATED_IMAGE_DIR

##---------------------------------------------------
cd $CURRENT_DIR

echo "rotating " $RGB_ROTATED_IMAGE_DIR
./rotate_images.sh $RGB_ROTATED_IMAGE_DIR &

echo "rotating " $LEFT_ROTATED_IMAGE_DIR 
./rotate_images.sh $LEFT_ROTATED_IMAGE_DIR & 

echo "rotating " $RIGHT_ROTATED_IMAGE_DIR
./rotate_images.sh $RIGHT_ROTATED_IMAGE_DIR &

echo "Rotation minions are live! They will work hard in the background. Be patient and do not kill them!"