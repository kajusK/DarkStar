;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; key.asm
;------------------------------
;
; The device has two buttons which can be used in two states
;
; short press < 2s
; 2s < long press
;
; long press on bt1 wakes the device up or turns it off
; long press on bt2 changes the led which is currently controlled by keys
;
; short press changes brightness
;
; Buttons logic is inverted (pressed equals to L)
;**********************************************************************
;-----------------------------------
; key press detection
;
; saves the current key state and compares it with the previous one
; if the key press action occured, set key_action and if the press
; was long, set key_long
;
; all flags except key_pressed should be properly cleared to avoid running button
; action multiple times
;
; After short press, key_pressed is cleared and key_action is set
; Long press behaves differently, key_press is cleared after releasing the key, but
;	key_action and key_long are set immediately when lenght of key press
;	exceeds the KEY_LONG time regardless if the key was just released or is
;	still hold
;
; Ignores too short presses
;-----------------------------------
key_check MACRO key_reg, key_num, r_pressed, r_action, r_long, k_timer
	local key_check_pressed
	local key_check_released

	btfsc	key_reg, key_num
	goto	key_check_released
;key pressed
	btfsc	buttons, r_pressed
	goto	key_check_pressed	;is still pressed
;was pressed just now
	movlw	KEY_LONG
	movwf	k_timer			;set timer
	bsf	buttons, r_pressed	;and flag
	return

key_check_pressed
	btfsc	buttons, r_long
	return				;long button occured and is still pressed, ignore

	decfsz	k_timer, f		;decrement key length timer
	return
	;overflowed - long press
	bsf	buttons, r_action
	bsf	buttons, r_long

	return

key_check_released
	btfss	buttons, r_pressed
	return				;was not pressed

	bcf	buttons, r_pressed

	btfsc	buttons, r_long
	return				;long press just finished, no need to do anything else

	movf	k_timer, w
	sublw	KEY_LONG-KEY_MIN	;(KEY_LONG-KEY_MIN) - timer
	btfss	status, c
	return				;key was pressed for too short time, ignore

	bsf	buttons, r_action
	bcf	buttons, r_long
	return
	ENDM
;----------------------
key_check_bt1
	key_check bt1, bt1_pressed, bt1_action, bt1_long, bt1_timer

key_check_bt2
	key_check bt2, bt2_pressed, bt2_action, bt2_long, bt2_timer

;-----------------------------------
; Button events, run actions...
;
;uses 1 level stack + action's stack levels
;-----------------------------------
key_event MACRO r_action, r_long, r_pressed, r_completed, key_short_action, key_long_pre_action, key_long_post_action
	local	key_event_short
	local	key_event_long_post

	btfss	buttons, r_long
	goto	key_event_short

;long press
	btfsc	buttons, r_completed
	goto	key_event_long_post

;action to run before key is released
	call	key_long_pre_action	;action before key is released
	bsf	buttons, r_completed	;pre action flag completed

	return

key_event_long_post
	btfsc	buttons, r_pressed
	return				;button was not released yet

	call	key_long_post_action	;action after the key is released

	bcf	buttons, r_completed
	bcf	buttons, r_long
	bcf	buttons, r_action	;cleanup of flags

	return

key_event_short
	bcf	buttons, r_action	;clear flag
	call	key_short_action
	return
	ENDM

;----------------------
bt1_event
	key_event bt1_action, bt1_long, bt1_pressed, bt1_completed, mode_up, leds_off, power_off

bt2_event
	key_event bt2_action, bt2_long, bt2_pressed, bt2_completed, mode_down, mode_switch_start, mode_switch_end

;-----------------------------------
; runs every 10ms, detect pressed keys
;
; and run commands based on the key pressed
; and length of the press
;
; Uses 2 level stack + action's stack levels
;-----------------------------------
key_task
;check keys
	call key_check_bt1
	call key_check_bt2
;run the actions if any
	btfsc	buttons, bt1_action
	call	bt1_event
	btfsc	buttons, bt2_action
	call	bt2_event

	return

;-----------------------------------
; Used during turn on event to check the key was hold
; long enough (e.g. to ignore momentary press)
;
; return status, c = 0 if too short
;-----------------------------------
key_powerup
;wait for about 2 sec
	movlw	10
	movwf	on_counter_1	;number of x100ms length
	movlw	212
	movwf	on_counter_2
	movlw	155
	movwf	on_counter_3

	bcf	status, c
	btfsc	bt1
	return			;button released after too short time, exit

	decfsz	on_counter_3, f
	goto	$-1		;3*c3 - 1
	decfsz	on_counter_2, f
	goto	$-8		;(3*255-1+8)*c2-1 =
	decfsz	on_counter_1, f
	goto	$-12

	;TODO add counter to avoid lock during key malofunction
;wait for key to be released
	btfss	bt1
	goto	$-1		;wait for key to be released
	bsf	status, c
	return			;pressed for time long enough
