cd ../tinyemu
make -s
cd ../kernel
../tinyemu/temu -ctrlc basic-riscv64.cfg
