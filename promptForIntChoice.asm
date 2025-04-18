
INCLUDE BangBangBank.inc

;-----------------------------------------------------------------
; This module will prompt and get the user's menu integer choice.
; If the input is invalid, the carry flag is set.
; Receives : The upper bound of choice, the lower bound of choice
; Returns : User's choice in AL
; Last update: 13/3/2025
;-----------------------------------------------------------------

.data
promptMsg BYTE "Enter your choice: ", 0
invalidChoiceMsg BYTE "Invalid option. Please try again", NEWLINE, 0
wrongTypeMessage BYTE "Please enter a number within the range", NEWLINE, 0

.code
promptForIntChoice PROC USES ebx ecx edx,
    lowerBound: BYTE,
    upperBound: BYTE

    INVOKE printString, OFFSET promptMsg
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT
    call ReadChar
    call WriteChar
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf
    call Crlf
    
    ; Check if it's 9 for special exit case
    .IF al == '9'
        CLC           ; Clear carry flag to indicate success
        jmp done      ; Jump to the end to return
    .ENDIF
    
    ; Check if input is a digit
    .IF al < '0' || al > '9'
        INVOKE printString, OFFSET wrongTypeMessage
        call Wait_Msg
        STC           ; Set carry flag to indicate error
        jmp done
    .ENDIF
    
    ; Convert ASCII to numeric value
    sub al, '0'
    
    ; Check if within bounds
    .IF al < lowerBound || al > upperBound
        INVOKE printString, OFFSET invalidChoiceMsg
        call Wait_Msg
        STC           ; Set carry flag to indicate error
        jmp done
    .ENDIF
    
    ; Input is valid, clear carry flag
    CLC

done:
    ret
promptForIntChoice ENDP
END