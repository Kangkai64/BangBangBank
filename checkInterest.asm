
INCLUDE BangBangBank.inc

;-----------------------------------------------------------
; This module will check user have interest or not
; Receives : Nothing
; Returns : Nothing
; Last update: 15/4/2025
;-----------------------------------------------------------

.data
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
openingDateLabel    BYTE "Opening Date: ", 0
noInterestMsg       BYTE NEWLINE, "You didn't earn any interest, or it had already been applied before.", 0
dayBuffer           BYTE 3 DUP(0)
monthBuffer         BYTE 3 DUP(0)
yearBuffer          BYTE 5 DUP(0)
line                BYTE "=================================================================", NEWLINE, NEWLINE, 0
openDayInteger      DWORD 0
openMonthInteger    DWORD 0
openYearInteger     DWORD 0
currDayInteger      DWORD 0
currMonthInteger    DWORD 0
currYearInteger     DWORD 0
balance             DWORD ?
interestAppliedMsg  BYTE NEWLINE, "Interest has been applied to your account!", 0
interestTransMsg    BYTE "Interest from BangBangBank", 0
newBalanceMsg       BYTE "New Balance     : RM ", 0
interestAmountMsg   BYTE "Interest Amount : RM ", 0
tempInterest        DWORD ?
tempBeneficiaries   BYTE 255 DUP(?)
newBalance          DWORD ?
decimalPoint BYTE ".", 0
leadingZero BYTE "0", 0
balanceStr BYTE 20 DUP(0)  
interestStr BYTE 20 DUP(0)
newTransactionId BYTE 255 DUP(?)
interestRecord userTransaction <>
transferTypeStr BYTE "Interest", 0

; File paths
transactionFileName    BYTE "Users\transactionLog.txt", 0

.code

;--------------------------------------------------
; This module is to get interest apply date
;--------------------------------------------------

parseOpeningDate PROC,
    account: PTR userAccount
    pushad                          ; Save all registers
    
    mov esi, account
    add esi, OFFSET userAccount.interest_apply_date  ; Load address of the date string
    
    ; Parse day (positions 0-1)
    xor eax, eax                    ; Clear EAX
    mov al, [esi]                   ; First digit
    sub al, '0'
    mov bl, 10
    mul bl                          ; Multiply first digit by 10
    mov bl, [esi+1]                 ; Second digit
    sub bl, '0'
    add al, bl                      ; Combine digits
    mov openDayInteger, eax         ; Store day value
    
    ; Parse month (positions 3-4)
    xor eax, eax                    ; Clear EAX
    mov al, [esi+3]                 ; First digit
    sub al, '0'
    mov bl, 10
    mul bl                          ; Multiply first digit by 10
    mov bl, [esi+4]                 ; Second digit
    sub bl, '0'
    add al, bl                      ; Combine digits
    mov openMonthInteger, eax       ; Store month value
    
    ; Parse year (positions 6-9)
    xor eax, eax                    ; Clear EAX
    
    ; Thousands digit
    mov al, [esi+6]
    sub al, '0'
    mov ebx, 1000
    mul ebx
    mov ecx, eax                    ; Store in ECX temporarily
    
    ; Hundreds digit
    xor eax, eax
    mov al, [esi+7]
    sub al, '0'
    mov ebx, 100
    mul ebx
    add ecx, eax                    ; Add to running total
    
    ; Tens digit
    xor eax, eax
    mov al, [esi+8]
    sub al, '0'
    mov ebx, 10
    mul ebx
    add ecx, eax                    ; Add to running total
    
    ; Ones digit
    xor eax, eax
    mov al, [esi+9]
    sub al, '0'
    add ecx, eax                    ; Final total
    
    mov openYearInteger, ecx        ; Store year value
    
    popad                           ; Restore all registers
    ret
parseOpeningDate ENDP

;--------------------------------------------------
; This module is to get current date
;--------------------------------------------------

parseCurrentDate PROC,
    account: PTR userAccount
    pushad                          ; Save all registers
    
    lea esi, timeDate               ; Load address of the date string (DD/MM/YYYY)
    
    ; Parse day (positions 0-1)
    xor eax, eax                    ; Clear EAX
    mov al, [esi]                   ; First digit
    sub al, '0'
    mov bl, 10
    mul bl                          ; Multiply first digit by 10
    mov bl, [esi+1]                 ; Second digit
    sub bl, '0'
    add al, bl                      ; Combine digits
    mov currDayInteger, eax         ; Store day value
    
    ; Parse month (positions 3-4)
    xor eax, eax                    ; Clear EAX
    mov al, [esi+3]                 ; First digit
    sub al, '0'
    mov bl, 10
    mul bl                          ; Multiply first digit by 10
    mov bl, [esi+4]                 ; Second digit
    sub bl, '0'
    add al, bl                      ; Combine digits
    mov currMonthInteger, eax       ; Store month value
    
    ; Parse year (positions 6-9)
    xor eax, eax                    ; Clear EAX
    
    ; Thousands digit
    mov al, [esi+6]
    sub al, '0'
    mov ebx, 1000
    mul ebx
    mov ecx, eax                    ; Store in ECX temporarily
    
    ; Hundreds digit
    xor eax, eax
    mov al, [esi+7]
    sub al, '0'
    mov ebx, 100
    mul ebx
    add ecx, eax                    ; Add to running total
    
    ; Tens digit
    xor eax, eax
    mov al, [esi+8]
    sub al, '0'
    mov ebx, 10
    mul ebx
    add ecx, eax                    ; Add to running total
    
    ; Ones digit
    xor eax, eax
    mov al, [esi+9]
    sub al, '0'
    add ecx, eax                    ; Final total
    
    mov currYearInteger, ecx        ; Store year value
    
    popad                           ; Restore all registers
    ret
parseCurrentDate ENDP

;---------------------------------------------------
; This module will check users earn interest or not
;---------------------------------------------------

checkInterest PROC,
    account: PTR userAccount
    pushad                          ; Save all registers
    INVOKE displayLogo
    INVOKE printString, ADDR line
    ; Get current time and format it in DD/MM/YYYY format
	INVOKE GetLocalTime, ADDR currentTime
	INVOKE formatSystemTime, ADDR currentTime, ADDR timeOutputBuffer
    

	; Copy the date part of the time stamp
	lea esi, timeOutputBuffer
	lea edi, timeDate
	mov ecx, 10

	copy_date:
		mov eax, [esi]
		mov [edi], eax
		inc esi
		inc edi
		LOOP copy_date

	; Add null terminator
	mov BYTE PTR [edi], 0

    ; Get user opening date
    mov esi, account
    add esi, OFFSET userAccount.opening_date

    ; Get balance
    mov esi, account
    add esi, OFFSET userAccount.account_balance

    ; Convert balance to int (without decimal)
    INVOKE StringToDecimal, esi
    mov balance, eax
    ;call WriteDecimalNumber

    ; Call parseOpeningDate to extract date components
    INVOKE parseOpeningDate, account

     ; Call parseCurrentDate to extract date components
    INVOKE parseCurrentDate, account

compare_date:
    ; Calculate if a full year has passed
    
    ; Compare years first - must be at least 1 year difference
    mov eax, currYearInteger
    sub eax, openYearInteger    ; Calculate year difference
    cmp eax, 1
    jg add_interest            ; If more than 1 year difference, definitely add interest
    jl end_compare             ; If less than 1 year difference, definitely no interest
    
    ; Exactly 1 year difference, now check month
    mov eax, currMonthInteger
    cmp eax, openMonthInteger
    jg add_interest            ; If current month > opening month, more than 1 year passed
    jl end_compare             ; If current month < opening month, less than 1 year passed
    
    ; Same month, check day
    mov eax, currDayInteger
    cmp eax, openDayInteger
    jge add_interest           ; If current day >= opening day, exactly or more than 1 year passed
    jl end_compare             ; If current day < opening day, less than 1 year passed

    
add_interest: 
    ; Formula = balance * 0.03
    mov eax, balance
    mov ebx, 3
    mul ebx
    add eax, 50     ; For rounding 
    mov ebx, 100
    div ebx         ; EAX = (balance * 3 + 50) /100, EDX = remainder
    mov tempInterest, eax

    ; Calculate new balance 
    mov eax, tempInterest
    add eax, balance
    ; Store new balance
    mov newBalance, eax

    ; Convert tempInterest to rm and cents format in interestStr
    mov eax, tempInterest
    mov edx, 0
    mov ebx, 100
    div ebx         ; EAX = rm, EDX = cents

    ; Create formatted interest string
    lea edi, interestStr    ; Point to output buffer

    ; Convert rm to string
    push edx               ; Save cents temporarily
    call IntToString       ; EDI now points after rm
    dec edi                ; Move back before the null terminator

    ; Add decimal point
    mov BYTE PTR [edi], '.'
    inc edi

    ; Handle cents with leading zero if needed
    pop eax                ; Get cents into EAX for conversion
    cmp eax, 10
    jae interest_no_leading_zero

    ; Add leading zero for cents < 10
    mov BYTE PTR [edi], '0'
    inc edi

    interest_no_leading_zero:
    ; Convert cents to string
    call IntToString       ; EDI now points after cents
    
    ; Convert newBalance to rm and cents 
    mov eax, newBalance
    mov edx, 0
    mov ebx, 100
    div ebx         ; EAX = rm, EDX = cents

    ; Create formatted balance string
    lea edi, balanceStr    ; Point to output buffer
    
    ; Convert rm to string
    push edx               ; Save cents temporarily
    call IntToString       ; EDI now points after rm
    dec edi                ; Move back before the null terminator
    
    ; Add decimal point
    mov BYTE PTR [edi], '.'
    inc edi
    
    ; Handle cents with leading zero if needed
    pop eax                ; Get cents into EAX for conversion
    cmp eax, 10
    jae no_leading_zero
    
    ; Add leading zero for cents < 10
    mov BYTE PTR [edi], '0'
    inc edi
    
no_leading_zero:
    ; Convert cents to string
    call IntToString       ; EDI now points after cents
    
    ; Display the combined balance string
    INVOKE printString, ADDR interestAmountMsg
    INVOKE printString, ADDR interestStr
    call Crlf
    INVOKE printString, ADDR newBalanceMsg
    INVOKE printString, ADDR balanceStr
    
    ; Display interest applied message
    call Crlf
    INVOKE printString, ADDR interestAppliedMsg

    ; Store new interest apply date in account structure
    mov esi, account
    add esi, OFFSET userAccount.account_balance
    INVOKE Str_copy, ADDR balanceStr, esi

    ; Update interest_apply_date
    mov esi, account
    add esi, userAccount.interest_apply_date
    INVOKE Str_copy, ADDR timeDate, esi

    ; Update the user account file with new balance
    INVOKE updateUserAccountFile, account

    ; Save record
    INVOKE generateTransactionId, ADDR newTransactionId

    ; Format transaction record with the values
    ; Copy transaction ID
    INVOKE Str_copy, ADDR newTransactionId, ADDR interestRecord.transaction_id

    ; Copy customer id from the sender
    mov esi, account
    add esi, OFFSET userAccount.customer_id
    INVOKE Str_copy, esi, ADDR interestRecord.customer_id

    ; Copy customer account number from the sender
    mov esi, account
    add esi, OFFSET userAccount.account_number
    INVOKE Str_copy, esi, ADDR interestRecord.sender_account_number

    ; Set transaction type as "Interest"
    INVOKE Str_copy, ADDR transferTypeStr, ADDR interestRecord.transaction_type

    ; Format amount with plus sign (for interest)
    mov al, '+'
    mov interestRecord.amount[0], al ; Set first character as '+'
    INVOKE Str_copy, ADDR interestStr, ADDR (interestRecord.amount+1)

    ; Copy updated account balance
    INVOKE Str_copy, ADDR balanceStr, ADDR interestRecord.balance

    ; Copy transaction detail
    INVOKE Str_copy, ADDR interestTransMsg, ADDR interestRecord.transaction_detail

    ; Copy date
    INVOKE Str_copy, ADDR timeDate, ADDR interestRecord.date

    ; Copy time
    lea esi, timeOutputBuffer
    add esi, 11 ; Skip date part
    INVOKE Str_copy, esi, ADDR interestRecord.time

    ; Insert the transaction log
    INVOKE insertTransaction, ADDR interestRecord
    call Wait_Msg
    jmp done

end_compare:
    INVOKE printString, ADDR noInterestMsg
    call Wait_Msg
    call Crlf
done:    
    popad                          ; Restore all registers
    ret
checkInterest ENDP
END