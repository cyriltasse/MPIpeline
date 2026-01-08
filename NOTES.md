
cd $USER
mkdir -p casacore_data
cd casacore_data
wget https://www.astron.nl/iers/WSRT_Measures.ztar
tar -zxvf WSRT_Measures.ztar


python3.9 -m venv venv
source venv/bin/activate
export VE_FOLDER=$PWD/venv

mkdir -p pip-cache pip-tmp
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

mkdir sources
cd $VE_FOLDER/../sources
git clone https://github.com/sailfishos-mirror/readline.git
cd readline/
./configure --prefix=$VE_FOLDER
make -j 20
make install


cd $VE_FOLDER/../sources
wget https://archives.boost.io/release/1.74.0/source/boost_1_74_0.tar.gz
tar -zxvf boost_1_74_0.tar.gz 
cd boost_1_74_0/
./bootstrap.sh --prefix=$VE_FOLDER --with-python=/usr/bin/python3.9  variant=release
./b2 --with-python variant=release threading=multi link=shared runtime-link=shared install

cd $VE_FOLDER/../sources
git clone https://github.com/healpy/cfitsio.git
cd cfitsio/
./configure --prefix=$VE_FOLDER
make -j 20
make install

cd $VE_FOLDER/../sources
git clone https://github.com/casacore/casacore.git
cd casacore/
git checkout v3.4.0
mkdir cbuild
cd cbuild
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV -DBUILD_PYTHON=OFF -DBUILD_PYTHON3=ON -DREADLINE_LIBRARY=/usr/lib64/libreadline.so.6 -DNCURSES_LIBRARY=/usr/lib64/libncurses.so.6 -DBUILD_TESTING=OFF -DDATA_DIR=/home/$USER/casacore_data -DBOOST_ROOT=$VIRTUAL_ENV ..
make -j 20
make install

cd $VE_FOLDER/../sources
git clone -b v3.5.2 https://github.com/casacore/python-casacore.git
CASACORE_DATA=/home/$USER/casacore_data CMAKE_ARGS="-DCASACORE_ROOT_DIR=$VIRTUAL_ENV -DCFITSIO_INCLUDE_DIR=$VIRTUAL_ENV/include -DCFITSIO_LIBRARY=$VIRTUAL_ENV/lib" pip install -e ./python-casacore


cd $VE_FOLDER/../sources
git clone -b NoBoost git@github.com:cyriltasse/LOFARBeam.git
mkdir -p LOFARBeam/build
cd LOFARBeam/build
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV ..
make -j 10
make install
cd ../..

cd $VE_FOLDER/../sources
export DDFACET_BRANCH=MassiveMerge_PR_MergeSSD3_NancepMPI
export KMS_BRANCH=APP_Predict_Compress_PolSmooth_HybridSM_OpFit_MultiField_MPI_MultiChain
export DDFPIPE_BRANCH=Hackaton_mpipool_test_NancepMPI

git clone -b $DDFACET_BRANCH git@github.com:cyriltasse/DDFacet.git
pip install -e ./DDFacet[mpi-support]


mpirun --prefix /soft/openmpi-4.1.6 -np 2 -x DDF_PIPELINE_CATALOGS -x DDF_LOCAL_DEV -x PATH -x VIRTUAL_ENV -x LD_LIBRARY_PATH -x PYTHONPATH -wdir /home/tasse/VE_MPI/MPIpeline -host smp5:1,smp4:1 DDF.py -h
