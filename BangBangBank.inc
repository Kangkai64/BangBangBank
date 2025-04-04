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
    transaction_id    BYTE 32 DUP(?)
    customer_id       BYTE 32 DUP(?)
    transaction_type  BYTE 32 DUP(?)
    amount            BYTE 32 DUP(?)
    balance           BYTE 32 DUP(?)
    transaction_detail BYTE 255 DUP(?)
    date              BYTE 32 DUP(?)
    time              BYTE 32 DUP(?)
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

;-------------------------
; Procedure Prototype
;-------------------------
printString PROTO,
	textAddress: DWORD

displayMainMenu PROTO

promptForIntChoice PROTO,
    lowerBound: BYTE,
    upperBound: BYTE

Wait_Msg PROTO

setTxtColor PROTO,
    colorCode: BYTE,
	colorMode: BYTE

login PROTO

aboutUs PROTO

processTransaction PROTO,
    account: PTR userAccount

promptForTransactionAmount PROTO \
    inputTransactionAmountAddress: PTR BYTE, \
    account: PTR userAccount

promptForRecipientAccNo PROTO,
    inputRecipientAccNoAddress: PTR BYTE

displayCustomerMenu PROTO,
    user: PTR userCredential

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

validateRecipientAcc PROTO,
    Account: PTR userAccount

inputFromTransaction PROTO,
    transaction: PTR userTransaction

validateLoginTime PROTO,
    user: PTR userCredential

validatePassword PROTO,
    inputPassword: PTR BYTE,
    hashedPassword: PTR BYTE,
    encryptionKey: PTR BYTE

updateUserFile PROTO,
    user: PTR userCredential

resetLoginAttempt PROTO,
    user: PTR userCredential

printUserCredentials PROTO, 
    user: PTR userCredential

printUserAccount PROTO, 
    account: PTR userAccount, printMode: DWORD

printUserTransaction PROTO, 
    transaction: PTR userTransaction


;-------------------------
; colorMode values
;-------------------------
DATE               EQU 1
INPUT              EQU 2
CUSTOM             EQU 9
DEFAULT_COLOR_CODE EQU 07h ; White foreground and black background
DATE_COLOR_CODE    EQU (yellow + (black SHL 4))
INPUT_COLOR_CODE   EQU (lightGreen + (black SHL 4))

;-------------------------
; pritnMode values
;-------------------------
PRINTMODE_ALL               EQU 0
PRINTMODE_ACCOUNT_NUMBER    EQU 1
PRINTMODE_FULLNAME          EQU 2
PRINTMODE_BALANCE           EQU 3

switchAccount PROTO

changeCredentials PROTO

printMonthlyStatement PROTO,
	account: PTR userAccount

MSnote PROTO

.LIST