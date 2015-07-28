NAME=headlamp
MCU=PIC16F616

${NAME}.hex: *.asm *.inc
	gpasm -i ${NAME}.asm

burn:
	pk2cmd -P${MCU} -F ${NAME}.hex -M -JN -X -L 16

remote:
	scp ${NAME}.hex reprap@192.168.1.254:/home/reprap/pic/
	ssh reprap@192.168.1.254 "cd pic; pk2cmd -P ${MCU} -F ${NAME}.hex -M -JN -X -L 16"

verify:
	pk2cmd -P${MCU} -F ${NAME}.hex -Y

clean:
	rm *.hex *.lst *.cod

