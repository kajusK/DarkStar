;**********************************************************************
;Led headlamp
;PIC 16F684
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
; Using watchdog
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

;wake up from sleep when gie stayed enabled, just return
int_raif
	movf	porta, f	;update latches
	bcf	intcon, raif
	goto	int_end

;-----------------------------
;timers for system tasks
;-----------------------------
int_systime
	incf	sys_timer, f	;general timer
	goto	int_pwm

;-----------------------------
; Double channel 1024Hz pwm, uses up to 50% of system time
;
; Generates shorter part of the pulse:
;	duty <= 50% : generate high part of pulse
;	duty >= 50% : generate low part of pulse
;
; first, set initial pwm pins values, wait for the length of the shorter
; pulse, then set new pin values and wait for the rest of the time of the longer
; one, finally set the last value
;
; Timing and output settings are determined by preset variables
;	pwm_time1,2 contains timing of the two parts
;	pwm_data pin states in all three parts of pwm execution
;
; Pulse time (0 < pwm_timeX < 256):
;	firtst 8+4*pwm_time1
;	second 19+4*pwm_time1+4*pwm_time2
;
; Because of lowest time consumption code, 100% duty is not possible
;	9us space will exist (equals 99% duty)
;-----------------------------
int_pwm
	bcf	intcon, t0if		;clear
	PWM_SET pstart1, pstart2	;set leds to initial state

;wait for shorter pulse to finish
	movf	pwm_time1, w
	movwf	pwm_count
int_pwm1
	nop
	decfsz	pwm_count, f
	goto	int_pwm1

	PWM_SET	pmiddle1, pmiddle2

;wait for the rest of the time for the second pulse end
	movf	pwm_time2, w
	movwf	pwm_count
int_pwm2
	nop
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
;all the important parts :)
;######################################################################
	include pwm.asm
	include led.asm

;######################################################################
;Init
;######################################################################
init
;**************************************
; peripherals
;**************************************
;---------------oscillator-------------
;bank 1
	bsf	status, rp0
	movlw	b'01100000'	;4MHz
	movwf	osccon
;----------------ports-----------------
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
	bcf	status, rp0
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
;watchdog
	clrwdt
	bsf	wdtcon, swdten	;enable
;--------------interrupt---------------
	movlw	b'01100000'	;tmr0 interrupt enabled, global disabled for now
	movwf	intcon
;bank1
	bsf	status, rp0
	movlw	0x08
	movlw	ioca		;unmask interrupt on bt1 change
;bank0
	bcf	status, rp0


;**************************************
; variables
;**************************************
	movlw	ADC_LOW_RETRIES
	movwf	adc_low_count

	;update ADC value





;IN CASE OF CLEAR REBOOT
;turn on the led
	bcf	ledv
	bsf	pwm1
;measure battery voltage
;if low, wait for second, turn off the led and go to sleep

;wait for button to be released - pic turned on by pressing the button
bt_start_rel
;	btfss	bt1
;	goto	bt_start_rel

;restore previous state
;read data from eeprom, 0xAA, led1, led2, mode
;no data in eprom, set default mode


;enable interrupt -> pwm
	bsf	intcon, gie
;######################################################################
;main
;######################################################################


;tasks
;monitor battery voltage and adjust the constant

;generates pwm and run tasks
	;pwm on
	;movlw	0
	;call	pwm_set_duty1
	;movlw	126
	;call	pwm_set_duty2

loop
	clrwdt
	goto	loop
;-----------------------------------
; Sleep - virtual poweroff
;
; disable everything you can and go to sleep
; return from sleep can be done by pressing bt1
;-----------------------------------
poweroff
	led_off	led1
	led_off led2
	bsf	ledv		;turn leds off

	bcf	pwm1
	bcf	pwm2

	clrf	tmr0
	bcf	intcon, t0if	;to be sure there's no pending interrupt

	movlw	CMP_OFF
	movwf	cmcon0		;disable comparator

	movf	porta, f	;update latches on porta
	bcf	intcon, raif
	bsf	intcon, raie	;enable interrupt on porta to wake up from sleep
	bcf	intcon, gie	;will cause wake up from sleep without calling interrupt

	bcf	wdtcon, swdten	;disable watchdog
	clrwdt

	sleep			;sleep my beauty, you are not needed for now...
;hey, you woke me up, time to start working again
	bsf	wdtcon, swdten	;reenable watchdog

	bcf	intcon, raie
	bsf	intcon, gie	;reenable timer interrupt

	movlw	CMP_ON
	movwf	cmcon0		;reenable comparators

	bcf	ledv

	movf	led1_mode,f
	btfsc	status, z
	led_on	led1

	movf	led2_mode, f
	btfsc	status, z
	led_on	led2		;reenable leds if were enabled before

	return
;----------------------------------------------------------------------
	end
