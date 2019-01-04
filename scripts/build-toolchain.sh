cd riscv-gnu-toolchain
if [ ! -f riscv-binutils/bfd/doc/chew ]; then
  cp -r riscv-binutils riscv-binutils-js
  cd riscv-binutils
  ./configure --prefix $PWD/../../utils --target=riscv64-unknown-elf
  make
  make install
  cd ..
fi
cd riscv-binutils-js
emconfigure ./configure --target=riscv64-unknown-elf
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32"
cp ../riscv-binutils/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-binutils/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32"
cp ../riscv-binutils/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-binutils/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32"
cd ../..

rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/getopt*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/fnmatch*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/strncmp*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/intl/intl-compat.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/ld/*testplug*.o
emcc -v --post-js lib/post-worker.js -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/gas -name \*.o` -o public/js/riscv64-unknown-elf-as.js -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s "BINARYEN_METHOD='native-wasm'" -s NO_EXIT_RUNTIME=0
emcc -v --post-js lib/post-worker.js -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` `ls riscv-gnu-toolchain/riscv-binutils-js/ld/*.o` -o public/js/riscv64-unknown-elf-ld.js -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s "BINARYEN_METHOD='native-wasm'" -s NO_EXIT_RUNTIME=0
emcc -v --post-js lib/post-worker.js -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` riscv-gnu-toolchain/riscv-binutils-js/binutils/objdump.o riscv-gnu-toolchain/riscv-binutils-js/binutils/{bucomm,dwarf,prdbg,debug,elfcomm,version,rddbg,filemode,stabs,rdcoff}.o -o public/js/riscv64-unknown-elf-objdump.js -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s "BINARYEN_METHOD='native-wasm'" -s NO_EXIT_RUNTIME=0
