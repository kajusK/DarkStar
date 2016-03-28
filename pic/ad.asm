;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 8MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; ad.asm
;------------------------------
; This task determines the actual voltage and shuts system down when it
; reaches about 3V
;
; As the measuring takes some time and measuring diode is connected
; to pwm1 pin to keep the sleep current as low as possible, the
; interrupt must be dissabled for time of measurement (2us). Also, the pwm1
; must be in high state. Therefore AD can't be used very often as it would
; cause light output instability.
;
; Supply voltage can be calculated:
; Ucc = 255*diode_fwd/ADRESH
;
; Pwm duty in % for output voltage U
; Pwm = U / Ucc = U*ADRESH / (255*diode_fwd) * 100
;
; For selected values of components, the ADRESH can be between 158 (3V) and
; around 100 (5V).
;**********************************************************************

;------------------------------
; Run the ADC conversion
;
; measured value from ADRESH is stored in adc_result and w
;
; Supply voltage is Ucc = 255*diode_drop/ADRESH
; Higher ADRESH means lower supply voltage!
;
; Disables interrupts and pools until the convertion is finished!
;------------------------------
adc_convert
	bcf	intcon, gie		;disable interrupt
	btfss	pwm1
	bsf	pwm1			;set output to H

;wait for a while (10us) to get stable voltage
adc_convert_wait
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1
	goto	$+1

adc_convert_run
	bsf	adcon0, go		;start conversion
;run conversion
adc_convert_1
	btfsc	adcon0, go
	goto	adc_convert_1

;conversion finished, reenable interrupts and force new pwm pulse
	clrf	tmr0
	bsf	intcon, t0if		;force interrupt to occur - generate new pwm
	bsf	intcon, gie		;reenable interrupts

	movf	ADRESH, w
	movwf	adc_result		;store the result
	return

;------------------------------
; ADC voltage check
;
; Check the current voltage level, if too low, set status, c to zero
;------------------------------
adc_voltage_check
	call	adc_convert		;result in W
	sublw	ADC_OFF_TRESHOLD	;treshold - adc_result
	return

;------------------------------
; ADC task
;
; Check the current voltage level, if too low, turn the device off,
; if not, calculate and apply pwm duty correction
;
; 2 stack levels and tmp
;------------------------------
adc_task
	decfsz	adc_task_timer, f
	return				;delay to get longer AD task period - reduce blinking
	movlw	ADC_TASK_PERIOD
	movwf	adc_task_timer

	call	adc_convert		;result in W

	movwf	tmp
	sublw	ADC_OFF_TRESHOLD	;treshold - adc_result
	btfss	status, c
	goto	adc_below_off		;voltage too low

adc_task_check
	movf	tmp, w
	sublw	ADC_LOW_TRESHOLD
	btfss	status, c
	goto	adc_below_low		;voltage low, reduce out power

	movlw	ADC_LOW_RETRIES
	movwf	adc_low_count		;reset adc low counter
	movwf	adc_off_count

;TODO: apply pwm output correction
adc_task_update
;	movf	led1_intensity, w
;	call	adc_pwm_calculate	;get the new pwm
;	call	pwm1_set		;and set it
;
;	movf	led2_intensity, w
;	call	adc_pwm_calculate
;	call	pwm2_set
;
;	call	pwm_update		;finally, apply the new values
	return

;voltage below treshold
adc_below_off
	decfsz	adc_off_count, f	;low voltage event must repeat few times before shutdown
	goto	adc_task_check		;not enough repeated low voltage measurements, continue
	;ugh, battery is low, shutdown

	movlw	ADC_LOW_RETRIES
	movwf	adc_off_count		;reset adc off counter

	call	turnoff_voltage
	return

adc_below_low
	decfsz	adc_low_count, f	;low voltage event must repeat few times before any action
	goto	adc_task_update		;not enough repeated low voltage measurements, continue
	;ugh, battery is low, reduce power

	call	low_voltage
	return
;-----------------------------
; calculate pwm value from intensity (W) and store result in W
; TODO add brightness compensation during voltage drop
;
; pwm_duty = intensity^2 * PWM_LED_STEP
; Intensity 1 has hardcoded value to PWM_LEVEL1_VAL
;
; uses tmp and 1 level stack
;-----------------------------
adc_pwm_calculate
	movwf	tmp
	sublw	1
	btfsc	status, z
	retlw	PWM_LEVEL1_VAL		;brightness 1 has hardcoded value

	movf	tmp, w
	movwf	numberl
	call	multiply		;intensity^2

	movf	numberh, f
	btfss	status, z
	retlw	0xff			;result > 255, shouldn't happen, return full anyway

	movlw	PWM_LED_STEP
	call	multiply		;*PWM_LED_STEP

	movf	numberh, f
	btfss	status, z
	retlw	0xff			;result > 255, shouldn't happen, return full anyway

	movf	numberl, w
	return

;------------------------------
; 8x8 bit multiply
;
; source: http://www.piclist.com/techref/microchip/math/mul/8x8.htm
;
; input numbers are in w and numberl
; Result is in numberh:numberl
;------------------------------
MULT	macro
	btfsc	status,c
	addwf	numberh,f
	rrf	numberh,f
	rrf	numberl,f
	endm

multiply:
	clrf	numberh
	rrf	numberl,f

	MULT
	MULT
	MULT
	MULT
	MULT
	MULT
	MULT
	MULT
	return

;------------------------------
; 16 bit divide by 2^W
;
; input and result is in numberh:numberl
; uses tmp
;------------------------------
divide:
	movwf	tmp
divide_1:
	bcf	status, c
	rrf	numberh, f
	rrf	numberl, f
	decfsz	tmp, f
	goto	divide_1
	return
