
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the recipient account no.
; Receives : The address / pointer of the recipientAccNo variable
; Returns : Nothing
; Last update: 23/3/2025
;------------------------------------------------------------------------

.data
promptRecipientAccountNo BYTE "Enter recipient account no. :", 0

.code
promptForRecipientAccNo PROC,
	inputRecipientAccNoAddress: PTR BYTE

	pushad

    INVOKE printString, ADDR promptRecipientAccountNo

    mov edx, inputRecipientAccNoAddress
    mov ecx, maxBufferSize - 1
    call ReadString

    popad
    ret


promptForRecipientAccNo ENDP
END