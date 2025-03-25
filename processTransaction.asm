
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will process transaction
; Receives : Nothing
; Returns : Nothing
; Last update: 25/3/2025
;------------------------------------------------------------------------

.data
transactionPageTitle BYTE "Bang Bang Bank Transaction", NEWLINE,
						  "==============================", NEWLINE,0
recipientAccNotFound BYTE "Recipient account not found...", NEWLINE,0
inputRecipientAccNo BYTE 32 DUP(?)
inputTransactionAmount BYTE 32 DUP(?)

.code
processTransaction PROC,
	account: PTR userAccount
	
	call Clrscr
	;Display transaction page
	INVOKE printString, ADDR transactionPageTitle
	
	;Prompt recipient account
	INVOKE promptForRecipientAccNo, OFFSET inputRecipientAccNo
	INVOKE validateRecipientAcc, OFFSET inputRecipientAccNo
	;validate recipient account
	.IF EAX == 0
		INVOKE printString, ADDR recipientAccNotFound
		call Wait_Msg
		STC
		jmp done
	.ENDIF
	;prompt transaction amount
	INVOKE promptForTransactionAmount, OFFSET inputTransactionAmount, account
	
	; Convert transaction amount to numeric value
	INVOKE StringToInt, OFFSET inputTransactionAmount
	mov ebx, eax  ; Store numeric amount in ebx
	
	
	done:
		ret
processTransaction ENDP
END