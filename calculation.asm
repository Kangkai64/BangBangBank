INCLUDE BangBangBank.inc
.data
; Totals for tracking
totalCredit   BYTE 32 DUP('0'), 0  ; Buffer for storing credit total as string
totalDebit    BYTE 32 DUP('0'), 0  ; Buffer for storing debit total as string
tempAmount    BYTE 32 DUP(0)       ; Temporary buffer for processing amounts
decimalPointChar BYTE ".", 0
.code
;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotalCredit PROC, 
    transaction: PTR userTransaction
    pushad
    
process_credit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalCredit, ADDR totalCredit, '+'
    INVOKE printString, ADDR totalCredit
 
    jmp done
    
done:    
    popad
    ret
calculateTotalCredit ENDP
;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotalDebit PROC, 
    transaction: PTR userTransaction
    pushad
    
process_debit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalDebit, ADDR totalDebit, '+'
    INVOKE printString, ADDR totalDebit
    jmp done
    
done:    
    popad
    ret
calculateTotalDebit ENDP
END