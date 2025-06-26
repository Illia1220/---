.model small
.data
    ; Максимальна довжина масиву
    ARR_MAX_LEN     equ 21

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

; Макрос для виведення повідомлення та зчитування введення
read_input macro msg
    local print_msg
print_msg:
    mov     dx, offset msg     ; Завантаження зміщення адреси повідомлення
    mov     ah, 9              ; Код функції виведення рядка
    int     21h                ; Виведення повідомлення
    lea     dx, input_buffer   ; Завантаження адреси буфера
    mov     ah, 10             ; Код функції зчитування рядка
    int     21h                ; Зчитування введення
endm

main proc
    ; Ініціалізація сегменту даних
    mov     ax, @data           ; Завантаження адреси сегменту даних у регістр AX
    mov     ds, ax              ; Встановлення сегменту даних у DS
    lea     bx, input_buffer    ; Завантаження адреси буфера введення у BX
    mov     input_ptr, bx       ; Збереження адреси буфера у змінній input_ptr

inf:
    ; Запит розміру масиву
    mov     bx, input_ptr       ; Відновлення адреси буфера введення у BX
    read_input msg_input_size   ; Виклик макросу для введення розміру
    call    print_new_line      ; Виведення нового рядка
    mov     cx, [bx+1]          ; Завантаження довжини введеного рядка
    xor     ch, ch              ; Очищення старшого байта CX
    call    parse_input         ; Парсинг введеного рядка
    mov     eax, parsed_num     ; Завантаження спарсеного числа у EAX
    cmp     eax, ARR_MAX_LEN    ; Порівняння з максимальним розміром масиву
    jae     bad_size_error      ; Перехід до помилки, якщо розмір завеликий
    cmp     eax, 0              ; Перевірка, чи розмір дорівнює нулю
    je      bad_size_error      ; Перехід до помилки, якщо розмір нульовий
    mov     array_size, ax      ; Збереження розміру масиву у змінній

    ; Введення елементів масиву
    call    input_array_elements ; Виклик процедури для введення елементів масиву

    ; Вивід масиву
    lea     ax, msg_show_array  ; Завантаження адреси повідомлення про вивід масиву
    call    print               ; Виведення повідомлення
    call    print_array         ; Виведення масиву
    call    print_new_line      ; Виведення нового рядка

    ; Вивід суми
    lea     ax, msg_show_sum    ; Завантаження адреси повідомлення про суму
    call    print               ; Виведення повідомлення
    call    calculate_sum       ; Обчислення та виведення суми елементів

    ; Пошук максимуму
    lea     ax, msg_show_max    ; Завантаження адреси повідомлення про максимум
    call    print               ; Виведення повідомлення
    call    find_max            ; Пошук та виведення максимального елемента

    ; Сортування і вивід
    lea     ax, msg_show_sorted ; Завантаження адреси повідомлення про сортування
    call    print               ; Виведення повідомлення
    call    sort_array          ; Сортування масиву
    call    print_array         ; Виведення відсортованого масиву
    call    print_new_line      ; Виведення нового рядка

    ; Циклічне виконання
    jmp inf                     ; Повторення циклу введення та обробки

end_:
    ; Завершення програми
    xor     ax, ax              ; Очищення AX
    mov     ah, 4ch             ; Код функції завершення програми
    mov     al, 0               ; Код повернення 0
    int     21h                 ; Виклик переривання для завершення

bad_size_error:
    ; Помилка введення розміру
    lea     ax, msg_invalid_size ; Завантаження адреси повідомлення про помилку розміру
    call    println             ; Виведення повідомлення з новим рядком
    mov     parsed_num, 0       ; Скидання спарсеного числа
    xor     eax, eax            ; Очищення EAX
    jmp     inf                 ; Повернення до циклу введення
main endp

; Вивід масиву у фігурних дужках
print_array proc
    mov     cx, array_size      ; Завантаження розміру масиву у CX
    sub     cx, 1               ; Зменшення лічильника на 1 для циклу
    mov     si, 0               ; Ініціалізація індексу масиву
    mov     al, '{'             ; Символ відкриваючої дужки
    call    putc                ; Виведення символу
    cmp     cx, 0               ; Перевірка, чи масив не порожній
    je      print_array_end     ; Перехід до кінця, якщо масив порожній

lop:
    mov     eax, array_data[si] ; Завантаження поточного елемента масиву
    push    cx                  ; Збереження лічильника
    call    print_number        ; Виведення числа
    pop     cx                  ; Відновлення лічильника
    mov     al, ','             ; Символ коми
    call    putc                ; Виведення коми
    mov     al, ' '             ; Символ пробілу
    call    putc                ; Виведення пробілу
    add     si, 4               ; Збільшення індексу на розмір елемента (4 байти)
    loop lop                    ; Повторення циклу

print_array_end:
    mov     eax, array_data[si] ; Завантаження останнього елемента
    call    print_number        ; Виведення числа
    mov     al, '}'             ; Символ закриваючої дужки
    call    putc                ; Виведення символу
    ret                         ; Повернення
print_array endp

; Обчислення суми елементів
calculate_sum proc
    mov     cx, array_size      ; Завантаження розміру масиву
    mov     si, 0               ; Ініціалізація індексу
    xor     ebx, ebx            ; Очищення регістру для суми

sum_lop:
    mov     eax, array_data[si] ; Завантаження поточного елемента
    add     ebx, eax            ; Додавання до суми
    add     si, 4               ; Збільшення індексу
    loop sum_lop                ; Повторення циклу

    ; Перевірка на переповнення
    cmp     ebx, -32768         ; Перевірка нижньої межі
    jl      overflow            ; Перехід до помилки при переповненні
    cmp     ebx, 65535          ; Перевірка верхньої межі
    jg      overflow            ; Перехід до помилки при переповненні

    mov     eax, ebx            ; Переміщення суми в EAX
    call    print_number        ; Виведення суми
    call    print_new_line      ; Виведення нового рядка
    jmp     end_sum             ; Перехід до кінця процедури

overflow:
    lea     ax, msg_overflow    ; Завантаження повідомлення про переповнення
    call    println             ; Виведення повідомлення

end_sum:
    ret                         ; Повернення
calculate_sum endp

; Пошук максимуму
find_max proc
    mov     si, 0               ; Ініціалізація індексу
    mov     cx, array_size         ; Завантаження розміру масиву
    mov     bx, 0               ; Очищення BX
    mov     edx, MIN_INT        ; Встановлення мінімального значення як початкове

max_lop:
    xor     eax, eax            ; Очищення EAX
    mov     eax, array_data[si] ; Завантаження поточного елемента
    cmp     eax, edx            ; Порівняння з поточним максимумом
    jg      upd_max             ; Оновлення максимуму, якщо більше

back_max:
    add     si, 4               ; Збільшення індексу
    loop max_lop                ; Повторення циклу

    mov     eax, edx            ; Переміщення максимуму в EAX
    call    print_number        ; Виведення максимуму
    call    print_new_line      ; Виведення нового рядка
    ret                         ; Повернення

upd_max:
    mov     edx, eax            ; Оновлення максимуму
    jmp     back_max            ; Повернення до циклу
find_max endp

; Сортування масиву
sort_array proc
    push    bp                  ; Збереження базового покажчика
    mov     bp, sp              ; Встановлення нового базового покажчика
    mov     cx, array_size      ; Завантаження розміру масиву
    sub     cx, 1               ; Зменшення для зовнішнього циклу
    jz      sort_end            ; Вихід, якщо масив має 1 елемент

sort_o:
    push    cx                  ; Збереження лічильника зовнішнього циклу
    mov     di, 0               ; Ініціалізація індексу внутрішнього циклу

sort_i:
    mov     ebx, array_data[di] ; Завантаження поточного елемента
    mov     edx, array_data[di+4] ; Завантаження наступного елемента
    cmp     ebx, edx            ; Порівняння елементів
    jle     skp                 ; Пропуск, якщо порядок правильний

    ; Обмін значень
    xchg    ebx, edx            ; Обмін регістрів
    mov     array_data[di], ebx ; Збереження першого елемента
    mov     array_data[di+4], edx ; Збереження другого елемента

skp:
    add     di, 4               ; Збільшення індексу
    loop    sort_i              ; Повторення внутрішнього циклу

    pop     cx                  ; Відновлення лічильника
    loop    sort_o              ; Повторення зовнішнього циклу

sort_end:
    mov     sp, bp              ; Відновлення стеку
    pop     bp                  ; Відновлення базового покажчика
    ret                         ; Повернення
sort_array endp

; Введення розміру масиву
input_array_size proc
read_size_repeat:
    lea     ax, msg_input_size  ; Завантаження повідомлення про введення розміру
    call    print               ; Виведення повідомлення
    call    read                ; Зчитування введення
    call    print_new_line      ; Виведення нового рядка
    mov     bx, input_ptr       ; Завантаження адреси буфера
    mov     cx, [bx+1]          ; Завантаження довжини введеного рядка
    xor     ch, ch              ; Очищення старшого байта CX
    call    parse_input         ; Парсинг введеного рядка
    cmp     ax, 1               ; Перевірка на помилку формату
    je      error2_read_size    ; Перехід до помилки формату

    cmp     parsed_num, 20      ; Перевірка верхньої межі розміру
    jg      error1_read_size    ; Помилка, якщо більше 20
    cmp     parsed_num, 0       ; Перевірка нижньої межі
    jle     error1_read_size    ; Помилка, якщо 0 або менше
    ret                         ; Повернення

error1_read_size:
    lea     ax, msg_invalid_size ; Завантаження повідомлення про некоректний розмір
    call    println             ; Виведення повідомлення
    jmp     read_size_repeat    ; Повторення введення

error2_read_size:
    lea     ax, msg_invalid_format ; Завантаження повідомлення про некоректний формат
    call    println             ; Виведення повідомлення
    jmp     read_size_repeat    ; Повторення введення
input_array_size endp

; Введення елементів масиву
input_array_elements proc
    mov     bx, 0               ; Ініціалізація лічильника елементів
    mov     cx, array_size      ; Завантаження розміру масиву

enter_mas:
    lea     ax, msg_input_elem  ; Завантаження повідомлення про введення елемента
    call    print               ; Виведення повідомлення
    mov     eax, ebx            ; Завантаження номера елемента
    add     eax, 1              ; Збільшення номера на 1 для виведення
    push    bx                  ; Збереження лічильника
    push    cx                  ; Збереження розміру
    call    print_number        ; Виведення номера елемента
    pop     cx                  ; Відновлення розміру
    pop     bx                  ; Відновлення лічильника
    mov     ax, ':'             ; Символ двокрапки
    call    putc                ; Виведення двокрапки
    call    read                ; Зчитування введення
    call    print_new_line      ; Виведення нового рядка
    push    bx                  ; Збереження лічильника
    push    cx                  ; Збереження розміру
    mov     parsed_num, 0       ; Скидання спарсеного числа
    call    parse_input         ; Парсинг введеного рядка
    pop     cx                  ; Відновлення розміру
    pop     bx                  ; Відновлення лічильника
    cmp     ax, 2               ; Перевірка на переповнення
    je      error1_read_mas     ; Перехід до помилки меж
    cmp     ax, 1               ; Перевірка на некоректний формат
    je      error2_read_mas     ; Перехід до помилки формату
    mov     eax, parsed_num     ; Завантаження спарсеного числа
    push    bx                  ; Збереження лічильника
    call    set_array_item      ; Встановлення елемента масиву
    pop     bx                  ; Відновлення лічильника
    add     bx, 1               ; Збільшення лічильника
    loop enter_mas              ; Повторення циклу
    ret                         ; Повернення

error1_read_mas:
    lea     ax, msg_invalid_bounds ; Завантаження повідомлення про некоректні межі
    call    println             ; Виведення повідомлення
    jmp     enter_mas           ; Повторення введення

error2_read_mas:
    lea     ax, msg_invalid_format ; Завантаження повідомлення про некоректний формат
    call    println             ; Виведення повідомлення
    jmp     enter_mas           ; Повторення введення
input_array_elements endp

; Парсинг введеного рядка у число
parse_input proc
    xor     cx, cx              ; Очищення CX
    mov     cl, input_buffer[1] ; Завантаження довжини введеного рядка
    cmp     cl, 0               ; Перевірка, чи рядок порожній
    je      error1              ; Перехід до помилки, якщо порожній
    mov     parsed_num, 0       ; Скидання спарсеного числа
    mov     bx, 2               ; Початок парсингу з третього байта буфера
    mov     is_negative, 0      ; Скидання прапора від’ємності

parse_loop:
    xor     ax, ax              ; Очищення AX
    mov     al, [input_buffer+bx] ; Завантаження поточного символу
    cmp     ax, 'q'             ; Перевірка на символ завершення
    je      end_                ; Завершення програми, якщо 'q'
    cmp     ax, '0'             ; Перевірка, чи символ є цифрою
    jl      is_minus            ; Перехід до перевірки на мінус
    cmp     ax, '9'             ; Перевірка верхньої межі цифри
    jg      error1              ; Помилка, якщо не цифра
    jmp     cont                ; Продовження парсингу

is_minus:
    cmp     ax, '-'             ; Перевірка на символ мінуса
    jne     error1              ; Помилка, якщо не мінус
    je      is_first            ; Перехід до перевірки позиції мінуса

is_first:
    cmp     cx, input_len       ; Перевірка, чи мінус на початку
    mov     is_negative, 1      ; Встановлення прапора від’ємності
    inc     bx                  ; Збільшення індексу
    mov     al, [input_buffer+bx] ; Завантаження наступного символу
    dec     cx                  ; Зменшення лічильника
    jz      error1              ; Помилка, якщо більше немає символів

cont:
    mov     curr_char, ax       ; Збереження поточного символу
    mov     eax, parsed_num     ; Завантаження поточного числа
    mov     dx, 10              ; Множник для зсуву
    mul     dx                  ; Множення на 10
    jnc     succ1               ; Продовження, якщо немає переповнення

error2:
    mov     ax, 2               ; Код помилки переповнення
    ret                         ; Повернення

succ1:
    mov     parsed_num, eax     ; Збереження результату множення
    mov     ax, curr_char       ; Завантаження поточного символу
    sub     ax, '0'             ; Перетворення символу в цифру
    mov     edx, parsed_num     ; Завантаження поточного числа
    add     dx, ax              ; Додавання нової цифри
    jc      error2              ; Помилка при переповненні
    mov     parsed_num, edx     ; Збереження результату
    inc     bx                  ; Збільшення індексу
    dec     cx                  ; Зменшення лічильника
    cmp     cx, 0               ; Перевірка кінця рядка
    jg      parse_loop          ; Повторення циклу
    jmp     end1                ; Завершення парсингу

error1:
    mov     ax, 1               ; Код помилки формату
    ret                         ; Повернення

ex:
    mov     ax, 3               ; Код помилки (не використовується)
    ret                         ; Повернення

end1:
    cmp     is_negative, 0      ; Перевірка прапора від’ємності
    mov     eax, parsed_num     ; Завантаження числа
    mov     parsed_value, eax   ; Збереження значення
    je      end2                ; Пропуск, якщо не від’ємне
    or      eax, eax            ; Перевірка числа
    neg     eax                 ; Зміна знаку
    cmp     eax, MIN_INT        ; Перевірка на переповнення
    jl      error2              ; Помилка при переповненні
    mov     parsed_num, eax     ; Збереження від’ємного числа

end2:
    mov     ax, 0               ; Код успішного виконання
    ret                         ; Повернення
parse_input endp

; Вивід рядка на екран
print proc
    mov     dx, ax              ; Завантаження адреси рядка у DX
    xor     ax, ax              ; Очищення AX
    mov     ah, 9               ; Код функції виведення рядка
    int     21h                 ; Виклик переривання
    ret                         ; Повернення
print endp

println proc
    call print                  ; Виведення рядка
    call print_new_line         ; Виведення нового рядка
    ret                         ; Повернення
println endp

; Вивід нового рядка
print_new_line proc
    mov   dl, 10                ; Символ нового рядка (LF)
    mov   ah, 02h               ; Код функції виведення символу
    int   21h                   ; Виклик переривання
    mov   dl, 13                ; Символ повернення каретки (CR)
    mov   ah, 02h               ; Код функції виведення символу
    int   21h                   ; Виклик переривання
    ret                         ; Повернення
print_new_line endp

; Вивід символу
putc proc
    xor     ah, ah              ; Очищення AH
    mov     dl, al              ; Завантаження символу у DL
    mov     ah, 02h             ; Код функції виведення символу
    int     21h                 ; Виклик переривання
    ret                         ; Повернення
putc endp

; Зчитування з клавіатури
read proc
    xor     ax, ax              ; Очищення AX
    lea     dx, input_buffer    ; Завантаження адреси буфера
    mov     ah, 10              ; Код функції зчитування рядка
    int     21h                 ; Виклик переривання
    ret                         ; Повернення
read endp

; Встановити елемент масиву
set_array_item proc
    push    ax                  ; Збереження AX
    mov     ax, bx              ; Завантаження індексу
    mov     bx, 4               ; Розмір елемента (4 байти)
    mul     bx                  ; Обчислення зміщення
    mov     si, ax              ; Збереження зміщення у SI
    pop     ax                  ; Відновлення AX
    mov     array_data[si], eax ; Збереження елемента у масив
    ret                         ; Повернення
set_array_item endp

; Отримати елемент масиву
get_array_item proc
    mov     si, ax              ; Завантаження індексу у SI
    mov     eax, array_data[si] ; Завантаження елемента з масиву
    ret                         ; Повернення
get_array_item endp

; Вивід цілого числа
print_number proc
    mov   ebx, eax              ; Завантаження числа з EAX у EBX для обробки
    or    ebx, ebx              ; Перевірка знаку числа (чи від’ємне)
    jns   m1                    ; Перехід до m1, якщо число не від’ємне
    mov   al, '-'               ; Завантаження символу мінуса в AL
    int   29h                   ; Виведення символу мінуса через швидке переривання
    neg   ebx                   ; Зміна знаку числа (з від’ємного на додатне)

m1:
    mov   eax, ebx              ; Переміщення числа з EBX назад у EAX
    xor   ecx, ecx              ; Очищення ECX для лічильника цифр
    mov   bx, 10                ; Завантаження дільника 10 для отримання цифр

m2:
    xor   dx, dx                ; Очищення DX для ділення
    div   bx                    ; Ділення EAX на 10, залишок у DX
    add   dl, '0'               ; Перетворення цифри у символ ASCII
    push  dx                    ; Збереження символу цифри у стеку
    inc   cx                    ; Збільшення лічильника цифр
    inc   dx                    ; Збільшення DX (необов’язкове, можлива помилка)
    test  ax, ax                ; Перевірка, чи залишилися цифри в EAX
    jnz   m2                    ; Повторення циклу, якщо є цифри

m3:
    pop   ax                    ; Витягування символу цифри зі стеку
    int   29h                   ; Виведення символу через швидке переривання
    loop  m3                    ; Повторення для всіх цифр у стеку
    ret                         ; Повернення з процедури
print_number endp

end main
