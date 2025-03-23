INCLUDE BangBangBank.inc
;------------------------------------------------------------------------
; This module will print the monthly statement
; Receives : Nothing
; Returns : Nothing
; Last update: 24/3/2025
;------------------------------------------------------------------------
.data
statementHeader BYTE "Monthly Statement", 0
nameLabel BYTE "Name: ", 0
accountLabel BYTE "Account No. : ", 0
periodLabel BYTE "Statement period : ", 0
separatorLine BYTE "=========================================================================", 0
tableHeader BYTE "|| Date  || Description   || Ref. || Withdrawals || Deposits || Balance ||", 0

colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?

.code
;------------------------------------------------------------------------
; printMonthlyStatement - Prints the complete monthly statement
; Receives: Nothing
; Returns: Nothing
;------------------------------------------------------------------------
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
    
    ; Print separator line
    mov edx, OFFSET separatorLine
    call WriteString
    call Crlf
    
    ; Print table header
    mov edx, OFFSET tableHeader
    call WriteString
    call Crlf
    
    ; Print separator line again
    mov edx, OFFSET separatorLine
    call WriteString
    call Crlf
    
    ; Exit monthly statement
    call WriteString
    call ReadChar
    STC
    
    ret
printMonthlyStatement ENDP
END