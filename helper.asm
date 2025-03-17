
INCLUDE BangBangBank.inc

.code
;--------------------------------------------------------------------------
; Helper function to format system time into a string (DD/MM/YYYY HH:MM:SS)
;--------------------------------------------------------------------------
formatSystemTime PROC,
    systemTimePtr:PTR SYSTEMTIME,
    outputBuffer:PTR BYTE
    
    LOCAL temp:DWORD
    
    pushad
    
    ; Get the system time structure pointer
    mov esi, systemTimePtr
    mov edi, outputBuffer
    
    ; Format day (with leading zero if needed)
    movzx eax, WORD PTR [esi].SYSTEMTIME.wDay
    cmp eax, 10
    jae dayTwoDigits
    
    ; Single digit day, add leading zero
    mov BYTE PTR [edi], '0'
    inc edi
    
dayTwoDigits:
    movzx eax, WORD PTR [esi].SYSTEMTIME.wDay
    call IntToString
    
    ; Add slash
    mov BYTE PTR [edi], '/'
    inc edi
    
    ; Format month (with leading zero if needed)
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMonth
    cmp eax, 10
    jae monthTwoDigits
    
    ; Single digit month, add leading zero
    mov BYTE PTR [edi], '0'
    inc edi
    
monthTwoDigits:
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMonth
    call IntToString
    
    ; Add slash
    mov BYTE PTR [edi], '/'
    inc edi
    
    ; Format year
    movzx eax, WORD PTR [esi].SYSTEMTIME.wYear
    
    ; For year we need to handle 4 digits
    mov temp, eax
    mov ebx, 1000  ; Divisor for thousands place
    xor edx, edx
    
    ; Convert each digit
    mov eax, temp
    div ebx         ; EAX = thousands digit, EDX = remainder
    add al, '0'     ; Convert to ASCII
    mov [edi], al   ; Store digit
    inc edi
    
    mov eax, edx    ; Move remainder to EAX
    mov ebx, 100    ; Divisor for hundreds place
    xor edx, edx    ; Clear EDX for division
    div ebx         ; EAX = hundreds digit, EDX = remainder
    add al, '0'     ; Convert to ASCII
    mov [edi], al   ; Store digit
    inc edi
    
    mov eax, edx    ; Move remainder to EAX
    mov ebx, 10     ; Divisor for tens place
    xor edx, edx    ; Clear EDX for division
    div ebx         ; EAX = tens digit, EDX = remainder
    add al, '0'     ; Convert to ASCII
    mov [edi], al   ; Store digit
    inc edi
    
    add dl, '0'     ; Convert ones digit to ASCII
    mov [edi], dl   ; Store digit
    inc edi
    
    ; Add space
    mov BYTE PTR [edi], ' '
    inc edi
    
    ; Format hour (with leading zero if needed)
    movzx eax, WORD PTR [esi].SYSTEMTIME.wHour
    cmp eax, 10
    jae hourTwoDigits
    
    ; Single digit hour, add leading zero
    mov BYTE PTR [edi], '0'
    inc edi
    
hourTwoDigits:
    movzx eax, WORD PTR [esi].SYSTEMTIME.wHour
    call IntToString
    
    ; Add colon
    mov BYTE PTR [edi], ':'
    inc edi
    
    ; Format minute (with leading zero if needed)
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMinute
    cmp eax, 10
    jae minuteTwoDigits
    
    ; Single digit minute, add leading zero
    mov BYTE PTR [edi], '0'
    inc edi
    
minuteTwoDigits:
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMinute
    call IntToString
    
    ; Add colon
    mov BYTE PTR [edi], ':'
    inc edi
    
    ; Format second (with leading zero if needed)
    movzx eax, WORD PTR [esi].SYSTEMTIME.wSecond
    cmp eax, 10
    jae secondTwoDigits
    
    ; Single digit second, add leading zero
    mov BYTE PTR [edi], '0'
    inc edi
    
secondTwoDigits:
    movzx eax, WORD PTR [esi].SYSTEMTIME.wSecond
    call IntToString
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    popad
    ret
formatSystemTime ENDP

;--------------------------------------------------------------------------------
; StringToInt: Converts an ASCII string to integer (supports signed integers)
; Receives: Pointer to null-terminated string containing a number
; Returns: EAX = converted integer value, ESI = updated position
;--------------------------------------------------------------------------------
StringToInt PROC USES ebx edx,
    pString: PTR BYTE
    
    ; Set up pointer to string
    mov esi, pString
    
    ; Check for negative sign
    xor ebx, ebx            ; EBX = sign flag (0 = positive)
    mov al, [esi]
    cmp al, '-'
    jne parse_digits
    
    ; Set negative flag and skip the sign
    mov ebx, 1
    inc esi
    
parse_digits:
    xor eax, eax            ; Clear result
    xor edx, edx            ; Digit counter
    
digit_loop:
    mov dl, [esi]
    cmp dl, '0'
    jl end_parse
    cmp dl, '9'
    jg end_parse
    
    ; Valid digit, process it
    imul eax, 10            ; Multiply current result by 10
    sub dl, '0'             ; Convert ASCII to number
    add eax, edx            ; Add new digit
    inc esi                 ; Move to next character
    inc ebx                 ; Increment digit counter
    jmp digit_loop
    
end_parse:
    ; If no digits were found, return 0
    cmp ebx, 1              ; Check if we only saw the negative sign
    jnz apply_sign
    cmp ebx, 0              ; Or if we saw nothing at all
    jnz apply_sign
    xor eax, eax            ; Return 0
    
apply_sign:
    ; Apply sign if negative
    cmp ebx, 1
    jne done_parsing
    neg eax                 ; Negate if negative
    
done_parsing:
    ret
StringToInt ENDP

;--------------------------------------------------------------------------------
; IntToString: Converts an integer to an ASCII string
; Receives: EAX = number to format, EDI = destination buffer
; Returns: EDI = updated position in buffer after the formatted number
;--------------------------------------------------------------------------------
IntToString PROC USES eax ebx ecx edx
    
    ; Check for negative number
    test eax, eax
    jns format_positive     ; Jump if not negative
    
    ; Handle negative number
    neg eax                 ; Make positive
    mov BYTE PTR [edi], '-' ; Add negative sign
    inc edi                 ; Move pointer past sign
    
format_positive:
    ; Determine number of digits needed
    mov ecx, eax            ; Save original number
    mov ebx, 10             ; Base 10
    
    ; First, count digits by repeatedly dividing by 10
    mov edx, 1              ; Start with at least 1 digit
    push edx                ; Save digit count on stack
    
    test eax, eax
    jz single_digit         ; Special case for 0
    
count_digits:
    cmp eax, 10
    jb done_counting
    xor edx, edx
    div ebx                 ; EAX = quotient, EDX = remainder
    inc DWORD PTR [esp]     ; Increment digit count on stack
    test eax, eax
    jnz count_digits
    
done_counting:
    pop ecx                 ; ECX = digit count
    mov eax, ecx            ; Restore original number
    
    ; Now generate digits from right to left
    add edi, ecx            ; Move to end position + 1
    mov BYTE PTR [edi], 0   ; Null-terminate the string
    dec edi                 ; Move to last digit position
    
    ; Handle 0 separately
    test eax, eax
    jnz digit_conversion
    mov BYTE PTR [edi], '0'
    inc edi
    jmp conversion_done
    
digit_conversion:
    ; Convert each digit, from right to left
    mov ecx, eax            ; Save number
    
gen_digits:
    xor edx, edx
    div ebx                 ; EAX = quotient, EDX = remainder
    add dl, '0'             ; Convert to ASCII
    mov [edi], dl           ; Store digit
    dec edi                 ; Move left
    test eax, eax
    jnz gen_digits          ; Continue if more digits
    
conversion_done:
    ret

single_digit:
    ; Handle single digit case (0-9)
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Store the character
    inc edi                 ; Move pointer
    jmp conversion_done
    
IntToString ENDP

;--------------------------------------------------------------------------------
; ParseCSVField: Parse the next field from the CSV format
; Receives: ESI = pointer to source buffer, EDI = pointer to destination buffer
; Returns: ESI = updated pointer position, EDI = updated with next field
;--------------------------------------------------------------------------------
parseCSVField PROC USES eax ecx edx
    ; Parse until comma or newline
    parseLoop:
        mov al, [esi]
        cmp al, 0         ; End of buffer?
        je endOfField
        cmp al, ','        ; Comma?
        je fieldEnd
        cmp al, 13         ; CR?
        je endOfLine
        cmp al, 10         ; LF?
        je endOfLine
        
        ; Copy character
        mov [edi], al
        inc esi
        inc edi
        jmp parseLoop
        
    fieldEnd:
        ; Skip comma
        inc esi
        INVOKE Str_trim, edi, " "
        jmp terminateField
        
    endOfLine:
        ; Handle CR/LF
        cmp al, 13        ; If CR
        jne skipJustLF
        inc esi           ; Skip CR
        cmp BYTE PTR [esi], 10  ; Check for LF
        jne terminateField
        inc esi           ; Skip LF
        jmp terminateField
        
    skipJustLF:
        inc esi           ; Skip LF
        
    endOfField:
        ; End of buffer reached
        
    terminateField:
        mov BYTE PTR [edi], 0  ; Add null terminator
        
    parseFieldDone:
        ret
parseCSVField ENDP

;-------------------------------------------------------------------------------------
; convertHexToString - Converts binary data to a hex string representation
; Receives: 
;   - source: PTR BYTE - Pointer to source binary data
;   - destination: PTR BYTE - Pointer to destination buffer for hex string
;   - byteCount: DWORD - Number of bytes to convert (optional, if 0 will assume null-terminated)
; Returns: 
;   - EAX = number of characters written to destination (excluding null terminator)
; Notes:
;   - Destination buffer must be at least (byteCount*2)+1 bytes to accommodate the string and null terminator
;   - Each byte becomes two hex characters in the output string
; Example: [0x1A, 0xF3] becomes "1AF3"
;-------------------------------------------------------------------------------------
.data
hexChars BYTE "0123456789ABCDEF",0

.code
convertHexToString PROC USES ebx ecx edx esi edi,
    source: PTR BYTE,
    destination: PTR BYTE,
    byteCount: DWORD

    LOCAL bytesProcessed:DWORD
    
    mov bytesProcessed, 0
    mov esi, source          ; Source pointer
    mov edi, destination     ; Destination pointer
    mov ecx, byteCount       ; Byte count
    
    ; If byteCount is 0, count bytes until null terminator
    .IF ecx == 0
        push esi
        call Str_length      ; Get length of source
        mov ecx, eax         ; Set byte count
        pop esi
    .ENDIF
    
    ; If no bytes to process, return empty string
    .IF ecx == 0
        mov BYTE PTR [edi], 0
        mov eax, 0
        ret
    .ENDIF
    
    ; Process each byte
processLoop:
    movzx eax, BYTE PTR [esi]  ; Get current byte
    mov ebx, eax
    
    ; Get high nibble (first hex digit)
    shr eax, 4                  ; Shift right by 4 bits
    and eax, 0Fh                ; Mask to get only low nibble
    lea edx, hexChars           ; Load hex character array address
    movzx eax, BYTE PTR [edx+eax] ; Get corresponding hex char
    mov [edi], al               ; Store first hex char
    inc edi
    
    ; Get low nibble (second hex digit)
    mov eax, ebx
    and eax, 0Fh                ; Mask to get only low nibble
    movzx eax, BYTE PTR [edx+eax] ; Get corresponding hex char
    mov [edi], al               ; Store second hex char
    inc edi
    
    ; Move to next byte
    inc esi
    inc bytesProcessed
    dec ecx
    jnz processLoop
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    ; Return number of characters written (2 per byte)
    mov eax, bytesProcessed
    shl eax, 1                  ; Multiply by 2
    
    ret
convertHexToString ENDP

;--------------------------------------------------------------------------
; Str_cat : Concatenates two strings
; Receives: EDX - Pointer to destination string (null-terminated)
;           EAX - Pointer to source string to append (null-terminated)
; Returns : EDX - Pointer to the resulting concatenated string
;--------------------------------------------------------------------------
Str_cat PROC USES esi edi,
    sourceString : PTR BYTE,
    targetString : PTR BYTE
    
    mov esi, sourceString    ; Source string
    mov edi, targetString    ; Target string
    
    ; Find the end of the destination string
    .WHILE BYTE PTR [edi] != 0
        inc edi
    .ENDW
    
    ; Copy the source string to the end of the destination
    .WHILE BYTE PTR [esi] != 0
        mov al, BYTE PTR [esi]
        mov BYTE PTR [edi], al
        inc esi
        inc edi
    .ENDW
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    ret
Str_cat ENDP
END