Name            VSNGO

Title           Bruce_&_James_Program_publishers_Inc

Subttl          Vision_Go

Page 60,132

; ************************************************************************
; |                                                                      |
; |             (C)opyright 1983 Bruce & James Program Publishers        |
; |                                                                      |
; |                  Author - Cameron L. Wolff                           |
; |                                                                      |
; ************************************************************************

Code_seg        segment

                assume  cs:code_seg

                org     100h              

;
; *** Equates
;

Loaded_by_go   equ     0fffeh

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                                    GO                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Go             proc    far

               assume  cs:code_seg

               jmp     go_start          ; *** entry point must be at 100h

;
; *** File control block
;

Prepare_fcb             db  0ffh,5 dup (00),06,1,'PREPARE COM'
                        db  32 dup (00)

Prepare_label           label dword

Prepare_offset          dw  0100h
Prepare_seg             dw  0000h

Prepare_not_found    db  38,' SORRY: Not a Wordvision Master disk. '

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                                   GO START                            |
; |                                                                       |
; -------------------------------------------------------------------------

        Go_start:

               cli

               mov     ax,cs
               mov     ds,ax
               mov     es,ax
               mov     ss,ax
               mov     sp,100

               sti

;
; ** Clear screen
;

               mov     ah,6
               mov     al,0
               mov     cx,0
               mov     dx,184fh
               mov     bh,07h
               int     10h

;
; *** Set up program prefix segment
;

               mov      ax,offset end_go
               and      ax,0fff0h         ; segment limited to 16 byte Bndry
               mov      cl,4
               shr      ax,cl             ; segment is upper 16 b of 20 b ad
               inc      ax                ; go to next segment
               mov      bx,cs
               add      ax,bx             ; ax = cs of new segment

               mov      prepare_seg,ax

        Create_program_prefix:

               mov      dx,ax
               mov      ah,26h
               int      21h

;
; *** Open file for prepare.com
;

               mov      dx,offset prepare_fcb
               mov      ah,0fh
               int      21h

               or       al,al
               jz       set_dta

;
; *** Inform user that prepare not found
;

               mov      cx,offset prepare_not_found
               mov      dx,07ffh
               call     display_message

               int      20h

;
; *** Set DTA
;

        Set_dta:

               push     ds

               mov      ds,prepare_seg
               mov      dx,prepare_offset

               mov      ah,1ah
               int      21h

               pop      ds

;
; *** Read in prepare.com
;

               mov      bx,offset prepare_fcb
               mov      dx,bx
               mov      cx,cs:[bx+16+7]
               mov      ax,1
               mov      cs:[bx+14+7],ax

               mov      ah,27h
               int      21h

               cmp      al,02
               jne      file_is_read      ; Has program passed 64k boundry

;
; *** If warp around occurs (64k boundry then try again at other side
; *** of 64k boundry)
;

               mov      ax,1000h
               mov      prepare_seg,1000h

               push     cs
               pop      ds

               jmp      create_program_prefix

;
; *** Set up segment registers (step 8 page b-12 in DOS manual)
;

        File_is_read:

                mov     ax,loaded_by_go
                mov     es,ax

;
; *** Give control to prepare.com
;

                jmp     prepare_label

Go              endp

Page

; -------------------------------------------------------------------------
; |                                                                       | 
; |                          DISPLAY MESSAGE                              |
; |                                                                       |
; |           Low level process for display to the screen                 |
; |               Displays message from right to left                     |
; |                                                                       |
; |           Entry:                                                      |
; |                    BL - color of message                              |
; |                 DS:CX - address of message                            |
; |                    DX - position of message                           | 
; |                         DH - line of screen                           |
; |                         DL - column of line                           |
; |                              if DL > 04fh then center message         |
; |                                                                       |
; -------------------------------------------------------------------------

Display_message proc    near

                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

                mov     bl,7

;
; *** Set up Display message and check limits
;

                mov     si,cx
                mov     al,[si]            ; al <- character count
                xor     ah,ah              ; clear garbage
                mov     bh,al
                dec     bh                 ; adjust for addition
                cmp     al,0               ; test for null message
                jbe     display_message_return
                cmp     dl,04fh            ; test for center
                jbe     message_positioned
                inc     bh                 ; readjust for centering
                shr     bh,1               ; length / 2
                mov     dl,28h             ; center column (40)

         Message_positioned:

                add     dl,bh              ; set end of message column
                cmp     dl,4fh             ; test screen limit (79 columns)
                jg      display_message_return
                cmp     dh,18h             ; test screen limit (24 lines)
                jg      display_message_return

        Display_loop:

                push    ax
                push    bx

                mov     ah,02
                mov     bh,0
                int     10h

                pop     bx
                pop     ax

                push    ax
                push    bx
                push    si

                mov     bp,ax
                mov     al,ds:[si+bp]      ; get character
                mov     bh,0
                mov     cx,1
                mov     ah,09
                int     10h

                pop     si
                pop     bx
                pop     ax

                sub     dl,1               ; next column to the left
                sub     al,1               ; decrement message count
                jnz     display_loop

        Display_message_return:

                pop     es
                pop     ds

                ret

Display_message endp

End_go          label byte

Code_seg        ends

                end     go
       pp  d        rt

ipa_esg np

n_o     ae ye

oesg    ns

        n   o
    p     r
iaegn
