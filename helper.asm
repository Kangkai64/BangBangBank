
INCLUDE BangBangBank.inc

.data

tempNum DWORD ?

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

;--------------------------------------------------------
; Leap year calculation function
; Input: Year in AX
; Output: Carry flag set if leap year, clear otherwise
;--------------------------------------------------------
checkLeapYear PROC
    push bx
    push dx
    
    ; Divisible by 4?
    mov bx, 4
    div bx
    cmp dx, 0
    jne notLeapYear
    
    ; Divisible by 100?
    mov ax, [esp+4]  ; Restore original year
    mov bx, 100
    div bx
    cmp dx, 0
    jne isLeapYear
    
    ; Divisible by 400?
    mov ax, [esp+4]
    mov bx, 400
    div bx
    cmp dx, 0
    jne notLeapYear
    
isLeapYear:
    pop dx
    pop bx
    STC  ; Set carry flag
    ret

notLeapYear:
    pop dx
    pop bx
    CLC  ; Clear carry flag
    ret
checkLeapYear ENDP

;--------------------------------------------------------
; Helper function for precise date and time calculation
; (Leap year, different month lengths etc.)
; Increment by 5 hours with absolute precision
; Receives : ESI points to timestamp string
; Returns : Incremented timestamp in ESI
;--------------------------------------------------------
.data
; Days in each month (non-leap year)
monthLengths BYTE 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

.code
calculateDateTime PROC

; Precise timestamp increment routine
IncrementTimestamp:
    
    ; Temporary stack storage for parsed values
    sub esp, 24
    
    ; Parse year (positions 6-9)
    xor eax, eax        ; Clear accumulator
    mov edi, 6          ; Starting index
    mov ecx, 4          ; 4 digits to parse
    
parseYear:
    movzx ebx, BYTE PTR [esi+edi]  ; Load digit
    sub bl, '0'                    ; Convert to numeric value
    
    ; Multiply current accumulated value by 10
    mov edx, 10
    mul edx
    
    ; Add new digit
    add eax, ebx
    
    inc edi
    LOOP parseYear
    
    ; Store parsed year value
    mov [esp], ax
    
    ; Parse month (positions 3-4)
    mov al, [esi+3]
    sub al, '0'
    mov bl, 10
    mul bl
    mov bl, [esi+4]
    sub bl, '0'
    add al, bl
    mov [esp+4], al     ; Store month (1-12)
    
    ; Parse day (positions 0-1)
    mov al, [esi]
    sub al, '0'
    mov bl, 10
    mul bl
    mov bl, [esi+1]
    sub bl, '0'
    add al, bl
    mov [esp+5], al     ; Store day
    
    ; Parse hour (positions 11-12)
    mov al, [esi+11]
    sub al, '0'
    mov bl, 10
    mul bl
    mov bl, [esi+12]
    sub bl, '0'
    add al, bl
    mov [esp+6], al     ; Store hour
    
    ; Add 5 hours
    add byte ptr [esp+6], 5
    
    ; Check hour overflow
    cmp byte ptr [esp+6], 24
    jl noHourOverflow
    
    ; Adjust hour and increment day
    sub byte ptr [esp+6], 24
    inc byte ptr [esp+5]
    
    ; Determine max days for month
    movzx bx, byte ptr [esp+4]
    dec bx              ; 0-based index
    mov al, monthLengths[bx]
    
    ; Check for leap year in February
    cmp bx, 1           ; February
    jne checkDayOverflow
    
    ; Verify leap year
    push ax
    mov ax, [esp+2]     ; Year
    call checkLeapYear
    pop ax
    jnc checkDayOverflow
    
    ; Leap year - February has 29 days
    inc al
    
checkDayOverflow:
    ; Check if day exceeds month length
    cmp byte ptr [esp+5], al
    jle noHourOverflow
    
    ; Month overflow
    sub byte ptr [esp+5], al
    inc byte ptr [esp+4]
    
    ; Check month overflow (beyond 12)
    cmp byte ptr [esp+4], 12
    jle noHourOverflow
    
    ; Year rollover
    sub byte ptr [esp+4], 12
    inc word ptr [esp]
    
noHourOverflow:
    ; Reconstruct timestamp string with precision
    
    ; Year Reconstruction
    mov edi, 0      ; Index for year value in stack
    mov ecx, 4      ; 4 digits to process
    mov ebx, 9      ; Starting index in timestamp string
    mov ax, [esp+edi]  ; Load year from stack

buildYear:  
    push ebx
    xor edx, edx
    mov ebx, 10
    div bx                 ; Convert numeric value to ASCII
    add dl, '0'
    pop ebx                    ; Restore the index here
    mov [esi+ebx], dl          ; Store in timestamp string
    dec ebx
    LOOP buildYear

    ; Month reconstruction
    xor edx, edx
    mov al, [esp+4]
    mov bl, 10
    div bl              ; AL = tens digit, AH = ones digit
    add al, '0'
    add ah, '0'
    mov [esi+3], al
    mov [esi+4], ah
    
    ; Day reconstruction
    xor edx, edx
    mov al, [esp+5]
    cbw
    mov bl, 10
    div bl              ; AL = tens digit, AH = ones digit
    add al, '0'
    add ah, '0'
    mov [esi], al
    mov [esi+1], ah
    
    ; Hour reconstruction
    xor edx, edx
    mov al, [esp+6]
    cbw
    mov bl, 10
    div bl              ; AL = tens digit, AH = ones digit
    add al, '0'
    add ah, '0'
    mov [esi+11], al
    mov [esi+12], ah
    
    ; Cleanup stack
    add esp, 24
    ret
calculateDateTime ENDP

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
; StringToDecimal: Converts an ASCII string with decimal point to integer
; Receives: Pointer to null-terminated string containing a number with decimal point
; Returns: EAX = converted integer value (decimal part included), ESI = updated position
;--------------------------------------------------------------------------------
StringToDecimal PROC USES ebx ecx edx,
    pString: PTR BYTE
    
    LOCAL decimal_found:BYTE    ; Flag for decimal point
    LOCAL decimal_count:BYTE    ; Count of digits after decimal
    
    ; Initialize local variables
    mov decimal_found, 0
    mov decimal_count, 0
    
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
    
digit_loop:
    mov dl, [esi]           ; Get current character
    
    ; Check for end of string
    cmp dl, 0
    je check_decimal_places
    
    ; Check for decimal point
    cmp dl, '.'
    je found_decimal
    
    ; Check if it's a valid digit
    cmp dl, '0'
    jl check_decimal_places
    cmp dl, '9'
    jg check_decimal_places
    
    ; Valid digit, process it
    imul eax, 10            ; Multiply current result by 10
    sub dl, '0'             ; Convert ASCII to number
    add eax, edx            ; Add new digit
    
    ; If we're past decimal point, increment decimal counter
    cmp decimal_found, 1
    jne next_digit
    inc decimal_count
    
    ; Check if we've processed 2 decimal places already
    cmp decimal_count, 2
    je check_decimal_places  ; Stop after 2 decimal places
    
    jmp next_digit
    
found_decimal:
    mov decimal_found, 1
    jmp next_digit
    
next_digit:
    inc esi                 ; Move to next character
    jmp digit_loop
    
check_decimal_places:
    ; If we found a decimal but didn't get 2 decimal places, pad with zeros
    cmp decimal_found, 1
    jne apply_sign
    
    cmp decimal_count, 0
    je add_two_zeros
    cmp decimal_count, 1
    je add_one_zero
    jmp apply_sign
    
add_two_zeros:
    imul eax, 100           ; Multiply by 100 (add 2 zeros)
    jmp apply_sign
    
add_one_zero:
    imul eax, 10            ; Multiply by 10 (add 1 zero)
    ; Fall through to apply_sign
    
apply_sign:
    ; Apply sign if negative
    cmp ebx, 1
    jne done_parsing
    neg eax                 ; Negate if negative
    
done_parsing:
    ret
StringToDecimal ENDP


;--------------------------------------------------------------------------------
; WriteDecimalNumber: Displays an integer as a decimal number
; Receives: EAX = integer value representing decimal number 
; Returns: Nothing, displays the number with decimal point
;--------------------------------------------------------------------------------
WriteDecimalNumber PROC USES eax ebx ecx edx
    
    ; Save original number
    mov tempNum, eax
    
    ; Get whole part (divide by 100)
    mov edx, 0
    mov ebx, 100
    div ebx         ; EAX = whole part, EDX = remainder (decimal part)
    
    ; Display whole part
    call WriteDec
    
    ; Display decimal point
    mov al, '.'
    call WriteChar
    
    ; Display decimal part with leading zero if needed
    mov eax, edx    ; Get remainder (decimal part)
    
    ; Check if we need a leading zero
    cmp eax, 10
    jge write_decimal_part
    
    ; Add leading zero
    push eax
    mov al, '0'
    call WriteChar
    pop eax
    
write_decimal_part:
    call WriteDec
    
    ret
WriteDecimalNumber ENDP

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