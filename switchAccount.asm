
INCLUDE BangBangBank.inc

;----------------------------------------------------------------------
; This module will print all user account that user can switch
; Receives : 
; Returns : Nothing
; Last update: 25/3/2025
;----------------------------------------------------------------------

.data
accountFileName		BYTE "Users\userAccount.txt", 0

switchAccountTitle	BYTE NEWLINE, 
					"Switch Account", NEWLINE, 
					"==============================", NEWLINE, 0
noAccountMessage	BYTE "You didn't have another account. Kindly register a new account", NEWLINE,
					"at your nearest Bang Bang Bank Branch.", NEWLINE, 0

; Handles and buffers
fileHandle         DWORD ?
readBuffer         BYTE 20480 DUP(?)  ; Larger buffer for multi-user file


.code
switchAccount PROC,
	
switchAccount ENDP
END