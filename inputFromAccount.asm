
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This procedure reads user account data from a single file by customer ID
; Receives: Pointer to userAccount structure (account) with customer_id filled
; Returns: EAX = 0 if the user account is not found
; Last update: 23/3/2025
;--------------------------------------------------------------------------------
.data
accountFileName     BYTE "Users\userAccount.txt", 0

; Handles and buffers
fileHandle         DWORD ?
readBuffer         BYTE 20480 DUP(?)  ; Larger buffer for multi-user file
errorMsg           BYTE "Error: File cannot be opened or read", NEWLINE, 0
pathErrorMsg       BYTE "Error: Invalid file path", NEWLINE, 0
userNotFoundMsg    BYTE NEWLINE, "User not found.", NEWLINE, 0
bytesRead          DWORD ?
tempBuffer         BYTE 512 DUP(?)
fieldBuffer        BYTE 512 DUP(?)
fieldIndex         DWORD 0
currentLineStart   DWORD 0
foundAccount       BYTE 0
userCustomerID BYTE 32 DUP(?)

.code
inputFromAccount PROC,
    account: PTR userAccount
    
    pushad

    ; Copy out the customer_id and store it into esi
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
    
    ; If match found, process this record
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
END