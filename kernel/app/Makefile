RISCV_BIN=${PWD}/../../utils/bin/

all: test.elf test.ehx

dump: test.ehx

test.o: test.s
	${RISCV_BIN}riscv64-unknown-elf-as test.s -o test.o -g

test.elf: test.o
	${RISCV_BIN}riscv64-unknown-elf-ld test.o -o test.elf -g

test.ehx:
	${RISCV_BIN}riscv64-unknown-elf-objdump -D -m riscv test.elf > test.ehx
