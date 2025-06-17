.model small
.data
    ; Максимальна довжина масиву
    ARR_MAX_LEN     equ 20

    ; Буфер введення рядка: [довжина, фактична довжина, дані]
    input_buffer    db  7, ?, 7 dup("$")
    input_ptr       dw  0               ; Вказівник на буфер введення
    input_len       dw  ?               ; Довжина введеного рядка

    ; Масив чисел (довжина максимум 20)
    array_data      dd  ARR_MAX_LEN dup(?) ; 32-бітні значення
    array_size      dw  0                   ; Фактичний розмір масиву

    parsed_value    dd  0               ; Значення після парсингу
    parsed_num      dd  0               ; Перетворене число
    is_negative     db  0               ; Прапорець мінуса
    curr_char       dw  0               ; Поточний символ

    ; Повідомлення
    msg_input_size      db  "Enter array size, max 20: $"
    msg_input_elem      db  "Enter element between -32768 and 65535 #$"
    msg_invalid_size    db  "Not valid size must be between 1 and 20$"
    msg_show_array      db  "Entered array: $"
    msg_show_sum        db  "Sum of elements: $"
    msg_show_max        db  "Max element of array: $"
    msg_show_sorted     db  "Sorted array: $"
    msg_invalid_bounds  db  "ERROR. Element size must be between -32768 and 65535$"
    msg_invalid_format  db  "ERROR. Not correct numeric format$"
    msg_overflow        db  "Overflow$"

    MIN_INT             equ -32768      ; Мінімальне значення типу int16

.stack 100h
.code
.386

main proc
    ; Ініціалізація сегменту даних
    mov     ax, @data
    mov     ds, ax
    lea     bx, input_buffer
    mov     input_ptr, bx

inf:
    ; Запит розміру масиву
    mov     bx, input_ptr
    call    input_array_size
    mov     eax, parsed_num
    cmp     eax, ARR_MAX_LEN
    jae     bad_size_error
    cmp     eax, 0
    je      bad_size_error
    mov     array_size, ax

    ; Введення елементів масиву
    call    input_array_elements

    ; Вивід масиву
    lea     ax, msg_show_array
    call    print
    call    print_array
    call    print_new_line

    ; Вивід суми
    lea     ax, msg_show_sum
    call    print
    call    calculate_sum

    ; Пошук максимуму
    lea     ax, msg_show_max
    call    print
    call    find_max

    ; Сортування і вивід
    lea     ax, msg_show_sorted
    call    print
    call    sort_array
    call    print_array
    call    print_new_line

    ; Циклічне виконання
    jmp inf

end_:
    ; Завершення програми
    xor     ax, ax
    mov     ah, 4ch
    mov     al, 0
    int     21h

bad_size_error:
    ; Помилка введення розміру
    lea     ax, msg_invalid_size
    call    println
    mov     parsed_num, 0
    xor     eax, eax
    jmp     inf
main endp




; Вивід масиву у фігурних дужках
print_array proc
    mov     cx, array_size
    sub     cx, 1
    mov     si, 0
    mov     al, '{'
    call    putc
    cmp     cx, 0
    je      print_array_end

lop:
    mov     eax, array_data[si]
    push    cx
    call    print_number
    pop     cx
    mov     al, ','
    call    putc
    mov     al, ' '
    call    putc
    add     si, 4
    loop lop

print_array_end:
    mov     eax, array_data[si]
    call    print_number
    mov     al, '}'
    call    putc
    ret
print_array endp

; Обчислення суми елементів
calculate_sum proc
    mov     cx, array_size
    mov     si, 0
    xor     ebx, ebx

sum_lop:
    mov     eax, array_data[si]
    add     ebx, eax
    add     si, 4
    loop sum_lop

    ; Перевірка на переповнення
    cmp     ebx, -32768
    jl      overflow
    cmp     ebx, 65535
    jg      overflow

    mov     eax, ebx
    call    print_number
    call    print_new_line
    jmp     end_sum

overflow:
    lea     ax, msg_overflow
    call    println

end_sum:
    ret
calculate_sum endp

; Пошук максимуму
find_max proc
    mov     si, 0
    mov     cx, array_size
    mov     bx, 0
    mov     edx, MIN_INT

max_lop:
    xor     eax, eax
    mov     eax, array_data[si]
    cmp     eax, edx
    jg      upd_max

back_max:
    add     si, 4
    loop max_lop

    mov     eax, edx
    call    print_number
    call    print_new_line
    ret

upd_max:
    mov     edx, eax
    jmp     back_max
find_max endp

; Сортування масиву
sort_array proc
    push    bp
    mov     bp, sp
    mov     cx, array_size
    sub     cx, 1
    jz      sort_end

sort_o:
    push    cx
    mov     di, 0

sort_i:
    mov     ebx, array_data[di]
    mov     edx, array_data[di+4]
    cmp     ebx, edx
    jle     skp

    ; Обмін значень
    xchg    ebx, edx
    mov     array_data[di], ebx
    mov     array_data[di+4], edx

skp:
    add     di, 4
    loop    sort_i

    pop     cx
    loop    sort_o

sort_end:
    mov     sp, bp
    pop     bp
    ret
sort_array endp

; Введення розміру масиву
input_array_size proc
read_size_repeat:
    lea     ax, msg_input_size
    call    print
    call    read
    call    print_new_line
    mov     bx, input_ptr
    mov     cx, [bx+1]
    xor     ch, ch
    call    parse_input
    cmp     ax, 1
    je      error2_read_size
    cmp     ax, 2
    je      error1_read_size
    cmp     parsed_num, 20
    jg      error1_read_size
    cmp     parsed_num, 0
    jle     error1_read_size
    ret

error1_read_size:
    lea     ax, msg_invalid_size
    call    println
    jmp     read_size_repeat

error2_read_size:
    lea     ax, msg_invalid_format
    call    println
    jmp     read_size_repeat
input_array_size endp

; Введення елементів масиву
input_array_elements proc
    mov     bx, 0
    mov     cx, array_size

enter_mas:
    lea     ax, msg_input_elem
    call    print
    mov     eax, ebx
    add     eax, 1
    push    bx
    push    cx
    call    print_number
    pop     cx
    pop     bx
    mov     ax, ':'
    call    putc
    call    read
    call    print_new_line
    push    bx
    push    cx
    mov     parsed_num, 0
    call    parse_input
    pop     cx
    pop     bx
    cmp     ax, 2
    je      error1_read_mas
    cmp     ax, 1
    je      error2_read_mas
    mov     eax, parsed_num
    push    bx
    call    set_array_item
    pop     bx
    add     bx, 1
    loop enter_mas
    ret

error1_read_mas:
    lea     ax, msg_invalid_bounds
    call    println
    jmp     enter_mas

error2_read_mas:
    lea     ax, msg_invalid_format
    call    println
    jmp     enter_mas
input_array_elements endp

; Парсинг введеного рядка у число
parse_input proc
    xor     cx, cx
    mov     cl, input_buffer[1]
    cmp     cl, 0
    je      error1
    mov     parsed_num, 0
    mov     bx, 2
    mov     is_negative, 0

parse_loop:
    xor     ax, ax
    mov     al, [input_buffer+bx]
    cmp     ax, 'q'             
    je      end_
    cmp     ax, '0'
    jl      is_minus
    cmp     ax, '9'
    jg      error1
    jmp     cont

is_minus:
    cmp     ax, '-'
    jne     error1
    je      is_first

is_first:
    cmp     cx, input_len
    mov     is_negative, 1
    inc     bx
    mov     al, [input_buffer+bx]
    dec     cx
    jz      error1

cont:
    mov     curr_char, ax
    mov     eax, parsed_num
    mov     dx, 10
    mul     dx
    jnc     succ1

error2:
    mov     ax, 2
    ret

succ1:
    mov     parsed_num, eax
    mov     ax, curr_char
    sub     ax, '0'      ; перетворення символу в цифру
    mov     edx, parsed_num
    add     dx, ax       
    jc      error2
    mov     parsed_num, edx
    inc     bx
    dec     cx
    cmp     cx, 0
    jg      parse_loop
    jmp     end1

error1:
    mov     ax, 1
    ret

ex:
    mov     ax, 3
    ret

end1:
    cmp     is_negative, 0
    mov     eax, parsed_num
    mov     parsed_value, eax
    je      end2
    or      eax, eax
    neg     eax
    cmp     eax, MIN_INT 
    jl      error2
    mov     parsed_num, eax

end2:
    mov     ax, 0
    ret
parse_input endp

; Вивід рядка на екран
print proc
    mov     dx, ax
    xor     ax, ax
    mov     ah, 9
    int     21h
    ret
print endp

println proc
    call print
    call print_new_line
    ret
println endp

; Вивід нового рядка
print_new_line proc
    mov   dl, 10
    mov   ah, 02h
    int   21h
    mov   dl, 13
    mov   ah, 02h
    int   21h
    ret
print_new_line endp

; Вивід символу
putc proc
    xor     ah, ah
    mov     dl, al
    mov     ah, 02h
    int     21h
    ret
putc endp

; Зчитування з клавіатури
read proc
    xor     ax, ax
    lea     dx, input_buffer
    mov     ah, 10
    int     21h
    ret
read endp

; Встановити елемент масиву
set_array_item proc
    push    ax
    mov     ax, bx
    mov     bx, 4
    mul     bx
    mov     si, ax
    pop     ax
    mov     array_data[si], eax
    ret
set_array_item endp

; Отримати елемент масиву
get_array_item proc
    mov     si, ax
    mov     eax, array_data[si]
    ret
get_array_item endp

; Вивід цілого числа
print_number proc
    mov   ebx, eax
    or    ebx, ebx
    jns   m1
    mov   al, '-'
    int   29h
    neg   ebx

m1:
    mov   eax, ebx
    xor   ecx, ecx
    mov   bx, 10

m2:
    xor   dx, dx
    div   bx
    add   dl, '0'     ; перетворення цифри у символ
    push  dx
    inc   cx
    inc   dx
    test  ax, ax
    jnz   m2

m3:
    pop   ax
    int   29h
    loop  m3
    ret
print_number endp

end main
