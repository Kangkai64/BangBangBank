
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will print the about us
; Receives : Nothing
; Returns : Nothing
; Last update: 22/3/2025
;------------------------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
aboutUsDesign BYTE NEWLINE, NEWLINE, "Bang Bang Bank Info", NEWLINE,
              "==============================", NEWLINE,
              "About Us", NEWLINE,
              "==============================", NEWLINE, 0

aboutUsInfo BYTE "Welcome to Bang Bang Bank, where we make banking fast, secure,", NEWLINE,
            "and hassle-free. Our mission is to provide innovative financial", NEWLINE,
            "solutions with top-notch customer service.", NEWLINE, NEWLINE,
            "Whether you're saving for the future, managing your daily expenses,", NEWLINE,
            "or looking for smart investment opportunities, we've got you covered.", NEWLINE, NEWLINE,
            "At Bang Bang Bank, your trust is our priority. Join us today and", NEWLINE,
            "experience banking that works for you!", NEWLINE, 0
			
.code

aboutUs PROC
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

	; Display about us 
	INVOKE printString, ADDR dateHeader
	INVOKE setTxtColor, colorCode
	INVOKE printString, ADDR timeDate
	INVOKE setTxtColor, defaultColor
	INVOKE printString, OFFSET aboutUsDesign
	INVOKE printString, OFFSET aboutUsInfo

	; Exit about us
	call Wait_Msg
	jmp displayMainMenu
	
aboutUs ENDP
END 