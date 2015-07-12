;**********************************************************************
;Led headlamp
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; headlamp.inc
;**********************************************************************

;**********************************************************************
;definitions
;**********************************************************************
;---------------constants---------------------
;cmcon0 - comparators
CMP_ON		equ	b'00010100'
CMP_OFF		equ	b'00010111'

;pwm duty equal to 50%
PWM_DUTY_HALF	equ	126
;full pwm duty
PWM_DUTY_FULL	equ	PWM_DUTY_HALF*2

;led modes
LED_MODE_MAX	equ	5
PWM_LED_STEP	equ	PWM_DUTY_FULL/LED_MODE_MAX

;ADC
; Cut off adc, when this threshold is exceeded, the devices moves to sleep as
; the battery is almost dead
;MODIFY - BASED ON PARTS YOU USED
; treshold_adc = 255*sense_diode_fwd/(treshold_voltage - supply_diode_fwd)
; = 255*1,85/(3-0,37)
ADC_TRESHOLD	equ	179
;at this level, set led output to minimum
ADC_SOFT_TRSH	equ	160

;low voltage has to be measured more times before shutting the device off
ADC_LOW_RETRIES	equ	10


;pwm_data
pstart1		equ	0
pstart2		equ	1
pmiddle1	equ	2
pmiddle2	equ	3
pend1		equ	4
pend2		equ	5
;----------------------pins-------------------
#define	pwm1	porta, 5
#define pwm2	portc, 2
#define bt1	porta, 3
#define bt2	porta, 4
#define led1	porta, 2
#define led2	portc, 4
#define ledv	portc, 5

;**********************************************************************
;variables
;**********************************************************************
	cblock	0x20
; bank0, 80bytes
;------------------------
;*****
;general
;*****
	tmp

	sys_timer	;system timer, increments every 1024 us

;*****
;pwm
;*****
;used by pwm generator
	pwm_data
	pwm_time1
	pwm_time2
	pwm_count
;tmp values for calculation of the pwm generator variables
	pwm_tmp_data	;-|
	pwm_tmp_time1	;-|- copied into non tmp values after computation
	pwm_tmp_time2	;-|
	pwm_tmp1
	pwm_tmp2
;actual pwm duty, or better, the number of repeats
	pwm_duty1
	pwm_duty2

;*****
;ADC
;*****
;last voltage
	adc_result
;adc conversions left before shutdown
	adc_low_count
;multiplication, division...
	numberl
	numberh

;led output power (0-5, 0 is off)
	led1_mode
	led2_mode
;------------------------
	endc

;bank 1
	cblock 0xa0
;-----------------------
;----------------------
	endc

	cblock	0x70
;mirrored into all banks, 16bytes
;------------------------
	w_sav
	stat_sav
	fsr_sav
;------------------------
	endc

;**********************************************************************
; Macros
;**********************************************************************
;---------------------------
; set outputs to values from pwm_data
; par1 and par2 defines bits to read
; 6 cycles
;---------------------------
PWM_SET macro par1, par2
	bcf	pwm1
	btfsc	pwm_data, par1
	bsf	pwm1

	bcf	pwm2
	btfsc	pwm_data, par2
	bsf	pwm2
	endm

;---------------------------
; set pwm_tmp_data, par1 to 1 if pwm_tmp_data, par2 is 0
; 6 cycles
;---------------------------
PWM_TOGGLE_CONF macro par1, par2
	bcf	pwm_tmp_data, par1
	btfss	pwm_tmp_data, par2
	bsf	pwm_tmp_data, par1
	endm

;---------------------------
; set pwm_tmp_data, par1 to pwm_tmp_data, par2
; 6 cycles
;---------------------------
PWM_COPY_CONF macro par1, par2
	bcf	pwm_tmp_data, par1
	btfsc	pwm_tmp_data, par2
	bsf	pwm_tmp_data, par1
	endm
