Name            VSNKEY

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Key

Page            60,132

; **************************************************************************
; *                                                                        *
; *        (C)opyright 1983 Bruce & James Program Publishers Inc.          *
; *                                                                        *
; *                    Author  Cameron L. Wolff                            *
; *                                                                        *
; **************************************************************************

Code_seg        segment public 'code'

                assume cs:code_seg

;
; Externals
;

                extrn  esc_prompt:far

                extrn  vertical:byte

;
; Publics
;

                public  function_choice
                public  check_heart_key
                public  flush_keyboard
                public  kb_int
                public  error_beep
                public  key_board
                public  pitch

                public  end_of_data


;
;  *** Equates
;

;
; *** Vision parameters
;

Vision_parameters       equ    100h

White_on_black          equ    07h
Bright_white_on_black   equ    0fh
Black_on_white          equ    70h
Black_on_bright_white   equ    0f0h

Cyan_on_black           equ    03h
Blue_on_black           equ    01h
Cyan_on_blue            equ    13h
Green_on_black          equ    02h
White_on_red            equ    47h

;
; *** Keyboard valuse
;

Esc_key_addr              equ    100h      ; Escape key address

F1                        equ    3bh       ; Function key 1
F2                        equ    3ch       ; Function key 2
F3                        equ    3dh       ; Function key 3
F4                        equ    3eh
F5                        equ    3fh
F6                        equ    40h
F7                        equ    41h
F8                        equ    42h
F9                        equ    43h
F10                       equ    44h
Esc                       equ    01h       ; Esc key

Kb_data                   equ    60h       ; Key board data port
Kb_ctl                    equ    61h       ; Key board control port
Eoi                       equ    20h       ; End of interrupt

Error_pitch               equ    10h
Prompt_pitch              equ    08h

Timer                     equ    42h
Timer_control             equ    43h
Port_b                    equ    61h

Mode                      equ    10110000b
Time_high                 equ    10h
Time_low                  equ    10h

Page

;
; *** Key board buffer
;

Kb_flag                 db   00h

Legal_characters        db   11,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,Esc

Buffer_head             dw   offset kb_buffer
Buffer_tail             dw   offset kb_buffer

Kb_buffer               dw 16 dup (0000)

Kb_buffer_end           label word

;
; *** Error beep parameters
;

Time_vars                label  word

Pitch                    db   10h
Duration                 db   0ah
Center                   db   33h

;
; *** Function key translator
;

Vertical_layout          db   3ch,3eh,40h,42h,44h
Horizontal_layout        db   40h,41h,42h,43h,44h

Accept_string            db   6 dup (00)

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           CHECK HEART KEY                             |
; |                                                                       |
; |       Output:                                                         |
; |                Carry set if heart key struck                          |
; |                                                                       |
; =========================================================================

Check_heart_key proc    near

                mov     cx,0fffh

        Heart_key_loop:

                push    cx

                mov     ah,1
                int     16h

                jz      no_key_available

                mov     ah,0
                int     16h

                cmp     vertical,1
                je      vertical_heart

                cmp     ah,42h
                jne     not_heart

                jmp     heart_hit

        Vertical_heart:

                cmp     ah,40h
                jne     not_heart

        Heart_hit:

                stc

                pop     cx

                jmp     check_heart_return

        Not_heart:

                mov     pitch,error_pitch
                call    error_beep

                call    flush_keyboard

        No_key_available:

                pop     cx

                loop    heart_key_loop

                clc

        Check_heart_return:

                ret

Check_heart_key endp

Page

; =========================================================================
; |                                                                       |
; |                          FUNCTION CHOICE                              |
; |                                                                       |
; |    Input:                                                             |
; |           SI - address of function keys to accept                     |
; |                LXXX...X  L - length of string  X charaters to accept  |
; |                                                                       |
; |    Output:                                                            |
; |           AH - scan code                                              |
; |           AL - key choice (1,first choice in string 2,second etc)     |
; |                                                                       |
; |    Softkeys are always 1,2,3,4,5 to rest of program, this routine     |
; |    translate these number into the proper scan codes based on         |
; |    hoizontal or vertical function key indicator                       |
; |                                                                       |
; =========================================================================

Function_choice proc    near

                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

                push    si

;
; *** Number of characters to accept
;

                mov     al,[si]
                xor     ch,ch
                mov     cl,[si]
                inc     si

;
; *** Put length of string into accept string
;

                mov     di,offset accept_string
                mov     [di],al
                inc     di

;
; *** Test for vertical or horizontal layout
;

                mov     bx,offset vertical_layout

                cmp     vertical,1
                je      translate_loop

                mov     bx,offset horizontal_layout

;
; *** CX - number of characters to process, SI - pointer to character to
; *** translate DI - pointer to translated accept string, BX string address of; *** translations
;

        Translate_loop:

                push    bx

                mov     al,[si]
                dec     al
                inc     si

                xlatb

                mov     [di],al
                inc     di

                pop     bx

                loop    translate_loop

        Get_function_choice:

                call    get_any_key

                cld

                mov     di,offset accept_string
                xor     ch,ch
                mov     cl,[di]
                inc     di
                mov     al,ah

                repne   scasb

                je      function_key_hit

                mov     pitch,error_pitch
                call    error_beep

                jmp     get_function_choice

;
; ***Translate key back as a value of 1,2,3,4,5
;

        Function_key_hit:

                pop     si

                mov     bx,offset accept_string+1
                sub     di,bx
                mov     bx,di
                mov     al,[si][bx]

        Function_choice_return:

                pop     es
                pop     ds

                ret

Function_choice endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           GET ANY KEY                                 |
; |                                                                       |
; |        Gets a key from the key board after flushing it first          |
; |                                                                       |
; -------------------------------------------------------------------------

Get_any_key     proc    near

                call    flush_keyboard

                mov     ah,00h
                int     16h

                ret

Get_any_key     endp

Page

; =========================================================================
; |                                                                       |
; |                            FLUSH KEYBOARD                             |
; |                                                                       |
; =========================================================================

Flush_keyboard  proc    near

                push    cx

        Flush_keyboard_loop:

                mov     ah,1
                int     16h

                jz      flush_keyboard_pause

                mov     ah,0
                int     16h

                jmp     flush_keyboard_loop

        Flush_keyboard_pause:

                mov     cx,0ffffh

        Key_pause_1:

                loop    key_pause_1

        Key_pause_2:

                loop    key_pause_2

                mov     ah,1
                int     16h

                jnz     flush_keyboard_loop

        Flush_keyboard_return:

                pop     cx

                ret

Flush_keyboard  endp

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                              KEY BOARD                                $
; $                                                                       $
; $         PROVIDES AN INTERFACE TO THE KEYBOARD FOR FILE CLERK II       $
; $                                                                       $
; $         Entry:                                                        $
; $                  AH - 0 read next ascii character in key board buffer $
; $         Exit:                                                         $
; $                  AL - 0 no need to return ascii character             $
; $                  AH - scan code                                       $
; $                                                                       $
; $         Entry:                                                        $
; $                  AH - 1 check to see if a character is available      $
; $         Exit:                                                         $
; $                  ZF - 0 character in buffer                           $
; $                  ZF - 1 buffer clear                                  $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Key_board       proc    far

                sti

                push    bx
                push    ds
                push    es

                push    cs
                push    cs

                pop     es
                pop     ds

                or      ah,ah
                jz      ascii_read

                dec     ah
                jz      ascii_status

                jmp     key_board_return

        Ascii_read:

                sti

                nop                        ; while looping allow an interrupt

                cli

                mov     bx,buffer_head
                cmp     bx,buffer_tail
                jz      ascii_read

                mov     ax,[bx]
                call    increment_ptr

                mov     buffer_head,bx
                jmp     key_board_return

        Ascii_status:

                cli

                mov     bx,buffer_head
                cmp     bx,buffer_tail
                mov     ax,[bx]

                sti

                pop     es
                pop     ds
                pop     bx

                ret     2                  ; needed to retain current flags

        Key_board_return:

                pop     es
                pop     ds
                pop     bx

                iret                       ; return from interupt

Key_board       endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       INCREMENT BUFFER POINTER                       |
; |                                                                      |
; |                             Subroutine                               |
; |                                                                      |
; ------------------------------------------------------------------------

Increment_ptr   proc    near

                push    ax

                add     bx,2
                mov     ax,offset kb_buffer_end
                cmp     bx,ax
                jne     increment_ptr_ret
                mov     bx,offset kb_buffer

          Increment_ptr_ret:

                pop     ax

                ret

Increment_ptr   endp

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                          KEY INT                                      $
; $                                                                       $
; $                  Key board interrupt route                            $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Kb_int         proc     near

                sti
 
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es

                cld                        ; string operation forward 

                push    cs
                push    cs

                pop     ds
                pop     es

                in      al,kb_data         ; read in the character

                push    ax                 ; save it

                in      al,kb_ctl          ; get the control port

                mov     ah,al              ; save value
                or      al,80h             ; reset bit for key board

                out     kb_ctl,al

                xchg    ah,al              ; get back original control

                out     kb_ctl,al          ; kb has been reset

                pop     ax                 ; recover scan code
                mov     ah,al              ; save scan code in AH also

;
; *** Test for overrun scan code for key board
;

                cmp     al,0ffh            ; is this an overrun character ?
                jnz     test_for_esc_key

                mov     pitch,error_pitch
                call    error_beep

                jmp     kb_int_ret

;
; *** Test for ESC key
;

        Test_for_esc_key:

                 cmp    al,esc
                 jne    test_for_break_key

                mov     sp,100h

                pushf
                mov     ax,cs
                push    ax
                mov     ax,offset esc_prompt
                push    ax

                cli

                mov     al,eoi             ; end of interrupt routine
                out     020h,al            ; interrupt return no EOI

                iret                       ; jump to ESC PROMPT

;
; *** Test for break key
;

        Test_for_break_key:

                 cmp    al,80h
                 jb     process_key

                 jmp    kb_int_ret

;
; *** Test for shift keys
;

        Process_key:

                mov     di,offset legal_characters
                xor     ch,ch
                mov     cl,[di]
                inc     di

                repne   scasb              ; look for a match

                je      legal_character    ; match found

                mov     pitch,error_pitch
                call    error_beep

                xor     ax,ax              ; all other characters are invalid

                jmp     kb_int_ret

;
; *** No need for ascii character place scan code and place in buffer
;

        Legal_character:

                xor     al,al              ; no ascii value

                cli

                mov     bx,buffer_tail     ; get the end pointer to buffer
                mov     si,bx              ; save the value
                call    increment_ptr      ; advance the tail
                cmp     bx,buffer_head     ; has the buffer wrapped around
                je      buffer_full        ; buffer full return

                mov     [si],ax            ; store the value
                mov     buffer_tail,bx     ; move the pointer up

                jmp     kb_int_ret

        Buffer_full:

                sti

                mov    pitch,error_pitch
                call   error_beep

        Kb_int_ret:

                cli                        ; turn off interrupts

                mov     al,eoi             ; end of interrupt routine
                out     020h,al            ; interrupt return no EOI

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax                 ; restore state

                iret                       ; return, interrupts back on

Kb_int          endp

Page

; =========================================================================
; |                                                                       |
; |                             ERROR BEEP                                |
; |                                                                       |
; |            Generate a tone at the speaker based on the parameters     |
; |            of FEQUENCY and DURATION.                                  |
; |                                                                       |
; =========================================================================

Error_beep     proc     near

               cli

               push      ax
               push      bx
               push      cx
               push      dx

               mov       dl,center
               dec       dl

               mov       al,mode

               out       timer_control,al
               out       timer,al
               out       timer,al

               in        al,port_b

               or        al,3

               out       port_b,al

        Tone:

               mov       bh,duration
 
        Wave:

                mov      bl,pitch

        Pulse_high:

                mov      al,mode
 
                out      timer_control,al

                mov      al,center

                add      al,dl

                out      timer,al

                xor      al,al

                out      timer,al

                mov      cx,time_high

        Wait:

                loop     wait

                dec      bl
                jnz      pulse_high

                mov      bl,pitch

        Pulse_low:

                mov      al,mode

                out      timer_control, al

                mov      al,center
                sub      al,dl
 
                out      timer,al

                xor      al,al

                out      timer,al

                mov      cx,time_low

        Stall:

                loop      stall

                dec       bl
                jnz       pulse_low

                dec       bh
                jnz       wave

                shr       dl, 1
                jnz       tone

                in        al,port_b

                and       al,11111100b

                out       port_b,al

                pop       dx
                pop       cx
                pop       bx
                pop       ax

                sti

                ret

Error_beep      endp

End_of_data     label byte

Code_seg        ends

                end
   ae ye

oesg    ns

        n a e
eg  s
      
g 
   
      o    x
        o    x

        t        rt

ro_ep   np

n_fdt                                                               