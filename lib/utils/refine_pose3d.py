import numpy as np
import os
import cv2
from scipy.optimize import least_squares
import random
from scipy import signal
import pandas as pd

## for coco 17 keypoints
## https://github.com/open-mmlab/mmpose/blob/af2cacd8492bea3b18d7eb407c5b9e52af1ad2fb/mmpose/apis/inference.py#L593
COCO_SKELETON = {
                'left_leg': [13, 15], ## l-knee to l-ankle
                'right_leg': [14, 16], ## r-knee to r-ankle
                'left_thigh': [11, 13], ## l-hip to l-knee
                'right_thigh': [12, 14], ## r-hip to r-knee
                'hip': [11, 12], ## l-hip to r-hip
                'left_torso': [5, 11], ## l-shldr to l-hip
                'right_torso': [6, 12], ## r-shldr to r-hip
                'left_bicep': [5, 7], ## l-shldr to l-elbow
                'right_bicep': [6, 8], ## r-shldr to r-elbow
                'shoulder': [5, 6], ## l-shldr to r-shldr
                'left_hand': [7, 9], ## l-elbow to l-wrist
                'right_hand': [8, 10], ## r-elbow to r-wrist
                'left_face': [1, 0], ## l-eye to nose
                'right_face': [2, 0], ## l-eye to nose
                'face': [1, 2], ## l-eye to r-eye
                'left_ear': [1, 3], ## l-eye to l-ear
                'right_ear': [2, 4], ## l-eye to r-ear
                'left_neck': [3, 5], ## l-ear to l-shldr
                'right_neck': [4, 6], ## r-ear to r-shldr
}

##------------------------------------------------------------------------------------
def refine_pose3d(cfg, human_name, poses, num_keypoints=17, window_length=10):
    assert(poses.shape[1] == num_keypoints)
    assert(poses.shape[2] == 4)

    total_time = poses.shape[0]
    refine_poses = poses.copy()

    refine_poses = fill_missing_keypoints(cfg, refine_poses, num_keypoints, human_name) ## fill in missing keypoints using interpolation
    refine_poses = fix_smoothing_mistakes(cfg, refine_poses, num_keypoints, human_name)
    refine_poses = fix_limb_mistakes(cfg, refine_poses, num_keypoints, human_name)
    refine_poses = smooth_keypoints(cfg, refine_poses, window_length=5, polyorder=3)

    return refine_poses

# ##--------------------------------------------------------------------------------
# ## fix the jitters
def fix_smoothing_mistakes(cfg, poses, num_keypoints, human_name=None, debug=True):
    total_time = poses.shape[0]
    window_length = cfg.REFINE_POSE3D.WINDOW_LENGTH
    motion_thres = cfg.REFINE_POSE3D.MOTION_THRES

    for i in range(num_keypoints):
        trajectory = poses[:, i, :3] ## t x 3

        ## we skip t=0 and assume it is correct
        distance = ((trajectory[1:] - trajectory[:-1])**2).sum(axis=1) ## dist[i] = p(i) - p(i-1) 
        assert(len(distance) == total_time - 1)

        df = pd.Series(distance)
        average_offset = df.mean()
        is_not_valid = (df > motion_thres).to_numpy() ## timestep with too much motion
        mistake_timestamps = ((is_not_valid).nonzero())[0] + 1 ## convert to indices in the poses

        poses[mistake_timestamps, i, 3] = 0 ## set the flag as missing
        if cfg.REFINE_POSE3D.DEBUG == True:
            print('{}, keypoint:{}, average_offset:{}. outlier_t:{}'.format(human_name, i, average_offset, mistake_timestamps))
    poses = fill_missing_keypoints(cfg, poses, num_keypoints, human_name)
    return poses


##--------------------------------------------------------------------------------
## replace the limb outliers
def fix_limb_mistakes(cfg, poses, num_keypoints, human_name=None):
    total_time = poses.shape[0]
    std_thres = cfg.REFINE_POSE3D.STD_THRES
    iqr_thres = cfg.REFINE_POSE3D.IQR_THRES
    window_length = cfg.REFINE_POSE3D.WINDOW_LENGTH

    limb_lengths = np.zeros((total_time, len(COCO_SKELETON.keys())))

    # print('---------------{}-------------'.format(human_name))
    ## compute limb lengths
    for t in range(total_time):
        pose = poses[t][:, :3] ## 17 x 3
        validity = poses[t][:, 3] ## 17 x 1

        assert(validity.sum() == 17) ## all keypoints should be visible for all timesteps after filling through interpolation

        for limb_idx, limb_name in enumerate(COCO_SKELETON.keys()):
            limb_idxs = COCO_SKELETON[limb_name]
            this_limb_length = np.sqrt(((pose[limb_idxs[0]] - pose[limb_idxs[1]])**2).sum()) 
            limb_lengths[t, limb_idx] = this_limb_length

    # print('---------------{}-------------'.format(human_name))
    ##---look for outliers----

    for limb_idx, limb_name in enumerate(COCO_SKELETON.keys()):
        limb_length_trajectory = limb_lengths[:, limb_idx]

        limb_idxs = COCO_SKELETON[limb_name]
        df = pd.Series(limb_length_trajectory)

        # ## IQR, https://www.geeksforgeeks.org/detect-and-remove-the-outliers-using-python/
        # q1 = np.percentile(df, 25, interpolation='midpoint')
        # q3 = np.percentile(df, 75, interpolation='midpoint')
        # iqr = q3 - q1 ## interquantile tange

        # upper_limit = q3 + iqr_thres*iqr
        # lower_limit = q1 - iqr_thres*iqr

        ##-----------alternatively------------------
        upper_limit = df.mean() + std_thres*df.std()
        lower_limit = df.mean() - std_thres*df.std()

        is_valid = (limb_length_trajectory <= upper_limit) * (limb_length_trajectory >= lower_limit)
        is_not_valid = ~is_valid

        mistake_timestamps = ((is_not_valid).nonzero())[0] ## note, this is not the image timestamp but index, timestamp -1 

        poses[mistake_timestamps, limb_idxs[0], 3] = 0 ## set the flag as missing
        poses[mistake_timestamps, limb_idxs[1], 3] = 0 ## set the flag as missing

        if cfg.REFINE_POSE3D.DEBUG == True:
            print('{}, {}, mean:{}. std:{}, upper:{}, lower:{}, outlier_t:{}'.format(human_name, limb_name, df.mean(), df.std(), upper_limit, lower_limit, mistake_timestamps))
         
    poses = fill_missing_keypoints(cfg, poses, num_keypoints, human_name)
    return poses

##--------------------------------------------------------------------------------
def fill_missing_keypoints(cfg, poses, num_keypoints=17, human_name=None, debug=False):
    total_time = poses.shape[0]
    window_length = cfg.REFINE_POSE3D.WINDOW_LENGTH
    left_window_length = window_length//2
    right_window_length = window_length//2
    polyorder = window_length//2

    ##---------- missing keypoints-------------
    for i in range(num_keypoints):
        x = poses[:, i, 0].copy()
        y = poses[:, i, 1].copy()
        z = poses[:, i, 2].copy()
        conf = poses[:, i, 3].copy()

        missing_timestamps = ((conf == 0).nonzero())[0]
        
        if len(missing_timestamps) == 0:
            continue

        ##----replace the missing keypoints with nan------------
        x[missing_timestamps] = np.nan
        y[missing_timestamps] = np.nan
        z[missing_timestamps] = np.nan

        all_idxs = np.arange(total_time) ## all indexes

        for missing_timestamp in missing_timestamps:
            left_timestamp = max(0, missing_timestamp - left_window_length)
            right_timestamp = min(missing_timestamp + right_window_length, total_time - 1)
            window_idxs = all_idxs[left_timestamp:right_timestamp + 1]

            assert(missing_timestamp in window_idxs)

            x_df = pd.Series(x[window_idxs]) 
            y_df = pd.Series(y[window_idxs])
            z_df = pd.Series(z[window_idxs])

            valid_values = len(x_df) - x_df.isnull().sum()

            if valid_values <= 3:
                x_prime_df, y_prime_df, z_prime_df = sliding_interpolate(x_df, y_df, z_df, polyorder=1)
            elif valid_values <= polyorder:
                x_prime_df, y_prime_df, z_prime_df = sliding_interpolate(x_df, y_df, z_df, polyorder=3)
            else:
                x_prime_df, y_prime_df, z_prime_df = sliding_interpolate(x_df, y_df, z_df, polyorder=polyorder)

            x[missing_timestamp] = x_prime_df[window_idxs == missing_timestamp]
            y[missing_timestamp] = y_prime_df[window_idxs == missing_timestamp]
            z[missing_timestamp] = z_prime_df[window_idxs == missing_timestamp]
            conf[missing_timestamp] = 1.0 ## not the window, just this timestamp

            ## fill other missing timestamps as well
            window_missing_timestamps = window_idxs[x_df.isnull()]
            x[window_missing_timestamps] = x_prime_df[x_df.isnull()]
            y[window_missing_timestamps] = y_prime_df[x_df.isnull()]
            z[window_missing_timestamps] = z_prime_df[x_df.isnull()]

            # if cfg.REFINE_POSE3D.DEBUG == True:
            #     print('t:{}'.format(missing_timestamp))
            #     print('x_t:{}'.format(x[missing_timestamp]))
            #     print('window_missing_timestamps', window_missing_timestamps)
            #     print('x_t, window', x[window_missing_timestamps])

        poses[:, i, 0] = x
        poses[:, i, 1] = y
        poses[:, i, 2] = z
        poses[:, i, 3] = conf

        assert(conf.sum() == total_time)

    return poses

def sliding_interpolate(x_df, y_df, z_df, polyorder=5):
    x_prime_df = x_df.interpolate(method='polynomial', order=polyorder).ffill().bfill()
    y_prime_df = y_df.interpolate(method='polynomial', order=polyorder).ffill().bfill()
    z_prime_df = z_df.interpolate(method='polynomial', order=polyorder).ffill().bfill()

    assert(x_prime_df.isnull().sum() == 0)
    return x_prime_df, y_prime_df, z_prime_df

def smooth_keypoints(cfg, poses, num_keypoints=17, window_length=5, polyorder=3):

    # ##------smoothing---------
    for i in range(num_keypoints):
        x = poses[:, i, 0]
        y = poses[:, i, 1]
        z = poses[:, i, 2]

        smooth_x = signal.savgol_filter(x, window_length, polyorder)
        smooth_y = signal.savgol_filter(y, window_length, polyorder)
        smooth_z = signal.savgol_filter(z, window_length, polyorder)

        poses[:, i, 0] = smooth_x
        poses[:, i, 1] = smooth_y
        poses[:, i, 2] = smooth_z
    
    return poses
