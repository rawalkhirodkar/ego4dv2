source ~/anaconda3/etc/profile.d/conda.sh

## cd to root of the repository
cd ../..


# # ###-------------------------------------------
conda create -n mmp python=3.8 -y
conda activate mmp

# conda install pytorch torchvision torchaudio cudatoolkit=11.3 -c pytorch -y ## pytorch 1.12.0
conda install pytorch==1.11.0 torchvision==0.12.0 torchaudio==0.11.0 cudatoolkit=11.3 -c pytorch -y ### pyotrch 1.11.0
# conda install pytorch torchvision torchaudio cudatoolkit=11.6 -c pytorch -c conda-forge -y ## pytorch 1.12.0

## install mmcvfull
####https://github.com/open-mmlab/mmcv/issues/1556, do not install mmcv 1.3.18
# pip install "mmcv-full>=1.3.13,<1.3.18" -f https://download.openmmlab.com/mmcv/dist/cu111/torch1.8.2/index.html    
# pip install "mmcv-full" -f https://download.openmmlab.com/mmcv/dist/cu111/torch1.8.2/index.html    
pip install "mmcv-full" -f https://download.openmmlab.com/mmcv/dist/cu113/torch1.11.0/index.html    
# pip install "mmcv-full" -f https://download.openmmlab.com/mmcv/dist/cu116/torch1.12.1/index.html    


### install mmdet
pip install mmdet

## install mmtrack
pip install mmtrack

## install mmpose
pip install -r requirements.txt
pip install -v -e . 
pip install flask

pip install opencv-contrib-python

pip install torchgeometry mmhuman3d

pip install colour pycolmap
pip install --upgrade numpy
pip install scipy --upgrade
pip install "numpy<1.24.0" ## for mot eval

pip install yacs
pip install Rtree
pip install pyntcloud pyvista
pip install python-fcl

cd ./external/pycococreator
python setup.py install
cd ..

