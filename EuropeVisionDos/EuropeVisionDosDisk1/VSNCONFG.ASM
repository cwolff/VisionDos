Name            VSNCONFG

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Configuration

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

                        extrn  function_choice:near
                        extrn  display_header:near
                        extrn  screen_header:near
                        extrn  display_trailer:near
                        extrn  screen_trailer:near
                        extrn  display_message:near
                        extrn  display_menu:near
                        extrn  clear_page:near
                        extrn  display_menu:near

                        extrn  vertical:byte
                        extrn  labels:byte
                        extrn  system_configuration:word
                        extrn  source_drive:byte
                        extrn  destination_drive:byte
                        extrn  number_of_drives:byte
                        extrn  color:byte
                        extrn  color_off_on:byte
                        extrn  special_attributes:near
                        extrn  function_key_attributes:byte
                        extrn  header_attribute:byte
                        extrn  header_text_attribute_low:byte
                        extrn  header_text_attribute_high:byte
                        extrn  trailer_attribute:byte
                        extrn  trailer_text_attribute:byte
                        extrn  main_text_attribute:byte
                        extrn  diagram_attribute_high:byte
                        extrn  diagram_attribute_low:byte
                        extrn  error_attribute:byte

;
; *** Public
;

                        public keyboard_mode
                        public display_mode
                        public drive_mode
                        public keyboard_2_message
                        public keyboard_fk2_message
                        public keyboard_1_message
                        public keyboard_heart_message

;
; *** Equates
;

Vision_parameters       equ    4f0h

White_on_black          equ    07h
Bright_white_on_black   equ    0fh
Black_on_white          equ    70h
Black_on_bright_white   equ    0f0h

Cyan_on_black           equ    03h
Blue_on_black           equ    01h
Cyan_on_blue            equ    13h
Green_on_black          equ    02h
White_on_red            equ    47h

Page

;
; *** Prompt messages for keyboard labels
;

Keyboard_fk2_message        db   4,221,'F2',222
Keyboard_1_message          db   33,'Planning to do without key labels'

Keyboard_heart_message      db   3,221,3,222
Keyboard_2_message          db   31,'Keys are labeled for Wordvision'

;
; *** Prompt messages for vertical or horizontal keyboard
;

Keyboard_test_prompt       db  2,51,'Press the key shown next to the '
                           db       'description of your'
                           db    16,'keyboard layout:'

Keyboard_test_menu         db   2
                           db   1
                           db   28,'Standard IBM keyboard layout'
                           db   3
                           db   40,'F1 through F10 all in one horizontal row'

Vision_or_fkey_string            db   3,1,3,4

Horizontal_or_vertical_string    db   2,1,3

;
; *** Prompt message for video layout
;

Monitor_test_prompt        db    1,58,'Which type of display screen will you '
                           db         'use with Wordvision?'

Monitor_test_menu  db    5
                  db    1
                  db    14,'IBM monochrome'
                  db    2
                  db    50,'Non-IBM monochrome with IBM color/graphics adapter'
                  db    3
                  db    37,'Color with IBM color/graphics adapter'
                  db    4
                  db    6,'Compaq'
                  db    5
                  db    32,'Special color (see User',27h,'s Guide)'

Monitor_type_string        db    5,1,2,3,4,5

Color_message              db  28,'This line is shown in color.'

Color_verify_message       db  1,23,'Can you read the above?'

Color_verify_menu          db  2
                           db  1
                           db  2,'No'
                           db  3
                           db  3,'Yes'

Color_verify_string        db  2,1,3

;
; *** Prompt messages for disk drive layout
;

Drive_test_prompt       db    2,57,'Does your computer have two or more real '
                        db         '(not simulated) '
                        db      12,'disk drives?'

Drive_test_menu         db    2
                        db    1
                        db    2,'No'
                        db    3
                        db    3,'Yes'

Drive_test_string       db    2,1,3

Page

; =========================================================================
; |                                                                       |
; |                              KEYBOARD MODE                            |
; |                                                                       |
; =========================================================================

Keyboard_mode  proc     near

               mov      vertical,1

; get function key for type of legends

               mov      si,offset vision_or_fkey_string
               call     function_choice

               cmp      al,1
               je       keyboard_test

               mov      labels,1

               cmp      al,3
               je       vertical_keyboard

               mov      vertical,2

               jmp      keyboard_mode_return

        Vertical_keyboard:

               mov      vertical,1

               jmp      keyboard_mode_return

; Function key labels are chosen

        Keyboard_test:

               mov      labels,2

               call     display_trailer
               call     screen_trailer     ; Show ESC instead of stop

               call     clear_page

               mov      cx,offset keyboard_test_prompt
               mov      si,offset keyboard_test_menu
               call     display_menu

; Get function key for type of board

               mov      si,offset horizontal_or_vertical_string
               call     function_choice

               mov      vertical,1

               cmp      al,1
               je       keyboard_mode_return

               mov      vertical,2

        Keyboard_mode_return:

               push     ds

               mov      ax,0
               mov      ds,ax

               mov      bx,vision_parameters

               mov      al,vertical
               mov      [bx+2],al
               mov      al,labels
               mov      [bx+3],al

               pop      ds

               ret

Keyboard_mode  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          DISPLAY MODE                                 |
; |                                                                       |
; |      Determine if there is a color graphics card. If yes then ask     |
; |      if they have a color monitor. If yes again display in green.     |
; |      If no color card do not do any thing                             |
; |                                                                       |
; -------------------------------------------------------------------------

Display_mode    proc    near

                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

                mov     ax,system_configuration

                and     al,30h

                cmp     al,30h

                jnz     color_graphics_card

                jmp     display_mode_return ; no color card

; Color graphics card present ask if they have a color monitor

        Color_graphics_card:

                call    clear_page

                mov     cx,offset monitor_test_prompt
                mov     si,offset monitor_test_menu
                call    display_menu

                mov     si,offset monitor_type_string
                call    function_choice

;
; Monitor check
;

        Ibm_monochrome_check:

                cmp     al,1
                jne     non_ibm_monochrome_check

                jmp     ibm_monochrome

        Non_ibm_monochrome_check:

                cmp     al,2
                jne     ibm_color_check

                jmp     non_ibm_monochrome

        Ibm_color_check:

                cmp     al,3
                jne     compaq_check

                jmp     ibm_color

        Compaq_check:

                cmp     al,4
                jne     special_color_check

                jmp    compaq

        Special_color_check:

                jmp     special_color

;
; Monitor types
;

        Ibm_monochrome:

                mov     color,1
                mov     color_off_on,0

                mov     header_attribute,white_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,white_on_black
                mov     trailer_text_attribute,black_on_white

                mov     main_text_attribute,white_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,black_on_bright_white

                jmp     display_mode_return

        Non_ibm_monochrome:

                mov     color,2
                mov     color_off_on,1

                mov     header_attribute,white_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,white_on_black
                mov     trailer_text_attribute,black_on_white

                mov     main_text_attribute,white_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,black_on_bright_white

                jmp     display_mode_return

        Ibm_color:

                mov     color,3
                mov     color_off_on,1

                mov     header_attribute,cyan_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,blue_on_black
                mov     trailer_text_attribute,cyan_on_blue

                mov     main_text_attribute,green_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,white_on_red

                mov     si,offset special_attributes

                jmp     color_verify

        Compaq:

                mov     color,4
                mov     color_off_on,0

                mov     header_attribute,white_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,white_on_black
                mov     trailer_text_attribute,black_on_white

                mov     main_text_attribute,white_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,black_on_bright_white

                jmp     display_mode_return

        Special_color:

                mov     color,5
                mov     color_off_on,0

                mov     header_attribute,cyan_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,blue_on_black
                mov     trailer_text_attribute,cyan_on_blue

                mov     main_text_attribute,green_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,white_on_red

                mov     si,offset special_attributes

        Color_verify:

                push    si

                call    display_header

                call    display_trailer

                call    screen_header

                call    screen_trailer

                pop     si

                mov     al,main_text_attribute
                mov     ah,color

                push    ax
                push    si

                mov     main_text_attribute,white_on_black
                mov     color,2

                call    clear_page

                mov     bl,green_on_black
                mov     cx,offset color_message
                mov     dx,060ah
                call    display_message

                mov     cx,offset color_verify_message
                mov     si,offset color_verify_menu
                call    display_menu

                pop     si
                pop     ax

                mov     color,ah
                mov     main_text_attribute,al

                push    si

                mov     si,offset color_verify_string
                call    function_choice

                pop     si

                cmp     al,3
                je      able_to_read_color

                mov     color,2
                mov     color_off_on,1

                mov     header_attribute,white_on_black
                mov     header_text_attribute_low,white_on_black
                mov     header_text_attribute_high,bright_white_on_black

                mov     trailer_attribute,white_on_black
                mov     trailer_text_attribute,black_on_white

                mov     main_text_attribute,white_on_black

                mov     diagram_attribute_high,bright_white_on_black
                mov     diagram_attribute_low,white_on_black

                mov     error_attribute,black_on_bright_white

                call    display_header

                call    display_trailer

                call    screen_header

                call    screen_trailer

                jmp     display_mode_return

; Set up function key attributes

        Able_to_read_color:

                cld

                mov     cx,5

                mov     di,offset function_key_attributes

                rep     movsb

        Display_mode_return:

                mov     ax,0
                mov     ds,ax

                mov     bx,vision_parameters

                mov     al,color
                mov     [bx+1],al

                pop     es
                pop     ds

                ret

Display_mode    endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DRIVE MODE                                 |
; |                                                                       |
; |         If the system shows two disk drive ask the user if they       |
; |         are both Floppies.                                            |
; |                                                                       |
; -------------------------------------------------------------------------

Drive_mode      proc    near

                mov     source_drive,0
                mov     destination_drive,0

                cmp     number_of_drives,1
                jne     test_for_floppy

                jmp     drive_mode_return

        Test_for_floppy:

                call    clear_page

                mov     cx,offset drive_test_prompt
                mov     si,offset drive_test_menu
                call    display_menu

                mov     si,offset drive_test_string
                call    function_choice

                mov     destination_drive,1

                cmp     al,1
                jne     drive_mode_return

                mov     destination_drive,0
                mov     number_of_drives,1

        Drive_mode_return:

                push    ds

                mov     ax,0
                mov     ds,ax

                mov     bx,vision_parameters

                mov     al,number_of_drives
                mov     [bx],al

                pop     ds

                ret

Drive_mode     endp

Code_seg        ends

                end
s

        o   lnme_fdie        mv  [x,l

      