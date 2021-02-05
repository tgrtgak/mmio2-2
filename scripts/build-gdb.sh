# Activate our emscripten environment
source "$PWD/emsdk/emsdk_env.sh"

# Go to the toolchain path
cd riscv-gnu-toolchain

# Build a native gdb
# The JS compilation needs some native executables to do a proper cross-compile.
if [ ! -f riscv-gdb/bfd/doc/chew ]; then
  cp -r riscv-gdb riscv-gdb-js
  cd riscv-gdb
  ./configure --prefix $PWD/../../utils --target=riscv64-unknown-elf --disable-nls
  make
  make install
  cd ..
fi

PROFILING_OPTS=
# Uncomment to gain stack traces
#PROFILING_OPTS=-g --profiling-funcs 

# The different flags we need to compile
CFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1" 
CPPFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1" 
LDFLAGS="-Wl,--no-check-features"

# Go into the gdb build directory for our JavaScript version
cd riscv-gdb-js

# Patch
echo ""
echo "Patching"
patch -p1 < ../../patches/gdb-emscripten.patch

# Configure
echo ""
echo "Configuring"
emconfigure ./configure --target=riscv64-unknown-elf --disable-nls --disable-shared --disable-threads

echo ""
echo "Building"
emmake make CXX=emcc CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"
cp ../riscv-gdb/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-gdb/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
cp ../riscv-gdb/sim/riscv/gentmap sim/riscv/gentmap
chmod +x sim/riscv/gentmap
emmake make CXX=emcc CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"
cp ../riscv-gdb/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-gdb/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
cp ../riscv-gdb/sim/riscv/gentmap sim/riscv/gentmap
chmod +x sim/riscv/gentmap
emmake make CXX=emcc CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"
cp ../riscv-gdb/bfd/doc/chew bfd/doc/chew
chmod +x bfd/doc/chew
cp ../riscv-gdb/binutils/sysinfo binutils/sysinfo
chmod +x binutils/sysinfo
cp ../riscv-gdb/sim/riscv/gentmap sim/riscv/gentmap
chmod +x sim/riscv/gentmap
emmake make CXX=emcc CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"
cd ../..

rm -f riscv-gnu-toolchain/riscv-gdb-js/libiberty/getopt*.o
rm -f riscv-gnu-toolchain/riscv-gdb-js/libiberty/fnmatch*.o
rm -f riscv-gnu-toolchain/riscv-gdb-js/libiberty/strncmp*.o
rm -f riscv-gnu-toolchain/riscv-gdb-js/intl/intl-compat.o
rm -f riscv-gnu-toolchain/riscv-gdb-js/ld/*testplug*.o

# This gets a _memset not defined in the emscripten implementation of the get_rusage syscall.
# There is no mechanism for emitting the _memset function in emscripten. Needs to be a
# js dep, but I can't figure out how to do that.
