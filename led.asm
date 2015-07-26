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
; Set led output intensity (0-5)
;
; Intensity in W
;
; uses tmp, 2 level stack
;-----------------------------------
led_set	MACRO r_intensity, led_p, led_n, f_pwm_set
	call	led_intensity_limit
	movwf	r_intensity		;save new intensity

	led_off	led_p, led_n
	movf	r_intensity, w
	btfss	status, z
	led_on	led_p, led_n

	call	adc_pwm_calculate
	call	f_pwm_set
	call	pwm_update

	return
	ENDM

led1_set
	led_set led1_intensity, led1, pwm1_set
led2_set
	led_set led2_intensity, led2, pwm2_set
