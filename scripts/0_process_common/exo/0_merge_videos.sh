# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam01
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam02
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam03
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam04
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam05
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam06
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam07
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam08
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam09
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam10
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam11
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam12
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam13
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam14
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/11_tennis/cam15

# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam01
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam02
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam03
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam04
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam05
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam06
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam07
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam08
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam09
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam10
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam11
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam12
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam13
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam14
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/12_soccer/cam15

# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam01
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam02
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam03
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam04
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam05
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam06
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam07
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam08
# DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam09
DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/common/raw_from_cameras/05_frisbee/cam10



##---make merge_list.txt---
echo $DIR
python make_merge_list.py $DIR

cd $DIR
ffmpeg -f concat -safe 0 -i merge_list.txt -c copy rgb.mp4
