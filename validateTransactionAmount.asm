 
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will validate the transaction amount whether exceed transaction limit and account balance
; Receives : The address / pointer of the transactionAmount variable
; Returns : Set carry flag if invalid, Clear if valid
; Formats the input for use with decimal arithmetic (without decimal point)
; Last update: 8/4/2025
;------------------------------------------------------------------------
.data
    notSufficientBalance BYTE "Not sufficient balance... ", NEWLINE, 0
    decimalPointChar BYTE ".", 0
    transactionLimit BYTE 32 DUP(?)
    exceedTransactionLimit BYTE "Exceed transaction limit! Will charge extra RM 1 for this transaction.", NEWLINE, 0
    currentStr  BYTE "Current", 0
    senderTransaction userTransaction <>
    currentTime SYSTEMTIME <>
    timeOutputBuffer BYTE 32 DUP(?)
    timeDate BYTE 16 DUP(?)
    dailyTotalTransactions BYTE 32 DUP('0')

.code
validateTransactionAmount PROC,
    inputTransactionAmountAddress: PTR BYTE,
    feeApplied: PTR BYTE,
    account: PTR userAccount
    
    LOCAL tempBuffer[32]: BYTE
    LOCAL formattedAccountBalance[32]: BYTE
    LOCAL formattedTransAmount[32]: BYTE
    LOCAL totalWithCurrentTransaction[32]: BYTE
    
    pushad
   
    ; First, check if it's a Current account
    mov esi, [account]
    lea edi, [esi + OFFSET userAccount.account_type]
    INVOKE Str_compare, edi, ADDR currentStr
    .IF ZERO?
        ; Get transaction limit
        mov esi, [account]
        lea edi, [esi + OFFSET userAccount.transaction_limit]
        INVOKE removeDecimalPoint, edi, ADDR transactionLimit
        
        ; Setup senderTransaction structure
        mov esi, [account]
        add esi, OFFSET userAccount.account_number
        INVOKE Str_copy, esi, ADDR senderTransaction.sender_account_number
        
        ; Get current date
        INVOKE GetLocalTime, ADDR currentTime
        INVOKE formatSystemTime, ADDR currentTime, ADDR timeOutputBuffer
        ; Copy date portion
        lea esi, timeOutputBuffer
        lea edi, timeDate
        mov ecx, 10
    copy_date:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        LOOP copy_date
        mov BYTE PTR [edi], 0
        
        ; Call procedure to get sum of all transactions today
        INVOKE inputTotalTransactionFromTransaction, ADDR senderTransaction, ADDR timeDate, ADDR dailyTotalTransactions
        call Crlf

        ; Format the new transaction amount
        INVOKE removeDecimalPoint, inputTransactionAmountAddress, ADDR formattedTransAmount
        
        ; Add new transaction to today's total
        INVOKE decimalArithmetic, ADDR dailyTotalTransactions, ADDR formattedTransAmount, ADDR totalWithCurrentTransaction, '-'

        call Crlf
        ; Compare total+new with limit
        INVOKE decimalArithmetic, ADDR transactionLimit, ADDR totalWithCurrentTransaction, ADDR tempBuffer, '+'
        
        ; Check if result is negative (over limit)
        lea esi, tempBuffer
        mov al, [esi]
        cmp al, '-'
        jne check_balance  ; Not over limit, proceed
        
        ; Over limit - display message
        INVOKE printString, ADDR exceedTransactionLimit
        mov esi, feeApplied    ; Load address of feeApplied into esi
        mov BYTE PTR [esi], 1  ; Store 1 at the address in esi
    .ENDIF
    
check_balance:
    ; Check whether user has enough balance
    ; Convert account_balance to numeric value first
    mov esi, [account]
    lea esi, [esi + OFFSET userAccount.account_balance]
    
    INVOKE removeDecimalPoint, esi, ADDR formattedAccountBalance
    INVOKE removeDecimalPoint, inputTransactionAmountAddress, ADDR tempBuffer
    
    ; Compare transaction amount with account balance
    ; We'll use decimalArithmetic with subtraction to see if result is negative
    INVOKE decimalArithmetic, ADDR formattedAccountBalance, ADDR tempBuffer, ADDR tempBuffer, '-'
    
    ; Check if first character of result is '-' (negative)
    lea esi, tempBuffer
    mov al, [esi]
    cmp al, '-'
    je insufficient_balance
    ; Clear carry flag to indicate success (if we hadn't already set it for exceeding limit)
    CLC
    jmp done
    
insufficient_balance:
    INVOKE printString, ADDR notSufficientBalance
    call Wait_Msg
    STC     ; Set carry flag to indicate failure
    
done:
    popad
    ret
validateTransactionAmount ENDP
END