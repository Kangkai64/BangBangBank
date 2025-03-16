.NOLIST

INCLUDE Irvine32.inc

NEWLINE TEXTEQU <0dh, 0ah>
maxBufferSize = 255

;-------------------------
; Date and Time Symbols
;-------------------------
YEAR = 1
MONTH = 2
DAY = 3 
WEEKDAY = 4
DATE = 5
TIME = 6

;----------------------------
; User Credential Structure
;----------------------------
userCredential STRUCT
	username BYTE 255 DUP(?)
	hashed_password BYTE 255 DUP(?)
	hashed_pin BYTE 32 DUP(?)
	customer_id BYTE 32 DUP(?)
	encryption_key BYTE 32 DUP(?)
	loginAttempt BYTE 16 DUP(?)
	firstLoginAttemptTimestamp BYTE 32 DUP(?)
userCredential ENDS

;----------------------------
; Customer Account Structure
;----------------------------
customerAccount STRUCT
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
customerAccount ENDS

;----------------------------
; Transaction Structure
;----------------------------
customerTransaction STRUCT
    transaction_id    BYTE 32 DUP(?)
    customer_id       BYTE 32 DUP(?)
    transaction_type  BYTE 32 DUP(?)
    amount            BYTE 32 DUP(?)
    date              BYTE 32 DUP(?)
    time              BYTE 32 DUP(?)
customerTransaction ENDS

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

StringToInt PROTO,
    pString: PTR BYTE

IntToString PROTO

formatUserData PROTO,
    userPtr:PTR userCredential,
    outputBuffer:PTR BYTE

parseCSVField PROTO

parseUserCredentials PROTO,
    user: PTR userCredential

Str_cat PROTO,
    sourceString : PTR BYTE,
    targetString : PTR BYTE

convertHexToString PROTO,
    source: PTR BYTE,
    destination: PTR BYTE,
    byteCount: DWORD

;-------------------------
; Procedure Prototype
;-------------------------
printString PROTO,
	textAddress: DWORD

displayMainMenu PROTO

promptForIntChoice PROTO,
    lowerBound: BYTE,
    upperBound: BYTE
	
getDateTimeComponent PROTO,
	timeOption: BYTE

Wait_Msg PROTO

setTxtColor PROTO,
	colorCode: BYTE

login PROTO

promptForUsername PROTO,
    inputUsernameAddress: PTR BYTE

promptForPassword PROTO,
    inputPasswordAddress: PTR BYTE

encrypt PROTO, 
	dataArray: PTR BYTE,
    keyArray: PTR BYTE

inputFromFile PROTO,
    user: PTR userCredential

outputToFile PROTO,
    userPtr:PTR userCredential

validateLoginTime PROTO,
    loginAttempt: PTR BYTE,
    firstLoginTimestamp: PTR BYTE

validatePassword PROTO,
    inputPassword: PTR BYTE,
    hashedPassword: PTR BYTE,
    encryptionKey: PTR BYTE

updateUserFile PROTO,
    user: PTR userCredential

readAccountFile PROTO,
    customerID: PTR BYTE,
    accountArray: PTR customerAccount,
    maxAccounts: DWORD

readTransactionFile PROTO,
    customerID: PTR BYTE,
    transactionArray: PTR customerTransaction,
    maxTransactions: DWORD

generateOTP PROTO,
    customerID: PTR BYTE

printUserCredentials PROTO, 
    user: PTR userCredential

switchAccount PROTO,
    user: PTR userCredential,
    customerID: PTR BYTE

.LIST