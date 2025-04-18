TITLE  BangBangBank(.asm)

;------------------------------------------------------
; This is the banking system of the BangBangBank
; RSW1S3G2, Group 5
; Members : Ho Kang Kai
;			Lee Yong Kang
;			Poh Qi Xuan
;			Chew Xu Sheng
; Last update: 13/3/2025
;------------------------------------------------------

INCLUDE BangBangBank.inc

.data
titleStr	BYTE "Bang Bang Bank Application Program", 0
exitMessage BYTE NEWLINE, "Thank you for using Bang Bang Bank!", NEWLINE, 0

.code
main PROC
	INVOKE SetConsoleTitle, ADDR titleStr

	mainMenu:
		call displayMainMenu
		.IF CARRY?
			call clearConsole
		.ENDIF
		jc mainMenu

	call clearConsole
	INVOKE printString, ADDR exitMessage
	INVOKE displayLogo
	call Crlf
	exit
main ENDP
END main