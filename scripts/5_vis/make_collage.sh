# BIG_SEQUENCE='01_tagging'

# # SEQUENCE='006_tagging'; NUM_ARIAS=4; NUM_CAMS=8;
# # SEQUENCE='007_tagging'; NUM_ARIAS=4; NUM_CAMS=8;
# # SEQUENCE='008_tagging'; NUM_ARIAS=4; NUM_CAMS=8;
# # SEQUENCE='009_tagging'; NUM_ARIAS=4; NUM_CAMS=8;
# # SEQUENCE='010_tagging'; NUM_ARIAS=4; NUM_CAMS=8;
# # SEQUENCE='011_tagging'; NUM_ARIAS=4; NUM_CAMS=8;

# # ###----------------------------------------------------------------
# BIG_SEQUENCE='02_legoassemble'
# # SEQUENCE='001_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;

# # # SEQUENCE='002_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;
# # # SEQUENCE='003_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;
# SEQUENCE='004_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;
# # SEQUENCE='005_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;
# SEQUENCE='006_legoassemble'; NUM_ARIAS=3; NUM_CAMS=8;

# # # ###----------------------------------------------------------------
# BIG_SEQUENCE='04_basketball'
# SEQUENCE='001_basketball'; NUM_ARIAS=4; NUM_CAMS=8;

# # # ###----------------------------------------------------------------
BIG_SEQUENCE='05_frisbee'
SEQUENCE='001_frisbee'; NUM_ARIAS=6; NUM_CAMS=10;


# # # # ###----------------------------------------------------------------
# BIG_SEQUENCE='06_volleyball'
# # SEQUENCE='001_volleyball'; NUM_ARIAS=4; NUM_CAMS=15;
# SEQUENCE='001_volleyball'; NUM_ARIAS=4; NUM_CAMS=9;

# # ###----------------------------------------------------------------
# BIG_SEQUENCE='07_fencing2'
# SEQUENCE='003_fencing2'; NUM_ARIAS=3; NUM_CAMS=15;

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='08_badminton'
# SEQUENCE='001_badminton'; NUM_ARIAS=4; NUM_CAMS=15;

# # # ###------------------------------------------------------------------
# BIG_SEQUENCE='11_tennis'
# # SEQUENCE='calibration_tennis'; NUM_ARIAS=4; NUM_CAMS=15;
# SEQUENCE='001_tennis'; NUM_ARIAS=4; NUM_CAMS=15;

# ###----------------------------------------------------------------
# BIG_SEQUENCE='uncego4d'
# SEQUENCE='001_uncego4d'; NUM_ARIAS=1; NUM_CAMS=4;

# ###----------------------------------------------------------------
# BIG_SEQUENCE='erwinwalk'
# SEQUENCE='001_erwinwalk'; NUM_ARIAS=1; NUM_CAMS=8;
# # SEQUENCE='calibration_erwinwalk'; NUM_ARIAS=1; NUM_CAMS=8;

# ###----------------------------------------------------------------
# BIG_SEQUENCE='erwinwalk2'
# SEQUENCE='calibration_erwinwalk2'; NUM_ARIAS=1; NUM_CAMS=8;


##-------------------------------------------
MODE='time_sync'
# MODE='vis_aria_locations'
# MODE='vis_poses2d'
# MODE='vis_poses3d'
# MODE='vis_refine_poses3d'
# MODE='vis_fit_poses3d'
# MODE='vis_smpl'

##-------------------------------------------

if [ $MODE == 'time_sync' ]
then
	READ_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/"

else
	READ_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data/$MODE/"
fi

OUTPUT_DIR="/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/processed_data/collage/$MODE/"

# # # # ###----------------------------------------------------------------
./make_collage_aria.sh ${READ_DIR} ${OUTPUT_DIR} ${NUM_ARIAS} &

# # ###----------------------------------------------------------------
./make_collage_exo.sh ${READ_DIR} ${OUTPUT_DIR} ${NUM_CAMS} &


