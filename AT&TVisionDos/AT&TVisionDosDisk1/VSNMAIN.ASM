Name            VSNMAIN

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_main

Page 60,126

; *************************************************************************
; *                                                                       *
; *      (C)opyright 1983 Bruce & James Program Publishers Inc.           *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Page

Code_seg        segment public 'code'

                assume  cs:code_seg

                org     100h

;
; *** Externals
;

                extrn  load_dos:near
                extrn  write_system_set:near
                extrn  make_batch_file:near
                extrn  master_error_prompt:near
                extrn  verify_master:near
                extrn  hide_command_file:near
                extrn  write_protect_prompt:near
                extrn  write_protect_error_prompt:near
                extrn  write_protect_master_check:near
                extrn  format_work_copy:near
                extrn  transfer_master_files:near
                extrn  kb_int:near
                extrn  key_board:far
                extrn  clear_video:near
                extrn  display_opening_screen:near
                extrn  keyboard_mode:near
                extrn  display_mode:near
                extrn  drive_mode:near
                extrn  display_header:near
                extrn  display_trailer:near
                extrn  display_vision_picture:near
                extrn  screen_header:near
                extrn  screen_trailer:near
                extrn  dos_error_handler:near
                extrn  clear_page:near
                extrn  dos_exit:near
                extrn  esc_prompt:near
                extrn  display_error:near
                extrn  error_beep:near

                extrn  file_1_dta:word
                extrn  end_of_data:byte
                extrn  m_disk:byte
                extrn  d_disk:byte
                extrn  w_disk:byte

;
; *** Publics
;

                public  load_indicator
                public  dos_segment
                public  dos_offset
                public  rom_reboot
                public  labels
                public  vertical
                public  color_off_on
                public  source_drive
                public  destination_drive
                public  system_configuration
                public  number_of_drives
                public  current_drive
                public  current_disk
                public  number_of_drives
                public  screen_step
                public  screen_step_message
                public  screen_seg
                public  general_dta_1
                public  general_dta_2
                public  general_dta_seg
                public  end_of_memory
                public  sectors_per_track
                public  addr_6845
                public  mode_select_register
                public  color
                public  video_seg
                public  special_attributes
                public  function_key_attributes
                public  header_attribute
                public  header_text_attribute_low
                public  header_text_attribute_high
                public  trailer_attribute
                public  trailer_text_attribute
                public  main_text_attribute
                public  diagram_attribute_high
                public  diagram_attribute_low
                public  error_attribute
                public  running_dos_version
                public  master_write_protect_tab
                public  disk_write_protect_error

Page

;
; *** Equates
;

         ;
         ; *** Conditional assembly vaules
         ;

         On                            equ     1
         Off                           equ     0

         Wv_keyboard                   equ     on
         Skip_workcopy                 equ     off

;
; *** Screen attributes
;

White_on_black                equ     07h
Bright_white_on_black         equ     0fh
Black_on_white                equ     70h
Black_on_bright_white         equ     0f0h

Cyan_on_black                 equ     03h
Blue_on_black                 equ     01h
Cyan_on_blue                  equ     13h
Green_on_black                equ     02h
White_on_red                  equ     47h

;
; *** Function key colors
;

Black_on_bright_red           equ     0c0h
Black_on_bright_yellow        equ     0e0h
Black_on_bright_green         equ     0a0h
Black_on_bright_cyan          equ     0b0h
Black_on_bright_magenta       equ     0d0h

Vision_parameters             equ     4f0h

;
; *** Hardware addresses
;

Crt_mode_port                 equ     03d8h

Address_6845                  equ     63h
Crt_mode_set                  equ     65h

Data_seg                      equ     40h
Int_seg                       equ     00h

;
; *** Load indicators
;

Loaded_by_vsnboot             equ     0ffffh
Loaded_by_go                  equ     0fffeh
Loaded_by_command             equ     0fffdh

Page

; =========================================================================
; *                                                                       *
; *                              VSNMAIN                                  *
; *                                                                       *
; *    Purpose of this program is to generate a working copy diskette     *
; *    that is configured to the user specifications. This includes       *
; *    the keyboard layout screen type and number of drives. These        *
; *    parameters are written to SYSTEM.SET. The working disk will        *
; *    also contain a batch file that will install a clock calender       *
; *    if one is present along with the MODE.COM instructions if a        *
; *    serial printer is being used and will also start WORDVISION        *
; *    upon boot or command (which ever is specified).                    * 
; *                                                                       *
; =========================================================================

Vision_main     proc    far

                jmp     main_start

;
; *** Indicates who loaded VSNDOS.COM (vsnboot, setup or xxxdos.com)
;

Load_indicator             dw     0000h

;
; *** Idicates what version of DOS prepare is running under
;

Running_dos_version        db     00h

Master_write_protect_tab   db     00h

Disk_write_protect_error   db     00h

;
; *** Psuedo screen segment
;

Screen_seg                 dw     0000h

;
; *** Disk transfer segments
;

General_dta_1              dw     0000h

General_dta_2              dw     0000h

General_dta_seg            dw     0000h

;
; *** Hardware variables
;

Addr_6845                  dw     0000h

Mode_select_register       db     00h

Video_seg                  dw     0000h

System_configuration       dw     0000h

;
; *** Configuration attributes
;

Color                      db     00h
Vertical                   db     00h
Labels                     db     00h

;
; *** Screen attributes
;

Header_attribute           db     white_on_black
Header_text_attribute_high db     bright_white_on_black
Header_text_attribute_low  db     white_on_black

Trailer_attribute          db     white_on_black
Trailer_text_attribute     db     black_on_white

Main_text_attribute        db     white_on_black

Diagram_attribute_high     db     bright_white_on_black
Diagram_attribute_low      db     white_on_black

Error_attribute            db     black_on_bright_white

;
; *** Function key attributes if color
;

Function_key_attributes    db     5 dup (black_on_bright_white)

Special_attributes         db     black_on_bright_red
                           db     black_on_bright_yellow
                           db     black_on_bright_green
                           db     black_on_bright_cyan
                           db     black_on_bright_magenta

;
; *** Memory size variables
;

One_k_byte                 dw     40h

End_of_memory              dw     0000h

;
; *** Determines if monitor is to be turned off and on
;

Color_off_on               db     00h

;
; *** Used to rebuild trailer after an error message
;

Screen_step                db     00h
Screen_step_message        dw     0000h

;
; *** Drive and disk variables
;

Source_drive               db     00h
Destination_drive          db     00h

Current_drive              db     00h
Current_disk               db     00h

Number_of_drives           db     00h

;
; *** Disk parameter block
;

Disk_parameter_block       db     0cfh
                           db     02h
                           db     25h
                           db     02h
Sectors_per_track          db     08h
                           db     2ah
                           db     0ffh
                           db     50h
                           db     0f6h
                           db     19h
                           db     04h

;
; *** Tansfer address to to XXXDOS.COM
;

Dos_transfer               label  dword

Dos_offset                 dw     0000h
Dos_segment                dw     0000h

;
; *** Rom reboot loacation
;

Rom_reboot                  label  dword

                            dw     0000h
                            dw     0ffffh

;
; *** Step messages for trailer line
;

Describing_message          db     32,'Describing your computer setup. '

Preparing_message           db     26,'Preparing the blank disk. '

;
; *** Illegal entry 
;

Illegal_prepare_entry db 68,' SORRY: Illegal entry, Type go or boot Master'
                      db    ' to make Working copy. '

;
; *** Copyright, version and author message
;

Copyright_message           db     '(C)opyright 1983 Bruce & James '
                            db     'Program Publishers Inc.'

Vsn_version                 db      'VSNDOS.COM 2.0 08/83'

Author_message              db     'Author - Cameron L. Wolff'

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          Main Start                                   |
; |                                                                       |
; |      Determine who loaded VSNDOS and proceed acordling                |
; |                                                                       |
; |      If ES = 0ffffh then loaded by vsnboot                            |
; |              Perform configuration                                    |
; |              Load and jump to XXXDOS                                  |
; |                                                                       |
; |      If ES = 0fffeh then loaded by go                                 |
; |              Perform configuration                                    |
; |              Make working copy and reboot                             |
; |                                                                       |
; |      Else loaded by XXXDOS                                            |
; |              Make working copy and reboot                             |
; |                                                                       |
; -------------------------------------------------------------------------

        Main_start:

                cli

;
; *** Set up segment registers and stack pointer
;

                mov     load_indicator,es

                mov     ax,cs
                mov     ds,ax
                mov     es,ax
                mov     ss,ax
                mov     sp,100h

                sti

                call    general_setup

;
; *** Determine who loaded program and proceed acordling
;

                cmp     load_indicator,loaded_by_vsnboot
                je      boot_load

                cmp     load_indicator,loaded_by_go
                je      go_load

                cmp     load_indicator,loaded_by_command
                je      command_load

                call    illegal_entry

;
; *** Loaded by XXXDOS.COM
;

        Command_load:

                call    video_setup

                call    system_setup

                jmp     prepare_working_copy

;
; *** Loaded by VSNBOOT
;

        Boot_load:

                call    configuration_driver

                call    load_dos

;
; *** XXXBIO & XXXDOS loaded transfer control to them with workcopy in drive A:
;

;
; *** XXXBIO.COM address
;

                jmp     dos_transfer       ; exit to XXXBIO.COM

;
; *** Loaded by GO.COM, First determine Version of DOS that Prepare is
; *** running under.
;

        Go_load:

                mov     ah,30h
                int     21h               

                mov     running_dos_version,al

                call    configuration_driver

;
; *** Make working copy
;

        Prepare_working_copy:

                if      skip_workcopy      ; **********************
                                           ; Skip make workcopy
                                           ; to speed up debuging

                        jmp     call_make_batch_file

                endif                      ; **********************

                call    make_working_copy

                call    write_system_set

        Call_make_batch_file:

                mov     m_disk,2
                mov     d_disk,2
                mov     w_disk,0

                call    make_batch_file

;
; *** Working copy is made reboot the system with WORKCOPY or IBM DOS
; *** in drive A:
;

                jmp      dos_exit

Vision_main     endp

Page

; =========================================================================
; |                                                                       |
; |                          CONFIGURATION DRIVER                         |
; |                                                                       |
; =========================================================================

Configuration_driver proc near

               mov     ax,0600h
               mov     bh,white_on_black
               mov     cx,0000h
               mov     dx,184fh
               int     10h

               call    clear_video

               call    display_opening_screen

;
; *** Determine key board legends and if vertical or horizontial function keys
;

               call    keyboard_mode

;
; *** Determine if they have a color monitor
;

               call    display_mode

;
; *** Determine the number of drives
;

               call     drive_mode

               mov      m_disk,0
               mov      d_disk,2
               mov      w_disk,2

               ret

Configuration_driver  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                      MAKE WORKING COPY DRIVER                         |
; |                                                                       |
; -------------------------------------------------------------------------

Make_working_copy proc    near

                mov     cx,offset preparing_message
                mov     screen_step_message,cx

                mov     screen_step,'2'

                call    display_trailer
                call    screen_trailer

                mov     m_disk,0
                mov     d_disk,1
                mov     w_disk,2

                cmp     load_indicator,loaded_by_go
                je      only_one_disk_in_drive

                cmp     number_of_drives,1
                jne     prepare_to_hide

        Only_one_disk_in_drive:

                mov     d_disk,2

;
; *** Hide COMMAND.COM file
;

        Prepare_to_hide:

                mov      al,source_drive
                mov      current_drive,al
                mov      current_disk,0

                jmp      try_to_hide_command_file

        Wrong_disk_to_hide_prompt:

                call     master_error_prompt

        Try_to_hide_command_file:

                call     verify_master

                jc       wrong_disk_to_hide_prompt

                call     hide_command_file

                jc       wrong_disk_to_hide_prompt

;
; *** Prompt for write protection
;

        Write_protect_disk_prompt:

                call     write_protect_prompt

                jmp      verify_write_protection

        Error_write_protect_prompt:

                call     write_protect_error_prompt

        Verify_write_protection:

                call     verify_master

                jc       error_write_protect_prompt

                call     write_protect_master_check

                jc       error_write_protect_prompt

                mov      master_write_protect_tab,1

;
; *** Format working disk
;

        Format_work_copy_loop:

                call     format_work_copy

;
; *** Transfer IBM DOS files and MASTER files
;

                call     transfer_master_files

                ret

Make_working_copy endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             GENERAL SETUP                             |
; |                                                                       |
; |     Regardless of who calls VSNDOS these tasks must be performed      |
; |                                                                       |
; -------------------------------------------------------------------------

General_setup  proc    near

               push    ds

               cli

               mov     ax,int_seg
               mov     ds,ax

               if      wv_keyboard         ; ************************
                                           ; Leave keyboard interrupts
                                           ; with DOS for DEBUG to use.

;
; *** Set keyboard int 16 address
;

                       mov     bx,24h
                       mov     ax,offset kb_int
                       mov     [bx],ax
                       mov     [bx+2],cs

;
; *** Set keyboard i/o address
;

                       mov     bx,58h
                       mov     ax,offset key_board
                       mov     [bx],ax
                       mov     [bx+2],cs

               endif                       ; ************************

;
; *** Set fatal DOS disk error interrupt
;

                       mov     bx,90h
                       mov     ax,offset dos_error_handler
                       mov     [bx],ax
                       mov     [bx+2],cs

;
; *** Set disk pointer
;

               mov      bx,78h
               mov      ax,offset disk_parameter_block
               mov      [bx],ax
               mov      [bx+2],cs

               sti

;
; *** Get port address
;

               mov     ax,data_seg
               mov     ds,ax

               mov     bx,address_6845
               mov     dx,[bx]
               mov     addr_6845,dx
               add     addr_6845,6

;
; *** Disable background blink (allows high intensity background attribute)
;

               mov     bx,crt_mode_set
               mov     al,[bx]

               and     al,1fh
               mov     mode_select_register,al

               add     dx,4
               out     dx,al

               mov     bx,crt_mode_set
               mov     [bx],al

;
; *** Disable cursor (makes cursor invisible)
;

               sub     dx,4

               mov     al,10
               out     dx,al

               inc     dx

               mov     al,20h
               out     dx,al

               pop     ds

;
; *** Determine system configuration
;

        Equipment_determination:

               mov     number_of_drives,1

               int     11h

               mov     system_configuration,ax

               push    ax

               and     al,0c0h
               jz      screen_type

               mov     number_of_drives,2

        Screen_type:

               pop     ax

               mov     color,2            ; assume IBM other mono
               mov     color_off_on,1
               mov     video_seg,0b800h

               and     ax,30h

               cmp     ax,30h

               jne     calculate_seg

               mov     color,1            ; assume IBM monochrome
               mov     color_off_on,0
               mov     video_seg,0b000h

        Calculate_seg:

               mov     ax,offset end_of_data
               mov     cl,4
               shr     ax,cl
               inc     ax

               mov     bx,cs
               add     ax,bx

               mov     screen_seg,ax

               add     ax,100h
               mov     general_dta_1,ax

               add     ax,20h
               mov     general_dta_2,ax

               add     ax,20h
               mov     general_dta_seg,ax

               add     ax,20h
               mov     file_1_dta,ax

;
; *** Determine end of memory for transfer program
;

        Get_end_of_memory:

               int      12h

               cwd

               mul      one_k_byte

               dec      ax

               mov      end_of_memory,ax

;
; *** Set up default values
;

               mov      labels,2
               mov      vertical,1

               mov      master_write_protect_tab,0
               mov      disk_write_protect_error,3

               mov     cx,offset describing_message
               mov     screen_step_message,cx
               mov     screen_step,'1'

               ret

General_setup  endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                             VIDEO SETUP                              |
; |                                                                      |
; |            Perform video setup that is necessary if XXXDOS.COM       |
; |                          has loaded program                          |
; |                                                                      |
; ------------------------------------------------------------------------

Video_setup    proc     near

               push     ds

;
; *** Get color driver type and set attributes
;

               mov      ax,0
               mov      ds,ax

               mov      bx,vision_parameters
               mov      al,[bx+1]

               cmp      al,0
               jne      set_color

;
; *** COMMAND.COM was visible and typed in by the user
;

               pop      ds

               call     illegal_entry      ; *** EXIT to DOS

        Set_color:

               mov      color,al

               pop      ds

        Ibm_monochrome_check:

                cmp     color,1
                jne     non_ibm_monochrome_check

                jmp     ibm_monochrome

        Non_ibm_monochrome_check:

                cmp     color,2
                jne     ibm_color_check

                jmp     non_ibm_monochrome

        Ibm_color_check:

                cmp     color,3
                jne     compaq_check

                jmp     ibm_color

        Compaq_check:

                cmp     color,4
                jne     special_color_check

                jmp    compaq

        Special_color_check:

                jmp     special_color

;
; *** Monitor types
;

        Ibm_monochrome:

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

                jmp     initial_video_return

        Non_ibm_monochrome:

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

                jmp     initial_video_return

        Ibm_color:

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

                cld
                mov     cx,5
                mov     si,offset special_attributes
                mov     di,offset function_key_attributes

                rep     movsb

                jmp     initial_video_return

        Compaq:

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

                jmp     initial_video_return

        Special_color:

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

                cld
                mov     cx,5
                mov     si,offset special_attributes
                mov     di,offset function_key_attributes

                rep     movsb

        Initial_video_return:

                call    clear_video

                ret

Video_setup     endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          SYSTEM SETUP                                |
; |                                                                      |
; |             Perform system setup if called by XXXDOS.COM             |
; |                                                                      |
; ------------------------------------------------------------------------

System_setup   proc    near

               push     ds

               mov      ax,0
               mov      ds,ax

;
; *** Get number of drives and color status passed by VSNDOS
;

               mov      bx,vision_parameters
               mov      al,[bx]

               cmp      al,0
               jne      set_number_of_drives

               pop      ds

               call     illegal_entry      ; *** EXIT to DOS

        Set_number_of_drives:

               mov      number_of_drives,al
               mov      al,[bx+2]

               cmp      al,0
               jne      set_vertical

               pop      ds

               call     illegal_entry      ; *** EXIT to DOS

        Set_vertical:

               mov      vertical,al
               mov      al,[bx+3]

               cmp      al,0
               jne      set_labels

               pop      ds

               call     illegal_entry      ; *** EXIT to DOS

        Set_labels:

               mov      labels,al

;
; *** Determine source and destination drives as passed by vision
; *** configuration program
;

                cmp      number_of_drives,1
                je       one_drive

                mov      source_drive,0
                mov      destination_drive,1
                jmp      initial_system_return

        One_drive:

                mov      source_drive,0
                mov      destination_drive,0

        Initial_system_return:

                pop      ds

                sti

                ret

System_setup    endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              ILLEGAL ENTRY                            |
; |                                                                       |
; -------------------------------------------------------------------------

Illegal_entry  proc     near

;
; *** Invalid entry into prepare program, inform user
; *** and exit to DOS
;

               mov     ah,6
               mov     al,0
               mov     bh,07h
               mov     cx,0
               mov     dx,184fh
               int     10h

               call    clear_video

               call    display_header
               call    display_trailer

               call    screen_header
               call    screen_trailer

               call    display_vision_picture

               xor     cx,cx

        Stall_loop:

               loop    stall_loop

               mov     cx,offset illegal_prepare_entry
               call    display_error

               call    esc_prompt         ; *** EXIT TO DOS

Illegal_entry  endp

Code_seg       ends

               end   vision_main
 vision_main
 tilglpeaeety
       cl  dslyerr

       cl  ecp