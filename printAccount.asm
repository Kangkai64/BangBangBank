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
AccountLabel        BYTE "Account ID: ", 0
customerIDLabel      BYTE "Customer ID: ", 0
accountbalanceLabel       BYTE "Account Balance: ", 0

.code
printUserAccount PROC, 
    user: PTR userAccount
    
    pushad
    
    ; Print username
    INVOKE printString, ADDR usernameLabel
    mov esi, user
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi
    call Crlf
    
    ; Print Account ID
    INVOKE printString, ADDR AccountLabel
    mov esi, user
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi
    call Crlf
    
    ; Print customer ID
    INVOKE printString, ADDR customerIDLabel
    mov esi, user
    add esi, OFFSET userAccount.customer_id
    INVOKE printString, esi
    call Crlf
    
    ; Print accountbalance
    INVOKE printString, ADDR accountbalanceLabel
    mov esi, user
    add esi, OFFSET userAccount.account_balance
    INVOKE printString, esi
    call Crlf
    
    popad
    ret
printUserAccount ENDP
END