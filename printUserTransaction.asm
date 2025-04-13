INCLUDE BangBangBank.INC
;----------------------------------------------------------------------
; This module will print all user transaction information onto the console
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 13/4/2025
;----------------------------------------------------------------------
.data
; Column widths for exact alignment matching the screenshot
dateColWidth        BYTE 19            ; Width for date column including pipe
descColWidth        BYTE 34            ; Width for transaction description column
balanceColWidth     BYTE 28            ; Width for balance column
amountColWidth      BYTE 17            ; Width for amount column
spaceChar           BYTE " ", 0        ; Space character for padding
pipeChar            BYTE "|", 0        ; Pipe character for column separation

.code
printUserTransaction PROC, 
    transaction: PTR userTransaction
    
    LOCAL fieldLen:DWORD
    LOCAL padCount:DWORD
    
    pushad
    mov ecx, 7
    starting:
       INVOKE printString, ADDR spaceChar
       loop starting
    
    ; Print entry date (left-aligned with padding)
    mov esi, transaction
    add esi, OFFSET userTransaction.date
    INVOKE printString, esi
    
    ; Calculate padding for date column
    INVOKE Str_length, esi
    mov fieldLen, eax
    
    ; Add extra padding to match exactly 26 characters including pipe
    movzx eax, dateColWidth
    sub eax, fieldLen
    dec eax        ; Account for the pipe character
    mov padCount, eax
    
    ; Print padding spaces
    mov ecx, padCount
    cmp ecx, 0
    jle skipDatePad
padDateLoop:
    INVOKE printString, ADDR spaceChar
    loop padDateLoop
skipDatePad:
    
    ; Print | separator
    INVOKE printString, ADDR pipeChar
    
    ; Print transaction detail (left-aligned with padding)
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_detail
    INVOKE printString, esi
    
    ; Calculate padding for description column
    INVOKE Str_length, esi
    mov fieldLen, eax
    
    movzx eax, descColWidth
    sub eax, fieldLen
    dec eax        ; Account for the pipe character
    mov padCount, eax
    
    ; Print padding spaces
    mov ecx, padCount
    cmp ecx, 0
    jle skipDescPad
padDescLoop:
    INVOKE printString, ADDR spaceChar
    loop padDescLoop
skipDescPad:
    
    ; Print | separator
    INVOKE printString, ADDR pipeChar
    
    ; Print balance (right-aligned with padding)
    mov esi, transaction
    add esi, OFFSET userTransaction.balance
    
    ; Calculate padding for balance column (right-aligned)
    INVOKE Str_length, esi
    mov fieldLen, eax
    
    movzx eax, balanceColWidth
    sub eax, fieldLen
    dec eax        ; Account for the pipe character
    mov padCount, eax
    
    ; Print padding spaces first (for right alignment)
    mov ecx, padCount
    cmp ecx, 0
    jle skipBalancePad
padBalanceLoop:
    INVOKE printString, ADDR spaceChar
    loop padBalanceLoop
skipBalancePad:
    
    ; Print balance value
    INVOKE printString, esi
    
    ; Print | separator
    INVOKE printString, ADDR pipeChar
    
    ; Print amount (right-aligned with padding)
    mov esi, transaction
    add esi, OFFSET userTransaction.amount
    
    ; Calculate padding for amount column (right-aligned)
    INVOKE Str_length, esi
    mov fieldLen, eax
    
    movzx eax, amountColWidth
    sub eax, fieldLen
    mov padCount, eax
    
    ; Print padding spaces first (for right alignment)
    mov ecx, padCount
    cmp ecx, 0
    jle skipAmountPad
padAmountLoop:
    INVOKE printString, ADDR spaceChar
    loop padAmountLoop
skipAmountPad:
    
    ; Print amount value
    INVOKE printString, esi
    
    ; Move to next line for next transaction
    call Crlf
    
done:    
    popad
    ret
printUserTransaction ENDP
END