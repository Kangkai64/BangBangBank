
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
    call formatNumberToString
    
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
    call formatNumberToString
    
    ; Add slash
    mov BYTE PTR [edi], '/'
    inc edi
    
    ; Format year
    movzx eax, WORD PTR [esi].SYSTEMTIME.wYear
    
    ; For year we need to handle 4 digits
    mov temp, eax
    mov ebx, 1000  ; Divisor for thousands place
    
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
    call formatNumberToString
    
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
    call formatNumberToString
    
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
    call formatNumberToString
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    popad
    ret
formatSystemTime ENDP

;-----------------------------------------------------------------------
; Helper function to format a number as a string
; Receives: EAX = number to format, EDI = destination buffer
; Returns: EDI = updated position in buffer after the formatted number
;-----------------------------------------------------------------------
formatNumberToString PROC USES eax ebx edx
    
    ; Handle single digit case separately
    cmp eax, 10
    jae twoOrMoreDigits
    
    ; Single digit
    add al, '0'     ; Convert to ASCII
    mov [edi], al   ; Store the character
    inc edi         ; Move pointer
    jmp formatNumberDone
    
twoOrMoreDigits:
    ; Convert to ASCII digits
    mov ebx, 10     ; Divisor
    
    ; For values >=10 we need to handle recursively
    cmp eax, 100
    jae threeOrMoreDigits
    
    ; Two digits
    div bl          ; AL = tens, AH = units
    add al, '0'     ; Convert tens to ASCII
    mov [edi], al   ; Store tens digit
    inc edi         ; Move pointer
    
    mov al, ah      ; Move units to AL
    add al, '0'     ; Convert units to ASCII
    mov [edi], al   ; Store units digit
    inc edi         ; Move pointer
    jmp formatNumberDone
    
threeOrMoreDigits:
    ; Handle larger numbers if needed
    xor edx, edx    ; Clear EDX for division
    div ebx         ; EAX = quotient, EDX = remainder
    
    ; Recursively format the quotient
    call formatNumberToString
    
    ; Format the remainder
    mov eax, edx
    add al, '0'     ; Convert to ASCII
    mov [edi], al   ; Store the character
    inc edi         ; Move pointer
    
formatNumberDone:
    ret
formatNumberToString ENDP

;--------------------------------------------------------------------------------
; Helper function to parse a number from a string
; Receives: ESI pointing to start of number
; Returns: EAX = parsed number, ESI = updated position
;--------------------------------------------------------------------------------
parseNumber PROC USES ebx edx
    
    xor eax, eax  ; Clear result
    xor ebx, ebx  ; Digit counter
    
parseDigits:
    mov dl, [esi]
    cmp dl, '0'
    jl endNumber
    cmp dl, '9'
    jg endNumber
    
    ; Valid digit, process it
    imul eax, 10      ; Multiply current result by 10
    sub dl, '0'       ; Convert ASCII to number
    add eax, edx      ; Add new digit
    inc esi           ; Move to next character
    inc ebx           ; Increment digit counter
    jmp parseDigits
    
endNumber:
    ; If no digits were found, return 0
    cmp ebx, 0
    jne parseNumberDone
    xor eax, eax      ; Return 0
    
parseNumberDone:
    ret
parseNumber ENDP

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

;--------------------------------------------------------------------------
; Str_cat : Concatenates two strings
; Receives: EDX - Pointer to destination string (null-terminated)
;           EAX - Pointer to source string to append (null-terminated)
; Returns : EDX - Pointer to the resulting concatenated string
;--------------------------------------------------------------------------
Str_cat PROC USES esi edi
    
    mov esi, eax    ; Source string
    mov edi, edx    ; Destination string
    
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