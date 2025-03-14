
INCLUDE BangBangBank.inc

; This module will prompt and get the user's menu integer choice.
; If the input is invalid, the carry flag is set.
; Receives : The upper bound of choice, the lower bound of choice
; Returns : User's choice in EAX
; Last update: 13/3/2025

.data
promptMsg BYTE "Enter your choice: ", 0
invalidChoiceMsg BYTE NEWLINE, NEWLINE, "Invalid option. Please try again", NEWLINE, 0
wrongTypeMessage BYTE NEWLINE, NEWLINE, "Please enter a number within the range", NEWLINE, 0
exitMessage BYTE NEWLINE, NEWLINE, "Thank you for using Bang Bang Bank!", 0

.code
promptForIntChoice PROC USES ebx ecx edx,
    lowerBound: BYTE,
    upperBound: BYTE
    
    INVOKE printString, OFFSET promptMsg
    call ReadChar
    call WriteChar
    
    ; Check if it's 9 for special exit case
    .IF al == '9'
        INVOKE printString, OFFSET exitMessage
        CLC           ; Clear carry flag to indicate success
        jmp done      ; Jump to the end to return
    .ENDIF
    
    ; Check if input is a digit
    .IF al < '0' || al > '9'
        INVOKE printString, OFFSET wrongTypeMessage
        call myWait
        STC           ; Set carry flag to indicate error
        jmp done
    .ENDIF
    
    ; Convert ASCII to numeric value
    sub al, '0'
    
    ; Check if within bounds
    .IF al < lowerBound || al > upperBound
        INVOKE printString, OFFSET invalidChoiceMsg
        call myWait
        STC           ; Set carry flag to indicate error
        jmp done
    .ENDIF
    
    ; Input is valid, clear carry flag
    movzx eax, al     ; Zero-extend AL to EAX
    CLC

done:
    ret
promptForIntChoice ENDP
END