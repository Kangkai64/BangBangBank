
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will print the login design onto the console
; and calls the functions for login.
; Receives : Nothing
; Returns : Carry flag is set if login failed, clear if login successful
; Last update: 15/3/2025
;------------------------------------------------------------------------
.data
loginDesign BYTE "Bang Bang Bank Login", NEWLINE,
            "==============================", NEWLINE,
            "User Login", NEWLINE,
            "==============================", NEWLINE, 0

loginAttemptLimitReachedMsg BYTE "You have reached your login attempt limit. Please try again at ", 0
unlockTimeMsg BYTE " hours.", NEWLINE, 0
loginSuccessMsg BYTE "Login successful! Welcome to Bang Bang Bank.", NEWLINE, 0
loginFailMsg BYTE "Login failed. Incorrect username or password.", NEWLINE, 0
loginAttemptsLeftMsg BYTE "You have ", 0
attemptsRemaining BYTE "  attempts remaining.", NEWLINE, 0

inputUsername BYTE 255 DUP(?)
inputPassword BYTE 255 DUP(?)
currentTime SYSTEMTIME <>
user userCredential <>
tempTime BYTE 32 DUP(?)
unlockHour BYTE 16 DUP(?)
timeFormat BYTE "HH:MM", 0
unlockTimeBuffer BYTE 32 DUP(?)

.code
login PROC
    
    ; Display login design
    INVOKE printString, OFFSET loginDesign
    
    ; Read username and password
    INVOKE promptForUsername, OFFSET inputUsername
    INVOKE promptForPassword, OFFSET inputPassword
    
    ; Copy input username to user structure
    INVOKE Str_copy, ADDR inputUsername, ADDR user.username
    
    ; Read user credentials from username.txt
    INVOKE inputFromFile, ADDR user

    .IF CARRY? ; If open file error, return to main menu
        jmp loginExit
    .ENDIF

    ; Get local time
    INVOKE GetLocalTime, ADDR currentTime
    
    ; Check if account is locked

    INVOKE validateLoginTime, ADDR user.loginAttempt, ADDR user.firstLoginAttemptTimestamp
    cmp eax, 1
    jne notLocked
    
    ; Account is locked - display message
    INVOKE printString, OFFSET loginAttemptLimitReachedMsg
    
    ; Parse timestamp to get original hour and add 5 hours for unlock time
    lea esi, user.firstLoginAttemptTimestamp
    
    ; Skip to hour part (format: DD/MM/YYYY HH:MM:SS)
    ; Skip 11 characters to reach hour
    add esi, 11
    
    ; Extract hour as text
    mov al, [esi]
    mov BYTE PTR [OFFSET unlockHour], al
    inc esi
    mov al, [esi]
    mov BYTE PTR [OFFSET unlockHour+1], al
    mov BYTE PTR [OFFSET unlockHour+2], 0
    
    ; Convert to number
    lea esi, unlockHour
    call StringToInt
    
    ; Add 5 hours for unlock time
    add eax, 5
    
    ; Handle day boundary crossing
    cmp eax, 24
    jl sameDay
    sub eax, 24  ; Wrap around to next day
    
sameDay:
    ; Convert back to string for display
    call WriteDec
    
    ; Display unlock time message
    INVOKE printString, ADDR unlockTimeMsg
    
    ; Login failed due to lockout
    mov eax, 0
    STC ; displayMainMenu
    jmp loginExit
    
notLocked:
    ; Validate password
    INVOKE validatePassword, ADDR inputPassword, ADDR user.hashed_password, ADDR user.encryption_key
    jnc loginSuccess
    
    ; Login failed - increment attempt counter
    mov esi, OFFSET user.loginAttempt
    mov al, [esi]
    
    ; Check if this is the first failed attempt (if first time, store timestamp)
    cmp al, '0'
    jne notFirstAttempt
    
    ; Store current time as first login attempt timestamp
    INVOKE formatSystemTime, ADDR currentTime, ADDR user.firstLoginAttemptTimestamp
    
notFirstAttempt:
    ; Increment login attempt counter if not at max (3)
    cmp al, '3'
    je counterAtMax
    
    inc al
    mov [esi], al
    
counterAtMax:
    ; Update user file with new attempt count and timestamp
    ; INVOKE updateUserFile, ADDR user
    
    ; Calculate remaining attempts
    mov al, '3'  ; Max attempts allowed
    sub al, [esi]
    add al, '0'  ; Convert back to character
    
    ; Check if any attempts remain
    cmp al, '0'
    jle noAttemptsLeft
    
    ; Display login failed message with attempts remaining
    INVOKE printString, ADDR loginFailMsg
    INVOKE printString, ADDR loginAttemptsLeftMsg
    
    ; Display number of attempts remaining
    mov BYTE PTR [OFFSET attemptsRemaining], al
    INVOKE printString, ADDR attemptsRemaining
    
    STC  ; Return login failed
    jmp loginExit
    
noAttemptsLeft:
    ; Display login failed message without attempts remaining
    INVOKE printString, ADDR loginFailMsg
    
    STC  ; Return login failed
    jmp loginExit
    
loginSuccess:
    ; Reset login attempts and timestamp on successful login
    mov BYTE PTR [OFFSET user.loginAttempt], '0'
    mov esi, OFFSET user.firstLoginAttemptTimestamp
    mov BYTE PTR [esi], '-'
    mov BYTE PTR [esi+1], 0
    
    ; Update user file with reset attempt count
    ; INVOKE updateUserFile, ADDR user
    
    ; Display success message
    INVOKE printString, ADDR loginSuccessMsg

    CLC  ; Return login succeeded
    
loginExit:
    ret
login ENDP
END