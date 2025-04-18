INCLUDE BangBangBank.Inc

.data
; OTP related messages
otpPromptMsg BYTE "Enter OTP: ", 0
otpInvalidMsg BYTE "Invalid OTP! You have ", 0
noAttemptsLeftMsg BYTE "Invalid OTP! No attempts left...", 0
otpAttemptsLeftMsg BYTE " attempts left.", NEWLINE, 0
otpExpiredMsg BYTE "OTP has expired! Transaction cancelled.", NEWLINE, 0
otpInputBuffer BYTE 32 DUP(?)
otpAttemptCount DWORD 3          ; User gets 3 attempts
otpGeneratedTime DWORD ?         ; Store the time when OTP was generated
otpTickCount DWORD ?             ; Current tick count for OTP timeout check
otpTempBuffer BYTE 32 DUP(?)     ; Buffer to store a copy of the generated OTP

.code
; Procedure to verify OTP with timeout and retry limit
verifyOTP PROC USES ebx ecx edx esi edi,
    generatedOTP: PTR BYTE       ; Points to the OTP that was generated
    
    ; Copy the generated OTP to our buffer to ensure it's not modified
    INVOKE Str_copy, generatedOTP, ADDR otpTempBuffer
    
    ; Get the current system tick count when OTP was generated
    INVOKE GetTickCount
    mov otpGeneratedTime, eax
    
    ; Initialize attempt counter
    mov otpAttemptCount, 3
    
    otpVerificationLoop:
        
        ; Prompt user for OTP
        INVOKE printString, ADDR otpPromptMsg
        
        ; Use ReadString to get user input
        lea edx, otpInputBuffer
        mov ecx, SIZEOF otpInputBuffer - 1  ; Leave room for null terminator
        INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT
        call ReadString
        INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

        ; Check if OTP has expired (60 seconds = 60,000 milliseconds)
        INVOKE GetTickCount
        mov otpTickCount, eax
        
        ; Calculate elapsed time
        mov eax, otpTickCount
        sub eax, otpGeneratedTime
        
        ; Check if more than 60 seconds (60,000 ms) have passed
        cmp eax, 60000
        jae otpExpired
        
        ; Try direct comparison with the OTP
        lea esi, otpTempBuffer      ; Point to expected OTP
        lea edi, otpInputBuffer     ; Point to user input
        mov ecx, 32                 ; Maximum length to compare
        cld                         ; Direction = forward
        repe cmpsb                  ; Compare strings byte by byte
        jz otpSuccess               ; Strings are equal (ZF=1 if equal)
        
        ; String comparison didn't match, check for case differences
        INVOKE Str_ucase, ADDR otpInputBuffer   ; Convert input to uppercase
        INVOKE Str_ucase, ADDR otpTempBuffer    ; Convert expected OTP to uppercase
        
        INVOKE Str_compare, ADDR otpInputBuffer, ADDR otpTempBuffer
        je otpSuccess                ; Case-insensitive match
        
        ; Now try comparing just the numeric part (if OTP includes a prefix)
        ; Check if tempOTP contains a hyphen
        lea esi, otpTempBuffer
        mov al, '-'
    findHyphen:
        cmp BYTE PTR [esi], 0        ; Check for end of string
        je checkNumericOnly          ; No hyphen found, try numeric only
        cmp BYTE PTR [esi], al       ; Check for hyphen
        je foundHyphen               ; Hyphen found
        inc esi                      ; Move to next character
        jmp findHyphen
        
    foundHyphen:
        inc esi                      ; Skip past the hyphen
        INVOKE Str_compare, ADDR otpInputBuffer, esi
        je otpSuccess                ; Numeric part matches
        
    checkNumericOnly:
        ; OTP doesn't match in any format, decrement attempt counter
        dec otpAttemptCount
        jz otpFailure                ; No more attempts
        
        ; Show attempts remaining message
        INVOKE printString, ADDR otpInvalidMsg
        
        ; Convert attempts remaining to string and display
        mov eax, otpAttemptCount
        call WriteDec
        
        INVOKE printString, ADDR otpAttemptsLeftMsg
        jmp otpVerificationLoop
    
    otpExpired:
        ; OTP has expired
        INVOKE printString, ADDR otpExpiredMsg
        mov eax, 2                   ; Return 2 for resend otp
        jmp otpVerificationDone
        
    otpFailure:
        ; User exhausted all attempts
        INVOKE printString, ADDR noAttemptsLeftMsg
        mov eax, 0                   ; Return false (0) for failure
        jmp otpVerificationDone
        
    otpSuccess:
        ; OTP verified successfully
        mov eax, 1                   ; Return true (1) for success
        
    otpVerificationDone:
        ret
verifyOTP ENDP
END