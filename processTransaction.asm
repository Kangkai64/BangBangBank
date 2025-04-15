
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will process transaction
; Receives : Nothing
; Returns : Nothing
; Last update: 25/3/2025
;------------------------------------------------------------------------
.data
dateHeader BYTE "Date & Time: ", 0
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
transactionPageTitle BYTE "Bang Bang Bank Transaction", NEWLINE,
                          "==============================", NEWLINE,0
transactionDetailTitle BYTE "Transaction details", NEWLINE,
                            "==============================", NEWLINE,0
recipientAccNotFound BYTE "Recipient account not found...", NEWLINE,0
selfAccountErrorMsg BYTE "You cannot enter your own account number as recipient.", NEWLINE, 0
recipientAccount userAccount <>
amount BYTE "Amount : RM ",0
confirmMsg BYTE "Press 1 to confirm and press 2 to cancel", NEWLINE,0
transactionIdMsg BYTE "Transaction ID: ", 0
recipientAccMsg BYTE "Account No: ",0
recipientNameMsg BYTE "Recipient Name: ", 0  
transTypeMsg BYTE "Transaction Type: Transaction", 0
transactionDetailMsg BYTE "Transaction Detail: ", 0
transactionSuccessful BYTE "Transaction Successful!",0
transactionCancel BYTE "Transaction Cancelled!",0
invalidOption BYTE "Invalid option. Please try again.", 0
transactionVerifiedMsg BYTE "OTP verification successful! Transaction completed.", NEWLINE, 0
transactionFailedMsg BYTE "OTP verification failed! Transaction cancelled.", NEWLINE, 0
resendOTPMsg BYTE "OTP will resend to the same file.", 0
inputRecipientAccNo BYTE 255 DUP(?)
inputTransactionAmount BYTE 255 DUP(?)
inputTransactionDetail BYTE 255 DUP(?)
defaultTransactionMessage BYTE "Transfer sent to another account", 0
tempBuffer BYTE 32 DUP(0)
formattedTransactionAmount BYTE 32 DUP(0)
newTransactionId BYTE 255 DUP(?)
transactionRecord userTransaction <>
transferTypeStr BYTE "Transfer", 0
feeApplied BYTE 0      ; Flag: 0 = no fee, 1 = fee applied
oneHundredStr BYTE "100", 0  ; RM 1.00 as 100 cents
extraFeeMsg BYTE "Extra Fee: RM 1.00 (exceeded daily limit)", NEWLINE, 0

.code
processTransaction PROC,
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

    ; prompt for recipient account number
    INVOKE promptForRecipientAccNo, ADDR inputRecipientAccNo

    ;validate recipient account
    INVOKE validateRecipientAcc, ADDR inputRecipientAccNo
    .IF EAX == 0
        INVOKE printString, ADDR recipientAccNotFound
        call Wait_Msg
        STC
        jmp done
    .ENDIF

    ; Store recipient account number into recipientAccount structure
    mov esi, OFFSET inputRecipientAccNo
    INVOKE Str_copy, esi, ADDR recipientAccount.account_number
    
    ; Read user account from userAccount.txt
	INVOKE inputFromAccountByAccNo, ADDR recipientAccount

    ; Prompt for transaction amount
    INVOKE promptForTransactionAmount, ADDR inputTransactionAmount, account
    INVOKE validateTransactionAmount, ADDR inputTransactionAmount, ADDR feeApplied, account
    jc done ; Invalid transaction amount

    ; Prompt for transaction detail
    INVOKE promptForTransactionDetail, ADDR inputTransactionDetail

    ; If empty or user exit, use default message
    .IF CARRY?
        INVOKE Str_copy, ADDR defaultTransactionMessage, ADDR inputTransactionDetail
    .ENDIF

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
    INVOKE printString, ADDR recipientAccount.full_name
    Call Crlf

    ; Print recipient's account
    INVOKE printString, ADDR recipientAccMsg
    INVOKE printString, ADDR inputRecipientAccNo
    Call Crlf
    
    ; Print transaction type
    INVOKE printString, ADDR transTypeMsg
    Call Crlf
  
    ; Print amount
    INVOKE printString, ADDR amount
    INVOKE addDecimalPoint, ADDR inputTransactionAmount, ADDR formattedTransactionAmount
    INVOKE printString, ADDR formattedTransactionAmount
    Call Crlf

    ; Show fee if applicable
    cmp feeApplied, 1
    jne skip_fee_message
    INVOKE printString, ADDR extraFeeMsg
skip_fee_message:

    ; Print transaction detail
    INVOKE printString, ADDR transactionDetailMsg
    INVOKE printString, ADDR inputTransactionDetail
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

        ; Format transaction record with the values
        ; Copy transaction ID
        INVOKE Str_copy, ADDR newTransactionId, ADDR transactionRecord.transaction_id

        ; Copy customer id from the sender
        mov esi, account
        add esi, OFFSET userAccount.customer_id
        INVOKE Str_copy, esi, ADDR transactionRecord.customer_id

        ; Copy account number from the sender
        mov esi, account
        add esi, OFFSET userAccount.account_number
        INVOKE Str_copy, esi, ADDR transactionRecord.sender_account_number

        ; Set transaction type as "Transfer"
        INVOKE Str_copy, ADDR transferTypeStr, ADDR transactionRecord.transaction_type

        ; Copy customer id from the recipient
        lea esi, recipientAccount
        add esi, OFFSET userAccount.customer_id
        INVOKE Str_copy, esi, ADDR transactionRecord.recipient_id

        ; Copy account number from the recipient
        lea esi, recipientAccount
        add esi, OFFSET userAccount.account_number
        INVOKE Str_copy, esi, ADDR transactionRecord.recipient_account_number

        ; Format amount with minus sign (for transfer out)
        mov al, '-'
        mov transactionRecord.amount[0], al ; Set first character as '-'
        INVOKE Str_copy, ADDR formattedTransactionAmount, ADDR (transactionRecord.amount+1)

        ; Get the current account balance and format it (remove decimal point)
        mov esi, account
        add esi, OFFSET userAccount.account_balance
        INVOKE removeDecimalPoint, esi, ADDR formattedTransactionAmount

        ; Calculate and set new balance (current balance - transfer amount)
        INVOKE decimalArithmetic, ADDR formattedTransactionAmount, ADDR inputTransactionAmount, ADDR tempBuffer, '-'

        ; If fee applies, subtract an additional RM 1.00
        cmp feeApplied, 1
        jne skip_fee_charge
        INVOKE decimalArithmetic, ADDR tempBuffer, ADDR oneHundredStr, ADDR tempBuffer, '-'

skip_fee_charge:
        ; Add decimal point back to the result
        INVOKE addDecimalPoint, ADDR tempBuffer, esi

        ; Copy the updated balance into the user's account balance in transaction log
        INVOKE Str_copy, esi, ADDR transactionRecord.balance

        ; Copy the updated balance into the user's account balance in user account
        mov edi, account
        add edi, OFFSET userAccount.account_balance
        INVOKE Str_copy, esi, edi

        ; Update the sender account file with new balance
        INVOKE updateUserAccountFile, account

        ; Get the recipient account balance and format it (remove decimal point)
        lea esi, recipientAccount
        add esi, OFFSET userAccount.account_balance
        INVOKE removeDecimalPoint, esi, ADDR formattedTransactionAmount

        ; Calculate and set new balance (current balance + transfer amount)
        INVOKE decimalArithmetic, ADDR formattedTransactionAmount, ADDR inputTransactionAmount, ADDR tempBuffer, '+'

        ; Add decimal point back to the result
        INVOKE addDecimalPoint, ADDR tempBuffer, esi

        ; Copy the updated balance into the recipient's account balance in user account
        lea edi, recipientAccount
        add edi, OFFSET userAccount.account_balance
        INVOKE Str_copy, esi, edi

        ; Update the recipient account file with new balance
        INVOKE updateUserAccountFile, ADDR recipientAccount

        ; Copy transaction detail
        INVOKE Str_copy, ADDR inputTransactionDetail, ADDR transactionRecord.transaction_detail

        ; Copy date
        INVOKE Str_copy, ADDR timeDate, ADDR transactionRecord.date

        ; Copy time
        lea esi, timeOutputBuffer
        add esi, 11 ; Skip date part
        INVOKE Str_copy, esi, ADDR transactionRecord.time

        ; Insert the transaction log
        INVOKE insertTransaction, ADDR transactionRecord

        call Wait_Msg
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
processTransaction ENDP
END