
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module updates user credentials in a file after successful login
; Receives: User credential structure
; Returns: Success flag
; Last update: 15/3/2025
;--------------------------------------------------------------------------------

.data
userFileBuffer BYTE 2048 DUP(?)
writeBuffer    BYTE 2048 DUP(?)
updateFilename BYTE 255 DUP(?)
updateUserDir  BYTE "Users\", 0
writeHandle    DWORD ?
writeErrorMsg  BYTE "Error: Could not update user file", 0
commaChar      BYTE ",", 0
newlineChar    BYTE NEWLINE, 0  ; CR+LF
timeBuffer     BYTE 64 DUP(?)

; Constants needed by updateUserFile procedure
headerLine BYTE "username,hashed_password,hashed_PIN,customer_id,encryption_key,loginAttempt,firstLoginAttemptTimestamp", NEWLINE, 0
zero BYTE "0", 0
dash BYTE "-", 0


.code
updateUserFile PROC,
    user: PTR userCredential
    
    pushad
    
    ; Create directory path and filename
    mov esi, OFFSET updateUserDir
    mov edi, OFFSET updateFilename
    call Str_copy
    
    mov edx, OFFSET updateFilename
    call Str_length
    mov edi, OFFSET updateFilename
    add edi, eax
    
    ; Append username and .txt
    mov esi, user
    add esi, OFFSET userCredential.username
    call Str_copy
    
    mov edx, OFFSET updateFilename
    call Str_length
    mov edi, OFFSET updateFilename
    add edi, eax
    
    mov BYTE PTR [edi], '.'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 'x'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 0
    
    ; Create CSV header in buffer
    mov edi, OFFSET writeBuffer
    mov BYTE PTR [edi], 0   ; Start with empty string
    
    ; Add header line
    mov edx, OFFSET writeBuffer
    mov esi, OFFSET headerLine
    call Str_cat
    
    ; Write the user data
    ; Format CSV line with user data
    mov esi, user
    
    ; Add username
    add esi, OFFSET userCredential.username
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add hashed_password
    mov esi, user
    add esi, OFFSET userCredential.hashed_password
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add hashed_pin
    mov esi, user
    add esi, OFFSET userCredential.hashed_pin
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add customer_id
    mov esi, user
    add esi, OFFSET userCredential.customer_id
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add encryption_key
    mov esi, user
    add esi, OFFSET userCredential.encryption_key
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add loginAttempt (reset to 0 after successful login)
    mov edx, OFFSET zero
    call Str_cat
    mov edx, OFFSET commaChar
    call Str_cat
    
    ; Add firstLoginAttemptTimestamp (reset to - after successful login)
    mov edx, OFFSET dash
    call Str_cat
    
    ; Open file for writing (create/overwrite)
    mov edx, OFFSET updateFilename
    call CreateOutputFile
    mov writeHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne writeFileOpen
    
    ; File open error
    mov edx, OFFSET writeErrorMsg
    call WriteString
    call Crlf
    jmp updateExit
    
writeFileOpen:
    ; Write buffer to file
    mov eax, writeHandle
    mov edx, OFFSET writeBuffer
    call Str_length
    mov ecx, eax
    call WriteToFile
    
    ; Close the file
    mov eax, writeHandle
    call CloseFile
    
updateExit:
    popad
    ret
updateUserFile ENDP
END