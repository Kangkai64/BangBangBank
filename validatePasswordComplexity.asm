
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will validate the complexity of the password.
; It sets the carry flag if the complexity is invalid, 
; clears the carry flag if the complexity is valid
; Receives : Password string pointer / address
; Returns : Nothing
; Last update: 26/3/2025
;------------------------------------------------------------------------
.code
validatePasswordComplexity PROC USES esi ecx, 
    pPassword:PTR BYTE

    LOCAL hasUpper:BYTE, hasLower:BYTE, hasDigit:BYTE, hasSpecial:BYTE
    
    ; Initialize flags to 0 (false)
    mov hasUpper, 0
    mov hasLower, 0
    mov hasDigit, 0
    mov hasSpecial, 0
    
    ; Set up loop to check each character
    mov esi, pPassword
    
checkComplexity: 
    mov al, [esi]       ; Get current character
    cmp al, 0           ; Check for null terminator
    je doneProcessing   ; Exit loop if end of string
    
    ; Check for uppercase letter (ASCII 'A' to 'Z' = 65 to 90)
    cmp al, 'A'
    jb notUppercase
    cmp al, 'Z'
    ja notUppercase
    mov hasUpper, 1     ; Set uppercase flag
    jmp nextChar
    
notUppercase:
    ; Check for lowercase letter (ASCII 'a' to 'z' = 97 to 122)
    cmp al, 'a'
    jb notLowercase
    cmp al, 'z'
    ja notLowercase
    mov hasLower, 1     ; Set lowercase flag
    jmp nextChar
    
notLowercase:
    ; Check for digit (ASCII '0' to '9' = 30h to 39h)
    cmp al, '0'
    jb notDigit
    cmp al, '9'
    ja notDigit
    mov hasDigit, 1     ; Set digit flag
    jmp nextChar
    
notDigit:
    ; Check for special characters [@$!%*?&]
    cmp al, '@'
    je foundSpecial
    cmp al, '$'
    je foundSpecial
    cmp al, '!'
    je foundSpecial
    cmp al, '%'
    je foundSpecial
    cmp al, '*'
    je foundSpecial
    cmp al, '?'
    je foundSpecial
    cmp al, '&'
    je foundSpecial
    jmp nextChar
    
foundSpecial:
    mov hasSpecial, 1   ; Set special character flag
    
nextChar:
    inc esi             ; Move to next character
    jmp checkComplexity ; Continue loop
    
doneProcessing:
    ; Check if all requirements were met
    mov al, hasUpper
    cmp al, 1
    jne validationFailed
    
    mov al, hasLower
    cmp al, 1
    jne validationFailed
    
    mov al, hasDigit
    cmp al, 1
    jne validationFailed
    
    mov al, hasSpecial
    cmp al, 1
    jne validationFailed
    
    ; All requirements met, return success
    CLC
    jmp validationDone
    
validationFailed:
    STC         ; Return failure
    
validationDone:
    ret
validatePasswordComplexity ENDP
END