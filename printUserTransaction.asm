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
tempBuffer          BYTE 33 DUP(0)     ; Buffer for storing truncated description
descPadding         BYTE 34 DUP(" "), 0 ; Padding for second line of description

.code
printUserTransaction PROC, 
    transaction: PTR userTransaction
    
    LOCAL fieldLen:DWORD
    LOCAL padCount:DWORD
    LOCAL descLen:DWORD
    
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
    
    ; Get description length
    INVOKE Str_length, esi
    mov descLen, eax
    mov fieldLen, eax
    
    ; Determine how much of the description to print
    movzx ebx, descColWidth
    sub ebx, 1     ; Account for pipe character
    cmp eax, ebx
    jle print_all_desc
    
    ; Description is too long, print just the first part
    ; Copy substring to tempBuffer
    push edi
    mov edi, OFFSET tempBuffer
    mov ecx, ebx   ; Use column width minus pipe as max chars
    xor edx, edx   ; Counter

copy_substring:
    mov al, [esi+edx]
    mov [edi+edx], al
    inc edx
    cmp edx, ecx
    jl copy_substring
    
    mov BYTE PTR [edi+edx], 0  ; Null-terminate
    pop edi
    
    ; Print truncated description
    INVOKE printString, OFFSET tempBuffer
    mov fieldLen, ebx  ; Set fieldLen to max column width
    jmp skipDescPad    ; Skip padding as we filled the column
    
print_all_desc:
    INVOKE printString, esi
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
    
    ; Print second line for long description if needed
    mov eax, descLen
    movzx ebx, descColWidth
    sub ebx, 1     ; Account for pipe character
    cmp eax, ebx
    jle skip_second_line   ; Skip if description fits in one line
    
    ; Print new line and create second line for description continuation
    call Crlf
    
    ; Print padding for first column
    mov ecx, 25    ; Initial spacing
    print_initial_spaces:
        INVOKE printString, ADDR spaceChar
        loop print_initial_spaces
    
    ; Print pipe separator
    INVOKE printString, ADDR pipeChar
    
    ; Print remainder of the description
    mov esi, transaction
    add esi, OFFSET userTransaction.transaction_detail
    add esi, ebx   ; Move pointer to start where we left off
    INVOKE printString, esi
    
    ; Calculate and print padding after remainder
    INVOKE Str_length, esi
    mov fieldLen, eax
    movzx eax, descColWidth
    sub eax, fieldLen
    dec eax        ; Account for the pipe character
    mov padCount, eax
    
    ; Print padding spaces
    mov ecx, padCount
    cmp ecx, 0
    jle skip_remainder_pad
remainder_pad_loop:
    INVOKE printString, ADDR spaceChar
    loop remainder_pad_loop
skip_remainder_pad:
    
    ; Print pipe and complete the remainder of the line with proper spacing
    INVOKE printString, ADDR pipeChar
    
skip_second_line:
    ; Move to next line for next transaction
    call Crlf
    
done:    
    popad
    ret
printUserTransaction ENDP
END