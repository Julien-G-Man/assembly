section .data
    msg1 db 'Enter first number: '
    len1 equ $-msg1

    msg2 db 'Enter second number: '
    len2 equ $-msg2

    sumMsg db 10, 'Sum: '
    lenSum equ $-sumMsg

    diffMsg db 10, 'Difference: '
    lenDiff equ $-diffMsg

    nl db 10

section .bss
    num1Input resb 16
    num2Input resb 16
    num1Value resd 1
    num2Value resd 1
    sumResult resd 1
    diffResult resd 1
    outBuffer resb 16

section .text
    global _start

_start:
    mov ecx, msg1
    mov edx, len1
    call print

    mov ecx, num1Input
    mov edx, 16
    call read

    mov esi, num1Input
    call parse_number
    mov [num1Value], eax

    mov ecx, msg2
    mov edx, len2
    call print

    mov ecx, num2Input
    mov edx, 16
    call read

    mov esi, num2Input
    call parse_number
    mov [num2Value], eax

    mov eax, [num1Value]
    add eax, [num2Value]
    mov [sumResult], eax

    mov eax, [num1Value]
    sub eax, [num2Value]
    mov [diffResult], eax

    mov ecx, sumMsg
    mov edx, lenSum
    call print

    mov eax, [sumResult]
    call print_number

    mov ecx, diffMsg
    mov edx, lenDiff
    call print

    mov eax, [diffResult]
    call print_number

    mov ecx, nl
    mov edx, 1
    call print

    mov eax, 1
    mov ebx, 0
    int 0x80

print:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

read:
    mov eax, 3
    mov ebx, 0
    int 0x80
    ret

parse_number:
    xor eax, eax
.next_digit:
    movzx edx, byte [esi]
    cmp edx, '0'
    jb .done
    cmp edx, '9'
    ja .done
    imul eax, eax, 10
    sub edx, '0'
    add eax, edx
    inc esi
    jmp .next_digit
.done:
    ret

print_number:
    cmp eax, 0
    jge .positive

    push eax
    mov byte [outBuffer], '-'
    mov ecx, outBuffer
    mov edx, 1
    call print
    pop eax
    neg eax

.positive:
    mov edi, outBuffer + 15
    mov byte [edi], 0
    mov ebx, 10

    cmp eax, 0
    jne .convert
    dec edi
    mov byte [edi], '0'
    jmp .write_number

.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .convert

.write_number:
    mov ecx, edi
    mov edx, outBuffer + 15
    sub edx, edi
    call print
    ret
