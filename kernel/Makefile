RISCV_BIN=${PWD}/../utils/bin/
SRC=$(wildcard *.s)
OBJ=$(SRC:.s=.o)

kernel.bin: kernel.elf
	${RISCV_BIN}riscv64-unknown-elf-objcopy -O binary kernel.elf kernel.bin
	mkdir -p ../assets/kernel
	cp kernel.bin ../assets/kernel/kernel.bin

kernel.elf: ${OBJ} linker.ld
	${RISCV_BIN}riscv64-unknown-elf-ld -o kernel.elf -T linker.ld ${OBJ}

%.o: %.s const.s util.s
	${RISCV_BIN}riscv64-unknown-elf-as $< -o $@

all: kernel.bin kernel.hex

dump: kernel.hex

kernel.hex: kernel.bin
	${RISCV_BIN}riscv64-unknown-elf-objdump -D -m riscv kernel.elf > kernel.ehx
	${RISCV_BIN}riscv64-unknown-elf-objdump -D -b binary -m riscv kernel.bin > kernel.hex

clean:
	rm -f *.o *.bin *.elf *.hex *.ehx
