
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module will prompt for user transaction
; Receives : A variable to store the choice
; Returns : Nothing
; Last update: 18/4/2025
;------------------------------------------------------
.data
depositMenuTitle  BYTE NEWLINE, "Bang Bang Bank Deposit", NEWLINE, 0
dateHeader		  BYTE "Today is ", 0
depositMenuDesign BYTE NEWLINE,
                    "==============================", NEWLINE, 
                    "1. Bank Transfer", NEWLINE, 
                    "2. Credit/Debit Card", NEWLINE, 
                    "3. Online Payment", NEWLINE, 
                    "4. TouchNGo ewallet", NEWLINE, 
                    NEWLINE, "Enter transfer method (9 to return)", NEWLINE, 0

.code
promptForTransactionMethod PROC, 
	transactionChoice: PTR BYTE,
	timeDate: PTR BYTE

	pushad

	INVOKE printString, ADDR depositMenuTitle
	INVOKE printString, ADDR dateHeader
	INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
	INVOKE printString, timeDate
	INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
	INVOKE printString, ADDR depositMenuDesign
	INVOKE promptForIntChoice, 1, 4
	mov esi, transactionChoice
	mov BYTE PTR [esi], al

done:
	popad
	ret
promptForTransactionMethod ENDP
END