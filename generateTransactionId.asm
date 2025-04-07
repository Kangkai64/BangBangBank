INCLUDE BangBangBank.INC

;--------------------------------------------------------------------------------
; This procedure generates the next transaction ID based on the latest one in the file
; If the file is empty or cannot be opened, it will start from T0001
; Receives: Pointer to buffer where the new transaction ID will be stored
; Returns: Nothing (buffer is filled with the new transaction ID)
; Last update: 01/04/2025
;--------------------------------------------------------------------------------
.data
transFileName         BYTE "Users\transactionLog.txt", 0
fileHandle            DWORD ?
readBuffer            BYTE 20480 DUP(?)
bytesRead             DWORD ?
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
        ADDR transFileName,          ; lpFileName
        GENERIC_READ,                   ; dwDesiredAccess
        FILE_SHARE_READ,                ; dwShareMode
        NULL,                           ; lpSecurityAttributes
        OPEN_EXISTING,                  ; dwCreationDisposition
        FILE_ATTRIBUTE_NORMAL,          ; dwFlagsAndAttributes
        NULL                            ; hTemplateFile
        
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccess
    
    ; File open error or file doesn't exist, use default ID T0001
    INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
    jmp genTransIDExit
    
fileOpenSuccess:
    ; Read file content into buffer
    INVOKE ReadFile, 
        fileHandle,                 ; hFile
        ADDR readBuffer,            ; lpBuffer
        SIZEOF readBuffer - 1,      ; nNumberOfBytesToRead
        ADDR bytesRead,             ; lpNumberOfBytesRead
        NULL                           ; lpOverlapped
    
    ; Check if read was successful
    .IF eax == 0
        INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
        jmp closeFileAndExit
    .ENDIF
    
    ; Add null terminator to buffer
    mov edi, OFFSET readBuffer
    add edi, bytesRead
    mov BYTE PTR [edi], 0
    
    ; Check if file is empty or too small (only header)
    cmp bytesRead, 30  ; Approximate minimum size for header + one record
    jb useDefaultID
    
    ; Initialize highest transaction number
    mov highestTransNum, 0
    
    ; Skip the header line
    mov esi, OFFSET readBuffer
    
skipHeaderLoop:
    mov al, [esi]
    cmp al, 0           ; End of buffer?
    je processTransIDs  ; File is empty or corrupted
    cmp al, 10          ; LF - new line?
    je headerSkipped
    cmp al, 13          ; CR?
    je skipCR
    inc esi
    jmp skipHeaderLoop
    
skipCR:
    inc esi             ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipHeaderLoop
    inc esi             ; Skip LF
    
headerSkipped:
    inc esi             ; Move to first character of data line

processTransIDs:
    
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
    jmp skipToNextLine
    
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
    push esi                  ; Save position in main buffer
    INVOKE StringToInt, edi   ; Call our custom conversion function (result in EAX)
    
    ; If valid and higher than current highest, update highest
    cmp eax, highestTransNum
    jbe notValidTransID2
    mov highestTransNum, eax
    
notValidTransID2:
    pop esi         ; Restore position in main buffer
    jmp skipToNextLine
    
notValidTransID:
    ; Skip to next line or continue processing
    jmp skipToNextLine
    
notTransIDStart:
    ; Not a transaction ID start, move to next character
    inc esi
    jmp findNextTransIDLoop
    
skipToNextLine:
    ; Skip to the start of the next line
    mov al, [esi]
    cmp al, 0       ; End of file?
    je doneProcessingIDs
    cmp al, 10      ; LF?
    je nextLine
    cmp al, 13      ; CR?
    je skipToNextCR
    inc esi
    jmp skipToNextLine
    
skipToNextCR:
    inc esi         ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipToNextLine
    inc esi         ; Skip LF
    
nextLine:
    inc esi         ; Skip LF
    jmp findNextTransIDLoop
    
doneProcessingIDs:
    ; If no valid transaction IDs found, use default
    cmp highestTransNum, 0
    je useDefaultID
    
    ; Generate next transaction ID
    mov eax, highestTransNum
    inc eax
    add eax, 2 ; Don't know why it wouldn't read the last two value
    mov newTransNum, eax
    
    ; Start creating the full transaction ID
    ; First, copy the "T" prefix
    INVOKE Str_copy, ADDR transIDPrefix, transIDBuffer
    
    ; Convert number to string with custom routine
    INVOKE DwordToStr, newTransNum    ; Convert newTransNum to string (in tempNumStr)
    
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
    INVOKE Str_cat, ADDR tempNumStr, transIDBuffer
    
    jmp closeFileAndExit
    
useDefaultID:
    INVOKE Str_copy, ADDR defaultTransID, transIDBuffer
    
closeFileAndExit:
    INVOKE CloseHandle, fileHandle
    
genTransIDExit:
    popad
    ret

generateTransactionID ENDP
END