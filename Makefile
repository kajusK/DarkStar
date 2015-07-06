NAME=headlamp
MCU=PIC16F616

${NAME}.hex: *.asm
	gpasm -i ${NAME}.asm

burn:
	pk2cmd -P${MCU} -F ${NAME}.hex -M -JN -X

verify:
	pk2cmd -P${MCU} -F ${NAME}.hex -Y

clean:
	rm *.hex *.lst *.cod

