INCLUDE BangBangBank.inc
;-----------------------------------------------------------
; This module will print monthly statement for the user
; Receives : Nothing
; Returns : Nothing
; Last update: 14/4/2025
;-----------------------------------------------------------
.data
; General formatting constants
lineWidth       BYTE 100               ; Width of the entire statement
leftPad         BYTE 5 DUP(32), 0      ; Left margin padding
spaceChar       BYTE " ", 0            ; Single space character

; Month input prompt and validation
monthPrompt     BYTE "Enter month (MM/YYYY format or 'all'), or press Enter to go back: ", 0
invalidFormat   BYTE "Invalid format! Please use MM/YYYY format (e.g., 03/2025) or 'all'.", 0
selectedMonth   BYTE "all", 0        ; Buffer to store user-selected month, default to "all"
monthBuffer     BYTE 32 DUP(0)         ; Temporary buffer for month input
charIndex       DWORD 0                ; Index for character input
exitflag        DWORD 0                ; Flag to indicate exit from the loop

; Constant for "all" option
allOption       BYTE "all", 0

; Statement headers and separators
bankHeader      BYTE "Bang Bang Bank", 0
bankAddress     BYTE "10th floor, Tower A, Dataran Bang Bang, 1, Jalan Hijau, 59000, Kuala Lumpur", 0
monthLabel       BYTE "Month:", 0
statementDate   BYTE "STATEMENT DATE: ", 0
timeOutputBuffer BYTE 32 DUP(?)
timeDate BYTE 16 DUP(?)
accountLabel    BYTE "ACCOUNT NUMBER:", 0
pidmNotice      BYTE "PROTECTED BY PIDM UP TO RM250,000 FOR EACH DEPOSITOR", 0
accountType     BYTE "SAVINGS ACCOUNT", 0
transHeader     BYTE "ACCOUNT TRANSACTIONS", 0
columnHeader    BYTE "     ENTRY DATE     |     TRANSACTION DESCRIPTION     |     STATEMENT BALANCE     |     AMOUNT     ", 0
doubleLine      BYTE "====================================================================================================", 0
singleLine      BYTE "----------------------------------------------------------------------------------------------------", 0

; Footer data
endingBalance   BYTE "ENDING BALANCE:", 0
totalCredit     BYTE "TOTAL CREDIT", 0
totalDebit      BYTE "TOTAL DEBIT", 0
avgExpenses     BYTE "AVERAGE EXPENSES", 0
variance        BYTE "VARIANCE", 0
stdDev          BYTE "STANDARD DEVIATION", 0

note            BYTE "Note:", 0
note1           BYTE "1. All items and balances shown will be considered correct unless the Bank is notified in writing of any", 0
note2           BYTE "   discrepancies within 21 days.", 0
note3           BYTE "2. Please notify any change of address in writing.", 0

currentTime     SYSTEMTIME <>
transaction     userTransaction <>

; Additional variables for alignment
tempBuffer      BYTE 256 DUP(0)        ; Temporary buffer for string formatting

.code
; Function to get and validate month input from user character by character
getSelectedMonth PROC
    LOCAL inputLen:DWORD
    LOCAL currChar:BYTE

getMonthInput:
    ; Clear the month buffer
    mov ecx, LENGTHOF monthBuffer
    mov edi, OFFSET monthBuffer
    mov al, 0
    rep stosb

    ; Reset character index
    mov charIndex, 0
    
    ; Reset exit flag
    mov exitflag, 0

    ; Prompt for month
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR monthPrompt
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, INPUT

    ; Get input character by character
    mov edi, OFFSET monthBuffer
charInputLoop:
    call ReadChar
    
    ; Check for Enter key (end of input)
    .IF al == 13
        ; Add null terminator
        mov BYTE PTR [edi], 0
        
        ; Check if input is empty (first character is null)
        mov edi, OFFSET monthBuffer
        mov al, BYTE PTR [edi]
        .IF al == 0
            ; Set exit flag for empty input
            mov exitflag, 1
            INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
            call Crlf
            jmp done
        .ELSE
            jmp validateInput
        .ENDIF
    .ENDIF
    
    ; Check for Backspace
    .IF al == 8
        ; Handle backspace if not at beginning
        .IF charIndex > 0
            ; Move cursor back, print space, move cursor back again
            call WriteChar    ; Backspace moves cursor back
            mov al, 32        ; Space character
            call WriteChar    ; Write space to erase character
            mov al, 8         ; Backspace character
            call WriteChar    ; Move cursor back again
            
            ; Update buffer and index
            dec edi
            dec charIndex
        .ENDIF
    .ELSE
        ; Store character if buffer not full (limit to 10 chars for safety)
        .IF charIndex < 10
            mov BYTE PTR [edi], al
            inc edi
            inc charIndex
            call WriteChar    ; Echo character
        .ENDIF
    .ENDIF
    
    jmp charInputLoop

validateInput:
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf
    ; Check for "all" option (case sensitive)
    INVOKE Str_compare, ADDR monthBuffer, ADDR allOption
    .IF ZERO?
        ; User entered "all"
        ; Clear the selected month buffer
        mov ecx, LENGTHOF selectedMonth
        mov edi, OFFSET selectedMonth
        mov al, 0
        rep stosb
        ; Copy "all" to selectedMonth
        INVOKE Str_copy, ADDR allOption, ADDR selectedMonth
        jmp validInput
    .ENDIF

    ; Validate MM/YYYY format
    INVOKE Str_length, ADDR monthBuffer
    mov inputLen, eax
    
    ; Check length (should be 7 characters: MM/YYYY)
    .IF inputLen != 7
        jmp invalidInput
    .ENDIF
    
    ; Check if month is numeric (0-9)
    mov al, monthBuffer
    .IF al < '0' || al > '9'
        jmp invalidInput
    .ENDIF
    
    mov al, monthBuffer+1
    .IF al < '0' || al > '9'
        jmp invalidInput
    .ENDIF
    
    ; Check for '/' separator
    mov al, monthBuffer+2
    .IF al != '/'
        jmp invalidInput
    .ENDIF
    
    ; Check if year is numeric (0-9)
    mov ecx, 4  ; Check 4 digits for year
    mov esi, OFFSET monthBuffer
    add esi, 3  ; Start at year position
yearLoop:
    mov al, [esi]
    .IF al < '0' || al > '9'
        jmp invalidInput
    .ENDIF
    inc esi
    loop yearLoop
    ; Clear the selected month buffer
    mov ecx, LENGTHOF selectedMonth
    mov edi, OFFSET selectedMonth
    mov al, 0
    rep stosb
    ; Valid format, copy to selectedMonth
    INVOKE Str_copy, ADDR monthBuffer, ADDR selectedMonth
    jmp validInput
    
invalidInput:
    INVOKE printString, ADDR leftPad	; Invalid format message
    INVOKE printString, ADDR invalidFormat
    call Crlf
    jmp getMonthInput
    
validInput:
    ; Make sure exit flag is not set for valid input
    mov exitflag, 0

done:
    ret
getSelectedMonth ENDP

; Function to create and print a right-aligned field
rightAlignField PROC,
    labelPtr:PTR BYTE,
    valuePtr:PTR BYTE,
    fieldWidth:DWORD
    
    LOCAL totalLen:DWORD
    LOCAL padLen:DWORD
    
    pushad

    ; Calculate total length of label and value
    INVOKE Str_length, labelPtr
    mov totalLen, eax
    
    INVOKE Str_length, valuePtr
    add totalLen, eax
    
    ; Calculate padding needed
    mov eax, fieldWidth
    sub eax, totalLen
    mov padLen, eax
    
    ; Print the label
    INVOKE printString, labelPtr
    
    ; Print padding spaces
    mov ecx, padLen
    cmp ecx, 0
    jle skipPad
padLoop:
    INVOKE printString, ADDR spaceChar
    loop padLoop
skipPad:
    
    ; Print the value
    INVOKE printString, valuePtr
    
    popad
    ret
rightAlignField ENDP

printMonthlyStatement PROC,
    account: PTR userAccount
    
    LOCAL textLen:DWORD
    LOCAL padLen:DWORD
    LOCAL totalWidth:DWORD
    
statementLoop:
    mov totalWidth, 90          ; Total width for content
    
    ; Skip month selection prompt on first run (it's already set to "all")
    ; Will only prompt after first statement is displayed
    
    ; Clear the screen
    call clearConsole
    
    ; Print left margin padding
    INVOKE printString, ADDR leftPad
    
    ; Bank header (centered manually)
    INVOKE Str_length, ADDR bankHeader
    mov textLen, eax
    
    mov eax, totalWidth
    sub eax, textLen
    shr eax, 1                ; Divide by 2 to get left padding
    mov padLen, eax
    
    ; Print padding spaces for centering
    mov ecx, padLen
    cmp ecx, 0
    jle skipHeaderPad
headerPadLoop:
    INVOKE printString, ADDR spaceChar
    loop headerPadLoop
skipHeaderPad:
    
    ; Print bank header
    INVOKE printString, ADDR bankHeader
    call Crlf
    
    ; Print left margin padding
    INVOKE printString, ADDR leftPad
    
    ; Bank address (centered manually)
    INVOKE Str_length, ADDR bankAddress
    mov textLen, eax
    
    mov eax, totalWidth
    sub eax, textLen
    shr eax, 1                ; Divide by 2 to get left padding
    mov padLen, eax
    
    ; Print padding spaces for centering
    mov ecx, padLen
    cmp ecx, 0
    jle skipAddressPad
addressPadLoop:
    INVOKE printString, ADDR spaceChar
    loop addressPadLoop
skipAddressPad:
    
    ; Print bank address
    INVOKE printString, ADDR bankAddress
    call Crlf
    call Crlf
    
    ; Customer information (left column)
    INVOKE printString, ADDR leftPad
    mov esi, [account]
    add esi, OFFSET userAccount.full_name
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
    INVOKE printString, esi
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    
    ; Fill the rest of the line with spaces to position right column
    INVOKE Str_length, esi
    mov ecx, 45                    ; Position for right column
    sub ecx, eax                   ; Subtract name length to get padding needed
    
    cmp ecx, 0
    jle skipPadName
padNameLoop:
    INVOKE printString, ADDR spaceChar
    loop padNameLoop
skipPadName:
    
    ; Statement information (right column)
    INVOKE printString, ADDR monthLabel
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
    INVOKE printString, ADDR selectedMonth
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf
    call Crlf
    
    ; Print left margin padding
    INVOKE printString, ADDR leftPad
    
    ; Fill with spaces to reach right column position
    mov ecx, 45                    ; Position for right column
padDateLabelLoop:
    INVOKE printString, ADDR spaceChar
    loop padDateLabelLoop
    
    ; Print statement date information (right-aligned)
    INVOKE printString, ADDR statementDate

    start:
    ; Get current time and format it in DD/MM/YYYY HH:MM:SS format
    INVOKE GetLocalTime, ADDR currentTime
    INVOKE formatSystemTime, ADDR currentTime, ADDR timeOutputBuffer

    ; Copy the date part of the time stamp
    lea esi, timeOutputBuffer
    lea edi, timeDate
    mov ecx, 10

    copy_date:
        mov eax, [esi]
        mov [edi], eax
        inc esi
        inc edi
        LOOP copy_date

    ; Add null terminator
    mov BYTE PTR [edi], 0

    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
    INVOKE printString, ADDR timeDate
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf
    
    ; Print left margin padding
    INVOKE printString, ADDR leftPad
    
    ; Fill with spaces to reach right column position
    mov ecx, 45                    ; Position for right column
padAcctLabelLoop:
    INVOKE printString, ADDR spaceChar
    loop padAcctLabelLoop
    
    ; Print account number information (right-aligned)
    INVOKE printString, ADDR accountLabel
    
    INVOKE printString, ADDR spaceChar
    
    mov esi, [account]
    add esi, OFFSET userAccount.account_number
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DATE
    INVOKE printString, esi
    INVOKE setTxtColor, DEFAULT_COLOR_CODE, DEFAULT_COLOR_CODE
    call Crlf
    call Crlf
    
    ; PIDM Notice (left-aligned)
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR pidmNotice
    
    ; Fill remainder of line with spaces
    INVOKE Str_length, ADDR pidmNotice
    mov ecx, 60                    ; Position for account type
    sub ecx, eax                   ; Subtract notice length to get padding needed
    
    cmp ecx, 0
    jle skipPadNotice
padNoticeLoop:
    INVOKE printString, ADDR spaceChar
    loop padNoticeLoop
skipPadNotice:
    
    ; Account Type (right-aligned)
    INVOKE printString, ADDR accountType
    call Crlf
    
    ; Double line
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR doubleLine
    call Crlf
    
    ; Account Transactions header (centered manually)
    INVOKE printString, ADDR leftPad
    
    INVOKE Str_length, ADDR transHeader
    mov textLen, eax
    
    mov eax, totalWidth
    sub eax, textLen
    shr eax, 1                ; Divide by 2 to get left padding
    mov padLen, eax
    
    ; Print padding spaces for centering
    mov ecx, padLen
    cmp ecx, 0
    jle skipTransHeaderPad
transHeaderPadLoop:
    INVOKE printString, ADDR spaceChar
    loop transHeaderPadLoop
skipTransHeaderPad:
    
    ; Print transactions header
    INVOKE printString, ADDR transHeader
    call Crlf
    
    ; Double line
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR doubleLine
    call Crlf
    
    ; Column headers
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR columnHeader
    call Crlf
    
    ; Single line
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR singleLine
    call Crlf
    
    ; Copy customer_id to transaction structure
    mov esi, [account]
    add esi, OFFSET userAccount.customer_id
    INVOKE Str_copy, esi, ADDR transaction.customer_id

    ; Transaction details - pass selectedMonth to filter transactions
    INVOKE inputFromTransaction, ADDR transaction, ADDR selectedMonth

    ; Double line
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR doubleLine
    call Crlf

    call printTotal
    
    ; Single line
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR singleLine
    call Crlf
    
    ; Print notes and menu
    call MSnote
    
    ; Now prompt for month filter (after showing the statement)
    call Crlf
    call getSelectedMonth
    
    ; Check if exit flag is set (indicating empty input)
    call clearConsole
    cmp exitflag, 1
    je done
    
    ; Otherwise, continue with the new month filter
    jmp statementLoop
    
done:
    STC                            ; Don't logout the user
    ret
printMonthlyStatement ENDP

MSnote PROC
    pushad
    
    ; Note header
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR note
    call Crlf
    
    ; Note 1
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR note1
    call Crlf
    
    ; Note 2
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR note2
    call Crlf
    
    ; Note 3
    INVOKE printString, ADDR leftPad
    INVOKE printString, ADDR note3
    call Crlf
    call Crlf
    
    popad
    ret
MSnote ENDP
END