;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
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
; interrupt must be dissabled for time of measurement (500ns). Also, the pwm1
; must be in high state. Therefore AD can't be used very often as it would
; cause light output instability.
;
; Supply voltage can be calculated:
; Ucc = 256*diode_fwd/ADRESH
;
; Pwm duty in % for output voltage U
; Pwm = U / Ucc = U*ADRESH / (256*diode_fwd) * 100
;
; For selected values components, the ADRESH might be between 179 (3V) and
; around 100 (5V). To simplify calculations of pwm duty, the following equation
; was designed, all constants were choosen experimentally for intesity in <0,5>
; and pwm in <0,255>
;
; pwm_duty = (ADRESH+25)*intensity/4
;
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
	btfsc	pwm1
	goto	adc_convert_nowait	;was on, start conversion

;pwm was low, have to wait for a while (20ns) to get stable voltage
adc_convert_wait
	bsf	pwm1
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

adc_convert_nowait
	bsf	adcon0, go		;start conversion
;run conversion
adc_convert_1
	btfsc	adcon0, go
	goto	adc_convert_1

;conversion finished, reenable interrupts
	bcf	pwm1			;pwm pulsed is fucked anyway, stop it
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
	sublw	ADC_TRESHOLD		;treshold - adc_result
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
	call	adc_convert		;result in W
	sublw	ADC_TRESHOLD		;treshold - adc_result
	btfss	status, c
	goto	adc_low			;voltage low

	movlw	ADC_LOW_RETRIES
	movwf	adc_low_count		;reset adc low counter

;apply pwm output correction
adc_task_update
	movf	led1_intensity, w
	call	adc_pwm_calculate	;get the new pwm
	call	pwm1_set		;and set it

	movf	led2_intensity, w
	call	adc_pwm_calculate
	call	pwm2_set

	call	pwm_update		;finally, apply the new values
	return

;voltage below treshold
adc_low
	decfsz	adc_low_count, f	;low voltage event must repeat few times before shutdown
	goto	adc_task_update		;not enough repeated low voltage measurements, continue
	;ugh, battery is low, shutdown

	movlw	ADC_LOW_RETRIES
	movwf	adc_low_count		;reset adc low counter

	call	low_voltage
	return
;-----------------------------
; calculate pwm value from intensity and current adc
; intensity and result in W
;
; pwm_duty = (adc_result+25)*intensity/4
;
; uses tmp and 1 level stack
;-----------------------------
adc_pwm_calculate
	movwf	numberl			;intensity to multiply with
	movf	adc_result, w
	addlw	25			;adc+25
	btfsc	status, c
	movlw	0xFC			;error, should not overflow, set to something below 255
	call	multiply		;(adc+25)*intensity
	movlw	2
	call	divide			;divide result by 2^2 = 4

	movf	numberh, f
	movlw	0xff
	btfss	status, z
	movwf	numberl			;result was bigger than 255 - set to 100% duty

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
