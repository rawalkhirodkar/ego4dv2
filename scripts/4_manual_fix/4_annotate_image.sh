cd ../..

###----------------------------------------------------------------
RUN_FILE='tools/manual_fix/4_annotate_image.py'

# IMAGE='/media/rawalk/disk1/rawalk/datasets/ego_exo/main/012_frisbee/ego/aria02/images/undistorted_rgb/00206.jpg'
# OUTPUT='/home/rawalk/Dropbox/cvpr2023/intro/1/frisbee_aria02_00206.jpg'

# IMAGE='/media/rawalk/disk1/rawalk/datasets/ego_exo/main/012_frisbee/ego/aria02/images/left/00206.jpg'
# OUTPUT='/home/rawalk/Dropbox/cvpr2023/intro/1/left_frisbee_aria02_00206.jpg'


# IMAGE='/media/rawalk/disk1/rawalk/datasets/ego_exo/main/012_frisbee/ego/aria02/images/right/00206.jpg'
# OUTPUT='/home/rawalk/Dropbox/cvpr2023/intro/1/right_frisbee_aria02_00206.jpg'

IMAGE='/home/rawalk/Dropbox/cvpr2023/intro/1/raw_images/4.png'
OUTPUT='/home/rawalk/Dropbox/cvpr2023/intro/1/raw_images/out_images/4.png'

###------------------------------------------------------------------
python $RUN_FILE --image_path $IMAGE --output_path $OUTPUT