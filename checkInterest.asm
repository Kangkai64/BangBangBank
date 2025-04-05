
INCLUDE BangBangBank.inc

;-----------------------------------------------------------
; This module will check user have interest or not
; Receives : Nothing
; Returns : Nothing
; Last update: 5/4/2025
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
openDayInteger      DWORD 0
openMonthInteger    DWORD 0
openYearInteger     DWORD 0
currDayInteger      DWORD 0
currMonthInteger    DWORD 0
currYearInteger     DWORD 0
balance             DWORD ?
interestAppliedMsg  BYTE NEWLINE, "Interest has been applied to your account!", 0
newBalanceMsg       BYTE "New Balance: ", 0
tempInterest        DWORD ?
newBalance          DWORD ?

.code

;--------------------------------------------------
; This module is to get opening date
;--------------------------------------------------

parseOpeningDate PROC,
    account: PTR userAccount
    pushad                          ; Save all registers
    
    mov esi, account
    add esi, OFFSET userAccount.opening_date  ; Load address of the date string
    
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
    
    ; Compare years
    mov eax, currYearInteger
    cmp eax, openYearInteger
    jg add_interest
    jl end_compare

    ; If years are same, compare month
    mov eax, currMonthInteger
    cmp eax, openMonthInteger
    jg add_interest
    jl end_compare

    ; If months are equal, compare days
    mov eax, currDayInteger
    cmp eax, openDayInteger
    jl end_compare

    
add_interest: 

    ; Formula = balance * 0.03
    mov eax, balance
    mov ebx, 3
    mul ebx
    mov edx, 0
    mov ebx, 100
    div ebx         ; EAX = balance * 3 /100 = balance * 0.03

    mov tempInterest, eax

    ; Calculate new balance (balance + interest)
    mov eax, balance
    add eax, tempInterest
    mov newBalance, eax
    INVOKE printString, ADDR newBalanceMsg
    mov eax, newBalance
    call WriteDecimalNumber
    call Crlf
    call Crlf

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