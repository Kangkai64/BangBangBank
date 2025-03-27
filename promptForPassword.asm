
INCLUDE BangBangBank.inc

;------------------------------------------------------------------------
; This module will prompt and get the password with masking and trims it
; to avoid excessive spaces
; Receives : The address / pointer of the password variable from caller
; Returns : Nothing
; Last update: 15/3/2025
;------------------------------------------------------------------------
.data

asterisk BYTE "*", 0
backspace = 8   ; ASCII value for backspace
enterKey = 13      ; ASCII value for enter key

.code
promptForPassword PROC,
    inputPasswordAddress: PTR BYTE,
    promptMessageAddress: PTR BYTE
    
    pushad

    INVOKE printString, promptMessageAddress
   
    ; Set up registers for password reading
    mov edi, inputPasswordAddress  ; Destination for actual password
    xor ecx, ecx                   ; Character counter
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT
    
readNextChar:
    ; Check if we've reached buffer limit
    cmp ecx, maxBufferSize - 2     ; Leave space for null terminator
    jae finishReading
    
    ; Read a single character (without echo)
    call ReadChar                  ; AL will contain the character
    
    ; Check for backspace
    cmp al, backspace
    je handleBackspace
    
    ; Check for enter key (end of input)
    cmp al, enterKey
    je finishReading
    
    ; Store the actual character in the password buffer
    mov [edi + ecx], al
    inc ecx
    
    ; Display an asterisk instead of the actual character
    push eax                       ; Save the actual character
    mov al, asterisk
    call WriteChar                 ; Display asterisk
    pop eax                        ; Restore the actual character
    
    jmp readNextChar
    
handleBackspace:
    ; Only handle backspace if we have characters to delete
    cmp ecx, 0
    je readNextChar                ; If at beginning, ignore backspace
    
    ; Handle backspace by moving cursor back, printing space, moving back again
    dec ecx                        ; Decrement counter
    mov al, backspace
    call WriteChar               ; Move cursor left
    mov al, ' '
    call WriteChar               ; Write space over the character
    mov al, backspace
    call WriteChar               ; Move cursor left again
    
    jmp readNextChar
    
finishReading:
    ; Null-terminate the password string
    mov BYTE PTR [edi + ecx], 0
    
    call Crlf
    ; Trims the password
    INVOKE myStr_trim, inputPasswordAddress, " "
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

    popad
    ret
promptForPassword ENDP
END