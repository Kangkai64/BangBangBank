
INCLUDE Irvine32.inc

encrypt PROTO,
    dataArray: PTR BYTE,
    keyArray: PTR BYTE

;----------------------------------------------------------------------
; Note:
; It might encounter bugs if the encrypted hashed value is 00h.
; It will not print the string with this hashed value as designed in the
; WriteString in Irvine32 library.
; Run this program in a new project and copy the hashed value
;----------------------------------------------------------------------

.data
; Test data
testMsg    BYTE "Pass123", 0
testMsg2   BYTE "JohnCena", 0 ; Put your string here
testHex    BYTE 35h, 0Dh, 16h, 03h, 59h, 53h, 5Dh, 28h, 21h, 28h ; Put your hex here to see the decrypted text
testKey    BYTE "elephant", 0 ; Put your encryption key here
decryptMsg BYTE 255 DUP(?)

; Output messages
promptTest    BYTE "Testing XOR encryption function...", 0dh, 0ah, 0
origPrompt    BYTE "Original message: ", 0
keyPrompt     BYTE "Encryption key:   ", 0
encPrompt     BYTE "Encrypted data:   ", 0
decPrompt     BYTE "Decrypted data:   ", 0
successPrompt BYTE 0dh, 0ah, "Encryption test successful!", 0dh, 0ah, 0
newLine       BYTE 0dh, 0ah, 0

.code
main PROC
    ; Display test header
    mov edx, OFFSET promptTest
    call WriteString
    
    ; Display original message
    mov edx, OFFSET origPrompt
    call WriteString
    mov edx, OFFSET testMsg2
    call WriteString
    mov edx, OFFSET newLine
    call WriteString
    
    ; Display encryption key
    mov edx, OFFSET keyPrompt
    call WriteString
    mov edx, OFFSET testKey
    call WriteString
    mov edx, OFFSET newLine
    call WriteString
    
    ; Call encrypt function with test message and key
    INVOKE encrypt, ADDR testMsg2, ADDR testKey
    mov esi, eax            ; ESI now has pointer to encrypted data
    
    ; Display encrypted data (as hex values since it may not be printable)
    mov edx, OFFSET encPrompt
    call WriteString
    
    push esi                ; Save encrypted data pointer
    
    ; Display all encrypted bytes as hex
    INVOKE Str_length, ADDR testMsg2
    mov ecx, eax
print_encrypted:
    mov al, BYTE PTR [esi]
    movzx eax, al           ; Zero-extend AL to EAX
    call WriteHex           ; Output in hexadecimal
    mov al, ' '             ; Space delimiter
    call WriteChar
    
    inc esi
    LOOP print_encrypted     ; Continue until null terminator
    
end_print:
    mov edx, OFFSET newLine
    call WriteString
    
    ; Now decrypt by XORing again with the same key
    pop esi                 ; Restore encrypted data pointer
    INVOKE encrypt, esi, ADDR testKey
    mov esi, eax            ; ESI now has pointer to decrypted data
    
    ; Display decrypted result
    mov edx, OFFSET decPrompt
    call WriteString
    INVOKE Str_length, ADDR testMsg2
    mov ecx, eax
    test_again:
        mov al, [esi]
        call WriteChar
        inc esi
        LOOP test_again

    mov edx, OFFSET newLine
    call WriteString
    
    ; Display success message
    mov edx, OFFSET successPrompt
    call WriteString
    
    exit
main ENDP
END main