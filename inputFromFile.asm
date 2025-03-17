
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module will read user credentials from a single file containing all users
; Receives: Pointer to userCredential structure (user)
; Returns: Nothing
; Last update: 16/3/2025
;--------------------------------------------------------------------------------

.data
; File name components
directoryPath       BYTE "Users\", 0
credentialFileName  BYTE "Users\userCredential.txt", 0
accountFileName     BYTE "Users\userAccount.txt", 0
transactionFileName BYTE "Users\transactionLog.txt", 0

; Handles and buffers
fileHandle         DWORD ?
readBuffer         BYTE 20480 DUP(?)  ; Larger buffer for multi-user file
errorMsg           BYTE "Error: File cannot be opened or read", NEWLINE, 0
pathErrorMsg       BYTE "Error: Invalid file path", NEWLINE, 0
userNotFoundMsg    BYTE NEWLINE, "User not found.", NEWLINE, 0
bytesRead          DWORD ?
tempBuffer         BYTE 512 DUP(?)
fieldBuffer        BYTE 512 DUP(?)
fieldIndex         DWORD 0
currentLineStart   DWORD 0
foundUser          BYTE 0
inputUsername      BYTE 64 DUP(?)

.code
inputFromFile PROC,
    user: PTR userCredential
    
    pushad

    ; Copy out the username and store it into inputUsername
    mov esi, [user]
    add esi, OFFSET userCredential.username
    INVOKE Str_copy, esi, ADDR inputUsername

    ; Open the credentials file
    INVOKE CreateFile, 
        ADDR credentialFileName,         ; lpFileName
        GENERIC_READ,                    ; dwDesiredAccess
        FILE_SHARE_READ,                 ; dwShareMode
        NULL,                            ; lpSecurityAttributes
        OPEN_EXISTING,                   ; dwCreationDisposition
        FILE_ATTRIBUTE_NORMAL,           ; dwFlagsAndAttributes
        NULL                             ; hTemplateFile
        
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccess
    
    ; File open error
    INVOKE printString, ADDR credentialFileName
    call Crlf
    INVOKE printString, ADDR errorMsg

    ; Try to create directory
    INVOKE CreateDirectory, ADDR directoryPath, NULL
    test eax, eax    ; Check if directory creation was successful
    jnz directoryCreated

    ; Directory creation failed
    call Crlf
    INVOKE printString, ADDR pathErrorMsg
    INVOKE printString, ADDR directoryPath
    call Crlf

directoryCreated:
    call Wait_Msg
    STC ; Set carry flag
    jmp inputFileExit
    
fileOpenSuccess:
    ; Read file content into buffer
    INVOKE ReadFile, 
        fileHandle,                     ; hFile
        ADDR readBuffer,                ; lpBuffer
        SIZEOF readBuffer - 1,          ; nNumberOfBytesToRead
        ADDR bytesRead,                 ; lpNumberOfBytesRead
        NULL                            ; lpOverlapped
    
    ; Check if read was successful
    .IF eax == 0
        INVOKE printString, ADDR errorMsg
        call Wait_Msg
        STC ; Set carry flag
        jmp inputFileExit
    .ENDIF
    
    ; Add null terminator to buffer
    mov edi, OFFSET readBuffer
    add edi, bytesRead
    mov BYTE PTR [edi], 0
    
    ; Skip the header line
    mov esi, OFFSET readBuffer
    
skipHeaderLoop:
    mov al, [esi]
    cmp al, 0          ; End of buffer?
    je userNotFound    ; File is empty or only has header
    cmp al, 10         ; LF - new line?
    je foundDataStart
    cmp al, 13         ; CR?
    je skipCR
    inc esi
    jmp skipHeaderLoop
    
skipCR:
    inc esi            ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipHeaderLoop
    inc esi            ; Skip LF
    
foundDataStart:
    
    ; Set foundUser flag to 0 (not found)
    mov foundUser, 0
    
searchUserLoop:
    ; Store the start of current line
    mov currentLineStart, esi
    
    ; Parse username field from current line
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Compare with input username
    INVOKE Str_compare, ADDR tempBuffer, ADDR inputUsername
    
    ; If match found, process this record
    .IF ZERO?
        ; Found the user! Set flag
        mov foundUser, 1
        
        ; Return to the start of this line
        mov esi, currentLineStart
        
        ; Initialize fieldIndex
        mov fieldIndex, 0
        
        ; Parse all fields for this user
        INVOKE ParseUserCredentials, user
        
        jmp inputFileExit
    .ENDIF
    
    ; Username didn't match, skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je userNotFound
    cmp al, 10     ; LF?
    je nextLine
    cmp al, 13     ; CR?
    je skipToNextCR
    inc esi
    jmp skipToNextLine
    
skipToNextCR:
    inc esi        ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipToNextLine
    inc esi        ; Skip LF
    jmp searchUserLoop
    
nextLine:
    inc esi        ; Skip LF
    jmp searchUserLoop
    
userNotFound:
    INVOKE printString, OFFSET userNotFoundMsg
    call Wait_Msg
    mov eax, FALSE
    mov [esp+28], eax
    
inputFileExit:
    INVOKE CloseHandle, fileHandle
    popad
    ret
inputFromFile ENDP

;--------------------------------------------------------------------------------
; ParseUserCredentials PROC
; Parses all credential fields for the current user and fills the structure
; Receives: ESI = pointer to start of user record in buffer
;           user = pointer to userCredential structure
; Returns: Filled user credential structure
;--------------------------------------------------------------------------------
ParseUserCredentials PROC,
    user: PTR userCredential
    
parseNextCredField:
    ; Parse username field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.username
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse hashed_password field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.hashed_password
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse hashed_pin field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.hashed_pin
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse customer_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.customer_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse encryption_key field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.encryption_key
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse loginAttempt field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.loginAttempt
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse firstLoginAttemptTimestamp field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.firstLoginAttemptTimestamp
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
doneParsingFields:
    ret
ParseUserCredentials ENDP
END