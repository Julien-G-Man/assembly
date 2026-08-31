; =====================================================
; UTILITY BILLING SYSTEM  --  32-bit x86 version
; NASM, Linux int 0x80 syscalls
; Group 3
;
; BUILD:
;   nasm -f elf32 billing32.asm -o billing32.o
;   ld -m elf_i386 billing32.o -o billing32
;   ./billing32
; =====================================================

section .bss
    MAX_CUSTOMERS   equ 20
    NAME_LEN        equ 20
    RECORD_SIZE     equ 32          ; 20 name + 4 prev + 4 curr + 4 bill

    customers       resb MAX_CUSTOMERS * RECORD_SIZE
    customer_count  resd 1
    view_index      resd 1

    input_buf       resb 64
    num_str_buf     resb 24

section .data
    menu_txt        db 10,"===== UTILITY BILLING SYSTEM =====",10
                     db "1. Add customer reading",10
                     db "2. View all bills",10
                     db "3. Exit",10
                     db "Choose an option: ",0
    menu_len        equ $ - menu_txt - 1

    prompt_name     db "Customer name: ",0
    prompt_name_len equ $ - prompt_name - 1

    prompt_prev     db "Previous meter reading: ",0
    prompt_prev_len equ $ - prompt_prev - 1

    prompt_curr     db "Current meter reading: ",0
    prompt_curr_len equ $ - prompt_curr - 1

    err_curr_lt_prev db "Error: current reading cannot be less than previous.",10,0
    err_curr_lt_prev_len equ $ - err_curr_lt_prev - 1

    err_full        db "Customer list is full.",10,0
    err_full_len    equ $ - err_full - 1

    added_msg       db "Customer added and bill calculated.",10,0
    added_msg_len   equ $ - added_msg - 1

    no_customers    db "No customers stored yet.",10,0
    no_customers_len equ $ - no_customers - 1

    hdr_txt         db 10,"---- Billing Report ----",10,0
    hdr_len         equ $ - hdr_txt - 1

    lbl_name        db "Name: ",0
    lbl_name_len    equ $ - lbl_name - 1

    lbl_usage       db "  Usage: ",0
    lbl_usage_len   equ $ - lbl_usage - 1

    lbl_bill        db "  Amount due: GHS ",0
    lbl_bill_len    equ $ - lbl_bill - 1

    newline         db 10

    invalid_opt     db "Invalid option, try again.",10,0
    invalid_opt_len equ $ - invalid_opt - 1

section .text
    global _start

; =====================================================
; ENTRY POINT
; =====================================================
_start:
    mov dword [customer_count], 0

main_loop:
    mov eax, 4                    ; sys_write
    mov ebx, 1
    mov ecx, menu_txt
    mov edx, menu_len
    int 0x80

    call read_line
    call str_to_int               ; eax = choice

    cmp eax, 1
    je do_add
    cmp eax, 2
    je do_view
    cmp eax, 3
    je do_exit

    mov eax, 4
    mov ebx, 1
    mov ecx, invalid_opt
    mov edx, invalid_opt_len
    int 0x80
    jmp main_loop

; -----------------------------------------------------
; OPTION 1: add a customer
; -----------------------------------------------------
do_add:
    mov eax, [customer_count]
    cmp eax, MAX_CUSTOMERS
    jl add_has_space

    mov eax, 4
    mov ebx, 1
    mov ecx, err_full
    mov edx, err_full_len
    int 0x80
    jmp main_loop

add_has_space:
    mov eax, [customer_count]
    imul eax, RECORD_SIZE
    lea esi, [customers + eax]    ; esi = this record (kept across calls)

    ; ---- name ----
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_name
    mov edx, prompt_name_len
    int 0x80

    call read_line                ; input_buf = name, no newline, null terminated
    mov edi, input_buf
    mov edx, esi                  ; edx = destination cursor
    mov ecx, NAME_LEN - 1
copy_name:
    mov al, [edi]
    cmp al, 0
    je copy_name_done
    mov [edx], al
    inc edi
    inc edx
    loop copy_name
copy_name_done:
    mov byte [edx], 0

    ; ---- previous reading ----
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_prev
    mov edx, prompt_prev_len
    int 0x80

    call read_line
    call str_to_int                ; eax = previous reading
    mov [esi + NAME_LEN], eax      ; store prev

    ; ---- current reading ----
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_curr
    mov edx, prompt_curr_len
    int 0x80

    call read_line
    call str_to_int                 ; eax = current reading
    mov ebx, [esi + NAME_LEN]       ; ebx = prev
    cmp eax, ebx
    jge curr_ok

    mov eax, 4
    mov ebx, 1
    mov ecx, err_curr_lt_prev
    mov edx, err_curr_lt_prev_len
    int 0x80
    jmp main_loop

curr_ok:
    mov [esi + NAME_LEN + 4], eax   ; store curr

    mov eax, [esi + NAME_LEN + 4]
    sub eax, [esi + NAME_LEN]       ; eax = usage

    call calculate_bill             ; in: eax = usage -> out: eax = bill
    mov [esi + NAME_LEN + 8], eax   ; store bill

    inc dword [customer_count]

    mov eax, 4
    mov ebx, 1
    mov ecx, added_msg
    mov edx, added_msg_len
    int 0x80
    jmp main_loop

; -----------------------------------------------------
; OPTION 2: view all bills
; -----------------------------------------------------
do_view:
    mov eax, [customer_count]
    cmp eax, 0
    jne view_has_data

    mov eax, 4
    mov ebx, 1
    mov ecx, no_customers
    mov edx, no_customers_len
    int 0x80
    jmp main_loop

view_has_data:
    mov eax, 4
    mov ebx, 1
    mov ecx, hdr_txt
    mov edx, hdr_len
    int 0x80

    mov dword [view_index], 0
view_loop:
    mov eax, [view_index]
    cmp eax, [customer_count]
    jge view_done

    imul eax, RECORD_SIZE
    lea esi, [customers + eax]     ; esi = this record

    mov eax, 4
    mov ebx, 1
    mov ecx, lbl_name
    mov edx, lbl_name_len
    int 0x80

    ; print the name: scan for its null terminator to get the length
    mov edi, esi
    xor edx, edx
name_len_loop:
    cmp byte [edi + edx], 0
    je name_len_done
    inc edx
    jmp name_len_loop
name_len_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, esi                   ; buffer = the name itself
    int 0x80                       ; edx already holds the length

    mov eax, 4
    mov ebx, 1
    mov ecx, lbl_usage
    mov edx, lbl_usage_len
    int 0x80

    mov eax, [esi + NAME_LEN + 4]
    sub eax, [esi + NAME_LEN]
    call print_int

    mov eax, 4
    mov ebx, 1
    mov ecx, lbl_bill
    mov edx, lbl_bill_len
    int 0x80

    mov eax, [esi + NAME_LEN + 8]
    call print_int

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    inc dword [view_index]
    jmp view_loop

view_done:
    jmp main_loop

; -----------------------------------------------------
; EXIT
; -----------------------------------------------------
do_exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =====================================================
; FUNCTION: calculate_bill
;   in:  eax = usage
;   out: eax = bill amount
;   Tier 1: first 50 units @ 5
;   Tier 2: next 100 units @ 8
;   Tier 3: remaining units @ 12
; =====================================================
calculate_bill:
    push ebx
    push ecx
    push edx
    mov ebx, eax                  ; ebx = remaining usage
    xor ecx, ecx                  ; ecx = running total

    cmp ebx, 0
    jle calc_done

    mov edx, ebx
    cmp edx, 50
    jle t1_all
    mov edx, 50
t1_all:
    imul eax, edx, 5
    add ecx, eax
    sub ebx, edx
    cmp ebx, 0
    jle calc_done

    mov edx, ebx
    cmp edx, 100
    jle t2_all
    mov edx, 100
t2_all:
    imul eax, edx, 8
    add ecx, eax
    sub ebx, edx
    cmp ebx, 0
    jle calc_done

    imul eax, ebx, 12
    add ecx, eax

calc_done:
    mov eax, ecx
    pop edx
    pop ecx
    pop ebx
    ret

; =====================================================
; FUNCTION: read_line
;   Reads a line from stdin into input_buf, one byte at a
;   time (Linux read does NOT stop at newline like fgets),
;   stops at '\n' (discarded) or buffer full. Null-terminated.
;   Saves/restores every register it touches so callers can
;   safely keep state (like esi = record pointer) across the
;   call.
; =====================================================
read_line:
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov edi, input_buf
    mov ecx, 64
    xor al, al
    rep stosb                     ; clear buffer

    xor edi, edi                  ; edi = bytes stored so far
rl_byte_loop:
    cmp edi, 62
    jge rl_done

    mov eax, 3                    ; sys_read
    mov ebx, 0                    ; stdin
    lea ecx, [input_buf + edi]
    mov edx, 1
    int 0x80

    cmp eax, 0
    jle rl_done

    movzx edx, byte [input_buf + edi]
    cmp edx, 10                   ; '\n' ?
    je rl_done

    inc edi
    jmp rl_byte_loop

rl_done:
    mov byte [input_buf + edi], 0

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; =====================================================
; FUNCTION: str_to_int
;   in:  input_buf (ascii digits)
;   out: eax = integer value
; =====================================================
str_to_int:
    push esi
    push ecx
    xor eax, eax
    mov esi, input_buf
s2i_loop:
    movzx ecx, byte [esi]
    cmp ecx, '0'
    jl s2i_done
    cmp ecx, '9'
    jg s2i_done
    sub ecx, '0'
    imul eax, eax, 10
    add eax, ecx
    inc esi
    jmp s2i_loop
s2i_done:
    pop ecx
    pop esi
    ret

; =====================================================
; FUNCTION: print_int
;   Prints the integer in eax to stdout, no newline.
; =====================================================
print_int:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov esi, eax                  ; keep the value safe from the div below
    lea edi, [num_str_buf + 23]
    mov byte [edi], 0
    mov ebx, 10
    xor ecx, ecx                  ; digit counter

    mov eax, esi
    cmp eax, 0
    jne i2s_convert
    dec edi
    mov byte [edi], '0'
    inc ecx
    jmp i2s_print

i2s_convert:
    cmp eax, 0
    je i2s_print
    xor edx, edx
    div ebx                       ; eax = eax/10, edx = remainder
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx
    jmp i2s_convert

i2s_print:
    mov edx, ecx                  ; length
    mov ecx, edi                  ; buffer pointer
    mov ebx, 1                    ; stdout
    mov eax, 4                    ; sys_write
    int 0x80

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
