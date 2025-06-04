.PHONY: default
default:
	chmod +x ./padup
	nasm -o boot.bin -f bin boot.asm
	nasm -o kernel.bin -f bin kernel.asm
	nasm -o testmem.com -f bin testmem.asm
	nasm -o command.com -f bin command.asm
	./padup boot.bin kernel.bin LORE.TXT testmem.com command.com > os.img
	nasm -o disk/disk2header.bin -f bin disk/headingsectors.asm
	nasm -o disk/program.com -f bin disk/program.asm
	nasm -o disk/typer.com -f bin disk/typer.asm
	./padup disk/disk2header.bin disk/test.txt disk/program.com disk/typer.com > disk2.img
	truncate -s 1440k os.img
	qemu-system-i386 -drive file="os.img",if=floppy,format=raw -drive file="disk2.img",if=floppy,format=raw