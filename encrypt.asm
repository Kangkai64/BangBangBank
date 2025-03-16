
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
    
    call Crlf
    ; Get string length of data
    INVOKE Str_length, dataArray
    mov arrayLength, eax
    
    ; Get key length of data
    INVOKE Str_length, keyArray
    mov keyLength, eax
    
    ; Initialize loop
    mov ecx, arrayLength
    mov esi, dataArray      ; Source data pointer
    mov edi, OFFSET encryptedDataArray ; Destination pointer
    mov ebx, keyArray       ; Key pointer
    xor edx, edx            ; Key index counter (start at 0)
    
encrypt_data:
    ; Load a single byte
    mov al, BYTE PTR [esi]
    
    ; Get current key byte and XOR
    mov eax, edx            ; Put key index in eax
    xor edx, edx            ; Clear edx for division
    div keyLength           ; Divide by key length, remainder in edx
    mov al, BYTE PTR [ebx + edx] ; Get key byte using remainder
    xor al, BYTE PTR [esi]  ; XOR with data byte
    
    ; Store encrypted byte
    mov BYTE PTR [edi], al
    
    ; Increment pointers and key index
    inc esi
    inc edi
    inc edx
    
    dec ecx
    jnz encrypt_data
    
    ; Set terminating null byte
    mov BYTE PTR [edi], 0
    
    popad
    
    ; Return pointer to encrypted data
    mov eax, OFFSET encryptedDataArray
    ret
encrypt ENDP
END