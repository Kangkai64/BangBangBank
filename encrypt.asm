
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module implements XOR encryption for data
; Receives: Data array to be encrypted and the encryption 
;           key array
; Returns: Encrypted data array's address in EAX
; Last update: 15/3/2025
;------------------------------------------------------

.data
encryptedDataArray BYTE 255 DUP(?)
arrayLength DWORD ?
keyLength DWORD ?

.code
encrypt PROC,
    dataArray: PTR BYTE,
    keyArray: PTR BYTE
    
    pushad
    
    ; Get string length of data
    mov edx, dataArray
    call Str_length
    mov arrayLength, eax
    
    ; Get key length of data
    mov edx, keyArray
    call Str_length
    mov keyLength, eax

    ; Initialize loop
    mov ecx, arrayLength
    mov esi, dataArray      ; Source data pointer
    mov edi, OFFSET encryptedDataArray ; Destination pointer
    mov ebx, keyArray       ; Key pointer
    mov edx, 0              ; Index for key wrapping
    
encrypt_data:
    ; Load a single byte
    mov al, BYTE PTR [esi]
    
    ; Get current key byte and XOR
    push ecx                ; Save main counter
    mov ecx, edx            ; Current key index
    mod_key:
        cmp ecx, keyLength
        jl use_key
        sub ecx, keyLength
        jmp mod_key
    use_key:
        mov edx, ecx        ; Save key index for next iteration
        mov ah, BYTE PTR [ebx + ecx]
        xor al, ah          ; XOR data with key
    pop ecx                 ; Restore main counter
    
    ; Store encrypted byte
    mov BYTE PTR [edi], al
    
    ; Increment pointers and key index
    inc esi
    inc edi
    inc edx
    
    LOOP encrypt_data
    
    ; Set terminating null byte
    mov BYTE PTR [edi], 0
    
    popad
    
    ; Return pointer to encrypted data
    mov eax, OFFSET encryptedDataArray
    ret
encrypt ENDP
END