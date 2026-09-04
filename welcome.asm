welcome BYTE "Welcome to CSM 254"
        BYTE "Programming with Assembly",CR,LF

.code
main PROC
; Clear the screen (call procedure Clrscr)
    call Clrscr

; Write a null-terminated string to standard output
    
    ; load effective address of welcome edx
    lea edx, welcome

    ; write string whoese address is in edx
    call WriteString
    
    exit
main ENDP
END main