.PHONY : all

all :
	fasm boot.asm win_7
img : all
	dd if=/dev/zero of=/tmp/fd0 bs=1024 count=1440
	dd if=win_7 of=/tmp/fd0 conv=notrunc

q : img
	qemu -fda /tmp/fd0
