
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the transaction amount
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
; Formats the input for use with decimal arithmetic (without decimal point)
; Last update: 8/4/2025
;------------------------------------------------------------------------
.data
    promptTransactionAmount BYTE "Enter transaction amount (Maximum 999999.99): ", 0
    invalidInputMsg BYTE "Invalid amount. Please enter a positive number.", NEWLINE, 0
    decimalPointChar BYTE ".", 0
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
    
    ; Check if input amount is valid integer
    mov esi, inputTransactionAmountAddress
    INVOKE Str_length, esi
    mov ecx, eax

validateInteger:
    mov al, [esi]

    .IF al < '0' || al > '9'
        INVOKE printString, ADDR invalidInputMsg
        jmp input_retry
    .ENDIF

    inc esi

    LOOP validateInteger

    INVOKE Str_length, inputTransactionAmountAddress
    .IF eax > 8
        INVOKE printString, ADDR exceedTransactionLimit
        jmp input_retry
    .ENDIF

    CLC ; LOOP will cause the Carry Flag!
done:
    popad
    ret
promptForTransactionAmount ENDP
END