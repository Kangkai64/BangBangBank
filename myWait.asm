
INCLUDE BangBangBank.inc

; This module will print the string onto the console
; Receives : The address of the string / prompt message to be printed with null terminator (,0)
; Returns : Nothing
; Last update: 13/3/2025

.data

.code
myWait PROC

	call Crlf
	call WaitMsg
	call Crlf
	call Crlf

	ret
myWait ENDP
END