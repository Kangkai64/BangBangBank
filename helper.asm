
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
    LOCAL temp[12]: BYTE    ; Temporary buffer for digits (max 10 digits + sign + null)
    LOCAL isNeg: BYTE
    
    ; Check for negative number
    mov isNeg, 0
    test eax, eax
    jns positive_number
    
    ; Handle negative
    mov isNeg, 1
    neg eax
    
positive_number:
    ; Use a temporary buffer to build the string backwards
    lea ebx, temp
    add ebx, 11            ; Point to end of buffer
    mov BYTE PTR [ebx], 0  ; Null terminate
    dec ebx
    
    ; Special case for 0
    test eax, eax
    jnz not_zero
    
    mov BYTE PTR [ebx], '0'
    dec ebx
    jmp prepare_output
    
not_zero:
    ; Convert digits
    mov ecx, 10            ; Base 10
    
digit_loop:
    xor edx, edx
    div ecx                ; EAX = quotient, EDX = remainder
    add dl, '0'            ; Convert to ASCII
    mov [ebx], dl          ; Store digit
    dec ebx                ; Move left
    test eax, eax
    jnz digit_loop         ; Continue if more digits
    
prepare_output:
    ; Add negative sign if needed
    cmp isNeg, 1
    jne copy_to_output
    mov BYTE PTR [ebx], '-'
    dec ebx
    
copy_to_output:
    ; Copy from temp buffer to output buffer
    inc ebx                ; Point to first character
    
copy_loop:
    mov al, [ebx]
    mov [edi], al
    inc ebx
    inc edi
    test al, al            ; Check for null terminator
    jnz copy_loop
    
    ret
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
    
    ; Add a space
    mov al, ' '
    mov [edi], al
    inc edi

    ; Move to next byte
    inc esi
    inc bytesProcessed
    dec ecx
    jnz processLoop
    
    ; Add null terminator
    dec edi ; Remove extra space
    mov BYTE PTR [edi], 0
    
    ; Return number of characters written (2 per byte)
    mov eax, bytesProcessed
    shl eax, 1                  ; Multiply by 2
    
    ret
convertHexToString ENDP

;--------------------------------------------------------------------------
; Str_cat : Concatenates two strings
; Receives: targetString - Pointer to destination string (null-terminated)
;           sourceString - Pointer to source string to append (null-terminated)
; Returns : EDI - Pointer to the resulting concatenated string
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
; Receives : The address / pointer to the string and the character
;            to be trimmed
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

;--------------------------------------------------------------------------------
; DwordToStr - Converts a DWORD to a string
; Receives: DWORD value to convert and pointer / address to store the stringVal
; Returns: stringVal contains the string representation
;          EAX contains the number of digits
;--------------------------------------------------------------------------------
DwordToStr PROC USES ebx esi edi,
    dwordVal: DWORD,
    stringVal: PTR BYTE

    LOCAL tempDigits[10]:BYTE
    LOCAL digitCount:DWORD

    ; Clear the buffer
    mov edi, stringVal
    mov ecx, SIZEOF stringVal
    mov al, 0
    rep stosb
    
    ; Reset digit count
    mov digitCount, 0
    
    ; Handle special case of zero
    mov eax, dwordVal
    cmp eax, 0
    jne notZero
    
    mov BYTE PTR [stringVal], '0'
    mov BYTE PTR [stringVal + 1], 0
    mov digitCount, 1
    jmp DwordToStrDone
    
notZero:
    ; Convert number to digits in reverse order
    lea edi, tempDigits
    mov ebx, 10     ; Divisor
    
extractDigitLoop:
    xor edx, edx    ; Clear high part of dividend
    div ebx         ; EDX:EAX / 10, quotient in EAX, remainder in EDX
    
    ; Convert remainder to ASCII and store
    add dl, '0'
    mov [edi], dl
    inc edi
    
    ; Increment digit count
    inc digitCount
    
    ; Continue if quotient is not zero
    test eax, eax
    jnz extractDigitLoop
    
    ; Reverse the digits to get correct order
    lea esi, tempDigits        ; Source (reversed digits)
    add esi, digitCount
    dec esi                    ; Point to last digit
    
    mov edi, stringVal         ; Destination
    
    mov ecx, digitCount        ; Counter
    
reverseLoop:
    mov al, [esi]   ; Get digit from end
    mov [edi], al   ; Store at beginning
    dec esi
    inc edi
    loop reverseLoop
    
    ; Null terminate
    mov BYTE PTR [edi], 0

    ; Return the digitCount in EAX
    mov eax, digitCount
    
DwordToStrDone:
    ret

DwordToStr ENDP

;------------------------------------------------------------------------
; Str_find - Finds a substring within a string
; 
; Receives: ESI = pointer to the source string
;           EDI = pointer to the substring to find
; 
; Returns:  EAX = position of the substring in source (0-based)
;                 or 0 if the substring was not found
;------------------------------------------------------------------------
Str_find PROC USES ebx ecx edx esi edi,
    sourceStr: PTR BYTE,    ; Pointer to the source string
    subString: PTR BYTE        ; Pointer to substring to find
    
    LOCAL sourceLen: DWORD,
          subLen: DWORD,
          pos: DWORD
    
    ; Get the length of both strings
    mov esi, sourceStr
    INVOKE Str_length, esi
    mov sourceLen, eax
     
    mov esi, subString
    INVOKE Str_length, esi
    mov subLen, eax
    
    ; If substring is empty or longer than source, return 0 (not found)
    .IF eax == 0 || eax > sourceLen
        mov eax, 0
        jmp done
    .ENDIF
    
    ; Initialize position counter
    mov pos, 0
    
    ; Set up pointers
    mov esi, sourceStr
    
search_loop:
    ; Check if we've reached the end of possible matches
    mov eax, sourceLen
    sub eax, subLen
    .IF pos > eax
        mov eax, 0      ; Not found, return 0
        jmp done
    .ENDIF
    
    ; Try to match substring at current position
    mov edi, subString
    mov ecx, subLen     ; Match length
    mov ebx, pos        ; Get current position
    mov edx, sourceStr
    add edx, ebx        ; Point to current position in source
    
    push esi
    push edi
    mov esi, edx        ; Source pointer at current position
    
    ; Compare strings
    repe cmpsb
    
    pop edi
    pop esi
    
    ; If ECX is 0, then all characters matched
    .IF ecx == 0
        mov eax, pos    ; Return the position where substring was found
        inc eax         ; Convert to 1-based index
        jmp done
    .ENDIF
    
    ; Move to next position in source
    inc pos
    jmp search_loop
    
done:
    ret
Str_find ENDP

;------------------------------------------------------------------------
; This module validates and formats decimal transaction input
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
;           Formats the input for use with decimalArithmetic (without decimal point)
; Last update: 7/4/2025
;------------------------------------------------------------------------
.data
    invalidDecimalMsg BYTE "Invalid decimal format. Please use format like 1000.56", NEWLINE, 0
    tooManyDecimalsMsg BYTE "Please enter no more than 2 decimal places.", NEWLINE, 0
    tempInputBuffer BYTE 32 DUP(0)    ; Temporary buffer for formatting
    
.code
validateDecimalInput PROC,
    inputAddress: PTR BYTE
    
    LOCAL hasDecimal: BYTE        ; Flag for decimal point found
    LOCAL decimalCount: BYTE      ; Count of digits after decimal
    LOCAL resultBuffer[32]: BYTE  ; Buffer for formatted result
    
    pushad
    
    ; Initialize local variables
    mov hasDecimal, 0
    mov decimalCount, 0
    
    ; Clear result buffer
    lea edi, resultBuffer
    mov ecx, 32
    mov al, 0
    rep stosb
    
    ; Get input string length
    INVOKE Str_length, inputAddress
    mov ecx, eax                  ; Length in ECX
    
    ; Validate characters and structure
    mov esi, inputAddress         ; Source string
    lea edi, resultBuffer    ; Destination buffer (without decimal point)
    
    xor edx, edx                  ; Counter for valid digits
    
validate_char_loop:
    mov al, [esi]                 ; Get current character
    
    ; Check for decimal point
    cmp al, '.'
    je process_decimal_point
    
    ; Check if it's a digit
    cmp al, '0'
    jl invalid_char
    cmp al, '9'
    jg invalid_char
    
    ; It's a valid digit, copy to result (without decimal point)
    mov [edi], al
    inc edi
    inc edx                       ; Increment valid digit counter
    
    ; Update decimal counter if we're past the decimal point
    cmp hasDecimal, 1
    jne next_char
    inc decimalCount
    
    ; Ensure max 2 digits after decimal
    cmp decimalCount, 3
    jge too_many_decimals
    
next_char:
    inc esi
    loop validate_char_loop
    jmp format_result
    
process_decimal_point:
    ; Check if we already found a decimal point
    cmp hasDecimal, 1
    je invalid_char               ; Multiple decimal points not allowed
    
    mov hasDecimal, 1
    inc esi
    dec ecx
    jmp validate_char_loop
    
invalid_char:
    INVOKE printString, ADDR invalidDecimalMsg
    STC                           ; Set carry flag for error
    jmp done
    
too_many_decimals:
    INVOKE printString, ADDR tooManyDecimalsMsg
    STC                           ; Set carry flag for error
    jmp done
    
format_result:
    ; Add null terminator to result
    mov BYTE PTR [edi], 0
    
    ; If no decimal was entered, append "00"
    cmp hasDecimal, 0
    jne check_decimal_count
    
    ; Append "00" for cents
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], 0
    jmp copy_to_input
    
check_decimal_count:
    ; Check if we need to pad with zeros
    cmp decimalCount, 0
    je add_two_zeros              ; No decimals entered after point (e.g., "100.")
    cmp decimalCount, 1
    je add_one_zero               ; One decimal entered (e.g., "100.5")
    jmp copy_to_input             ; Two decimals entered (e.g., "100.56")
    
add_two_zeros:
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], 0
    jmp copy_to_input
    
add_one_zero:
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], 0
    
copy_to_input:
    ; Copy formatted result back to input address
    INVOKE Str_copy, ADDR resultBuffer, inputAddress
    
    ; Clear carry flag to indicate success
    CLC
    
done:
    popad
    ret
validateDecimalInput ENDP

;------------------------------------------------------------------------
; This module handles conversion between string representations with decimal
; points and the internal format needed for decimal arithmetic operations
; Last update: 08/04/2025
;------------------------------------------------------------------------
.data
    tempNumBuffer BYTE 32 DUP(0)
    minusSign BYTE "-", 0
    plusSign BYTE "+", 0

.code
;------------------------------------------------------------------------
; Converts a string with decimal point to a string without decimal point
; Receives: 
;   - sourceStr: PTR to source string (e.g., "2500.12")
;   - destStr: PTR to destination buffer
; Returns:
;   - destStr contains formatted string without decimal point (e.g., "250012")
;------------------------------------------------------------------------
removeDecimalPoint PROC,
    sourceStr: PTR BYTE,
    destStr: PTR BYTE
    
    LOCAL hasSign: BYTE
    
    pushad

    ; Initialize sign status
    mov hasSign, 0
    
    ; Point to source and destination
    mov esi, sourceStr
    mov edi, destStr
    
    ; Check if there's a sign at the beginning
    mov al, [esi]
    cmp al, '+'
    je handle_sign
    cmp al, '-'
    jne copy_loop
    
handle_sign:
    ; Store the sign in the destination
    mov [edi], al
    inc edi
    inc esi
    mov hasSign, 1
    
copy_loop:
    ; Get current character
    mov al, [esi]
    
    ; Check if end of string
    cmp al, 0
    je done
    
    ; Check if decimal point
    cmp al, '.'
    je skip_decimal
    
    ; Copy character to destination
    mov [edi], al
    inc edi
    
skip_decimal_continue:
    inc esi
    jmp copy_loop
    
skip_decimal:
    inc esi
    jmp copy_loop
    
done:
    ; Null-terminate the destination string
    mov BYTE PTR [edi], 0

    popad
    ret
removeDecimalPoint ENDP

;------------------------------------------------------------------------
; Converts a string without decimal point to a string with decimal point
; Receives: 
;   - sourceStr: PTR to source string (e.g., "250012")
;   - destStr: PTR to destination buffer
; Returns:
;   - destStr contains formatted string with decimal point (e.g., "2500.12")
;------------------------------------------------------------------------
addDecimalPoint PROC,
    sourceStr: PTR BYTE,
    destStr: PTR BYTE
    
    LOCAL sourceLength: DWORD
    LOCAL hasSign: BYTE
    
    pushad

    ; Initialize sign status
    mov hasSign, 0
    
    ; Get string length
    INVOKE Str_length, sourceStr
    mov sourceLength, eax
    
    ; Check if string has a sign
    mov esi, sourceStr
    mov al, [esi]
    cmp al, '+'
    je has_sign
    cmp al, '-'
    jne no_sign
    
has_sign:
    mov hasSign, 1
    dec sourceLength    ; Adjust length for the sign
    
no_sign:
    ; Point to destination
    mov edi, destStr
    
    ; If there's a sign, copy it first
    .IF hasSign == 1
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
    .ENDIF
    
    ; Check if we need to add leading zero for values less than 1
    .IF sourceLength < 3
        mov BYTE PTR [edi], '0'
        inc edi
        mov BYTE PTR [edi], '.'
        inc edi
        
        ; Add leading zeros if needed
        .IF sourceLength == 1
            mov BYTE PTR [edi], '0'
            inc edi
        .ENDIF
        
        ; Copy rest of digits
        mov ecx, sourceLength
        rep movsb
    .ELSE
        ; Calculate position for decimal point
        mov ecx, sourceLength
        sub ecx, 2    ; Position before last two digits
        
        ; Copy digits before decimal point
        mov ebx, ecx
        rep movsb
        
        ; Add decimal point
        mov BYTE PTR [edi], '.'
        inc edi
        
        ; Copy last two digits
        mov ecx, 2
        rep movsb
    .ENDIF
    
    ; Null-terminate the destination string
    mov BYTE PTR [edi], 0

    popad
    ret
addDecimalPoint ENDP

;------------------------------------------------------------------------
; Processes a transaction amount from the transaction log
; Receives:
;   - transactionAmount: PTR to transaction amount string (e.g., "+852.33" or "-723.45")
;   - formattedAmount: PTR to output buffer (for formatted amount without decimal)
; Returns:
;   - formattedAmount contains the amount without decimal point
;   - AL contains the operation ('+' or '-')
;------------------------------------------------------------------------
processTransactionAmount PROC USES ebx ecx edx esi edi,
    transactionAmount: PTR BYTE,
    formattedAmount: PTR BYTE
    
    ; Initialize
    mov esi, transactionAmount
    mov edi, formattedAmount
    
    ; Check first character for sign
    mov al, [esi]
    
    ; Store the operation
    mov bl, al
    
    ; Skip the sign in the input
    inc esi
    
    ; Process the rest of the string (remove decimal point)
    mov ecx, 0    ; Initialize counter
    
copy_digits:
    mov al, [esi]
    
    ; Check if end of string
    cmp al, 0
    je add_padding
    
    ; Check if decimal point
    cmp al, '.'
    je skip_point
    
    ; Copy digit to output
    mov [edi], al
    inc edi
    inc ecx
    
next_digit:
    inc esi
    jmp copy_digits
    
skip_point:
    inc esi
    jmp copy_digits
    
add_padding:
    ; Check if we need to add padding zeros
    cmp ecx, 0
    je add_zeros
    
    ; If we have fewer than 2 digits after decimal point, add zeros
    mov al, 0    ; Null-terminate
    mov [edi], al
    
    ; Return the operation sign in AL
    mov al, bl
    ret
    
add_zeros:
    ; Add zeros if needed
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], 0
    
    ; Return the operation sign in AL
    mov al, bl
    ret
processTransactionAmount ENDP

;------------------------------------------------------------------------
; A more comprehensive decimal arithmetic function that supports both
; addition and subtraction of decimal numbers
; Receives:
;   - num1: PTR to first number (without decimal point)
;   - num2: PTR to second number (without decimal point)
;   - result: PTR to result buffer
;   - operation: BYTE ('+' = addition, '-' = subtraction)
; Returns:
;   - result contains the formatted result string without decimal point
;------------------------------------------------------------------------
decimalArithmetic PROC USES eax ebx ecx edx esi edi,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE,
    operation: BYTE
    
    LOCAL num1Val: DWORD
    LOCAL num2Val: DWORD
    LOCAL resultVal: DWORD
    LOCAL isNegative: BYTE
    
    ; Initialize negative flag
    mov isNegative, 0
    
    ; Check for signs in num1
    mov esi, num1
    mov al, [esi]
    mov num1Val, 0
    
    cmp al, '+'
    je positive_num1
    cmp al, '-'
    jne convert_num1

    ; Negative num1
    mov isNegative, 1
    
positive_num1:
    inc esi        ; Skip the sign
    
convert_num1:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num1Val, eax
    pop esi
    
    ; If num1 was negative, negate value
    .IF isNegative == 1
        neg num1Val
    .ENDIF
    
    ; Reset negative flag for num2
    mov isNegative, 0
    
    ; Check for signs in num2
    mov esi, num2
    mov al, [esi]
    mov num2Val, 0
    
    cmp al, '+'
    je positive_num2
    cmp al, '-'
    jne convert_num2

    ; Negative num2
    mov isNegative, 1
    
positive_num2:
    inc esi        ; Skip the sign
    
convert_num2:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num2Val, eax
    pop esi
    
    ; If num1 was negative, negate value
    .IF isNegative == 1
        neg num2Val
    .ENDIF

    ; Perform arithmetic based on operation
    mov eax, num1Val
    
    cmp operation, '+'
    jne subtract_operation
    
    ; Addition
    add eax, num2Val
    jmp format_result
    
subtract_operation:
    ; Subtraction
    sub eax, num2Val
    
format_result:
    ; Check if result is negative
    mov isNegative, 0
    cmp eax, 0
    jge positive_result
    
    ; Handle negative result
    mov isNegative, 1
    neg eax
    
positive_result:
    ; eax now contains absolute value of result
    mov resultVal, eax
    
    ; Convert to string
    mov edi, result
    
    ; Add sign if negative
    .IF isNegative == 1
        mov BYTE PTR [edi], '-'
        inc edi
    .ENDIF
    
    ; Convert integer to string
    mov eax, resultVal
    call IntToString
    
    ret
decimalArithmetic ENDP

;------------------------------------------------------------------------
; Decimal multiplication function
; Multiplies two decimal numbers represented as strings
; Receives:
;   - num1: PTR to first number (without decimal point)
;   - num2: PTR to second number (without decimal point)
;   - result: PTR to result buffer
; Returns:
;   - result contains the formatted result string without decimal point
;------------------------------------------------------------------------
decimalMultiply PROC USES eax ebx ecx edx esi edi,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE
    
    LOCAL num1Val: DWORD
    LOCAL num2Val: DWORD
    LOCAL resultVal: DWORD
    LOCAL isNegative: BYTE
    
    ; Initialize negative flag
    mov isNegative, 0
    
    ; Check for signs in num1
    mov esi, num1
    mov al, [esi]
    mov num1Val, 0
    
    cmp al, '+'
    je positive_num1
    cmp al, '-'
    jne check_num1_done
    
    ; Negative num1
    mov isNegative, 1
    inc esi        ; Skip the sign
    jmp convert_num1
    
positive_num1:
    inc esi        ; Skip the sign
    
check_num1_done:
    
convert_num1:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num1Val, eax
    pop esi
    
    ; Check for signs in num2
    mov esi, num2
    mov al, [esi]
    mov num2Val, 0
    
    cmp al, '+'
    je positive_num2
    cmp al, '-'
    jne check_num2_done
    
    ; Negative num2 - toggle isNegative
    .IF isNegative == 1
        mov isNegative, 0    ; Two negatives make a positive
    .ELSE
        mov isNegative, 1    ; One negative makes result negative
    .ENDIF
    inc esi        ; Skip the sign
    jmp convert_num2
    
positive_num2:
    inc esi        ; Skip the sign
    
check_num2_done:
    
convert_num2:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num2Val, eax
    pop esi
    
    ; Perform multiplication
    mov eax, num1Val
    mov ebx, num2Val
    mul ebx         ; EDX:EAX = EAX * EBX
    
    ; For simplicity, we'll assume the result fits in EAX
    ; In a real implementation, you'd need to handle overflow
    
    ; Check if result is negative based on sign flag
    .IF isNegative == 1
        neg eax     ; Negate the result if needed
    .ENDIF
    
    mov resultVal, eax
    
    ; Convert to string
    mov edi, result
    
    ; Add sign if negative
    .IF isNegative == 1
        mov BYTE PTR [edi], '-'
        inc edi
    .ENDIF
    
    ; Convert integer to string
    mov eax, resultVal
    call IntToString
    
    ret
decimalMultiply ENDP

;------------------------------------------------------------------------
; Decimal division function
; Divides two decimal numbers represented as strings
; Receives:
;   - num1: PTR to first number (dividend, without decimal point)
;   - num2: PTR to second number (divisor, without decimal point)
;   - result: PTR to result buffer
; Returns:
;   - result contains the formatted result string without decimal point
;   - EAX contains 0 if successful, 1 if division by zero attempted
;------------------------------------------------------------------------
decimalDivide PROC USES ebx ecx edx esi edi,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE
    
    LOCAL num1Val: DWORD
    LOCAL num2Val: DWORD
    LOCAL resultVal: DWORD
    LOCAL isNegative: BYTE
    LOCAL remainder: DWORD
    
    ; Initialize negative flag
    mov isNegative, 0
    
    ; Check for signs in num1
    mov esi, num1
    mov al, [esi]
    mov num1Val, 0
    
    cmp al, '+'
    je positive_num1
    cmp al, '-'
    jne check_num1_done
    
    ; Negative num1
    mov isNegative, 1
    inc esi        ; Skip the sign
    jmp convert_num1
    
positive_num1:
    inc esi        ; Skip the sign
    
check_num1_done:
    
convert_num1:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num1Val, eax
    pop esi
    
    ; Check for signs in num2
    mov esi, num2
    mov al, [esi]
    mov num2Val, 0
    
    cmp al, '+'
    je positive_num2
    cmp al, '-'
    jne check_num2_done
    
    ; Negative num2 - toggle isNegative
    .IF isNegative == 1
        mov isNegative, 0    ; Two negatives make a positive
    .ELSE
        mov isNegative, 1    ; One negative makes result negative
    .ENDIF
    inc esi        ; Skip the sign
    jmp convert_num2
    
positive_num2:
    inc esi        ; Skip the sign
    
check_num2_done:
    
convert_num2:
    ; Convert string to integer
    push esi
    INVOKE StringToInt, esi
    mov num2Val, eax
    pop esi
    
    ; Check for division by zero
    cmp eax, 0
    jne perform_division
    
    ; Handle division by zero
    mov edi, result
    mov BYTE PTR [edi], 'E'  ; Error indicator
    mov BYTE PTR [edi+1], 'r'
    mov BYTE PTR [edi+2], 'r'
    mov BYTE PTR [edi+3], 'o'
    mov BYTE PTR [edi+4], 'r'
    mov BYTE PTR [edi+5], 0   ; Null terminator
    mov eax, 1               ; Return error code
    jmp division_done
    
perform_division:
    ; Perform division
    mov eax, num1Val
    mov ebx, num2Val
    mov edx, 0               ; Clear EDX for division
    div ebx                  ; EAX = quotient, EDX = remainder
    
    mov resultVal, eax
    mov remainder, edx       ; Store remainder if needed for further processing
    
    ; Check if result is negative based on sign flag
    .IF isNegative == 1
        neg eax     ; Negate the result if needed
        mov resultVal, eax
    .ENDIF
    
    ; Convert to string
    mov edi, result
    
    ; Add sign if negative
    .IF isNegative == 1
        mov BYTE PTR [edi], '-'
        inc edi
    .ENDIF
    
    ; Convert integer to string
    mov eax, resultVal
    call IntToString
    
    mov eax, 0               ; Return success code
    
division_done:
    ret
decimalDivide ENDP
END