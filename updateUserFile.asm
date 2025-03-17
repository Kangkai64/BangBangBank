
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module updates user credentials in the credentials file
; Receives: User credential structure
; Returns : Carry flag is set if failed, clear if successful
; Last update: 16/3/2025
;--------------------------------------------------------------------------------
.data
; File handling variables
tempCredentialFile   BYTE "Users\userCredential.tmp", 0  ; Temporary file for writing
credentialSourceFile BYTE "Users\userCredential.txt", 0  ; Source file to read from
fileReadHandle       DWORD ?
fileWriteHandle      DWORD ?
bytesRead            DWORD ?
bytesWritten         DWORD ?

; Buffers
readLineBuffer       BYTE 1024 DUP(?)  ; Buffer for reading lines
tempUserBuffer       BYTE 512 DUP(?)   ; Buffer for extracted username
outputBuffer         BYTE 2048 DUP(?)  ; Buffer for writing
eolMarker            BYTE NEWLINE, 0   ; End of line marker
timeStampFormat      BYTE "%02d/%02d/%04d %02d:%02d:%02d",0

; Messages
fileReadErrorMsg     BYTE "Error: Could not open user credentials file for reading", 0
fileWriteErrorMsg    BYTE "Error: Could not open temporary file for writing", 0
fileCopyErrorMsg     BYTE "Error: Could not copy updated file back to original", 0
fileRenameErrorMsg   BYTE "Error: Could not rename temporary file", 0
fileDeleteErrorMsg   BYTE "Error: Could not delete original file", 0
headerLine           BYTE "username,hashed_password,hashed_PIN,customer_id,encryption_key,loginAttempt,firstLoginAttemptTimestamp", NEWLINE, 0
commaChar            BYTE ",", 0
zeroVal              BYTE "0", 0
dashVal              BYTE "-", 0
currTime             SYSTEMTIME <>     ; For timestamp

.code
;--------------------------------------------------------------------------------
; updateUserFile PROC
; Updates user record in the credentials file
; Receives: Pointer to userCredential structure
; Returns: EAX = 1 if successful, 0 if failed
;--------------------------------------------------------------------------------
updateUserFile PROC,
    user: PTR userCredential
    
    LOCAL userFound:BYTE

    pushad
    
    ; Initialize userFound flag
    mov userFound, 0

    ; Open source file for reading
    INVOKE CreateFile,
        ADDR credentialSourceFile,
        GENERIC_READ,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    
    ; Save handle
    mov fileReadHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne readFileOpened
    
    ; File open error
    INVOKE printString, ADDR fileReadErrorMsg
    call Crlf
    STC  ; Return failure
    jmp updateExit
    
readFileOpened:
    ; Create temporary file for writing
    INVOKE CreateFile,
        ADDR tempCredentialFile,
        GENERIC_WRITE,
        0,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    
    ; Save handle
    mov fileWriteHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne processNextLine
    
    ; File open error
    INVOKE printString, ADDR fileWriteErrorMsg
    call Crlf
    
    ; Close read handle
    INVOKE CloseHandle, fileReadHandle
    STC ; Return failure
    jmp updateExit
    
    ; Process file line by line
processNextLine:
    ; Initialize read line buffer
    mov edi, OFFSET readLineBuffer
    mov BYTE PTR [edi], 0
    
    ; Read a line from the file
    call ReadLineFromFile
    
    ; Check for EOF
    cmp bytesRead, 0
    je processingComplete
    
    ; Extract username from line (first field before comma)
    mov esi, OFFSET readLineBuffer
    mov edi, OFFSET tempUserBuffer
    call parseCSVField
    
    ; Compare with username from user struct
    mov edi, user
    add edi, OFFSET userCredential.username
    INVOKE Str_compare, ADDR tempUserBuffer, edi
    
    ; If usernames match, write our updated record instead
    jnz writeOriginalLine
    
    ; Username matched, mark as found
    mov userFound, 1
    
    ; Format user data line
    mov edi, OFFSET outputBuffer
    mov BYTE PTR [edi], 0   ; Start with empty string
    
    ; Add username
    mov edx, user
    add edx, OFFSET userCredential.username
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add hashed_password
    mov edx, user
    add edx, OFFSET userCredential.hashed_password
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add hashed_pin
    mov edx, user
    add edx, OFFSET userCredential.hashed_pin
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add customer_id
    mov edx, user
    add edx, OFFSET userCredential.customer_id
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add encryption_key
    mov edx, user
    add edx, OFFSET userCredential.encryption_key
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add loginAttempt from user structure
    mov edx, user
    add edx, OFFSET userCredential.loginAttempt
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add firstLoginAttemptTimestamp
    mov edx, user
    add edx, OFFSET userCredential.firstLoginAttemptTimestamp
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ; Add newline
    mov eax, OFFSET eolMarker
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ; Write updated line to file
    INVOKE Str_length, ADDR outputBuffer
    mov ecx, eax                         
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR outputBuffer,
        ecx,                             
        ADDR bytesWritten,
        NULL
    
    jmp processNextLine
    
writeOriginalLine:
    ; Write original line unchanged + newline if needed
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR readLineBuffer,
        bytesRead,
        ADDR bytesWritten,
        NULL
        
    ; Check if the line already ends with newline
    mov esi, OFFSET readLineBuffer
    add esi, bytesRead
    dec esi
    cmp BYTE PTR [esi], 10  ; LF
    je processNextLine      ; Already has newline
    
    ; Add newline if needed
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR eolMarker,
        SIZEOF eolMarker - 1,  ; Exclude null terminator
        ADDR bytesWritten,
        NULL
    
    jmp processNextLine
    
processingComplete:
    
fileUpdated:
    ; Close both files
    INVOKE CloseHandle, fileReadHandle
    INVOKE CloseHandle, fileWriteHandle
    
    ; Replace original file with updated file
    ; First, try to delete the original file
    INVOKE DeleteFile, ADDR credentialSourceFile
    
    ; Check if delete was successful
    .IF eax == 0
        INVOKE printString, ADDR fileDeleteErrorMsg
        call Crlf
        STC ; Return failure
        jmp updateExit
    .ENDIF
    
    ; Rename temp file to original filename
    INVOKE MoveFile, ADDR tempCredentialFile, ADDR credentialSourceFile
    
    ; Check if rename was successful
    .IF eax == 0
        INVOKE printString, ADDR fileRenameErrorMsg
        call Crlf
        STC  ; Return failure
        jmp updateExit
    .ENDIF
    
    ; Success
    CLC ; Return success
    
updateExit:
    popad
    
    ; Return success flag
    CLC
    ret
updateUserFile ENDP

;--------------------------------------------------------------------------------
; ReadLineFromFile PROC
; Reads a line from the file into readLineBuffer
; Receives: fileReadHandle - global variable with file handle
; Returns: bytesRead - number of bytes read, buffer filled
;--------------------------------------------------------------------------------
ReadLineFromFile PROC USES eax ebx ecx edx esi edi
    LOCAL charBuffer:BYTE
    LOCAL charBytesRead:DWORD
    
    ; Initialize
    mov bytesRead, 0
    mov edi, OFFSET readLineBuffer
    
readCharLoop:
    ; Read a single character
    INVOKE ReadFile,
        fileReadHandle,
        ADDR charBuffer,
        1,
        ADDR charBytesRead,
        NULL
    
    ; Check for EOF
    mov eax, charBytesRead
    cmp eax, 0
    je endOfReadLine
    
    ; Check for CR (13)
    cmp charBuffer, 13
    je checkForLF
    
    ; Check for LF (10) alone
    cmp charBuffer, 10
    je endOfLine
    
    ; Regular character, store it and continue
    mov al, charBuffer
    mov [edi], al
    inc edi
    inc bytesRead
    jmp readCharLoop
    
checkForLF:
    ; We found CR, peek ahead for LF
    INVOKE ReadFile,
        fileReadHandle,
        ADDR charBuffer,
        1,
        ADDR charBytesRead,
        NULL
    
    ; If EOF, we're done
    cmp charBytesRead, 0
    je endOfReadLine
    
    ; If LF, we've found CRLF sequence
    cmp charBuffer, 10
    je endOfLine
    
    ; Not LF, store this character and continue
    mov al, charBuffer
    mov [edi], al
    inc edi
    inc bytesRead
    jmp readCharLoop
    
endOfLine:
    ; Add null terminator
    mov BYTE PTR [edi], 0
    jmp readLineDone
    
endOfReadLine:
    ; Check if we read anything
    cmp bytesRead, 0
    je readLineDone
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
readLineDone:
    ret
ReadLineFromFile ENDP

;---------------------------------------------------------------
; This module will add a comma when formatting data
; Receives: The address / pointer of the output string in EDX
; Returns: Nothing
;---------------------------------------------------------------

addComma PROC
    ; Add comma
    mov eax, OFFSET commaChar
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx

    ret
addComma ENDP

;--------------------------------------------------------------------------------
; resetLoginAttempt PROC
; Resets the login attempt counter and timestamp for a specified user
; Receives: Pointer to user credential structure
; Returns : Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
resetLoginAttempt PROC,
    user: PTR userCredential
    
    pushad
    
    mov esi, user

    ; Reset loginAttempt to "0" and timestamp to "-"
    INVOKE Str_copy, ADDR zeroVal, ADDR (userCredential PTR [esi]).loginAttempt
    INVOKE Str_copy, ADDR dashVal, ADDR (userCredential PTR [esi]).firstLoginAttemptTimestamp
    
    ; Update user record
    INVOKE updateUserFile, ADDR user
    CLC ; Return Success
    jmp resetDone
    
resetFailed:
    STC ; Return failure
    
resetDone:
    popad
    ret
resetLoginAttempt ENDP

;--------------------------------------------------------------------------------
; changeUserCredential PROC
; Updates specific fields in a user's credentials
; Receives: Pointer to userCredential structure with fields to update
;           (only fields with non-empty values will be updated)
; Returns : Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
changeUserCredential PROC,
    newCred: PTR userCredential
    
    LOCAL currCred: userCredential
    
    pushad
    
    ; Copy username from new credentials
    mov esi, newCred
    add esi, OFFSET userCredential.username
    INVOKE Str_copy, esi, ADDR currCred.username
    
    ; Read current user data
    INVOKE inputFromFile, ADDR currCred
    
    ; Check if user found
    jc changeFailed
    
    ; Check and update password if provided
    mov esi, newCred
    add esi, OFFSET userCredential.hashed_password
    cmp BYTE PTR [esi], 0
    je checkPin  ; Skip if empty
    
    lea edi, currCred.hashed_password
    INVOKE Str_copy, esi, edi
    
checkPin:
    ; Check and update PIN if provided
    mov esi, newCred
    add esi, OFFSET userCredential.hashed_pin
    cmp BYTE PTR [esi], 0
    je checkCustomerId  ; Skip if empty
    
    lea edi, currCred.hashed_pin
    INVOKE Str_copy, esi, edi
    
checkCustomerId:
    ; Check and update customer ID if provided
    mov esi, newCred
    add esi, OFFSET userCredential.customer_id
    cmp BYTE PTR [esi], 0
    je checkEncryptionKey  ; Skip if empty
    
    lea edi, currCred.customer_id
    INVOKE Str_copy, esi, edi
    
checkEncryptionKey:
    ; Check and update encryption key if provided
    mov esi, newCred
    add esi, OFFSET userCredential.encryption_key
    cmp BYTE PTR [esi], 0
    je checkLoginAttempt  ; Skip if empty
    
    lea edi, currCred.encryption_key
    INVOKE Str_copy, esi, edi
    
checkLoginAttempt:
    ; Check and update login attempt if provided
    mov esi, newCred
    add esi, OFFSET userCredential.loginAttempt
    cmp BYTE PTR [esi], 0
    je checkTimestamp  ; Skip if empty
    
    lea edi, currCred.loginAttempt
    INVOKE Str_copy, esi, edi
    
checkTimestamp:
    ; Check and update timestamp if provided
    mov esi, newCred
    add esi, OFFSET userCredential.firstLoginAttemptTimestamp
    cmp BYTE PTR [esi], 0
    je updateCredentials  ; Skip if empty
    
    lea edi, currCred.firstLoginAttemptTimestamp
    INVOKE Str_copy, esi, edi
    
updateCredentials:
    ; Write the updated user credentials
    INVOKE updateUserFile, ADDR currCred
    CLC ; Return Success
    jmp changeDone
    
changeFailed:
    STC
    
changeDone:
    popad
    ret
changeUserCredential ENDP
END