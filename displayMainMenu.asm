
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module will print the main menu onto the console
; Receives : Nothing
; Returns : Nothing
; Last update: 13/3/2025
;------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
colorCode BYTE (blue + (black SHL 4))
defaultColor BYTE (white + (black SHL 4))
mainMenuDesign BYTE "Welcome to Bang Bang Bank", NEWLINE, 
					"==============================", NEWLINE, 
					"Main Menu", NEWLINE, 
					"==============================", NEWLINE,
					"1. Login", NEWLINE,
					"2. About Us", NEWLINE,
					"9. Exit", NEWLINE, 0

username BYTE 50 DUP("*")
password BYTE 50 DUP("*")

.code
displayMainMenu PROC
	
	INVOKE printString, ADDR dateHeader
	INVOKE setTxtColor, colorCode
	INVOKE getDateTimeComponent, DATE
	INVOKE setTxtColor, defaultColor
	INVOKE printString, ADDR mainMenuDesign
	INVOKE promptForIntChoice, 1, 2
	
	.IF CARRY? ; Return if the input is invalid
		jmp done
	.ELSEIF al == 1
		call login
	.ENDIF

	done:
		ret
displayMainMenu ENDP
END