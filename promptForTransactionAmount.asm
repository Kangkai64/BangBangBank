
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
        ; First validate the integer input
        mov esi, inputTransactionAmountAddress
        INVOKE Str_length, esi
        mov ecx, eax              ; Length of input string
        mov edx, 0                ; Accumulator for numeric value
        mov ebx, 10               ; Multiplier
        
validate_integer_loop:
        ; Get current character
        mov al, [esi]
        
        ; Check if character is a digit
        .IF al < '0' || al > '9'
            INVOKE printString, ADDR invalidInputMsg
            jmp input_retry
        .ENDIF
        
        ; Convert character to numeric value
        sub al, '0'
        
        ; Multiply existing value by 10 and add new digit
        push eax
        mov eax, edx
        mul ebx
        mov edx, eax
        pop eax
        movzx eax, al
        add edx, eax
        
        ; Check for overflow (max 999,999,999)
        .IF edx > 999999999
            INVOKE printString, ADDR overflowMsg
            jmp input_retry
        .ENDIF
        
        ; Move to next character
        inc esi
        loop validate_integer_loop
        
        ; Check if input amount is zero
        .IF edx == 0
            INVOKE printString, ADDR invalidInputMsg
            jmp input_retry
        .ENDIF
        
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
    
    ; Assume this is a withdrawal, so add '-' sign to transaction amount
    ; for proper comparison and calculation
    INVOKE Str_length, inputTransactionAmountAddress
    mov ecx, eax                  ; Save length
    mov esi, inputTransactionAmountAddress
    lea edi, formattedTransAmount
    
    ; Add negative sign (for withdrawal)
    mov BYTE PTR [edi], '-'
    inc edi
    
    ; Copy the rest of the string
    rep movsb
    mov BYTE PTR [edi], 0         ; Null-terminate
    
    ; Get account balance and remove decimal point for comparison
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
    
    ; Balance is sufficient, clear carry flag to indicate success
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