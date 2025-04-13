
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; BangBangBank File Operations Module
; Unified procedures for reading, writing, and updating bank data files
; Last update: 08/04/2025
;--------------------------------------------------------------------------------

.data
; File type constants
FILE_TYPE_CREDENTIALS   EQU 1
FILE_TYPE_ACCOUNTS      EQU 2
FILE_TYPE_TRANSACTIONS  EQU 3

; File paths
credentialFileName     BYTE "Users\userCredential.txt", 0
tempCredentialFile     BYTE "Users\userCredential.tmp", 0
accountFileName        BYTE "Users\userAccount.txt", 0
tempAccountFile        BYTE "Users\userAccount.tmp", 0
transactionFileName    BYTE "Users\transactionLog.txt", 0
tempTransactionFile    BYTE "Users\transactionLog.tmp", 0
directoryPath          BYTE "Users\", 0

; File handling variables
currentSourceFile      DWORD ?  ; Pointer to current source file path
currentTempFile        DWORD ?  ; Pointer to current temp file path
fileHandle            DWORD ?
fileReadHandle        DWORD ?
fileWriteHandle       DWORD ?
readBuffer            BYTE 20480 DUP(?)  ; Larger buffer for file reading
bytesRead             DWORD ?
bytesWritten          DWORD ?

; Buffer variables
readLineBuffer        BYTE 1024 DUP(?)  ; Buffer for reading lines
tempBuffer            BYTE 512 DUP(?)   ; For temporary storage
fieldBuffer           BYTE 512 DUP(?)   ; Buffer for extracted field
outputBuffer          BYTE 4096 DUP(?)  ; Buffer for writing
eolMarker             BYTE NEWLINE, 0   ; End of line marker
formatPtr             DWORD ?
currentLineStart      DWORD 0

; Flags and fields
foundUser             BYTE 0
foundAccount          BYTE 0
foundTransaction      BYTE 0
inputUsername         BYTE 64 DUP(?)
userCustomerID        BYTE 32 DUP(?)
userAccountNumber     BYTE 32 DUP(?)
fieldIndex            DWORD 0
totalCredit   BYTE 32 DUP('0'), 0  ; Buffer for storing credit total as string
totalDebit    BYTE 32 DUP('0'), 0  ; Buffer for storing debit total as string

; Error messages
errorMsg              BYTE "Error: File cannot be opened or read", NEWLINE, 0
pathErrorMsg          BYTE "Error: Invalid file path", NEWLINE, 0
userNotFoundMsg       BYTE NEWLINE, "User not found.", NEWLINE, 0
fileReadErrorMsg      BYTE "Error: Could not open source file for reading", 0
fileWriteErrorMsg     BYTE "Error: Could not open temporary file for writing", 0
fileDeleteErrorMsg    BYTE "Error: Could not delete original file", 0
fileRenameErrorMsg    BYTE "Error: Could not rename temporary file", 0

; CSV formatting
commaChar             BYTE ",", 0
zeroVal               BYTE "0", 0
dashVal               BYTE "-", 0
spaceChar             BYTE " ", 0

; Transaction type strings
DepositStr            BYTE "Deposit", 0
TransferStr           BYTE "Transfer", 0

; CSV Headers
headerCredentialLine  BYTE "username,hashed_password,hashed_PIN,customer_id,encryption_key,loginAttempt,firstLoginAttemptTimestamp", NEWLINE, 0
headerAccountLine     BYTE "account_number,customer_id,full_name,phone_number,email,account_balance,opening_date,transaction_limit,branch_name,branch_address,account_type,currency,beneficiaries", NEWLINE, 0
headerTransactionLine BYTE "transaction_id,customer_id,sender_account_number,transaction_type,recipient_id,recipient_account_number,amount,balance,transaction_detail,date,time", NEWLINE, 0

; System time structure for timestamps
currTime              SYSTEMTIME <>

.code
;--------------------------------------------------------------------------------
; inputFromFile PROC
; Reads user credentials from a file
; Receives: Pointer to userCredential structure (user)
; Returns: EAX = 0 if the user is not found
; Last update: 08/04/2025
;--------------------------------------------------------------------------------
inputFromFile PROC,
    user: PTR userCredential
    
    pushad

    ; Copy out the username and store it into inputUsername
    mov esi, [user]
    add esi, OFFSET userCredential.username
    INVOKE Str_copy, esi, ADDR inputUsername

    ; Open the credentials file
    INVOKE CreateFile, 
        ADDR credentialFileName,         ; lpFileName
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
    INVOKE printString, ADDR credentialFileName
    call Crlf
    INVOKE printString, ADDR errorMsg

    ; Try to create directory
    INVOKE CreateDirectory, ADDR directoryPath, NULL
    test eax, eax    ; Check if directory creation was successful
    jnz directoryCreated

    ; Directory creation failed
    call Crlf
    INVOKE printString, ADDR pathErrorMsg
    INVOKE printString, ADDR directoryPath
    call Crlf

directoryCreated:
    call Wait_Msg
    STC ; Set carry flag
    jmp inputFileExit
    
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
        STC ; Set carry flag
        jmp inputFileExit
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
    je userNotFound    ; File is empty or only has header
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
    
    ; Set foundUser flag to 0 (not found)
    mov foundUser, 0
    
searchUserLoop:
    ; Store the start of current line
    mov currentLineStart, esi
    
    ; Parse username field from current line
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Compare with input username
    INVOKE Str_compare, ADDR tempBuffer, ADDR inputUsername
    
    ; If match found, process this record
    .IF ZERO?
        ; Found the user! Set flag
        mov foundUser, 1
        
        ; Return to the start of this line
        mov esi, currentLineStart
        
        ; Parse all fields for this user
        INVOKE parseUserCredentials, user
        
        jmp inputFileExit
    .ENDIF
    
    ; Username didn't match, skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je userNotFound
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
    jmp searchUserLoop
    
nextLine:
    inc esi        ; Skip LF
    jmp searchUserLoop
    
userNotFound:
    mov eax, FALSE
    mov [esp+28], eax
    
inputFileExit:
    INVOKE CloseHandle, fileHandle
    popad
    ret
inputFromFile ENDP

;--------------------------------------------------------------------------------
; parseUserCredentials PROC
; Parses all credential fields for the current user and fills the structure
; Receives: ESI = pointer to start of user record in buffer
;           user = pointer to userCredential structure
; Returns: Filled user credential structure
;--------------------------------------------------------------------------------
parseUserCredentials PROC,
    user: PTR userCredential

parseNextCredField:
    ; Parse username field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.username
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse hashed_password field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.hashed_password
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse hashed_pin field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.hashed_pin
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse customer_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.customer_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse encryption_key field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.encryption_key
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse loginAttempt field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.loginAttempt
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse firstLoginAttemptTimestamp field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, user
    add edi, OFFSET userCredential.firstLoginAttemptTimestamp
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
doneParsingFields:
    ret
parseUserCredentials ENDP

;--------------------------------------------------------------------------------
; inputFromAccount PROC
; This procedure reads user account data from a single file by customer ID
; Receives: Pointer to userAccount structure (account) with customer_id filled
; Returns: EAX = 0 if the user account is not found
; Last update: 08/04/2025
;--------------------------------------------------------------------------------
inputFromAccount PROC,
    account: PTR userAccount
    
    pushad

    ; Copy out the customer_id and store it into userCustomerID
    mov esi, [account]
    add esi, OFFSET userAccount.customer_id
    INVOKE Str_copy, esi, ADDR userCustomerID

    ; Open the account file
    INVOKE CreateFile, 
        ADDR accountFileName,            ; lpFileName
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
    INVOKE printString, ADDR accountFileName
    call Crlf
    INVOKE printString, ADDR errorMsg

    call Wait_Msg
    mov foundAccount, 0  ; Set not found flag
    jmp readAccountFileExit
    
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
        mov foundAccount, 0  ; Set not found flag
        jmp readAccountFileExit
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
    je accountNotFound ; File is empty or only has header
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
    
    ; Set foundAccount flag to 0 (not found)
    mov foundAccount, 0
    
searchAccountLoop:
    ; Store the start of current line
    mov currentLineStart, esi
    
    ; Skip account_number field (first field)
    mov edi, OFFSET tempBuffer
    call ParseCSVField
    
    ; Parse customer_id field from current line (second field)
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Compare with input customer_id
    INVOKE Str_compare, ADDR tempBuffer, ADDR userCustomerID
    
    ; If match found
    .IF ZERO?
        ; Found the account! Set flag
        mov foundAccount, 1
        
        ; Return to the start of this line
        mov esi, currentLineStart
        
        ; Parse all fields for this account
        INVOKE parseUserAccount, account
        
        jmp readAccountFileExit
    .ENDIF
    
    ; CustomerID didn't match, skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je accountNotFound
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
    jmp searchAccountLoop
    
nextLine:
    inc esi        ; Skip LF
    jmp searchAccountLoop
    
accountNotFound:
    mov eax, FALSE
    mov [esp+28], eax
    
readAccountFileExit:
    INVOKE CloseHandle, fileHandle
    popad
    ret
inputFromAccount ENDP

;--------------------------------------------------------------------------------
; inputFromAccountByAccNo PROC
; This procedure reads user account data from a single file by account number
; Receives: Pointer to userAccount structure (account) with account number filled
; Returns: EAX = 0 if the user account is not found
; Last update: 08/04/2025
;--------------------------------------------------------------------------------
inputFromAccountByAccNo PROC,
    recipientAccount: PTR userAccount
    
    pushad

    ; Copy out the account number and store it into userAccountNumber
    mov esi, [recipientAccount]
    add esi, OFFSET userAccount.account_number
    INVOKE Str_copy, esi, ADDR userAccountNumber

    ; Open the account file
    INVOKE CreateFile, 
        ADDR accountFileName,            ; lpFileName
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
    INVOKE printString, ADDR accountFileName
    call Crlf
    INVOKE printString, ADDR errorMsg

    call Wait_Msg
    mov foundAccount, 0  ; Set not found flag
    jmp readAccountFileExit
    
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
        mov foundAccount, 0  ; Set not found flag
        jmp readAccountFileExit
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
    je accountNotFound ; File is empty or only has header
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
    
    ; Set foundAccount flag to 0 (not found)
    mov foundAccount, 0
    
searchAccountLoop:
    ; Store the start of current line
    mov currentLineStart, esi
    
    ; Parse account_number field from current line (first field)
    mov edi, OFFSET tempBuffer
    call ParseCSVField

    ; Compare with input account number
    INVOKE Str_compare, ADDR tempBuffer, ADDR userAccountNumber
    
    ; If match found
    .IF ZERO?
        ; Found the account! Set flag
        mov foundAccount, 1
        
        ; Return to the start of this line
        mov esi, currentLineStart
        
        ; Parse all fields for this account
        INVOKE parseUserAccount, recipientAccount
        
        jmp readAccountFileExit
    .ENDIF
    
    ; CustomerID didn't match, skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je accountNotFound
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
    jmp searchAccountLoop
    
nextLine:
    inc esi        ; Skip LF
    jmp searchAccountLoop
    
accountNotFound:
    mov eax, FALSE
    mov [esp+28], eax
    
readAccountFileExit:
    INVOKE CloseHandle, fileHandle
    popad
    ret
inputFromAccountByAccNo ENDP

;--------------------------------------------------------------------------------
; parseUserAccount PROC
; Parses all account fields for the current user and fills the structure
; Receives: ESI = pointer to start of account record in buffer
;           account = pointer to userAccount structure
; Returns: Filled user account structure
;--------------------------------------------------------------------------------
parseUserAccount PROC,
    account: PTR userAccount
    
parseNextAccountField:
    
    ; Parse account_number field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.account_number
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse customer_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.customer_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse full_name field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.full_name
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse phone_number field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.phone_number
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse email field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.email
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse account_balance field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.account_balance
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse opening_date field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.opening_date
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse transaction_limit field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.transaction_limit
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse branch_name field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.branch_name
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse branch_address field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.branch_address
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse account_type field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.account_type
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse currency field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.currency
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse beneficiaries field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, account
    add edi, OFFSET userAccount.beneficiaries
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
doneParsingFields:
    ret
parseUserAccount ENDP

;--------------------------------------------------------------------------------
; inputFromTransaction PROC
; This procedure reads user transaction data from a single file by customer ID and month
; Receives: Pointer to userTransaction structure (transaction) with customer_id filled
;           and selected month as a string (e.g., "01", "02", ..., "12")
; Returns: EAX = 0 if no transactions found for the user in the selected month
; Last update: 13/04/2025
;--------------------------------------------------------------------------------
inputFromTransaction PROC,
    transaction: PTR userTransaction,
    selectedMonth: PTR BYTE    ; Pointer to a 2-character month string ("01"-"12")
    
    LOCAL monthBuffer[3]: BYTE  ; Buffer to hold 2 digits + null terminator
    
    pushad

    ; Copy out the customer_id and store it into userCustomerID
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
    
    ; If customer_id matches, check the date for month
    .IF ZERO?
        ; Store the current position
        push esi
        
        ; Skip to date field (10th field)
        ; Skip fields 3-9
        mov ecx, 7  ; Need to skip 7 more fields to reach date field
    skipToDateField:
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        loop skipToDateField
        
        ; Parse date field
        mov edi, OFFSET tempBuffer
        call ParseCSVField
        
        ; Extract month from date (format: DD/MM/YYYY)
        ; Month is at index 3-4
        
        ; Copy month part to buffer
        mov al, [tempBuffer+3]  ; First digit of month
        mov [monthBuffer], al
        mov al, [tempBuffer+4]  ; Second digit of month
        mov [monthBuffer+1], al
        mov BYTE PTR [monthBuffer+2], 0  ; Null terminator
        
        ; Compare with selected month
        INVOKE Str_compare, ADDR monthBuffer, selectedMonth
        
        ; Restore position for further processing
        pop esi
        
        ; If month matches, process the transaction
        .IF ZERO?
            ; Found a transaction for this customer in the selected month! Set flag
            mov foundTransaction, 1
            
            ; Return to the start of this line
            mov esi, currentLineStart
        
            ; Parse all fields for this transaction
            INVOKE parseUserTransaction, transaction
            
            ; Process based on transaction type
            mov edi, transaction
            add edi, OFFSET userTransaction.transaction_type
            INVOKE Str_compare, edi, ADDR TransferStr
            .IF ZERO?
                INVOKE calculateTotalCredit, transaction
            .ELSE
                INVOKE Str_compare, edi, ADDR DepositStr
                .IF ZERO?
                    INVOKE calculateTotalDebit, transaction
                .ENDIF
            .ENDIF
            
            INVOKE calculateDailyAverageBalance, transaction
            INVOKE printUserTransaction, transaction
        .ENDIF
    .ENDIF
    
    ; Skip to next line
skipToNextLine:
    mov al, [esi]
    cmp al, 0      ; End of file?
    je doneSearching
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
    jmp readTransactionFileExit
    
doneSearching:
    ; If we found at least one transaction, return success
    .IF foundTransaction == 1
        mov eax, TRUE
        mov [esp+28], eax
    .ELSE
        mov eax, FALSE
        mov [esp+28], eax
    .ENDIF
    
readTransactionFileExit:
    .IF foundTransaction == 1
        INVOKE calculateAverageBalance, transaction
    .ENDIF
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
; Last update: 10/04/2025
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
    
    ; Parse sender_account_number field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.sender_account_number
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse transaction_type field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.transaction_type
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse recipient_id field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.recipient_id
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse recipient_account_number field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.recipient_account_number
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse amount field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.amount
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse balance field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.balance
    INVOKE Str_copy, ADDR fieldBuffer, edi
    
    ; Parse transaction_detail field
    mov edi, OFFSET fieldBuffer
    call ParseCSVField
    mov edi, transaction
    add edi, OFFSET userTransaction.transaction_detail
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