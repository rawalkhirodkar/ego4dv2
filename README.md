# Ego-Exo

## Installation
- Following the instructions in ```./scripts/_install/conda.sh```
- It will create an conda environment "mmp" for you.

## Data Setup
- Please download two demo sequences "calibration_uncego4d" and [001_uncego4d](https://drive.google.com/file/d/1DXKSfxvI5QD0_vutOUXmIK3Q92auY2_O/view?usp=share_link).
- Unzip, it contains the timesynced images and colmap calibration output.
- Paste the "calibration_uncego4d" anmd '001_uncego4d' under the path '/media/rawalk/disk1/rawalk/datasets/ego_exo/main/uncego4d'. Or change the sequence paths in the scripts.


## Camera Alignment
- We align the aria cameras with the gopros using the colmap output using procrustes alignment.
- ```cd scripts/1_process_ego```
- ```./3_run_pa.sh```
- This will generate and save camera transforms "Aria to COLMAP" and "COLMAP to Aria" to the 'colmap/workplace' folder under 'calibration_uncego4d'

## Camera Center Visualization
- To check if the camera alignment was successful, we visualize the camera centers in the ego and exo views.
- ```cd scripts/3_process_smpl```
- ```./get_aria_locations.sh```
- Output saved to 'calibration_uncego4d/processed_data'. 'cyan' for gopro camera center, 'blue' for aria camera center.