if [ ! -d assets/js/ace-builds ]; then
  git clone https://github.com/ajaxorg/ace-builds assets/js/ace-builds
else
  echo "ace-builds already exists. delete the assets/js/ace-builds directory to reinstall"
fi

if [ lib/mode-assembly_riscv.js -nt assets/js/ace-builds/src-noconflict/mode-assembly_riscv.js ]; then
  cp lib/mode-assembly_riscv.js assets/js/ace-builds/src-noconflict/.
  echo "mode-assembly_riscv.js copied into ace-builds/src-noconflict"
else
  echo "mode-assembly_riscv.js is unchanged"
fi

if [ ! -d riscv-gnu-toolchain ]; then
  git clone https://github.com/riscv/riscv-gnu-toolchain
  cd riscv-gnu-toolchain
  git submodule init
  git submodule update riscv-binutils
else
  echo "riscv-gnu-toolchain already exists. delete the riscv-gnu-toolchain directory to reinstall"
fi

if [ ! -d "tinyemu" ]; then
  git clone https://gitlab.com/wilkie/tinyemu
else
  echo "tinyemu already exists. delete the tinyemu directory to reinstall"
fi
