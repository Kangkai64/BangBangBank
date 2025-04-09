
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will validate the transaction amount whether exceed transaction limit and account balance
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
; Formats the input for use with decimal arithmetic (without decimal point)
; Last update: 8/4/2025
;------------------------------------------------------------------------
.data
    notSufficientBalance BYTE "Not sufficient balance... ", NEWLINE, 0
    decimalPointChar BYTE ".", 0
    transactionLimit BYTE 32 DUP(?)
    exceedTransactionLimit BYTE "Exceed transaction limit! Will charge extra RM 1 for this transaction.", NEWLINE, 0

.code
validateTransactionAmount PROC,
    inputTransactionAmountAddress: PTR BYTE,
    account: PTR userAccount
    
    LOCAL tempBuffer[32]: BYTE
    LOCAL formattedAccountBalance[32]: BYTE
    LOCAL formattedTransAmount[32]: BYTE
    
    pushad
   
    ; Check whether exceed transaction limit
    ; Convert transaction limit to numeric value first
    mov esi, [account]
    lea edi, [esi + OFFSET userAccount.transaction_limit]
    INVOKE removeDecimalPoint, edi, ADDR transactionLimit

    ; Compare transaction amount with transaction limit
    INVOKE Str_compare, ADDR transactionLimit, inputTransactionAmountAddress

    .IF CARRY?
        INVOKE printString, ADDR exceedTransactionLimit
    .ENDIF

    ; Check whether user has enough balance
    ; Convert account_balance to numeric value first
    mov esi, [account]
    lea esi, [esi + OFFSET userAccount.account_balance]
    
    INVOKE removeDecimalPoint, esi, ADDR formattedAccountBalance
    INVOKE removeDecimalPoint, inputTransactionAmountAddress, ADDR tempBuffer
    
    ; Compare transaction amount with account balance
    ; We'll use decimalArithmetic with subtraction to see if result is negative
    INVOKE decimalArithmetic, ADDR formattedAccountBalance, ADDR tempBuffer, ADDR tempBuffer, '-'
    
    ; Check if first character of result is '-' (negative)
    lea esi, tempBuffer
    mov al, [esi]
    cmp al, '-'
    je insufficient_balance

    ; Clear carry flag to indicate success
    CLC
    jmp done
    
insufficient_balance:
    INVOKE printString, ADDR notSufficientBalance
    call Wait_Msg
    STC     ; Set carry flag to indicate failure
    
done:
    popad
    ret
validateTransactionAmount ENDP
END