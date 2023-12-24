
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.model small                   
.stack 1000h
.data
 
    number      db  150d            ;variable 'number' stores the random value 
 
    ;to add LineBreak to strings
    CR          equ 13d
    LF          equ 10d
 
    ;String messages used through the application
    instruction db  CR, LF, LF, 'Please enter a valid number between 1 and 255 : $'
    lessValue   db  CR, 'The number is SMALLER than your guess','$'
    moreValue   db  CR, 'The number is BIGGER than your guess', '$'
    equalValue  db  CR, ' CONGUTRALATION You have made THE  Guess you are LUCKY!', '$'
    errorMsg    db  CR, 'Error - The number is out of range!', '$'
    retry       db  CR, LF,'Retry [y/n] ? ' ,'$'
 
    guessNum    db  0d              ;variable user to store the value that the user entered
    errorCHeck  db  0d              ;variable user to CHeck if entered value is in range
 
    param       label Byte
 
.code
 
start:
 
    ; --- BEGIN resting all registers and variables to 0h
    MOV AX, 0h
    MOV BX, 0h
    MOV CX, 0h
    MOV DX, 0h
 
    MOV BX, OFFSET guessNum         ; get address of 'guessNum' variable in BX.
    MOV BYTE PTR [BX], 0d           ; set 'guessNum' to 0 (decimal)
 
    MOV BX, OFFSET errorCheck       ; get address of 'errorCheck' variable in BX.
    MOV BYTE PTR [BX], 0d           ; set 'errorCheck' to 0 (decimal)
    ; --- END resting
 
    MOV AX, @data                   ; get address of data to AX
    MOV DS, AX                      ; set 'data segment' to value of AX whiCH is 'address of data'
    MOV DX, offset instruction      ; load address of 'instruction' message to DX
 
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
 
    MOV CL, 0h                      ; set CL to 0  (Counter)
    MOV DX, 0h                      ; set DX to 0  (Data register used to store user input)
 
; -- BEGIN reading user input
while:
                                    
    CMP     CL, 5d                  ; compare CL with 10d (5 is the maximum number of digits allowed)
    JG      endwhile                ; IF CL > 5 then JUMP to 'endwhile' label
    
    MOV     AH, 1h                  ; Read character from STDIN into AL (for DOS interrupt)
    INT     21h                     ; DOS INT 21h (DOS interrupt)
    
    CMP     AL, 0DH                 ; compare read value with 0DH which is ASCII code for ENTER key
    JE      endwhile                ; IF AL = 0DH, Enter key pressed, JUMP to 'endwhile'      

    SUB     AL, 30h                 ; Substract 30h from input ASCII value to get actual number. (Because ASCII 30h = number '0')
    MOV     DL, AL                  ; Move input value to DL
    PUSH    DX                      ; Push DL into stack, to get it read to read next input
    INC     CL                      ; Increment CL (Counter)
 
    JMP while                       ; JUMP back to label 'while' if reached
 
endwhile:
; -- END reading user input
 
    DEC CL                          ; decrement CL by one to reduce increment made in last iteration
    
    CMP CL, 02h                     ; compare CL with 02, because only 3 numbers can be accepted as IN RANGE
    JG  ifError                     ; IF CL (number of input characters) is greater than 3 JUMP to 'ifError' label
 
    MOV BX, OFFSET errorCHeck       ; get address of 'errorCheck' variable in BX.
    MOV BYTE PTR [BX], CL           ; set 'errorCheck' to value of CL
 
    MOV CL, 0h                      ; set CL to 0, because counter is used in next section again
 
; -- BEGIN processing user input
 
; -- Create actual NUMERIC representation of
;--   number read from user as three characters
while2:
 
    CMP CL,errorCheck
    JG endwhile2
 
    POP DX                          ; POP DX value stored in stack, (from least-significant-digit to most-significant-digit)
 
    MOV CH, 0h                      ; clear CH which is used in inner loop as counter
    MOV AL, 1d                      ; initially set AL to 1   (decimal)
    MOV DH, 10d                     ; set DH to 10  (decimal)
 
 ; -- BEGIN loop to create power of 10 for related position of digit
 ; --  IF CL is 2
 ; --   1st loop will produce  10^0
 ; --   2nd loop will produce  10^1
 ; --   3rd loop will produce  10^2
 while3:
 
    CMP CH, CL                      ; compare CH with CL
    JGE endwhile3                   ; IF CH >= CL, JUMP to 'endwhile3
 
    MUL DH                          ; AX = AL * DH whis is = to (AL * 10)
 
    INC CH                          ; increment CH
    JMP while3
 
 endwhile3:
 ; -- END power calculation loop
 
    ; now AL contains 10^0, 10^1 or 10^2 depending on the value of CL
 
    MUL DL                          ; AX = AL * DL, which is actual positional value of number
 
    JO  ifError                     ; If there is an overflow JUMP to 'ifError'label (for values above 300)
 
    MOV DL, AL                      ; move restlt of multiplication to DL
    ADD DL, guessNum                ; add result (actual positional value of number) to value in 'guessNum' variable
 
    JC  ifError                     ; If there is an overflow JUMP to 'ifError'label (for values above 255 to 300)
 
    MOV BX, OFFSET guessNum         ; get address of 'guessNum' variable in BX.
    MOV BYTE PTR [BX], DL           ; set 'errorCheck' to value of DL
 
    INC CL                          ; increment CL counter
 
    JMP while2                      ; JUMP back to label 'while2'
 
endwhile2:
; -- END processing user input
 
    MOV AX, @data                   ; get address of data to AX
    MOV DS, AX                      ; set 'data segment' to value of AX which is 'address of data'
    
    MOV DL, number                  ; load original 'number' to DL
    MOV DH, guessNum                ; load guessed 'number' to DH
    
    CMP DH, DL                      ; compare DH and DL (DH - DL)
 
    JC ifGreater                    ; if DH (GUESSNUM) > DL (NUMBER) cmparision will cause a Carry. Becaus of that if carry has been occured print that 'number is more'
    JE ifEqual                      ; IF DH (GUESSNUM) = DL (NUMBER) print that guess is correct
    JG ifLower                      ; IF DH (GUESSNUM) < DL (NUMBER) print that number is less
 
ifEqual:
 
    MOV DX, offset equalValue       ; load address of 'equalValue' message to DX
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
    JMP exit                        ; JUMP to end of the program
 
ifGreater:
 
    MOV DX, offset moreVALue         ; load address of 'moreValue' message to DX
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
    JMP start                       ; JUMP to beginning of the program
 
ifLower:
 
    MOV DX, offset lessValue        ; load address of 'lessValue' message to DX
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
    JMP start                       ; JUMP to beginning of the program
 
ifError:
 
    MOV DX, offset errorMsg         ; load address of 'errorwMsg' message to DX
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
    JMP start                       ; JUMP to beginning of the program      
 
exit:
 
; -- Ask user if he needs to try again if guess was successful
retry_while:
 
    MOV DX, offset retry            ; load address of 'retry' message to DX
 
    MOV AH, 9h                      ; Write string to STDOUT (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
 
    MOV AH, 1h                      ; Read character from STDIN into AL (for DOS interrupt)
    INT 21h                         ; DOS INT 21h (DOS interrupt)
 
    CMP AL, 6Eh                     ; Check if input is 'n'
    JE return_to_DOS                ; call 'return_to_DOS' label is input is 'n'
 
    CMP AL, 79h                     ; Check if input is 'y'
    JE restart                      ; call 'restart' label is input is 'y' ..
                                    ; "JE start" is not used because it is translated as NOP by emu8086
 
    JMP retry_while                 ; if input is neither 'y' nor 'n' re-ask the same question   
 
retry_endwhile:
 
restart:
    JMP start                       ; JUMP to begining of program
    
return_to_DOS:
    MOV AX, 4c00h                   ; Return to ms-dos
    INT 21h                         ; DOS INT 21h (DOS interrupt)
    end start
 

ret




