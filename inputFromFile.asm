
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module will read user credentials from a file named "[username].txt"
; Receives: User credential structure
; Returns: Filled user credential structure
; Last update: 15/3/2025
;--------------------------------------------------------------------------------

.data
; Buffer to store filename (username.txt)
filenameBuffer BYTE 255 DUP(?)
userDataDir    BYTE "Users\", 0
fileHandle     DWORD ?
readBuffer     BYTE 2048 DUP(?)
errorMsg       BYTE "Error: File cannot be opened or read", NEWLINE, 0
bytesRead      DWORD ?
tempBuffer     BYTE 255 DUP(?)

.code
inputFromFile PROC,
    user: PTR userCredential
    
    pushad
    
    ; Create directory path for user file
    INVOKE Str_copy, ADDR userDataDir, ADDR filenameBuffer
    
    ; Get length of directory path
    mov edx, OFFSET filenameBuffer
    call Str_length
    
    ; Point edi to the end of "Users\"
    mov edi, OFFSET filenameBuffer
    add edi, eax  ; Move to end of directory path (end of "Users\")
    add edi, 3 ; Need to move 3 more bytes!
    
    ; Get the username from the structure
    mov esi, [user]  ; esi = pointer to userCredential structure
    add esi, OFFSET userCredential.username  ; esi points to username field
    
    ; Copy username to filenameBuffer after "Users\"
appendUsername:
    mov al, [esi]  ; Get character from username
    cmp al, 0      ; Check for null terminator
    je addExtension
    mov [edi], al  ; Copy character to filenameBuffer
    inc esi        ; Move to next character in username
    inc edi        ; Move to next position in filenameBuffer
    jmp appendUsername
    
addExtension:
    ; Append .txt to the filename
    mov BYTE PTR [edi], '.'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 'x'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 0  ; Add null terminator
    
    ; Open the file
    mov edx, OFFSET filenameBuffer
    call OpenInputFile
    mov fileHandle, eax
    
    INVOKE printString, ADDR filenameBuffer
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccess
    
    ; File open error
    INVOKE printString, ADDR errorMsg
    call Wait_Msg
    STC ; Set carry flag
    jmp inputFileExit
    
fileOpenSuccess:
    ; Read file content into buffer
    mov eax, fileHandle
    mov edx, OFFSET readBuffer
    mov ecx, SIZEOF readBuffer - 1
    call ReadFromFile
    mov bytesRead, eax
    
    ; Add null terminator to buffer
    mov edi, OFFSET readBuffer
    add edi, eax
    mov BYTE PTR [edi], 0
    
    ; Close the file
    mov eax, fileHandle
    call CloseFile
    
    ; Parse the buffer for data fields using CSV format
    mov esi, OFFSET readBuffer   ; Source
    
    ; Skip header line if present (detect comma)
    skipHeader:
        mov al, [esi]
        cmp al, 0          ; End of buffer?
        je inputFileExit   ; File is empty or only has header
        cmp al, 10         ; LF - new line?
        je foundNewLine
        cmp al, 13         ; CR?
        je skipCR
        inc esi
        jmp skipHeader
        
    skipCR:
        inc esi            ; Skip CR
        cmp BYTE PTR [esi], 10  ; Check for LF
        jne skipHeader
        inc esi            ; Skip LF
        jmp parseFields
        
    foundNewLine:
        inc esi            ; Skip LF
        
    parseFields:
        ; Read fields into structure
        ; 1. username
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        ; Copy to structure if not empty
        cmp BYTE PTR [OFFSET tempBuffer], 0
        je skipUsername
        
        ; Copy tempBuffer to username field
        mov edi, [user]
        add edi, OFFSET userCredential.username
        INVOKE Str_copy, ADDR tempBuffer, edi
        
    skipUsername:
        ; 2. hashed_password
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        mov edi, [user]
        add edi, OFFSET userCredential.hashed_password
        INVOKE Str_copy, ADDR tempBuffer, edi
        
        ; 3. hashed_pin
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        mov edi, [user]
        add edi, OFFSET userCredential.hashed_pin
        INVOKE Str_copy, ADDR tempBuffer, edi
        
        ; 4. customer_id
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        mov edi, [user]
        add edi, OFFSET userCredential.customer_id
        INVOKE Str_copy, ADDR tempBuffer, edi
        
        ; 5. encryption_key
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        mov edi, [user]
        add edi, OFFSET userCredential.encryption_key
        INVOKE Str_copy, ADDR tempBuffer, edi
        
        ; 6. loginAttempt
        mov edi, OFFSET tempBuffer
        call ParseCSVField

        mov edi, [user]
        add edi, OFFSET userCredential.loginAttempt
        INVOKE Str_copy, ADDR tempBuffer, edi
        
        ; 7. firstLoginAttemptTimestamp
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        mov edi, [user]
        add edi, OFFSET userCredential.firstLoginAttemptTimestamp
        INVOKE Str_copy, ADDR tempBuffer, edi

        CLC ; Clear carry flag if no error

inputFileExit:
    popad
    ret
inputFromFile ENDP
END