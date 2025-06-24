.model small
.data
MAX_DIM equ 5                   ;  Максимальний розмір масиву
INT_MIN equ -32768              ;  Мінімально допустиме значення

input_buffer db 7, ?, 7 dup("$")
input_ptr dw 0
input_len dw ?

array dd MAX_DIM dup(MAX_DIM dup(?)) ;  Двовимірний масив [5][5]
array_size dw 0
height dw 0
width_size dw 0

inp dd 0
num dd 0
is_negstive db 0
curr dw 0
elem dd 0


enter_height db "Enter array height, max 5: $"
enter_width db "Enter array width, max 5: $"
bad_height db "ERROR. Height size must be between 1 and 5$"       
bad_width db "ERROR. Width size must be between 1 and 5$"         
bad_limit db "ERROR. Element size must be between -32768 and 65535$"
bad_char db "ERROR. Not correct numeric format$"                 
enter_element db "Enter element between -32768 and 65535 ($"
output_array db "Entered array:$"
change_index db "Enter element which you find:$"
none_ db "Nothing found$"

.stack 100h
.code
.386

main proc
    mov ax, @data
    mov ds, ax
    lea bx, input_buffer
    mov input_ptr, bx

inf:
rep_height:                         ;  Повтор запиту висоти
    lea ax, enter_height
    lea bx, bad_height              ;  У разі помилки – покажемо bad_height
    call input_array_size
    mov eax, num
    cmp eax, MAX_DIM
    ja bad_height_error             ;  Введене значення більше 5 чи менше 1
    mov height, ax

rep_width:                          ;  Повтор запиту ширини
    lea ax, enter_width
    lea bx, bad_width               ;  У разі помилки – покажемо bad_width
    call input_array_size
    mov eax, num
    cmp eax, MAX_DIM
    ja bad_width_error              ;  Введене значення більше 5 чи менше 1
    mov width_size, ax

    call read_array                 ;  Зчитування елементів масиву
    lea ax, output_array
    call println
    call print_array
    call print_new_line

    lea ax, change_index
    lea bx, bad_limit               ;  Якщо введене значення елемента неправильне
    call input_array_elements
    mov eax, num
    mov elem, eax
    call print_new_line
    call index                      ; Пошук елемента
    call print_new_line
    jmp inf                         ;  Зациклення програми

end_:
    xor ax, ax
    mov ah, 4ch
    mov al, 0
    int 21h
    ret

bad_height_error:                   ;  Висота не в межах [1,5]
    lea ax, bad_height
    call println
    mov num, 0
    xor eax, eax
    jmp rep_height

bad_width_error:                    ;  Ширина не в межах [1,5]
    lea ax, bad_width
    call println
    mov num, 0
    xor eax, eax
    jmp rep_width
main endp


;  Пошук усіх входжень елемента elem у масиві та виведення їх позицій
index proc
    push bp
    mov bp, sp
    mov cx, height
    mov bx, 0
    push bx                       ;  Лічильник знайдених

outer_lop_index:
    push cx
    mov si, 0
    mov cx, width_size

inner_lop_index:
    push bx
    push si
    call get
    pop si
    pop bx
    cmp elem, eax
    jne index_cont                ;  Якщо не співпадає — пропустити
    mov ax, [bp-2]
    add ax, 1
    mov [bp-2], ax                ;  Збільшуємо лічильник знайдених
    mov ax, '('
    call putc
    mov ax, si
    inc ax
    push cx
    push bx
    call print_number             ;  Вивід індексу стовпця
    pop bx
    pop cx
    mov ax, ','
    call putc
    mov ax, bx
    inc ax
    push cx
    push bx
    call print_number             ;  Вивід індексу рядка
    pop bx
    pop cx
    mov al, ')'
    call putc
    call print_new_line

index_cont:
    add si, 1
    loop inner_lop_index
    pop cx
    add bx, 1
    loop outer_lop_index
    pop bx
    cmp bx, 0
    jne index__end                
    lea ax, none_                 ;  Нічого не знайдено
    call println

index__end:
    mov sp, bp
    pop bp
    ret
index endp

; Зчитування всіх елементів масиву з консолі
read_array proc
    push bp
    mov bp, sp
    mov cx, height
    mov bx, 0
enter_array_o:
    push bx
    push cx
    mov cx, width_size
    mov bx, 0

enter_array_i:
    lea ax, enter_element
    call print
    mov eax, ebx
    add eax, 1
    push bx
    push cx
    call print_number
    pop cx
    pop bx
    mov ax, ','
    call putc
    mov ax, [bp-2]
    add ax, 1
    push bx
    push cx
    call print_number
    pop cx
    pop bx
    mov ax, ')'
    call putc
    mov ax, ':'
    call putc
    call read
    call print_new_line
    push bx
    push cx
    mov num, 0
    call parse_input
    pop cx
    pop bx
    cmp ax, 2
    je error1_read_array          ;  Значення поза допустимим діапазоном
    cmp ax, 1
    je error2_read_array          ;  Некоректний формат числа
    mov eax, num
    push bx
    mov si, [bp-2]
    mov di, bx
    call set
    pop bx
    add bx, 1
    loop enter_array_i
    pop cx
    pop bx
    add bx, 1
    loop enter_array_o
    mov sp, bp
    pop bp
    ret

error1_read_array:
    lea ax, bad_limit             ; Помилка: число поза межами
    call println
    jmp enter_array_i

error2_read_array:
    lea ax, bad_char              ;  Помилка: недопустимий символ
    call println
    jmp enter_array_i
read_array endp

;  Вивід масиву у вигляді таблиці
print_array proc
    mov cx, height
    mov bx, 0
outer_lop:
    push cx
    mov si, 0
    mov cx, width_size
inner_lop:
    push bx
    push si
    call get
    pop si
    pop bx
    push cx
    push bx
    call print_number
    pop bx
    pop cx
    mov al, ' '
    call putc
    add si, 1
    loop inner_lop
    pop cx
    add bx, 1
    call print_new_line
    loop outer_lop
    ret
print_array endp

;  Запис значення в масив
set proc
    push eax
    mov ax, si
    mov bx, 4
    mul bx
    mov bx, MAX_DIM
    mul bx
    mov si, ax
    mov ax, di
    mov bx, 4
    mul bx
    mov di, ax
    pop eax
    mov bx, si
    mov array[bx][di], eax
    ret
set endp

;  Отримання значення з масиву
get proc
    mov ax, bx
    mov bx, 20
    mul bx
    push ax
    mov ax, si
    mov bx, 4
    mul bx
    mov si, ax
    pop bx
    mov eax, array[bx][si]
    ret
get endp

; Зчитування розміру (height, width)
input_array_size proc
    push bp
    mov bp, sp
    push ax
    push bx

read_size_repeat:
    mov ax, [bp-2]
    call print
    call read
    call print_new_line
    mov bx, input_ptr
    mov cx, [bx+1]
    xor ch, ch
    call parse_input
    cmp ax, 2
    je error1_read_size           ;  Значення за межами
    cmp ax, 1
    je error2_read_size           ;  Некоректний формат
    cmp num, 20
    jg error1_read_size
    cmp num, 0
    jle error1_read_size
    mov sp, bp
    pop bp
    ret

error1_read_size:
    mov ax, [bp-4]
    call println
    jmp read_size_repeat

error2_read_size:
    lea ax, bad_char
    call println
    jmp read_size_repeat
input_array_size endp

; Ввід одного елемента (для пошуку)
input_array_elements proc
    push bp
    mov bp, sp
    push ax
    push bx

read_elem_repeat:
    mov ax, [bp-2]
    call print
    call read
    call print_new_line
    mov bx, input_ptr
    mov cx, [bx+1]
    xor ch, ch
    call parse_input
    cmp ax, 2
    je error1_elem_size           ;  Значення поза межами
    cmp ax, 1
    je error2_elem_size           ;  Некоректний символ
    mov sp, bp
    pop bp
    ret

error1_elem_size:
    mov ax, [bp-4]
    call println
    jmp read_elem_repeat

error2_elem_size:
    lea ax, bad_char
    call println
    jmp read_elem_repeat
input_array_elements endp

; Системні процедури виводу / вводу
println proc
    call print
    call print_new_line
    ret
println endp

print proc
    mov dx, ax
    xor ax, ax
    mov ah, 9
    int 21h
    ret
print endp

print_new_line proc
    mov dl, 10
    mov ah, 02h
    int 21h
    mov dl, 13
    mov ah, 02h
    int 21h
    ret
print_new_line endp

read proc
    xor ax, ax
    lea dx, input_buffer
    mov ah, 10
    int 21h
    ret
read endp

putc proc
    xor ah, ah
    mov dl, al
    mov ah, 02h
    int 21h
    ret
putc endp

print_number proc
    mov ebx, eax
    or ebx, ebx
    jns m1
    mov al, '-'
    int 29h
    neg ebx
m1:
    mov eax, ebx
    xor ecx, ecx
    mov bx, 10
m2:
    xor dx, dx
    div bx
    add dl, '0'      ; число в символ
    push dx
    inc ecx
    inc dx
    test ax, ax
    jnz m2
m3:
    pop ax
    int 29h
    loop m3
    ret
print_number endp

; Парсинг числа з input_buffer
parse_input proc
    xor cx, cx
    mov cl, input_buffer[1]
    mov num, 0
    mov bx, 2
    mov is_negstive, 0

parse_loop:
    xor ax, ax
    mov al, [input_buffer+bx]
    cmp ax, 'q'
    je end_
    cmp ax, '0'
    jl is_minus
    cmp ax, '9'
    jg error1
    jmp cont

is_minus:
    cmp ax, '-'
    jne error1
    je is_first

is_first:
    cmp cx, input_len
    mov is_negstive, 1
    inc bx
    mov al, [input_buffer+bx]
    dec cx
    jz error1

cont:
    mov curr, ax
    mov eax, num
    mov dx, 10
    mul dx
    jnc succ1

error2:
    mov ax, 2
    ret

succ1:
    mov num, eax
    mov ax, curr
    sub ax, '0'      ; ASCII в число
    mov edx, num
    add dx, ax
    jc error2
    mov num, edx
    inc bx
    dec cx
    cmp cx, 0
    jg parse_loop
    jmp end1

error1:
    mov ax, 1
    ret

end1:
    cmp is_negstive, 0
    mov eax, num
    mov inp, eax
    je end2
    or eax, eax
    neg eax
    cmp eax, INT_MIN
    jl error2
    mov num, eax
end2:
    mov ax, 0
    ret
parse_input endp

end main
