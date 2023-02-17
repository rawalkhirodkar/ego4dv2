import numpy as np
import os
import cv2
from tqdm import tqdm
import sys
import pathlib
import torch
import mmcv
from mmhuman3d.core.conventions.keypoints_mapping import convert_kps
from mmhuman3d.core.evaluation import keypoint_mpjpe
from mmhuman3d.core.visualization.visualize_smpl import visualize_smpl_pose
from mmhuman3d.core.visualization.visualize_keypoints3d import visualize_kp3d
from mmhuman3d.data.data_structures import HumanData
from mmhuman3d.models.registrants.builder import build_registrant
from mmhuman3d.core.conventions.keypoints_mapping import KEYPOINTS_FACTORY
from mmhuman3d.utils.transforms import rotmat_to_aa
from mmhuman3d.core.conventions.keypoints_mapping.coco import COCO_KEYPOINTS
from mmhuman3d.core.conventions.keypoints_mapping.smpl import SMPL_45_KEYPOINTS

from utils.icp import icp

mmhuman3d_dir = os.path.join(pathlib.Path(__file__).parent.resolve(), '..', '..', '..', 'mmhuman3d') 

####---------------------------------------------------
MESH_COLORS = {
    'pink': np.array([197, 27, 125]),
    'light_pink': np.array([233, 163, 201]),
    'light_green': np.array([161, 215, 106]),
    'green': np.array([77, 146, 33]),
    'red': np.array([215, 48, 39]),
    'light_red': np.array([252, 146, 114]),
    'light_orange': np.array([252, 141, 89]),
    'purple': np.array([118, 42, 131]),
    'light_purple': np.array([175, 141, 195]),
    'light_blue': np.array([145, 191, 219]),
    'blue': np.array([69, 117, 180]),
    'gray': np.array([130, 130, 130]),
    'white': np.array([255, 255, 255]),
    'turkuaz': np.array([50, 134, 204]),
    'orange': np.array([205, 133, 51]),
    'light_yellow': np.array([255, 255, 224]),
}

##------------------------------------------------------------------------------------
class SMPLify:
    def __init__(self, cfg):
        self.cfg = cfg
        self.keypoint_type = 'coco' ## 17 keypoints
        self.input_type = 'keypoints3d'

        self.config_file = os.path.join(mmhuman3d_dir, 'configs', 'smplify', cfg.SMPL.CONFIG_FILE)

        self.body_model_dir = os.path.join(mmhuman3d_dir, 'data', 'body_models')

        self.device = torch.device('cuda')
        self.num_betas = 10
        self.batch_size = 1

        self.original_smplify_config = mmcv.Config.fromfile(self.config_file)
        assert self.original_smplify_config.body_model.type.lower() in ['smpl', 'smplx']
        assert self.original_smplify_config.type.lower() in ['smplify', 'smplifyx']

        return


    def build_smplify(self, human_name):
        all_human_names = self.cfg.SMPL.ARIA_NAME_LIST
        idx = all_human_names.index(human_name)
        num_epochs = self.cfg.SMPL.NUM_EPOCHS_LIST[idx]
        stage1_iters = self.cfg.SMPL.STAGE1_ITERS_LIST[idx]
        stage2_iters = self.cfg.SMPL.STAGE2_ITERS_LIST[idx]
        stage3_iters = self.cfg.SMPL.STAGE3_ITERS_LIST[idx]
        gender = self.cfg.SMPL.ARIA_GENDER_LIST[idx]

        # create body model
        self.body_model_config = dict(
                type=self.original_smplify_config.body_model.type.lower(),
                gender=gender,
                num_betas=self.num_betas,
                model_path=self.body_model_dir,
                batch_size=self.batch_size,
            )

        ##---------build-------------
        smplify_config = self.original_smplify_config.copy()
        smplify_config.update(dict(
                            verbose=self.cfg.SMPL.VERBOSE,
                            body_model=self.body_model_config,
                            use_one_betas_per_video=True,
                            num_epochs=num_epochs))
        smplify_config['stages'][0]['num_iter'] = stage1_iters
        smplify_config['stages'][1]['num_iter'] = stage2_iters
        smplify_config['stages'][2]['num_iter'] = stage3_iters

        smplify = build_registrant(dict(smplify_config))

        return smplify, smplify_config

    def get_smpl_trajectory(self, human_name, poses3d_trajectory, initial_smpl_trajectory):
        """
        all_poses3d_trajectory is time x 17 x 4
        initial_smpl_trajectory is time x smpl_info --> nested dicts
        """
        assert(poses3d_trajectory.shape[0] == len(initial_smpl_trajectory.keys()))
        assert(poses3d_trajectory.shape[1] == 17)
        assert(poses3d_trajectory.shape[2] == 4)

        self.smplify, self.smplify_config = self.build_smplify(human_name)

        total_time = poses3d_trajectory.shape[0]
        keypoints_src = poses3d_trajectory[:, :17, :3] ## take the first 17 keypoints, T x 17 x 3

        if human_name not in self.cfg.SMPL.JOINT_WEIGHT_OVERRIDE.ARIA_NAME_LIST:
            keypoints, mask =  convert_kps(
                                keypoints_src,
                                mask=None,
                                src=self.keypoint_type,
                                dst=self.smplify_config.body_model['keypoint_dst']
                            )
        else:
            idx = self.cfg.SMPL.JOINT_WEIGHT_OVERRIDE.ARIA_NAME_LIST.index(human_name)
            override_joint_names = self.cfg.SMPL.JOINT_WEIGHT_OVERRIDE.JOINT_NAMES[idx]
            override_joint_weights = self.cfg.SMPL.JOINT_WEIGHT_OVERRIDE.JOINT_WEIGHTS[idx]

            src_mask = np.ones(17)

            ## update the src_mask
            for joint_name, joint_weight in zip(override_joint_names, override_joint_weights):
                joint_idx = COCO_KEYPOINTS.index(joint_name)
                src_mask[joint_idx] = joint_weight

            keypoints, mask =  convert_kps(
                                keypoints_src,
                                mask=src_mask,
                                src=self.keypoint_type,
                                dst=self.smplify_config.body_model['keypoint_dst']
                            )

        keypoints_conf = np.repeat(mask[None], keypoints.shape[0], axis=0)

        ##---------------beta----------------------
        # dict_keys(['betas', 'rotmat', 'pose', 'cam_full', 'vertices', 'joints', 'focal_length', 'init_transl', 'init_global_orient', 'transformed_vertices', 'bbox', 'best_view'])
        beta = []
        for t in initial_smpl_trajectory.keys():
            beta.append(initial_smpl_trajectory[t]['betas'].reshape(1, -1)) ## 1 x 10
        beta = np.concatenate(beta, axis=0) ## t x 10

        ##---------------init_body_pose----------------------
        init_body_pose = []
        for t in initial_smpl_trajectory.keys():
            body_pose = initial_smpl_trajectory[t]['pose'].reshape(-1, 3) ## 24 x 3
            body_pose = body_pose[1:] ## drop the global pose
            body_pose = body_pose.reshape(1, -1) ## 1 x 69
            init_body_pose.append(body_pose) 
        init_body_pose = np.concatenate(init_body_pose, axis=0) ## t x 69

        ##-----------------init_transl-------------------
        init_transl = []
        for t in initial_smpl_trajectory.keys():
            init_transl.append(initial_smpl_trajectory[t]['init_transl'].reshape(1, -1)) ## 1 x 3
        init_transl = np.concatenate(init_transl, axis=0) ## t x 3

        ##-----------------init_global_orient-------------------
        init_global_orient = []
        for t in initial_smpl_trajectory.keys():
            init_global_orient.append(initial_smpl_trajectory[t]['init_global_orient'].reshape(1, -1)) ## 1 x 3
        init_global_orient = np.concatenate(init_global_orient, axis=0) ## t x 3

        ##-------------------------------------------------------------------------------
        keypoints = torch.tensor(keypoints, dtype=torch.float32, device=self.device)
        keypoints_conf = torch.tensor(keypoints_conf, dtype=torch.float32, device=self.device)

        init_beta = torch.tensor(beta, dtype=torch.float32, device=self.device)
        init_body_pose = torch.tensor(init_body_pose, dtype=torch.float32, device=self.device)
        init_transl = torch.tensor(init_transl, dtype=torch.float32, device=self.device)
        init_global_orient = torch.tensor(init_global_orient, dtype=torch.float32, device=self.device)

        ## initial with the CLIFF predictions, throw away the global information
        human_data = dict(
                            human_name=human_name, \
                            keypoints3d=keypoints, \
                            keypoints3d_conf=keypoints_conf, \
                            init_betas=init_beta, \
                            init_body_pose=init_body_pose, \
                            init_transl=init_transl, \
                            init_global_orient=init_global_orient,\
                        )

        # run SMPLify(X)
        smplify_output, smplify_output_per_epoch = self.smplify(**human_data, return_joints=True, return_verts=True)

        ret = {t:{} for t in range(total_time)}

        for key in smplify_output.keys():
            for t in range(total_time):
                if key == 'epoch_loss':
                    ret[t][key] = smplify_output[key]
                else:
                    ret[t][key] = smplify_output[key][t].cpu().numpy() 

        return ret
       
