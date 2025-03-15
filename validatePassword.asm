
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will check and validate the password without decryption
; Receives : Input password pointer, hashed password pointer, encryption key pointer
; Returns : EAX = 1 if password is valid, 0 if invalid
; Last update: 15/3/2025
;------------------------------------------------------------------------
.data
validationBuffer BYTE 255 DUP(?)
validationSuccess BYTE "Password is valid.", NEWLINE, 0
validationFailure BYTE "Password is invalid.", NEWLINE, 0

.code
validatePassword PROC,
    inputPassword: PTR BYTE,
    hashedPassword: PTR BYTE,
    encryptionKey: PTR BYTE
    
    pushad
    
    ; First determine key length
    mov edx, encryptionKey
    call Str_length
    mov ecx, eax            ; Store key length in ECX
    
    ; Hash the input password with encryption key
    INVOKE encrypt, inputPassword, encryptionKey
    
    ; EAX now contains pointer to encrypted result
    mov esi, eax            ; Encrypted input password
    mov edi, hashedPassword ; Stored hashed password
    
    ; Compare the results
    push ecx                ; Save registers
    push esi
    push edi
    
    mov ebx, 1              ; Default to success
    
compareLoop:
    mov al, [esi]
    mov dl, [edi]
    
    ; Check if we've reached the end of either string
    cmp al, 0
    je checkEndDest
    cmp dl, 0
    je notMatching
    
    ; Compare characters
    cmp al, dl
    jne notMatching
    
    ; Move to next character
    inc esi
    inc edi
    jmp compareLoop
    
checkEndDest:
    cmp dl, 0               ; Check if destination also ended
    jne notMatching
    jmp comparisonDone      ; Both strings ended, match found
    
notMatching:
    mov ebx, 0              ; Set failure flag
    
comparisonDone:
    pop edi                 ; Restore registers
    pop esi
    pop ecx
    
    ; Set return value
    mov [esp+28], ebx       ; Update EAX in saved registers (return value)
    
    ; Optional: Print result for debugging
    .IF ebx == 1
        INVOKE printString, ADDR validationSuccess
    .ELSE
        INVOKE printString, ADDR validationFailure
    .ENDIF
    
    ; Uncomment to display validation result
    call WriteString
    call Crlf
    
    popad
    ret
validatePassword ENDP
END