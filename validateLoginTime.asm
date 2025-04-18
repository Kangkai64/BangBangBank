
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module validates login time restrictions
; Receives: loginAttempt count and firstLoginAttemptTimestamp
; Returns: EAX = 1 if locked out, 0 if not locked out
; Last update: 17/3/2025
;--------------------------------------------------------------------------------

.data
currentTime          SYSTEMTIME <>
attemptHour         DWORD ?
currentHour         DWORD ?
attemptMinute       DWORD ?
currentMinute       DWORD ?
hourDiff            DWORD ?

.code
validateLoginTime PROC,
    user: PTR userCredential
    
    pushad
    
    mov edi, user
    ; Check if loginAttempt > 3
    lea esi, (userCredential PTR [edi]).loginAttempt
    xor eax, eax
    mov al, [esi]
    sub al, '0'  ; Convert ASCII to number
    cmp al, 3
    jl notLockedOut  ; If attempts < 3, not locked out
    
    ; Check if timestamp is "-" (no previous attempts)
    lea esi, (userCredential PTR [edi]).firstLoginAttemptTimestamp
    mov al, [esi]
    cmp al, '-'
    je notLockedOut   ; If no timestamp, not locked out
    
    ; Get current time
    invoke GetLocalTime, ADDR currentTime
    
    ; Get current hour
    movzx eax, currentTime.wHour
    mov currentHour, eax

    ; Get current minute
    movzx eax, currentTime.wMinute
    mov currentMinute, eax
    
    ; Get hour from timestamp (DD/MM/YYYY HH:MM:SS format)
    lea esi, (userCredential PTR [edi]).firstLoginAttemptTimestamp
    
    ; Parse timestamp - skip over DD/MM/YYYY and space to get to HH
    add esi, 11
    
    ; Now ESI points to the HH part
    xor eax, eax
    mov al, [esi]     ; Get first digit
    sub al, '0'       ; Convert from ASCII
    mov ebx, 10
    mul ebx           ; Multiply by 10
    mov bl, [esi+1]   ; Get second digit
    sub bl, '0'       ; Convert from ASCII
    add eax, ebx      ; Add to get full hour value
    mov attemptHour, eax

    ; Get MM part
    xor eax, eax
    mov al, [esi+3]   ; Get first digit
    sub al, '0'       ; Convert from ASCII
    mov ebx, 10
    mul ebx           ; Multiply by 10
    mov bl, [esi+4]   ; Get second digit
    sub bl, '0'       ; Convert from ASCII
    add eax, ebx      ; Add to get full hour value
    mov attemptMinute, eax
    
    ; Calculate hours difference
    mov eax, currentHour
    sub eax, attemptHour
    
    ; Handle day boundary crossing (if current hour < attempt hour)
    cmp eax, 0
    jge hourDiffPositive
    add eax, 24  ; Add 24 hours if current < attempt
hourDiffPositive:
    mov hourDiff, eax

    ; Calculate minute difference
    mov eax, currentMinute
    sub eax, attemptMinute

    cmp eax, 0
    jge checkLockout
    add eax, 24  ; Add 24 hours if current < attempt
    
checkLockout:
    mov hourDiff, eax

    ; Check if within 24 hour lockout period
    cmp hourDiff, 24
    .IF hourDiff >= 24
        INVOKE resetLoginAttempt, user
    .ENDIF
    jge notLockedOut  ; If 24+ hours passed, not locked out
    
    ; User is locked out
    mov eax, 1
    mov [esp+28], eax  ; Return 1 in EAX (locked out)
    jmp validateTimeExit
    
notLockedOut:
    mov eax, 0
    mov [esp+28], eax  ; Return 0 in EAX (not locked out)
    
validateTimeExit:
    popad
    ret
validateLoginTime ENDP
END