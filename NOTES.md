
cd $USER
mkdir -p casacore_data
cd casacore_data
wget https://www.astron.nl/iers/WSRT_Measures.ztar
tar -zxvf WSRT_Measures.ztar

cd $VE_FOLDER/..
git clone https://github.com/casacore/casacore.git
cd casacore/
git checkout v3.4.0
mkdir cbuild
cd cbuild
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV -DBUILD_PYTHON=OFF -DBUILD_PYTHON3=ON -DBUILD_TESTING=OFF -DDATA_DIR=/home/$USER/casacore_data  ..
make -j 20
make install

cd $VE_FOLDER/..
wget https://archives.boost.io/release/1.74.0/source/boost_1_74_0.tar.gz
tar -zxvf boost_1_74_0.tar.gz 
cd boost_1_74_0/
./bootstrap.sh --prefix=$VE_FOLDER --with-python=$VE_FOLDER/bin/python
./b2 install


cd $VE_FOLDER/..
git clone https://github.com/healpy/cfitsio.git
cd cfitsio/
./configure --prefix=$VE_FOLDER
make -j 20
make install

cd $VE_FOLDER/..
git clone -b v3.5.2 https://github.com/casacore/python-casacore.git
CASACORE_DATA=/home/$USER/casacore_data CMAKE_ARGS="-DCASACORE_ROOT_DIR=$VIRTUAL_ENV -DCFITSIO_INCLUDE_DIR=$VIRTUAL_ENV/include -DCFITSIO_LIBRARY=$VIRTUAL_ENV/lib" pip install -e ./python-casacore


cd $VE_FOLDER/..
git clone -b NoBoost git@github.com:cyriltasse/LOFARBeam.git
mkdir -p LOFARBeam/build
cd LOFARBeam/build
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV ..
make -j 10
make install
cd ../..

mpirun --prefix /soft/openmpi-4.1.6 -np 2 -x DDF_PIPELINE_CATALOGS -x DDF_LOCAL_DEV -x PATH -x VIRTUAL_ENV -x LD_LIBRARY_PATH -x PYTHONPATH -wdir /home/tasse/VE_MPI/MPIpeline -host smp5:1,smp4:1 DDF.py -h
