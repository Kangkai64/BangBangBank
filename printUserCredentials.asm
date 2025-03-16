
INCLUDE BangBangBank.inc

;-------------------------------------------------------------------
; This module will print the user credentials onto the console
; Receives : The address / pointer of the user credential structure
; Returns : Nothing
; Last update: 16/3/2025
;-------------------------------------------------------------------

.data
; Labels for each field
usernameLabel        BYTE "Username: ", 0
passwordLabel        BYTE "Hashed Password: ", 0
pinLabel             BYTE "Hashed PIN: ", 0
customerIDLabel      BYTE "Customer ID: ", 0
encryptionKeyLabel   BYTE "Encryption Key: ", 0
loginAttemptsLabel   BYTE "Login Attempts: ", 0
timestampLabel       BYTE "First Login Attempt Timestamp: ", 0

.code
printUserCredentials PROC, 
    user: PTR userCredential
    
    pushad
    
    ; Print username
    INVOKE printString, ADDR usernameLabel
    mov esi, user
    add esi, OFFSET userCredential.username
    INVOKE printString, esi
    call Crlf
    
    ; Print hashed password
    INVOKE printString, ADDR passwordLabel
    mov esi, user
    add esi, OFFSET userCredential.hashed_password
    INVOKE printString, esi
    call Crlf
    
    ; Print hashed PIN
    INVOKE printString, ADDR pinLabel
    mov esi, user
    add esi, OFFSET userCredential.hashed_pin
    INVOKE printString, esi
    call Crlf
    
    ; Print customer ID
    INVOKE printString, ADDR customerIDLabel
    mov esi, user
    add esi, OFFSET userCredential.customer_id
    INVOKE printString, esi
    call Crlf
    
    ; Print encryption key
    INVOKE printString, ADDR encryptionKeyLabel
    mov esi, user
    add esi, OFFSET userCredential.encryption_key
    INVOKE printString, esi
    call Crlf
    
    ; Print login attempts
    INVOKE printString, ADDR loginAttemptsLabel
    mov esi, user
    add esi, OFFSET userCredential.loginAttempt
    INVOKE printString, esi
    call Crlf
    
    ; Print first login attempt timestamp
    INVOKE printString, ADDR timestampLabel
    mov esi, user
    add esi, OFFSET userCredential.firstLoginAttemptTimestamp
    INVOKE printString, esi
    call Crlf
    
    popad
    ret
printUserCredentials ENDP
END