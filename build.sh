#!/bin/bash

source "$PWD/emsdk/emsdk_env.sh"

_ROOTPATH=$PWD

if [ ! -f assets/js/binutils/riscv64-unknown-elf-as.wasm ] || [ ! -f assets/js/binutils/riscv64-unknown-elf-ld.wasm ] || [ ! -f assets/js/binutils/riscv64-unknown-elf-objdump.wasm ] || [ ! -f assets/js/binutils/riscv64-unknown-elf-readelf.wasm ]; then
  bash ./scripts/build-toolchain.sh
else
  echo "Toolchain seems to exist. Remove assets/js/binutils/riscv64-unknown-elf-*.wasm to rebuild."
fi

cd _ROOTPATH

if [ ! -f assets/js/gdb/riscv64-unknown-elf-gdb-bare.wasm ]; then
  bash ./scripts/build-gdb.sh
else
  echo "GDB seems to exist. Remove assets/js/gdb/riscv64-unknown-elf-gdb-bare.wasm to rebuild."
fi

cd _ROOTPATH

if [ ! -f assets/js/tinyemu/riscvemu64-wasm.wasm ]; then
  bash ./scripts/build-tinyemu.sh
else
  echo "TinyEMU seems to exist. Remove assets/js/tinyemu to rebuild."
fi

cd _ROOTPATH

# Build the kernel
cd kernel
make
cd ..

npm run build
