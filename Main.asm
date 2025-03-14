TITLE  BangBangBank(.asm)

; This is the banking system of the BangBangBank
; RSW1S3G2, Group 5
; Members : Ho Kang Kai
;			Lee Yong Kang
;			Poh Qi Xuan
;			Chew Xu Sheng
; Last update: 13/3/2025

INCLUDE BangBangBank.inc

.data


.code
main PROC
	
	mainMenu:
		call displayMainMenu
		jc mainMenu
		; Test if it can go out of the loop
		call Crlf
		call Crlf
		call WaitMsg

	exit
main ENDP
END main