; Оголошення сегменту стеку
STACK_SEG SEGMENT PARA STACK 'STACK'
    DB 64 DUP(0)            ; Резервування 64 байтів для стеку, заповнених нулями
STACK_SEG ENDS              ; Кінець сегменту стеку

; Оголошення сегменту даних
DATA_SEG SEGMENT PARA 'DATA'
    prompt_msg       DB 'Program computes Z based on x and y.$'              ; Повідомлення про призначення програми
    expr1_msg        DB 'Z = 34 * x^2 / (y * (x - y)), if y > 0 and x != y$' ; Формула для випадку y > 0 і x != y
    expr2_msg        DB 'Z = (1 - x) / (1 + x), if y = 0$'                   ; Формула для випадку y = 0
    expr3_msg        DB 'Z = x^2 * y^2, if y < 0$'                           ; Формула для випадку y < 0
    input_x_prompt   DB 'Enter x [-32768; 65535] (or "q" to quit): $'        ; Запит введення x
    input_y_prompt   DB 'Enter y [-32768; 65535] (or "q" to quit): $'        ; Запит введення y
    input_buffer     DB 8                                                    ; Максимальна довжина буфера введення (8 символів)
                     DB ?                                                    ; Фактична кількість введених символів
    input_string     DB 8 DUP('$')                                           ; Буфер для зберігання введеного рядка
    result_msg       DB 'Result: $'                                          ; Повідомлення для виведення результату
    fraction_msg     DB ' and $'                                             ; Текст для дробової частини
    fraction_slash   DB '/$'                                                 ; Символ дробу
    invalid_input_msg DB 'Invalid input! Please enter a valid number.$'       ; Повідомлення про некоректне введення
    out_of_range_msg DB 'Number out of range!$'                              ; Повідомлення про вихід за межі діапазону
    div_overflow_msg DB 'Error: Arithmetic overflow or division by zero!$'    ; Повідомлення про арифметичну помилку
    newline          DB 0Dh, 0Ah, '$'                                        ; Символи нового рядка (CR, LF)

    ALIGN 2                                                                  ; Вирівнювання даних на парну адресу
    x_value          DW 0                                                    ; Змінна для зберігання x
    y_value          DW 0                                                    ; Змінна для зберігання y
    result           DW 0                                                    ; Змінна для зберігання результату
    remainder        DW 0                                                    ; Змінна для зберігання остачі
    denominator      DW 0                                                    ; Змінна для зберігання знаменника
    show_fraction    DB 0                                                    ; Прапор для відображення дробу
    is_negative      DB 0                                                    ; Прапор для від’ємного числа
DATA_SEG ENDS                                                                ; Кінець сегменту даних

; Оголошення сегменту коду
CODE_SEG SEGMENT PARA 'CODE'
.386                                                                         ; Використання інструкцій для процесора 80386
    ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:STACK_SEG                            ; Прив’язка сегментів до регістрів

; Головна процедура
MAIN PROC FAR
    MOV AX, DATA_SEG                    ; Завантаження адреси сегменту даних у AX
    MOV DS, AX                          ; Ініціалізація регістру DS сегментом даних

program_start:                          ; Мітка початку програми
    CALL print_newline                  ; Виклик процедури виведення нового рядка
    CALL display_menu                   ; Виклик процедури відображення меню

    CALL print_newline                  ; Виведення нового рядка
    MOV DX, OFFSET input_x_prompt       ; Завантаження адреси запиту введення x
    CALL print_string                   ; Виведення запиту
    CALL get_and_validate_input         ; Отримання та перевірка введення
    JC invalid_input_handler            ; Якщо помилка (CF=1), перехід до обробки
    MOV x_value, AX                     ; Збереження введеного x

    CALL print_newline                  ; Виведення нового рядка
    MOV DX, OFFSET input_y_prompt       ; Завантаження адреси запиту введення y
    CALL print_string                   ; Виведення запиту
    CALL get_and_validate_input         ; Отримання та перевірка введення
    JC invalid_input_handler            ; Якщо помилка, перехід до обробки
    MOV y_value, AX                     ; Збереження введеного y

    CALL compute_expression             ; Обчислення виразу
    JC arith_error_handler              ; Якщо арифметична помилка, перехід до обробки

    CALL display_result                 ; Виведення результату
    JMP program_start                   ; Повторення циклу програми

invalid_input_handler:                  ; Обробка некоректного введення
    CALL print_newline                  ; Виведення нового рядка
    MOV DX, OFFSET invalid_input_msg    ; Завантаження адреси повідомлення про помилку
    CALL print_string                   ; Виведення повідомлення
    CALL print_newline                  ; Виведення нового рядка
    JMP program_start                   ; Повернення до початку програми

arith_error_handler:                    ; Обробка арифметичної помилки
    CALL print_newline                  ; Виведення нового рядка
    MOV DX, OFFSET div_overflow_msg     ; Завантаження адреси повідомлення про помилку
    CALL print_string                   ; Виведення повідомлення
    CALL print_newline                  ; Виведення нового рядка
    JMP program_start                   ; Повернення до початку програми

exit_program:                           ; Завершення програми
    MOV AX, 4C00h                       ; Код завершення програми (DOS INT 21h)
    INT 21h                             ; Виклик переривання DOS
MAIN ENDP                               ; Кінець головної процедури

; Процедура відображення меню
display_menu PROC
    MOV DX, OFFSET prompt_msg           ; Завантаження адреси повідомлення про програму
    CALL print_string                   ; Виведення повідомлення
    CALL print_newline                  ; Виведення нового рядка

    MOV DX, OFFSET expr1_msg            ; Завантаження адреси першої формули
    CALL print_string                   ; Виведення формули
    CALL print_newline                  ; Виведення нового рядка

    MOV DX, OFFSET expr2_msg            ; Завантаження адреси другої формули
    CALL print_string                   ; Виведення формули
    CALL print_newline                  ; Виведення нового рядка

    MOV DX, OFFSET expr3_msg            ; Завантаження адреси третьої формули
    CALL print_string                   ; Виведення формули
    CALL print_newline                  ; Виведення нового рядка
    RET                                 ; Повернення з процедури
display_menu ENDP                       ; Кінець процедури

; Процедура отримання та перевірки введення
get_and_validate_input PROC
    MOV BYTE PTR [is_negative], 0       ; Скидання прапорця від’ємного числа
    MOV DX, OFFSET input_buffer         ; Завантаження адреси буфера введення
    MOV AH, 0Ah                         ; Код функції DOS для строкового введення
    INT 21h                             ; Виклик переривання DOS

    ; Додавання '$' у кінець введеного рядка
    LEA DI, input_string                ; Завантаження адреси input_string
    MOV CL, [input_buffer + 1]          ; Отримання кількості введених символів
    XOR CH, CH                          ; Очищення старшого байта CX
    ADD DI, CX                          ; Переміщення до кінця введеного рядка
    MOV BYTE PTR [DI], '$'              ; Додавання термінатора рядка

    ; Перевірка на введення "q" для виходу
    MOV SI, OFFSET input_string         ; Завантаження адреси введеного рядка
    MOV BL, [SI]                        ; Отримання першого символу
    CMP BL, 'q'                         ; Порівняння з 'q'
    JE exit_program                     ; Якщо 'q', вихід з програми

    ; Ініціалізація регістрів
    XOR AX, AX                          ; Очищення AX для накопичення результату
    XOR CX, CX                          ; Очищення CX
    MOV SI, 10                          ; Основа системи числення (10)
    MOV CL, [input_buffer + 1]          ; Кількість введених символів
    LEA DI, input_string                ; Завантаження адреси введеного рядка

    ; Перевірка на знак мінус
    CMP BYTE PTR [DI], '-'              ; Порівняння першого символу з '-'
    JNE Convert                         ; Якщо не мінус, перехід до конвертації
    MOV BYTE PTR [is_negative], 1       ; Встановлення прапорця від’ємного числа
    DEC CX                              ; Зменшення лічильника символів
    INC DI                              ; Перехід до наступного символу

    XOR DX, DX                          ; DX=0 — позначка, що цифр ще не було

Convert:                                ; Початок конвертації
ConvertLoop:                            ; Цикл конвертації
    OR CX, CX                           ; Перевірка, чи є ще символи
    JZ EndConvert                       ; Якщо немає, завершення конвертації

    MOV BL, [DI]                        ; Отримання поточного символу
    CMP BL, '0'                         ; Перевірка, чи символ менше '0'
    JB invalid                          ; Якщо так, помилка
    CMP BL, '9'                         ; Перевірка, чи символ більше '9'
    JA invalid                          ; Якщо так, помилка

    SUB BL, '0'                         ; Перетворення ASCII в число
    MUL SI                              ; AX = AX * 10
    JC out_of_range                     ; Якщо переповнення, помилка
    ADD AX, BX                          ; Додавання нової цифри
    JC out_of_range                     ; Якщо переповнення, помилка

    INC DI                              ; Перехід до наступного символу
    DEC CX                              ; Зменшення лічильника
    MOV DX, 1                           ; Позначка, що була цифра
    JMP ConvertLoop                     ; Повторення циклу

EndConvert:                             ; Завершення конвертації
    CMP DX, 1                           ; Перевірка, чи були цифри
    JNE invalid                         ; Якщо ні, помилка

    ; Перевірка меж
    CMP BYTE PTR [is_negative], 1       ; Перевірка, чи число від’ємне
    JNE CheckPositive                   ; Якщо ні, перевірка додатнього
    CMP AX, 32768                       ; Перевірка, чи не менше -32768
    JA out_of_range                     ; Якщо більше, помилка
    NEG AX                              ; Зміна знаку на від’ємний
    JMP Done                            ; Завершення

CheckPositive:                          ; Перевірка додатнього числа
    CMP AX, 65535                       ; Перевірка, чи не більше 65535
    JA out_of_range                     ; Якщо більше, помилка

Done:                                   ; Успішне завершення
    CLC                                 ; Скидання прапорця помилки
    RET                                 ; Повернення

invalid:                                ; Помилка введення
    STC                                 ; Встановлення прапорця помилки
    RET                                 ; Повернення

out_of_range:                           ; Помилка діапазону
    STC                                 ; Встановлення прапорця помилки
    RET                                 ; Повернення
get_and_validate_input ENDP             ; Кінець процедури

; Процедура обчислення виразу
compute_expression PROC
    MOV AX, x_value                     ; Завантаження x
    MOV BX, y_value                     ; Завантаження y
    MOV show_fraction, 0                ; Скидання прапорця дробу
    MOV result, 0                       ; Ініціалізація результату
    MOV remainder, 0                    ; Ініціалізація остачі
    MOV denominator, 1                  ; Ініціалізація знаменника

    ; Перевірка умов
    CMP BX, 0                           ; Порівняння y з 0
    JG check_x_not_y                    ; Якщо y > 0, перевірка x != y
    JE check_y_zero                     ; Якщо y = 0, перехід до відповідного випадку
    JMP check_y_negative                ; Якщо y < 0, перехід до відповідного випадку

check_x_not_y:                          ; Перевірка x != y
    CMP AX, BX                          ; Порівняння x і y
    JE set_default                      ; Якщо x = y, встановлення результату 0
    ; Випадок 1: Z = 34 * x^2 / (y * (x - y))
    MOV CX, AX                          ; CX = x
    IMUL CX                             ; AX = x^2
    JO compute_overflow                 ; Якщо переповнення, помилка
    CMP AX, 964                         ; 32767 / 34 ≈ 964
    JG compute_overflow                 ; Якщо більше, помилка
    MOV DX, 34                          ; DX = 34
    IMUL DX                             ; AX = 34 * x^2
    JO compute_overflow                 ; Якщо переповнення, помилка
    PUSH AX                             ; Збереження 34 * x^2
    MOV AX, BX                          ; AX = y
    SUB CX, BX                          ; CX = x - y
    JE compute_overflow                 ; Якщо x - y = 0, помилка
    IMUL CX                             ; AX = y * (x - y)
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV denominator, AX                 ; Збереження знаменника
    CMP AX, 0                           ; Перевірка на нуль
    JE compute_overflow                 ; Якщо нуль, помилка
    POP AX                              ; Відновлення 34 * x^2
    CWD                                 ; Розширення знаку для ділення
    IDIV denominator                    ; AX = 34 * x^2 / (y * (x - y))
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV result, AX                      ; Збереження результату
    MOV remainder, DX                   ; Збереження остачі
    MOV show_fraction, 1                ; Встановлення прапорця дробу
    CLC                                 ; Скидання прапорця помилки
    JMP compute_exit                    ; Завершення

check_y_zero:                           ; Випадок y = 0
    ; Z = (1 - x) / (1 + x)
    MOV AX, 1                           ; AX = 1
    SUB AX, x_value                     ; AX = 1 - x
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV CX, 1                           ; CX = 1
    ADD CX, x_value                     ; CX = 1 + x
    JO compute_overflow                 ; Якщо переповнення, помилка
    CMP CX, 0                           ; Перевірка на нуль
    JE compute_overflow                 ; Якщо нуль, помилка
    MOV denominator, CX                 ; Збереження знаменника
    CWD                                 ; Розширення знаку
    IDIV CX                             ; AX = (1 - x) / (1 + x)
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV result, AX                      ; Збереження результату
    MOV remainder, DX                   ; Збереження остачі
    MOV show_fraction, 1                ; Встановлення прапорця дробу
    CLC                                 ; Скидання прапорця помилки
    JMP compute_exit                    ; Завершення

check_y_negative:                       ; Випадок y < 0
    ; Z = x^2 * y^2
    MOV AX, x_value                     ; AX = x
    IMUL AX                             ; AX = x^2
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV CX, AX                          ; CX = x^2
    MOV AX, y_value                     ; AX = y
    IMUL AX                             ; AX = y^2
    JO compute_overflow                 ; Якщо переповнення, помилка
    ; Перевірка меж
    CMP CX, 181                         ; Приблизно sqrt(32767)
    JA compute_overflow                 ; Якщо більше, помилка
    CMP AX, 181                         ; Приблизно sqrt(32767)
    JA compute_overflow                 ; Якщо більше, помилка
    IMUL CX                             ; AX = x^2 * y^2
    JO compute_overflow                 ; Якщо переповнення, помилка
    MOV result, AX                      ; Збереження результату
    MOV remainder, 0                    ; Остача = 0
    CLC                                 ; Скидання прапорця помилки
    JMP compute_exit                    ; Завершення

set_default:                            ; Випадок x = y
    MOV result, 0                       ; Результат = 0
    MOV remainder, 0                    ; Остача = 0
    CLC                                 ; Скидання прапорця помилки
    JMP compute_exit                    ; Завершення

compute_overflow:                       ; Обробка переповнення
    STC                                 ; Встановлення прапорця помилки
    JMP compute_exit                    ; Завершення

compute_exit:                           ; Завершення процедури
    RET                                 ; Повернення
compute_expression ENDP                 ; Кінець процедури

; Процедура виведення результату
display_result PROC
    CALL print_newline                  ; Виведення нового рядка
    MOV DX, OFFSET result_msg           ; Завантаження адреси повідомлення результату
    CALL print_string                   ; Виведення повідомлення

    MOV BX, result                      ; Завантаження результату
    CALL OutputNum                      ; Виведення числа

    CMP show_fraction, 1                ; Перевірка прапорця дробу
    JNE skip_fraction                   ; Якщо не потрібно, пропуск
    CMP remainder, 0                    ; Перевірка, чи є остача
    JE skip_fraction                    ; Якщо немає, пропуск

    MOV DX, OFFSET fraction_msg         ; Завантаження адреси тексту дробу
    CALL print_string                   ; Виведення тексту

    MOV BX, remainder                   ; Завантаження остачі
    CALL OutputNum                      ; Виведення остачі

    MOV DX, OFFSET fraction_slash       ; Завантаження адреси символу дробу
    CALL print_string                   ; Виведення символу

    MOV BX, denominator                 ; Завантаження знаменника
    CALL OutputNum                      ; Виведення знаменника

skip_fraction:                          ; Пропуск дробової частини
    CALL print_newline                  ; Виведення нового рядка
    RET                                 ; Повернення
display_result ENDP                     ; Кінець процедури

; Процедура виведення числа
OutputNum PROC
    CMP BX, 0                           ; Перевірка, чи число 0
    JE print_zero                       ; Якщо 0, виведення нуля

    OR BX, BX                           ; Перевірка знаку
    JNS positive                        ; Якщо додатнє, перехід
    MOV DL, '-'                         ; Завантаження символу мінус
    MOV AH, 02h                         ; Код функції DOS для виведення символу
    INT 21h                             ; Виведення мінуса
    NEG BX                              ; Зміна знаку числа

positive:                               ; Виведення додатнього числа
    MOV AX, BX                          ; AX = число
    XOR CX, CX                          ; Очищення лічильника цифр
    MOV BX, 10                          ; Основа системи числення

    TEST AX, AX                         ; Перевірка на нуль
    JNZ print_num_loop                  ; Якщо не нуль, виведення цифр

print_zero:                             ; Виведення нуля
    MOV DL, '0'                         ; Завантаження символу '0'
    MOV AH, 02h                         ; Код функції DOS
    INT 21h                             ; Виведення символу
    JMP end_print                       ; Завершення

print_num_loop:                         ; Цикл виведення цифр
    XOR DX, DX                          ; Очищення DX
    DIV BX                              ; Ділення AX на 10, остача в DX
    ADD DL, '0'                         ; Перетворення цифри в ASCII
    PUSH DX                             ; Збереження цифри
    INC CX                              ; Збільшення лічильника цифр
    TEST AX, AX                         ; Перевірка, чи залишились цифри
    JNZ print_num_loop                  ; Якщо так, продовження

print_loop:                             ; Цикл виведення збережених цифр
    POP DX                              ; Отримання цифри
    MOV AH, 02h                         ; Код функції DOS
    INT 21h                             ; Виведення цифри
    LOOP print_loop                     ; Повторення для всіх цифр

end_print:                              ; Завершення виведення
    RET                                 ; Повернення
OutputNum ENDP                          ; Кінець процедури

; Процедура виведення рядка
print_string PROC
    MOV AH, 09h                         ; Код функції DOS для виведення рядка
    INT 21h                             ; Виклик переривання
    RET                                 ; Повернення
print_string ENDP                       ; Кінець процедури

; Процедура виведення нового рядка
print_newline PROC
    MOV DX, OFFSET newline              ; Завантаження адреси символів нового рядка
    MOV AH, 09h                         ; Код функції DOS
    INT 21h                             ; Виведення
    RET                                 ; Повернення
print_newline ENDP                      ; Кінець процедури

CODE_SEG ENDS                           ; Кінець сегменту коду

END MAIN                                ; Точка входу в програму