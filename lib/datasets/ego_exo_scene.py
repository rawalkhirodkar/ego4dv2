import numpy as np
import os
import cv2
import trimesh
import sys
import pickle
import json
import collections
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from models.pose_estimator import PoseModel
from models.human_detector import DetectorModel
import time

from .aria_human import AriaHuman
from .exo_camera import ExoCamera

from utils.triangulation import Triangulator
from utils.keypoints_info import COCO_KP_CONNECTIONS
from utils.keypoints_info import COCO_KP_ORDER

from utils.icp import icp
from utils.transforms import linear_transform, fast_circle, slow_circle, plane_unit_normal
import pathlib
from pyntcloud import PyntCloud
import pandas as pd
import pyvista as pv
from scipy.spatial.transform import Rotation as R

from pyntcloud.geometry.models.plane import Plane
import sympy

try:
    ##---import mmhuman functions
    from mmhuman3d.core.conventions.keypoints_mapping import convert_kps
    from mmhuman3d.core.conventions.keypoints_mapping.coco import COCO_KEYPOINTS
    from mmhuman3d.utils.transforms import rotmat_to_aa

    from models.smpl_estimator import SMPLModel
    from models.smplify import SMPLify

except:
    print('Cannot import mmhuman3d, you should be inside mmpose conda environment!')

##------------------------------------------------------------------------------------
class EgoExoScene:
    def __init__(self, cfg, root_dir):
        self.cfg = cfg
        print(self.cfg)
        self.root_dir = root_dir
        self.exo_dir = os.path.join(self.root_dir, 'exo')
        self.ego_dir = os.path.join(self.root_dir, 'ego')    
        self.colmap_dir = os.path.join(self.root_dir, 'colmap', 'workplace')

        self.bbox_dir = os.path.join(self.root_dir, 'processed_data', 'bboxes')
        self.pose2d_dir = os.path.join(self.root_dir, 'processed_data', 'poses2d')
        self.pose3d_dir = os.path.join(self.root_dir, 'processed_data', 'poses3d')
        self.refine_pose3d_dir = os.path.join(self.root_dir, 'processed_data', 'refine_poses3d')
        self.fit_pose3d_dir = os.path.join(self.root_dir, 'processed_data', 'fit_poses3d')
        self.init_smpl_dir = os.path.join(self.root_dir, 'processed_data', 'init_smpl')
        self.smpl_dir = os.path.join(self.root_dir, 'processed_data', 'smpl')

        ##---------------colmap things---------------------------
        ###-----------load the coordinate transofmrs---------------
        colmap_transforms_file = os.path.join(self.colmap_dir, 'colmap_from_aria_transforms.pkl') 
        inv_colmap_transforms_file = os.path.join(self.colmap_dir, 'aria_from_colmap_transforms.pkl') ## colmap to aria

        with open(colmap_transforms_file, 'rb') as handle:
            self.colmap_from_aria_transforms = pickle.load(handle) ## aria coordinate system to colmap

        with open(inv_colmap_transforms_file, 'rb') as handle:
            self.inv_colmap_from_aria_transforms = pickle.load(handle) ## colmap coordinate system to aria

        ##----------modify if manual-----------
        for aria_human_name in self.colmap_from_aria_transforms.keys():
            if aria_human_name in self.cfg.CALIBRATION.MANUAL_EGO_CAMERAS:
                manual_transform = np.load(os.path.join(self.colmap_dir, 'manual_calib', aria_human_name, 'transform.npy'))

                import pdb; pdb.set_trace()

                self.colmap_from_aria_transforms[aria_human_name] = manual_transform

        ##------transform from aria1 coordinate system to colmap
        self.primary_transform = self.colmap_from_aria_transforms['aria01'] 

        ##----------------load the scene point cloud-----------------
        self.scene_vertices, self.scene_ground_vertices, self.ground_plane = self.load_scene_geometry()

        ##------------------------ego--------------------------
        self.aria_human_names = [human_name for human_name in sorted(os.listdir(self.ego_dir)) if human_name not in self.cfg.INVALID_ARIAS and human_name.startswith('aria')]

        self.aria_humans = {}
        for person_idx, aria_human_name in enumerate(self.aria_human_names):
            coordinate_transform = np.dot(
                                np.linalg.inv(self.colmap_from_aria_transforms[aria_human_name]), 
                                self.primary_transform
                            ) 

            self.aria_humans[aria_human_name] = AriaHuman(
                            cfg=cfg,
                            root_dir=self.ego_dir, human_name=aria_human_name, \
                            human_id=person_idx, ground_plane=self.ground_plane, \
                            coordinate_transform=coordinate_transform)

        self.total_time = self.aria_humans[self.aria_human_names[0]].total_time
        self.time_stamp = 0 ## 0 is an invalid time stamp, we start with 1

        ##------------------------exo--------------------------
        self.exo_camera_mapping = self.get_colmap_camera_mapping()
        self.exo_camera_names = [exo_camera_name for exo_camera_name in sorted(os.listdir(self.exo_dir)) if exo_camera_name not in self.cfg.INVALID_EXOS and exo_camera_name.startswith('cam')]
        
        self.exo_cameras = {exo_camera_name: ExoCamera(cfg=cfg, root_dir=self.exo_dir, colmap_dir=self.colmap_dir, \
                            exo_camera_name=exo_camera_name, coordinate_transform=self.primary_transform, \
                            exo_camera_mapping=self.exo_camera_mapping) \
                            for exo_camera_name in self.exo_camera_names}  

        #-----check for total time-----
        for aria_human_name in self.aria_human_names:
            assert(self.aria_humans[aria_human_name].total_time == self.total_time)

        ##------------------------common---------------------
        self.view_camera = None

        ##-------------------used for triangulation-----------------
        self.ego_camera_names_with_mode = [(aria_human_name, camera_mode) \
                        for aria_human_name in self.aria_human_names \
                        for camera_mode in ['rgb', 'left', 'right']]

        self.exo_camera_names_with_mode = [(camera_name, camera_mode) \
                        for camera_name in self.exo_camera_names \
                        for camera_mode in ['rgb']]

        self.camera_names = self.ego_camera_names_with_mode + self.exo_camera_names_with_mode ##[(camera_name, camera_mode)...]
        self.cameras = {} ## all cameras

        for (camera_name, camera_mode) in self.camera_names:
            camera, view_type = self.get_camera(camera_name, camera_mode)
            self.cameras[(camera_name, camera_mode)] = camera

        ##-----------------used for smpl fitting---------------
        self.load_pose2d_flag = False
        self.load_pose3d_flag = False
        self.load_refine_pose3d_flag = False
        self.load_fit_pose3d_flag = False
        self.load_smpl_flag = False

        return  

    ##--------------------------------------------------------
    def load_scene_geometry(self, max_dist=0.1):
        Point3D = collections.namedtuple(
                "Point3D", ["id", "xyz", "rgb", "error", "image_ids", "point2D_idxs"])

        path = os.path.join(self.colmap_dir, 'points3D.txt')

        # https://github.com/colmap/colmap/blob/5879f41fb89d9ac71d977ae6cf898350c77cd59f/scripts/python/read_write_model.py#L308
        points3D = []
        with open(path, "r") as fid:
            while True:
                line = fid.readline()
                if not line:
                    break
                line = line.strip()
                if len(line) > 0 and line[0] != "#":
                    elems = line.split()
                    point3D_id = int(elems[0])
                    xyz = np.array(tuple(map(float, elems[1:4])))
                    rgb = np.array(tuple(map(int, elems[4:7])))
                    error = float(elems[7])
                    image_ids = np.array(tuple(map(int, elems[8::2])))
                    point2D_idxs = np.array(tuple(map(int, elems[9::2])))
                    points3D.append(xyz.reshape(1, -1))

        points3D = np.concatenate(points3D, axis=0)
        points3D = linear_transform(points3D, np.linalg.inv(self.primary_transform)) ## convert to aria01 from colmap

        cloud = PyntCloud(pd.DataFrame(
                        # same arguments that you are passing to visualize_pcl
                        data=points3D,
                        columns=["x", "y", "z"]))

        is_floor = cloud.add_scalar_field("plane_fit", max_dist=max_dist)

        ground_points3D = points3D[cloud.points['is_plane'] == 1]

        ground_cloud = PyntCloud(pd.DataFrame(
                        # same arguments that you are passing to visualize_pcl
                        data=ground_points3D,
                        columns=["x", "y", "z"]))

        ground_plane = Plane()
        ground_plane.from_point_cloud(ground_cloud.xyz)
        ground_plane.get_equation()

        ###----------------------------------------
        if self.cfg.GEOMETRY.MANUAL_GROUND_PLANE_POINTS != "":
            array_string = self.cfg.GEOMETRY.MANUAL_GROUND_PLANE_POINTS.replace('array(', '').replace(')', '')
            ground_points3D = np.array(json.loads(array_string))

            ## enlarge the plane 10 times.
            ground_cloud = PyntCloud(pd.DataFrame(
                        # same arguments that you are passing to visualize_pcl
                        data=ground_points3D,
                        columns=["x", "y", "z"]))

            ground_plane = Plane()
            ground_plane.from_point_cloud(ground_cloud.xyz)
            a, b, c, d = ground_plane.get_equation() ## a, b, c, d: ax + by + cz + d = 0
            centroid = ground_points3D.mean(axis=0)
            centroid_up = centroid + 0.005*np.array([a, b, c])
            centroid_down = centroid - 0.005*np.array([a, b, c])

            ## equation of plane passing through origin and is parallel to our plane
            num_points = 1000
            bound_val = 100
            x = np.random.rand(num_points) * bound_val - bound_val/2 
            y = np.random.rand(num_points) * bound_val - bound_val/2
            z = -1*(a*x + b*y)/c

            ## bigger plane
            plane_points = np.concatenate([x.reshape(-1, 1), y.reshape(-1, 1), z.reshape(-1, 1)], axis=1) + centroid
            plane_up_points = np.concatenate([x.reshape(-1, 1), y.reshape(-1, 1), z.reshape(-1, 1)], axis=1) + centroid_up
            plane_down_points = np.concatenate([x.reshape(-1, 1), y.reshape(-1, 1), z.reshape(-1, 1)], axis=1) + centroid_down

            # ground_points3D = np.concatenate([bigger_ground_points3D, ground_points3D], axis=0)
            ground_points3D = np.concatenate([plane_points, plane_up_points, plane_down_points], axis=0)

            ## add random noise
            ground_points3D += 0.1*np.random.rand(ground_points3D.shape[0], ground_points3D.shape[1])

        return points3D, ground_points3D, ground_plane

    ##--------------------------------------------------------
    def init_smpl(self):
        self.load_fit_pose3d_flag = True
        self.total_time_fit_pose3d = len([file for file in os.listdir(self.fit_pose3d_dir) if file.endswith('npy')])
        self.smpl_model = SMPLModel(cfg=self.cfg)
        self.smplify = SMPLify(cfg=self.cfg)
        return

    def init_smpl_trajectory(self):
        self.smpl_model = SMPLModel(cfg=self.cfg)
        self.smplify = SMPLify(cfg=self.cfg)

        ##----temporal-----
        self.total_time_fit_pose3d = len([file for file in os.listdir(self.fit_pose3d_dir) if file.endswith('npy')])
        time_stamps = list(range(1, self.total_time_fit_pose3d + 1))
        poses3d_trajectory = {aria_human_name:[] for aria_human_name in self.aria_human_names}

        for time_stamp in time_stamps:
            pose3d_path = os.path.join(self.refine_pose3d_dir, '{:05d}.npy'.format(time_stamp))
            poses3d = (np.load(pose3d_path, allow_pickle=True)).item()

            for aria_human_name in poses3d.keys():
                if aria_human_name in self.aria_human_names:
                    poses3d_trajectory[aria_human_name].append(poses3d[aria_human_name].reshape(1, -1, 4)) ## 1 x 17 x 4

        self.set_poses3d_trajectory(poses3d_trajectory) ## the pose trajectory for all the humans            
        return

    def load_smpl(self):
        self.load_smpl_flag = True
        self.total_time_smpl = len([file for file in os.listdir(self.smpl_dir) if file.endswith('npy')])
        
        from models.smpl_estimator import get_smpl_faces
        self.smpl_faces = get_smpl_faces()

        return
    ##-------------------------------------------------------
    def init_refine_smpl(self):
        self.load_smpl_flag = True
        self.total_time_smpl = len([file for file in os.listdir(self.smpl_dir) if file.endswith('npy')])
        return

    ##-------------------------------------------------------
    def init_refine_pose3d(self):
        self.total_time_pose3d = len([file for file in os.listdir(self.pose3d_dir) if file.endswith('npy')])

        ## load all the 3d poses in memory
        time_stamps = list(range(1, self.total_time_pose3d + 1))

        poses3d_trajectory = {aria_human_name:[] for aria_human_name in self.aria_human_names}

        for time_stamp in time_stamps:
            pose3d_path = os.path.join(self.pose3d_dir, '{:05d}.npy'.format(time_stamp))
            poses3d = (np.load(pose3d_path, allow_pickle=True)).item()

            for aria_human_name in poses3d.keys():
                if aria_human_name not in self.aria_human_names:
                    print('skipping {}'.format(aria_human_name))
                    continue
                poses3d_trajectory[aria_human_name].append(poses3d[aria_human_name].reshape(1, -1, 4)) ## 1 x 17 x 4

        self.set_poses3d_trajectory(poses3d_trajectory)            

        return

    def load_refine_pose3d(self):
        self.load_refine_pose3d_flag = True
        self.total_time_refine_pose3d = len([file for file in os.listdir(self.refine_pose3d_dir) if file.endswith('npy')])
        return

    ##-------------------------------------------------------
    def init_fit_pose3d(self):
        self.total_time_refine_pose3d = len([file for file in os.listdir(self.refine_pose3d_dir) if file.endswith('npy')])

        ## load all the 3d poses in memory
        time_stamps = list(range(1, self.total_time_refine_pose3d + 1))

        poses3d_trajectory = {aria_human_name:[] for aria_human_name in self.aria_human_names}

        for time_stamp in time_stamps:
            pose3d_path = os.path.join(self.refine_pose3d_dir, '{:05d}.npy'.format(time_stamp))
            poses3d = (np.load(pose3d_path, allow_pickle=True)).item()

            for aria_human_name in poses3d.keys():
                if aria_human_name not in self.aria_human_names:
                    continue
                poses3d_trajectory[aria_human_name].append(poses3d[aria_human_name].reshape(1, -1, 4)) ## 1 x 17 x 4

        ##-----------------------------------
        self.set_poses3d_trajectory(poses3d_trajectory)            

        return

    def load_fit_pose3d(self):
        self.load_fit_pose3d_flag = True
        self.total_time_fit_pose3d = len([file for file in os.listdir(self.fit_pose3d_dir) if file.endswith('npy')])
        return

    ##-------------------------------------------------------
    def init_pose3d(self):
        self.load_pose2d_flag = True
        self.total_time_pose2d = len([file for file in os.listdir(os.path.join(self.pose2d_dir, self.exo_camera_names[0], 'rgb')) if file.endswith('npy')])
        return

    def load_pose3d(self):
        self.load_pose3d_flag = True
        self.total_time_pose3d = len([file for file in os.listdir(self.pose3d_dir) if file.endswith('npy')])
        return         

    ##-------------------------------------------------------
    def init_pose2d(self):
        self.init_pose2d_rgb()
        self.init_pose2d_gray()
        return

    def init_pose2d_rgb(self):
        ##------------------------2d pose model-----------------------
        rgb_pose_config = self.cfg.POSE2D.RGB_CONFIG_FILE
        rgb_pose_checkpoint = self.cfg.POSE2D.RGB_CHECKPOINT

        self.rgb_pose_model = PoseModel(cfg=self.cfg, pose_config=rgb_pose_config, pose_checkpoint=rgb_pose_checkpoint)

        return

    def init_bbox(self):
        if self.cfg.POSE2D.USE_BBOX_DETECTOR == True and self.load_pose2d_flag == False:
            detector_config = self.cfg.POSE2D.DETECTOR_CONFIG_FILE
            detector_checkpoint = self.cfg.POSE2D.DETECTOR_CHECKPOINT
            self.detector_model = DetectorModel(cfg=self.cfg, detector_config=detector_config, detector_checkpoint=detector_checkpoint)

        return

    def init_pose2d_gray(self):
        ##------------------------2d pose model-----------------------
        gray_pose_config = self.cfg.POSE2D.GRAY_CONFIG_FILE
        gray_pose_checkpoint = self.cfg.POSE2D.GRAY_CHECKPOINT
        self.gray_pose_model = PoseModel(cfg=self.cfg, pose_config=gray_pose_config, pose_checkpoint=gray_pose_checkpoint)
        return

    ##--------------------------------------------------------
    def update(self, time_stamp):
        self.time_stamp = time_stamp
        for aria_human_name in self.aria_humans.keys():
            self.aria_humans[aria_human_name].update(time_stamp=self.time_stamp)    

        for exo_camera_name in self.exo_cameras.keys():
            self.exo_cameras[exo_camera_name].update(time_stamp=self.time_stamp)        

        ## load 2d poses
        if self.load_pose2d_flag == True:
            self.pose2d = {}

            for camera_name, camera_mode in self.camera_names:
                if camera_mode == 'rgb':
                    pose2d_path = os.path.join(self.pose2d_dir, camera_name, camera_mode, '{:05d}.npy'.format(time_stamp))
                    pose2d_results = np.load(pose2d_path, allow_pickle=True)
                    self.pose2d[(camera_name, camera_mode)] = pose2d_results

        ## load 3d poses
        if self.load_pose3d_flag == True:
            pose3d_path = os.path.join(self.pose3d_dir, '{:05d}.npy'.format(time_stamp))
            pose3d = np.load(pose3d_path, allow_pickle=True)
            self.set_poses3d(pose3d.item()) ## ndarray to dict, set the refined pose!

        ## load refined 3d poses
        if self.load_refine_pose3d_flag == True:
            pose3d_path = os.path.join(self.refine_pose3d_dir, '{:05d}.npy'.format(time_stamp))
            pose3d = np.load(pose3d_path, allow_pickle=True)
            self.set_poses3d(pose3d.item()) ## ndarray to dict, set the refined pose!

        ## load fitted 3d poses
        if self.load_fit_pose3d_flag == True:
            pose3d_path = os.path.join(self.fit_pose3d_dir, '{:05d}.npy'.format(time_stamp))
            pose3d = np.load(pose3d_path, allow_pickle=True)
            self.set_poses3d(pose3d.item())            

        ## load smpl params
        if self.load_smpl_flag == True:
            smpl_path = os.path.join(self.smpl_dir, '{:05d}.npy'.format(time_stamp))
            smpl = np.load(smpl_path, allow_pickle=True)
            self.set_smpl(smpl.item()) ## ndarray to dict            

        return

    ##--------------------------------------------------------
    def get_refine_poses3d(self):
        poses3d = {}
        for aria_human_name in self.aria_human_names:
            poses3d[aria_human_name] = self.aria_humans[aria_human_name].get_refine_poses3d()
        return poses3d

    def fit_poses3d(self):
        poses3d = {}
        for aria_human_name in self.aria_human_names:
            poses3d[aria_human_name] = self.aria_humans[aria_human_name].fit_poses3d()
        return poses3d

    ##--------------------------------------------------------
    def get_smpl(self):
        smpl_params = {}
        initial_smpls = self.load_initial_smpl()

        for human_name in initial_smpls.keys():
            smpl_params[human_name] = self.smplify.get_smpl(pose3d=self.aria_humans[human_name].pose3d, initial_smpl=initial_smpls[human_name])

        return smpl_params

    def get_smpl_trajectory(self):
        smpl_params_trajectory = {}
        initial_smpl_trajectory = self.load_initial_smpl_trajectory() ## H x T x smpl_info, nested dicts

        for human_name in self.aria_human_names:
            poses3d_trajectory = self.aria_humans[human_name].poses3d_trajectory ## T x 17 x 4
            smpl_params_trajectory[human_name] = self.smplify.get_smpl_trajectory(human_name=human_name, poses3d_trajectory=poses3d_trajectory, \
                    initial_smpl_trajectory=initial_smpl_trajectory[human_name])

        return smpl_params_trajectory

    ##--------------------------------------------------------
    def load_initial_smpl(self, time_stamp=None):
        if time_stamp is None:
            time_stamp = self.time_stamp
        initial_smpl_path = os.path.join(self.init_smpl_dir, '{:05d}.npy'.format(time_stamp))
        initial_smpl = np.load(initial_smpl_path, allow_pickle=True)
        return initial_smpl.item()

    def load_initial_smpl_trajectory(self):
        initial_smpl_trajectory = {human_name:{} for human_name in self.aria_human_names} ## H x T x smpl
        time_stamps = list(range(1, self.total_time_fit_pose3d + 1))

        for t in time_stamps:
            smpl_trajectory = self.load_initial_smpl(time_stamp=t) ## human
            for human_name in smpl_trajectory.keys():
                if human_name in self.aria_human_names:
                    initial_smpl_trajectory[human_name][t] = smpl_trajectory[human_name]
        return initial_smpl_trajectory


    # ## initial estimate of the SMPL from CLIFF
    def get_initial_smpl(self, choosen_camera_names, bbox_padding=1.25):
        choosen_camera_names = [(camera_name, mode) for camera_name, mode in choosen_camera_names if camera_name in self.exo_cameras.keys()] ## filter by valid camera names
        choosen_cameras = [self.exo_cameras[camera_name] for camera_name, _ in choosen_camera_names]
        best_initial_smpl = {human_name: None for human_name in self.aria_human_names} ## dict by human names
        best_initial_smpl_error = {human_name: 1e5 for human_name in self.aria_human_names}

        for camera in choosen_cameras:
            bboxes = {}

            for human_name in self.aria_humans.keys():
                bbox = camera.get_bbox_2d(aria_human=self.aria_humans[human_name]) ## xy, xy

                ## human not detected from this view
                if bbox is None:
                    continue

                bboxes[human_name] = bbox
        
            image_path = camera.get_image_path(time_stamp=self.time_stamp)
            initial_smpl = self.smpl_model.get_initial_smpl(image_path=image_path, bboxes=bboxes, bbox_padding=bbox_padding) ## dict by human name

            ## convert the smpl mesh to the global coordinate system
            for human_name in bboxes.keys():
                pose3d = self.aria_humans[human_name].pose3d

                init_transl, init_global_orient, init_transformed_vertices, init_error = self.get_initial_smpl_transformation(pose3d, initial_smpl[human_name])

                if init_error < best_initial_smpl_error[human_name]:
                    initial_smpl[human_name]['init_transl'] = init_transl
                    initial_smpl[human_name]['init_global_orient'] = init_global_orient
                    initial_smpl[human_name]['transformed_vertices'] = init_transformed_vertices ## the vertices transformed to the scene's global coordinate system
                    initial_smpl[human_name]['bbox'] = bboxes[human_name]
                    initial_smpl[human_name]['best_view'] = camera.camera_name

                    best_initial_smpl_error[human_name] = init_error
                    best_initial_smpl[human_name] = initial_smpl[human_name]

        return best_initial_smpl


    ## convert the predicted SMPL to our global coordinate system using ICP
    def get_initial_smpl_transformation(self, pose3d, smpl, max_iterations=10, error_thres=1.0):
        keypoints_coco = pose3d[:17, :3] ## 17 x 3
        init_joints = smpl['joints'] # 45 x 3
        init_rotmat = smpl['rotmat']
        init_vertices = smpl['vertices']
        init_transl = smpl['cam_full']
        init_pose = smpl['pose'] ## 72


        ###-------------------------run icp---------------------------------------------------
        init_joints_coco, init_mask = convert_kps(
                        init_joints.reshape(1, -1, 3),
                        mask=None,
                        src='smpl_45',
                        dst='coco'
                    )


        init_joints_coco = init_joints_coco[0] ## remove batch
        init_mask = init_mask == 1

        ## only consider common keypoints
        init_joints_coco = init_joints_coco[init_mask]
        keypoints_coco = keypoints_coco[init_mask]
        coco_keypoint_names = list(np.array(COCO_KP_ORDER)[init_mask])

        ##---recenter centroid to 0,0,0--
        init_joints_coco_centroid = init_joints_coco.mean(axis=0)
        init_joints_coco = init_joints_coco - init_joints[0] ## set the pelvis joint of the mesh to (0, 0, 0)
        init_vertices = init_vertices - init_joints[0] ## 
        init_transformation, distances, iterations = icp(init_joints_coco, keypoints_coco, max_iterations=20, tolerance=0.0000001) ## 4 x 4

        icp_error = distances.sum()

        ## remove the eyes and nose and ears
        if icp_error > error_thres:
            mask = init_joints_coco[:, 0] == init_joints_coco[:, 0]
            mask[coco_keypoint_names.index('nose')] = False
            mask[coco_keypoint_names.index('left_eye')] = False
            mask[coco_keypoint_names.index('right_eye')] = False
            mask[coco_keypoint_names.index('left_ear')] = False
            mask[coco_keypoint_names.index('right_ear')] = False
            init_transformation, distances, iterations = icp(init_joints_coco, keypoints_coco, init_pose=init_transformation, max_iterations=20, tolerance=0.0000001) ## 4 x 4
            icp_error = distances.sum()

        ##------------------------------------------------------------------------------------
        init_transl = init_transformation[:3, 3].copy() ## not exactly correct!

        init_global_orient_rotmat = np.dot(init_transformation[:3, :3].copy(), init_rotmat[0]) 
        init_global_orient = rotmat_to_aa(matrix=init_global_orient_rotmat)

        ###---------get how the verticies initialized would look like----------------
        transformed_vertices = self.smpl_model.get_initial_vertices(betas=smpl['betas'], \
                        body_pose_aa=smpl['pose'][3:], global_orient_aa=init_global_orient, transl=init_transl)

        return init_transl, init_global_orient, transformed_vertices, icp_error

    def save_initial_smpl(self, smpl, save_path):
        np.save(save_path, smpl, allow_pickle=True)
        return

    def save_smpl(self, smpl, save_path):
        np.save(save_path, smpl, allow_pickle=True)
        return


     ## no intersecting foot to the plane, currently deprecated
    def ground_plane_contact(self, vertices):
        max_offset = self.cfg.BLENDER.MAX_OFFSET
        tol = self.cfg.BLENDER.TOLERANCE
        mesh = trimesh.Trimesh(vertices, self.smpl_faces)

        signed_distance = self.proximity_manager.signed_distance(vertices) #https://trimsh.org/trimesh.proximity.html#trimesh.proximity.ProximityQuery.signed_distance
        intersecting_vertices = signed_distance > tol

        if intersecting_vertices.sum() > 0:
            distance_to_plane = min(max_offset, max(signed_distance[intersecting_vertices])) 
            normal = plane_unit_normal(self.ground_plane)
            vertices = vertices + distance_to_plane*normal

        return vertices

    def save_mesh_as_obj(self, save_dir):
        os.makedirs(save_dir, exist_ok=True)

        all_vertices = {human_name: self.aria_humans[human_name].smpl['vertices'] for human_name in self.aria_human_names} ## 6890 x 3
        
        ##----refine to solve for the touching ground floor----
        # all_modified_vertices = self.ground_plane_contact(all_vertices) ## deprecated logic
        all_modified_vertices = all_vertices

        for human_name in all_modified_vertices.keys():
            human = self.aria_humans[human_name]
            vertices = all_modified_vertices[human_name]
            mesh = trimesh.Trimesh(vertices, self.smpl_faces)
            mesh.visual.face_colors = [human.color[2], human.color[1], human.color[0], 255*human.alpha] ## note the colors are bgr
            mesh.export(os.path.join(save_dir, 'mesh_{}.obj'.format(human_name)))

        return

    def save_mesh_as_obj_ego(self, save_dir, distance_thres=0.3):
        os.makedirs(save_dir, exist_ok=True)

        for human_name in self.aria_human_names:
            human = self.aria_humans[human_name]
            smpl_human = human.smpl
            vertices = smpl_human['vertices'] ## 6890 x 3
            mesh = trimesh.Trimesh(vertices, self.smpl_faces)

            ##--------save the aria location as obj-----------------
            transform = np.eye(4) ##4x4
            transform[:3, 3] = human.location ## place the sphere at the location
            head_mesh = trimesh.primitives.Sphere(radius=0.0001)
            head_mesh.apply_transform(transform)
            head_mesh.export(os.path.join(save_dir, 'mesh_head_{}.obj'.format(human_name)))

            ##------------------------------------------------------
            # ## delete the head
            if human_name == 'aria01':
                distances = np.sqrt(((vertices - human.location)**2).sum(axis=1))
                is_valid = distances < distance_thres
                head_vertices_idx = (is_valid.nonzero())[0]

                face_mask = (self.smpl_faces == self.smpl_faces)[:, 0] ## intialize

                for head_vertex_idx in head_vertices_idx:
                    is_vertex_in_faces = (self.smpl_faces == head_vertex_idx).sum(axis=1)
                    face_idxs = (is_vertex_in_faces.nonzero())[0]
                    face_mask[face_idxs] = False ## delete these faces

                mesh.update_faces(face_mask)

            mesh.visual.face_colors = [human.color[2], human.color[1], human.color[0], 255*human.alpha] ## note the colors are bg
            mesh.export(os.path.join(save_dir, 'mesh_{}.obj'.format(human_name)))

        return

    def get_ground_plane_mesh(self):

        prefix = ''

        if self.cfg.GEOMETRY.MANUAL_GROUND_PLANE_POINTS != '':
            prefix = 'manual_'

        ground_plane_mesh = pv.PolyData(self.scene_ground_vertices)
        volume = ground_plane_mesh.delaunay_3d(alpha=2.)

        shell = volume.extract_geometry()

        faces_as_array = shell.faces.reshape((-1, 4))[:, 1:]
        ground_mesh = trimesh.Trimesh(shell.points, faces_as_array)

        ground_mesh.export(os.path.join(self.colmap_dir, '{}raw_ground_plane_mesh.obj'.format(prefix)))

        print('ground plane saved to colmap dir! please import it in the scene.blend if not done already!')

        ##-----------save the ground plane equation as obj-----------------
        immutable_ground_plane = ground_mesh.bounding_box_oriented
        ground_plane = trimesh.Trimesh(vertices=immutable_ground_plane.vertices, faces=immutable_ground_plane.faces)
        ground_plane.export(os.path.join(self.colmap_dir, '{}ground_plane_mesh.obj'.format(prefix)))

        return ground_plane

    # #     colors = {
    #     'pink': np.array([197, 27, 125]),
    #     'light_pink': np.array([233, 163, 201]),
    #     'light_green': np.array([161, 215, 106]),
    #     'green': np.array([77, 146, 33]),
    #     'red': np.array([215, 48, 39]),
    #     'light_red': np.array([252, 146, 114]),
    #     'light_orange': np.array([252, 141, 89]),
    #     'purple': np.array([118, 42, 131]),
    #     'light_purple': np.array([175, 141, 195]),
    #     'light_blue': np.array([145, 191, 219]),
    #     'blue': np.array([69, 117, 180]),
    #     'gray': np.array([130, 130, 130]),
    #     'white': np.array([255, 255, 255]),
    #     'turkuaz': np.array([50, 134, 204]),
    # }

    def init_blender_vis(self):
        self.ground_plane_mesh = self.get_ground_plane_mesh()
        self.collision_manager = trimesh.collision.CollisionManager()
        self.collision_manager.add_object('ground', self.ground_plane_mesh)
        self.proximity_manager = trimesh.proximity.ProximityQuery(self.ground_plane_mesh)

        ## the normal to the plane pointing upwards
        colmap_normal = plane_unit_normal(self.ground_plane) ## from the colmap
        trimesh_normals = self.ground_plane_mesh.face_normals
        
        ## figure out the trimesh normal clossest to the colmap normal
        normal_idx = ((colmap_normal*trimesh_normals).sum(axis=1)).argmax()
        self.ground_plane_normal = trimesh_normals[normal_idx]

        face = self.ground_plane_mesh.faces[normal_idx]
        self.ground_plane_origin = np.array(self.ground_plane_mesh.vertices[face[0]])

        return

    def blender_vis(self, mesh_dir, save_path):
        scene_name = self.cfg.BLENDER.SCENE_FILE
        colors = self.cfg.BLENDER.COLORS

        root_dir = os.path.join(pathlib.Path(__file__).parent.resolve(), '..', '..') 
        scene_file = os.path.join(root_dir, 'assets', scene_name) 

        blender_file = os.path.join(root_dir, 'lib', 'utils', 'blender.py')
        thickness = 0

        image_size = 1024
        focal_length = 2500
        output_file = save_path

        ####-------------------------------------------
        command = "blender -b {} \
          --python {} -- \
          -i {} \
          -o {} \
          -of {} \
          -t {} -f {} --sideview -c {} -s {}".format(\
                    scene_file, blender_file, \
                    mesh_dir, mesh_dir, output_file, thickness, focal_length,\
                    colors, image_size) 

        os.system(command)

        return

    def blender_vis_ego(self, aria_human_name, mesh_dir, save_path, scene_name='tagging/tagging_ego.blend'):

        ## comment or uncomment if scene is properly set
        # self.get_ground_plane_mesh()

        root_dir = os.path.join(pathlib.Path(__file__).parent.resolve(), '..', '..') 
        scene_file = os.path.join(root_dir, 'assets', scene_name) 

        ##---------------get camera translation and rotation-------------------
        ## world matrix of objects in blender
        blender_convention = np.zeros((4, 4))
        blender_convention[0, 0] = 1
        blender_convention[1, 1] = -4.371138828673793e-08
        blender_convention[1, 2] = -1
        blender_convention[2, 2] = -4.371138828673793e-08
        blender_convention[2, 1] = 1
        blender_convention[3, 3] = 1

        ###-------------------------------------------------------
        camera_rotation = self.cameras[(aria_human_name, 'rgb')].get_rotation()
        print('rotation', camera_rotation)
            
        ###--------------convert to blender camera system, xyz -> xzy
        # camera_rotation_blender = np.dot(blender_convention[:3, :3], camera_rotation)
        camera_rotation_blender = camera_rotation

        camera_rotation_blender = R.from_matrix(camera_rotation_blender)

        # camera_rotation_blender_euler = camera_rotation_blender.as_euler('xyz', degrees=True)
        camera_rotation_blender_euler = camera_rotation_blender.as_euler('xyz', degrees=False)

        # camera_rotation_blender_euler = np.array([268, -0.0754, -70]) * np.pi/180.0

        camera_rotation_string = ':' +  ':'.join([str(val) for val in camera_rotation_blender_euler.tolist()]) + ':'

        # camera_rotation_blender_quaternion = np.array([-0.569, 0.589, 0.413, 0.398]) 
        # camera_rotation_string = ':' +  ':'.join([str(val) for val in camera_rotation_blender_quaternion.tolist()]) + ':'

        blender_file = os.path.join(root_dir, 'lib', 'utils', 'blender_ego.py')
        thickness = 0
        colors = 'blue###green###red###orange'
        image_size = 1408
        focal_length = 2500
        output_file = save_path

        ####-------------------------------------------
        command = "blender -b {} \
          --python {} -- \
          -i {} \
          -o {} \
          -of {} \
          -t {} -f {} --sideview -c {} -s {} \
          --camera_rotation {}".format(\
                    scene_file, blender_file, \
                    mesh_dir, mesh_dir, output_file, thickness, focal_length,\
                    colors, image_size, camera_rotation_string) 
        os.system(command)

        return

    def draw_initial_smpl(self, smpl, save_path):
        original_image = self.view_camera.get_image(time_stamp=self.time_stamp)
        image = original_image.copy()
        overlay = 255*np.ones(image.shape)
        alpha = 0.7

        for human_name in smpl.keys():
            ## skip if human_name is the same as aria
            if human_name == self.viewer_name:
                continue
                
            smpl_human = smpl[human_name]
            color = self.aria_humans[human_name].color

            points_3d = smpl_human['transformed_vertices'] ## 6890 x 3
            # points_3d = self.aria_humans[human_name].pose3d[:, :3] 

            points_2d = self.view_camera.vec_project(points_3d)

            ## rotated poses from aria frame to human frame
            if self.view_camera.camera_type == 'ego':
                points_2d = self.view_camera.get_inverse_rotated_pose2d(pose2d=points_2d)

            is_valid = (points_2d[:, 0] >= 0) * (points_2d[:, 0] < image.shape[1]) * \
                        (points_2d[:, 1] >= 0) * (points_2d[:, 1] < image.shape[0])

            points_2d = points_2d[is_valid] ## only plot inside image points

            ## for exo
            if image.shape[0] > 1408:
                radius = 3
            else:
                radius = 1

            for idx in range(len(points_2d)):
                image = cv2.circle(image, (round(points_2d[idx, 0]), round(points_2d[idx, 1])), radius, color, -1)
                overlay = cv2.circle(overlay, (round(points_2d[idx, 0]), round(points_2d[idx, 1])), radius, color, -1)

        image = cv2.addWeighted(image, alpha, original_image, 1 - alpha, 0)
        image = np.concatenate([image, overlay], axis=1)

        ##----------------
        cv2.imwrite(save_path, image)

        return

    ##--------------------------------------------------------
    def draw_smpl(self, smpl, save_path):
        original_image = self.view_camera.get_image(time_stamp=self.time_stamp)
        image = original_image.copy()
        overlay = 255*np.ones(image.shape)
        alpha = 0.7

        for human_name in smpl.keys():
            ## skip if human_name is the same as aria
            if human_name == self.viewer_name:
                continue

            smpl_human = smpl[human_name]
            color = self.aria_humans[human_name].color

            points_3d = smpl_human['vertices']
            points_2d = self.view_camera.vec_project(points_3d)

            ## rotated poses from aria frame to human frame
            if self.view_camera.camera_type == 'ego':
                points_2d = self.view_camera.get_inverse_rotated_pose2d(pose2d=points_2d)

            is_valid = (points_2d[:, 0] >= 0) * (points_2d[:, 0] < image.shape[1]) * \
                        (points_2d[:, 1] >= 0) * (points_2d[:, 1] < image.shape[0])

            points_2d = points_2d[is_valid] ## only plot inside image points

            ## for exo
            if image.shape[0] > 1408:
                radius = 3
            else:
                radius = 1

            image, overlay = fast_circle(image, overlay, points_2d, radius, color)
            # image, overlay = slow_circle(image, overlay, points_2d, radius, color)

        image = cv2.addWeighted(image, alpha, original_image, 1 - alpha, 0)
        image = np.concatenate([image, overlay], axis=1)

        ##----------------
        cv2.imwrite(save_path, image)

        return

    ##--------------------------------------------------------
    def triangulate(self, flag='exo', secondary_flag='ego_rgb', debug=False):
        if flag == 'ego':
            choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in self.ego_camera_names_with_mode] ## only ego
        elif flag == 'exo':
            choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in self.exo_camera_names_with_mode] ## only exo
        elif flag == 'ego_rgb':
            choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in self.ego_camera_names_with_mode if camera_mode == 'rgb'] ## only ego, only rgb
        elif flag == 'all_rgb':
            choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in self.exo_camera_names_with_mode] ## only exo
            choosen_camera_names += [(camera_name, camera_mode) for (camera_name, camera_mode) in self.ego_camera_names_with_mode if camera_mode == 'rgb'] ## exo + ego rgb
        elif flag == 'all':
            choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in \
                                    self.ego_camera_names_with_mode + self.exo_camera_names_with_mode] ## both

        ##-------------------------------------------------------------
        if secondary_flag == 'ego_rgb':
            secondary_choosen_camera_names = [(camera_name, camera_mode) for (camera_name, camera_mode) in self.ego_camera_names_with_mode if camera_mode == 'rgb'] ## only ego, only rgb

        ##-------------------------------------------------------------
        if debug == True:
            print('-------------------time_stamp:{}-------------------'.format(self.time_stamp))

        triangulator = Triangulator(cfg=self.cfg, time_stamp=self.time_stamp, camera_names=choosen_camera_names, \
                        cameras={val: self.cameras[val] for val in choosen_camera_names}, \
                        secondary_camera_names=secondary_choosen_camera_names, \
                        secondary_cameras={val: self.cameras[val] for val in secondary_choosen_camera_names}, \
                        pose2d=self.pose2d, humans=self.aria_humans)

        poses3d = triangulator.run(debug=debug)
        return poses3d

    def draw_poses3d(self, poses3d_list, save_path):
        ##---------------visualize---------------------------
        fig = plt.figure()
        ax = fig.add_subplot(111, projection='3d')
        ax.set_box_aspect([1,1,1])

        for poses3d in poses3d_list:
            for human_name in poses3d.keys():
                points_3d = poses3d[human_name]
                color_string = self.aria_humans[human_name].color_string

                for _c in COCO_KP_CONNECTIONS:
                    ax.plot(xs=[points_3d[_c[0],0], points_3d[_c[1],0]], ys=[points_3d[_c[0],1], points_3d[_c[1],1]], zs=[points_3d[_c[0],2], points_3d[_c[1],2]], c=color_string)
                    # ax.scatter(xs=points_3d[:,0], ys=points_3d[:, 1], zs=points_3d[:, 2], c='blue')
                        
        plt.show()

        return

    def set_poses3d(self, poses3d):
        for human_name in poses3d.keys():
            if human_name not in self.aria_humans.keys():
                print('skipping {}'.format(human_name))
                continue
            self.aria_humans[human_name].set_pose3d(pose3d=poses3d[human_name])
        return

    def set_poses3d_trajectory(self, poses3d_trajectory):
        for human_name in poses3d_trajectory.keys():
            trajectory = poses3d_trajectory[human_name]
            trajectory = np.concatenate(trajectory, axis=0) ## T x 17 x 4
            self.aria_humans[human_name].set_poses3d_trajectory(poses3d_trajectory=trajectory)

        return

    def set_smpl(self, smpl):
        for human_name in smpl.keys():
            self.aria_humans[human_name].set_smpl(smpl=smpl[human_name])

        return

    def save_poses3d(self, poses3d, save_path):
        np.save(save_path, poses3d, allow_pickle=True)
        return

    ##--------------------------------------------------------
    def get_camera(self, camera_name='aria01', camera_mode='rgb'):
        camera = None
        view_type = None

        ## ego
        if camera_name in self.aria_human_names:
            view_type = 'ego'
            if camera_mode == 'rgb':
                camera = self.aria_humans[camera_name].rgb_cam

            elif camera_mode == 'left':
                camera = self.aria_humans[camera_name].left_cam

            elif camera_mode == 'right':
                camera = self.aria_humans[camera_name].right_cam

        elif camera_name in self.exo_camera_names:
            view_type = 'exo'
            camera = self.exo_cameras[camera_name]

        else:
            print('invalid camera name!: {},{}'.format(camera_name, camera_mode))
            exit()

        return camera, view_type

    ##--------------------------------------------------------
    def set_view(self, camera_name='aria01', camera_mode='rgb'):
        camera, view_type = self.get_camera(camera_name, camera_mode)
        self.view_camera = camera
        self.view_camera_type = camera_mode
        self.view_type = view_type ## ego or exo
        self.viewer_name = camera_name

        return 

    ##-----------------------bboxes----------------------------
    def get_bboxes(self):
        bboxes = []
        aria_humans = [aria_human for aria_human_name, aria_human in self.aria_humans.items() if aria_human_name != self.viewer_name]

        for aria_human in aria_humans:
            bbox = self.view_camera.get_bbox_2d(aria_human=aria_human)

            if bbox is not None:
                bbox = np.array([bbox[0], bbox[1], bbox[2], bbox[3], 1]) ## add confidnece
                bboxes.append({'bbox': bbox, \
                                'human_name': aria_human.human_name, \
                                'human_id': aria_human.human_id, \
                                'color': aria_human.color})

        if self.cfg.POSE2D.USE_BBOX_DETECTOR == True:
            image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)
            offshelf_bbox = self.detector_model.get_bboxes(image_name=image_name, bboxes=bboxes)

        return bboxes

    def save_bboxes(self, bboxes, save_path):
        np.save(save_path, bboxes, allow_pickle=True)
        return

    def load_bboxes(self):
        bboxes_path = os.path.join(self.bbox_dir, self.view_camera.camera_name, self.view_camera.type_string, '{:05d}.npy'.format(self.time_stamp))
        bboxes = np.load(bboxes_path, allow_pickle=True).tolist()
        return bboxes

    def draw_bboxes(self, bboxes, save_path):
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)
        image = cv2.imread(image_name)

        for bbox_2d_info in bboxes:
            bbox_2d = bbox_2d_info['bbox']
            color = bbox_2d_info['color']

            if image.shape[0] > 1408:
                thickness = 12
            elif image.shape[0] == 1408:
                thickness = 5
            else:
                thickness = 2

            image = cv2.rectangle(image, (round(bbox_2d[0]), round(bbox_2d[1])), (round(bbox_2d[2]), round(bbox_2d[3])), color, thickness)
        
        cv2.imwrite(save_path, image)

        return 

    def draw_scene_vertices(self, save_path):
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)
        image = cv2.imread(image_name)

        points_2d = self.view_camera.vec_project(self.scene_ground_vertices) ## N x 2

        if self.view_camera.camera_type == 'ego':
            x = points_2d[:, 0].copy()
            y = points_2d[:, 1].copy()

            rotated_x = self.view_camera.rotated_image_height - y
            rotated_y = x 

            points_2d[:, 0] = rotated_x
            points_2d[:, 1] = rotated_y
        
        ## for exo
        if image.shape[0] > 1408:
            radius = 3
        else:
            radius = 1

        for idx in range(len(points_2d)):
            image = cv2.circle(image, (round(points_2d[idx, 0]), round(points_2d[idx, 1])), radius, [255, 255, 0], -1)
        
        cv2.imwrite(save_path, image)

        return 

    ##-----------------------get aria locations------------------
    def get_aria_locations(self, debug=False):
        aria_locations = []
        aria_humans = [aria_human for aria_human_name, aria_human in self.aria_humans.items() if aria_human_name != self.viewer_name]

        for aria_human in aria_humans:
            aria_human_location_2d, is_valid = self.view_camera.get_aria_location(point_3d=aria_human.location)

            if debug == True:
                print('view: {}, human:{}, loc:{}, is_valid:{}'.format(self.view_camera.camera_name, aria_human.human_name, aria_human_location_2d, is_valid))

            ## inside the frame            
            if is_valid:
                aria_locations.append({'location':aria_human_location_2d, 'color': aria_human.color, 'human_name': aria_human.human_name})

        return aria_locations

    def get_exo_locations(self):
        exo_locations = []

        for exo_camera_name, exo_camera in self.exo_cameras.items():
            location_2d, is_valid = self.view_camera.get_aria_location(point_3d=exo_camera.location)

            ## inside the frame            
            if is_valid:
                exo_locations.append({'location':location_2d, 'color': [255, 255, 0], 'human_name': exo_camera_name})

        return exo_locations

    def draw_camera_locations(self, aria_locations_2d, save_path):
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)
        image = cv2.imread(image_name)

        for location_info in aria_locations_2d:
            location = location_info['location']
            color = location_info['color']

            ## for exo
            if image.shape[0] > 1408:
                radius = 10
            elif image.shape[0] < 1408:
                radius = 3
            else:
                radius = 5

            image = cv2.circle(image, (round(location[0]), round(location[1])), radius, color, -1)
        
        cv2.imwrite(save_path, image)

        return 

    ## both ego and exo
    def get_camera_locations(self):
        aria_locations = self.get_aria_locations()
        exo_locations = self.get_exo_locations()

        locations = aria_locations + exo_locations

        return locations


    ##-------------------------poses2d---------------------------
    def get_poses2d(self, save_results=True):
        bboxes = self.load_bboxes()
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)

        if self.view_camera.type_string == 'rgb':
            pose_results = self.rgb_pose_model.get_poses2d(bboxes=bboxes, \
                                        image_name=image_name, \
                                        camera_type=self.view_camera.camera_type, ## ego or exo
                                        camera_mode=self.view_camera.type_string,
                                        camera=self.view_camera,
                                        aria_humans=self.aria_humans,
                                    )
        else:
            pose_results = self.gray_pose_model.get_poses2d(bboxes=bboxes, \
                                        image_name=image_name, \
                                        camera_type=self.view_camera.camera_type, ## ego or exo
                                        camera_mode=self.view_camera.type_string,
                                        camera=self.view_camera,
                                        aria_humans=self.aria_humans,
                                    )

        return pose_results    

    def save_poses2d(self, pose_results, save_path):
        np.save(save_path, pose_results, allow_pickle=True)
        return   

    def draw_poses2d(self, pose_results, save_path):
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)

        if self.view_camera.type_string == 'rgb':
            self.rgb_pose_model.draw_poses2d(pose_results, image_name, save_path, \
                                    camera_type=self.view_camera.camera_type, ## ego or exo
                                    camera_mode=self.view_camera.type_string)

        else:
            self.gray_pose_model.draw_poses2d(pose_results, image_name, save_path, \
                                    camera_type=self.view_camera.camera_type, ## ego or exo
                                    camera_mode=self.view_camera.type_string)

        return    

    def draw_rotated_poses2d(self, pose_results, save_path):
        image_name = self.view_camera.get_rotated_image_path(time_stamp=self.time_stamp)

        for idx in range(len(pose_results)):
            keypoints = pose_results[idx]['keypoints']
            bbox = pose_results[idx]['bbox']
            pose_results[idx]['keypoints'], pose_results[idx]['bbox'] = self.view_camera.get_rotated_pose2d(pose2d=keypoints, bbox=bbox)

        if self.view_camera.type_string == 'rgb':
            self.rgb_pose_model.draw_poses2d(pose_results, image_name, save_path, \
                                    camera_type=self.view_camera.camera_type, ## ego or exo
                                    camera_mode=self.view_camera.type_string)

        else:
            self.gray_pose_model.draw_poses2d(pose_results, image_name, save_path, \
                                    camera_type=self.view_camera.camera_type, ## ego or exo
                                    camera_mode=self.view_camera.type_string)

        return    

    ## only of the view of the scene
    def load_poses2d(self):
        pose2d_path = os.path.join(self.pose2d_dir, self.view_camera.camera_name, self.view_camera.type_string, '{:05d}.npy'.format(self.time_stamp))
        pose2d = np.load(pose2d_path, allow_pickle=True).tolist()   
        return pose2d

    ##-------------------------------------------------------------
    def get_poses3d(self):
        return {human_name: self.aria_humans[human_name].pose3d for human_name in self.aria_humans}

    ##-----------------project the pose3d of the aria humans from the viewer-------
    def get_projected_poses3d(self):
        pose_results = {}

        for human_name in self.aria_humans:
            if human_name != self.viewer_name:
                pose3d = self.aria_humans[human_name].pose3d ## 17 x 4
                projected_pose3d = self.view_camera.vec_project(pose3d[:, :3]) ## 17 x 2
                projected_pose3d = np.concatenate([projected_pose3d, pose3d[:, 3].reshape(-1, 1)], axis=1) ## 17 x 3

                ## rotated poses from aria frame to human frame
                if self.view_camera.camera_type == 'ego':
                    projected_pose3d = self.view_camera.get_inverse_rotated_pose2d(pose2d=projected_pose3d)

                pose_results[human_name] = projected_pose3d

        return pose_results

    ## 3d poses in camera coordinate system, RGB
    def get_cam_poses3d(self):
        assert self.viewer_name.startswith('aria')
        pose_results = {}

        for human_name in self.aria_humans:
            if human_name != self.viewer_name:
                pose3d = self.aria_humans[human_name].pose3d ## 17 x 4
                pose3d_cam = self.view_camera.vec_cam_from_world(pose3d[:, :3])
                pose3d_cam = np.concatenate([pose3d_cam, pose3d[:, 3].reshape(-1, 1)], axis=1) ## 17 x 4, note its in the rotated camera

                pose_results[human_name] = pose3d_cam

        return pose_results

    def draw_projected_poses3d(self, pose_results, save_path):
        image_name = self.view_camera.get_image_path(time_stamp=self.time_stamp)

        ##------------this is a generic function------------------
        self.rgb_pose_model.draw_projected_poses3d(pose_results, image_name, save_path, \
                                    camera_type=self.view_camera.camera_type, ## ego or exo
                                    camera_mode=self.view_camera.type_string)

        return    

    ##--------------------------------------------------------
    def get_image(self):
        return self.view_camera.get_image(time_stamp=self.time_stamp) ## opencv, BGR image

    ##--------------------------------------------------------
    def debug(self):
        radius = 1
        scene_list = []

        ##-------ego spheres-----------
        for aria_human_name in self.aria_human_names:
            aria_human = self.aria_humans[aria_human_name]
            sphere = aria_human.get_sphere_mesh(point_3d=aria_human.location, radius=radius)
            scene_list.append(sphere)

        ##-------exo spheres-----------
        for exo_camera_name in self.exo_camera_names:
            exo_camera = self.exo_cameras[exo_camera_name]
            sphere = exo_camera.get_sphere_mesh(point_3d=exo_camera.location, radius=radius)
            scene_list.append(sphere)

        scene = trimesh.Scene(scene_list)
        scene.show()

        return

        ego_objects = [self.aria_humans[aria_human_name] for aria_human_name in self.aria_human_names]
        run_debug(ego_objects)

        return

    ##-----------------------------------------------------------------
    def get_colmap_camera_mapping(self):
        self.intrinsics_calibration_file = os.path.join(self.colmap_dir, 'cameras.txt')
        self.extrinsics_calibration_file = os.path.join(self.colmap_dir, 'images.txt')

        with open(self.intrinsics_calibration_file) as f:
            intrinsics = f.readlines()
            intrinsics = intrinsics[3:] ## drop the first 3 lines

        colmap_camera_ids = []
        is_exo_camera = []
        for line in intrinsics:
            line = line.split()
            colmap_camera_id = int(line[0])
            colmap_camera_model = line[1]
            image_width = int(line[2])
            image_height = int(line[3])

            colmap_camera_ids.append(colmap_camera_id)

            if image_height == 1408 and image_width == 1408:
                is_exo_camera.append(False)
            else:
                is_exo_camera.append(True)

        num_colmap_arias = len(is_exo_camera) - sum(is_exo_camera)
        num_arias = len(os.listdir(self.ego_dir))
        exo_camera_names = sorted(os.listdir(self.exo_dir))

        # assert(num_colmap_arias == num_arias)

        ## get the name of the folder containing the camera name for the exo cameras
        exo_camera_mapping = {}
        for (colmap_camera_id, is_valid) in zip(colmap_camera_ids, is_exo_camera):
            if is_valid == True:
                exo_camera_name = self.get_camera_name_from_colmap_camera_id(colmap_camera_id)
                assert(exo_camera_name is not None)
                exo_camera_mapping[exo_camera_name] = colmap_camera_id            

        return exo_camera_mapping

    ##--------------------------------------------------------
    def get_camera_name_from_colmap_camera_id(self, colmap_camera_id):
        with open(self.extrinsics_calibration_file) as f:
            extrinsics = f.readlines()
            extrinsics = extrinsics[4:] ## drop the first 4 lines
            extrinsics = extrinsics[::2] ## only alternate lines

        for line in extrinsics:
            line = line.strip().split()
            camera_id = int(line[-2])
            image_path = line[-1]
            camera_name = image_path.split('/')[0]

            if camera_id == colmap_camera_id:
                return camera_name

        return None