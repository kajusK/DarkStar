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
;**********************************************************************
;-----------------------------------
; Enable/disable led
;
; set port as input/output which effectively
; disable/enable comparator output
; and therefore the led itself
;-----------------------------------
led_on	macro r_tris, pin
	bsf	status, rp0
	bcf	r_tris, pin
	bcf	status, rp0
	endm

led_off macro r_tris, pin
	bsf	status, rp0
	bsf	r_tris, pin
	bcf	status, rp0
	endm

;-----------------------------------
; Limit W to led mode max
; uses tmp
;-----------------------------------
led_intensity_limit
	movwf	tmp
	sublw	LED_MODE_MAX		;max - new
	btfss	status, c
	retlw	LED_MODE_MAX		;new > max
	movf	tmp, w
	return

;-----------------------------------
; Set led1 output intensity (0-5)
;
; Intensity in W
;
; uses tmp, 2 level stack
;-----------------------------------
led1_set
	call	led_intensity_limit
	movwf	led1_intensity		;save new intensity

	led_off	led1
	movf	led1_intensity, w
	btfss	status, z
	led_on	led1

	call	adc_pwm_calculate
	call	pwm1_set
	call	pwm_update
	led_on	led1

	return

;-----------------------------------
; Set led2 output intensity (0-5)
;
; Intensity in W
;
; uses tmp, 2 level stack
;-----------------------------------
led2_set
	call	led_intensity_limit
	movwf	led2_intensity		;save new intensity

	led_off	led2
	movf	led2_intensity, w
	btfss	status, z
	led_on	led2

	call	adc_pwm_calculate
	call	pwm2_set
	call	pwm_update
	led_on	led2

	return
