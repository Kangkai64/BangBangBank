
INCLUDE BangBangBank.inc

;-----------------------------------------------------------
; This module will print the customer menu onto the console
; Receives : Nothing
; Returns : Nothing
; Last update: 25/3/2025
;-----------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
welcomeMessage BYTE NEWLINE, NEWLINE, "Welcome ", 0
customerMenuTitle BYTE NEWLINE,
					"==============================", NEWLINE, 
					"Customer Menu", NEWLINE, 
					"==============================", NEWLINE, 0
customerMenuChoice BYTE NEWLINE,
					"1. Transfer", NEWLINE,
					"2. Deposit", NEWLINE,
					"3. Monthly Statement", NEWLINE,
					"4. Change Password", NEWLINE,
					"5. Switch Account", NEWLINE,
					"9. Logout", NEWLINE, NEWLINE, 0

account userAccount <>
interestFlag DWORD 0
inputAccountFlag DWORD 0

.code
displayCustomerMenu PROC,
	user: PTR userCredential

start:
	call clearConsole
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

	; Copy out the customer_id and store it into user account structure
    mov esi, [user]
    add esi, OFFSET userCredential.customer_id
    INVOKE Str_copy, esi, ADDR account.customer_id
	mov esi, [user]
	add esi, OFFSET userCredential.username

	.IF inputAccountFlag == 0
		; Read user account from userAccount.txt
		INVOKE inputFromAccount, ADDR account
		mov eax, 1
		mov inputAccountFlag, eax
	.ENDIF

	; Check interest only for one time
	.IF interestFlag == 0
		INVOKE checkInterest, ADDR account
		mov eax, 1
		mov interestFlag, eax
		call clearConsole
	.ENDIF

	; Display the main menu
	INVOKE displayLogo
	INVOKE printString, ADDR dateHeader
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
	INVOKE printString, ADDR timeDate
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
	INVOKE printString, ADDR welcomeMessage
	INVOKE printUserAccount, ADDR account, PRINTMODE_FULLNAME
	INVOKE printString, ADDR customerMenuTitle
	INVOKE printUserAccount, ADDR account, PRINTMODE_ACCOUNT_NUMBER
	Call Crlf
	INVOKE printUserAccount, ADDR account, PRINTMODE_BALANCE
	Call Crlf
	INVOKE printString, ADDR customerMenuChoice
	INVOKE promptForIntChoice, 1, 5
	
	.IF CARRY? ; Return to start if the input is invalid
		jmp start
	.ELSEIF al == 1
		INVOKE processTransaction, ADDR account
	.ELSEIF al == 2
		INVOKE processDeposit, ADDR account, user
	.ELSEIF al == 3
        INVOKE printMonthlyStatement, ADDR account
	.ELSEIF al == 4
		INVOKE changePassword, user
	.ELSEIF al == 5
		INVOKE switchAccount, ADDR account, user
	.ENDIF

	jc start

	done:
		; Reset the flag values
		mov eax, 0
		mov inputAccountFlag, eax
		mov interestFlag, eax
		ret  
displayCustomerMenu ENDP
END