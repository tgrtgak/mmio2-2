#!/bin/bash

source "$PWD/emsdk/emsdk_env.sh"

if [ ! -f assets/js/riscv64-unknown-elf-as.wasm ] || [ ! -f assets/js/riscv64-unknown-elf-ld.wasm ] || [ ! -f assets/js/riscv64-unknown-elf-objdump.wasm ] || [ ! -f assets/js/riscv64-unknown-elf-readelf.wasm ]; then
  bash ./scripts/build-toolchain.sh
else
  echo "Toolchain seems to exist. Remove assets/js/riscv64-unknown-elf-*.wasm to rebuild."
fi

if [ ! -d assets/js/tinyemu ]; then
  bash ./scripts/build-tinyemu.sh
else
  echo "TinyEMU seems to exist. Remove assets/js/tinyemu to rebuild."
fi

# Build the kernel
cd kernel
make
cd ..

npm run build
