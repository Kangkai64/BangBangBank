
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
welcomeMessage BYTE NEWLINE, NEWLINE, "Welcome ", 0
customerMenuTitle BYTE NEWLINE,
					"==============================", NEWLINE, 
					"Customer Menu", NEWLINE, 
					"==============================", NEWLINE, 
					"Account No.: ", NEWLINE, 0
customerMenuChoice BYTE NEWLINE,
					"1. Transfer", NEWLINE,
					"2. Deposit", NEWLINE,
					"3. Monthly Statement", NEWLINE,
					"4. Change Credentials", NEWLINE,
					"5. Switch Account", NEWLINE,
					"9. Logut", NEWLINE, NEWLINE, 0

username BYTE 255 DUP("?")
password BYTE 255 DUP("?")

.code
displayCustomerMenu PROC
	call Clrscr
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
	INVOKE printString, ADDR welcomeMessage
	INVOKE printString, ADDR customerMenuTitle
	INVOKE printString, ADDR customerMenuChoice
	INVOKE promptForIntChoice, 1, 5
	
	.IF CARRY? ; Return if the input is invalid
		jmp done
	.ELSEIF al == 1
		;call processtransfer
	.ELSEIF al == 2
		;call processdeposit
	.ELSEIF al == 3
		call printMonthlyStatement
	.ELSEIF al == 4
		;call changeCredentials
	.ELSEIF al == 5
		;call switchAccount
	.ENDIF

	done:
		ret 
displayCustomerMenu ENDP
END