
INCLUDE BangBangBank.inc

;--------------------------------------------------------------------------------
; This module validates login time restrictions
; Receives: loginAttempt count and firstLoginAttemptTimestamp
; Returns: EAX = 1 if locked out, 0 if not locked out
; Last update: 15/3/2025
;--------------------------------------------------------------------------------
.data
currentTime          SYSTEMTIME <>
attemptTimeBuffer   BYTE 64 DUP(?)
attemptDay          DWORD ?
attemptMonth        DWORD ?  
attemptYear         DWORD ?
attemptHour         DWORD ?
attemptMinute       DWORD ?
attemptSecond       DWORD ?
currentHour         DWORD ?
hourDiff            DWORD ?

; Constants for time parsing
slash              BYTE "/", 0
space              BYTE " ", 0
colon              BYTE ":", 0

.code
validateLoginTime PROC,
    loginAttempt: PTR BYTE,
    firstLoginTimestamp: PTR BYTE
    
    pushad
    
    ; Check if loginAttempt > 3
    mov esi, loginAttempt
    xor eax, eax
    mov al, [esi]
    sub al, '0'  ; Convert ASCII to number
    cmp al, 3
    jle notLockedOut  ; If attempts <= 3, not locked out
    
    ; Check if timestamp is "-" (no previous attempts)
    mov esi, firstLoginTimestamp
    mov al, [esi]
    cmp al, '-'
    je notLockedOut   ; If no timestamp, not locked out
    
    ; Get current time
    invoke GetLocalTime, ADDR currentTime
    movzx eax, currentTime.wHour
    mov currentHour, eax
    
    ; Parse the timestamp (format: DD/MM/YYYY HH:MM:SS)
    mov esi, firstLoginTimestamp
    
    ; Extract day
    call StringToInt
    mov attemptDay, eax
    
    ; Skip slash
    add esi, 1
    
    ; Extract month
    call StringToInt
    mov attemptMonth, eax
    
    ; Skip slash
    add esi, 1
    
    ; Extract year
    call StringToInt
    mov attemptYear, eax
    
    ; Skip space
    add esi, 1
    
    ; Extract hour
    call StringToInt
    mov attemptHour, eax
    
    ; Calculate hours difference
    mov eax, currentHour
    sub eax, attemptHour
    
    ; Handle day boundary crossing
    cmp eax, 0
    jge hourDiffPositive
    add eax, 24  ; Add 24 hours if current < attempt
    
hourDiffPositive:
    mov hourDiff, eax
    
    ; Check if within 5 hour lockout period
    cmp hourDiff, 5
    jge notLockedOut  ; If 5+ hours passed, not locked out
    
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