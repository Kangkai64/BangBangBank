INCLUDE BangBangBank.INC

;--------------------------------------------------------------------------------
; This procedure generates the next transaction ID based on the latest one in the file
; If the file is empty or cannot be opened, it will start from T0001
; Receives: Pointer to buffer where the new transaction ID will be stored
; Returns: Nothing (buffer is filled with the new transaction ID)
; Last update: 01/04/2025
;--------------------------------------------------------------------------------
.data
transFileNameNew      BYTE "Users\transactionLog.txt", 0
fileHandleNew         DWORD ?
readBufferNew         BYTE 20480 DUP(?)
bytesReadNew          DWORD ?
errorMsgNew           BYTE "Error: Transaction file cannot be opened or read, starting with T0001", NEWLINE, 0
transIDPrefix         BYTE "T", 0
defaultTransID        BYTE "T0001", 0
tempTransID           BYTE 32 DUP(?)
highestTransNum       DWORD 0
newTransNum           DWORD 0
tempNumStr            BYTE 16 DUP(?)
currentDigit          DWORD ?
tempDigits            BYTE 10 DUP(?)
digitCount            DWORD ?

.code
generateTransactionID PROC,
    transIDBuffer: PTR BYTE
    
    pushad
    
    ; Open the transaction file
    INVOKE CreateFile, 
        ADDR transFileNameNew,          ; lpFileName
        GENERIC_READ,                   ; dwDesiredAccess
        FILE_SHARE_READ,                ; dwShareMode
        NULL,                           ; lpSecurityAttributes
        OPEN_EXISTING,                  ; dwCreationDisposition
        FILE_ATTRIBUTE_NORMAL,          ; dwFlagsAndAttributes
        NULL                            ; hTemplateFile
        
    mov fileHandleNew, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccessNew
    
    ; File open error or file doesn't exist, use default ID T0001
    INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
    jmp genTransIDExit
    
fileOpenSuccessNew:
    ; Read file content into buffer
    INVOKE ReadFile, 
        fileHandleNew,                 ; hFile
        ADDR readBufferNew,            ; lpBuffer
        SIZEOF readBufferNew - 1,      ; nNumberOfBytesToRead
        ADDR bytesReadNew,             ; lpNumberOfBytesRead
        NULL                           ; lpOverlapped
    
    ; Check if read was successful
    .IF eax == 0
        INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
        jmp closeFileAndExit
    .ENDIF
    
    ; Add null terminator to buffer
    mov edi, OFFSET readBufferNew
    add edi, bytesReadNew
    mov BYTE PTR [edi], 0
    
    ; Check if file is empty or too small (only header)
    cmp bytesReadNew, 30  ; Approximate minimum size for header + one record
    jb useDefaultID
    
    ; Initialize highest transaction number
    mov highestTransNum, 0
    
    ; Skip the header line
    mov esi, OFFSET readBufferNew
    
skipHeaderLoopNew:
    mov al, [esi]
    cmp al, 0           ; End of buffer?
    je processTransIDs  ; File is empty or corrupted
    cmp al, 10          ; LF - new line?
    je headerSkipped
    cmp al, 13          ; CR?
    je skipCRNew
    inc esi
    jmp skipHeaderLoopNew
    
skipCRNew:
    inc esi             ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipHeaderLoopNew
    inc esi             ; Skip LF
    
headerSkipped:
    inc esi             ; Move to first character of data line
    
processTransIDs:
    ; Process all transaction IDs in the file
    mov esi, OFFSET readBufferNew
    
findNextTransIDLoop:
    ; Check for end of buffer
    mov al, [esi]
    cmp al, 0
    je doneProcessingIDs
    
    ; Check for start of a new line (could be transaction_id field)
    cmp al, 'T'
    jne notTransIDStart
    
    ; Found potential transaction ID, copy it to tempTransID
    mov edi, OFFSET tempTransID
    mov ecx, 0   ; Counter for ID length
    
copyTransIDLoop:
    mov al, [esi]
    cmp al, ','  ; End of field?
    je endOfTransID
    cmp al, 0    ; End of buffer?
    je endOfTransID
    cmp al, 13   ; CR?
    je endOfTransID
    cmp al, 10   ; LF?
    je endOfTransID
    
    ; Copy character
    mov [edi], al
    inc edi
    inc esi
    inc ecx
    
    cmp ecx, 10  ; Reasonable max length for transaction ID
    jb copyTransIDLoop
    
    ; ID too long, skip to next line
    jmp skipToNextLineNew
    
endOfTransID:
    ; Null-terminate the ID
    mov BYTE PTR [edi], 0
    
    ; Verify it's a valid transaction ID (starts with T followed by digits)
    mov edi, OFFSET tempTransID
    cmp BYTE PTR [edi], 'T'
    jne notValidTransID
    
    ; Extract numeric part
    inc edi  ; Skip the T prefix
    
    ; Convert numeric string to integer using custom conversion
    push esi        ; Save position in main buffer
    mov esi, edi    ; Point to numeric part of transaction ID
    call StrToInt   ; Call our custom conversion function (result in EAX)
    
    ; If valid and higher than current highest, update highest
    cmp eax, highestTransNum
    jbe notValidTransID2
    mov highestTransNum, eax
    
notValidTransID2:
    pop esi         ; Restore position in main buffer
    jmp skipToNextLineNew
    
notValidTransID:
    ; Skip to next line or continue processing
    jmp skipToNextLineNew
    
notTransIDStart:
    ; Not a transaction ID start, move to next character
    inc esi
    jmp findNextTransIDLoop
    
skipToNextLineNew:
    ; Skip to the start of the next line
    mov al, [esi]
    cmp al, 0       ; End of file?
    je doneProcessingIDs
    cmp al, 10      ; LF?
    je nextLineNew
    cmp al, 13      ; CR?
    je skipToNextCRNew
    inc esi
    jmp skipToNextLineNew
    
skipToNextCRNew:
    inc esi         ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipToNextLineNew
    inc esi         ; Skip LF
    
nextLineNew:
    inc esi         ; Skip LF
    jmp findNextTransIDLoop
    
doneProcessingIDs:
    ; If no valid transaction IDs found, use default
    cmp highestTransNum, 0
    je useDefaultID
    
    ; Generate next transaction ID
    mov eax, highestTransNum
    inc eax
    mov newTransNum, eax
    
    ; Start creating the full transaction ID
    ; First, copy the "T" prefix
    INVOKE Str_copy, ADDR transIDPrefix, transIDBuffer
    
    ; Convert number to string with custom routine
    mov eax, newTransNum
    call DwordToStr     ; Convert newTransNum to string (in tempNumStr)
    
    ; Pad with zeros if needed (to maintain 4 digits)
    mov ebx, 4          ; We want 4 digits total
    sub ebx, digitCount ; Calculate how many zeros to add
    
    ; Add leading zeros if needed
    .IF ebx > 0
        mov edi, transIDBuffer
        INVOKE Str_length, edi  ; Find end of buffer (after "T")
        add edi, eax            ; Point to position after "T"
        
        ; Add leading zeros
        mov ecx, ebx
    addZeroLoop:
        mov BYTE PTR [edi], '0'
        inc edi
        loop addZeroLoop
        
        ; Null terminate
        mov BYTE PTR [edi], 0
    .ENDIF
    
    ; Concatenate the numeric part
    INVOKE Str_cat, transIDBuffer, ADDR tempNumStr
    
    jmp closeFileAndExit
    
useDefaultID:
    INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
    
closeFileAndExit:
    INVOKE CloseHandle, fileHandleNew
    
genTransIDExit:
    popad
    ret

;--------------------------------------------------------------------------------
; StrToInt - Converts a string to an integer
; Receives: ESI = pointer to null-terminated string of digits
; Returns: EAX = integer value, CF=1 if error occurred
; Affects: EAX, ECX, EDX
;--------------------------------------------------------------------------------
StrToInt:
    push ebx
    mov eax, 0      ; Initialize result
    mov ebx, 10     ; Base 10 for multiplication
    
StrToIntLoop:
    mov cl, [esi]   ; Get character
    cmp cl, 0       ; Check for end of string
    je StrToIntDone
    
    ; Verify that character is a digit
    cmp cl, '0'
    jb StrToIntError
    cmp cl, '9'
    ja StrToIntError
    
    ; Convert character to digit
    sub cl, '0'
    movzx ecx, cl
    
    ; Multiply result by 10 and add new digit
    mul ebx
    add eax, ecx
    
    ; Check for overflow
    jc StrToIntError
    
    ; Move to next character
    inc esi
    jmp StrToIntLoop
    
StrToIntError:
    stc             ; Set carry flag to indicate error
    mov eax, 0      ; Return 0 on error
    jmp StrToIntExit
    
StrToIntDone:
    clc             ; Clear carry flag to indicate success
    
StrToIntExit:
    pop ebx
    ret

;--------------------------------------------------------------------------------
; DwordToStr - Converts a DWORD to a string
; Receives: EAX = DWORD value to convert
; Returns: tempNumStr contains the string representation
;          digitCount contains the number of digits
; Affects: EAX, EBX, ECX, EDX, ESI, EDI
;--------------------------------------------------------------------------------
DwordToStr:
    push ebx
    push esi
    push edi
    
    ; Clear the buffer
    mov edi, OFFSET tempNumStr
    mov ecx, SIZEOF tempNumStr
    mov al, 0
    rep stosb
    
    ; Reset digit count
    mov digitCount, 0
    
    ; Handle special case of zero
    cmp eax, 0
    jne notZero
    
    mov BYTE PTR [OFFSET tempNumStr], '0'
    mov BYTE PTR [OFFSET tempNumStr + 1], 0
    mov digitCount, 1
    jmp DwordToStrDone
    
notZero:
    ; Convert number to digits in reverse order
    mov edi, OFFSET tempDigits
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
    mov esi, OFFSET tempDigits        ; Source (reversed digits)
    add esi, digitCount
    dec esi                           ; Point to last digit
    
    mov edi, OFFSET tempNumStr        ; Destination
    
    mov ecx, digitCount               ; Counter
    
reverseLoop:
    mov al, [esi]   ; Get digit from end
    mov [edi], al   ; Store at beginning
    dec esi
    inc edi
    loop reverseLoop
    
    ; Null terminate
    mov BYTE PTR [edi], 0
    
DwordToStrDone:
    pop edi
    pop esi
    pop ebx
    ret

generateTransactionID ENDP
END