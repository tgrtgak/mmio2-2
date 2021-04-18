# Activate our emscripten environment
source "$PWD/emsdk/emsdk_env.sh"

# Go to the toolchain path
cd riscv-gnu-toolchain

# Build a native gdb
# The JS compilation needs some native executables to do a proper cross-compile.
if [ ! -f riscv-gdb/bfd/doc/chew ]; then
  cp -r riscv-gdb riscv-gdb-js
  cd riscv-gdb
  ./configure --prefix $PWD/../../utils --target=riscv64-unknown-elf --disable-nls --enable-64-bit-bfd
  make
  make install
  cd ..
fi

PROFILING_OPTS=
# Uncomment to gain stack traces
#PROFILING_OPTS=-g --profiling-funcs 

# The different flags we need to compile
CFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1 -s DISABLE_EXCEPTION_CATCHING=0 -fexceptions" 
CPPFLAGS="-DHAVE_PSIGNAL -m32 ${PROFILING_OPTS} -s ALLOW_MEMORY_GROWTH=1 -s DISABLE_EXCEPTION_CATCHING=0 -fexceptions" 
LDFLAGS="-Wl,--no-check-features -s DISABLE_EXCEPTION_CATCHING=0"

# Go into the gdb build directory for our JavaScript version
cd riscv-gdb-js

# Patch
echo ""
echo "Patching"
patch -N -p1 < ../../patches/gdb-emscripten.patch
patch -N -p1 < ../../patches/gdb-emscripten-readline.patch
patch -N -p1 < ../../patches/gdb-emscripten-fix-maint.patch
patch -N -p1 < ../../patches/gdb-emscripten-remote-jsinvoke.patch
patch -N -p1 < ../../patches/gdb-emscripten-get_tty_state.patch
patch -N -p1 < ../../patches/gdb-emscripten-removes_warnings.patch
patch -N -p1 < ../../patches/gdb-emscripten-jsinvoke_prompt.patch
patch -N -p1 < ../../patches/gdb-emscripten-no-wait-for-continue.patch

# Configure
echo ""
echo "Configuring"
emconfigure ./configure --target=riscv64-unknown-elf --disable-nls --disable-shared --disable-threads --enable-64-bit-bfd

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

echo ""
echo "Linking"
cd riscv-gnu-toolchain/riscv-gdb-js/gdb
em++ -s DISABLE_EXCEPTION_CATCHING=0 -s FORCE_FILESYSTEM=1 -s 'EXPORT_NAME="GDB"' -s "EXPORTED_FUNCTIONS=['_jsmain','_jsstep','_jsinvoke']" -s "EXPORTED_RUNTIME_METHODS=['FS','ccall','cwrap','getValue','setValue']" -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s MODULARIZE=1 -s NO_EXIT_RUNTIME=1 -lworkerfs.js -lfs.js -s ASSERTIONS=1 -g -O2   -Wl,--no-check-features -s ERROR_ON_UNDEFINED_SYMBOLS=0 -pthread  \ -g -O2   -Wl,--no-check-features  -pthread          -o ../../../assets/js/riscv64-unknown-elf-gdb-bare.js ada-exp.o ada-lang.o ada-tasks.o ada-typeprint.o ada-valprint.o ada-varobj.o addrmap.o agent.o alloc.o annotate.o arch-utils.o arch/riscv.o async-event.o auto-load.o auxv.o ax-gdb.o ax-general.o bcache.o bfd-target.o block.o blockframe.o break-catch-sig.o break-catch-syscall.o break-catch-throw.o breakpoint.o btrace.o build-id.o buildsym-legacy.o buildsym.o c-exp.o c-lang.o c-typeprint.o c-valprint.o c-varobj.o charset.o cli-out.o cli/cli-cmds.o cli/cli-decode.o cli/cli-dump.o cli/cli-interp.o cli/cli-logging.o cli/cli-option.o cli/cli-script.o cli/cli-setshow.o cli/cli-style.o cli/cli-utils.o coff-pe-read.o coffread.o compile/compile-c-support.o compile/compile-c-symbols.o compile/compile-c-types.o compile/compile-cplus-symbols.o compile/compile-cplus-types.o compile/compile-loc2c.o compile/compile-object-load.o compile/compile-object-run.o compile/compile.o complaints.o completer.o continuations.o copying.o corefile.o corelow.o cp-abi.o cp-name-parser.o cp-namespace.o cp-support.o cp-valprint.o ctfread.o d-exp.o d-lang.o d-namespace.o d-valprint.o dbxread.o dcache.o debug.o debuginfod-support.o dictionary.o disasm.o dummy-frame.o dwarf2/abbrev.o dwarf2/attribute.o dwarf2/comp-unit.o dwarf2/dwz.o dwarf2/expr.o dwarf2/frame-tailcall.o dwarf2/frame.o dwarf2/index-cache.o dwarf2/index-common.o dwarf2/index-write.o dwarf2/leb.o dwarf2/line-header.o dwarf2/loc.o dwarf2/macro.o dwarf2/read.o dwarf2/section.o dwarf2/stringify.o eval.o event-top.o exceptions.o exec.o expprint.o extension.o f-exp.o f-lang.o f-typeprint.o f-valprint.o filename-seen-cache.o filesystem.o findcmd.o findvar.o frame-base.o frame-unwind.o frame.o gcore.o gdb-demangle.o gdb_bfd.o elfread.o stap-probe.o dtrace-probe.o gdb_obstack.o gdb_regex.o gdbarch.o gdbtypes.o gnu-v2-abi.o gnu-v3-abi.o go-exp.o go-lang.o go-typeprint.o go-valprint.o guile/guile.o inf-child.o inf-loop.o infcall.o infcmd.o inferior.o inflow.o infrun.o inline-frame.o interps.o jit.o language.o linespec.o location.o m2-exp.o m2-lang.o m2-typeprint.o m2-valprint.o macrocmd.o macroexp.o macroscope.o macrotab.o main.o maint-test-options.o maint-test-settings.o maint.o mdebugread.o mem-break.o memattr.o memory-map.o memrange.o mi/mi-cmd-break.o mi/mi-cmd-catch.o mi/mi-cmd-disas.o mi/mi-cmd-env.o mi/mi-cmd-file.o mi/mi-cmd-info.o mi/mi-cmd-stack.o mi/mi-cmd-target.o mi/mi-cmd-var.o mi/mi-cmds.o mi/mi-common.o mi/mi-console.o mi/mi-getopt.o mi/mi-interp.o mi/mi-main.o mi/mi-out.o mi/mi-parse.o mi/mi-symbol-cmds.o minidebug.o minsyms.o mipsread.o namespace.o objc-lang.o objfiles.o observable.o opencl-lang.o osabi.o osdata.o p-exp.o p-lang.o p-typeprint.o p-valprint.o parse.o posix-hdep.o printcmd.o probe.o process-stratum-target.o producer.o progspace-and-thread.o progspace.o prologue-value.o psymtab.o python/python.o ravenscar-thread.o record-btrace.o record-full.o record.o regcache-dump.o regcache.o reggroups.o registry.o remote-fileio.o remote-notif.o remote-sim.o remote.o reverse.o riscv-ravenscar-thread.o riscv-tdep.o run-on-main-thread.o rust-exp.o rust-lang.o sentinel-frame.o ser-base.o ser-event.o ser-pipe.o ser-tcp.o ser-uds.o ser-unix.o serial.o skip.o solib-target.o solib.o source-cache.o source.o stabsread.o stack.o std-regs.o stub-termcap.o symfile-debug.o symfile.o symmisc.o symtab.o target-connection.o target-dcache.o target-descriptions.o target-float.o target-memory.o target.o target/waitstatus.o test-target.o thread-iter.o thread.o tid-parse.o top.o tracectf.o tracefile-tfile.o tracefile.o tracepoint.o trad-frame.o tramp-frame.o type-stack.o typeprint.o ui-file.o ui-out.o ui-style.o user-regs.o utils.o valarith.o valops.o valprint.o value.o varobj.o version.o xml-builtin.o xml-support.o xml-syscall.o xml-tdesc.o init.o           ../sim/riscv/libsim.a ../readline/readline/libreadline.a ../opcodes/libopcodes.a ../libctf/.libs/libctf.a ../bfd/libbfd.a -L./../zlib -lz ../gdbsupport/libgdbsupport.a  ../libiberty/libiberty.a ../libdecnumber/libdecnumber.a   -lm      ../gnulib/import/libgnu.a
cd ../../..

cat lib/pre-worker.js assets/js/riscv64-unknown-elf-gdb-bare.js lib/post-worker.js > assets/js/riscv64-unknown-elf-gdb.js
