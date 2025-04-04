INCLUDE BangBangBank.inc
;-----------------------------------------------------------
; This module will print monthly statement for the user
; Receives : Nothing
; Returns : Nothing
; Last update: 2/4/2025
;-----------------------------------------------------------
.data
bankHeader      BYTE "Bang Bang Bank", 0
bankAddress     BYTE "10th floor, Tower A, Dataran Bang Bang, 1, Jalan Hijau, 59000, Kuala Lumpur", 0
pageLabel       BYTE "PAGE", 0
pageNum         BYTE ": 1", 0
statementDate   BYTE "STATEMENT DATE", 0
dateValue       BYTE ": 31 / 03 / 2025", 0
accountLabel    BYTE "ACCOUNT NUMBER", 0
pidmNotice      BYTE "PROTECTED BY PIDM UP TO RM250,000 FOR EACH DEPOSITOR", 0
accountType     BYTE "SAVINGS ACCOUNT", 0
transHeader     BYTE "ACCOUNT TRANSACTIONS", 0
columnHeader1   BYTE "ENTRY DATE", 0
columnHeader2   BYTE "TRANSACTION DESCRIPTION", 0
columnHeader3   BYTE "TRANSACTION", 0
columnHeader4   BYTE "STATEMENT BALANCE", 0
amountLabel     BYTE "AMOUNT", 0
beginBalance    BYTE "BEGINNING BALANCE", 0
doubleLine      BYTE "===========================================================================", 0
singleLine      BYTE "---------------------------------------------------------------------------", 0


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

menuPrompt      BYTE "Enter your choice:", 0
menuOption1     BYTE "1. Previous Page", 0
menuOption2     BYTE "2. Next Page", 0
menuOption3     BYTE "9. Back to Account Dashboard", 0
menuNoNext      BYTE "If no next page:", 0
menuContinue    BYTE "Press any key to continue...", 0

currentTime     SYSTEMTIME <>
timeOutputBuffer BYTE 32 DUP(?)
transaction     userTransaction <>

.code
printMonthlyStatement PROC,
    account: PTR userAccount
    
    ; Clear the screen
    call Clrscr
    
    ; Bank header
    mov dl, 40
    mov dh, 1
    call Gotoxy
    INVOKE printString, ADDR bankHeader
    
    ; Bank address
    mov dl, 15
    mov dh, 2
    call Gotoxy
    INVOKE printString, ADDR bankAddress
    
    ; Customer information - left side
    mov dl, 5
    mov dh, 5
    call Gotoxy
    mov esi, [account]
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi
    
    ; Statement information - right side
    mov dl, 50
    mov dh, 5
    call Gotoxy
    INVOKE printString, ADDR pageLabel
    
    mov dl, 65
    mov dh, 5
    call Gotoxy
    INVOKE printString, ADDR pageNum
    
    mov dl, 50
    mov dh, 7
    call Gotoxy
    INVOKE printString, ADDR statementDate
    
    mov dl, 65
    mov dh, 7
    call Gotoxy
    INVOKE printString, ADDR dateValue
    
    mov dl, 50
    mov dh, 8
    call Gotoxy
    INVOKE printString, ADDR accountLabel
    
    mov dl, 65
    mov dh, 8
    call Gotoxy
    mov esi, [account]
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi
    
    ; PIDM Notice and Account Type
    mov dl, 5
    mov dh, 10
    call Gotoxy
    INVOKE printString, ADDR pidmNotice
    
    mov dl, 65
    mov dh, 10
    call Gotoxy
    INVOKE printString, ADDR accountType
    
    ; Double line
    mov dl, 5
    mov dh, 11
    call Gotoxy
    INVOKE printString, ADDR doubleLine
    
    ; Account Transactions header
    mov dl, 40
    mov dh, 12
    call Gotoxy
    INVOKE printString, ADDR transHeader
    
    ; Double line
    mov dl, 5
    mov dh, 13
    call Gotoxy
    INVOKE printString, ADDR doubleLine
    
    ; Column headers
    mov dl, 5
    mov dh, 14
    call Gotoxy
    INVOKE printString, ADDR columnHeader1
    
    mov dl, 30
    mov dh, 14
    call Gotoxy
    INVOKE printString, ADDR columnHeader2
    
    mov dl, 55
    mov dh, 14
    call Gotoxy
    INVOKE printString, ADDR columnHeader3
    
    mov dl, 75
    mov dh, 14
    call Gotoxy
    INVOKE printString, ADDR columnHeader4
    
    ; Transaction Amount subheader
    mov dl, 55
    mov dh, 15
    call Gotoxy
    INVOKE printString, ADDR amountLabel
    
    ; Single line
    mov dl, 5
    mov dh, 16
    call Gotoxy
    INVOKE printString, ADDR singleLine
    
    ; Beginning balance
    mov dl, 30
    mov dh, 17
    call Gotoxy
    INVOKE printString, ADDR beginBalance
    
    ; Summary section
    mov dl, 20
    mov dh, 30
    call Gotoxy
    INVOKE printString, ADDR endingBalance
    
    ;mov dl, 65
    ;mov dh, 30
    ;call Gotoxy
    ;INVOKE printString, ADDR endBalValue

    ; Copy out the customer_id and store it into user account structure
     mov esi, [account]
     add esi, OFFSET userAccount.customer_id
     INVOKE Str_copy, esi, ADDR transaction.customer_id

    ; Transaction details
    INVOKE inputFromTransaction, ADDR transaction
    
    mov dl, 20
    mov dh, 31
    call Gotoxy
    INVOKE printString, ADDR totalCredit
    
    ;mov dl, 65
    ;mov dh, 31
    ;call Gotoxy
    ;INVOKE printString, ADDR creditValue
    
    mov dl, 20
    mov dh, 32
    call Gotoxy
    INVOKE printString, ADDR totalDebit
    
    ;mov dl, 65
    ;mov dh, 32
    ;call Gotoxy
    ;INVOKE printString, ADDR debitValue
    
    mov dl, 20
    mov dh, 33
    call Gotoxy
    INVOKE printString, ADDR avgExpenses
    
    mov dl, 20
    mov dh, 34
    call Gotoxy
    INVOKE printString, ADDR variance
    
    mov dl, 20
    mov dh, 35
    call Gotoxy
    INVOKE printString, ADDR stdDev
    
    ; Single line
    mov dl, 5
    mov dh, 36
    call Gotoxy
    INVOKE printString, ADDR singleLine

    ; Wait for user input
    call ReadChar
    STC
    
    ret
printMonthlyStatement ENDP

MSnote PROC
mov dl, 5
    mov dh, 37
    call Gotoxy
    INVOKE printString, ADDR note
    
    mov dl, 5
    mov dh, 38
    call Gotoxy
    INVOKE printString, ADDR note1
    
    mov dl, 5
    mov dh, 39
    call Gotoxy
    INVOKE printString, ADDR note2
    
    mov dl, 5
    mov dh, 40
    call Gotoxy
    INVOKE printString, ADDR note3
    
    ; Menu options
    mov dl, 5
    mov dh, 42
    call Gotoxy
    INVOKE printString, ADDR menuPrompt
    
    mov dl, 5
    mov dh, 43
    call Gotoxy
    INVOKE printString, ADDR menuOption1
    
    mov dl, 5
    mov dh, 44
    call Gotoxy
    INVOKE printString, ADDR menuOption2
    
    mov dl, 5
    mov dh, 45
    call Gotoxy
    INVOKE printString, ADDR menuOption3
    
    mov dl, 5
    mov dh, 47
    call Gotoxy
    INVOKE printString, ADDR menuNoNext
    
    mov dl, 5
    mov dh, 49
    call Gotoxy
    INVOKE printString, ADDR menuContinue

    ret
MSnote ENDP
END