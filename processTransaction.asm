INCLUDE BangBangBank.inc
;------------------------------------------------------------------------
; This module will process transaction
; Receives : Nothing
; Returns : Nothing
; Last update: 25/3/2025
;------------------------------------------------------------------------
.data
dateHeader BYTE "Date & Time: ", 0
colorCode BYTE (yellow + (black SHL 4))
defaultColor BYTE ?
currentTime SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
transactionPageTitle BYTE "Bang Bang Bank Transaction", NEWLINE,
                          "==============================", NEWLINE,0
transactionDetailTitle BYTE "Transaction details", NEWLINE,
                            "==============================", NEWLINE,0
recipientAccNotFound BYTE "Recipient account not found...", NEWLINE,0
selfAccountErrorMsg BYTE "You cannot enter your own account number as recipient.", NEWLINE, 0
amount BYTE "Amount : RM ",0
confirmMsg BYTE "Press 1 to confirm and press 2 to cancel", NEWLINE,0
transactionIdMsg BYTE "Transaction ID: ", 0
recipientAccMsg BYTE "Account No: ",0
recipientNameMsg BYTE "Recipient Name: ", 0  
transTypeMsg BYTE "Transaction Type: Transaction", 0
transactionSuccessful BYTE "Transaction Successful!",0
transactionCancel BYTE "Transaction Cancelled!",0
inputRecipientAccNo BYTE 32 DUP(?)
inputTransactionAmount BYTE 32 DUP(?)
recipientName BYTE 32 DUP(?)
newTransactionId BYTE 32 DUP(?)
.code
processTransaction PROC,
    account: PTR userAccount
    call Clrscr
    ; Get console default text color
    call GetTextColor
    mov defaultColor, al
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
    INVOKE promptForRecipientAccNo, OFFSET inputRecipientAccNo

    ;validate recipient account
    INVOKE validateRecipientAcc, OFFSET inputRecipientAccNo
    .IF EAX == 0
        INVOKE printString, ADDR recipientAccNotFound
        call Wait_Msg
        STC
        jmp done
    .ENDIF
    ;prompt transaction amount
    INVOKE promptForTransactionAmount, OFFSET inputTransactionAmount, account

    jmp confirmTransaction
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
    INVOKE printString, ADDR recipientName
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
    ; Convert numeric amount back to string for printing
    ;mov eax, ebx    ; Move number to convert into eax
    ;lea edi, inputTransactionAmount  ; Point to destination buffer
    ;call IntToString
    INVOKE printString, ADDR inputTransactionAmount
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
        jmp confirmTransaction
    .ELSEIF al == 1
        Call Clrscr
        INVOKE generateOTP, account
        INVOKE printString, ADDR transactionSuccessful
        call Wait_Msg
        jmp done
    .ELSEIF al == 2
        INVOKE printString, ADDR transactionCancel
        call Wait_Msg
        jmp done
    .ENDIF

    done:
        STC
        ret
processTransaction ENDP
END