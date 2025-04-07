INCLUDE BangBangBank.INC

;--------------------------------------------------------------------------------
; This procedure generates the next transaction ID based on the latest one in the file
; If the file is empty or cannot be opened, it will start from T0001
; Receives: Pointer to buffer where the new transaction ID will be stored
; Returns: Nothing (buffer is filled with the new transaction ID)
; Last update: 07/04/2025
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
digitCount            DWORD ?
commaChar             BYTE ",", 0

.code
generateTransactionID PROC,
    transIDBuffer: PTR BYTE
    
    pushad
    
    ; Open the transaction file
    INVOKE CreateFile, 
        ADDR transFileName,          ; lpFileName
        GENERIC_READ,                ; dwDesiredAccess
        FILE_SHARE_READ,             ; dwShareMode
        NULL,                        ; lpSecurityAttributes
        OPEN_EXISTING,               ; dwCreationDisposition
        FILE_ATTRIBUTE_NORMAL,       ; dwFlagsAndAttributes
        NULL                         ; hTemplateFile
        
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
        fileHandle,                  ; hFile
        ADDR readBuffer,             ; lpBuffer
        SIZEOF readBuffer - 1,       ; nNumberOfBytesToRead
        ADDR bytesRead,              ; lpNumberOfBytesRead
        NULL                         ; lpOverlapped
    
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
    
    ; Point to start of file content
    mov esi, OFFSET readBuffer
    
    ; Skip the header line (first line of the CSV file)
skipHeaderLine:
    mov al, [esi]
    cmp al, 0           ; End of buffer?
    je processComplete  ; File is empty
    cmp al, 10          ; LF - new line?
    je foundHeaderEnd
    cmp al, 13          ; CR?
    je checkCRLF
    inc esi
    jmp skipHeaderLine
    
checkCRLF:
    inc esi             ; Skip CR
    mov al, [esi]
    cmp al, 10          ; Check for LF
    jne skipHeaderLine  ; If not LF, continue checking
    
foundHeaderEnd:
    inc esi             ; Move past the newline character
    
    ; Now process each line, looking for transaction IDs
processLines:
    mov al, [esi]
    cmp al, 0           ; End of buffer?
    je processComplete
    
    ; Check if line starts with 'T' followed by digits (likely a transaction ID)
    cmp al, 'T'
    jne skipToNextLine
    
    ; Found a potential transaction ID, capture it
    mov edi, OFFSET tempTransID
    mov ecx, 0          ; Counter for ID length
    
captureTransID:
    mov al, [esi]
    cmp al, ','         ; End of field (comma)?
    je endOfTransID
    cmp al, 0           ; End of buffer?
    je processComplete
    cmp al, 13          ; CR?
    je endOfTransID
    cmp al, 10          ; LF?
    je endOfTransID
    
    ; Copy character to temp buffer
    mov [edi], al
    inc edi
    inc esi
    inc ecx
    
    cmp ecx, 31         ; Prevent buffer overflow
    jge skipToNextLine
    jmp captureTransID
    
endOfTransID:
    ; Null-terminate the captured ID
    mov BYTE PTR [edi], 0
    
    ; Only process if it's a valid transaction ID (starts with T followed by digits)
    mov edi, OFFSET tempTransID
    cmp BYTE PTR [edi], 'T'
    jne notValidTransID
    
    ; Skip 'T' prefix
    inc edi
    
    ; Check if the rest are digits
    push esi            ; Save current position in file buffer
    
    ; Convert numeric part to integer
    INVOKE StringToInt, edi
    
    ; Compare with highest transaction number found so far
    cmp eax, highestTransNum
    jle notHigherTransID
    
    ; Found new highest transaction number
    mov highestTransNum, eax
    
notHigherTransID:
    pop esi             ; Restore position in file buffer
    
notValidTransID:
    ; Move to next line
skipToNextLine:
    ; Skip to the start of the next line
    mov al, [esi]
    cmp al, 0           ; End of buffer?
    je processComplete
    cmp al, 10          ; LF?
    je nextLine
    cmp al, 13          ; CR?
    je skipCR
    inc esi
    jmp skipToNextLine
    
skipCR:
    inc esi             ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipToNextLine
    inc esi             ; Skip LF
    jmp processLines    ; Continue from next line
    
nextLine:
    inc esi             ; Skip LF
    jmp processLines    ; Continue from next line
    
processComplete:
    ; If no valid transaction IDs found, use default
    cmp highestTransNum, 0
    je useDefaultID
    
    ; Generate next transaction ID
    mov eax, highestTransNum
    inc eax             ; Increment to get next ID number
    mov newTransNum, eax
    
    ; Start creating the full transaction ID
    ; First, copy the "T" prefix
    INVOKE Str_copy, ADDR transIDPrefix, transIDBuffer
    
    ; Convert number to string
    INVOKE DwordToStr, newTransNum, ADDR tempNumStr
    mov digitCount, eax
    
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