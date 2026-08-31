section .data
    name db 'Zara Ali'
    lenName equ $-name
    newName db 'Nuha Ali'
    nl db 0xa

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, lenName
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, nl
    mov edx, 1
    int 0x80

    mov esi, newName
    mov edi, name
    mov ecx, lenName
copyLoop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop copyLoop

    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, lenName
    int 0x80

    mov eax, 1
    mov ebx, 0
    int 0x80