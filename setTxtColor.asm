
INCLUDE BangBangBank.inc

;-------------------------------------------------------------
; This module will change the text color
; Receives : The color code (foreground + (background SHL 4))
; Returns : Nothing
; Last update: 15/3/2025
;-------------------------------------------------------------

.code
setTxtColor PROC,
	colorCode: BYTE

	pushad

	movzx eax, colorCode
	call SetTextColor

	popad
	ret
setTxtColor ENDP
END