#!/bin/bash

python -m venv venv
source venv/bin/activate
mkdir -p pip-cache pip
export PIP_CACHE_DIR="$PWD/pip-cache"
export TMPDIR="$PWD/pip-tmp"

export DDFACET_BRANCH=MassiveMerge_PR_MergeSSD3_NancepMPI
export KMS_BRANCH=APP_Predict_Compress_PolSmooth_HybridSM_OpFit_MultiField_MPI_MultiChain
export DDFPIPE_BRANCH=Hackaton_mpipool_test_NancepMPI

pip install --upgrade pip
git clone -b $DDFACET_BRANCH git@github.com:cyriltasse/DDFacet.git
pip install -e ./DDFacet[mpi-support]
git clone -b $KMS_BRANCH git@github.com:cyriltasse/killMS.git
pip install -e ./killMS
git clone -b $DDFPIPE_BRANCH git@github.com:mhardcastle/ddf-pipeline.git

git clone -b NoBoost git@github.com:cyriltasse/LOFARBeam.git
cd LOFARBeam
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV ..
make install
cd ../..

pip install future
pip install sshtunnel
pip install pymysql
pip install pyregion

