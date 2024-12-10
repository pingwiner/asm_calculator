.MODEL tiny

.CODE
.8086
org 100h

STATE_ROOT   equ    0
STATE_NUMBER equ    1
TOKEN_NUMBER equ    '@'

start:
    mov di, offset tokens
    cld

read_char:
    mov ah, 01h
    int 21h         ; Input char from stdin
    cmp al, 0dh     ; Enter ?
    je process_expr ; Process expression
    call proc_char  ; Else process char
    jmp read_char

process_expr:
    call proc_char   ; Process last char
    cmp prev_token, TOKEN_NUMBER
    je expression_correct
    dec di           ; Ignore trailing operator
expression_correct:
    xor al, al
    stosb            ; Zero token marks end of expr
    call calculate
    jmp print_result ; Then print result and exit

calculate:
    mov si, offset tokens
next_token:
    lodsb
    test al, al
    jnz not_final_token
    mov ax, bx      ; Return result of calculation
    ret
not_final_token:
    cmp al, TOKEN_NUMBER
    jne operator_token
    lodsw           ; load number
    mov bx, ax      ; Save left operand
    jmp next_token
operator_token:
    mov cl, al      ; Operator to cl
    lodsb           ; Read token
    lodsw           ; Read operand value
    call operation
    mov bx, ax      ; Result became left operand for next operation
    jmp next_token

operation:
    xchg ax, bx     ; Left operand in bx, right in ax, need to swap
    cmp cl, '+'
    je process_add
    cmp cl, '-'
    je process_sub
    cmp cl, '*'
    je process_mul
    cmp cl, '/'
    je process_div
    ret

process_add:
    add ax, bx
    ret

process_sub:
    sub ax, bx
    ret

process_mul:
    imul bx
    ret

process_div:
    xor dx, dx
    idiv bx
    ret

proc_char:
    cmp state, STATE_NUMBER ; Check current state
    jne proc_root_state

proc_number_state:          ; User entering number
    call is_digit           ; Check if char is a digit
    jnc save_number         ; if not - save current number
    xor bx, bx
    sub al, 30h             ; Convert char to int
    mov bl, al
    mov ax, current_number  ; Load current number value
    xor dx, dx
    mov cx, 0ah
    imul cx                 ; Multiply current value to 10
    add ax, bx              ; Add last entered digit
    mov current_number, ax  ; Save result
    ret
save_number:
    cmp unary_minus, 1      ; If previous token was unary minus
    jne positive_number
    neg current_number      ; Invert sign
    mov unary_minus, 0      ; Clear flag of unary minus
positive_number:
    mov bl, al
    call push_number_token  ; Push current number as a token
    mov state, STATE_ROOT
    mov al, bl
    jmp proc_operator

proc_root_state:
    call is_digit
    jnc proc_operator
    inc state               ; state = STATE_NUMBER
    xor bx, bx
    sub al, 30h
    mov bl, al
    mov current_number, bx
    ret

proc_operator:
    cmp al, '+'
    je valid_operator
    cmp al, '-'
    je valid_operator
    cmp al, '*'
    je valid_operator
    cmp al, '/'
    je valid_operator
    ret
valid_operator:
    call push_operator_token
    ret

is_digit:
    cmp al, 30h
    jl not_digit
    cmp al, 39h
    jg not_digit
    stc
    ret
not_digit:
    clc
    ret

push_operator_token:
    cmp prev_token, TOKEN_NUMBER
    jne process_unary_minus
    stosb
    mov prev_token, al
    ret
process_unary_minus:
    cmp al, '-'
    jne error
    xor unary_minus, 1        ; Invert flag of unary minus
    ret

push_number_token:
    mov al, TOKEN_NUMBER
    stosb
    mov prev_token, al
    mov ax, current_number
    stosw
    ret

error:
    mov dx, offset error_msg
    mov ah, 09h
    int 21h
    jmp exit

print_result:
    test ax, 8000h
    jz positive
    neg ax
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax
positive:
    mov bx, 0ah
    xor cx, cx
print_step:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz print_step
print_out:
    pop dx
    add dl, 30h
    mov ah, 02h
    int 21h
    loop print_out

exit:
    mov ax, 4c00h
    int 21h

state           db STATE_ROOT
prev_token      db ' '
unary_minus     db 0
error_msg       db 13, 10, "Error$"
current_number  dw ?
tokens:

END start
