source "$PWD/emsdk/emsdk_env.sh"

cd riscv-gnu-toolchain
if [ ! -f riscv-binutils/bfd/doc/chew ]; then
  cp -r riscv-binutils riscv-binutils-js
  cd riscv-binutils
  ./configure --prefix $PWD/../../utils --target=riscv64-unknown-elf --disable-nls
  make
  make install
  cd ..
fi

PROFILING_OPTS=

# Uncomment to gain stack traces
#PROFILING_OPTS=-g --profiling-funcs 

cd riscv-binutils-js
emconfigure ./configure --target=riscv64-unknown-elf --disable-nls
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1"
cp ../riscv-binutils/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-binutils/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1"
cp ../riscv-binutils/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-binutils/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
emmake make all-ld CFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1"
cd ../..

rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/getopt*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/fnmatch*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/libiberty/strncmp*.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/intl/intl-compat.o
rm -f riscv-gnu-toolchain/riscv-binutils-js/ld/*testplug*.o

# This gets a _memset not defined in the emscripten implementation of the get_rusage syscall.
# There is no mechanism for emitting the _memset function in emscripten. Needs to be a
# js dep, but I can't figure out how to do that.

mkdir -p assets/js/binutils

# Assembler (as)
emcc -v -O2 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libctf -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/gas -name \*.o` -o assets/js/binutils/riscv64-unknown-elf-as-bare.js -s WASM=1 -s ASSERTIONS=1 -lworkerfs.js -lfs.js -s NO_EXIT_RUNTIME=0 -s ALLOW_MEMORY_GROWTH=1 ${PROFILING_OPTS}

# Linker (ld)
emcc -v -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libctf -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` `ls riscv-gnu-toolchain/riscv-binutils-js/ld/*.o` -o assets/js/binutils/riscv64-unknown-elf-ld-bare.js -s WASM=1 -s ASSERTIONS=1 -lworkerfs.js -lfs.js -s NO_EXIT_RUNTIME=0 -s ALLOW_MEMORY_GROWTH=1 ${PROFILING_OPTS}

# Disassembler (objdump)
emcc -v -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libctf -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` riscv-gnu-toolchain/riscv-binutils-js/binutils/objdump.o riscv-gnu-toolchain/riscv-binutils-js/binutils/{bucomm,dwarf,prdbg,debug,elfcomm,version,rddbg,filemode,stabs,rdcoff}.o -o assets/js/binutils/riscv64-unknown-elf-objdump-bare.js -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=0 -lworkerfs.js -s ASSERTIONS=1 -lworkerfs.js -lfs.js ${PROFILING_OPTS}

# Metadata-reader (readelf)
emcc -v -O3 `find riscv-gnu-toolchain/riscv-binutils-js/intl -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/zlib -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/opcodes -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libiberty -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/libctf -name \*.o` `find riscv-gnu-toolchain/riscv-binutils-js/bfd -name \*.o` riscv-gnu-toolchain/riscv-binutils-js/binutils/readelf.o riscv-gnu-toolchain/riscv-binutils-js/binutils/{unwind-ia64,dwarf,prdbg,debug,elfcomm,version,rddbg,filemode,stabs,rdcoff}.o -o assets/js/binutils/riscv64-unknown-elf-readelf-bare.js -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=0 -lworkerfs.js -lfs.js -s ASSERTIONS=1 ${PROFILING_OPTS}

# Prepend and append the shims
cat lib/pre-worker.js assets/js/binutils/riscv64-unknown-elf-as-bare.js lib/post-worker.js > assets/js/binutils/riscv64-unknown-elf-as.js
cat lib/pre-worker.js assets/js/binutils/riscv64-unknown-elf-ld-bare.js lib/post-worker.js > assets/js/binutils/riscv64-unknown-elf-ld.js
cat lib/pre-worker.js assets/js/binutils/riscv64-unknown-elf-objdump-bare.js lib/post-worker.js > assets/js/binutils/riscv64-unknown-elf-objdump.js
cat lib/pre-worker.js assets/js/binutils/riscv64-unknown-elf-readelf-bare.js lib/post-worker.js > assets/js/binutils/riscv64-unknown-elf-readelf.js
