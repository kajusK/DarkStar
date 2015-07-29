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
; Press bt1 for about 2 sec to turn headlamp on
; Press it again for more than 2 sec to turn it off
;
; Short press of bt1 increases light output, bt2 decreases
;
; Led1 is turned on all times except power off state, led2 is controled by
; long press of bt2 (on/off), long press bt2 also switches currently controled
; led's intensity
;**********************************************************************
	LIST P=16F616, R=DEC
	include p16f616.inc
	errorlevel -302

	__CONFIG _CP_OFF & _BOREN_ON & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _IOSCFS_4MHZ

	include headlamp.inc

;**********************************************************************
; Beginning of the program execution
;**********************************************************************
	org 0x0
	goto init

	org 0x4
	goto interrupt

;######################################################################
;all the important parts :)
;######################################################################
	include led.asm
	include pwm.asm
	include ad.asm
	include key.asm
	include actions.asm
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

;ERROR, some other interrupts enabled, fix and return:
	movlw	b'01100000'
	movwf	intcon
	goto	int_end

;wake up from sleep when gie was forgotten enabled, just return
int_raif
	movf	porta, f	;update latches
	bcf	intcon, raif
	goto	int_end

;-----------------------------
;timers for system tasks
; sets run flags after specified period
;
;to keep pwm timing acurate, this part should always take same time
;-----------------------------
int_systime
	decfsz	adc_period_timer, f
	goto	int_systime_ad_wait
	movlw	ADC_PERIOD
	movwf	adc_period_timer
	bsf	task_flags, adc_run	;time to run adc task

int_systime_key
	decfsz	key_period_timer, f
	goto	int_systime_key_wait
	movlw	KEY_PERIOD
	movwf	key_period_timer
	bsf	task_flags, key_run	;time to run key task

	goto	int_pwm

int_systime_ad_wait
	goto	int_systime_key

int_systime_key_wait
	goto	$+1
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
;Init
;######################################################################
init
;**************************************
; peripherals
;**************************************
;bank 0
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
	movlw	b'10110011'
	movwf	ansel		;only RC3 and comparators out are analog inputs
;----------------AD--------------------
	movlw	b'01010000'
	movwf	adcon1		;set ADC period
;bank0
	bcf	status, rp0
	movlw	b'00011101'	;left justified, vdd reference,AD module on
	movwf	adcon0
;------------comparator----------------
	movlw	b'10110000'
	movwf	cm1con0		;output inverted
	movlw	b'10100001'
	movwf	cm2con0
	movlw	0x02
	movwf	cm2con1		;asynchronous outputs, timer1 ignored
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
	movlw	b'00100000'	;tmr0 interrupt enabled, global disabled for now
	movwf	intcon
;bank1
	bsf	status, rp0
	movlw	0x08
	movwf	ioca		;unmask interrupt on bt1 change
;bank0
	bcf	status, rp0

;-------------status_led---------------
	bcf	ledv
	bsf	pwm1		;turn led on
;**************************************
; variables
;**************************************
	clrf	led1_intensity
	clrf	led2_intensity

	clrf	pwm_duty1
	clrf	pwm_duty2
	call	pwm_update		;init pwm values

	movlw	ADC_LOW_RETRIES
	movwf	adc_low_count

	movlw	ADC_PERIOD
	movwf	adc_period_timer
	movlw	KEY_PERIOD
	movwf	key_period_timer

	clrf	task_flags

	clrf	buttons
	clrf	mode

;**************************************
; battery check...
;**************************************
;init adc result, checking if voltage is high enough not neccesary, device
; will turn off itself in few us anyway, voltage will be checked when turning on
	call	adc_voltage_check

;enable interrupt -> pwm
	bsf	intcon, gie

;set leds to default states
	movlw	1
	call	led1_set
	movlw	1
	call	led2_set
;set leds to default power output
;finally, go to sleep, wait for button press to wake up
	call	power_off
;######################################################################
;main loop
;
; Runing two tasks:
;	adc task reads voltage and updates pwm duty to keep output stable
;		regardles of input voltage
;
;	key task reads key presses and runs associated commands
;######################################################################
main_loop
;Uses flags set in interrupt routine, no need to take care of race conditions
;interrupt only sets the value, readed and unset is here
;timing is also not critical +- few ms means nothing
;key task
	btfss	task_flags, key_run
	goto	$+3
	call	key_task
	bcf	task_flags, key_run	;clear flag

;adc task
	btfss	task_flags, adc_run
	goto	$+3
	call	adc_task
	bcf	task_flags, adc_run	;clear flag

	goto	main_loop
;----------------------------------------------------------------------
	end
