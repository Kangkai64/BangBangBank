
INCLUDE Irvine32.inc

.code
printString PROC,
    textAddress: PTR BYTE

    pushad

    mov edx, textAddress
    call WriteString

    popad
    ret
printString ENDP
END