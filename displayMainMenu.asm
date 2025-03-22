
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module will print the main menu onto the console
; Receives : Nothing
; Returns : Nothing
; Last update: 13/3/2025
;------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
mainMenuDesign BYTE NEWLINE, NEWLINE, "Welcome to Bang Bang Bank", NEWLINE, NEWLINE, 
					"==============================", NEWLINE, 
					"Main Menu", NEWLINE, 
					"==============================", NEWLINE,
					"1. Login", NEWLINE,
					"2. About Us", NEWLINE,
					"9. Exit", NEWLINE, 0

username BYTE 255 DUP("?")
password BYTE 255 DUP("?")

.code
displayMainMenu PROC
	
	; Get console default text color
	call GetTextColor
	mov defaultColor, al

	; Get current time and format it in DD/MM/YYYY HH:MM:SS format
	INVOKE GetLocalTime, ADDR currentTime
	INVOKE formatSystemTime, ADDR currentTime, ADDR timeOutputBuffer

	; Copy the date part of the time stamp
	lea esi, timeOutputBuffer
	lea edi, timeDate
	mov ecx, 10

	copy_date:
		mov eax, [esi]
		mov [edi], eax
		inc esi
		inc edi
		LOOP copy_date

	; Add null terminator
	mov BYTE PTR [edi], 0

	; Display the main menu
	INVOKE printString, ADDR dateHeader
	INVOKE setTxtColor, colorCode
	INVOKE printString, ADDR timeDate
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