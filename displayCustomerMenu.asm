
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
					"4. Change Credentials", NEWLINE,
					"5. Switch Account", NEWLINE,
					"9. Logout", NEWLINE, NEWLINE, 0

account userAccount <>

.code
displayCustomerMenu PROC,
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

	; Read user account from userAccount.txt
	INVOKE inputFromAccount, ADDR account

	;Check apply interest or not
	INVOKE checkInterest, ADDR account

	; Display the main menu
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
	
	.IF CARRY? ; Return if the input is invalid
		jmp done
	.ELSEIF al == 1
		INVOKE processTransaction, ADDR account
	.ELSEIF al == 2
		;call aboutUs
	.ELSEIF al == 3
		INVOKE printMonthlyStatement, ADDR account
	.ELSEIF al == 4
		call changeCredentials
	.ELSEIF al == 5
		;call switchAccount
	.ENDIF

	done:
		ret 
displayCustomerMenu ENDP
END