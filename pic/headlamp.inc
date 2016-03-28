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
;pwm duty equal to 50%
PWM_DUTY_HALF	equ	126
;full pwm duty
PWM_DUTY_FULL	equ	PWM_DUTY_HALF*2

;led modes
LED_MODE_MAX	equ	5
PWM_LEVEL1_VAL	equ	1
PWM_LED_STEP	equ	255/(LED_MODE_MAX*LED_MODE_MAX)

;ADC
; When LOW treshold is exceeded, device turns off second led and kees first on
; lowest level
; When the OFF threshold is exceeded, the devices moves to sleep as
; the battery is almost dead
;MODIFY - BASED ON PARTS YOU USED
; treshold_adc = 255*sense_diode_fwd/(treshold_voltage - supply_diode_fwd)
; or simply measure cut off voltage, modify value and repeat until correct
ADC_OFF_TRESHOLD	equ	160	;should be between 2.6-2.8V
ADC_LOW_TRESHOLD	equ	150	;Around 3V

;low voltage has to be measured more times before shutting the device off
ADC_LOW_RETRIES	equ	3

;timing of system tasks - increments of 512 us
ADC_PERIOD	equ	250		;8 Hz
KEY_PERIOD	equ	20		;every 10ms

;min time of long press (in KEY_PERIOD increments)
KEY_LONG	equ	80
;min time of key press (to avoid multiple short press events in case of key bouncing)
KEY_MIN		equ	3

;-------------------
;pwm_data
;-------------------
pstart1		equ	0
pstart2		equ	1
pmiddle1	equ	2
pmiddle2	equ	3
pend1		equ	4
pend2		equ	5

;-------------------
;task_flags
;-------------------
adc_run		equ	0
key_run		equ	1

;-------------------
;mode
;-------------------
led_sel		equ	0

;-------------------
;buttons
;-------------------
bt1_pressed	equ	0
bt2_pressed	equ	1
bt1_action	equ	2
bt1_long	equ	3
bt2_action	equ	4
bt2_long	equ	5
bt1_completed	equ	6
bt2_completed	equ	7

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

;system timer, increments every 512 us
	adc_period_timer
	key_period_timer
;tasks run etc flags
	task_flags
;current mode data
	mode
;led output power (0-5, 0 is off)
	led1_intensity
	led2_intensity

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
;adc conversions left before shutdown of low voltage
	adc_low_count
	adc_off_count
;multiplication, division...
	numberl
	numberh
;*****
;buttons
;*****
;buttons status
	buttons
;button timers
	bt1_timer
	bt2_timer
	on_counter_1
	on_counter_2
	on_counter_3

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
