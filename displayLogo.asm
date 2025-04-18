
INCLUDE BangBangBank.inc

;------------------------------------------------------
; This module will print the main menu onto the console
; Receives : Nothing
; Returns : Nothing
; Last update: 13/3/2025
;------------------------------------------------------

.data
logoDesign BYTE NEWLINE, NEWLINE,
               "   ___                 ___                 ___            __  ", NEWLINE,
               "  / _ )___ ____  ___ _/ _ )___ ____  ___ _/ _ )___ ____  / /__", NEWLINE,
               " / _  / _ `/ _ \/ _ `/ _  / _ `/ _ \/ _ `/ _  / _ `/ _ \/  '_/", NEWLINE,
               "/____/\_,_/_//_/\_, /____/\_,_/_//_/\_, /____/\_,_/_//_/_/\_\ ", NEWLINE,
               "               /___/               /___/                      ", NEWLINE,
               NEWLINE, NEWLINE, 0

.code
displayLogo PROC

    pushad

    INVOKE setTxtColor, DEFAULT_COLOR_CODE, LOGO
    INVOKE printString, ADDR logoDesign
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE

    popad
    ret
displayLogo ENDP
END