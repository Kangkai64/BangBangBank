INCLUDE BangBangBank.inc

;-----------------------------------------------------------
; This module will print monthly statement for the user
; Receives : Nothing
; Returns : Nothing
; Last update: 24/3/2025
;-----------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
statementHeader BYTE "Monthly Statement", 0
nameLabel BYTE "Name: ", 0
accountLabel BYTE "Account No. :", 0
statementLabel BYTE "Statement period :",0
tableHeader BYTE NEWLINE,
					"===========================================================================", NEWLINE, 
					"|| Date  || Description   || Ref. || Withdrawals || Deposits || Balance ||", NEWLINE, 
					"===========================================================================", NEWLINE, 0
transaction userTransaction <>

.code
printMonthlyStatement PROC,
    account: PTR userAccount
    ; Clear the screen
    call Clrscr

    ; Copy out the customer_id and store it into user account structure
    mov esi, [account]
    add esi, OFFSET userAccount.customer_id
    INVOKE Str_copy, esi, ADDR transaction.customer_id
	mov esi, [account]
	add esi, OFFSET userAccount.full_name

	; Read user account from userAccount.txt
	INVOKE inputFromTransaction, ADDR transaction

    
    ; Display statement header with highlighted title
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
	INVOKE printString, ADDR statementHeader
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf

    ; Display User's info
    INVOKE printString, ADDR nameLabel
    mov esi, [account]
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi
    Call Crlf
    INVOKE printString, ADDR accountLabel
    mov esi, [account]
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi
    Call Crlf
    INVOKE printString, ADDR statementLabel
    
    Call Crlf
    
    ; Print table header
    mov edx, OFFSET tableHeader
    call WriteString
    call Crlf
    ;Print transaction details
    INVOKE printUserTransaction, ADDR transaction
    
    ; Exit monthly statement
    call ReadChar
    STC
    
    ret
printMonthlyStatement ENDP
END