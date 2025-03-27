
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the username and trims it
; to avoid excessive spaces
; Receives : The address / pointer of the username variable from caller
; Returns : Nothing
; Last update: 15/3/2025
;------------------------------------------------------------------------

.data
promptUsernameMsg BYTE "Please enter your username: ", 0 

.code
promptForUsername PROC,
    inputUsernameAddress: PTR BYTE
    
    pushad

    INVOKE printString, ADDR promptUsernameMsg

    mov edx, inputUsernameAddress
    mov ecx, maxBufferSize - 1
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUTMODE
    call ReadString
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

    ; Trims the username
    INVOKE myStr_trim, inputUsernameAddress, " "

    popad
    ret
promptForUsername ENDP
END