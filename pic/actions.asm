;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; actions.asm
;**********************************************************************
;-----------------------------------
; Increase/decrease led brightness
; 1 level stack
;-----------------------------------
led_down MACRO reg, function
;failsafe check
	movf	reg, w
	btfsc	status, z
	return				;already zero, nothing to do
;real end check
	sublw	1
	btfsc	status, z		;already at lowest, nothing to do
	return

	decf	reg, w
	call	function
	return
	ENDM
;--------------------------

mode_up
	btfsc	mode, led_sel
	goto	mode_up_1		;led2 is selected

	incf	led1_intensity, w
	call	led1_set
	return

;led 2
mode_up_1
	incf	led2_intensity, w
	call	led2_set
	return

;--------------------------
mode_down
	btfsc	mode, led_sel
	goto	mode_down_1		;led2 is selected
;led 1
	led_down	led1_intensity, led1_set

;led 2
mode_down_1
	led_down	led2_intensity, led2_set

;-----------------------------------
; Switch led mode (control between led1 and led2)
;-----------------------------------
;toggle led selector bit
mode_switch_start
	btfss	mode, led_sel
	goto	mode_switch_start_1	;led1 is selected, change

;led2 was selected, turn it off
	bcf	mode, led_sel
	led_off	led2
	return

;select led2
mode_switch_start_1
	bsf	mode, led_sel
	led_on	led2
	return

;just placeholder for key macro, nothing useful to do now here
mode_switch_end
	return

;-----------------------------------
; Battery voltage is too low, turn everything off
;	and go to sleep
;
; Currently just redirects to power_off routine
;-----------------------------------
low_voltage
	goto	power_off

;-----------------------------------
; Turn leds off - long press occured
;
; before power off to notify user the button press is accepted
;-----------------------------------
leds_off
	led_off	led1
	led_off	led2
	return

;-----------------------------------
; Sleep - virtual poweroff
;
; disable everything you can and go to sleep
; return from sleep can be done by pressing bt1 for time of long press
;-----------------------------------
power_off
	led_off	led1
	led_off led2		;turn leds off

	bcf	pwm2

	clrf	tmr0
	bcf	intcon, t0if	;to be sure there's no pending interrupt

	bcf	cm1con0, c1on
	bcf	cm2con0, c2on	;disable comparators

	bcf	intcon, gie	;will cause wake up from sleep without calling interrupt
	bsf	intcon, raie	;enable interrupt on porta to wake up from sleep

;loop for momentary power button press
power_off_sleep
	movf	porta, f	;update latches on porta
	bcf	intcon, raif	;clear flag if set
	bcf	pwm1
	bsf	ledv		;turn status led off

	bcf	adcon0, adon	;turn off adc module

	sleep			;sleep my beauty, you are not needed for now...

;after wake up, turn led on and check voltage and power button pressed time
	bsf	adcon0, adon	;turn on adc module

	bsf	pwm1
	bcf	ledv		;turn status led on

	call	adc_voltage_check
	btfss	status, c
	goto	power_off_sleep	;voltage too low

	call	key_powerup
	btfss	status, c
	goto	power_off_sleep	;was pressed for too short time, sleep again

;ok, time to start working again
	bcf	intcon, raie
	bsf	intcon, gie	;reenable timer interrupt

	bsf	cm1con0, c1on
	bsf	cm2con0, c2on	;reenable comparators

;restore led states
	led_on	led1

	btfsc	mode, led_sel
	led_on	led2		;reenable leds if were enabled before

	call	key_bt1_wait	;wait for key to be released

	return
