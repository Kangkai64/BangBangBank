
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; incrementLoginAttempt PROC
; Increments the login attempt counter for a specified user
; Receives: Pointer to username
; Returns: EAX = 1 if successful, 0 if failed
;--------------------------------------------------------------------------------
incrementLoginAttempt PROC,
    username: PTR BYTE
    
    LOCAL userCred: userCredential
    LOCAL timeStr[30]: BYTE
    
    pushad
    
    ; Initialize userCredential structure
    INVOKE Str_copy, username, ADDR userCred.username
    
    ; Read user record to get current data
    INVOKE inputFromFile, ADDR userCred
    
    ; Check if user found
    cmp eax, 0
    je incrementFailed
    
    ; Convert string loginAttempt to number, increment, and convert back
    lea edi, userCred.loginAttempt
    INVOKE StringToInt, edi
    inc eax
    INVOKE IntToString
    
    ; If this is first attempt (was 0, now 1), set timestamp
    cmp eax, 1
    jne updateLoginAttempt
    
    ; Get current system time
    INVOKE GetLocalTime, ADDR currTime
    
    ; Format timestamp: DD/MM/YYYY HH:MM:SS
    INVOKE wsprintf, ADDR timeStr, ADDR timeStampFormat,
        currTime.wDay,
        currTime.wMonth,
        currTime.wYear,
        currTime.wHour,
        currTime.wMinute,
        currTime.wSecond
    
    ; Copy timestamp to firstLoginAttemptTimestamp
    INVOKE Str_copy, ADDR timeStr, ADDR userCred.firstLoginAttemptTimestamp
    
updateLoginAttempt:
    ; Update user record
    INVOKE updateUserFile, ADDR userCred
    jmp incrementDone
    
incrementFailed:
    mov eax, 0
    
incrementDone:
    popad
    ret
incrementLoginAttempt ENDP

;--------------------------------------------------------------------------------
; resetLoginAttempt PROC
; Resets the login attempt counter and timestamp for a specified user
; Receives: Pointer to username
; Returns: EAX = 1 if successful, 0 if failed
;--------------------------------------------------------------------------------
resetLoginAttempt PROC,
    username: PTR BYTE
    
    LOCAL userCred: userCredential
    
    pushad
    
    ; Initialize userCredential structure
    INVOKE Str_copy, username, ADDR userCred.username
    
    ; Read user record to get current data
    INVOKE inputFromFile, ADDR userCred
    
    ; Check if user found
    cmp eax, 0
    je resetFailed
    
    ; Reset loginAttempt to "0" and timestamp to "-"
    INVOKE Str_copy, ADDR zeroVal, ADDR userCred.loginAttempt
    INVOKE Str_copy, ADDR dashVal, ADDR userCred.firstLoginAttemptTimestamp
    
    ; Update user record
    INVOKE updateUserFile, ADDR userCred
    jmp resetDone
    
resetFailed:
    mov eax, 0
    
resetDone:
    popad
    ret
resetLoginAttempt ENDP

;--------------------------------------------------------------------------------
; changeUserCredential PROC
; Updates specific fields in a user's credentials
; Receives: Pointer to userCredential structure with fields to update
;           (only fields with non-empty values will be updated)
; Returns: EAX = 1 if successful, 0 if failed
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
    cmp eax, 0
    je changeFailed
    
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
    jmp changeDone
    
changeFailed:
    mov eax, 0
    
changeDone:
    popad
    ret
changeUserCredential ENDP
END