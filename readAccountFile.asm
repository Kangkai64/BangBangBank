
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module handles customer account operations including:
; - Reading account data from file
; - Switch account functionality
; - OTP generation
; Last update: 15/3/2025
;--------------------------------------------------------------------------------

.data
; File paths
accountFilePath       BYTE "Accounts\accounts.csv", 0
transactionFilePath   BYTE "Transactions\transactions.csv", 0
otpDirPath            BYTE "GeneratedOTP\", 0
otpFilePath           BYTE "GeneratedOTP\otp_", 0  ; Will append customer_id and .txt

; OTP variables
otpBuffer             BYTE 8 DUP(?)
otpPrefix             BYTE "OTP-", 0
otpMessage            BYTE "Your OTP has been generated: ", 0
createDirError BYTE "Error creating OTP file", NEWLINE, 0

; Switch account variables
switchAccountMenuHeader BYTE "Switch Account", NEWLINE, 
                             "=======================================", NEWLINE, 0
accountChoice         BYTE "Enter your choice : ", 0
pinPrompt             BYTE "Enter your PIN number : ", 0
invalidPinMsg         BYTE "Your PIN number is invalid. Please try again.", NEWLINE, 0
noAccountsMsg         BYTE "You don't have another account. Kindly register a new account at your nearest Bang Bang Bank Branch.", NEWLINE, NEWLINE, 0

; File handling variables
accountBuffer         BYTE 4096 DUP(?)
transactionBuffer     BYTE 4096 DUP(?)
fileHandle            DWORD ?
bytesRead             DWORD ?
bytesWritten          DWORD ?
accountTempBuffer     BYTE 255 DUP(?)

; For displaying account list
MAX_ACCOUNTS          EQU 10
accountList           customerAccount MAX_ACCOUNTS DUP(<>)
accountCount          DWORD 0

.code
;--------------------------------------------------------------------------------
; Reads customer account data from accounts.csv
; Receives: customer_id pointer, account array pointer, max accounts count
; Returns: EAX = number of accounts found
;--------------------------------------------------------------------------------
readAccountFile PROC,
    customerID: PTR BYTE,
    accountArray: PTR customerAccount,
    maxAccounts: DWORD
    
    pushad
    
    ; Open the account file
    mov edx, OFFSET accountFilePath
    call OpenInputFile
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne accountFileOpenSuccess
    
    ; File open error - return 0 accounts
    mov eax, 0
    mov [esp+28], eax ; Set EAX return value to 0
    jmp readAccountExit
    
accountFileOpenSuccess:
    ; Read file content into buffer
    mov eax, fileHandle
    mov edx, OFFSET accountBuffer
    mov ecx, SIZEOF accountBuffer - 1
    call ReadFromFile
    mov bytesRead, eax
    
    ; Add null terminator to buffer
    mov edi, OFFSET accountBuffer
    add edi, eax
    mov BYTE PTR [edi], 0
    
    ; Close the file
    mov eax, fileHandle
    call CloseFile
    
    ; Skip header line
    mov esi, OFFSET accountBuffer
    call SkipCSVLine
    
    ; Initialize account counter
    mov ecx, 0  ; Account counter
    
parseAccountLoop:
    ; Check if we've reached max accounts or end of buffer
    cmp ecx, maxAccounts
    jae endAccountParsing
    
    cmp BYTE PTR [esi], 0  ; End of buffer?
    je endAccountParsing
    
    ; Calculate pointer to current account in array
    mov edi, accountArray
    push eax
    mov eax, SIZEOF customerAccount
    mul ecx
    add edi, eax
    pop eax
    
    ; Get customer_id field (to compare)
    push esi
    call FindCustomerIDInLine
    
    ; Compare with requested customer_id
    mov edx, customerID
    call Str_compare
    pop esi
    
    cmp eax, 0
    jne skipThisAccount    ; Not matching customer ID
    
    ; Found matching account - parse all fields
    push ecx
    
    ; Reset to beginning of line
    mov edx, esi
    
    ; Parse account fields into structure
    ; 1. account_number
    lea edi, [edi + OFFSET customerAccount.account_number]
    call ParseCSVField
    
    ; 2. customer_id
    lea edi, [edi + OFFSET customerAccount.customer_id - OFFSET customerAccount.account_number]
    call ParseCSVField
    
    ; 3. full_name
    lea edi, [edi + OFFSET customerAccount.full_name - OFFSET customerAccount.customer_id]
    call ParseCSVField
    
    ; 4. phone_number
    lea edi, [edi + OFFSET customerAccount.phone_number - OFFSET customerAccount.full_name]
    call ParseCSVField
    
    ; 5. email
    lea edi, [edi + OFFSET customerAccount.email - OFFSET customerAccount.phone_number]
    call ParseCSVField
    
    ; 6. account_balance
    lea edi, [edi + OFFSET customerAccount.account_balance - OFFSET customerAccount.email]
    call ParseCSVField
    
    ; 7. opening_date
    lea edi, [edi + OFFSET customerAccount.opening_date - OFFSET customerAccount.account_balance]
    call ParseCSVField
    
    ; 8. transaction_limit
    lea edi, [edi + OFFSET customerAccount.transaction_limit - OFFSET customerAccount.opening_date]
    call ParseCSVField
    
    ; 9. branch_name
    lea edi, [edi + OFFSET customerAccount.branch_name - OFFSET customerAccount.transaction_limit]
    call ParseCSVField
    
    ; 10. branch_address
    lea edi, [edi + OFFSET customerAccount.branch_address - OFFSET customerAccount.branch_name]
    call ParseCSVField
    
    ; 11. account_type
    lea edi, [edi + OFFSET customerAccount.account_type - OFFSET customerAccount.branch_address]
    call ParseCSVField
    
    ; 12. currency
    lea edi, [edi + OFFSET customerAccount.currency - OFFSET customerAccount.account_type]
    call ParseCSVField
    
    ; 13. beneficiaries
    lea edi, [edi + OFFSET customerAccount.beneficiaries - OFFSET customerAccount.currency]
    call ParseCSVField
    
    ; Increment account counter
    pop ecx
    inc ecx
    jmp parseNextAccount
    
skipThisAccount:
    ; Skip to next line
    call SkipCSVLine
    
parseNextAccount:
    cmp BYTE PTR [esi], 0  ; Check if we've reached end of buffer
    jne parseAccountLoop
    
endAccountParsing:
    ; Return the number of accounts found
    mov [esp+28], ecx  ; Set EAX return value to account count
    
readAccountExit:
    popad
    ret
readAccountFile ENDP

;--------------------------------------------------------------------------------
; Reads customer transaction data from transactions.csv
; Receives: customer_id pointer, transaction array pointer, max transactions count
; Returns: EAX = number of transactions found
;--------------------------------------------------------------------------------
readTransactionFile PROC,
    customerID: PTR BYTE,
    transactionArray: PTR customerTransaction,
    maxTransactions: DWORD
    
    pushad
    
    ; Open the transaction file
    mov edx, OFFSET transactionFilePath
    call OpenInputFile
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne transFileOpenSuccess
    
    ; File open error - return 0 transactions
    mov eax, 0
    mov [esp+28], eax  ; Set EAX return value to 0
    jmp readTransactionExit
    
transFileOpenSuccess:
    ; Read file content into buffer
    mov eax, fileHandle
    mov edx, OFFSET transactionBuffer
    mov ecx, SIZEOF transactionBuffer - 1
    call ReadFromFile
    mov bytesRead, eax
    
    ; Add null terminator to buffer
    mov edi, OFFSET transactionBuffer
    add edi, eax
    mov BYTE PTR [edi], 0
    
    ; Close the file
    mov eax, fileHandle
    call CloseFile
    
    ; Skip header line
    mov esi, OFFSET transactionBuffer
    call SkipCSVLine
    
    ; Initialize transaction counter
    mov ecx, 0  ; Transaction counter
    
parseTransLoop:
    ; Check if we've reached max transactions or end of buffer
    cmp ecx, maxTransactions
    jae endTransParsing
    
    cmp BYTE PTR [esi], 0  ; End of buffer?
    je endTransParsing
    
    ; Calculate pointer to current transaction in array
    mov edi, transactionArray
    push eax
    mov eax, SIZEOF customerTransaction
    mul ecx
    add edi, eax
    pop eax
    
    ; Get customer_id field (to compare)
    push esi
    call FindCustomerIDInTransaction
    
    ; Compare with requested customer_id
    mov edx, customerID
    call Str_compare
    pop esi
    
    cmp eax, 0
    jne skipThisTrans    ; Not matching customer ID
    
    ; Found matching transaction - parse all fields
    push ecx
    
    ; Reset to beginning of line
    mov edx, esi
    
    ; Parse transaction fields into structure
    ; 1. transaction_id
    lea edi, [edi + OFFSET customerTransaction.transaction_id]
    call ParseCSVField
    
    ; 2. customer_id
    lea edi, [edi + OFFSET customerTransaction.customer_id - OFFSET customerTransaction.transaction_id]
    call ParseCSVField
    
    ; 3. transaction_type
    lea edi, [edi + OFFSET customerTransaction.transaction_type - OFFSET customerTransaction.customer_id]
    call ParseCSVField
    
    ; 4. amount
    lea edi, [edi + OFFSET customerTransaction.amount - OFFSET customerTransaction.transaction_type]
    call ParseCSVField
    
    ; 5. date
    lea edi, [edi + OFFSET customerTransaction.date - OFFSET customerTransaction.amount]
    call ParseCSVField
    
    ; 6. time
    lea edi, [edi + OFFSET customerTransaction.time - OFFSET customerTransaction.date]
    call ParseCSVField
    
    ; Increment transaction counter
    pop ecx
    inc ecx
    jmp parseNextTrans
    
skipThisTrans:
    ; Skip to next line
    call SkipCSVLine
    
parseNextTrans:
    cmp BYTE PTR [esi], 0  ; Check if we've reached end of buffer
    jne parseTransLoop
    
endTransParsing:
    ; Return the number of transactions found
    mov [esp+28], ecx  ; Set EAX return value to transaction count
    
readTransactionExit:
    popad
    ret
readTransactionFile ENDP

;--------------------------------------------------------------------------------
; Switch Account function - displays accounts and prompts for PIN
; Receives: user credential structure, customer_id
; Returns: EAX = selected account index (or -1 if canceled/invalid)
;--------------------------------------------------------------------------------
switchAccount PROC,
    user: PTR userCredential,
    customerID: PTR BYTE
    
    LOCAL pinInput[32]:BYTE
    LOCAL selectedOption:DWORD
    
    pushad
    
    ; Display the switch account menu header
    INVOKE printString, ADDR switchAccountMenuHeader
    
    ; Read customer accounts
    INVOKE readAccountFile, customerID, ADDR accountList, MAX_ACCOUNTS
    mov accountCount, eax
    
    ; Check if any accounts were found
    cmp eax, 0
    je noAccountsFound
    
    ; Display list of accounts
    xor ecx, ecx  ; Account counter
    
displayAccountLoop:
    cmp ecx, accountCount
    jae endAccountDisplay
    
    ; Calculate pointer to current account
    mov esi, OFFSET accountList
    push eax
    mov eax, SIZEOF customerAccount
    mul ecx
    add esi, eax
    pop eax
    
    ; Display account option
    mov eax, ecx
    inc eax  ; Start numbering from 1
    call WriteDec
    mov al, '.'
    call WriteChar
    mov al, ' '
    call WriteChar
    
    ; Display account type
    lea edx, [esi + OFFSET customerAccount.account_type]
    call WriteString
    mov al, ' '
    call WriteChar
    mov al, '('
    call WriteChar
    
    ; Display account number
    lea edx, [esi + OFFSET customerAccount.account_number]
    call WriteString
    mov al, ')'
    call WriteChar
    call Crlf
    
    inc ecx
    jmp displayAccountLoop
    
endAccountDisplay:
    ; Prompt for choice
    INVOKE printString, ADDR accountChoice

    call ReadDec  ; Read decimal into EAX
    mov selectedOption, eax
    
    ; Validate option
    cmp eax, 0
    jle invalidOption
    cmp eax, accountCount
    jg invalidOption
    
    ; Prompt for PIN
    INVOKE printString, ADDR pinPrompt
    
    ; Read PIN with masking
    INVOKE promptForPassword, ADDR pinInput
    
    ; Validate PIN
    mov esi, user
    add esi, OFFSET userCredential.hashed_pin
    add esi, OFFSET userCredential.encryption_key
    INVOKE validatePassword, ADDR pinInput, esi, esi
    
    ; Check validation result
    cmp eax, 0
    je invalidPin
    
    ; PIN is valid, return selected account index
    mov eax, selectedOption
    dec eax  ; Convert to 0-based index
    mov [esp+28], eax  ; Set return value in EAX
    jmp switchAccountExit
    
invalidPin:
    ; Display invalid PIN message
    INVOKE printString, ADDR invalidPinMsg
    call Wait_Msg
    
    ; Return -1 to indicate failure
    mov eax, -1
    mov [esp+28], eax
    jmp switchAccountExit
    
invalidOption:
    ; Return -1 to indicate invalid selection
    mov eax, -1
    mov [esp+28], eax
    jmp switchAccountExit
    
noAccountsFound:
    ; Display no accounts message
    INVOKE printString, ADDR noAccountsMsg
    
    ; Return -1 to indicate no accounts
    mov eax, -1
    mov [esp+28], eax
    
switchAccountExit:
    popad
    ret
switchAccount ENDP

;--------------------------------------------------------------------------------
; Generate OTP and save it to file
; Receives: customer_id pointer
; Returns: EAX = pointer to OTP string
;--------------------------------------------------------------------------------
generateOTP PROC,
    customerID: PTR BYTE
    
    pushad
    
    ; Generate random 6-digit OTP
    call Randomize  ; Initialize random number generator
    
    ; Format OTP prefix
    mov edi, OFFSET otpBuffer
    mov esi, OFFSET otpPrefix
    call Str_copy
    
    ; Get length of prefix
    mov edx, OFFSET otpBuffer
    call Str_length
    mov edi, OFFSET otpBuffer
    add edi, eax  ; Move to end of prefix
    
    ; Generate 6 random digits
    mov ecx, 6  ; 6 digits
    
generateDigits:
    mov eax, 10
    call RandomRange  ; Generate random 0-9
    add eax, '0'      ; Convert to ASCII
    mov [edi], al     ; Store in buffer
    inc edi
    LOOP generateDigits
    
    ; Add null terminator
    mov BYTE PTR [edi], 0
    
    ; Create OTP filename (otpDir\otp_customerID.txt)
    mov edi, OFFSET otpFilePath
    call Str_length
    mov edi, OFFSET otpFilePath
    add edi, eax  ; Move to end of path
    
    ; Append customer_id
    mov esi, customerID
    call Str_copy
    
    ; Append .txt
    mov edx, OFFSET otpFilePath
    call Str_length
    mov edi, OFFSET otpFilePath
    add edi, eax
    
    mov BYTE PTR [edi], '.'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 'x'
    inc edi
    mov BYTE PTR [edi], 't'
    inc edi
    mov BYTE PTR [edi], 0
    
    ; Write OTP to file
    mov edx, OFFSET otpFilePath
    call CreateOutputFile
    mov fileHandle, eax
    
    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne otpFileOpen
    
    ; File open error
    INVOKE printString, ADDR createDirError
    call Crlf
    jmp generateOTPExit
    
otpFileOpen:
    ; Write OTP to file
    mov eax, fileHandle
    mov edx, OFFSET otpBuffer
    call Str_length
    mov ecx, eax
    call WriteToFile
    
    ; Close the file
    mov eax, fileHandle
    call CloseFile
    
    ; Display confirmation message
    INVOKE printString, ADDR otpMessage
    INVOKE printString, ADDR otpBuffer
    call Crlf
    
generateOTPExit:
    ; Return pointer to OTP buffer
    mov eax, OFFSET otpBuffer
    mov [esp+28], eax  ; Set return value in EAX
    
    popad
    ret
generateOTP ENDP

;--------------------------------------------------------------------------------
; Helper procedures for CSV parsing
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Skip to the next line in a CSV file
; Receives: ESI = pointer to current position in buffer
; Returns: ESI = updated to beginning of next line
;--------------------------------------------------------------------------------
SkipCSVLine PROC
    push eax
    
skipLineLoop:
    mov al, [esi]
    cmp al, 0         ; End of buffer?
    je endSkipLine
    cmp al, 10        ; LF?
    je foundLF
    cmp al, 13        ; CR?
    je foundCR
    
    ; Move to next character
    inc esi
    jmp skipLineLoop
    
foundCR:
    inc esi           ; Skip CR
    cmp BYTE PTR [esi], 10  ; Check for LF
    jne endSkipLine
    inc esi           ; Skip LF
    jmp endSkipLine
    
foundLF:
    inc esi           ; Skip LF
    
endSkipLine:
    pop eax
    ret
SkipCSVLine ENDP

;--------------------------------------------------------------------------------
; Find customer_id field in a CSV line
; Receives: ESI = pointer to start of line
; Returns: ESI = pointing to customer_id value
;--------------------------------------------------------------------------------
FindCustomerIDInLine PROC
    push eax
    push ebx
    push ecx
    
    ; For account file, customer_id is the 2nd field
    ; Skip first field
    mov ecx, 1  ; Skip 1 field
    
skipFields:
    cmp ecx, 0
    je foundField
    
    ; Skip to next comma
    findComma:
        mov al, [esi]
        cmp al, 0     ; End of buffer?
        je endFindField
        cmp al, ','   ; Comma?
        je foundComma
        inc esi
        jmp findComma
        
    foundComma:
        inc esi       ; Skip comma
        dec ecx
        jmp skipFields
        
foundField:
    ; ESI now points to customer_id
    
endFindField:
    pop ecx
    pop ebx
    pop eax
    ret
FindCustomerIDInLine ENDP

;--------------------------------------------------------------------------------
; Find customer_id field in a transaction line
; Receives: ESI = pointer to start of line
; Returns: ESI = pointing to customer_id value
;--------------------------------------------------------------------------------
FindCustomerIDInTransaction PROC
    push eax
    push ebx
    push ecx
    
    ; For transaction file, customer_id is the 2nd field
    ; Skip first field
    mov ecx, 1  ; Skip 1 field
    
skipTransFields:
    cmp ecx, 0
    je foundTransField
    
    ; Skip to next comma
    findTransComma:
        mov al, [esi]
        cmp al, 0     ; End of buffer?
        je endFindTransField
        cmp al, ','   ; Comma?
        je foundTransComma
        inc esi
        jmp findTransComma
        
    foundTransComma:
        inc esi       ; Skip comma
        dec ecx
        jmp skipTransFields
        
foundTransField:
    ; ESI now points to customer_id
    
endFindTransField:
    pop ecx
    pop ebx
    pop eax
    ret
FindCustomerIDInTransaction ENDP
END