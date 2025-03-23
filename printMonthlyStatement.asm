INCLUDE BangBangBank.inc

;-----------------------------------------------------------
; This module will print monthly statement for the user
; Receives : Nothing
; Returns : Nothing
; Last update: 24/3/2025
;-----------------------------------------------------------

.data
dateHeader BYTE "Today is ", 0
colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
statementHeader BYTE "Monthly Statement", 0
nameLabel BYTE "Name: ", 0
accountLabel BYTE "Account No. : ", 0
periodLabel BYTE "Statement period : ", 0
tableHeader BYTE NEWLINE,
					"===========================================================================", NEWLINE, 
					"|| Date  || Description   || Ref. || Withdrawals || Deposits || Balance ||", NEWLINE, 
					"===========================================================================", NEWLINE, 0

.code
printMonthlyStatement PROC
    ; Clear the screen
    call Clrscr

    ; Get console default text color
    call GetTextColor
    mov defaultColor, al
    
    ; Display statement header with highlighted title
    mov edx, OFFSET statementHeader
    call SetTextColor
    mov al, colorCode
    call SetTextColor
    call WriteString
    call Crlf
    
    ; Restore default text color
    mov al, defaultColor
    call SetTextColor
    
    ; Print customer information
    mov edx, OFFSET nameLabel
    call WriteString
    call Crlf
    
    mov edx, OFFSET accountLabel
    call WriteString
    call Crlf
    
    mov edx, OFFSET periodLabel
    call WriteString
    call Crlf
    
    ; Print table header
    mov edx, OFFSET tableHeader
    call WriteString
    call Crlf
    
    ; Exit monthly statement
    call WriteString
    call ReadChar
    STC
    
    ret
printMonthlyStatement ENDP
END