INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This procedure reads user transaction data from a single file by customer ID
; Receives: Pointer to userTransaction structure (transaction) with customer_id filled
; Returns: EAX = 0 if the user transaction is not found
; Last update: 25/3/2025
;--------------------------------------------------------------------------------
.data
transactionFileName     BYTE "Users\transactionLog.txt", 0

; Handles and buffers
fileHandle         DWORD ?
readBuffer         BYTE 20480 DUP(?)  ; Larger buffer for multi-transaction file
errorMsg           BYTE "Error: File cannot be opened or read", NEWLINE, 0
pathErrorMsg       BYTE "Error: Invalid file path", NEWLINE, 0
transactionNotFoundMsg BYTE NEWLINE, "Transaction not found.", NEWLINE, 0
bytesRead          DWORD ?
tempBuffer         BYTE 512 DUP(?)
fieldBuffer        BYTE 512 DUP(?)
fieldIndex         DWORD 0
currentLineStart   DWORD 0
foundTransaction   BYTE 0
userCustomerID     BYTE 32 DUP(?)
DepositStr         BYTE "Deposit", 0
TransferStr        BYTE "Transfer", 0

.code
inputFromTransaction PROC,
    transaction: PTR userTransaction
    
    pushad

    ; Copy out the customer_id and store it into esi
    mov esi, [transaction]
    add esi, OFFSET userTransaction.customer_id
    INVOKE Str_copy, esi, ADDR userCustomerID

    ; Open the transaction file
    INVOKE CreateFile, 
        ADDR transactionFileName,        ; lpFileName
        GENERIC_READ,                    ; dwDesiredAccess
        FILE_SHARE_READ,                 ; dwShareMode
        NULL,                            ; lpSecurityAttributes
        OPEN_EXISTING,                   ; dwCreationDisposition
        FILE_ATTRIBUTE_NORMAL,           ; dwFlagsAndAttributes
        NULL                             ; hTemplateFile
        
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenSuccess
    
    ; File open error
    INVOKE printString, ADDR transactionFileName
    call Crlf
    INVOKE printString, ADDR errorMsg

    call Wait_Msg
    mov foundTransaction, 0  ; Set not found flag
    jmp readTransactionFileExit
    
fileOpenSuccess:
    ; Read file content into buffer
    INVOKE ReadFile, 
        fileHandle,                     ; hFile
        ADDR readBuffer,                ; lpBuffer
        SIZEOF readBuffer - 1,          ; nNumberOfBytesToRead
        ADDR bytesRead,                 ; lpNumberOfBytesRead
        NULL                            ; lpOverlapped
    
    ; Check if read was successful
    .IF eax == 0
        INVOKE printString, ADDR errorMsg
        call Wait_Msg
        mov foundTransaction, 0  ; Set not found flag
        jmp readTransactionFileExit
    .ENDIF
    
    ; Add null terminator to buffer
    mov edi, OFFSET readBuffer
    add edi, bytesRead
    mov BYTE PTR [edi], 0
    
    ; Skip the header line
    mov esi, OFFSET readBuffer
    
skipHeaderLoop:
    mov al, [esi]
    cmp al, 0          ; End of buffer?
    je transactionNotFound ; File is empty or only has header
    cmp al, 10         ; LF - new line?
    je foundDataStart
    cmp al, 13         ; CR?
    je skipCR
    inc esi
    jmp skipHeaderLoop
    
skipCR:
    inc esi            ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipHeaderLoop
    inc esi            ; Skip LF
    
foundDataStart:
    
    ; Set foundTransaction flag to 0 (not found)
    mov foundTransaction, 0
    
searchTransactionLoop:
    ; Store the start of current line
    mov currentLineStart, esi
    
    ; Parse transaction_id field from current line (first field)
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Parse customer_id field (second field)
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Compare with input customer_id
    INVOKE Str_compare, ADDR tempBuffer, ADDR userCustomerID
    
    ; If match found, check transaction type
    .IF ZERO?
        ; Parse transaction_type field
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        ; Check if transaction type is Transfer
        INVOKE Str_compare, ADDR tempBuffer, ADDR TransferStr
        .IF ZERO?
            ; Found the transaction! Set flag
            mov foundTransaction, 1
        
            ; Return to the start of this line
            mov esi, currentLineStart
        
            ; Parse all fields for this transaction
            INVOKE parseUserTransaction, transaction
        
            INVOKE printUserTransaction, transaction
            jmp searchTransactionLoop
        .ENDIF

        ; Check if transaction type is Deposit
        INVOKE Str_compare, ADDR tempBuffer, ADDR DepositStr
        .IF ZERO?
            ; Found the transaction! Set flag
            mov foundTransaction, 1
        
            ; Return to the start of this line
            mov esi, currentLineStart
        
            ; Parse all fields for this transaction
            INVOKE parseUserTransaction, transaction
        
            INVOKE printUserTransaction,transaction
            jmp searchTransactionLoop
        .ENDIF
    .ENDIF
    
    ; CustomerID didn't match, skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je transactionNotFound
    cmp al, 10     ; LF?
    je nextLine
    cmp al, 13     ; CR?
    je skipToNextCR
    inc esi
    jmp skipToNextLine
    
skipToNextCR:
    inc esi        ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne skipToNextLine
    inc esi        ; Skip LF
    jmp searchTransactionLoop
    
nextLine:
    inc esi        ; Skip LF
    jmp searchTransactionLoop
    
transactionNotFound:
    mov eax, FALSE
    mov [esp+28], eax
    
readTransactionFileExit:
    INVOKE CloseHandle, fileHandle
    popad
    ret
inputFromTransaction ENDP

;--------------------------------------------------------------------------------
; parseUserTransaction PROC
; Parses all transaction fields for the current user and fills the structure
; Receives: ESI = pointer to start of transaction record in buffer
;           transaction = pointer to userTransaction structure
; Returns: Filled user transaction structure
;--------------------------------------------------------------------------------
parseUserTransaction PROC,
    transaction: PTR userTransaction
    
parseNextTransactionField:
    
    ; Parse transaction_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.transaction_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse customer_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.customer_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse transaction_type field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.transaction_type
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse amount field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.amount
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse date field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.date
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse time field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.time
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
doneParsingFields:
    ret
parseUserTransaction ENDP

END