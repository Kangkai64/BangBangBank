
INCLUDE BangBangBank.inc

;-------------------------------------------------------------
; This module will change the text color
; Receives : The color code (foreground + (background SHL 4))
; Returns : Nothing
; Last update: 15/3/2025
;-------------------------------------------------------------
.data

.code
setTxtColor PROC,
	colorCode: BYTE,
	colorMode: BYTE

	pushad

	.IF colorMode == CUSTOMMODE
		movzx eax, colorCode
		call SetTextColor
	.ELSEIF colorMode == DATEMODE
		mov eax, DATE_COLOR_CODE
		call SetTextColor
	.ELSEIF colorMode == INPUTMODE
		mov eax, INPUT_COLOR_CODE
		call SetTextColor
	.ELSE
		mov eax, DEFAULT_COLOR_CODE
		call SetTextColor
	.ENDIF

	popad
	ret
setTxtColor ENDP
END