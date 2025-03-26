
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will print the login design onto the console
; and calls the functions for login.
; Receives : Nothing
; Returns : Carry flag is set if login failed, clear if login successful
; Last update: 17/3/2025
;------------------------------------------------------------------------
.data
loginDesign BYTE "Bang Bang Bank Login", NEWLINE,
            "==============================", NEWLINE,
            "User Login", NEWLINE,
            "==============================", NEWLINE, 0
promptPasswordMsg BYTE "Please enter your password: ", 0
loginAttemptLimitReachedMsg BYTE NEWLINE, "You have reached your login attempt limit. Please try again at ", 0
loginSuccessMsg BYTE "Login successful! Welcome to Bang Bang Bank.", NEWLINE, 0
loginFailMsg BYTE NEWLINE, "Login failed. Incorrect username or password.", NEWLINE, 0
loginAttemptsLeftMsg BYTE "You have ", 0
attemptsRemaining BYTE "  attempts remaining.", NEWLINE, 0

inputUsername BYTE 255 DUP(?)
inputPassword BYTE 255 DUP(?)
currentTime SYSTEMTIME <>
user userCredential <>

.code
login PROC
    
    ; Display login design
    INVOKE printString, OFFSET loginDesign
    
    ; Read username and password
    INVOKE promptForUsername, OFFSET inputUsername
    INVOKE promptForPassword, OFFSET inputPassword, ADDR promptPasswordMsg
    
    ; Copy input username to user structure
    INVOKE Str_copy, ADDR inputUsername, ADDR user.username
    
    ; Read user credentials from username.txt
    INVOKE inputFromFile, ADDR user

    .IF eax == 0
        INVOKE printString, ADDR loginFailMsg
        STC ; Return login failure
        jmp loginExit
    .ENDIF

    ; Get local time
    INVOKE GetLocalTime, ADDR currentTime
    
    ; Check if account is locked
    INVOKE validateLoginTime, ADDR user
    cmp eax, 1
    jne notLocked
    
    ; Account is locked - display message
    INVOKE printString, OFFSET loginAttemptLimitReachedMsg

    ; Parse timestamp to get original hour and add 5 hours for unlock time
    lea esi, user.firstLoginAttemptTimestamp

    ; Skip to hour part (format is DD/MM/YYYY HH:MM:SS)
    ; Start at position 11 which is the first digit of the hour
    add esi, 11

    ; Extract hour as text and convert to integer
    mov al, [esi]      ; First digit of hour
    sub al, '0'        ; Convert from ASCII
    mov bl, 10         
    mul bl             ; Multiply by 10
    mov bl, [esi+1]    ; Second digit of hour
    sub bl, '0'        ; Convert from ASCII
    add al, bl         ; Full hour value in AL

    ; Add 5 hours for unlock time
    add al, 5

    ; Handle day boundary crossing
    cmp al, 24
    jl noWrapDay
    sub al, 24  ; Wrap around to next day

    noWrapDay:
    ; Convert back to string format (2 digits)
    mov bl, 10
    div bl              ; AL = tens digit, AH = ones digit
    add al, '0'         ; Convert back to ASCII
    add ah, '0'         ; Convert back to ASCII

    ; Move back the updated time into ESI
    mov [esi], al
    mov [esi+1], ah 

    sub esi, 11 ; Point to the start of timestamp

    ; Display the unlock time
    INVOKE printString, esi
    
    ; Login failed due to lockout
    call Wait_Msg
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
    INVOKE updateUserFile, ADDR user
    
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
    
    call Wait_Msg
    STC  ; Return login failed
    jmp loginExit
    
noAttemptsLeft:
    ; Display login failed message without attempts remaining
    INVOKE printString, ADDR loginFailMsg
    call Wait_Msg
    STC  ; Return login failed
    jmp loginExit
    
loginSuccess:
    ; Reset login attempts and timestamp on successful login
    mov BYTE PTR [OFFSET user.loginAttempt], '0'
    mov esi, OFFSET user.firstLoginAttemptTimestamp
    mov BYTE PTR [esi], '-'
    mov BYTE PTR [esi+1], 0
    
    ; Update user file with reset attempt count
    INVOKE updateUserFile, ADDR user
    
    ; Display success message
    INVOKE printString, ADDR loginSuccessMsg

    CLC  ; Return login succeeded
    call Wait_Msg

    ; Display customer menu
    customerMenu:
        INVOKE displayCustomerMenu, ADDR user
        .IF CARRY?
            call Clrscr
        .ENDIF
        jc customerMenu
   
loginExit:
    INVOKE clearUserCredential, ADDR user
    ret
login ENDP
END