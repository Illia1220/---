; Макрос для очищення екрана
ClearScreen MACRO
MOV AH, 06h          ; Функція прокрутки екрана вгору
MOV AL, 0            ; Очистити весь екран
MOV BH, 07h          ; Атрибут (білий текст на чорному фоні)
MOV CX, 0            ; Верхній лівий кут (0,0)
MOV DX, 184Fh        ; Нижній правий кут (24,79)
INT 10h              ; Виклик BIOS
MOV AH, 02h          ; Встановити позицію курсора
MOV BH, 0            ; Сторінка 0
MOV DX, 0            ; Позиція (0,0)
INT 10h              ; Виклик BIOS
ENDM

STSEG SEGMENT PARA STACK 'STACK'
DB 64 DUP ('STACK')             ; Сегмент стека, 64 байта
STSEG ENDS

DSEG SEGMENT PARA PUBLIC 'DATA'
EnterMSG     DB 'Enter number ->: (-32768..65457) + 78$' ; Оновлене повідомлення з новими межами
IncorrectMSG DB 'Incorrect number$'                       ; Повідомлення про помилку введення
OverflowMSG  DB 'Number overflow$'                        ; Повідомлення про переповнення
Buffer       DB 7, ?, 7 DUP ('?')                        ; Буфер введення: довжина, введена довжина, символи
Result       DW 0                                        ; Зберігаємо результат
SignFlag     DB 0                                        ; Флаг знака: 0 = позитивне, 1 = негативне
DSEG ENDS

CSEG SEGMENT PARA PUBLIC 'CODE'

MAIN PROC FAR
ASSUME CS:CSEG, DS:DSEG, SS:STSEG

PUSH DS
MOV AX, DSEG
MOV DS, AX                    ; Встановлюємо сегмент даних
ClearScreen                   ; Очищення екрана перед початком роботи

StartInput:
CALL EnterNum                ; Введення числа і перевірка

DoAdd:
ADD AX, 78                   ; Додаємо 78
JO OverflowErr              ; Якщо переповнення — обробка помилки
JMP StoreResult

StoreResult:
MOV Result, AX              ; Зберігаємо результат у змінну

OutputResult:
CALL WriteLine              ; Перехід на нову строку
CALL OutputNum              ; Виведення результату
CALL WriteLine              ; Перехід на нову строку
JMP StartInput              ; Повторити все заново

OverflowErr:
LEA DX, OverflowMSG
MOV AH, 9
INT 21h                     ; Виводимо повідомлення про переповнення
CALL WriteLine
MOV BYTE PTR [SignFlag], 0  ; Скидаємо флаг знака
JMP StartInput

MAIN ENDP

; Печать нової строки
WriteLine PROC
MOV DL, 10

MOV AH, 2
INT 21h
MOV DL, 13

MOV AH, 2
INT 21h
RET
WriteLine ENDP

; Введення і перетворення числа
EnterNum PROC
Input:
MOV BYTE PTR [SignFlag], 0   ; Скидаємо флаг знака
LEA DX, EnterMSG
MOV AH, 9
INT 21h                      ; Виводимо запрошення до введення
CALL WriteLine

LEA DX, Buffer
MOV AH, 10
INT 21h                      ; Зчитування строки DOS-функцією

; Візуальний вивід введеної строки
LEA DI, Buffer + 2
MOV CL, [Buffer + 1]
ADD DI, CX
MOV BYTE PTR [DI], '$'
LEA DX, Buffer + 2
MOV AH, 9
INT 21h
CALL WriteLine

; --- Перетворення ASCII → число в AX ---
XOR AX, AX                   ; AX = 0 (накопичувач результату)
XOR CX, CX
MOV SI, 10                   ; Основа системи числення (10)
MOV CL, [Buffer + 1]         ; Кількість символів
LEA DI, Buffer + 2           ; DI вказує на перший введений символ

CMP BYTE PTR [DI], '-'       ; Перевірка знака
JNE Convert
MOV BYTE PTR [SignFlag], 1   ; Встановлюємо флаг мінуса
DEC CX
INC DI

; --- Цикл конвертації строки в число ---
Convert:
ConvertLoop:
OR CX, CX
JZ EndConvert
MOV BL, [DI]                 ; Отримуємо поточний символ
CMP BL, '0'
JB IncorrectErr
CMP BL, '9'
JA IncorrectErr
SUB BL, '0'                  ; ASCII → число (наприклад, '5' → 5)

MUL SI                       ; AX = AX * 10
JC OverflowErr1
ADD AX, BX                   ; Додаємо поточну цифру до результату
JC OverflowErr1

INC DI
DEC CX
JMP ConvertLoop

EndConvert:
CMP BYTE PTR [SignFlag], 1
JNE CheckPositive
CMP AX, 32768                ; Перевірка для від’ємних чисел (-32768)
JA IncorrectErr
NEG AX                       ; Робимо результат від’ємним
JMP CheckRange

CheckPositive:
CMP AX, 65457                ; Перевірка верхньої межі (65535 - 78)
JA IncorrectErr

CheckRange:
CMP AX, -32768               ; Перевірка нижньої межі
JL IncorrectErr

; --- Перевірка на переповнення при додаванні 78 ---
CMP BYTE PTR [SignFlag], 1
JE CheckNegOverflow
CMP AX, 65457                ; Перевірка для позитивних чисел
JA OverflowErr1
JMP DoneInput

CheckNegOverflow:
CMP AX, -32768         ; Перевірка для від’ємних чисел
JL OverflowErr1

DoneInput:
RET

IncorrectErr:
LEA DX, IncorrectMSG
MOV AH, 9
INT 21h
CALL WriteLine
JMP Input

OverflowErr1:
LEA DX, OverflowMSG
MOV AH, 9
INT 21h
CALL WriteLine
JMP Input
EnterNum ENDP

; Виведення числа, включаючи знак
OutputNum PROC NEAR
MOV BX, Result
CMP BYTE PTR [SignFlag], 0
JNE PrintSigned

; --- Виведення позитивного числа ---
MOV AX, BX
XOR CX, CX
MOV BX, 10

ULoop:
XOR DX, DX
DIV BX

ADD DL, '0'                  ; Число → ASCII символ (5 → '5')

PUSH DX

INC CX
TEST AX, AX
JNZ ULoop

ULoopPrint:
POP AX
INT 29h

LOOP ULoopPrint
RET

; --- Виведення від’ємного числа ---
PrintSigned:
OR BX, BX
JNS PrintSignedPos
MOV AL, '-'
INT 29h
NEG BX

PrintSignedPos:
MOV AX, BX
XOR CX, CX
MOV BX, 10

SLoop:
XOR DX, DX
DIV BX
ADD DL, '0'                  ; Число → ASCII символ (5 → '5')

PUSH DX
INC CX
TEST AX, AX
JNZ SLoop

SLoopPrint:
POP AX
INT 29h

LOOP SLoopPrint
RET
OutputNum ENDP

CSEG ENDS
END MAIN