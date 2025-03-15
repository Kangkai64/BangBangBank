
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; Generate OTP and save it to file
; Receives: customer_id pointer
; Returns: EAX = pointer to OTP string
;--------------------------------------------------------------------------------

.data
otpDirPath            BYTE "GeneratedOTP\", 0
otpFilePath           BYTE "GeneratedOTP\otp_", 0  ; Will append customer_id and .txt

; OTP variables
otpBuffer             BYTE 8 DUP(?)
otpPrefix             BYTE "OTP-", 0
otpMessage            BYTE "Your OTP has been generated: ", 0

createDirError BYTE "Error creating OTP file", 0

.code
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