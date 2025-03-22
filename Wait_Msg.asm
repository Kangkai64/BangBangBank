
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module will print the wait message onto the 
; console with two NEWLINE
; Receives : Nothing
; Returns : Nothing
; Last update: 13/3/2025
;------------------------------------------------------

.data

.code
Wait_Msg PROC

	call Crlf
	call Crlf
	call WaitMsg
	call Crlf
	call Crlf

	ret
Wait_Msg ENDP
END