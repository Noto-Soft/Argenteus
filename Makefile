.PHONY: default

default:
	chmod +x ./padup
	nasm -o boot.bin -f bin boot.asm
	nasm -o kernel.bin -f bin kernel.asm
	nasm -o testmem.com -f bin testmem.asm
	nasm -o command.com -f bin command.asm
	./padup boot.bin kernel.bin LORE.TXT testmem.com command.com pits.txt FALSE.txt afile.txt aldis.txt > os.img
	nasm -o disk2header.bin -f bin disk/headingsectors.asm
	nasm -o program.com -f bin disk/program.asm
	./padup disk2header.bin test.txt program.com > disk2.img
	truncate -s 1440k os.img
	qemu-system-i386 -drive file="os.img",if=floppy,format=raw -drive file="disk2.img",if=floppy,format=raw