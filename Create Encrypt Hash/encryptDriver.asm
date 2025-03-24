
INCLUDE Irvine32.inc

encrypt PROTO,
    dataArray: PTR BYTE,
    keyArray: PTR BYTE
printString PROTO,
    textAddress: PTR BYTE

.data
; Test data
testMsg      BYTE 255 DUP(?)
msgBytesRead BYTE ?
testHex      BYTE 35h, 0Dh, 16h, 03h, 59h, 53h, 5Dh, 28h, 21h, 28h
testKey      BYTE 255 DUP(?)
keyBytesRead BYTE ?
decryptMsg   BYTE 255 DUP(?)
; Output messages
resultHeader  BYTE 0dh, 0ah, 
                   "===========================================", 0dh, 0ah,
                   "                   Result                  ", 0dh, 0ah,
                   "===========================================", 0dh, 0ah, 0
promptTest    BYTE "Testing XOR encryption function...", 0dh, 0ah, 0
origPrompt    BYTE "Original message : ", 0
keyPrompt     BYTE "Encryption key   : ", 0
encPrompt     BYTE "Encrypted data   : ", 0
decPrompt     BYTE "Decrypted data   : ", 0
successPrompt BYTE 0dh, 0ah, "Encryption test successful!", 0dh, 0ah, 0
newLine       BYTE 0dh, 0ah, 0
.code
;-----------------------------------------------------
; WriteHexByte - Displays a byte in hexadecimal format
; Receives: AL = byte to display
; Returns: Nothing
;-----------------------------------------------------
WriteHexByte PROC
    push eax
    push ebx
    
    movzx eax, al           ; Zero-extend AL to EAX
    mov ebx, eax            ; Save a copy
    
    ; Display first hex digit
    shr eax, 4              ; Shift right to get high 4 bits
    call WriteHexDigit
    
    ; Display second hex digit
    mov eax, ebx            ; Restore original value
    and eax, 0Fh            ; Mask to get low 4 bits
    call WriteHexDigit
    
    ; Add space after hex byte
    mov al, ' '
    call WriteChar
    
    pop ebx
    pop eax
    ret
WriteHexByte ENDP

;-----------------------------------------------------
; WriteHexDigit - Displays a single hex digit
; Receives: AL = value (0-15)
; Returns: Nothing
;-----------------------------------------------------
WriteHexDigit PROC
    push eax
    
    cmp al, 10              ; Check if digit or letter
    jl digit
    add al, 'A' - 10        ; Convert to A-F
    jmp display
digit:
    add al, '0'             ; Convert to 0-9
display:
    call WriteChar
    
    pop eax
    ret
WriteHexDigit ENDP

main PROC
    ; Display test header
    INVOKE printString, ADDR promptTest
    
    ; Prompt and get message to be encrypted
    INVOKE printString, ADDR origPrompt
    lea edx, testMsg
    mov ecx, SIZEOF testMsg
    call ReadString
    mov BYTE PTR msgBytesRead, al
    
    ; Prompt and get encryption key
    INVOKE printString, ADDR keyPrompt
    lea edx, testKey
    mov ecx, SIZEOF testKey
    call ReadString
    mov BYTE PTR keyBytesRead, al
    
    ; Display original message
    INVOKE printString, ADDR resultHeader
    INVOKE printString, ADDR origPrompt
    INVOKE printString, ADDR testMsg
    INVOKE printString, ADDR newLine
    INVOKE printString, ADDR keyPrompt
    INVOKE printString, ADDR testKey
    INVOKE printString, ADDR newLine
    
    ; Call encrypt function with test message and key
    INVOKE encrypt, ADDR testMsg, ADDR testKey
    mov esi, eax            ; ESI now has pointer to encrypted data
    
    ; Display encrypted data as hex values
    INVOKE printString, ADDR encPrompt
    
    push esi                ; Save encrypted data pointer
    
    ; Display all encrypted bytes as hex
    INVOKE Str_length, ADDR testMsg
    mov ecx, eax
    
print_encrypted:
    mov al, BYTE PTR [esi]
    call WriteHexByte       ; Call our new hex display function
    inc esi
    loop print_encrypted
    
    INVOKE printString, ADDR newLine
    
    ; Now decrypt by XORing again with the same key
    pop esi                 ; Restore encrypted data pointer
    INVOKE encrypt, esi, ADDR testKey
    mov esi, eax            ; ESI now has pointer to decrypted data
    
    ; Display decrypted result
    INVOKE printString, ADDR decPrompt
    INVOKE Str_length, ADDR testMsg
    mov ecx, eax
    
display_decrypted:
    mov al, [esi]
    call WriteChar          ; Display as ASCII character
    inc esi
    loop display_decrypted
    
    INVOKE printString, ADDR newLine
    
    ; Display success message
    INVOKE printString, ADDR successPrompt
    
    exit
main ENDP
END main