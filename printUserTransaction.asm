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

    ;cmp printMode, PRINTMODE_TRANSACTION_ID
    ;je print_transaction_id

    ;cmp printMode, PRINTMODE_TRANSACTION_TYPE
    ;je print_transaction_type

    ;cmp printMode, PRINTMODE_AMOUNT
    ;je print_amount

    ;jmp print_all

;print_transaction_id:
    ; Print transaction ID
    INVOKE printString, ADDR transactionIdLabel
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_id
    INVOKE printString, esi

    ;jmp done

;print_transaction_type: 
    ; Print transaction type
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.transaction_type
    ;INVOKE printString, esi

    ;jmp done

;print_amount:
    ; Print transaction amount
    ;INVOKE printString, ADDR amountLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.amount
    ;INVOKE printString, esi
    
    ;jmp done
    
;print_all: 
    ; Print transaction ID
    ;INVOKE printString, ADDR transactionIdLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.transaction_id
    ;INVOKE printString, esi
    ;call Crlf

    ; Print customer ID
    ;INVOKE printString, ADDR customerIdLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.customer_id
    ;INVOKE printString, esi
    ;call Crlf
    
    ; Print transaction type
    ;INVOKE printString, ADDR transactionTypeLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.transaction_type
    ;INVOKE printString, esi
    ;call Crlf
    
    ; Print amount
    ;INVOKE printString, ADDR amountLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.amount
    ;INVOKE printString, esi
    ;call Crlf
    
    ; Print date
    ;INVOKE printString, ADDR dateLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.date
    ;INVOKE printString, esi
    ;call Crlf
    
    ; Print time
    ;INVOKE printString, ADDR timeLabel
    ;mov esi, transaction
    ;add esi, OFFSET userTransaction.time
    ;INVOKE printString, esi
    ;call Crlf

done:    
    popad
    ret
printUserTransaction ENDP
END