
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

;------------------------------------------------------
; These module are used to clear the console screen 
; leftover output not cleared by Clrscr
; Receives : Nothing
; Returns : Nothing
; Last update: 15/4/2025
;------------------------------------------------------

.data
clsCommand          BYTE "cmd.exe /c cls", 0 

.code
clearConsole PROC
    pushf
    pushad

    INVOKE WinExec, ADDR clsCommand, SW_HIDE

    popad
    popf

    INVOKE Sleep, 100
    ret
clearConsole ENDP
END