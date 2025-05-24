.PHONY: default

default:
	chmod +x ./padup
	nasm -o boot.bin -f bin boot.asm
	nasm -o kernel.bin -f bin kernel.asm
	nasm -o testmem.com -f bin testmem.asm
	./padup boot.bin kernel.bin LORE.TXT testmem.com > os.img
	truncate -s 1440k os.img
	qemu-system-i386 -drive file="os.img",if=floppy,format=raw