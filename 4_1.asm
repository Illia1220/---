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


; Пошук усіх входжень елемента elem у масиві та виведення їх позицій
index proc
    push bp                     ; Зберегти базовий покажчик
    mov bp, sp                  ; Встановити базовий покажчик на стек
    mov cx, height              ; Завантажити висоту масиву в CX
    mov bx, 0                   ; Ініціалізувати лічильник рядків (BX = 0)
    push bx                     ; Зберегти лічильник знайдених елементів (BX) на стек
outer_lop_index:
    push cx                     ; Зберегти лічильник зовнішнього циклу
    mov si, 0                   ; Ініціалізувати індекс стовпця (SI = 0)
    mov cx, width_size          ; Завантажити ширину масиву в CX
inner_lop_index:
    push bx                     ; Зберегти лічильник рядків
    push si                     ; Зберегти індекс стовпця
    call get                    ; Отримати елемент масиву за індексами BX, SI
    pop si                      ; Відновити індекс стовпця
    pop bx                      ; Відновити лічильник рядків
    cmp elem, eax               ; Порівняти елемент масиву з шуканим елементом (elem)
    jne index_cont              ; Якщо не співпадає, перейти до index_cont
    mov ax, [bp-2]              ; Отримати лічильник знайдених зі стеку
    add ax, 1                   ; Збільшити лічильник знайдених
    mov [bp-2], ax              ; Зберегти оновлений лічильник
    mov ax, '('                 ; Вивести символ '('
    call putc                   ; Викликати процедуру виведення символу
    mov ax, si                  ; Завантажити індекс стовпця
    inc ax                      ; Інкрементувати для відображення (нумерація з 1)
    push cx                     ; Зберегти лічильник циклу
    push bx                     ; Зберегти лічильник рядків
    call print_number           ; Вивести індекс стовпця
    pop bx                      ; Відновити лічильник рядків
    pop cx                      ; Відновити лічильник циклу
    mov ax, ','                 ; Вивести символ ','
    call putc                   ; Викликати процедуру виведення символу
    mov ax, bx                  ; Завантажити індекс рядка
    inc ax                      ; Інкрементувати для відображення (нумерація з 1)
    push cx                     ; Зберегти лічильник циклу
    push bx                     ; Зберегти лічильник рядків
    call print_number           ; Вивести індекс рядка
    pop bx                      ; Відновити лічильник рядків
    pop cx                      ; Відновити лічильник циклу
    mov al, ')'                 ; Вивести символ ')'
    call putc                   ; Викликати процедуру виведення символу
    call print_new_line         ; Вивести новий рядок
index_cont:
    add si, 1                   ; Інкрементувати індекс стовпця
    loop inner_lop_index        ; Повторити внутрішній цикл
    pop cx                      ; Відновити лічильник зовнішнього циклу
    add bx, 1                   ; Інкрементувати індекс рядка
    loop outer_lop_index        ; Повторити зовнішній цикл
    pop bx                      ; Відновити лічильник знайдених
    cmp bx, 0                   ; Перевірити, чи знайдено елементи
    jne index__end              ; Якщо знайдено, завершити
    lea ax, none_               ; Завантажити повідомлення "нічого не знайдено"
    call println                ; Вивести повідомлення
index__end:
    mov sp, bp                  ; Відновити стек
    pop bp                      ; Відновити базовий покажчик
    ret                         ; Повернутися з процедури
index endp

; Зчитування всіх елементів масиву з консолі
read_array proc
    push bp                     ; Зберегти базовий покажчик
    mov bp, sp                  ; Встановити базовий покажчик на стек
    mov cx, height              ; Завантажити висоту масиву
    mov bx, 0                   ; Ініціалізувати лічильник рядків
enter_array_o:
    push bx                     ; Зберегти лічильник рядків
    push cx                     ; Зберегти лічильник зовнішнього циклу
    mov cx, width_size          ; Завантажити ширину масиву
    mov bx, 0                   ; Ініціалізувати лічильник стовпців
enter_array_i:
    lea ax, enter_element       ; Завантажити повідомлення "введіть елемент"
    call print                  ; Вивести повідомлення
    mov eax, ebx                ; Завантажити індекс стовпця
    add eax, 1                  ; Інкрементувати для відображення (нумерація з 1)
    push bx                     ; Зберегти лічильник стовпців
    push cx                     ; Зберегти лічильник циклу
    call print_number           ; Вивести індекс стовпця
    pop cx                      ; Відновити лічильник циклу
    pop bx                      ; Відновити лічильник стовпців
    mov ax, ','                 ; Вивести символ ','
    call putc                   ; Викликати процедуру виведення символу
    mov ax, [bp-2]              ; Завантажити індекс рядка зі стеку
    add ax, 1                   ; Інкрементувати для відображення (нумерація з 1)
    push bx                     ; Зберегти лічильник стовпців
    push cx                     ; Зберегти лічильник циклу
    call print_number           ; Вивести індекс рядка
    pop cx                      ; Відновити лічильник циклу
    pop bx                      ; Відновити лічильник стовпців
    mov ax, ')'                 ; Вивести символ ')'
    call putc                   ; Викликати процедуру виведення символу
    mov ax, ':'                 ; Вивести символ ':'
    call putc                   ; Викликати процедуру виведення символу
    call read                   ; Зчитати введення користувача
    call print_new_line         ; Вивести новий рядок
    push bx                     ; Зберегти лічильник стовпців
    push cx                     ; Зберегти лічильник циклу
    mov num, 0                  ; Скинути змінну num
    call parse_input            ; Парсити введене число
    pop cx                      ; Відновити лічильник циклу
    pop bx                      ; Відновити лічильник стовпців
    cmp ax, 2                   ; Перевірити на помилку діапазону
    je error1_read_array        ; Якщо помилка, обробити
    cmp ax, 1                   ; Перевірити на некоректний формат
    je error2_read_array        ; Якщо помилка, обробити
    mov eax, num                ; Завантажити спарсене число
    push bx                     ; Зберегти лічильник стовпців
    mov si, [bp-2]              ; Завантажити індекс рядка
    mov di, bx                  ; Завантажити індекс стовпця
    call set                    ; Записати значення в масив
    pop bx                      ; Відновити лічильник стовпців
    add bx, 1                   ; Інкрементувати індекс стовпця
    loop enter_array_i          ; Повторити внутрішній цикл
    pop cx                      ; Відновити лічильник зовнішнього циклу
    pop bx                      ; Відновити лічильник рядків
    add bx, 1                   ; Інкрементувати індекс рядка
    loop enter_array_o          ; Повторити зовнішній цикл
    mov sp, bp                  ; Відновити стек
    pop bp                      ; Відновити базовий покажчик
    ret                         ; Повернутися з процедури
error1_read_array:
    lea ax, bad_limit           ; Завантажити повідомлення про помилку діапазону
    call println                ; Вивести повідомлення
    jmp enter_array_i           ; Повторити введення
error2_read_array:
    lea ax, bad_char            ; Завантажити повідомлення про некоректний символ
    call println                ; Вивести повідомлення
    jmp enter_array_i           ; Повторити введення
read_array endp

; Вивід масиву у вигляді таблиці
print_array proc
    mov cx, height              ; Завантажити висоту масиву
    mov bx, 0                   ; Ініціалізувати лічильник рядків
outer_lop:
    push cx                     ; Зберегти лічильник зовнішнього циклу
    mov si, 0                   ; Ініціалізувати індекс стовпця
    mov cx, width_size          ; Завантажити ширину масиву
inner_lop:
    push bx                     ; Зберегти лічильник рядків
    push si                     ; Зберегти індекс стовпця
    call get                    ; Отримати елемент масиву
    pop si                      ; Відновити індекс стовпця
    pop bx                      ; Відновити лічильник рядків
    push cx                     ; Зберегти лічильник циклу
    push bx                     ; Зберегти лічильник рядків
    call print_number           ; Вивести елемент
    pop bx                      ; Відновити лічильник рядків
    pop cx                      ; Відновити лічильник циклу
    mov al, ' '                 ; Вивести пробіл
    call putc                   ; Викликати процедуру виведення символу
    add si, 1                   ; Інкрементувати індекс стовпця
    loop inner_lop              ; Повторити внутрішній цикл
    pop cx                      ; Відновити лічильник зовнішнього циклу
    add bx, 1                   ; Інкрементувати індекс рядка
    call print_new_line         ; Вивести новий рядок
    loop outer_lop              ; Повторити зовнішній цикл
    ret                         ; Повернутися з процедури
print_array endp

; Запис значення в масив
set proc
    push eax                    ; Зберегти значення елемента
    mov ax, si                  ; Завантажити індекс рядка
    mov bx, 4                   ; Помножити на 4 (розмір елемента)
    mul bx                      ; Обчислити зміщення по рядках
    mov bx, MAX_DIM             ; Завантажити максимальний розмір
    mul bx                      ; Обчислити базову адресу рядка
    mov si, ax                  ; Зберегти зміщення
    mov ax, di                  ; Завантажити індекс стовпця
    mov bx, 4                   ; Помножити на 4 (розмір елемента)
    mul bx                      ; Обчислити зміщення по стовпцях
    mov di, ax                  ; Зберегти зміщення
    pop eax                     ; Відновити значення елемента
    mov bx, si                  ; Завантажити зміщення рядка
    mov array[bx][di], eax      ; Записати значення в масив
    ret                         ; Повернутися з процедури
set endp

; Отримання значення з масиву
get proc
    mov ax, bx                  ; Завантажити індекс рядка
    mov bx, 20                  ; Помножити на 20 (розмір рядка)
    mul bx                      ; Обчислити зміщення по рядках
    push ax                     ; Зберегти зміщення
    mov ax, si                  ; Завантажити індекс стовпця
    mov bx, 4                   ; Помножити на 4 (розмір елемента)
    mul bx                      ; Обчислити зміщення по стовпцях
    mov si, ax                  ; Зберегти зміщення
    pop bx                      ; Відновити зміщення рядка
    mov eax, array[bx][si]      ; Отримати значення з масиву
    ret                         ; Повернутися з процедури
get endp

; Зчитування розміру (height, width)
input_array_size proc
    push bp                     ; Зберегти базовий покажчик
    mov bp, sp                  ; Встановити базовий покажчик на стек
    push ax                     ; Зберегти регістр AX
    push bx                     ; Зберегти регістр BX
read_size_repeat:
    mov ax, [bp-2]              ; Завантажити повідомлення для введення
    call print                  ; Вивести повідомлення
    call read                   ; Зчитати введення
    call print_new_line         ; Вивести новий рядок
    mov bx, input_ptr           ; Завантажити покажчик на буфер введення
    mov cx, [bx+1]              ; Отримати довжину введення
    xor ch, ch                  ; Очистити старший байт CX
    call parse_input            ; Парсити введене число
    cmp ax, 2                   ; Перевірити на помилку діапазону
    je error1_read_size         ; Якщо помилка, обробити
    cmp ax, 1                   ; Перевірити на некоректний формат
    je error2_read_size         ; Якщо помилка, обробити
    cmp num, 20                 ; Перевірити, чи розмір <= 20
    jg error1_read_size         ; Якщо більше, помилка
    cmp num, 0                  ; Перевірити, чи розмір > 0
    jle error1_read_size        ; Якщо менше або дорівнює, помилка
    mov sp, bp                  ; Відновити стек
    pop bp                      ; Відновити базовий покажчик
    ret                         ; Повернутися з процедури
error1_read_size:
    mov ax, [bp-4]              ; Завантажити повідомлення про помилку діапазону
    call println                ; Вивести повідомлення
    jmp read_size_repeat        ; Повторити введення
error2_read_size:
    lea ax, bad_char            ; Завантажити повідомлення про некоректний символ
    call println                ; Вивести повідомлення
    jmp read_size_repeat        ; Повторити введення
input_array_size endp

; Введення одного елемента (для пошуку)
input_array_elements proc
    push bp                     ; Зберегти базовий покажчик
    mov bp, sp                  ; Встановити базовий покажчик на стек
    push ax                     ; Зберегти регістр AX
    push bx                     ; Зберегти регістр BX
read_elem_repeat:
    mov ax, [bp-2]              ; Завантажити повідомлення для введення
    call print                  ; Вивести повідомлення
    call read                   ; Зчитати введення
    call print_new_line         ; Вивести новий рядок
    mov bx, input_ptr           ; Завантажити покажчик на буфер введення
    mov cx, [bx+1]              ; Отримати довжину введення
    xor ch, ch                  ; Очистити старший байт CX
    call parse_input            ; Парсити введене число
    cmp ax, 2                   ; Перевірити на помилку діапазону
    je error1_elem_size         ; Якщо помилка, обробити
    cmp ax, 1                   ; Перевірити на некоректний символ
    je error2_elem_size         ; Якщо помилка, обробити
    mov sp, bp                  ; Відновити стек
    pop bp                      ; Відновити базовий покажчик
    ret                         ; Повернутися з процедури
error1_elem_size:
    mov ax, [bp-4]              ; Завантажити повідомлення про помилку діапазону
    call println                ; Вивести повідомлення
    jmp read_elem_repeat        ; Повторити введення
error2_elem_size:
    lea ax, bad_char            ; Завантажити повідомлення про некоректний символ
    call println                ; Вивести повідомлення
    jmp read_elem_repeat        ; Повторити введення
input_array_elements endp

; Системні процедури виводу / вводу
println proc
    call print                  ; Вивести рядок
    call print_new_line         ; Вивести новий рядок
    ret                         ; Повернутися з процедури
println endp

print proc
    mov dx, ax                  ; Завантажити адресу рядка в DX
    xor ax, ax                  ; Очистити AX
    mov ah, 9                   ; Встановити функцію DOS для виведення рядка
    int 21h                     ; Викликати переривання DOS
    ret                         ; Повернутися з процедури
print endp

print_new_line proc
    mov dl, 10                  ; Вивести символ нового рядка (LF)
    mov ah, 02h                 ; Встановити функцію DOS для виведення символу
    int 21h                     ; Викликати переривання DOS
    mov dl, 13                  ; Вивести символ повернення каретки (CR)
    mov ah, 02h                 ; Встановити функцію DOS для виведення символу
    int 21h                     ; Викликати переривання DOS
    ret                         ; Повернутися з процедури
print_new_line endp

read proc
    xor ax, ax                  ; Очистити AX
    lea dx, input_buffer        ; Завантажити адресу буфера введення
    mov ah, 10                  ; Встановити функцію DOS для зчитування рядка
    int 21h                     ; Викликати переривання DOS
    ret                         ; Повернутися з процедури
read endp

putc proc
    xor ah, ah                  ; Очистити AH
    mov dl, al                  ; Завантажити символ для виведення
    mov ah, 02h                 ; Встановити функцію DOS для виведення символу
    int 21h                     ; Викликати переривання DOS
    ret                         ; Повернутися з процедури
putc endp

print_number proc
    mov ebx, eax                ; Завантажити число для виведення
    or ebx, ebx                 ; Перевірити знак числа
    jns m1                      ; Якщо не від’ємне, продовжити
    mov al, '-'                 ; Вивести знак мінус
    int 29h                     ; Викликати швидкий вивід символу
    neg ebx                     ; Змінити знак числа
m1:
    mov eax, ebx                ; Завантажити число
    xor ecx, ecx                ; Очистити лічильник цифр
    mov bx, 10                  ; Встановити основу (10)
m2:
    xor dx, dx                  ; Очистити DX
    div bx                      ; Ділити число на 10
    add dl, '0'                 ; Перетворити залишок у символ
    push dx                     ; Зберегти символ
    inc ecx                     ; Збільшити лічильник цифр
    inc dx                      ; Перевірити залишок
    test ax, ax                 ; Перевірити, чи залишилося число
    jnz m2                      ; Якщо так, повторити
m3:
    pop ax                      ; Отримати символ
    int 29h                     ; Вивести символ
    loop m3                     ; Повторити для всіх цифр
    ret                         ; Повернутися з процедури
print_number endp

; Парсинг числа з input_buffer
parse_input proc
    xor cx, cx                  ; Очистити CX
    mov cl, input_buffer[1]     ; Завантажити довжину введення
    mov num, 0                  ; Скинути результат
    mov bx, 2                   ; Індекс першого символу в буфері
    mov is_negstive, 0          ; Скинути прапор від’ємного числа
parse_loop:
    xor ax, ax                  ; Очистити AX
    mov al, [input_buffer+bx]   ; Завантажити символ
    cmp ax, 'q'                 ; Перевірити на символ завершення
    je end_                     ; Якщо 'q', завершити
    cmp ax, '0'                 ; Перевірити, чи символ < '0'
    jl is_minus                 ; Якщо так, перевірити на мінус
    cmp ax, '9'                 ; Перевірити, чи символ > '9'
    jg error1                   ; Якщо так, помилка
    jmp cont                    ; Продовжити обробку
is_minus:
    cmp ax, '-'                 ; Перевірити, чи символ є мінусом
    jne error1                  ; Якщо ні, помилка
    je is_first                 ; Якщо так, перевірити позицію
is_first:
    cmp cx, input_len           ; Перевірити, чи мінус на початку
    mov is_negstive, 1          ; Встановити прапор від’ємного числа
    inc bx                      ; Перейти до наступного символу
    mov al, [input_buffer+bx]   ; Завантажити наступний символ
    dec cx                      ; Зменшити лічильник
    jz error1                   ; Якщо кінець, помилка
cont:
    mov curr, ax                ; Зберегти поточний символ
    mov eax, num                ; Завантажити поточне число
    mov dx, 10                  ; Помножити на 10
    mul dx                      ; Виконати множення
    jnc succ1                   ; Якщо без переповнення, продовжити
error2:
    mov ax, 2                   ; Повернути код помилки діапазону
    ret                         ; Повернутися з процедури
succ1:
    mov num, eax                ; Зберегти проміжний результат
    mov ax, curr                ; Завантажити символ
    sub ax, '0'                 ; Перетворити символ у цифру
    mov edx, num                ; Завантажити поточне число
    add dx, ax                  ; Додати нову цифру
    jc error2                   ; Якщо переповнення, помилка
    mov num, edx                ; Зберегти результат
    inc bx                      ; Перейти до наступного символу
    dec cx                      ; Зменшити лічильник
    cmp cx, 0                   ; Перевірити, чи кінець
    jg parse_loop               ; Якщо ні, повторити
    jmp end1                    ; Завершити обробку
error1:
    mov ax, 1                   ; Повернути код помилки формату
    ret                         ; Повернутися з процедури
end1:
    cmp is_negstive, 0          ; Перевірити, чи число від’ємне
    mov eax, num                ; Завантажити число
    mov inp, eax                ; Зберегти вхідне число
    je end2                     ; Якщо не від’ємне, завершити
    or eax, eax                 ; Перевірити число
    neg eax                     ; Змінити знак
    cmp eax, INT_MIN            ; Перевірити на переповнення
    jl error2                   ; Якщо переповнення, помилка
    mov num, eax                ; Зберегти від’ємне число
end2:
    mov ax, 0                   ; Повернути код успіху
    ret                         ; Повернутися з процедури
parse_input endp

end main                        ; Кінець програми