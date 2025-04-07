
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the transaction amount
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
; Last update: 25/3/2025
;------------------------------------------------------------------------
.data
    promptTransactionAmount BYTE "Enter transaction amount: ", 0
    invalidInputMsg BYTE "Invalid amount. Please enter a positive number.", 13, 10, 0
    overflowMsg BYTE "Amount too large. Maximum allowed is 999,999,999.", 13, 10, 0
    notSufficientBalance BYTE "Not sufficient balance... ", NEWLINE, 0
    exceedTransactionLimit BYTE "Invalid amount! Exceeded transaction limit...", NEWLINE, 0

.code
promptForTransactionAmount PROC,
    inputTransactionAmountAddress: PTR BYTE,
    account: PTR userAccount

    pushad

    ; Validate input loop
input_retry:
    ; Display prompt
    INVOKE printString, ADDR promptTransactionAmount
    
    ; Read input
    mov edx, inputTransactionAmountAddress
    mov ecx, maxBufferSize - 1
    call ReadString
    
    ; Check if any input was received
    .IF eax == 0
        INVOKE printString, ADDR invalidInputMsg
        jmp input_retry
    .ENDIF

    ; Validate input
    mov esi, inputTransactionAmountAddress
    mov ecx, eax        ; Length of input string
    mov edx, 0          ; Accumulator for numeric value
    mov ebx, 10         ; Multiplier

validate_loop:
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
    loop validate_loop

    ; Check if input amount is zero
    .IF edx == 0
        INVOKE printString, ADDR invalidInputMsg
        jmp input_retry
    .ENDIF

    ;check whether exceed transaction limit
    ; Convert transaction limit to numeric value first
    mov esi, [account]
    lea edi, [esi + OFFSET userAccount.transaction_limit]
    INVOKE StringToInt, edi
    mov ecx, eax      ; Store transaction limit in ecx

    ; Compare transaction amount with transaction limit
    .IF edx > ecx
        INVOKE printString, ADDR exceedTransactionLimit
        jmp input_retry
    .ENDIF

    ;check whether enough balance
    ; Convert account_balance to numeric value first
    mov esi, [account]
    lea edi, [esi + OFFSET userAccount.account_balance]
    INVOKE StringToInt, edi
    mov ecx, eax      ; Store account balance in ecx

    ; Compare transaction amount with account balance
    .IF edx > ecx
        INVOKE printString, ADDR notSufficientBalance
        jmp input_retry
    .ENDIF

    ; Convert validated number back to string
    mov eax, edx
    mov edi, inputTransactionAmountAddress
    call IntToString

    ; Clear carry flag to indicate success
    CLC
    jmp done

done:
    popad
    ret

promptForTransactionAmount ENDP
END