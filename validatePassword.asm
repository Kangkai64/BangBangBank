
INCLUDE BangBangBank.inc

;-------------------------------------------------------------------------------------
; This module will check and validate the password without decryption
; Receives : Input password pointer, hashed password pointer, encryption key pointer
; Returns : Carry flag is set if password is invalid, cleared if password is valid
; Last update: 16/3/2025
;-------------------------------------------------------------------------------------
.data
validationBuffer BYTE 255 DUP(?)

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
    mov esi, eax                         ; Encrypted input password
    INVOKE Str_length, esi
    INVOKE convertHexToString, esi, ADDR validationBuffer, eax  ; Convert binary to string
    lea esi, validationBuffer            ; Now use string version for comparison
    mov edi, hashedPassword              ; Stored hashed password

    ; Compare the results
    push ecx                ; Save registers
    push esi
    push edi
    
    ; Tried to check their content
    INVOKE printString, esi
    call Crlf
    INVOKE printString, edi
    call Crlf

compareLoop:
    mov al, [esi]
    mov dl, [edi]
    
    ; There's space in the hashed password
    checkSpace:
        cmp dl, ' '
        jne continue
        inc edi
        jmp compareLoop

    continue:
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
    STC                     ; Set failure flag
    jmp validatePasswordExit
    
comparisonDone:
    CLC ; Clear carry if successed

validatePasswordExit:
    pop edi                 ; Restore registers
    pop esi
    pop ecx
    popad
    ret
validatePassword ENDP
END