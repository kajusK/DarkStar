;**********************************************************************
;Led headlamp
;PIC 16F616
;internal 4MHz
;------------------------------
; Jakub Kaderka
; jakub.kaderka@gmail.com
; 2015
;------------------------------
; modes.asm
;**********************************************************************

;clear device with no data in eeprom
mode_init
;set 3v level
;set min led levels
;set max led levels

;go to sleep
mode_sleep

mode_normal

mode_bike

mode_single

mode_dual
