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

;**********************************************************************
; Local for this file
;**********************************************************************
;-----------------------------------
; calculate variables for pwm generator and update them when finished
; disables interrupts momentarily
;-----------------------------------
pwm_update
	clrf	pwm_tmp_data

;****first initial values and timing of shorter part of the pulse
	movlw	PWM_DUTY_HALF
	subwf	pwm_duty1, w		;compare 50% and actual value
	btfsc	status, c
	goto	pwm_update_2		;over 50%

	bsf	pwm_tmp_data, pstart1	;under 50%
	movf	pwm_duty1, w
	movwf	pwm_tmp1		;just copy the duty for further computation

pwm_update_1
	movlw	PWM_DUTY_HALF
	subwf	pwm_duty2, w		;compare 50% and actual value
	btfsc	status, c
	goto	pwm_update_3		;over 50%

	bsf	pwm_tmp_data, pstart2	;under 50%
	movf	pwm_duty2, w
	movwf	pwm_tmp2		;just copy the duty for further computation

	goto	pwm_update_4

;duty1 over 50
pwm_update_2
	movf	pwm_duty1, w
	addlw	0xff-PWM_DUTY_FULL	;PWM_DUTY_FULL - pwm_duty
	movwf	pwm_tmp1
	goto	pwm_update_1

;duty2 over 50
pwm_update_3
	movf	pwm_duty2, w
	addlw	0xff-PWM_DUTY_FULL	;PWM_DUTY_FULL - pwm_duty
	movwf	pwm_tmp2

;first bits and times are ready, compute middle and end bits
pwm_update_4
	movf	pwm_tmp1, w
	subwf	pwm_tmp2, w		;tmp2 - tmp1
	btfsc	status, z
	goto	pwm_update_same		;tmp2 == tmp1

	btfss	status, c
	goto	pwm_update_5		;tmp1 > tmp2
;tmp1 < tmp2
	PWM_TOGGLE_CONF pmiddle1, pstart1
	PWM_COPY_CONF	pmiddle2, pstart2
	PWM_TOGGLE_CONF pend2, pmiddle2
	PWM_COPY_CONF	pend1, pmiddle1

	movf	pwm_tmp1, w
	movwf	pwm_tmp_time1		;update shorter pulse time

	subwf	pwm_tmp2, w
	movwf	pwm_tmp_time2		;tmp2-tmp1
	goto	pwm_update_var		;set the permanent values and return

;tmp1 > tmp2
pwm_update_5
	PWM_TOGGLE_CONF pmiddle2, pstart2
	PWM_COPY_CONF	pmiddle1, pstart1
	PWM_TOGGLE_CONF pend1, pmiddle1
	PWM_COPY_CONF	pend2, pmiddle2

	movf	pwm_tmp2, w
	movwf	pwm_tmp_time2		;update shorter pulse time

	subwf	pwm_tmp1, w
	movwf	pwm_tmp_time1		;tmp2-tmp1
	goto	pwm_update_var		;set the permanent values and return

;both pwm times are same
pwm_update_same
	PWM_TOGGLE_CONF	pmiddle1, pstart1
	PWM_TOGGLE_CONF	pmiddle2, pstart2
	PWM_COPY_CONF	pend1, pmiddle1
	PWM_COPY_CONF	pend2, pmiddle2	;toggle middle and copy middle to end
	clrf	pwm_tmp_time2
	movf	pwm_tmp1, w
	movwf	pwm_tmp_time1		;update time1 to pulse length and time2 to 0
	goto	pwm_update_var		;finally, update the real pwm values

;finally, copy values from tmp to permanent locations
;additionally, check for 100% or 0% duty cycles and update the data parts
;disables interrupts mometarily!
pwm_update_var
	movf	pwm_tmp1, f
	btfsc	status, z
	goto	pwm_update_var_1	;pwm1 is 100% or 0%
pwm_update_var_3
	movf	pwm_tmp2, f
	goto	pwm_update_var_2
pwm_update_var_4
	bcf	intcon, gie		;disable interrupt
	movf	pwm_tmp_data, w
	movwf	pwm_data
	movf	pwm_tmp_time1, w
	movwf	pwm_time1
	movf	pwm_tmp_time2, w
	movwf	pwm_time2		;copy data
	bsf	intcon, gie		;reenable interrupt
	return

;pwm 1 on 100% or 0%
pwm_update_var_1
	PWM_TOGGLE_CONF	pstart1, pstart1
	PWM_COPY_CONF	pmiddle1, pstart1
	PWM_COPY_CONF	pend1, pmiddle1
	goto		pwm_update_var_3

;pwm 2 on 100% or 0%
pwm_update_var_2
	PWM_TOGGLE_CONF	pstart2, pstart2
	PWM_COPY_CONF	pmiddle2, pstart2
	PWM_COPY_CONF	pend2, pmiddle2
	goto		pwm_update_var_4
;**********************************************************************
; Global
;**********************************************************************
;-----------------------------------
; Correct pwm output by voltage offset
; offset in w
;-----------------------------------
pwm_correct

;-----------------------------------
; Correct pwm output by voltage offset
; offset in w
;-----------------------------------

;-----------------------------------
; Enable/disable led
;
;set port as input/output which effectively
;disable/enable comparator output
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
; Set led output levels, stored in ledX_mode
;-----------------------------------
led1_level
	;Nejak pronasob aby sedelo


led2_level


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

	clrf	tmr0
	bcf	intcon, t0if	;to be sure there's no pending interrupt

	movlw	CMP_OFF
	movwf	cmcon0		;disable comparator

	movf	porta, f	;update latches on porta
	bcf	intcon, raif
	bsf	intcon, raie	;enable interrupt on porta to wake up from sleep
	bcf	intcon, gie	;will cause wake up from sleep without calling interrupt

	sleep			;sleep my beauty, you are not needed for now...
;hey, you woke me up, time to start working again
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
