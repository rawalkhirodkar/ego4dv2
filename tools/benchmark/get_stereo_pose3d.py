import _init_paths
import numpy as np
import os
import argparse
from tqdm import tqdm
import json
import cv2
import matplotlib.pyplot as plt
from cycler import cycle
from pathlib import Path
from mpl_toolkits.mplot3d import Axes3D
import mmcv
from datetime import datetime
from datasets.aria_camera import AriaCamera
from datasets.aria_human import AriaHuman
from datasets.ego_exo_scene import EgoExoScene

from configs import cfg
from configs import update_config
from pycocotools.coco import COCO
from pycococreatortools import pycococreatortools
import pickle 
from utils.transforms import linear_transform, fast_circle
from utils.triangulation import Triangulator

##------------------------------------------------------------------------------------
def pose_to_bbox(pose, image_width, image_height, keypoint_thres=0.5, padding=1.4, min_keypoints=5):
    is_valid = (pose[:, 2] > keypoint_thres)  
    is_valid = is_valid * (pose[:, 0] > 0) * (pose[:, 0] <= image_width)
    is_valid = is_valid * (pose[:, 1] > 0) * (pose[:, 1] <= image_height)

    if is_valid.sum() < min_keypoints:
        return None, None, None, None, None

    x1 = pose[is_valid, 0].min(); x2 = pose[is_valid, 0].max()
    y1 = pose[is_valid, 1].min(); y2 = pose[is_valid, 1].max()

    center_x = (x1 + x2)/2
    center_y = (y1 + y2)/2

    scale_x = (x2 - x1)*padding
    scale_y = (y2 - y1)*padding

    bbx = max(1, center_x - scale_x/2)
    bby = max(1, center_y - scale_y/2)

    bbw = scale_x
    bbh = scale_y

    return bbx, bby, bbw, bbh, is_valid


##------------------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description='Visualization of extrinsics of camera parameters.')
    parser.add_argument('--sequence_path', action='store', help='the path to the sequence for visualization')
    parser.add_argument('--output_path', action='store', help='the path to the sequence for visualization')

    args = parser.parse_args()
    sequence_path = args.sequence_path
    sequence_name = sequence_path.split('/')[-1]
    parent_sequence = sequence_name.split('_')[-1]
    config_file = os.path.join(_init_paths.root_path, 'configs', parent_sequence, '{}.yaml'.format(sequence_name))
    update_config(cfg, config_file)

    scene = EgoExoScene(cfg=cfg, root_dir=sequence_path)
    scene.init_pose2d_rgb() ## for visualization
    scene.load_fit_pose3d() ## load all the 3d poses in memory

    output_path = os.path.join(args.output_path, 'coco_track') 
    os.makedirs(output_path, exist_ok=True)

    # time_stamps = list(range(1, scene.total_time_fit_pose3d  + 1))
    time_stamps = [1]
    triangulator = Triangulator(scene.cfg, [], [], [], [], {}, {})

    for t in tqdm(time_stamps):
        scene.update(time_stamp=t)

        # cameras = scene.exo_camera_names_with_mode + scene.ego_camera_names_with_mode
        camera_name = 'aria01'
        rgb_camera = scene.cameras[(camera_name, 'rgb')]
        left_camera = scene.cameras[(camera_name, 'left')]
        right_camera = scene.cameras[(camera_name, 'right')]

        rgb_image = rgb_camera.get_image(t)
        left_image = left_camera.get_image(t)
        right_image = right_camera.get_image(t)

        subject_name = 'aria03'
        pose3d = scene.aria_humans[subject_name].pose3d
        num_points = len(pose3d)

        ###--------------get rgb pose2d---------------------
        scene.set_view(camera_name=camera_name, camera_mode='rgb')
        rgb_poses2d = scene.get_projected_poses3d()
        rgb_pose2d = rgb_poses2d[subject_name] ## for example

         ###--------------get left pose2d---------------------
        scene.set_view(camera_name=camera_name, camera_mode='left')
        left_poses2d = scene.get_projected_poses3d()
        left_pose2d = left_poses2d[subject_name] ## for example

         ###--------------get right pose2d---------------------
        scene.set_view(camera_name=camera_name, camera_mode='right')
        right_poses2d = scene.get_projected_poses3d()
        right_pose2d = right_poses2d[subject_name] ## for example

        rgb_image = fast_circle(rgb_image, None, rgb_pose2d, 5, [0, 255, 0])
        cv2.imwrite('rgb.jpg', rgb_image)

        ##-------------------------------------------------------
        ###--------------triangulate----------------
        points_3d = np.zeros((num_points, 3))

        for point_idx in range(num_points):
            proj_matricies = []
            points = []

            for points_2d, camera in zip([rgb_pose2d, right_pose2d], [rgb_camera, right_camera]):
                point_2d = points_2d[point_idx, :2]
                extrinsics = camera.extrinsics[:3, :] ## 3x4
                ray_3d = camera.cam_from_image(point_2d=point_2d)
                assert(len(ray_3d) == 3 and ray_3d[2] == 1)  
                point = ray_3d.copy()
                points.append(point)
                proj_matricies.append(extrinsics)

            point_3d, inlier_views, reprojection_error_vector = triangulator.triangulate_ransac(proj_matricies, points, n_iters=100, reprojection_error_epsilon=0.01, direct_optimization=True)
            points_3d[point_idx, :] = point_3d[:]
            print(reprojection_error_vector, inlier_views)

        import pdb; pdb.set_trace()
        projected_pose3d = rgb_camera.vec_project(points_3d[:, :3])
        scene.draw_poses3d([{subject_name: points_3d}], 'yo.jpg')



    return


##------------------------------------------------------------------------------------
if __name__ == "__main__":
    main()