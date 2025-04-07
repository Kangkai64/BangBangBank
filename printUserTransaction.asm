
INCLUDE BangBangBank.inc

;----------------------------------------------------------------------
; This module will print all user transaction information onto the console
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 25/3/2025
;----------------------------------------------------------------------
.data
; Labels for each transaction field
break       BYTE "   |   "

.code
printUserTransaction PROC, 
    transaction: PTR userTransaction
    
    pushad
    INVOKE printString, OFFSET break
    ; Print date
    mov esi, transaction
    add esi, OFFSET userTransaction.date
    INVOKE printString, esi
    
    INVOKE printString, OFFSET break
    ; Print transaction detail
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_detail
    INVOKE printString, esi
    
    INVOKE printString, OFFSET break
    ; Print balance
    mov esi, transaction
    add esi, OFFSET userTransaction.balance
    INVOKE printString, esi
    
    INVOKE printString, OFFSET break
    ; Print amount (with proper sign based on transaction type)
    mov esi, transaction
    add esi, OFFSET userTransaction.amount
    INVOKE printString, esi
    INVOKE printString, OFFSET break
    
    ; Move to next line for next transaction
    call Crlf
    
done:    
    popad
    ret
printUserTransaction ENDP
END