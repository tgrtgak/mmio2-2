source "$PWD/emsdk/emsdk_env.sh"

cd tinyemu
source ../emsdk/emsdk_env.sh
make -f Makefile.js
mkdir -p ../assets/js/tinyemu
cp js/riscvemu64* ../assets/js/tinyemu/.
cd ..
