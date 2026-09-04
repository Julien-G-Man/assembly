.global _start
.intel_syntax noprefix

_start:
    mov eax, A
    mul eax, B
    add eax, 10
    mov D, eax