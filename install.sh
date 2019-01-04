TINYEMU_URL=https://bellard.org/tinyemu/tinyemu-2018-09-23.tar.gz

if [ ! -d public/js/ace-builds ]; then
  git clone https://github.com/ajaxorg/ace-builds public/js/ace-builds
else
  echo "ace-builds already exists. delete the public/js/ace-builds directory to reinstall"
fi

if [ lib/mode-assembly_riscv.js -nt public/js/ace-builds/src-noconflict/mode-assembly_riscv.js ]; then
  cp lib/mode-assembly_riscv.js public/js/ace-builds/src-noconflict/.
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

TINYEMU_TAR=$(basename ${TINYEMU_URL})

if [ ! -f "${TINYEMU_TAR}" ]; then
  wget ${TINYEMU_URL}
  tar xvf ${TINYEMU_TAR}
fi
