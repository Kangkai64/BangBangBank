
INCLUDE BangBangBank.inc

;-----------------------------------------------------------------------
; This function writes updated user credentials to a file
; Receives: Pointer to userCredential structure
; Returns: EAX = 1 if successful, 0 if failed
; Last update: 15/3/2025
;-----------------------------------------------------------------------

.data
outputFileName BYTE "users.txt", 0
tempFileName BYTE "temp.txt", 0
fileHandle HANDLE ?
tempFileHandle HANDLE ?
bytesWritten DWORD ?
bufferSize = 512
buffer BYTE bufferSize DUP(?)
lineBuffer BYTE bufferSize DUP(?)
usernameMatch BYTE 0
usernameSeparator BYTE ":", 0
bufferLineSize = 1024
lineToWrite BYTE bufferLineSize DUP(?)
myCrlf BYTE 13, 10, 0    ; CR, LF, null terminator

.code
outputToFile PROC,
    userPtr:PTR userCredential
    
    pushad
    
    ; Open the existing file for reading
    INVOKE CreateFile, 
        ADDR outputFileName,
        GENERIC_READ,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    mov fileHandle, eax
    
    ; Check if file was opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccess
    
    ; File open failed
    mov eax, 0
    mov [esp+28], eax  ; Return 0 in EAX
    jmp outputToFileExit
    
fileOpenSuccess:
    ; Create a temporary file for writing
    INVOKE CreateFile,
        ADDR tempFileName,
        GENERIC_WRITE,
        0,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    mov tempFileHandle, eax
    
    ; Check if temp file was created successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne tempFileCreateSuccess
    
    ; Close the input file
    INVOKE CloseHandle, fileHandle
    
    ; File create failed
    mov eax, 0
    mov [esp+28], eax  ; Return 0 in EAX
    jmp outputToFileExit
    
tempFileCreateSuccess:
    ; Start reading the file line by line
    mov usernameMatch, 0
    
readNextLine:
    ; Read a line from the file
    INVOKE ReadFile,
        fileHandle,
        ADDR buffer,
        bufferSize,
        ADDR bytesWritten,
        NULL
    
    ; Check if we reached the end of file
    cmp bytesWritten, 0
    je endOfFile
    
    ; Process the buffer
    mov esi, OFFSET buffer
    mov edi, OFFSET lineBuffer
    xor ecx, ecx  ; Character count
    
processBuffer:
    cmp ecx, bytesWritten
    jae readNextLine
    
    ; Get the current character
    mov al, [esi+ecx]
    inc ecx
    
    ; Check for line end
    cmp al, 13  ; Carriage return
    je endOfLine
    cmp al, 10  ; Line feed
    je endOfLine
    
    ; Add character to line buffer
    mov [edi], al
    inc edi
    jmp processBuffer
    
endOfLine:
    ; Null-terminate the line
    mov BYTE PTR [edi], 0
    
    ; Check if this is the username we're looking for
    mov esi, OFFSET lineBuffer
    mov edi, userPtr
    
    ; Compare the username
    call compareUsernames
    
    ; If match, write updated user data
    cmp usernameMatch, 1
    je writeUpdatedUser
    
    ; If no match, write the original line
    INVOKE WriteFile,
        tempFileHandle,
        ADDR lineBuffer,
        LENGTHOF lineBuffer,
        ADDR bytesWritten,
        NULL
    
    ; Write CRLF
    INVOKE WriteFile,
        tempFileHandle,
        ADDR myCrlf,
        2,                  ; Exclude null terminator
        ADDR bytesWritten,
        NULL
    
    jmp readNextLine
    
writeUpdatedUser:
    ; Format the updated user data
    INVOKE formatUserData, userPtr, ADDR lineToWrite
    
    ; Write the updated line
    INVOKE WriteFile,
        tempFileHandle,
        ADDR lineToWrite,
        LENGTHOF lineToWrite,
        ADDR bytesWritten,
        NULL
    
    ; Write CRLF
    INVOKE WriteFile,
        tempFileHandle,
        ADDR myCrlf,
        2,                  ; Exclude null terminator
        ADDR bytesWritten,
        NULL
    
    jmp readNextLine
    
endOfFile:
    ; Close both files
    INVOKE CloseHandle, fileHandle
    INVOKE CloseHandle, tempFileHandle
    
    ; Return success
    mov eax, 1
    mov [esp+28], eax  ; Return 1 in EAX
    
outputToFileExit:
    popad
    ret
outputToFile ENDP

;-----------------------------------------------------------------------
; Helper function to compare usernames
; Receives: ESI = line buffer, EDI = user structure
; Returns: Sets usernameMatch to 1 if match found, 0 otherwise
;-----------------------------------------------------------------------
compareUsernames PROC USES eax ebx ecx edx esi edi
    
    ; Save the original line buffer position
    mov ebx, esi
    
    ; Point to the username in the structure
    mov edi, [edi]  ; Get the username from the structure
    
    ; Compare usernames
compareLoop:
    mov al, [esi]
    mov dl, [edi]
    
    ; Check for end of username (colon or null)
    cmp al, ':'
    je endOfUsername
    cmp al, 0
    je endOfUsername
    
    ; Compare characters
    cmp al, dl
    jne usernamesDiffer
    
    ; Move to next character
    inc esi
    inc edi
    jmp compareLoop
    
endOfUsername:
    ; Check if we've reached the end of the username in the structure
    cmp dl, 0
    jne usernamesDiffer
    
    ; We found a match
    mov usernameMatch, 1
    jmp compareUsernameDone
    
usernamesDiffer:
    mov usernameMatch, 0
    
compareUsernameDone:
    ret
compareUsernames ENDP

;-----------------------------------------------------------------------
; Helper function to format user data for output
; Receives: Pointer to user structure, Pointer to output buffer
; Returns: Formatted user data in the output buffer
;-----------------------------------------------------------------------
formatUserData PROC,
    userPtr:PTR userCredential,
    outputBuffer:PTR BYTE
    
    pushad
    
    ; Get pointers to the data
    mov esi, userPtr
    mov edi, outputBuffer
    
    ; Format: username:password:encryptionKey:loginAttempt:firstLoginAttemptTimestamp
    
    ; Copy username
    mov esi, [userPtr]
    call copyStringToBuffer
    
    ; Add separator
    mov al, ':'
    mov [edi], al
    inc edi
    
    ; Copy password
    mov esi, [userPtr + 4]  ; Offset to password field
    call copyStringToBuffer
    
    ; Add separator
    mov al, ':'
    mov [edi], al
    inc edi
    
    ; Copy encryption key
    mov esi, [userPtr + 8]  ; Offset to encryptionKey field
    call copyStringToBuffer
    
    ; Add separator
    mov al, ':'
    mov [edi], al
    inc edi
    
    ; Copy login attempt count
    mov esi, [userPtr + 12]  ; Offset to loginAttempt field
    call copyStringToBuffer
    
    ; Add separator
    mov al, ':'
    mov [edi], al
    inc edi
    
    ; Copy first login attempt timestamp
    mov esi, [userPtr + 16]  ; Offset to firstLoginAttemptTimestamp field
    call copyStringToBuffer
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    popad
    ret
formatUserData ENDP

;-----------------------------------------------------------------------
; Helper function to copy a string to the buffer
; Receives: ESI = source string, EDI = destination buffer
; Returns: EDI = updated position in the buffer
;-----------------------------------------------------------------------
copyStringToBuffer PROC
    push eax
    
copyLoop:
    mov al, [esi]
    cmp al, 0
    je copyDone
    
    mov [edi], al
    inc esi
    inc edi
    jmp copyLoop
    
copyDone:
    pop eax
    ret
copyStringToBuffer ENDP
END