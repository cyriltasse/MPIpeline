#!/bin/bash

PYTHON=""

for cmd in python3.10 python3.9 python3.8 python3; do
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$("$cmd" - <<'EOF'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)
        major=${version%%.*}
        minor=${version##*.}

        if [ "$major" -eq 3 ] && [ "$minor" -ge 8 ] && [ "$minor" -lt 11 ]; then
            PYTHON="$cmd"
            break
        fi
    fi
done

echo using $PYTHON


$PYTHON -m venv venv
source venv/bin/activate

module load openmpi-4.1.6

mkdir -p pip-cache pip
export PIP_CACHE_DIR="$PWD/pip-cache"
export TMPDIR="$PWD/pip-tmp"
pip install --upgrade pip

pip install numpy==1.22.4
export CFLAGS="-I$(python - <<'EOF'
import numpy
print(numpy.get_include())
EOF
)"
pip install sharedarray==3.2.1

pip install python-casacore

export DDFACET_BRANCH=MassiveMerge_PR_MergeSSD3_NancepMPI
export KMS_BRANCH=APP_Predict_Compress_PolSmooth_HybridSM_OpFit_MultiField_MPI_MultiChain
export DDFPIPE_BRANCH=Hackaton_mpipool_test_NancepMPI

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
pip install ipython

