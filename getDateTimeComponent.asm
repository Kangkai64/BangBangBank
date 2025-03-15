INCLUDE BangBangBank.inc

;---------------------------------------------------------------
; This module will print out the date and time 
; component of the current time, based on the option received.
; 1 for YEAR, 2 for MONTH, 3 for DAY, 4 for WEEKDAY,
; 5 for DATE (MM/DD/YYYY), 6 for TIME (HH:MM:SS)
; Receives : option (BYTE)
; Returns : Nothing
; Last update: 13/3/2025
;--------------------------------------------------------------

.data
dateTime SYSTEMTIME <>
weekdays BYTE "Sunday", 0, "Monday", 0, "Tuesday", 0, "Wednesday", 0, "Thursday", 0, "Friday", 0, "Saturday", 0

.code
getDateTimeComponent PROC,
    timeOption: BYTE
    ; Get the current system date and time
    INVOKE GetLocalTime, ADDR dateTime

    mov al, timeOption

    .IF al == YEAR
        movzx eax, dateTime.wYear
        call WriteDec
        call Crlf

    .ELSEIF al == MONTH
        movzx eax, dateTime.wMonth
        call WriteDec
        call Crlf

    .ELSEIF al == DAY
        movzx eax, dateTime.wDay
        call WriteDec
        call Crlf

    .ELSEIF al == WEEKDAY
        movzx eax, dateTime.wDayOfWeek
        lea edi, [weekdays + eax * 8]  ; Each weekday name is 8 bytes
        call WriteString
        call Crlf

    .ELSEIF al == DATE ; (DD/MM/YYYY)
        movzx eax, dateTime.wDay
        call WriteDec
        mov al, '/'
        call WriteChar

        movzx eax, dateTime.wMonth
        call WriteDec
        mov al, '/'
        call WriteChar

        movzx eax, dateTime.wYear
        call WriteDec
        call Crlf

    .ELSEIF al == TIME ; (HH:MM:SS)
        movzx eax, dateTime.wHour
        call WriteDec
        mov al, ':'
        call WriteChar

        movzx eax, dateTime.wMinute
        .IF eax < 10
            mov al, '0'
            call WriteChar
            movzx eax, dateTime.wMinute
        .ENDIF
        call WriteDec

        mov al, ':'
        call WriteChar

        movzx eax, dateTime.wSecond
        .IF eax < 10
            mov al, '0'
            call WriteChar
            movzx eax, dateTime.wSecond
        .ENDIF
        call WriteDec
        call Crlf
    .ENDIF

    ret
getDateTimeComponent ENDP
END