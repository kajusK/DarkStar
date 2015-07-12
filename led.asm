;**********************************************************************
;Led headlamp
;PIC 16F684
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; ad.asm
;------------------------------
;
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
led_mode_limit
	movwf	tmp
	sublw	LED_MODE_MAX		;max - new
	btfss	status, c
	retlw	LED_MODE_MAX		;new > max
	movf	tmp, w
	return

;-----------------------------------
; Set led output power
;
; Convert led level from W to pwm_duty
; Call pwm_correct to apply voltage correction
; and update pwm generator

; uses tmp, 2 level stack
;-----------------------------------
set_led1_mode
	call	led_mode_limit
	;0 - turn off, else *step

	return

set_led2_mode
	call	led_mode_limit
	return

;-----------------------------------
; Enable/disable led
;
; set port as input/output which effectively
; disable/enable comparator output
; and therefore the led itself
;-----------------------------------
