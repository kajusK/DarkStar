NAME=headlamp
MCU=PIC16F616

${NAME}.hex: *.asm *.inc
	gpasm -i ${NAME}.asm

program:
	pk2cmd -P${MCU} -F ${NAME}.hex -M -JN -X -L 16

verify:
	pk2cmd -P${MCU} -F ${NAME}.hex -Y

clean:
	rm *.hex *.lst *.cod

