
INCLUDE BangBangBank.inc

;----------------------------------------------------------------------
; This module will print all user transaction information onto the console
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 25/3/2025
;----------------------------------------------------------------------
.data
; Labels for each transaction field
transactionIdLabel    BYTE "Transaction ID: ", 0
customerIdLabel       BYTE "Customer ID: ", 0
transactionTypeLabel  BYTE "Transaction Type: ", 0
amountLabel           BYTE "Amount: RM ", 0
dateLabel             BYTE "Date: ", 0
timeLabel             BYTE "Time: ", 0

.code
printUserTransaction PROC, 
    transaction: PTR userTransaction,
    ;printMode: DWORD ; Decide print what info

    pushad
    
    INVOKE printString, ADDR dateLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.date
    INVOKE printString, esi

    INVOKE printString, ADDR transactionTypeLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_type
    INVOKE printString, esi
    
    INVOKE printString, ADDR transactionIdLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_id
    INVOKE printString, esi

    INVOKE printString, ADDR amountLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.amount
    INVOKE printString, esi

    INVOKE printString, ADDR customerIdLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.customer_id
    INVOKE printString, esi
    call Crlf

done:    
    popad
    ret
printUserTransaction ENDP
END