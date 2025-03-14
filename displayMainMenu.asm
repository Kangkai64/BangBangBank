
INCLUDE BangBangBank.inc

; This module will print the main menu onto the console
; Receives : Nothing
; Returns : Nothing
; Last update: 13/3/2025

.data
dateHeader BYTE "Today is ", 0
mainMenuDesign BYTE "Welcome to Bang Bang Bank", NEWLINE, 
					"==============================", NEWLINE, 
					"Main Menu", NEWLINE, 
					"==============================", NEWLINE,
					"1. Login", NEWLINE,
					"2. About Us", NEWLINE,
					"9. Exit", NEWLINE

.code
displayMainMenu PROC
	
	INVOKE printString, OFFSET dateHeader
	INVOKE getDateTimeComponent, DATE
	INVOKE printString, OFFSET mainMenuDesign
	INVOKE promptForIntChoice, 1, 2

	ret
displayMainMenu ENDP
END