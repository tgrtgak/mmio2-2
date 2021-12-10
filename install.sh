#!/bin/bash

echo "Emscripten"
echo "=========="

if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install 2.0.13
  ./emsdk activate 2.0.13
  cd ..
else
  echo "emscripten already exists. delete the emsdk directory to reinstall"
fi

echo ""
echo "Ace Editor"
echo "=========="

if [ ! -d assets/js/ace-builds ]; then
  git clone https://github.com/ajaxorg/ace-builds assets/js/ace-builds
else
  echo "ace-builds already exists. delete the assets/js/ace-builds directory to reinstall"
fi

echo ""
echo "Ace Editor RISC-V Highlighter"
echo "============================="

if [ lib/mode-assembly_riscv.js -nt assets/js/ace-builds/src-noconflict/mode-assembly_riscv.js ]; then
  cp lib/mode-assembly_riscv.js assets/js/ace-builds/src-noconflict/.
  echo "mode-assembly_riscv.js copied into ace-builds/src-noconflict"
else
  echo "mode-assembly_riscv.js is unchanged"
fi

echo ""
echo "GNU RISC-V Toolchain"
echo "===================="

if [ ! -d riscv-gnu-toolchain ]; then
  git clone https://github.com/riscv/riscv-gnu-toolchain
  cd riscv-gnu-toolchain
  git reset --hard d45cfc68be6ce0a2f69daf66e64fc446224b3416
  git submodule init
  git submodule update riscv-binutils
  git submodule update riscv-gdb
  cd ..
else
  echo "riscv-gnu-toolchain already exists. delete the riscv-gnu-toolchain directory to reinstall"
fi

echo ""
echo "TinyEMU"
echo "======="

if [ ! -d "tinyemu" ]; then
  git clone -b demo https://gitlab.com/erikjoy/tinyemu
else
  echo "tinyemu already exists. delete the tinyemu directory to reinstall"
fi

echo ""
echo "Dependencies"
echo "============"

bundle install
npm install
