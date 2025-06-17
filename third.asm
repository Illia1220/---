STACK_SEG SEGMENT PARA STACK 'STACK'
    DB 64 DUP(0)
STACK_SEG ENDS

DATA_SEG SEGMENT PARA 'DATA'
    prompt_msg       DB 'Program computes Z based on x and y.$'
    expr1_msg        DB 'Z = 34 * x^2 / (y * (x - y)), if y > 0 and x != y$'
    expr2_msg        DB 'Z = (1 - x) / (1 + x), if y = 0$'
    expr3_msg        DB 'Z = x^2 * y^2, if y < 0$'
    input_x_prompt   DB 'Enter x [-16384; 32767] (or "q" to quit): $'
    input_y_prompt   DB 'Enter y [-16384; 32767] (or "q" to quit): $'
    input_buffer     DB 8
                     DB ?
    input_string     DB 8 DUP('$')
    result_msg       DB 'Result: $'
    fraction_msg     DB ' and $'
    fraction_slash   DB '/$'
    invalid_input_msg DB 'Invalid input! Please enter a valid number.$'
    out_of_range_msg DB 'Number out of range!$'
    div_overflow_msg DB 'Error: Arithmetic overflow or division by zero!$'
    newline          DB 0Dh, 0Ah, '$'

    ALIGN 2
    x_value          DW 0
    y_value          DW 0
    result           DW 0
    remainder        DW 0
    denominator      DW 0
    show_fraction    DB 0
    is_negative      DB 0
DATA_SEG ENDS

CODE_SEG SEGMENT PARA 'CODE'
    ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:STACK_SEG

MAIN PROC FAR
    MOV AX, DATA_SEG
    MOV DS, AX

program_start:
    CALL print_newline
    CALL display_menu

    CALL print_newline
    MOV DX, OFFSET input_x_prompt
    CALL print_string
    CALL get_and_validate_input
    JC invalid_input_handler
    MOV x_value, AX

    CALL print_newline
    MOV DX, OFFSET input_y_prompt
    CALL print_string
    CALL get_and_validate_input
    JC invalid_input_handler
    MOV y_value, AX

    CALL compute_expression
    JC arith_error_handler

    CALL display_result
    JMP program_start

invalid_input_handler:
    CALL print_newline
    MOV DX, OFFSET invalid_input_msg
    CALL print_string
    CALL print_newline
    JMP program_start

arith_error_handler:
    CALL print_newline
    MOV DX, OFFSET div_overflow_msg
    CALL print_string
    CALL print_newline
    JMP program_start

exit_program:
    MOV AX, 4C00h
    INT 21h
MAIN ENDP

display_menu PROC
    MOV DX, OFFSET prompt_msg
    CALL print_string
    CALL print_newline

    MOV DX, OFFSET expr1_msg
    CALL print_string
    CALL print_newline

    MOV DX, OFFSET expr2_msg
    CALL print_string
    CALL print_newline

    MOV DX, OFFSET expr3_msg
    CALL print_string
    CALL print_newline
    RET

display_menu ENDP

; ----- Ввід числа, парсинг ASCII → число, перевірка -----
get_and_validate_input PROC
    MOV BYTE PTR [is_negative], 0         ; Скидаємо прапорець знаку
    MOV DX, OFFSET input_buffer
    MOV AH, 0Ah
    INT 21h                               ; DOS-функція: строковий ввід у input_buffer

    ; Додаємо '$' наприкінці введеного рядка для коректного завершення
    LEA DI, input_string
    MOV CL, [input_buffer + 1]            ; К-ть введених символів (без Enter)
    XOR CH, CH
    ADD DI, CX
    MOV BYTE PTR [DI], '$'                ; Кінець рядка

    ; Якщо користувач ввів "q" — завершити програму
    MOV SI, OFFSET input_string
    MOV BL, [SI]
    CMP BL, 'q'
    JE exit_program

    ; Ініціалізуємо регістри для перетворення ASCII у десяткове число
    XOR AX, AX                            ; AX буде результатом
    XOR CX, CX
    MOV SI, 10                            ; Основа системи числення
    MOV CL, [input_buffer + 1]
    LEA DI, input_string

    ; Перевірка на знак мінус (перший символ)
    CMP BYTE PTR [DI], '-'
    JNE Convert
    MOV BYTE PTR [is_negative], 1         ; Якщо є '-', встановлюємо прапорець знаку
    DEC CX                                ; Зменшуємо кількість оброблюваних символів
    INC DI                                ; Пропускаємо мінус

    ; DX — прапорець: чи було хоч одну цифру
    XOR DX, DX         ; DX=0 — не було жодної цифри, DX=1 — хоча б одна цифра

Convert:
ConvertLoop:
    OR CX, CX
    JZ EndConvert                         ; Якщо CX=0 — кінець обробки

    MOV BL, [DI]
    CMP BL, '0'
    JB invalid                            ; Якщо символ < '0' — помилка
    CMP BL, '9'
    JA invalid                            ; Якщо символ > '9' — помилка

    SUB BL, '0'                           ; ASCII → число
    MUL SI                                ; AX = AX * 10
    JC out_of_range                       ; Перевірка переповнення при множенні

    ADD AX, BX                            ; AX = AX + цифра
    JC out_of_range                       ; Перевірка переповнення при додаванні

    INC DI
    DEC CX
    MOV DX, 1                             ; Було введено хоча б одну цифру!
    JMP ConvertLoop

EndConvert:
    CMP DX, 1
    JNE invalid                           ; Якщо не було цифр — помилка

    ; Перевірка на вихід за допустимі межі
    CMP BYTE PTR [is_negative], 1
    JNE CheckPositive
    CMP AX, 16384                        ; Модуль від'ємного числа ≤ 32768
    JA out_of_range
    NEG AX                                ; Робимо число від’ємним
    JMP Done

CheckPositive:
    CMP AX, 32767                         ; Для додатніх: не більше 32767
    JA out_of_range

Done:
    CLC                                   ; CF = 0 (успішно)
    RET

invalid:
    STC                                   ; CF = 1 (помилка)
    RET

out_of_range:
    STC
    RET
get_and_validate_input ENDP

compute_expression PROC
    MOV AX, x_value                       ; AX = x
    MOV BX, y_value                       ; BX = y
    MOV show_fraction, 0                  ; Reset fraction flag
    MOV result, 0                         ; Initialize result
    MOV remainder, 0                      ; Initialize remainder
    MOV denominator, 1                    ; Initialize denominator

    ; Check condition: y > 0
    CMP BX, 0
    JG check_x_not_y                     ; If y > 0, check x != y
    JE check_y_zero                      ; If y = 0, go to y = 0 case
    JMP check_y_negative                 ; If y < 0, go to y < 0 case

check_x_not_y:
    CMP AX, BX
    JE set_default                       ; If x == y, set default (Z = 0)
    ; Case 1: Z = 34x^2 / (y * (x - y))
    MOV CX, AX                           ; CX = x
    IMUL CX                              ; AX = x^2
    JO compute_overflow                  ; Check for overflow
    MOV DX, 34
    IMUL DX                              ; AX = 34x^2
    JO compute_overflow                  ; Check for overflow
    PUSH AX                              ; Save 34x^2
    MOV AX, BX                           ; AX = y
    SUB CX, BX                           ; CX = x - y
    IMUL CX                              ; AX = y * (x - y)
    JO compute_overflow                  ; Check for overflow
    MOV denominator, AX                  ; Denominator = y * (x - y)
    POP AX                               ; Restore 34x^2
    CWD
    IDIV denominator                     ; AX = 34x^2 / (y * (x - y)), DX = remainder
    MOV result, AX
    MOV remainder, DX
    MOV show_fraction, 1                 ; Show fraction if remainder exists
    CLC
    JMP compute_exit

check_y_zero:
    ; Case 2: Z = (1 - x) / (1 + x)
    MOV AX, 1
    SUB AX, x_value                      ; AX = 1 - x
    MOV CX, 1
    ADD CX, x_value                      ; CX = 1 + x
    MOV denominator, CX
    CWD
    IDIV CX                              ; AX = (1 - x) / (1 + x), DX = remainder
    MOV result, AX
    MOV remainder, DX
    MOV show_fraction, 1                 ; Show fraction if remainder exists
    CLC
    JMP compute_exit

check_y_negative:
    ; Case 3: Z = x^2 * y^2
    MOV AX, x_value
    IMUL AX                              ; AX = x^2
    JO compute_overflow                  ; Check for overflow
    MOV CX, AX                           ; CX = x^2
    MOV AX, y_value
    IMUL AX                              ; AX = y^2
    JO compute_overflow                  ; Check for overflow
    IMUL CX                              ; AX = x^2 * y^2
    JO compute_overflow                  ; Check for overflow
    MOV result, AX
    MOV remainder, 0
    CLC
    JMP compute_exit

set_default:
    MOV result, 0                        ; Default case: Z = 0 when y > 0 and x = y
    MOV remainder, 0
    CLC
    JMP compute_exit

compute_overflow:
    MOV AX, 2                            ; AX=2 as error code
    STC                                  ; CF = 1 (error)
    JMP compute_exit

compute_exit:
    RET
compute_expression ENDP


; ----- Вивід результату (і дробової частини, якщо потрібно) -----
display_result PROC
    CALL print_newline
    MOV DX, OFFSET result_msg
    CALL print_string

    MOV BX, result
    CALL OutputNum                     ; Вивід основної (цілої) частини

    CMP show_fraction, 1                  ; Чи потрібно виводити дріб?
    JNE skip_fraction
    CMP remainder, 0
    JE skip_fraction

    MOV DX, OFFSET fraction_msg
    CALL print_string

    MOV BX, remainder                     ; Вивід залишку (чисельник дробу)
    CALL OutputNum

    MOV DX, OFFSET fraction_slash
    CALL print_string

    MOV BX, denominator                   ; Вивід знаменника
    CALL OutputNum

skip_fraction:
    CALL print_newline
    RET
display_result ENDP

; ----- Друк числа у десятковому вигляді -----
OutputNum PROC
    CMP BX, 0
    JE print_zero

    OR BX, BX
    JNS positive
    MOV DL, '-'
    MOV AH, 02h
    INT 21h
    NEG BX

positive:
    MOV AX, BX
    XOR CX, CX
    MOV BX, 10                            ; Ділимо по розрядах на 10

    TEST AX, AX
    JNZ print_num_loop

print_zero:
    MOV DL, '0'
    MOV AH, 02h
    INT 21h
    JMP end_print

print_num_loop:
    XOR DX, DX
    DIV BX                                ; Ділення AX на 10, DX=залишок (остання цифра)
    ADD DL, '0'                           ; Перетворюємо у ASCII
    PUSH DX                               ; Зберігаємо цифру у стеку
    INC CX
    TEST AX, AX
    JNZ print_num_loop

print_loop:
    POP DX
    MOV AH, 02h
    INT 21h                               ; Виводимо чергову цифру
    LOOP print_loop

end_print:
    RET
OutputNum ENDP

; ----- Вивід тексту з пам'яті -----
print_string PROC
    MOV AH, 09h
    INT 21h
    RET
print_string ENDP

; ----- Вивід переходу на новий рядок -----
print_newline PROC
    MOV DX, OFFSET newline
    MOV AH, 09h
    INT 21h
    RET
print_newline ENDP

CODE_SEG ENDS

END MAIN