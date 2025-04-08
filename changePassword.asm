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
promptNewPassword		BYTE NEWLINE, "Your password must be at least 8 characters and contains: ", NEWLINE,
							 "-An uppercase letter",NEWLINE,
							 "-A lowercase letter",NEWLINE,
							 "-A digit",NEWLINE,
							 "-A special character [@$!%*?&]",NEWLINE,
							 NEWLINE, NEWLINE, "Enter new password: ", 0
promptConfirmPassword   BYTE "Enter confirm password: ", 0
successChangeMessage	BYTE NEWLINE, "Your password has been changed successfully.", 0
inputEmptyMessage		BYTE NEWLINE, "Input cannot be empty.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
incorrectPasswordMessage BYTE NEWLINE, "Incorrect password.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
sameWithOldMessage		BYTE NEWLINE, "Your password cannot be the same with your old password.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
insufficientLengthMessage BYTE NEWLINE, "Password must be at least 8 characters long.", NEWLINE, NEWLINE, 0
invalidComplexityMessage  BYTE NEWLINE, "Password must contain uppercase, lowercase, digit, and special character.", NEWLINE, NEWLINE, 0
mismatchPassword		BYTE NEWLINE, "Your confirm password is not the same as your new password.", NEWLINE,
							 "Please try again.", NEWLINE, NEWLINE, 0
exitCode				BYTE "9", 0

currentPassword     BYTE 50 DUP(?)
newPassword         BYTE 50 DUP(?)
confirmPassword     BYTE 50 DUP(?)
new_hashed_password BYTE 255 DUP(?)

.code
changePassword PROC,
	user: PTR userCredential
	
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

currentPasswordEntry:
	; Prompt for current password
	INVOKE promptForPassword, OFFSET currentPassword, ADDR promptCurrentPassword

	; Check if user wants to exit or not
	INVOKE Str_compare, OFFSET currentPassword, ADDR exitCode
	je exitChangeCredentials

	; Check if user input is empty
	INVOKE Str_length, ADDR currentPassword
	cmp eax, 0
	je inputEmpty

	; Extract the hashed old password for validation
	mov esi, [user]
    add esi, OFFSET userCredential.hashed_password
	mov edi, [user]
	add edi, OFFSET userCredential.encryption_key
	INVOKE validatePassword, ADDR currentPassword, esi, edi

	jc incorrectPassword

newPasswordEntry:
	; Prompt for new password
	INVOKE promptForPassword, OFFSET newPassword, ADDR promptNewPassword

	; Check if user wants to exit or not
	INVOKE Str_compare, OFFSET newPassword, ADDR exitCode
	je exitChangeCredentials

	; Check password length
	INVOKE Str_compare, OFFSET newPassword, OFFSET currentPassword
	je passwordSameError

	; Compare with old password
	INVOKE Str_compare, OFFSET newPassword, OFFSET currentPassword
	je passwordSameError

    ; Get length of new password
    INVOKE Str_length, OFFSET newPassword
    
    ; Check if password is at least 8 characters
    cmp eax, 8
	jl invalidLength
    
    ; Validate password complexity
    INVOKE validatePasswordComplexity, ADDR newPassword
    
    jc invalidComplexity

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

inputEmpty:
	INVOKE printString, ADDR inputEmptyMessage
	jmp currentPasswordEntry

incorrectPassword:
	INVOKE printString, ADDR incorrectPasswordMessage
	jmp currentPasswordEntry

passwordSameError:
	INVOKE printString, ADDR sameWithOldMessage
	jmp newPasswordEntry

invalidLength:
	INVOKE printString, ADDR insufficientLengthMessage
	jmp newPasswordEntry

invalidComplexity:
	INVOKE printString, ADDR invalidComplexityMessage
	jmp newPasswordEntry
	
passwordMatch:
    ; Get encryption key from user structure
    mov edi, [user]
    add edi, OFFSET userCredential.encryption_key
    
    ; Encrypt the password - returns pointer to encrypted data in EAX
    INVOKE encrypt, ADDR newPassword, edi
    
    ; Get destination pointer for hashed_password field
    mov edi, [user]
    add edi, OFFSET userCredential.hashed_password
    
    mov esi, eax          ; ESI = source (encrypted password)
	INVOKE Str_length, esi
	INVOKE convertHexToString, esi, ADDR new_hashed_password, eax  ; Convert hex values to string

    ; Use ECX as counter for string copy
    xor ecx, ecx          ; Clear ECX for the loop counter
    
	; Copy the encrypted data to the hashed_password field
	INVOKE Str_copy, ADDR new_hashed_password, edi
    
    ; Update user file with new credentials
    INVOKE updateUserFile, user
    INVOKE printString, ADDR successChangeMessage
    call Wait_msg

exitChangeCredentials:
	STC ; Don't logout the user
	ret

changePassword ENDP
END
