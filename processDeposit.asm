INCLUDE BangBangBank.inc

;----------------------------------------------------------------------------
; This module will process the deposit and reflect it to the account balance
; Receives : The address / pointer of the user account variable
; Returns : Nothing
; Last update: 7/4/2025
;----------------------------------------------------------------------------

.data
dateHeader BYTE "Date & Time: ", 0
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
transactionPageTitle BYTE "Bang Bang Bank Transaction", NEWLINE,
                          "==============================", NEWLINE,0
transactionDetailTitle BYTE "Transaction details", NEWLINE,
                            "==============================", NEWLINE,0
amount BYTE "Amount : RM ",0
confirmMsg BYTE "Press 1 to confirm and press 2 to cancel", NEWLINE,0
transactionIdMsg BYTE "Transaction ID: ", 0
recipientAccMsg BYTE "Account No: ",0
recipientNameMsg BYTE "Recipient Name: ", 0  
transTypeMsg BYTE "Transaction Type: Deposit", 0
transactionSuccessful BYTE "Transaction Successful!",0
transactionCancel BYTE "Transaction Cancelled!",0
invalidOption BYTE "Invalid option. Please try again.", 0
transactionVerifiedMsg BYTE "OTP verification successful! Transaction completed.", NEWLINE, 0
transactionFailedMsg BYTE "OTP verification failed! Transaction cancelled.", NEWLINE, 0
resendOTPMsg BYTE "OTP will resend to the same file.", 0
promptTransactionAmtMsg BYTE "Enter deposit amount (RM): ", 0
inputDepositAmount BYTE 255 DUP(?)
formattedDepositAmount BYTE 32 DUP(0)
newTransactionId BYTE 255 DUP(?)
formattedAccountBalance BYTE 32 DUP(0)
tempBuffer BYTE 32 DUP(0)
transactionRecord userTransaction <>
transferTypeStr BYTE "Deposit", 0
transferDesc BYTE "Cash deposit into account", 0

.code
processDeposit PROC,
    account: PTR userAccount

    call Clrscr
    ; Get current time and format it in DD/MM/YYYY HH:MM:SS format
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

    call Clrscr
    ;Display transaction page
    INVOKE printString, ADDR transactionPageTitle

    ;prompt transaction amount
    INVOKE promptForTransactionAmount, OFFSET inputDepositAmount, account

    jc done
    ; confirm transaction

confirmTransaction:
    INVOKE generateTransactionId, ADDR newTransactionId
    call Clrscr
    INVOKE printString, ADDR transactionDetailTitle

    ; Print transaction id
    INVOKE printString, ADDR transactionIdMsg
    INVOKE printString, ADDR newTransactionId
    Call Crlf

    ; Print recipient's name
    INVOKE printString, ADDR recipientNameMsg
    mov esi, account
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi
    Call Crlf

    ; Print recipient's account
    INVOKE printString, ADDR recipientAccMsg
    mov esi, account
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi
    Call Crlf
    
    ; Print transaction type
    INVOKE printString, ADDR transTypeMsg
    Call Crlf
  
    ; Print amount
    INVOKE printString, ADDR amount
    INVOKE addDecimalPoint, ADDR inputDepositAmount, ADDR formattedDepositAmount
    INVOKE printString, ADDR formattedDepositAmount
    Call Crlf 

    INVOKE printString, ADDR dateHeader
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
    INVOKE printString, ADDR timeDate
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    Call Crlf
    Call Crlf

    INVOKE printString, ADDR confirmMsg
    Call Crlf
    
    INVOKE promptForIntChoice, 1, 2
    
    .IF CARRY? ; Return if the input is invalid
        INVOKE printString, ADDR invalidOption
        call Wait_Msg
        jmp confirmTransaction
    .ELSEIF al == 1
        jmp validateOTP
    .ELSEIF al == 2
        INVOKE printString, ADDR transactionCancel
        call Wait_Msg
        jmp done
    .ENDIF

validateOTP:
    Call Clrscr
    INVOKE generateOTP, account    ; This puts OTP in eax
    push eax                       ; Save the OTP

    ; Verify OTP with timeout and retry limit
    INVOKE verifyOTP, eax
        
    .IF eax == 1   ; If OTP verification was successful
        INVOKE printString, ADDR transactionVerifiedMsg
        INVOKE printString, ADDR transactionSuccessful
        call Wait_Msg

        ; Get the current account balance and format it (remove decimal point)
        mov esi, account
        add esi, OFFSET userAccount.account_balance
        INVOKE removeDecimalPoint, esi, ADDR formattedAccountBalance

        ; Add the deposit amount to the account balance
        INVOKE decimalArithmetic, ADDR formattedAccountBalance, ADDR inputDepositAmount, ADDR tempBuffer, '+'

        ; Add decimal point back to the result
        INVOKE addDecimalPoint, ADDR tempBuffer, esi

        ; Copy the updated balance into the user's account balance
        mov edi, account
        add edi, OFFSET userAccount.account_balance
        INVOKE Str_copy, esi, edi

        ; Update the user account file with new balance
        INVOKE updateUserAccountFile, account

        ; Format transaction record with the values
        ; Copy transaction ID
        INVOKE Str_copy, ADDR newTransactionId, ADDR transactionRecord.transaction_id

        ; Copy customer id from the sender
        mov esi, account
        add esi, OFFSET userAccount.customer_id
        INVOKE Str_copy, esi, ADDR transactionRecord.customer_id

        ; Set transaction type as "Deposit"
        INVOKE Str_copy, ADDR transferTypeStr, ADDR transactionRecord.transaction_type

        ; Format amount with plus sign (for deposit)
        mov al, '+'
        mov transactionRecord.amount[0], al ; Set first character as '+'
        INVOKE Str_copy, ADDR formattedDepositAmount, ADDR (transactionRecord.amount+1)

        ; Copy updated account balance
        INVOKE Str_copy, edi, ADDR transactionRecord.balance

        ; Set description as "Cash deposit into account"
        INVOKE Str_copy, ADDR transferDesc, ADDR transactionRecord.transaction_detail

        ; Copy date
        INVOKE Str_copy, ADDR timeDate, ADDR transactionRecord.date

        ; Copy time
        lea esi, timeOutputBuffer
        add esi, 11 ; Skip date part
        INVOKE Str_copy, esi, ADDR transactionRecord.time

        ; Insert the transaction log
        INVOKE insertTransaction, ADDR transactionRecord

    .ELSEIF eax == 2 ; IF OTP was expired, resend otp
        INVOKE printString, ADDR resendOTPMsg
        call Wait_Msg
        jmp validateOTP
    .ELSE              ; If OTP verification failed
        INVOKE printString, ADDR transactionFailedMsg
        call Wait_Msg
    .ENDIF
    jmp done

done:
    STC ; Don't logout the user
    ret
processDeposit ENDP
END