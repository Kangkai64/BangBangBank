INCLUDE BangBangBank.inc
.data
; Totals for tracking
totalCredit   BYTE 32 DUP('0'), 0  ; Buffer for storing credit total as string
totalDebit    BYTE 32 DUP('0'), 0  ; Buffer for storing debit total as string
tempAmount    BYTE 32 DUP(0)       ; Temporary buffer for processing amounts
.code
;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotal PROC, 
    transaction: PTR userTransaction
    
    pushad
    
process_credit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount
     ; Remove sign from the amount
    INVOKE removeSign, ADDR tempAmount

   
    

    
    
    ; Add to credit total
    INVOKE addDecimal, ADDR tempAmount, ADDR totalCredit, 2
    
    ; Copy result to totalCredit
    INVOKE Str_copy, eax, ADDR totalCredit
    
    ; Display the result for debugging
    INVOKE printString, ADDR totalCredit
    jmp done
    
done:    
    popad
    ret
calculateTotal ENDP

;----------------------------------------------------------------------
; Removes the decimal point from a string
; Receives: Pointer to a string containing a decimal point
; Returns: Original string modified with decimal point removed
;----------------------------------------------------------------------
removeDecimalPoint PROC,
    pString: PTR BYTE
    
    push esi
    push edi
    
    ; Get string pointer
    mov esi, pString
    mov edi, esi
    
scan_loop:
    mov al, [esi]
    cmp al, 0       ; Check for end of string
    je done
    
    cmp al, '.'     ; Check for decimal point
    je skip_decimal
    
    ; Copy character if it's not a decimal point
    mov [edi], al
    inc edi
    
skip_decimal:
    inc esi
    jmp scan_loop
    
done:
    INVOKE printString, pString
    pop edi
    pop esi
    ret
removeDecimalPoint ENDP

;----------------------------------------------------------------------
; Removes the sign (+ or -) from the beginning of a string
; Receives: Pointer to a string that may have a sign
; Returns: Original string modified with sign removed
;----------------------------------------------------------------------
removeSign PROC,
    pString: PTR BYTE
    
    push esi
    push edi
    
    ; Get string pointer
    mov esi, pString
    
    ; Check if first character is a sign
    mov al, [esi]
    cmp al, '+'
    je remove_sign
    cmp al, '-'
    je remove_sign
    jmp done    ; No sign to remove
    
remove_sign:
    ; Shift everything left by one character to remove the sign
    mov edi, esi
    
shift_loop:
    inc esi
    mov al, [esi]
    mov [edi], al
    inc edi
    cmp al, 0       ; Check for end of string
    jne shift_loop
    
done:
    INVOKE printString, pString
    pop edi
    pop esi
    ret
removeSign ENDP
END