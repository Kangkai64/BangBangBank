
INCLUDE Irvine32.inc

NEWLINE TEXTEQU <0dh, 0ah>

;-------------------------
; Boolean Symbols
;-------------------------
TRUE = 1
FALSE = 0

;-------------------------
; Date and Time Symbols
;-------------------------
YEAR = 1
MONTH = 2
DAY = 3 
WEEKDAY = 4
DATE = 5
TIME = 6

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

myWait PROTO