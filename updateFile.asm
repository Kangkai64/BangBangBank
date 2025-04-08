
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module provides unified file updating for user files
; Can update: user credentials, account information, and transactions
; Last update: 07/04/2025
;--------------------------------------------------------------------------------
.data
; File type constants
FILE_TYPE_CREDENTIALS   EQU 1
FILE_TYPE_ACCOUNTS      EQU 2
FILE_TYPE_TRANSACTIONS  EQU 3

; File paths
credentialSourceFile    BYTE "Users\userCredential.txt", 0  ; Source file for credentials
tempCredentialFile      BYTE "Users\userCredential.tmp", 0  ; Temporary file for credentials
accountSourceFile       BYTE "Users\userAccount.txt", 0    ; Source file for accounts
tempAccountFile         BYTE "Users\userAccount.tmp", 0    ; Temporary file for accounts
transactionSourceFile   BYTE "Users\transactionLog.txt", 0    ; Source file for transactions
tempTransactionFile     BYTE "Users\transactionLog.tmp", 0    ; Temporary file for transactions

; File handling variables - shared across all file types
currentSourceFile       DWORD ?  ; Pointer to current source file path
currentTempFile         DWORD ?  ; Pointer to current temp file path
fileReadHandle          DWORD ?  ; Handle for file reading
fileWriteHandle         DWORD ?  ; Handle for file writing
bytesRead               DWORD ?  ; Bytes read from file
bytesWritten            DWORD ?  ; Bytes written to file

; Shared buffers for all file types
readLineBuffer          BYTE 1024 DUP(?)  ; Buffer for reading lines
tempFieldBuffer         BYTE 512 DUP(?)   ; Buffer for extracted field
outputBuffer            BYTE 4096 DUP(?)  ; Buffer for writing (increased for larger structures)
eolMarker               BYTE NEWLINE, 0   ; End of line marker
formatPtr               DWORD ?

; Error messages
fileReadErrorMsg        BYTE "Error: Could not open source file for reading", 0
fileWriteErrorMsg       BYTE "Error: Could not open temporary file for writing", 0
fileDeleteErrorMsg      BYTE "Error: Could not delete original file", 0
fileRenameErrorMsg      BYTE "Error: Could not rename temporary file", 0

; CSV formatting
commaChar               BYTE ",", 0
zeroVal                 BYTE "0", 0
dashVal                 BYTE "-", 0
spaceChar               BYTE " ", 0

; CSV Headers - used when creating new files
headerCredentialLine    BYTE "username,hashed_password,hashed_PIN,customer_id,encryption_key,loginAttempt,firstLoginAttemptTimestamp", NEWLINE, 0
headerAccountLine       BYTE "account_number,customer_id,full_name,phone_number,email,account_balance,opening_date,transaction_limit,branch_name,branch_address,account_type,currency,beneficiaries", NEWLINE, 0
headerTransactionLine   BYTE "transaction_id,customer_id,transaction_type,amount,balance,transaction_detail,date,time", NEWLINE, 0

; System time structure for timestamps
currTime                SYSTEMTIME <>

.code
;----------------------------------------------------------------------------------------------
; updateFile PROC
; Unified procedure to update any of the three file types
; Receives: 
;   - fileType: Type of file to update (1 = credentials, 2 = accounts, 3 = transactions)
;   - recordPtr: Pointer to the record structure (userCredential/userAccount/userTransaction)
;   - keyFieldOffset: Offset to the key field in the structure (used for matching)
; Returns: Carry flag is set if failed, clear if successful
;----------------------------------------------------------------------------------------------
updateFile PROC,
    fileType:DWORD,
    recordPtr:PTR BYTE,
    keyFieldOffset:DWORD

    LOCAL recordFound:BYTE
    
    pushad
    
    ; Initialize recordFound flag
    mov recordFound, 0
    
    ; Set up file paths based on file type
    .IF fileType == FILE_TYPE_CREDENTIALS
        mov eax, OFFSET credentialSourceFile
        mov currentSourceFile, eax
        mov eax, OFFSET tempCredentialFile
        mov currentTempFile, eax
    .ELSEIF fileType == FILE_TYPE_ACCOUNTS
        mov eax, OFFSET accountSourceFile
        mov currentSourceFile, eax
        mov eax, OFFSET tempAccountFile
        mov currentTempFile, eax
    .ELSEIF fileType == FILE_TYPE_TRANSACTIONS
        mov eax, OFFSET transactionSourceFile
        mov currentSourceFile, eax
        mov eax, OFFSET tempTransactionFile
        mov currentTempFile, eax
    .ELSE
        ; Invalid file type
        STC  ; Return failure
        jmp updateExit
    .ENDIF
    
    ; Open source file for reading
    INVOKE CreateFile,
        currentSourceFile,
        GENERIC_READ,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    
    ; Save handle
    mov fileReadHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne readFileOpened
    
    ; File open error
    INVOKE printString, ADDR fileReadErrorMsg
    call Crlf
    STC  ; Return failure
    jmp updateExit
    
readFileOpened:
    ; Create temporary file for writing
    INVOKE CreateFile,
        currentTempFile,
        GENERIC_WRITE,
        0,
        NULL,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    
    ; Save handle
    mov fileWriteHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne processNextLine
    
    ; File open error
    INVOKE printString, ADDR fileWriteErrorMsg
    call Crlf
    
    ; Close read handle
    INVOKE CloseHandle, fileReadHandle
    STC ; Return failure
    jmp updateExit
    
    ; Process file line by line
processNextLine:
    ; Initialize read line buffer
    mov edi, OFFSET readLineBuffer
    mov BYTE PTR [edi], 0
    
    ; Read a line from the file
    call ReadLineFromFile
    
    ; Check for EOF
    cmp bytesRead, 0
    je processingComplete
    
    ; Extract key field from line (first field before comma)
    mov esi, OFFSET readLineBuffer
    mov edi, OFFSET tempFieldBuffer
    call parseCSVField
    
    ; Compare with key field from record struct
    mov edi, recordPtr
    add edi, keyFieldOffset  ; Add offset to get to the key field
    INVOKE Str_compare, ADDR tempFieldBuffer, edi
    
    ; If keys match, write our updated record instead
    jnz writeOriginalLine
    
    ; Key matched, mark as found
    mov recordFound, 1
    
    ; Format data line based on file type
    mov edi, OFFSET outputBuffer
    mov BYTE PTR [edi], 0   ; Start with empty string

    ; Move the recordPtr for formatting
    mov esi, recordPtr
    mov formatPtr, esi
    
    .IF fileType == FILE_TYPE_CREDENTIALS
        call formatCredentialRecord
    .ELSEIF fileType == FILE_TYPE_ACCOUNTS
        call formatAccountRecord
    .ELSEIF fileType == FILE_TYPE_TRANSACTIONS
        call formatTransactionRecord
    .ENDIF
    
    ; Add newline
    mov eax, OFFSET eolMarker
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ; Write updated line to file
    INVOKE Str_length, ADDR outputBuffer
    mov ecx, eax                         
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR outputBuffer,
        ecx,                             
        ADDR bytesWritten,
        NULL
    
    jmp processNextLine
    
writeOriginalLine:
    ; Write original line unchanged + newline if needed
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR readLineBuffer,
        bytesRead,
        ADDR bytesWritten,
        NULL
        
    ; Check if the line already ends with newline
    mov esi, OFFSET readLineBuffer
    add esi, bytesRead
    dec esi
    cmp BYTE PTR [esi], 10  ; LF
    je processNextLine      ; Already has newline
    
    ; Add newline if needed
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR eolMarker,
        SIZEOF eolMarker - 1,  ; Exclude null terminator
        ADDR bytesWritten,
        NULL
    
    jmp processNextLine
    
processingComplete:
    ; Close both files
    INVOKE CloseHandle, fileReadHandle
    INVOKE CloseHandle, fileWriteHandle
    
    ; Replace original file with updated file
    ; First, try to delete the original file
    INVOKE DeleteFile, currentSourceFile
    
    ; Check if delete was successful
    .IF eax == 0
        INVOKE printString, ADDR fileDeleteErrorMsg
        call Crlf
        STC ; Return failure
        jmp updateExit
    .ENDIF
    
    ; Rename temp file to original filename
    INVOKE MoveFile, currentTempFile, currentSourceFile
    
    ; Check if rename was successful
    .IF eax == 0
        INVOKE printString, ADDR fileRenameErrorMsg
        call Crlf
        STC  ; Return failure
        jmp updateExit
    .ENDIF
    
    ; Success
    CLC ; Return success
    
updateExit:
    popad
    
    ; Return success/failure via carry flag
    ret
updateFile ENDP

;--------------------------------------------------------------------------------
; formatCredentialRecord PROC
; Formats a userCredential record into outputBuffer
; Receives: formatPtr (global) - Pointer to userCredential structure
; Returns: outputBuffer filled with formatted CSV line
;--------------------------------------------------------------------------------
formatCredentialRecord PROC USES eax edx
    ; Add username
    mov edx, formatPtr
    add edx, OFFSET userCredential.username
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add hashed_password
    mov edx, formatPtr
    add edx, OFFSET userCredential.hashed_password
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add hashed_pin
    mov edx, formatPtr
    add edx, OFFSET userCredential.hashed_pin
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add customer_id
    mov edx, formatPtr
    add edx, OFFSET userCredential.customer_id
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add encryption_key
    mov edx, formatPtr
    add edx, OFFSET userCredential.encryption_key
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add loginAttempt
    mov edx, formatPtr
    add edx, OFFSET userCredential.loginAttempt
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add firstLoginAttemptTimestamp
    mov edx, formatPtr
    add edx, OFFSET userCredential.firstLoginAttemptTimestamp
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ret
formatCredentialRecord ENDP

;--------------------------------------------------------------------------------
; formatAccountRecord PROC
; Formats a userAccount record into outputBuffer
; Receives: formatPtr (global) - Pointer to userAccount structure
; Returns: outputBuffer filled with formatted CSV line
;--------------------------------------------------------------------------------
formatAccountRecord PROC USES eax edx
    ; Add account_number
    mov edx, formatPtr
    add edx, OFFSET userAccount.account_number
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add customer_id
    mov edx, formatPtr
    add edx, OFFSET userAccount.customer_id
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add full_name
    mov edx, formatPtr
    add edx, OFFSET userAccount.full_name
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add phone_number
    mov edx, formatPtr
    add edx, OFFSET userAccount.phone_number
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add email
    mov edx, formatPtr
    add edx, OFFSET userAccount.email
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add account_balance
    mov edx, formatPtr
    add edx, OFFSET userAccount.account_balance
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add opening_date
    mov edx, formatPtr
    add edx, OFFSET userAccount.opening_date
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add transaction_limit
    mov edx, formatPtr
    add edx, OFFSET userAccount.transaction_limit
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add branch_name
    mov edx, formatPtr
    add edx, OFFSET userAccount.branch_name
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add branch_address
    mov edx, formatPtr
    add edx, OFFSET userAccount.branch_address
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add account_type
    mov edx, formatPtr
    add edx, OFFSET userAccount.account_type
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add currency
    mov edx, formatPtr
    add edx, OFFSET userAccount.currency
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add beneficiaries
    mov edx, formatPtr
    add edx, OFFSET userAccount.beneficiaries
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ret
formatAccountRecord ENDP

;--------------------------------------------------------------------------------
; formatTransactionRecord PROC
; Formats a userTransaction record into outputBuffer
; Receives: formatPtr (global) - Pointer to userTransaction structure
; Returns: outputBuffer filled with formatted CSV line
;--------------------------------------------------------------------------------
formatTransactionRecord PROC USES eax edx
    ; Add transaction_id
    mov edx, formatPtr
    add edx, OFFSET userTransaction.transaction_id
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add customer_id
    mov edx, formatPtr
    add edx, OFFSET userTransaction.customer_id
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add transaction_type
    mov edx, formatPtr
    add edx, OFFSET userTransaction.transaction_type
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add amount
    mov edx, formatPtr
    add edx, OFFSET userTransaction.amount
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add balance
    mov edx, formatPtr
    add edx, OFFSET userTransaction.balance
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add transaction_detail
    mov edx, formatPtr
    add edx, OFFSET userTransaction.transaction_detail
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add date
    mov edx, formatPtr
    add edx, OFFSET userTransaction.date
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    call addComma
    
    ; Add time
    mov edx, formatPtr
    add edx, OFFSET userTransaction.time
    mov eax, edx
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ret
formatTransactionRecord ENDP

;--------------------------------------------------------------------------------
; addComma PROC
; This module will add a comma when formatting data
; Receives: The address / pointer of the output string is expected to be in EDX
; Returns: Nothing
;--------------------------------------------------------------------------------
addComma PROC
    ; Add comma
    mov eax, OFFSET commaChar
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx

    ret
addComma ENDP

;--------------------------------------------------------------------------------
; ReadLineFromFile PROC
; Reads a line from the file into readLineBuffer
; Receives: fileReadHandle - global variable with file handle
; Returns: bytesRead - number of bytes read, buffer filled
;--------------------------------------------------------------------------------
ReadLineFromFile PROC USES eax ebx ecx edx esi edi
    LOCAL charBuffer:BYTE
    LOCAL charBytesRead:DWORD
    
    ; Initialize
    mov bytesRead, 0
    mov edi, OFFSET readLineBuffer
    
readCharLoop:
    ; Read a single character
    INVOKE ReadFile,
        fileReadHandle,
        ADDR charBuffer,
        1,
        ADDR charBytesRead,
        NULL
    
    ; Check for EOF
    mov eax, charBytesRead
    cmp eax, 0
    je endOfReadLine
    
    ; Check for CR (13)
    cmp charBuffer, 13
    je checkForLF
    
    ; Check for LF (10) alone
    cmp charBuffer, 10
    je endOfLine
    
    ; Regular character, store it and continue
    mov al, charBuffer
    mov [edi], al
    inc edi
    inc bytesRead
    jmp readCharLoop
    
checkForLF:
    ; We found CR, peek ahead for LF
    INVOKE ReadFile,
        fileReadHandle,
        ADDR charBuffer,
        1,
        ADDR charBytesRead,
        NULL
    
    ; If EOF, we're done
    cmp charBytesRead, 0
    je endOfReadLine
    
    ; If LF, we've found CRLF sequence
    cmp charBuffer, 10
    je endOfLine
    
    ; Not LF, store this character and continue
    mov al, charBuffer
    mov [edi], al
    inc edi
    inc bytesRead
    jmp readCharLoop
    
endOfLine:
    ; Add null terminator
    mov BYTE PTR [edi], 0
    jmp readLineDone
    
endOfReadLine:
    ; Check if we read anything
    cmp bytesRead, 0
    je readLineDone
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
readLineDone:
    ret
ReadLineFromFile ENDP

;--------------------------------------------------------------------------------
; insertTransaction PROC
; Adds a new transaction record to the transaction log file
; Receives: Pointer to userTransaction structure
; Returns: Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
insertTransaction PROC,
    transaction: PTR userTransaction
    
    pushad
    
    ; Open transaction file for append
    INVOKE CreateFile,
        ADDR transactionSourceFile,
        GENERIC_WRITE,
        0,
        NULL,
        OPEN_ALWAYS,      ; Open file if exists, create if not
        FILE_ATTRIBUTE_NORMAL,
        NULL
    
    ; Save handle
    mov fileWriteHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne fileOpenedSuccessfully
    
    ; File open error
    INVOKE printString, ADDR fileWriteErrorMsg
    call Crlf
    STC  ; Return failure
    jmp insertExit
    
fileOpenedSuccessfully:
    ; Move file pointer to end of file for appending
    INVOKE SetFilePointer,
        fileWriteHandle,
        0,
        NULL,
        FILE_END
    
    ; Format transaction record into output buffer
    mov edi, OFFSET outputBuffer
    mov BYTE PTR [edi], 0   ; Start with empty string
    
    ; Move the transaction pointer for formatting
    mov esi, transaction
    mov formatPtr, esi
    
    ; Format the transaction record
    call formatTransactionRecord
    
    ; Add newline
    mov eax, OFFSET eolMarker
    mov edx, OFFSET outputBuffer
    INVOKE Str_cat, eax, edx
    
    ; Write transaction to file
    INVOKE Str_length, ADDR outputBuffer
    mov ecx, eax                         
    INVOKE WriteFile,
        fileWriteHandle,
        ADDR outputBuffer,
        ecx,                             
        ADDR bytesWritten,
        NULL
    
    ; Check if write was successful
    cmp bytesWritten, 0
    je insertWriteError
    
    ; Close file
    INVOKE CloseHandle, fileWriteHandle
    
    ; Success
    CLC ; Return success
    jmp insertExit
    
insertWriteError:
    ; Handle write error
    INVOKE CloseHandle, fileWriteHandle
    STC ; Return failure
    
insertExit:
    popad
    ret
insertTransaction ENDP

;--------------------------------------------------------------------------------
; Wrapper functions to provide backward compatibility with existing code
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; updateUserFile PROC
; Updates user record in the credentials file (compatibility wrapper)
; Receives: Pointer to userCredential structure
; Returns: Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
updateUserFile PROC,
    user: PTR userCredential
    
    INVOKE updateFile, FILE_TYPE_CREDENTIALS, user, OFFSET userCredential.username
    ret
updateUserFile ENDP

;--------------------------------------------------------------------------------
; updateUserAccountFile PROC
; Updates user account record in the accounts file (compatibility wrapper)
; Receives: Pointer to userAccount structure
; Returns: Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
updateUserAccountFile PROC,
    account: PTR userAccount
    
    INVOKE updateFile, FILE_TYPE_ACCOUNTS, account, OFFSET userAccount.account_number
    ret
updateUserAccountFile ENDP

;--------------------------------------------------------------------------------
; updateTransactionFile PROC
; Updates transaction record in the transactions file (compatibility wrapper)
; Receives: Pointer to userTransaction structure
; Returns: Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
updateTransactionLog PROC,
    transaction: PTR userTransaction
    
    INVOKE updateFile, FILE_TYPE_TRANSACTIONS, transaction, OFFSET userTransaction.transaction_id
    ret
updateTransactionLog ENDP

;--------------------------------------------------------------------------------
; resetLoginAttempt PROC
; Resets the login attempt counter and timestamp for a specified user
; Receives: Pointer to user credential structure
; Returns : Carry flag is set if failed, clear if successful
;--------------------------------------------------------------------------------
resetLoginAttempt PROC,
    user: PTR userCredential
    
    pushad
    
    mov esi, user

    ; Reset loginAttempt to "0" and timestamp to "-"
    INVOKE Str_copy, ADDR zeroVal, ADDR (userCredential PTR [esi]).loginAttempt
    INVOKE Str_copy, ADDR dashVal, ADDR (userCredential PTR [esi]).firstLoginAttemptTimestamp
    
    ; Update user record
    INVOKE updateUserFile, user
    jnc resetDone     ; If carry flag is clear, success
    
resetFailed:
    STC ; Return failure
    
resetDone:
    popad
    ret
resetLoginAttempt ENDP

END