
INCLUDE BangBangBank.inc

;----------------------------------------------------------------------
; This module will print all user account that user can switch and
; switch the account based on user's choice
; Receives : User's current account structure
; Returns : User's account structure, either switched or unswitched
; Last update: 15/4/2025
;----------------------------------------------------------------------

.data
switchAccountHeader         BYTE NEWLINE, 
                                 "Available Account", NEWLINE, 
                                 "==============================", NEWLINE, 0
noOtherAccountMessage       BYTE NEWLINE, "You didn't have another account. Kindly register a new account", NEWLINE,
                                 "at your nearest Bang Bang Bank Branch.", NEWLINE, 0
promptPIN                   BYTE "Enter your PIN : ", 0
userVerifiedMsg             BYTE NEWLINE, "PIN verification successful! Transaction completed.", NEWLINE, 0
switchAccountSuccessMessage BYTE "Account switched successfully.", NEWLINE, 0
switchAccountFailedMessage  BYTE "PIN verification failed! Account switching is cancelled.", NEWLINE, 0

accountCount                DWORD 0
accountChoice               DWORD 0
exitCode                    BYTE "0",0
inputPIN                    BYTE 255 DUP(?)
accountBuffer               BYTE 100 DUP(0)  ; Buffer to store up to 10 account numbers (20 chars each)
accountPtrs                 DWORD 5 DUP(0)  ; Array of pointers to account numbers

.code
switchAccount PROC,
    account: PTR userAccount,
    user: PTR userCredential
    
    call clearConsole
    INVOKE printString, ADDR switchAccountHeader
    
    ; Initialize the pointers array
    mov ecx, 5                      ; Max 10 accounts
    mov edi, OFFSET accountBuffer
    mov ebx, OFFSET accountPtrs

initPtrArrayLoop:
    mov [ebx], edi                   ; Store pointer in array
    add ebx, 4                       ; Next pointer
    add edi, 20                      ; Next account slot (20 chars per account)
    loop initPtrArrayLoop
    
    INVOKE listAccount, account, ADDR accountBuffer
    mov accountCount, eax
    
    .IF eax < 2 ; Less than 2 accounts
        INVOKE printString, ADDR noOtherAccountMessage
        call Wait_Msg
        jmp switchAccountExit
    .ELSE
        movzx eax, al
        INVOKE promptForIntChoice, 1, al
        .IF CARRY? || al == exitCode
            jmp switchAccountExit
        .ELSE
            movzx eax, al
            mov accountChoice, eax

            validatePIN:
                mov esi, [user]
                add esi, OFFSET userCredential.hashed_pin
                mov ebx, esi
                mov esi, [user]
                add esi, OFFSET userCredential.encryption_key

                ; Prompt for user's PIN
	            INVOKE promptForPassword, ADDR inputPIN, ADDR promptPIN
                INVOKE validatePassword, ADDR inputPIN, ebx, esi
        
                .IF CARRY? ; Invalid PIN
                    INVOKE printString, ADDR switchAccountFailedMessage
                    call Wait_Msg
                .ELSE
                    INVOKE printString, ADDR userVerifiedMsg
                    INVOKE printString, ADDR switchAccountSuccessMessage
                    call Wait_Msg

                    ; Get the chosen account number from our array
                    mov eax, accountChoice
                    dec eax                 ; Convert from 1-based to 0-based index
                    shl eax, 2              ; Multiply by 4 for pointer array
                    mov edi, OFFSET accountPtrs
                    add edi, eax            ; Add offset to get pointer to account number string
                    mov ebx, [edi]          ; Get pointer to the chosen account number string
            
                    ; Copy the chosen account number into the structure
                    mov esi, account
                    add esi, OFFSET userAccount.account_number
                    INVOKE Str_copy, ebx, esi
            
                    ; Load the account details using the account number
                    INVOKE inputFromAccountByAccNo, account
                .ENDIF
        .ENDIF
    .ENDIF
    
switchAccountExit:
    STC ; Don't logout the user
    ret
switchAccount ENDP
END