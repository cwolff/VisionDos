Name            VSNSCRN

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Screen

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
; *** Externals
;

                extrn  main_text_attribute:byte
                extrn  labels:byte
                extrn  vertical:byte
                extrn  color_off_on:byte
                extrn  function_key_attributes:byte
                extrn  screen_seg:word
                extrn  video_seg:word
                extrn  mode_select_register:byte


;
; *** Public
;

                public function_key_message
                public vision_string
                public display_message
                public display_menu
                public display_prompt
                public display_function_key
                public clear_page
                public clear_monitor
                public clear_video
                public screen_header
                public screen_trailer
                public screen_page


;
; *** Equates
;

Row_length      equ    80

;
; *** Variables
;

Function_key_message   db     0,'     '

Crt_cols               db     80

Vision_string          db     5,4,3,6,15

Page

; =========================================================================
; |                                                                       |
; |                         DISPLAY PROMPT                                |
; |                                                                       |
; |            SI - [#,L1,XXX...X,L2,XXX...X,,...,LN,XXX...X]             |
; |            DX - row column                                            |
; |            BL - attribute                                             |
; |                                                                       |
; =========================================================================

Display_prompt proc     near

               push     ds
               push     es

               push     cs
               push     cs

               pop      es
               pop      ds

;
; *** get number of choices to display
;

               xor      ch,ch
               mov      cl,[si]
               inc      si

        Display_prompt_loop:

               push     cx

               mov      cx,si
               mov      bl,main_text_attribute
               call     display_message

               xor      ah,ah
               mov      al,[si]
               add      si,ax
               inc      si

               inc      dh

               pop      cx

               loop     display_prompt_loop

               pop      es
               pop      ds

               ret

Display_prompt endp

Page

; =========================================================================
; |                                                                       |
; |                          DISPLAY MENU                                 |
; |                                                                       |
; |     Input:                                                            |
; |            CX - offset message_prompt                                 |
; |            SI- [#,(K1,L1,XXX...X,K2,L2,XXX...X, ... ,KN,LN,XXX...X)]  |
; |                 # - number of items in menu                           |
; |                 KN - soft function key number 1,2,3,4,5               |
; |                 LN - length of choice description string              |
; |                 XXX...X - choice description string                   |
; |                                                                       |
; |                 function key are alway displayed starting             |
; |                 in column 10h                                         |
; |                                                                       |
; |                 choice descriptions start in column 2fh               |
; |                                                                       |
; =========================================================================

Display_menu   proc     near

               push     ds
               push     es

               push     cs
               push     cs

               pop      es
               pop      ds

;
; *** get number of choices to display
;

               mov      bx,cx

               xor      ch,ch
               mov      cl,[si]

               inc      si

;
; *** Put current position on screen in DX
;

               mov      dh,14
               sub      dh,cl

               push     si
               push     cx
               push     dx

               mov      si,bx

               mov      ah,[si]       ; *** number of lines for prompt
               sub      dh,ah
               sub      dh,2
               mov      dl,0ah

               mov      cx,0

               call     display_prompt

               pop      dx
               pop      cx
               pop      si

        Display_menu_loop:

               push     cx
               push     dx

               mov      al,[si]
               mov      dl,0ah
               call     display_function_key

               pop      dx

               inc      si
               mov      cx,si
               mov      bl,main_text_attribute
               mov      dl,12h
               call     display_message

               xor      ah,ah
               mov      al,[si]
               add      si,ax
               inc      si

               add      dh,2

               pop      cx

               loop     display_menu_loop

               call     screen_page

               pop      es
               pop      ds

               ret

Display_menu   endp

Page

; =========================================================================
; |                                                                       |
; |                          DISPLAY FUNCTION KEY                         |
; |                                                                       |
; |       Input:                                                          |
; |            DX - row, column to display funtion key                    |
; |            AL - number of function key to display                     |
; |            LABELS - determines if function keys or vision style       |
; |                     0 - function keys displayed                       |
; |                     1 - vision style keys                             |
; |            If function keys displayed then VERTICAL determines if     |
; |            horizontal or vertical keys are displayed                  |
; |                                                                       |
; =========================================================================

Display_function_key proc near

               push     cx
               push     si

               cmp      labels,1
               je       vision_keys

;
; *** Display function key labels
;

               mov      di,offset function_key_message
               mov      byte ptr [di],4
               inc      di
               mov      byte ptr [di],221
               inc      di
               mov      byte ptr [di],'F'
               inc      di

               mov      ah,al

;
; *** Determine vertical or horizontal layout
;

               cmp      vertical,2
               je       horizontal_layout

               shl      al,1
               add      al,'0'

               jmp      function_key_display

        Horizontal_layout:

               add      al,'5'

               jmp      function_key_display

;
; *** Vision key layout
;

        Vision_keys:

               mov      di,offset function_key_message
               mov      byte ptr [di],3
               inc      di
               mov      byte ptr [di],221
               inc      di

               mov      ah,al
               dec      al

               mov      bx,offset vision_string

               xlatb

        Function_key_display:

               cmp      al,':'             ; test for F10 case
               jne      not_f10

               mov      function_key_message,5

               mov      al,'1'
               mov      [di],al
               inc      di

               mov      al,'0'               

        Not_f10:

               mov      [di],al                      
               inc      di

               mov      byte ptr [di],222

               mov      cx,offset function_key_message

;
; *** get function key color attribute
;

               mov      al,ah
               dec      al
               mov      bx,offset function_key_attributes
               
               xlatb

               mov      bl,al

               call     display_message

               pop      si
               pop      cx

               ret

Display_function_key endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            CLEAR MONITOR                              |
; |                                                                       |
; -------------------------------------------------------------------------

Clear_monitor   proc    near

                pushf
                push    ax
                push    si

                mov     ax,0600h
                mov     bh,0h
                mov     cx,0600h
                mov     dx,0c25h

                call    clear_screen

                mov     ax,0600h
                mov     bh,0h
                mov     cx,0b00h
                mov     dx,0c4fh

                call    clear_screen

                pop     si
                pop     ax
                popf

                ret

Clear_monitor   endp

Page

; =========================================================================
; |                                                                       |
; |                              CLEAR PAGE                               |
; |                                                                       |
; =========================================================================

Clear_page     proc     near

               push     ax
               push     cx
               push     dx
               push     si

               mov      ax,0600h
               mov      bh,0h
               mov      cx,0300h
               mov      dx,164fh

               call     clear_screen

               pop      si
               pop      dx
               pop      cx
               pop      ax

               ret

Clear_page     endp

Page

; =========================================================================
; |                                                                       |
; |                             CLEAR VIDEO                               |
; |                                                                       |
; =========================================================================

Clear_video    proc     near

               push     ax
               push     cx
               push     dx
               push     si

               mov      ax,0600h
               mov      bh,0h
               mov      cx,0000h
               mov      dx,184fh

               call     clear_screen

               pop      si
               pop      dx
               pop      cx
               pop      ax


               ret

Clear_video    endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          DISPLAY MESSAGE                             |
; |                                                                      |
; |  Display message driver. Display string until a 0ffh is encountered  |
; |                                                                      |
; |              Input:                                                  |
; |                      CS:CX - contains address of message             |
; |                         DX - position on screen                      |
; |                              DH - row  DL - column                   |
; |                         BL - attribute                               |
; |                                                                      |
; |                                                                      |
; ------------------------------------------------------------------------

Display_message proc    near

                push    ax
                push    bx
                push    cx
                push    dx
                push    di
                push    si
                push    ds
                push    es

;
; *** Check to see if centering needs to take place
;

                push    cs
                pop     ds

                mov     es,screen_seg

                mov     si,cx

                cmp     dl,04fh
                jb      dont_center

                mov     dl,[si]
                inc     dl
                shr     dl,1
                mov     al,dl
                mov     dl,27h
                sub     dl,al

        Dont_center:

                push    si
                push    bx

                call    find_position

                pop     bx
                pop     si

                mov     cl,[si]
                xor     ch,ch

                inc     si

        Display_loop:

                mov     al,[si]
                mov     ah,bl

                stosw

                inc     si

                loop    display_loop

        Display_message_return:

                pop     es
                pop     ds
                pop     si
                pop     di
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_message endp

Page

; =========================================================================
; |                                                                       |
; |                          FIND POSITION                                |
; |                                                                       |
; |  Input:                                                               |
; |      DX has row position                                              |
; |  Output:                                                              |
; |      DI has position in regen buffer                                  |
; |                                                                       |
; =========================================================================

Find_position   proc    near

                mov     ax,dx
                mov     al,ah

                cbw

                mul     crt_cols

                xor     dh,dh

                add     ax,dx

                sal     ax,1

                mov     di,ax

                ret

Find_position   endp

Page

; =========================================================================
; |                                                                       |
; |                             COLOR ON                                  |
; |                                                                       |
; | When running with the MAD Computer it isn't necessary to toggle the   |
; | 6845 ON/OFF to obtain clear screen images without snow.               |
; |                                                                       |
; | Note:                                                                 |
; |                                                                       |
; |  This code is executed only when the RGB monitor is selected.         |
; |  You can use your own switches to determine when it should be         |
; |  executed.                                                            |
; |                                                                       |
; |    Special controllers to turn color video screen on/off to avoid     |
; |    disgusting screen glitch.  should only be executed when the        |
; |                       color rgb monitor is in use.                    |
; |                                                                       |
; =========================================================================

Color_on	      proc	    near

               cmp      color_off_on,01h
             		jne      color_on_return

             		push	    ax
             		push	    dx

             		mov	     dx,3d8h
           	  	mov     	al,mode_select_register

             		out	     dx,al

             		pop	     dx
             		pop	     ax

        Color_on_return:

    		         ret

Color_on	      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                                COLOR OFF                              |
; |                                                                       |
; -------------------------------------------------------------------------

Color_off	     proc	    near

               cmp      color_off_on,01h
             		jne      color_off_return

             		push    	ax
 	            	push    	dx

             		mov     	dx,3dah

        Color_off_loop:

               in       al,dx

               test     al,8
               jz       color_off_loop

              	mov	     al,mode_select_register
	             	and	     al,0f7h		          ; strip enable signal
             		mov	     dx,3d8h

               out      dx,al

             		pop	     dx
             		pop	     ax

        Color_off_return:

             		ret

Color_off	     endp

Page

; ========================================================================
; |                                                                      |
; |                          SCREEN HEADER                               |
; |                                                                      |
; ========================================================================

Screen_header  proc     near

               push     ds
               push     es
               push     si
               push     di
               push     cx

               mov      ds,screen_seg
               mov      es,video_seg

               mov      si,0
               mov      di,0

               mov      cx,3 * row_length

               call     color_off

               cld

               rep      movsw

               call     color_on

               pop      cx
               pop      di
               pop      si
               pop      es
               pop      ds

               ret

Screen_header  endp

Page

; =========================================================================
; |                                                                       |
; |                          SCREEN TRAILER                               |
; |                                                                       |
; =========================================================================

Screen_trailer proc     near

               push     ds
               push     es
               push     si
               push     di
               push     cx

               mov      ds,screen_seg
               mov      es,video_seg

               mov      si,23 * row_length * 2
               mov      di,si

               mov      cx,2 * row_length

               call     color_off

               cld

               rep      movsw

               call     color_on

               pop      cx
               pop      di
               pop      si
               pop      es
               pop      ds

               ret

Screen_trailer endp

Page

; =========================================================================
; |                                                                       |
; |                            SCREEN PAGE                                |
; |                                                                       |
; =========================================================================

Screen_page    proc     near

               push     ds
               push     es
               push     si
               push     di
               push     cx

               mov      ds,screen_seg
               mov      es,video_seg

               mov      si,3 * row_length * 2
               mov      di,si

               mov      cx,6

        Page_loop:

               push     cx

               mov      cx,3 * row_length

               call     color_off

               cld

               rep      movsw

               call     color_on

               pop      cx

               loop     page_loop

               pop      cx
               pop      di
               pop      si
               pop      es
               pop      ds

               ret

Screen_page    endp

Page

; =========================================================================
; |                                                                       |
; |                            CLEAR SCREEN                               |
; |                                                                       |
; =========================================================================

Clear_screen   proc     near

               push     es

               mov      es,screen_seg

               push     dx

               mov      dx,cx

               call     find_position

               pop      dx

;
; *** rows
;

               sub      dh,ch
               inc      dh

;
; *** columns
;

               sub      dl,cl
               inc      dl

               xor      ch,ch
               mov      cl,dl

               mov      ah,07
               mov      al,20h

       Clear_loop:

               push     cx
               push     di

               cld

               rep      stosw

               pop      di
               pop      cx

               add      di,row_length * 2

               dec      dh
               jnz      clear_loop

               pop      es

               ret

Clear_screen   endp

Code_seg       ends

             		end
ed
e

   o   c        d   d,o_egh*2

       dc   h
       jz   la_op

       pp   s

       rt

la_cen edCd_e    ns

      	ay
                call    display_message

                ret

Disk_on         endp

Page

; ==================