INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will print the login design onto the console
; and calls the functions for login.
; Receives : Nothing
; Returns : Carry flag is set if login failed, clear if login successful
; Last update: 17/3/2025
;------------------------------------------------------------------------
.data

inputUsername BYTE 255 DUP(?)
inputPassword BYTE 255 DUP(?)

user userAccount <>

.code
testing PROC
    ; Read username and password
    INVOKE promptForUsername, OFFSET inputUsername
    INVOKE promptForPassword, OFFSET inputPassword
    
    ; Copy input username to user structure
    INVOKE Str_copy, ADDR inputUsername, ADDR user.full_name

    ; Read user credentials from username.txt
    INVOKE inputFromAccount, ADDR user

	; Check the value of each field 
    INVOKE printAccount, ADDR user

    
testing ENDP
END