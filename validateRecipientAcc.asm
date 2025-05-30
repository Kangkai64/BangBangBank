
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This procedure reads user account data from a single file by account number
; Receives: Pointer to userAccount structure (account) with customer_id filled
; Returns: EAX = 0 if the user account is not found
; Last update: 25/3/2025
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
recipientAccNo    BYTE 32 DUP(?)
recipientName       BYTE 64 DUP(?)

.code
validateRecipientAcc PROC,
    account: PTR userAccount
    
    pushad

    ; Copy out the account_number and store it into esi
    mov esi, [account]
    add esi, OFFSET userAccount.account_number
    INVOKE Str_copy, esi, ADDR recipientAccNo

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

    ; Compare with input account_number
    INVOKE Str_compare, ADDR tempBuffer, ADDR recipientAccNo
    
    ; If match found, parse data
    .IF ZERO?
         ; Found the account! Set flag
            mov foundAccount, 1
        
            ; Return to the start of this line
            mov esi, currentLineStart
        
            ; Parse all fields for this account
            INVOKE parseUserAccount, account

            ; esi still points to your account struct
            mov esi, [account]
            add esi, OFFSET userAccount.full_name
            INVOKE Str_copy, esi, ADDR recipientName
        
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
validateRecipientAcc ENDP
END