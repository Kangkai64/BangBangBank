
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the transaction details and trims it
; to avoid excessive spaces
; Receives : The address / pointer of the transaction details
;            variable from caller
; Returns : Nothing
; Last update: 10/4/2025
;------------------------------------------------------------------------

.data
promptForTransactionDetailMsg BYTE "Enter recipient details (Press ENTER to use default): ", 0
inputBuffer BYTE 255 DUP(?)
replaceBuffer BYTE 255 DUP(?)
commaChar BYTE ",", 0
periodChar BYTE ".", 0

.code
promptForTransactionDetail PROC,
    inputTransactionDetailAddress: PTR BYTE
    
    pushad

    INVOKE printString, ADDR promptForTransactionDetailMsg

    lea edx, inputBuffer
    mov ecx, maxBufferSize - 1
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT
    call ReadString
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

    ; Trims the username
    INVOKE myStr_trim, ADDR inputBuffer, " "

	; Check if user input is empty
	INVOKE Str_length, ADDR inputBuffer
    cmp eax, 0

    .IF ZERO?
        STC ; Use default message
	    jmp done
    .ENDIF

    ; Copy custom message
    INVOKE Str_replace, ADDR inputBuffer, ADDR commaChar, ADDR periodChar, ADDR replaceBuffer, maxBufferSize
    INVOKE Str_copy, ADDR replaceBuffer, inputTransactionDetailAddress
    CLC ; Use custom message

done:
    popad
    ret
promptForTransactionDetail ENDP
END