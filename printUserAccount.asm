
INCLUDE BangBangBank.inc

;----------------------------------------------------------------------
; This module will print all user account information onto the console
; Receives : The address / pointer of the user account structure
; Returns : Nothing
; Last update: 23/3/2025
;----------------------------------------------------------------------
.data
; Labels for each field
accountNumberLabel    BYTE "Account Number: ", 0
customerIdLabel       BYTE "Customer ID: ", 0
fullNameLabel         BYTE "Full Name: ", 0
phoneNumberLabel      BYTE "Phone Number: ", 0
emailLabel            BYTE "Email: ", 0
accountBalanceLabel   BYTE "Account Balance: RM ", 0
openingDateLabel      BYTE "Opening Date: ", 0
transactionLimitLabel BYTE "Transaction Limit: RM ", 0
branchNameLabel       BYTE "Branch Name: ", 0
branchAddressLabel    BYTE "Branch Address: ", 0
accountTypeLabel      BYTE "Account Type: ", 0
currencyLabel         BYTE "Currency: ", 0
beneficiariesLabel    BYTE "Beneficiaries: ", 0

.code
printUserAccount PROC, 
    account: PTR userAccount,
    printMode: DWORD ; Decide print what info

    pushad

    cmp printMode, 1
    je print_account_number

    cmp printMode, 2
    je print_full_name

    jmp print_all

print_account_number:

    ; Print account number
    INVOKE printString, ADDR accountNumberLabel
    mov esi, account
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi

    jmp done

print_full_name: 
    
    ; Print full name
    mov esi, account
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi

    jmp done
    
print_all: 

    ; Print account number
    INVOKE printString, ADDR accountNumberLabel
    mov esi, account
    add esi, OFFSET userAccount.account_number
    INVOKE printString, esi
    call Crlf

    ; Print customer ID
    INVOKE printString, ADDR customerIdLabel
    mov esi, account
    add esi, OFFSET userAccount.customer_id
    INVOKE printString, esi
    call Crlf
    
    ; Print full name
    INVOKE printString, ADDR fullNameLabel
    mov esi, account
    add esi, OFFSET userAccount.full_name
    INVOKE printString, esi
    call Crlf
    
    ; Print phone number
    INVOKE printString, ADDR phoneNumberLabel
    mov esi, account
    add esi, OFFSET userAccount.phone_number
    INVOKE printString, esi
    call Crlf
    
    ; Print email
    INVOKE printString, ADDR emailLabel
    mov esi, account
    add esi, OFFSET userAccount.email
    INVOKE printString, esi
    call Crlf
    
    ; Print account balance
    INVOKE printString, ADDR accountBalanceLabel
    mov esi, account
    add esi, OFFSET userAccount.account_balance
    INVOKE printString, esi
    call Crlf
    
    ; Print opening date
    INVOKE printString, ADDR openingDateLabel
    mov esi, account
    add esi, OFFSET userAccount.opening_date
    INVOKE printString, esi
    call Crlf
    
    ; Print transaction limit
    INVOKE printString, ADDR transactionLimitLabel
    mov esi, account
    add esi, OFFSET userAccount.transaction_limit
    INVOKE printString, esi
    call Crlf
    
    ; Print branch name
    INVOKE printString, ADDR branchNameLabel
    mov esi, account
    add esi, OFFSET userAccount.branch_name
    INVOKE printString, esi
    call Crlf
    
    ; Print branch address
    INVOKE printString, ADDR branchAddressLabel
    mov esi, account
    add esi, OFFSET userAccount.branch_address
    INVOKE printString, esi
    call Crlf
    
    ; Print account type
    INVOKE printString, ADDR accountTypeLabel
    mov esi, account
    add esi, OFFSET userAccount.account_type
    INVOKE printString, esi
    call Crlf
    
    ; Print currency
    INVOKE printString, ADDR currencyLabel
    mov esi, account
    add esi, OFFSET userAccount.currency
    INVOKE printString, esi
    call Crlf
    
    ; Print beneficiaries
    INVOKE printString, ADDR beneficiariesLabel
    mov esi, account
    add esi, OFFSET userAccount.beneficiaries
    INVOKE printString, esi
    call Crlf

done:    
    popad
    ret
printUserAccount ENDP
END