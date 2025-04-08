
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the transaction amount
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
; Formats the input for use with decimal arithmetic (without decimal point)
; Last update: 8/4/2025
;------------------------------------------------------------------------
.data
    promptTransactionAmount BYTE "Enter transaction amount: ", 0
    invalidInputMsg BYTE "Invalid amount. Please enter a positive number.", NEWLINE, 0
    overflowMsg BYTE "Amount too large. Maximum allowed is 999,999,999.99.", NEWLINE, 0
    notSufficientBalance BYTE "Not sufficient balance... ", NEWLINE, 0
    decimalPointChar BYTE ".", 0
    transactionLimit BYTE 32 DUP(?)
    exceedTransactionLimit BYTE "Invalid amount! Exceeded transaction limit...", NEWLINE, 0

.code
promptForTransactionAmount PROC,
    inputTransactionAmountAddress: PTR BYTE,
    account: PTR userAccount
    
    LOCAL tempBuffer[32]: BYTE
    LOCAL formattedAccountBalance[32]: BYTE
    LOCAL formattedTransAmount[32]: BYTE
    
    pushad
    ; Validate input loop
input_retry:
    ; Display prompt
    INVOKE printString, ADDR promptTransactionAmount
    
    ; Read input
    mov edx, inputTransactionAmountAddress
    mov ecx, maxBufferSize - 1
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT
    call ReadString
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

    ; Trims the transaction amount
    INVOKE myStr_trim, inputTransactionAmountAddress, " "
    
    ; Check if any input was received
    .IF eax == 0
        INVOKE printString, ADDR invalidInputMsg
        jmp input_retry
    .ENDIF

    ; Make a copy of the input for checking decimal format
    INVOKE Str_copy, inputTransactionAmountAddress, ADDR tempBuffer

    ; Check if the input contains a decimal point
    INVOKE Str_find, ADDR tempBuffer, ADDR decimalPointChar
    .IF eax != 0
        ; Input has decimal point, validate decimal format
        INVOKE validateDecimalInput, inputTransactionAmountAddress
        jc input_retry            ; If validation failed, retry
    .ELSE
        ; Input is integer, convert and append "00"        
        ; Format with "00" at the end (for use with decimal arithmetic)
        ; Find end of string
        mov esi, inputTransactionAmountAddress
        INVOKE Str_length, esi
        lea edi, [esi + eax]      ; Point to end of string
        
        ; Append "00" for cents
        mov BYTE PTR [edi], '0'
        inc edi
        mov BYTE PTR [edi], '0'
        inc edi
        mov BYTE PTR [edi], 0
    .ENDIF
    
    ; Check if input amount is zero
    mov esi, inputTransactionAmountAddress
    mov al, [esi]

    .IF al == '0'
        INVOKE printString, ADDR invalidInputMsg
        jmp input_retry
    .ENDIF
    
    ; Assume this is a withdrawal, so add '-' sign to transaction amount
    lea edi, formattedTransAmount
    mov BYTE PTR [edi], '-'       ; Add negative sign
    inc edi                       ; Move to next position

    ; Copy the original amount after the negative sign
    INVOKE Str_copy, inputTransactionAmountAddress, edi

    ; Check whether exceed transaction limit
    ; Convert transaction limit to numeric value first
    mov esi, [account]
    lea edi, [esi + OFFSET userAccount.transaction_limit]
    INVOKE removeDecimalPoint, edi, ADDR transactionLimit

    ; Compare transaction amount with transaction limit
    INVOKE Str_compare, ADDR transactionLimit, inputTransactionAmountAddress

    .IF CARRY?
        INVOKE printString, ADDR exceedTransactionLimit
        jmp input_retry
    .ENDIF

    ; Check whether user has enough balance
    ; Convert account_balance to numeric value first
    mov esi, [account]
    lea esi, [esi + OFFSET userAccount.account_balance]
    
    INVOKE removeDecimalPoint, esi, ADDR formattedAccountBalance
    INVOKE removeDecimalPoint, ADDR formattedTransAmount, ADDR tempBuffer
    
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
promptForTransactionAmount ENDP
END