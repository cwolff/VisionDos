Name            VSNBATCH

Title           Bruce_&_James_Inc_Command

Subttl          Vision_Batch

Page 60,132

; *************************************************************************
; *                                                                       *
; *      (C)opyright 1983 Bruce & James Program Publisher Inc.            *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg       segment public 'code'

               assume cs:code_seg

               org   100h

;
; *** Externals
;

                        extrn screen_step:byte
                        extrn current_disk:byte
                        extrn current_drive:byte
                        extrn source_drive:byte
                        extrn current_error:byte
                        extrn file_1_dta:word
                        extrn file_1_fcb:byte
                        extrn screen_step_message:word
                        extrn calendar_clock_command:byte
                        extrn serial_printer_command:byte

                        extrn display_trailer:near
                        extrn screen_trailer:near
                        extrn clear_page:near
                        extrn check_heart_key:near
                        extrn work_error_prompt:near
                        extrn display_function_key:near
                        extrn function_choice:near
                        extrn screen_page:near
                        extrn display_message:near
                        extrn display_prompt:near
                        extrn display_menu:near
                        extrn verify_work:near
                        extrn display_error:near
                        extrn rename_file:near
                        extrn create_file:near
                        extrn write_driver:near
                        extrn close_file:near
                        extrn printer_configuration:near
                        extrn put_clock:near

;
; *** Publics
;

                        public make_batch_file

                        public batch_size

;
; *** Equates
;

Carriage_return        equ    0dh
Line_feed              equ    0ah
Select                 equ    11h

Page

;
; *** Start up batch file commands
;

Automatic                  db  00h

Start_up_command           db  10
                           db  'word.exe'
                           db  carriage_return
                           db  line_feed

Batch_size                 dw  0000h

Wv_exe_file                db  'WV      EXE'
Word_exe_file              db  'WORD    EXE'

Wv_bat                     db  'WV      BAT'
Autoexec_bat               db  'AUTOEXECBAT'

Go_name                    db  'GO      COM'

;
; *** Copying done message
;

Copying_done_message    db  4

    db      52,'Copying of disk files is done. Take out and put away'
    db      50,'your Wordvision Master disk. Leave the new working'
    db      39,'copy in computer for final preparation.'
    db      18,'To continue press '

Setting_up_batch_file   db  21,'Preparing batch file '

End_of_prepare_program  db  23,'End of prepare program '

;
; *** Startup Mode
;

Start_up_prompt    db 1,49,'Which way do you prefer to have Wordvision start?'

Start_up_menu      db 2
                   db 1
                   db 41,'Automatically when I turn on the computer'
                   db 3
                   db 31,'By typing "WV" and pressing ',17,196,217

Start_up_string    db 2,1,3

;
; *** End Mode
;

End_prompt        db 5

    db     53,'Your Wordvision working copy is now ready to use.  To'
    db     53,'make another copy you can either repeat this process,'
    db     27,'or use a disk copy program.'
    db     01,' '
    db     26,'To use working copy press '

;
; *** Batch file error message
;

Wv_exe_rename_error    db  44,' SORRY: Unable to rename WV.EXE to WORD.EXE. '

Batch_file_create_error db 51,' SORRY: Directory is full, no room for batch '
                        db    'file. '

Batch_file_write_error  db 40,' SORRY: No room on disk for batch file. '

Batch_file_close_error  db 38,' SORRY: This is not the Working Disk. '

Page

; =========================================================================
; |                                                                       |
; |                          MAKE BATCH FILE                              |
; |                                                                       |
; =========================================================================

Make_batch_file proc  near

               call     clear_page

               mov      si,offset copying_done_message
               mov      dx,070eh
               call     display_prompt

               mov      al,3
               mov      dx,0a20h
               call     display_function_key

               call     screen_page

        Make_batch_continue_loop:

               call     check_heart_key

               jnc      make_batch_continue_loop

               mov      screen_step,'4'
               mov      screen_step_message,offset setting_up_batch_file

               call     display_trailer
               call     screen_trailer

               mov      batch_size,0

;
; *** Check for calendar clock
;

               call     put_clock

               call     printer_configuration

               call     start_mode

               mov      al,source_drive
               mov      current_drive,al
               mov      current_disk,2

               jmp      check_write_batch_files

        Write_batch_file_error:

               call     work_error_prompt

        Check_write_batch_files:

               call     verify_work

               jc       write_batch_file_error

               call     delete_go_file

               call     create_batch_file

               call     prepare_exit

               ret

Make_batch_file endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                               START MODE                              |
; |                                                                       |
; |       Determine if Wordvision is to start automatically or via        |
; |       the WV command.                                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Start_mode     proc     near

               call     clear_page

               mov      cx,offset start_up_prompt
               mov      si,offset start_up_menu
               call     display_menu

               mov      si,offset start_up_string
               call     function_choice

               mov      automatic,1

               cmp      al,1
               je       start_mode_return

               mov      automatic,0

        Start_mode_return:

               add      batch_size,10

               ret

Start_mode     endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              CREATE BATCH FILE                        |
; |                                                                       |
; -------------------------------------------------------------------------

Create_batch_file proc  near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

               cld

               call     setup_batch_dta

;
; *** test if batch file necessary
;

               cmp      automatic,1
               je       create_autoexec_bat

               cmp      calendar_clock_command,0
               jne      create_wv_bat

               cmp      serial_printer_command,0
               jne      create_wv_bat

               jmp      create_batch_file_return

;
; *** Create AUTOEXEC.BAT then create WV.BAT
;

        Create_autoexec_bat:

               mov      si,offset autoexec_bat

               call     write_batch_file

               jnc      create_wv_bat

               jmp      display_batch_file_error

;
; *** Create WV.BAT must rename WV.EXE to WORD.EXE
;

        Create_wv_bat:

               mov      si,offset wv_exe_file
               mov      di,offset word_exe_file
               call     rename_file

               jnc      continue_with_wv_start

               mov      cx,offset wv_exe_rename_error

               jmp      display_batch_file_error

        Continue_with_wv_start:

               mov      si,offset wv_bat

               call     write_batch_file

               jnc      create_batch_file_return

;
; *** Display critical batch file error
;

        Display_batch_file_error:

               call     display_error

        Create_batch_file_return:

               pop     es
               pop     ds

               ret

Create_batch_file endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            WRITE BATCH FILE                           |
; |                                                                       |
; |         SI - offset of file control block                             |
; |                                                                       |
; -------------------------------------------------------------------------

Write_batch_file proc   near

               push     ds
               push     es

               mov      cx,11
               mov      di,offset file_1_fcb
               mov      al,current_drive
               inc      al
               mov      [di],al
               inc      di

               rep      movsb

               mov      bx,offset file_1_fcb

               mov      ax,batch_size
               mov      [bx+16],ax
               xor      ax,ax
               mov      [bx+18],ax

               mov      al,0
               mov      dl,1
               call     create_file

               jnc      write_batch_file_operation

               mov      cx,offset batch_file_create_error

               jmp      critical_batch_file_error

;
; *** Write batch file
;

        Write_batch_file_operation:

               mov      al,1
               call     write_driver

               jnc      close_batch_file

               mov      cx,offset batch_file_write_error

               jmp      critical_batch_file_error

        Close_batch_file:

               mov      dl,1
               call     close_file

               jnc      create_batch_file_return

               mov      cx,offset batch_file_close_error

        Critical_batch_file_error:

               stc

        Write_batch_file_return:

               pop     es
               pop     ds

               ret

Write_batch_file endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            SETUP BATCH DTA                            |
; |                                                                       |
; -------------------------------------------------------------------------

Setup_batch_dta proc    near

               push     es

               mov      es,file_1_dta
               xor      di,di

               cmp      calendar_clock_command,0
               je       check_serial_command

               mov      si,offset calendar_clock_command
               xor      ch,ch
               mov      cl,[si]
               inc      si

               rep      movsb

        Check_serial_command:

               cmp      serial_printer_command,0
               je       get_start_up_command

               mov      si,offset serial_printer_command
               xor      ch,ch
               mov      cl,[si]
               inc      si

               rep      movsb

        Get_start_up_command:

               mov      si,offset start_up_command
               xor      ch,ch
               mov      cl,[si]
               inc      si

               rep      movsb

        Setup_batch_dta_return:

               pop      es

               ret

Setup_batch_dta endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           PREPARE EXIT                                |
; |                                                                       |
; |         Ask user if they wish to exit to working disk of IBM DOS      |
; |                                                                       |
; -------------------------------------------------------------------------

Prepare_exit   proc     near

               mov      screen_step,'5'
               mov      screen_step_message,offset end_of_prepare_program

               call     display_trailer
               call     screen_trailer

               call     clear_page

               mov      si,offset end_prompt
               mov      dx,070dh
               call     display_prompt

               mov      al,3
               mov      dx,0b28h
               call     display_function_key

               call     screen_page

        Final_choice_pause:

               call     check_heart_key

               jnc      final_choice_pause

               ret

Prepare_exit   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DELETE GO FILE                             |
; |                                                                       |
; -------------------------------------------------------------------------

Delete_go_file proc     near

               push     ds

               push     cs
               pop      ds

               cld

               mov      cx,11
               mov      si,offset go_name
               mov      di,offset file_1_fcb
               mov      al,current_drive
               inc      al
               mov      [di],al
               inc      di

               rep      movsb

               mov      ah,13h
               mov      dx,offset file_1_fcb
               int      21h

               pop      ds

               ret

Delete_go_file endp

Code_seg       ends

                end
t   1        o   d        eDlt_ofl np

oesg   ed        ed
t 1          el_f p
eg e    e
      elfpe   
  e