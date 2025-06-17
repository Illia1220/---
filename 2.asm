STSEG SEGMENT PARA STACK 'STACK'
DB 64 DUP ('STACK')             ; Сегмент стека, 64 байта
STSEG ENDS

DSEG SEGMENT PARA PUBLIC 'DATA'
EnterMSG     DB 'Enter number ->: (-32767..32767) + 78$' ; Сообщение запроса числа
IncorrectMSG DB 'Incorrect number$'                       ; Ошибка некорректного ввода
OverflowMSG  DB 'Number overflow$'                        ; Ошибка переполнения
Buffer       DB 7, ?, 7 DUP ('?')                         ; Буфер ввода: длина, считанная длина, символы
Result       DW 0                                          ; Сохраняем результат
SignFlag     DB 0                                          ; Флаг знака: 0 = положительное, 1 = отрицательное
DSEG ENDS

CSEG SEGMENT PARA PUBLIC 'CODE'

MAIN PROC FAR
ASSUME CS:CSEG, DS:DSEG, SS:STSEG

PUSH DS
MOV AX, DSEG
MOV DS, AX                    ; Устанавливаем сегмент данных

StartInput:
CALL EnterNum                ; Ввод числа и проверка

DoAdd:
ADD AX, 78                   ; Прибавляем 78
JO OverflowErr              ; Если переполнение — обработка ошибки
JMP StoreResult

StoreResult:
MOV Result, AX              ; Сохраняем результат в переменную

OutputResult:
CALL WriteLine              ; Переход на новую строку
CALL OutputNum              ; Вывод результата
CALL WriteLine              ; Переход на новую строку
JMP StartInput              ; Повторить всё заново

OverflowErr:
LEA DX, OverflowMSG
MOV AH, 9
INT 21h                     ; Выводим сообщение о переполнении
CALL WriteLine
MOV BYTE PTR [SignFlag], 0  ; Сброс флага знака
JMP StartInput

MAIN ENDP

;-----------------------
; Печать новой строки
;-----------------------
WriteLine PROC
MOV DL, 10                  ; LF (Line Feed)
MOV AH, 2
INT 21h
MOV DL, 13                  ; CR (Carriage Return)
MOV AH, 2
INT 21h
RET
WriteLine ENDP

;-----------------------
; Ввод и преобразование числа
;-----------------------
EnterNum PROC
Input:
MOV BYTE PTR [SignFlag], 0   ; Сброс флага знака
LEA DX, EnterMSG
MOV AH, 9
INT 21h                      ; Вывод приглашения к вводу
CALL WriteLine

LEA DX, Buffer
MOV AH, 10
INT 21h                      ; Считывание строки DOS-функцией

; Визуальный вывод введённой строки
LEA DI, Buffer + 2
MOV CL, [Buffer + 1]
ADD DI, CX
MOV BYTE PTR [DI], '$'
LEA DX, Buffer + 2
MOV AH, 9
INT 21h
CALL WriteLine

; --- Преобразование ASCII → число в AX ---
XOR AX, AX                   ; AX = 0 (накопитель результата)
XOR CX, CX
MOV SI, 10                   ; Основание системы счисления (10)
MOV CL, [Buffer + 1]         ; Кол-во символов
LEA DI, Buffer + 2           ; DI указывает на 1-й введённый символ

CMP BYTE PTR [DI], '-'       ; Проверка знака
JNE Convert
MOV BYTE PTR [SignFlag], 1   ; Установить флаг минуса
DEC CX
INC DI

; --- Цикл конвертации строки в число ---
Convert:
ConvertLoop:
OR CX, CX
JZ EndConvert

MOV BL, [DI]                 ; Получаем текущий символ
CMP BL, '0'
JB IncorrectErr
CMP BL, '9'
JA IncorrectErr
SUB BL, '0'                  ; ASCII → число (например, '5' → 5)      
MUL SI                       ; AX = AX * 10
JC OverflowErr1
ADD AX, BX                   ; Добавляем текущую цифру к результату
JC OverflowErr1

INC DI
DEC CX
JMP ConvertLoop

EndConvert:
CMP BYTE PTR [SignFlag], 1
JNE CheckPositive
CMP AX, 32767
JA IncorrectErr
NEG AX                       ; Делаем результат отрицательным
JMP CheckRange

CheckPositive:
CMP AX, 32767
JA IncorrectErr

CheckRange:
CMP AX, -32767               ; Проверка нижней границы
JL IncorrectErr

; --- Проверка на переполнение при прибавлении 78 ---
CMP BYTE PTR [SignFlag], 1
JE CheckNegOverflow
CMP AX, 32767 - 78
JA OverflowErr1
JMP DoneInput

CheckNegOverflow:
CMP AX, -32768 + 78
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

;-----------------------
; Вывод числа, включая знак
;-----------------------
OutputNum PROC NEAR
MOV BX, Result
CMP BYTE PTR [SignFlag], 0
JNE PrintSigned

; --- Вывод положительного числа ---
MOV AX, BX
XOR CX, CX
MOV BX, 10

ULoop:
XOR DX, DX
DIV BX                       
ADD DL, '0'                  ; Число → ASCII символ (5 → '5')        
PUSH DX                     ; Сохраняем символ
INC CX
TEST AX, AX
JNZ ULoop

ULoopPrint:
POP AX
INT 29h                     
LOOP ULoopPrint
RET

; --- Вывод отрицательного числа ---
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
