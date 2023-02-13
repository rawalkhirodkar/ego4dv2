cd ../..

# # # ###---------------------------------------------------------------------
BIG_SEQUENCE='uncego4d' 
SEQUENCE='calibration_uncego4d'
# SEQUENCE='001_uncego4d'

# # ###---------------------------------------------------------------------
COLMAP_ROOT_DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/colmap
ARIA_WORKPLACE_DIR=/media/rawalk/disk1/rawalk/datasets/ego_exo/main/$BIG_SEQUENCE/$SEQUENCE/ego

###------------------------------------------------------------------
COLMAP_WORKPLACE_DIR=$COLMAP_ROOT_DIR/"workplace"
RUN_FILE='tools/calibration/run_procrustes_alignment.py'

###------------------------------------------------------------------
python $RUN_FILE --colmap-workplace-dir ${COLMAP_WORKPLACE_DIR} --aria-workplace-dir $ARIA_WORKPLACE_DIR