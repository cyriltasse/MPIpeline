#!/usr/bin/env bash
set -euf -o pipefail
set -x

# install UV
export PATH=$HOME/.local/bin:$PATH
if ! command -v uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

#export DDFACET_BRANCH=MassiveMerge_PR_MergeSSD3_NancepMPI
#export KMS_BRANCH=APP_Predict_Compress_PolSmooth_HybridSM_OpFit_MultiField_MPI_MultiChain
#export DDFPIPE_BRANCH=Hackaton_mpipool_test_NancepMPI
git clone https://github.com/cyriltasse/DDFacet -b MassiveMerge_PR_MergeSSD3_NancepMPI  ../DDFacet || true
git clone https://github.com/cyriltasse/killMS -b APP_Predict_Compress_PolSmooth_HybridSM_OpFit_MultiField_MPI_MultiChain ../killMS || true
git clone https://github.com/dguibert/ddf-pipeline i-b Hackaton_mpipool_test_NancepMPI_Herts ../ddf-pipeline || true

if test -z "${VIRTUAL_ENV:-}"; then
    export UV_CACHE_DIR=$PWD/../uv-cache
    # create venv if not exists yet
    if ! test -d venv; then
        uv venv -p 3.10 venv
    fi
    # load venv
    source venv/bin/activate
    (
    cd ../ddf-pipeline
    uv sync --extra mpi-support --frozen --active --verbose
    )
fi

test -n "$VIRTUAL_ENV" || ( echo "ERROR: load the venv first"; exit 1)
export SCRIPT_DIR=$(readlink -f $(dirname $0))

if ! test -d casacore_data; then
    (
    mkdir -p casacore_data
    cd casacore_data
    curl -O -L https://www.astron.nl/iers/WSRT_Measures.ztar
    tar -zxvf WSRT_Measures.ztar
    )
fi
export CASACORE_DATA=$PWD/casacore_data

#export LIBRARY_PATH="$VIRTUAL_ENV/lib${LIBRARY_PATH+:${LIBRARY_PATH}}"
export CFLAGS="-I$(python -c "import numpy; print(numpy.get_include())")"
python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
python_version_long=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
# -c 'import sysconfig; print(sysconfig.get_config_h_filename())'
#                                                /home_nfs/users/bguibertd/.local/share/uv/python/cpython-3.10.19-linux-x86_64-gnu/include/python3.10/pyconfig.h
#                                                /home_nfs/projects/pro_2020_ska/bguibertd/MPIpeline/venv/include/home_nfs/users/bguibertd/.local/share/uv/python/cpython-3.10.19-linux-x86_64-gnu/include/python3.1
export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:+CPLUS_INCLUDE_PATH:}$HOME/.local/share/uv/python/cpython-${python_version_long}-linux-x86_64-gnu/include/python${python_version}"
export CPLUS_INCLUDE_PATH="$VIRTUAL_ENV/include:$CPLUS_INCLUDE_PATH"

cd /dev/shm
mkdir -p sources
cd sources

false && (
git clone https://github.com/sailfishos-mirror/readline.git || true
cd readline/
./configure --prefix=$VIRTUAL_ENV
make -j $(nproc)
make install
)


true && (
    curl -O -L -C- https://archives.boost.io/release/1.74.0/source/boost_1_74_0.tar.gz
    if ! test -d boost_1_74_0; then
        tar -zxvf boost_1_74_0.tar.gz 
        ( cd boost_1_74_0
          patch -p1 -i $SCRIPT_DIR/boost-with-python-3.10.patch
        )
    fi
    cd boost_1_74_0/
    ./bootstrap.sh --prefix=$VIRTUAL_ENV --with-libraries=all --with-python=$(command -v python)  variant=release
    ./b2 variant=release threading=multi link=shared runtime-link=shared install
)

true && (
git clone https://github.com/healpy/cfitsio.git || true
cd cfitsio/
./configure --prefix=$VIRTUAL_ENV
make -j $(nproc)
make install
)

true && (
#    curl -O -L -C- ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-8.4.tar.bz2
    curl -O -L -C- https://ftp.eso.org/pub/dfs/pipelines/libraries/wcslib/wcslib-8.4.tar.bz2
    if ! test -d wcslib-8.4; then
        tar xvf wcslib-8.4.tar.bz2
    fi
    cd wcslib-8.4
    ./configure --prefix=$VIRTUAL_ENV
    make -j $(nproc)
    make install
)
    

true && (
    curl -O -L -C- https://fftw.org/fftw-3.3.10.tar.gz
    if ! test -d fftw-3.3.10; then
        tar xvf fftw-3.3.10.tar.gz
    fi
    cd fftw-3.3.10
    CFLAGS=-fPIC ./configure --prefix=$VIRTUAL_ENV --enable-threads
    make -j $(nproc)
    make install

    CFLAGS=-fPIC ./configure --prefix=$VIRTUAL_ENV --enable-float --enable-threads
    make -j $(nproc)
    make install
)

true && (
git clone -b v0.3.30 https://github.com/OpenMathLib/OpenBLAS || true
cd OpenBLAS/
make -j $(nproc)
make install PREFIX=$VIRTUAL_ENV
)

true && (
git clone https://github.com/casacore/casacore.git || true
cd casacore/
git checkout v3.7.1
patch -p1 -i $SCRIPT_DIR/fix-datatype-constexpr.patch || true
rm -rf cbuild
mkdir -p cbuild
cd cbuild
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV -DBUILD_PYTHON=OFF -DBUILD_PYTHON3=ON -DBUILD_TESTING=OFF -DDATA_DIR=/home/$USER/casacore_data -DBOOST_ROOT=$VIRTUAL_ENV -Dboost_python310_DIR=$VIRTUAL_ENV -DCMAKE_VERBOSE_MAKEFILE=ON ..
make -j $(nproc)
make install
)

export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib${LD_LIBRARY_PATH+:${LD_LIBRARY_PATH}}"
true && (
    cd $SCRIPT_DIR
    git clone -b v3.7.1 https://github.com/casacore/python-casacore.git || true
    ( cd python-casacore; git checkout v3.7.1 )
    CMAKE_ARGS="-DCASACORE_ROOT_DIR=$VIRTUAL_ENV -DCFITSIO_INCLUDE_DIR=$VIRTUAL_ENV/include -DCFITSIO_LIBRARY=$VIRTUAL_ENV/lib -DWCSLIB_INCLUDE_DIR=$VIRTUAL_ENV/include -DWCSLIB_LIBRARY=$VIRTUAL_ENV/lib -DCMAKE_CXX_FLAGS=-std=c++11" uv pip install -e ./python-casacore
)


true && (
git clone -b NoBoost https://github.com/cyriltasse/LOFARBeam.git || true
mkdir -p LOFARBeam/build
cd LOFARBeam/build
cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV ..
make -j $(nproc)
make install
)

tree && (
    git clone https://github.com/aroffringa/dysco.git || true
     cd dysco
     mkdir build && cd build
     cmake -DCMAKE_INSTALL_PREFIX=$VIRTUAL_ENV \
       -DPYTHON_EXECUTABLE=$VIRTUAL_ENV/bin/python \
       -DPYTHON_INSTALL_DIR=$VIRTUAL_ENV/lib/python3.10/site-packages \
       ..
     make -j $(nproc)
     make install
)
