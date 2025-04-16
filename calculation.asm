
INCLUDE BangBangBank.inc

.data
; Totals for tracking
totalCredit   BYTE 32 DUP('0'), 0  ; Buffer for storing credit total as string
totalDebit    BYTE 32 DUP('0'), 0  ; Buffer for storing debit total as string
totalBalance    BYTE 32 DUP('0'), 0  ; Buffer for storing balance total as string
totalInterest    BYTE 32 DUP('0'), 0  ; Buffer for storing balance total as string
balanceCount    BYTE 32 DUP('0'), 0 ; Buffer for storing balance count as string
averageBalance    BYTE 32 DUP('0'), 0  ; Buffer for storing average balance as string
averageExpenses    BYTE 32 DUP('0'), 0  ; Buffer for storing average balance as string
emptyValue    BYTE 32 DUP('0'), 0 ; Buffer for storing empty value as string
tempAmount    BYTE 32 DUP(0)       ; Temporary buffer for processing amounts
lastBalanceForDate    BYTE 32 DUP(0)       ; Temporary buffer for processing amounts
dateBuffer    BYTE 32 DUP('0'), 0  ; Buffer for storing date
oldDateBuffer    BYTE 32 DUP('0'), 0  ; Buffer for storing date
decimalPointChar BYTE ".", 0
transferMsg     BYTE "Total Transfer: RM ", 0
depositMsg      BYTE "Total Deposit: RM ", 0
interestMsg      BYTE "Total Interest: RM ", 0
balanceMsg      BYTE "Average Balance: RM ", 0
expensesMsg      BYTE "Average Expenses: RM ", 0
incremental     BYTE '1', 0
emptyOutput     BYTE ' -',0
leftPad         BYTE 5 DUP(32), 0      ; Left margin padding

.code
;----------------------------------------------------------------------
; This module reset all the global variables
; Receives : Nothing
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
resetData PROC
    push eax         ; Save registers
    push ecx
    push edi
    
    ; Reset totalCredit (fill with '0')
    mov edi, OFFSET totalCredit
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    ; Reset totalDebit
    mov edi, OFFSET totalDebit
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    ; Reset totalBalance
    mov edi, OFFSET totalBalance
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    ; Reset balanceCount
    mov edi, OFFSET balanceCount
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    ; Reset averageBalance
    mov edi, OFFSET averageBalance
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    ; Clear temp buffers (fill with 0)
    mov edi, OFFSET tempAmount
    mov al, 0
    mov ecx, 32
    rep stosb
    
    mov edi, OFFSET lastBalanceForDate
    mov al, 0
    mov ecx, 32
    rep stosb
    
    ; Reset date buffers
    mov edi, OFFSET dateBuffer
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    mov edi, OFFSET oldDateBuffer
    mov al, '0'
    mov ecx, 32
    rep stosb
    mov BYTE PTR [edi], 0    ; Null-terminate
    
    pop edi          ; Restore registers
    pop ecx
    pop eax
    ret
resetData ENDP
;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotalCredit PROC USES eax ebx ecx edx esi edi, 
    transaction: PTR userTransaction
    
    
process_credit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalCredit, ADDR totalCredit, '+'
    jmp done
    
done:    
    
    ret
calculateTotalCredit ENDP

;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotalDebit PROC USES eax ebx ecx edx esi edi, 
    transaction: PTR userTransaction,
    
    
process_debit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalDebit, ADDR totalDebit, '+'
    jmp done
    
done:    
    
    ret
calculateTotalDebit ENDP

;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------
calculateTotalInterest PROC USES eax ebx ecx edx esi edi, 
    transaction: PTR userTransaction,
    
    
process_debit:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.amount

    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalInterest, ADDR totalInterest, '+'
    jmp done
    
done:    
    
    ret
calculateTotalInterest ENDP

;----------------------------------------------------------------------
; This module calculates the total of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 9/4/2025
;----------------------------------------------------------------------
calculateAverageBalance PROC USES eax ebx ecx edx esi edi, 
    transaction: PTR userTransaction
    
    
process_total_balance:
    mov esi, transaction
    ; Get transaction amount pointer
    add esi, OFFSET userTransaction.balance
    ; Copy and remove decimal point from the amount
    INVOKE Str_copy, esi, ADDR tempAmount
    INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
    INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalBalance, ADDR totalBalance, '+'
    INVOKE decimalDivide, ADDR totalBalance, ADDR balanceCount, ADDR averageBalance
    jmp done
done:    
    
    ret
calculateAverageBalance ENDP
;----------------------------------------------------------------------
; This module calculates the daily balance of all user transactions
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 9/4/2025
;----------------------------------------------------------------------
calculateDailyAverageBalance PROC USES eax ebx ecx edx esi edi, 
    transaction: PTR userTransaction
    
    
check_date:
    mov esi, transaction
    ; Get transaction date pointer
    add esi, OFFSET userTransaction.date
    INVOKE Str_copy, esi, ADDR dateBuffer
    
    ; Compare with current date being processed
    INVOKE Str_compare, ADDR oldDateBuffer, ADDR dateBuffer
    .IF ZERO?
        ; Same date - update the balance for this date
        ; Get transaction balance pointer
        mov esi, transaction
        add esi, OFFSET userTransaction.balance
        INVOKE Str_copy, esi, ADDR lastBalanceForDate
    .ELSE
        ; New date found - process the previous date's last balance (if any)
        .IF dateBuffer[0] != 0  ; If not first record
            ; Process the last balance from previous date
            INVOKE decimalArithmetic, ADDR balanceCount, ADDR incremental, ADDR balanceCount, '+'
            ; Copy and remove decimal point from the last balance of previous date
            INVOKE Str_copy, ADDR lastBalanceForDate, ADDR tempAmount
            INVOKE removeDecimalPoint, ADDR tempAmount, ADDR tempAmount
            INVOKE decimalArithmetic, ADDR tempAmount, ADDR totalBalance, ADDR totalBalance, '+'
            INVOKE decimalDivide, ADDR totalBalance, ADDR balanceCount, ADDR averageBalance
        .ENDIF
        
        ; Update to new date and store its balance
        INVOKE Str_copy, ADDR oldDateBuffer, ADDR dateBuffer
        mov esi, transaction
        add esi, OFFSET userTransaction.balance
        INVOKE Str_copy, esi, ADDR lastBalanceForDate
    .ENDIF
    
    jmp done
done:    
    ret
calculateDailyAverageBalance ENDP

;----------------------------------------------------------------------
; Prints the total credit and debit amounts
; Receives: Nothing
; Returns: Nothing
; Last update: 4/9/2025
;----------------------------------------------------------------------
printTotal PROC
    pushad
    INVOKE Str_compare, ADDR totalInterest, ADDR emptyValue  
    .IF ZERO?
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR interestMsg
    INVOKE printString, ADDR emptyOutput
    call CRLF
    .ELSE
    INVOKE addDecimalPoint, ADDR totalInterest, ADDR tempAmount
    ; Display the credit total
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR interestMsg
    INVOKE printString, ADDR tempAmount
    call CRLF
    .ENDIF
    INVOKE Str_compare, ADDR totalCredit, ADDR emptyValue  
    .IF ZERO?
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR transferMsg
    INVOKE printString, ADDR emptyOutput
    call CRLF
    .ELSE
    INVOKE addDecimalPoint, ADDR totalCredit, ADDR tempAmount
    ; Display the credit total
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR transferMsg
    INVOKE printString, ADDR tempAmount
    call CRLF
    .ENDIF
    INVOKE Str_compare, ADDR totalDebit, ADDR emptyValue
    .IF ZERO?
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR depositMsg
    INVOKE printString, ADDR emptyOutput
    call CRLF
    .ELSE
    INVOKE addDecimalPoint, ADDR totalDebit, ADDR tempAmount
    ; Display the debit total
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR depositMsg
    INVOKE printString, ADDR tempAmount
    call CRLF
    .ENDIF
    INVOKE Str_compare, ADDR averageBalance, ADDR emptyValue
    .IF ZERO?
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR balanceMsg
    INVOKE printString, ADDR emptyOutput
    call CRLF
    .ELSE
    INVOKE addDecimalPoint, ADDR averageBalance, ADDR tempAmount
    ; Display the debit total
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR balanceMsg
    INVOKE printString, ADDR tempAmount
    call CRLF
    .ENDIF
    INVOKE decimalDivide, ADDR totalCredit, ADDR balanceCount, ADDR averageExpenses
    INVOKE Str_compare, ADDR averageExpenses, ADDR emptyValue
    .IF ZERO?
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR expensesMsg
    INVOKE printString, ADDR emptyOutput
    call CRLF
    .ELSE
    INVOKE addDecimalPoint, ADDR averageExpenses, ADDR tempAmount
    ; Display the debit total
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR expensesMsg
    INVOKE printString, ADDR tempAmount
    call CRLF
    .ENDIF
    popad
    ret
printTotal ENDP
END