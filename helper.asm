
INCLUDE BangBangBank.inc

.code
;--------------------------------------------------------
; Helper function to format system time into a timestamp 
; string (DD/MM/YYYY HH:MM:SS)
;--------------------------------------------------------
formatSystemTime PROC,
    systemTimePtr:PTR SYSTEMTIME,
    outputBuffer:PTR BYTE
    
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
    mov al, BYTE PTR [esi].SYSTEMTIME.wDay
    add al, '0'        ; Convert to ASCII
    mov [edi], al      ; Store digit
    inc edi
    jmp dayDone
    
dayTwoDigits:
    ; Two digit day - handle directly
    movzx eax, WORD PTR [esi].SYSTEMTIME.wDay
    mov ebx, 10
    xor edx, edx
    div ebx            ; EAX = tens, EDX = ones
    add al, '0'        ; Convert tens to ASCII
    mov [edi], al      ; Store tens digit
    inc edi
    mov eax, edx
    add al, '0'        ; Convert ones to ASCII
    mov [edi], al      ; Store ones digit
    inc edi
    
dayDone:
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
    mov al, BYTE PTR [esi].SYSTEMTIME.wMonth
    add al, '0'        ; Convert to ASCII
    mov [edi], al      ; Store digit
    inc edi
    jmp monthDone
    
monthTwoDigits:
    ; Two digit month - handle directly
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMonth
    mov ebx, 10
    xor edx, edx
    div ebx            ; EAX = tens, EDX = ones
    add al, '0'        ; Convert tens to ASCII
    mov [edi], al      ; Store tens digit
    inc edi
    mov eax, edx
    add al, '0'        ; Convert ones to ASCII
    mov [edi], al      ; Store ones digit
    inc edi
    
monthDone:
    ; Add slash
    mov BYTE PTR [edi], '/'
    inc edi
    
    ; Format year
    movzx eax, WORD PTR [esi].SYSTEMTIME.wYear
    
    ; For year we need to handle 4 digits
    ; Thousands place
    mov ebx, 1000
    xor edx, edx
    div ebx                 ; EAX = thousands, EDX = remainder
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Store digit
    inc edi
    
    ; Hundreds place
    mov eax, edx
    mov ebx, 100
    xor edx, edx
    div ebx                 ; EAX = hundreds, EDX = remainder
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Store digit
    inc edi
    
    ; Tens place
    mov eax, edx
    mov ebx, 10
    xor edx, edx
    div ebx                 ; EAX = tens, EDX = remainder
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Store digit
    inc edi
    
    ; Ones place
    mov eax, edx
    add al, '0'             ; Convert to ASCII
    mov [edi], al           ; Store digit
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
    mov al, BYTE PTR [esi].SYSTEMTIME.wHour
    add al, '0'        ; Convert to ASCII
    mov [edi], al      ; Store digit
    inc edi
    jmp hourDone
    
hourTwoDigits:
    ; Two digit hour - handle directly
    movzx eax, WORD PTR [esi].SYSTEMTIME.wHour
    mov ebx, 10
    xor edx, edx
    div ebx            ; EAX = tens, EDX = ones
    add al, '0'        ; Convert tens to ASCII
    mov [edi], al      ; Store tens digit
    inc edi
    mov eax, edx
    add al, '0'        ; Convert ones to ASCII
    mov [edi], al      ; Store ones digit
    inc edi
    
hourDone:
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
    mov al, BYTE PTR [esi].SYSTEMTIME.wMinute
    add al, '0'        ; Convert to ASCII
    mov [edi], al      ; Store digit
    inc edi
    jmp minuteDone
    
minuteTwoDigits:
    ; Two digit minute - handle directly
    movzx eax, WORD PTR [esi].SYSTEMTIME.wMinute
    mov ebx, 10
    xor edx, edx
    div ebx            ; EAX = tens, EDX = ones
    add al, '0'        ; Convert tens to ASCII
    mov [edi], al      ; Store tens digit
    inc edi
    mov eax, edx
    add al, '0'        ; Convert ones to ASCII
    mov [edi], al      ; Store ones digit
    inc edi
    
minuteDone:
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
    mov al, BYTE PTR [esi].SYSTEMTIME.wSecond
    add al, '0'        ; Convert to ASCII
    mov [edi], al      ; Store digit
    inc edi
    jmp secondDone
    
secondTwoDigits:
    ; Two digit second - handle directly
    movzx eax, WORD PTR [esi].SYSTEMTIME.wSecond
    mov ebx, 10
    xor edx, edx
    div ebx            ; EAX = tens, EDX = ones
    add al, '0'        ; Convert tens to ASCII
    mov [edi], al      ; Store tens digit
    inc edi
    mov eax, edx
    add al, '0'        ; Convert ones to ASCII
    mov [edi], al      ; Store ones digit
    inc edi
    
secondDone:
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    popad
    ret
formatSystemTime ENDP

;--------------------------------------------------------------------------------
; This module will clear the user credential structure for each loop
; Receives: Address / Pointer the user credential structure
; Returns: Nothing
;--------------------------------------------------------------------------------
clearUserCredential PROC USES edi ecx,
    pUser:PTR userCredential
    
    mov edi, pUser            
    mov ecx, SIZEOF userCredential
    mov al, 0                 
    rep stosb                 
    
    ret
clearUserCredential ENDP

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
    xor edx, edx
    xor ecx, ecx            ; Digit counter
    
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
    inc ecx                 ; Increment digit counter
    jmp digit_loop
    
end_parse:
    ; If no digits were found, return 0
    cmp ebx, 1              ; Check if we only saw the negative sign
    jle apply_sign
    cmp ebx, 0              ; Or if we saw nothing at all
    jle apply_sign
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
; ParseCSVField PROC
; Parse the next field from the CSV format and trim leading/trailing spaces
; Receives: ESI = pointer to source buffer, EDI = pointer to destination buffer
; Returns: ESI = updated pointer position, trimmed field stored in destination buffer
;--------------------------------------------------------------------------------
parseCSVField PROC USES eax ecx edx
    LOCAL tempPtr:DWORD
    
    ; Save starting position of destination buffer
    mov tempPtr, edi
    
    ; Parse until comma or newline
    parseLoop:
        mov al, [esi]
        cmp al, 0          ; End of buffer?
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
        
        ; Trim both leading and trailing spaces from the field
        push esi                ; Save ESI as Str_trim might modify it
        mov edi, tempPtr       ; Pass the start of our buffer to Str_trim
        INVOKE myStr_trim, edi, " "  ; This should trim both leading and trailing spaces
        pop esi                 ; Restore ESI
        
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

;------------------------------------------------------------------
; Str_trim : Remove all occurrences of a given delimiter character
;            from both the beginning and end of a string.
; Receives : The address / pointer to the string
; Returns: nothing
;------------------------------------------------------------------
myStr_trim PROC USES eax ecx esi edi,
    pString:PTR BYTE,
    char: BYTE           

    LOCAL originalLen:DWORD

    ; Step 1: Check for empty string
    mov esi,pString      ; ESI = source pointer
    INVOKE Str_length,esi ; returns the length in EAX
    cmp eax,0            ; is the length equal to zero?
    je trimFinish        ; yes: exit now
    mov originalLen,eax  ; store original length

    ; Step 2: Find first non-delimiter character
    mov edi,pString      ; EDI = destination pointer
    mov ecx,eax          ; ECX = string length
    mov esi,pString      ; ESI = source pointer (start of string)

SkipLeading:
    mov al,[esi]         ; get a character from source
    cmp al,0             ; check for end of string
    je EndOfString       ; if end of string, all chars are delimiters
    cmp al,char          ; is it the delimiter?
    jne TrimTrailing     ; no: move to trimming trailing delimiters
    inc esi              ; yes: skip this character
    dec ecx              ; decrement count
    jnz SkipLeading      ; continue if not end of string

EndOfString:
    ; If we get here, the string only contained delimiters
    mov edi,pString      ; point back to start
    mov BYTE PTR [edi],0 ; make it an empty string
    jmp trimFinish

TrimTrailing:
    ; Step 3: Find the position of the last non-delimiter character
    mov edi,pString
    add edi,originalLen  ; point to position after the last character
    dec edi              ; point to the last character

FindLastChar:
    mov al,[edi]         ; get character from end
    cmp al,char          ; is it the delimiter?
    jne CopyString       ; no: found last non-delimiter
    dec edi              ; yes: move backward
    dec ecx              ; decrement count
    jnz FindLastChar     ; continue if not beginning of string

    ; If we get here, we've checked the entire string
    ; and every character is a delimiter, make it empty
    mov edi,pString
    mov BYTE PTR [edi],0
    jmp trimFinish

CopyString:
    ; Step 4: Copy characters from start position to end position
    INVOKE Str_copy, esi, pString

trimFinish:
    ret
myStr_trim ENDP
END