.NOLIST

INCLUDE Irvine32.inc

NEWLINE TEXTEQU <0dh, 0ah>
maxBufferSize = 255

;----------------------------
; User Credential Structure
;----------------------------
userCredential STRUCT
	username BYTE 255 DUP(?)
	hashed_password BYTE 255 DUP(?)
	hashed_pin BYTE 32 DUP(?)
	customer_id BYTE 32 DUP(?)
	encryption_key BYTE 32 DUP(?)
	loginAttempt BYTE 4 DUP(?)
	firstLoginAttemptTimestamp BYTE 32 DUP(?)
userCredential ENDS

;----------------------------
; Customer Account Structure
;----------------------------
userAccount STRUCT
    account_number    BYTE 32 DUP(?)
    customer_id       BYTE 32 DUP(?)
    full_name         BYTE 64 DUP(?)
    phone_number      BYTE 32 DUP(?)
    email             BYTE 64 DUP(?)
    account_balance   BYTE 32 DUP(?)
    opening_date      BYTE 32 DUP(?)
    transaction_limit BYTE 32 DUP(?)
    branch_name       BYTE 64 DUP(?)
    branch_address    BYTE 128 DUP(?)
    account_type      BYTE 32 DUP(?)
    currency          BYTE 16 DUP(?)
    beneficiaries     BYTE 255 DUP(?)
userAccount ENDS

;----------------------------
; Transaction Structure
;----------------------------
userTransaction STRUCT
    transaction_id              BYTE 32 DUP(?)
    customer_id                 BYTE 32 DUP(?)
    sender_account_number       BYTE 32 DUP(?)
    transaction_type            BYTE 32 DUP(?)
    recipient_id                BYTE 32 DUP(?)
    recipient_account_number    BYTE 32 DUP(?)
    amount                      BYTE 32 DUP(?)
    balance                     BYTE 32 DUP(?)
    transaction_detail          BYTE 255 DUP(?)
    date                        BYTE 32 DUP(?)
    time                        BYTE 32 DUP(?)
userTransaction ENDS

;-------------------------------------------
; File Function Prototype from kernel32.inc
;-------------------------------------------
CreateDirectoryA PROTO STDCALL :DWORD,:DWORD
IFNDEF __UNICODE__
  CreateDirectory equ <CreateDirectoryA>
ENDIF

MoveFileA PROTO STDCALL :DWORD,:DWORD
IFNDEF __UNICODE__
  MoveFile equ <MoveFileA>
ENDIF

DeleteFileA PROTO STDCALL :DWORD
IFNDEF __UNICODE__
  DeleteFile equ <DeleteFileA>
ENDIF

;-----------------------------
; Symbols from windows.inc
;-----------------------------
ERROR_ALREADY_EXISTS equ 183

;-----------------------------
; Helper Function Prototype
;-----------------------------
formatSystemTime PROTO,
    systemTimePtr:PTR SYSTEMTIME,
    outputBuffer:PTR BYTE

checkLeapYear PROTO

calculateDateTime PROTO

clearUserCredential PROTO,
    pUser:PTR userCredential

StringToInt PROTO,
    pString: PTR BYTE

IntToString PROTO

StringToDecimal PROTO,
    pString: PTR BYTE

WriteDecimalNumber PROTO

formatUserData PROTO,
    userPtr:PTR userCredential,
    outputBuffer:PTR BYTE

parseCSVField PROTO

parseUserCredentials PROTO,
    user: PTR userCredential

parseUserAccount PROTO,
    account: PTR userAccount

parseUserTransaction PROTO,
    transaction : PTR userTransaction

convertHexToString PROTO,
    source: PTR BYTE,
    destination: PTR BYTE,
    byteCount: DWORD

Str_cat PROTO,
    sourceString : PTR BYTE,
    targetString : PTR BYTE

myStr_trim PROTO,
    pString:PTR BYTE,
    char: BYTE

DwordToStr PROTO,
    dwordVal: DWORD,
    stringVal: PTR BYTE

Str_find PROTO,
    sourceStr: PTR BYTE,
    subString: PTR BYTE

validateDecimalInput PROTO,
    inputAddress: PTR BYTE

removeDecimalPoint PROTO,
    sourceStr: PTR BYTE,
    destStr: PTR BYTE

addDecimalPoint PROTO,
    sourceStr: PTR BYTE,
    destStr: PTR BYTE

processTransactionAmount PROTO,
    transactionAmount: PTR BYTE,
    formattedAmount: PTR BYTE

decimalArithmetic PROTO,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE,
    operation: BYTE

decimalMultiply PROTO,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE

decimalDivide PROTO,
    num1: PTR BYTE,
    num2: PTR BYTE,
    result: PTR BYTE

str_initZero PROTO,
    pBuffer: PTR BYTE

;-------------------------
; Procedure Prototype
;-------------------------
printString PROTO,
	textAddress: DWORD

displayLogo PROTO

displayMainMenu PROTO

promptForIntChoice PROTO,
    lowerBound: BYTE,
    upperBound: BYTE

Wait_Msg PROTO

setTxtColor PROTO,
    colorCode: BYTE,
	colorMode: BYTE

;-------------------------
; colorMode values
;-------------------------
DATE               EQU 1
LOGO               EQU 2
INPUT              EQU 3
CUSTOM             EQU 9
DEFAULT_COLOR_CODE EQU 07h ; White foreground and black background
DATE_COLOR_CODE    EQU (yellow + (black SHL 4))
LOGO_COLOR_CODE    EQU (lightblue + (black SHL 4))
INPUT_COLOR_CODE   EQU (lightGreen + (black SHL 4))

login PROTO

aboutUs PROTO

processTransaction PROTO,
    account: PTR userAccount

promptForTransactionAmount PROTO,
    inputTransactionAmountAddress: PTR BYTE,
    account: PTR userAccount

promptForTransactionDetail PROTO,
    inputTransactionDetailAddress: PTR BYTE

promptForRecipientAccNo PROTO,
    inputRecipientAccNoAddress: PTR BYTE

displayCustomerMenu PROTO,
    user: PTR userCredential

parseOpeningDate PROTO,
    account: PTR userAccount

parseCurrentDate PROTO,
    account: PTR userAccount

checkInterest PROTO,
    account: PTR userAccount

promptForUsername PROTO,
    inputUsernameAddress: PTR BYTE

promptForPassword PROTO,
    inputPasswordAddress: PTR BYTE, 
    promptMessageAddress: PTR BYTE

encrypt PROTO, 
	dataArray: PTR BYTE,
    keyArray: PTR BYTE

inputFromFile PROTO,
    user: PTR userCredential

inputFromAccount PROTO,
    account: PTR userAccount

inputFromAccountByAccNo PROTO,
    recipientAccount: PTR userAccount

validateRecipientAcc PROTO,
    Account: PTR userAccount

inputFromTransaction PROTO,
    transaction: PTR userTransaction

inputTotalTransactionFromTransaction PROTO,
    transaction: PTR userTransaction,
    timeDate: PTR BYTE,
    dailyTotalTransaction: PTR BYTE

validateLoginTime PROTO,
    user: PTR userCredential

validatePassword PROTO,
    inputPassword: PTR BYTE,
    hashedPassword: PTR BYTE,
    encryptionKey: PTR BYTE

changePassword PROTO,
    user: PTR userCredential

validatePasswordComplexity PROTO, 
    pPassword:PTR BYTE

validateTransactionAmount PROTO,
    inputTransactionAmountAddress: PTR BYTE,
    account: PTR userAccount

updateFile PROTO,
    fileType:DWORD,
    recordPtr:PTR BYTE,
    keyFieldOffset:DWORD

updateUserFile PROTO,
    user: PTR userCredential

updateUserAccountFile PROTO,
    account: PTR userAccount

updateTransactionLog PROTO,
    transaction: PTR userTransaction

insertTransaction PROTO,
    transaction: PTR userTransaction

resetLoginAttempt PROTO,
    user: PTR userCredential

printUserCredentials PROTO, 
    user: PTR userCredential

printUserAccount PROTO, 
    account: PTR userAccount, printMode: DWORD

;-------------------------
; printMode values
;-------------------------
PRINTMODE_ALL               EQU 0
PRINTMODE_ACCOUNT_NUMBER    EQU 1
PRINTMODE_FULLNAME          EQU 2
PRINTMODE_BALANCE           EQU 3

printUserTransaction PROTO, 
    transaction: PTR userTransaction

generateOTP PROTO,
    account: PTR userAccount

generateTransactionID PROTO,
    transIDBuffer: PTR BYTE

verifyOTP PROTO,
    generatedOTP: PTR BYTE 

processDeposit PROTO,
    account: PTR userAccount

switchAccount PROTO

printMonthlyStatement PROTO,
	account: PTR userAccount

MSnote PROTO

calculateTotalCredit PROTO, 
    transaction: PTR userTransaction

calculateTotalDebit PROTO, 
    transaction: PTR userTransaction

calculateAverageBalance PROTO, 
    transaction: PTR userTransaction

calculateDailyAverageBalance PROTO, 
    transaction: PTR userTransaction

printTotal PROTO
.LIST