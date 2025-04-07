
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
    INVOKE Str_length, ADDR encryptionKey
    mov ecx, eax            ; Store key length in ECX
    
    ; Hash the input password with encryption key
    INVOKE encrypt, inputPassword, encryptionKey

    ; EAX now contains pointer to encrypted result
    mov esi, eax                         ; Encrypted input password
    INVOKE Str_length, esi
    INVOKE convertHexToString, esi, ADDR validationBuffer, eax  ; Convert hex values to string
    lea esi, validationBuffer            ; Now use string version for comparison
    mov edi, hashedPassword              ; Stored hashed password

    ; Compare the results
    INVOKE Str_compare, ADDR validationBuffer, hashedPassword
    je comparisonDone       ; If equal, clear carry flag
    
notMatching:
    STC                     ; Set failure flag
    jmp validatePasswordExit
    
comparisonDone:
    CLC ; Clear carry if successed

validatePasswordExit:
    popad
    ret
validatePassword ENDP
END