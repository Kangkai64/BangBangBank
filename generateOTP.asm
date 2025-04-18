INCLUDE BangBangBank.inc
;--------------------------------------------------------------------------------
; Generate OTP and save it to file
; Receives: account pointer to userAccount structure
; Returns: EAX = pointer to OTP string
;--------------------------------------------------------------------------------
.data
fileHandle            DWORD ?
otpDirPath            BYTE "GeneratedOTP\", 0
otpFilePrefix         BYTE "GeneratedOTP\otp_", 0
otpFileSuffix         BYTE ".txt", 0
otpFilePath           BYTE 256 DUP(0)  ; Increased buffer size for safety

; OTP variables
otpBuffer             BYTE 16 DUP(0)   ; Initialize with zeros for safety
otpPrefix             BYTE "OTP-", 0
otpMessage1           BYTE "Your OTP is generated in the Bang Bang Bank\", 0
otpMessage2           BYTE ".", NEWLINE, "Please do not share it with others. Expiring in 60 seconds.", 0
createDirError        BYTE "Error creating OTP directory", 0
createFileError       BYTE "Error creating OTP file", 0
bytesWritten          DWORD ?
tempBuffer            BYTE 16 DUP(0)   ; Initialize with zeros

.code
generateOTP PROC,
    account: PTR userAccount

    ; Save registers we'll modify
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Generate random 6-digit OTP
    call Randomize  ; Initialize random number generator

    ; Clear OTP buffer first to ensure clean state
    push ecx
    push edi
    mov ecx, 16     ; Buffer size
    mov al, 0
    lea edi, otpBuffer
    rep stosb       ; Fill with zeros
    pop edi
    pop ecx

    ; Format OTP prefix - using a safer approach
    push edi             ; Save EDI before modifying
    push esi             ; Save ESI before modifying
    lea edi, otpBuffer   ; Load effective address instead of OFFSET
    lea esi, otpPrefix   ; Load effective address instead of OFFSET

copyPrefix:
    mov al, [esi]        ; Get byte from source
    mov [edi], al        ; Store in destination
    inc esi              ; Move to next source byte
    inc edi              ; Move to next destination byte
    cmp al, 0            ; Check if we reached end of string
    jne copyPrefix       ; If not, continue copying
    dec edi              ; Back up to overwrite null terminator

    ; Generate 6 random digits
    mov ecx, 6           ; 6 digits

generateDigits:
    push ecx             ; Save loop counter
    mov eax, 10
    call RandomRange     ; Generate random 0-9
    add al, '0'          ; Convert to ASCII
    mov [edi], al        ; Store in buffer
    inc edi
    pop ecx              ; Restore loop counter
    loop generateDigits

    ; Add null terminator
    mov BYTE PTR [edi], 0

    pop esi              ; Restore original ESI
    pop edi              ; Restore original EDI

    ; First ensure directory exists
    INVOKE CreateDirectory, ADDR otpDirPath, NULL

    ; Clear otpFilePath buffer
    push ecx
    push edi
    mov ecx, 256
    mov al, 0
    lea edi, otpFilePath
    rep stosb
    pop edi
    pop ecx

    ; Build file path manually (concatenate parts)
    push edi
    push esi

    ; Build OTP file path
    lea esi, otpFilePrefix
    lea edi, otpFilePath
    INVOKE Str_copy, esi, edi

    INVOKE Str_length, edi
    add edi, eax

    mov esi, account
    add esi, OFFSET userAccount.customer_id
    INVOKE Str_copy, esi, edi

    INVOKE Str_length, edi
    add edi, eax

    lea esi, otpFileSuffix
    INVOKE Str_copy, esi, edi

    pop esi
    pop edi

    ; Write OTP to file
    INVOKE CreateFile, 
           ADDR otpFilePath,              ; lpFileName
           GENERIC_WRITE,                 ; dwDesiredAccess
           0,                             ; dwShareMode (no sharing)
           NULL,                          ; lpSecurityAttributes
           CREATE_ALWAYS,                 ; dwCreationDisposition
           FILE_ATTRIBUTE_NORMAL,         ; dwFlagsAndAttributes
           NULL                           ; hTemplateFile

    mov fileHandle, eax

    ; Check if file opened successfully
    cmp eax, INVALID_HANDLE_VALUE
    jne otpFileOpen

    ; File open error
    INVOKE GetLastError
    push eax
    INVOKE printString, ADDR createFileError
    pop eax
    call WriteDec
    call Crlf
    jmp generateOTPExit

otpFileOpen:
    ; Get length of OTP using a fixed value for now
    mov ecx, 10        ; "OTP-" (4) + 6 digits = 10 bytes

    ; Write to file
    INVOKE WriteFile,
           fileHandle,
           ADDR otpBuffer,
           ecx,
           ADDR bytesWritten,
           NULL

    ; Close file
    INVOKE CloseHandle, fileHandle

    ; Print success message
    INVOKE printString, ADDR otpMessage1
    INVOKE printString, ADDR otpFilePath
    INVOKE printString, ADDR otpMessage2
    call Crlf
    call Crlf

generateOTPExit:
    ; Set return value
    lea eax, otpBuffer

    ; Restore registers
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx

    ; Keep EAX for return value
    add esp, 4  ; Skip the EAX we pushed at the beginning

    ret
generateOTP ENDP
END