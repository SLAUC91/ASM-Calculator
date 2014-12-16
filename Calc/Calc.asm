;----------------------------------------------------------------------------
; Author:  SL
;----------------------------------------------------------------------------

[GLOBAL mystart]                  ; export the start address

;----------------------------------------------------------------------------
[SECTION .text]
;----------------------------------------------------------------------------

; code belongs in this section starting here

;----------------------------------------------------------------------------
; MESSAGE is a macro displays a message for prompts.
; The address of the $ terminated string is passed as the only parameter.

%macro MESSAGE 1
         push eax                 ; macro transparency
         push edx

         mov  ah, 09h             ; select write string function
         mov  edx, %1             ; load EDX with address of string
         int  0f1h                ; call OS interrupt 0F1H

         pop  edx                 ; restore registers
         pop  eax
%endmacro
mystart:
;----------------------------------------------------------------------------
; MAIN starts here

INF:
         MESSAGE msg1    ;callGETBASE for inital base
         call GETBASE
         cmp edi,0       ;check to see if it should quit
         je END

         MESSAGE msg2    ;enter the number
         call ASCIIBIN
         cmp edi, 0
         je END
         push edi

         MESSAGE msg3    ;second base
         call GETBASE
         cmp edi, 0
         je END

         pop edi
         MESSAGE msg5    ;print answer
         mov ebx, OBU    ;location of string in outbuffer
         mov eax, edi    ;accum in edi mov to eax
         call BINASCII
         call CONOUT
         jmp INF
END:
         ret


GETBASE: mov ecx, 10              ; BASE 10
         mov edi, 0               ; set accum to 0
         call ASCIIBIN
         cmp edi, 2               ;cmp the upper and lower base limit
         jb END1
         cmp edi, 36
         ja END1
         mov ecx, edi             ; move current base into accum
         ret

END1:    mov ecx, 0
         ret
         
ASCIIBIN:
         mov  edi, 0
         mov  byte [buffer], 32   ; buffer can hold 32 characters
         mov  byte [buffer+1], 0  ; reuse 0 characters from last input
         mov  ah, 0ah             ; select buffered input function
         mov  edx, buffer         ; put buffer address in EDX
         int  0f1h                ; call OS interrupt 0F1H
         
         movzx esi, byte [buffer+1] ;load ECX with number of characters read
         mov  ebx, buffer+2         ;load address of input text into EBX

looop1:  mov al, [ebx]      ; load 1 byte from ebx address

inner:   cmp al, '0'
         jb error2
         cmp al, '9'
         ja error1
         sub al, '0'      ; subtract '0'
         jmp OK
         
error1:  and al, 0DFh     ; else and with DF
         cmp al, 'A'
         jb error2
         cmp al, 'Z'
         ja error2
         sub al,'A'-10    ; sub al"A"-10
         jmp OK

error2:  MESSAGE msg4
         mov edi, 0       ;zeros out the accumulator 
         ret


OK:      ;compare digit to base. If >, ERROR.
         movzx eax, al    ; zero extend digit
         cmp eax, ecx     ; cmp digit to base
         ja error2
         imul edi, ecx    ; accum * base
         add edi, eax     ; accum + digit         

next:    add ebx, 1       ; increment ebx
         sub esi, 1       ; decraments esi
         cmp esi, 0
         ja looop1        ; loop if it is above 0
         cmp edi, 2147483647 ;checks the upperbound
         ja error2
         cmp edi, 1          ;check lowerbound
         je error2
         cmp edi, -2147483647 ; check lower bound
         je error2
         cmp edi, -1         ;check upperbound
         je error2
         ret


;----------------------------------------------------------------------------
; CONOUT transfers byte characters from [EBX] to screen (console).
; String at [EBX] must be null terminated.

CONOUT:
         push eax                 ; save regs for subroutine transparency
         push edx
         push esi

         mov  esi, ebx            ; load ESI with address of buffer
         cld                      ; clear direction flage for forward scan
         mov  ah, 02h             ; select write character function
loop1:   lodsb                    ; get next byte   (NB this loop could be
         test al, 0ffh            ; test for null    more efficiently coded!)
         jz   done
         mov  dl, al              ; copy character into DL for function
         int  0f1h                ; call OS interrupt 0F1H
         jmp  loop1               ; ending in JMP is inefficient
done:
         pop  esi                 ; restore registers - transparency
         pop  edx
         pop  eax
         ret


; BINASCII routine to convert a 2's complement number passed in EAX, base in
; ECX, into a null-terminated string of ASCII characters stored at [EBX].

BINASCII:
         push edx                 ; transparency
         push edi

         mov  edi, ebx            ; put pointer to output string in EDI
         test eax, 0ffffffffh
         jns  positive
         mov  byte [edi], '-'     ; store minus sign in output string
         inc  edi

         neg  eax                 ; will this work OK with 8000000H?
positive:
         push dword 0             ; push marker, keeping stack dword aligned
looop:
         mov  edx, 0              ; NOTE: HAD TO FIX THIS ONE, CUZ THE STUPID
                                  ; INTEL CHIP INSISTS ON GENERATING A DIVIDE
                                  ; ERROR EXCEPTION IF QUOTIENT TOO BIG!!!
                                  
         div  ecx                 ; divide base into R:Q where EDX will
                                  ; contain the remainder and EAX the
                                  ; dividend then quotient
         cmp  edx, 9
         ja  letter
         add  edx, '0'            ; most convenient to do ASCII conversion here
                                  ; add ASCII '0'
         jmp  puush               ; so we can terminate our popping off stack
letter:
         add  edx, 'A'-10         ; easily: we can have digits of zero which
                                  ; couldn't be distinguished from the marker
puush:
         push edx                 ; push the character
         test eax, 0ffffffffh     ; if quotient is zero we are done
         jnz  looop

outloop:
         pop  eax                 ; pop digits
         mov  [edi], al           ; and store
         inc  edi                 ; the null is also popped and stored
         test al, 0ffh            ; test for null
         jnz  outloop

         pop  edi                 ; transparency
         pop  edx
         ret


;----------------------------------------------------------------------------
[SECTION .data]
;----------------------------------------------------------------------------

; all initialized data variables and constant definitions go here

msg1     db   13,10,"Enter a base number or Q to quit: ", 13, 10, "$"
msg2     db   13,10,"Enter a Number: ", 13, 10, "$"
msg3     db   13,10,"Enter the desired base: ", 13, 10, "$"
msg4     db   13,10,"INVALID INPUT", 13, 10, "$"
msg5     db   13,10,"Your Result is: ", 13, 10, "$"

;----------------------------------------------------------------------------
[SECTION .bss]
;----------------------------------------------------------------------------

; all uninitialized data elements go here

buffer   resb 34                 ; buffer to store input characters
OBU  resb 80                     ; buffer to store output char
