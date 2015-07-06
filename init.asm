;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; init.asm
;**********************************************************************

;---------------oscillator-------------
;bank 1
	bsf	status, rp0
	movlw	b'01100000'	;4MHz
;---------------set ports--------------
;bank 0
	bcf	status, rp0
;clear ports
	movlw	0xff
	movwf	porta
	movwf	portc
;bank1
	bsf	status, rp0
;comparators outputs in input state for now
	movlw	b'11011111'
	movwf	trisa
	movlw	b'11011011'
	movwf	trisb

	clrf	wpua		;disable pull ups
;----------------AD--------------------
	movlw	0x80
	movwf	ansel		;only RC3 is analog input
;bank0
	movlw	b'00011101'	;left justified, vdd reference,AD module on
	movwf	adcon0
;------------comparator----------------
	movlw	CMP_ON
	movwf	cmcon0		;c1 inverted, two independent comparators
;---------------timers-----------------
;timer 0
	bsf	option_reg, t0cs	;incremented by pulses on T0CKI
;bank 0
	bcf	status, rp0
	clrf	tmr0

;--------------interrupt----------------
;bank 1
	bsf	status, rp0

	movlw	0x20
	movwf	pie1		;enable UART_RX interrupt

	movlw	0x70
	movwf	intcon		;enable int on portb, 0 and timer 0
;---------------serial-----------------
	movlw	BAUDRATE
	movwf	spbrg		;set baudrate
	movlw	0x24
	movwf	txsta		;high speed, 8 bit, asynchronous mode
;bank 0
	bcf	status, rp0
	movlw	0x90
	movwf	rcsta
