section .data
    newA dq 0
    newB dq 0

section .text
    global _start

_start:
    mov rax, 50
    mov rbx, 100

    mov rcx, rax
    mov rax, rbx
    mov rbx, rcx

    mov [newA], rax
    mov [newB], rbx

    mov rax, 60
    mov rdi, 0
    syscall