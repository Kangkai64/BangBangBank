INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will let user change their credentials
; Receives : Nothing
; Returns : Nothing
; Last update: 26/3/2025
;------------------------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
changeCredentialsDesign BYTE NEWLINE, NEWLINE,
							 "Change Credentials (Enter 9 to exit)", NEWLINE,
							 "====================================", NEWLINE, 0
promptCurrentPassword   BYTE "Enter old password: ", 0
promptNewPassword		BYTE "Enter new password: ", 0
promptConfirmPassword   BYTE "Enter confirm password: ", 0
successChangeMessage	BYTE NEWLINE, "Your password has been changed successfully.", 0
sameWithOldMessage		BYTE NEWLINE, "Your password cannot be the same with your old password.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
mismatchPassword		BYTE NEWLINE, "Your confirm password is not the same as your new password.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
exitCode				BYTE "9", 0

currentPassword     BYTE 50 DUP(?)
newPassword         BYTE 50 DUP(?)
confirmPassword     BYTE 50 DUP(?)

.code
changeCredentials PROC
	
	call Clrscr

	; Get current time and format it in DD/MM/YYYY HH:MM:SS format
	INVOKE GetLocalTime, ADDR currentTime
	INVOKE formatSystemTime, ADDR currentTime, ADDR timeOutputBuffer

	; Copy the date part of the time stamp
	lea esi, timeOutputBuffer
	lea edi, timeDate
	mov ecx, 10

copy_date:
		mov al, [esi]
		mov [edi], al
		inc esi
		inc edi
		LOOP copy_date

	; Add null terminator
	mov BYTE PTR [edi], 0

	; Display date
	INVOKE printString, ADDR dateHeader
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
	INVOKE printString, ADDR timeDate
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
	; Display change credentials design
	INVOKE printString, ADDR changeCredentialsDesign

	; Prompt for current password
	INVOKE promptForPassword, OFFSET currentPassword, ADDR promptCurrentPassword

	; Check if user wants to exit or not
	INVOKE Str_compare, OFFSET currentPassword, ADDR exitCode
	je exitChangeCredentials

newPasswordEntry:
	; Prompt for new password
	INVOKE promptForPassword, OFFSET newPassword, ADDR promptNewPassword

	; Check if user wants to exit or not
	INVOKE Str_compare, OFFSET newPassword, ADDR exitCode
	je exitChangeCredentials

	; Compare with old password
	INVOKE Str_compare, OFFSET newPassword, OFFSET currentPassword
	je passwordSameError

confirmPasswordEntry:
	; Prompt for confirm password
	INVOKE promptForPassword, OFFSET confirmPassword, ADDR promptConfirmPassword

	; Check if user wants to exit or not
	INVOKE Str_compare, OFFSET confirmPassword, ADDR exitCode
	je exitChangeCredentials

	; Compare new password with confirm password
	INVOKE Str_compare, OFFSET confirmPassword, OFFSET newPassword
	je passwordMatch

	INVOKE printString, ADDR mismatchPassword
	jmp confirmPasswordEntry  ; Fix: Only re-enter confirm password instead of new password

passwordSameError:
	; Display error message
	INVOKE printString, ADDR sameWithOldMessage
	jmp newPasswordEntry
	
passwordMatch:
	INVOKE printString, ADDR successChangeMessage
	call Wait_msg

exitChangeCredentials:
	STC
	ret

changeCredentials ENDP
END
