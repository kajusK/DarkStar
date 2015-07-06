;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
;                                 PIC 16F648
;                         ------------\/-----------
;                        -|Vcc                 VSS|-
;               LED1 PWM -|RA5       RA0/AN0/C1IN+|- LED1 level set
;                    BT2 -|RA4/AN3         RA1/AN1|- LED1 sense
;                    BT1 -|RA3/MCLR      RA2/C1OUT|- LED1 FET
;             LED ground -|RC5       RC0/AN4/C2IN+|- LED2 sense
;	        LED2 FET -|RC4/C2OUT       RC1/AN5|- LED2 level set
;        voltage measure -|RC3/AN7         RC2/AN6|- LED2 PWM
;                         -------------------------
;------------------------------
; BT1 wakes pic from sleep
;**********************************************************************
	LIST P=16F684, R=DEC
	include p16f684.inc
	errorlevel -302

	__CONFIG _CP_OFF & _CPD_OFF & _BOREN_ON & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _FCMEN_OFF & _IESO_OFF

	include headlamp.inc

;**********************************************************************
; Beginning of the program execution
;**********************************************************************
	org 0x0
	goto init

	org 0x4
	goto interrupt

;######################################################################
;interrupt
;######################################################################
interrupt
;save registers values
	movwf	w_sav

	swapf	status, w
	movwf	stat_sav

	movf	fsr, w
	movwf	fsr_sav

	clrf	status
;-----------------------------
	btfsc	intcon, t0if
	goto	int_systime
	btfsc	intcon, raif
	goto	int_raif

;ERROR, some other interrupt enabled, fix and return:
	movlw	b'01100000'
	movwf	intcon
	goto	int_end

;wake up from sleep, just return
int_raif
	movf	porta, f	;update latches
	bcf	intcon, raif
	goto	int_end

;simple timer for system tasks
int_systime
	goto	int_pwm

;-----------------------------
; Double channel 1024Hz pwm, uses up to 50% of system time
;
; Generates shorter part of the pulse:
;	duty <= 50% : generate high part of pulse
;	duty >= 50% : generate low part of pulse
;
;first, set initial pwm pins values, wait for the length of the shorter
;pulse, then set new pin values and wait for the rest of the time of the longer
;one, finally set the last value
;
; Timing and output settings are determined by preset variables
;	pwm_val1,2 contains timing of the two parts
;	pwm_data pin states in all three parts of pwm execution
;
; Times:
;	9	int start
;	4	set led1
;	3	set led2
;	2	preloop
;	3*pwm_val1+2	loop1
;	3	set led1
;	3	set led2
;	2	preloop
;	3*pwm_val2+2	loop2
;	3	set led1
;	3	set led2
;	8	int end
;
; Pulse lengths (low or high part, depends on pwm_mode)
;	average 13+3*pwm_valX
;	shortest 6+3*pwm_valX
;	longest	23+3*pwm_val1 + 3*pwm_val2
;
; Because of lowest time consumption code, 100% is not possible - 9us space will exist
int_pwm
	bcf	intcon, t0if		;clear
	PWM_SET pstart1, pstart2	;set leds to initial state

;wait for shorter pulse to finish
	movf	pwm_time1, f
	movwf	pwm_count
int_pwm1
	decfsz	pwm_count, f
	goto	int_pwm1

	PWM_SET	pmiddle1, pmiddle2

;wait for the rest of the time for the second pulse end
	movf	pwm_time2, f
	movwf	pwm_count
int_pwm2
	decfsz	pwm_count, f
	goto	int_pwm2

	PWM_SET	pend1, pend2
;-----------------------------
;restore register values
int_end
	movf	fsr_sav, w
	movwf	fsr

	swapf	stat_sav, w
	movwf	status

	swapf	w_sav, f
	swapf	w_sav, w
;...............................
	retfie

;######################################################################
;Init
;######################################################################
init
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
	movwf	trisc

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
;tmr0
;bank1
	bsf	status, rp0
	movlw	b'11010001'	;timer0 incremented by internal clock, 1:4 prescaler
	movwf	option_reg
;bank0
	bcf	status, rp0
	clrf	tmr0
;--------------interrupt---------------
	movlw	b'01100000'	;tmr0 interrupt enabled, global disabled for now
	movwf	intcon
;bank1
	bsf	status, rp0
	movlw	0x08
	movlw	ioca		;interrupt on bt1 change
;bank0
	bcf	status, rp0




;turn on the led
	bcf	ledv
	bsf	pwm1
;measure battery voltage
;if low, wait for second, turn off the led and go to sleep

;wait for button to be released - pic turned on by pressing the button
bt_start_rel
	btfss	bt1
	goto	bt_start_rel

;restore previous state
;read data from eeprom, 0xAA, led1, led2, mode
;no data in eprom, set default mode


;enable interrupt -> pwm
	bsf	intcon, gie
;######################################################################
;main
;######################################################################
	include actions.asm
;before sleep
;	disable comparators
		;movlw	CMP_OFF
		;movwf	cmcon0
;	AD is disabled automatically
;


;tasks
;monitor battery voltage and adjust the constant

;generates pwm and run tasks
	;pwm on
loop

	goto	loop
;----------------------------------------------------------------------
	end
