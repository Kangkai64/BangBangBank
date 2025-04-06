INCLUDE BangBangBank.inc
.data
; Labels for each transaction field
idLabel       BYTE "ID: ", 0
dateLabel     BYTE "Date: ", 0
amountLabel   BYTE "Amount: ", 0
descLabel     BYTE "Description: ", 0
break         BYTE "   |   ", 0

; Totals for tracking
totalCredit   DWORD 0
totalDebit    DWORD 0

; Buffer for float conversion
floatBuffer   BYTE 16 DUP(0)

; Summary strings
creditMsg     BYTE "Total Credit: ", 0
debitMsg      BYTE "Total Debit: ", 0
balanceMsg    BYTE "Balance: ", 0
.code
;----------------------------------------------------------------------
; IntToFloatStr - Converts an integer to a floating-point string
; Receives: EAX = integer value to convert
;           EDI = pointer to output buffer
; Returns:  EDI = pointer to the output buffer containing the float string
;           EAX = length of the resulting string
; Modifies: EAX, EBX, ECX, EDX, ESI, EDI
;----------------------------------------------------------------------
IntToFloatStr PROC
    ; Preserve registers
    push ebx
    push ecx
    push edx
    push esi

    ; Save output buffer pointer
    push edi
    
    ; Check if number is negative
    mov ebx, eax            ; Save original value in EBX
    test eax, eax
    jns positive
    
    ; Handle negative number
    neg eax                 ; Make value positive
    mov byte ptr [edi], '-' ; Store minus sign
    inc edi                 ; Move buffer pointer
    
positive:
    ; Initialize for conversion
    mov ecx, 10             ; Divisor = 10
    xor esi, esi            ; ESI will count digits
    
    ; First, convert integer part to string (backwards)
    push edi                ; Save start of digits position
    
convert_loop:
    xor edx, edx            ; Clear EDX for division
    div ecx                 ; Divide EAX by 10, quotient in EAX, remainder in EDX
    add dl, '0'             ; Convert remainder to ASCII
    mov [edi], dl           ; Store digit
    inc edi                 ; Move buffer pointer
    inc esi                 ; Increment digit counter
    test eax, eax           ; Check if quotient is zero
    jnz convert_loop        ; If not zero, continue loop
    
    ; Reverse the digits
    mov eax, edi            ; EAX = end of string + 1
    dec eax                 ; EAX = last character position
    pop edi                 ; EDI = first character position
    push eax                ; Save end position for later
    
    mov ecx, esi            ; ECX = number of digits
    shr ecx, 1              ; ECX = half the number of digits
    jz end_reverse          ; If zero digits, skip reversing
    
reverse_loop:
    mov dl, [edi]           ; Get character from start
    mov bl, [eax]           ; Get character from end
    mov [edi], bl           ; Swap characters
    mov [eax], dl
    inc edi                 ; Move start pointer forward
    dec eax                 ; Move end pointer backward
    dec ecx                 ; Decrement counter
    jnz reverse_loop        ; Continue until done
    
end_reverse:
    pop edi                 ; Restore end position to EDI
    inc edi                 ; Move past last digit
    
    ; Add decimal point and zeros for floating-point representation
    mov byte ptr [edi], '.' ; Add decimal point
    inc edi                 ; Move buffer pointer
    mov byte ptr [edi], '0' ; Add first zero after decimal
    inc edi
    mov byte ptr [edi], '0' ; Add second zero after decimal
    inc edi
    mov byte ptr [edi], 0   ; Null-terminate the string
    
    ; Calculate string length
    pop edi                 ; Restore original buffer pointer
    mov eax, edi            ; Set up for length calculation
    neg eax                 ; Negate to prepare for addition
    add eax, edi            ; EAX = current position - start position = length
    
    ; Restore registers
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
IntToFloatStr ENDP
;----------------------------------------------------------------------
; This module will print all user transaction information onto the console
; Receives : The address / pointer of the user transaction structure
; Returns : Nothing
; Last update: 25/3/2025
;----------------------------------------------------------------------
calculateTotal PROC, 
    transaction: PTR userTransaction
    
    pushad
    
    mov esi, transaction
    add esi, OFFSET userTransaction.amount
    INVOKE StringtoInt, esi
    add totalCredit, eax
    mov eax,totalCredit

     ; Convert integer to float string
    lea edi, floatBuffer    ; Load address of buffer
    call IntToFloatStr      ; Convert EAX to float string
    
    ; Display the result
    lea edi, floatBuffer    ; Reload buffer address
    INVOKE printString, edi
    
done:    
    popad
    ret
calculateTotal ENDP
END