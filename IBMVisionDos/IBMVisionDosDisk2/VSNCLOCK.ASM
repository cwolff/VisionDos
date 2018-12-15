Name            VSNCLOCK

Title           Bruce_&_James_Inc_Command

Subttl          Vision_Clock

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

                        extrn any_file_name:byte
                        extrn batch_size:byte
                        extrn search_fcb:byte
                        extrn found_fcb:byte
                        extrn current_drive:byte
                        extrn source_drive:byte
                        extrn destination_drive:byte
                        extrn current_disk:byte
                        extrn number_of_drives:byte
                        extrn pitch:byte

                        extrn clear_page:near
                        extrn screen_page:near
                        extrn display_menu:near
                        extrn display_prompt:near
                        extrn check_heart_key:near
                        extrn function_choice:near
                        extrn open_file:near
                        extrn read_driver:near
                        extrn create_file:near
                        extrn write_driver:near
                        extrn close_file:near
                        extrn display_error:near
                        extrn work_error_prompt:near
                        extrn verify_work:near
                        extrn search_first_entry:near
                        extrn search_next_entry:near
                        extrn display_function_key:near
                        extrn error_beep:near

;
; *** Publics
;

                        public put_clock

                        public calendar_clock_command

;
; *** Equates
;

Carriage_return        equ    0dh
Line_feed              equ    0ah
Select                 equ    11h

Prompt_pitch           equ    08h

Page

;
; *** Ask if user has calendar clock
;

Clock_querry_prompt  db  2,36,'Does your computer have an optional '
                     db    25,'clock/calendar accessory.'

Clock_querry_menu    db  2
                     db  1
                     db  2,'No'
                     db  3
                     db  3,'Yes'

Clock_querry_string  db  2,1,3

;
; *** Calender disk prompt
;

Clock_disk_prompt  db  2
                   db  50,'Please insert the disk that has the clock/calendar'
                   db  23,'in drive '
Clock_drive        db  00
                   db     ', then press '

;
; *** Calender clock choice menu
;

Clock_choice_prompt  db    2
                     db    42,'Press the key next to the file name of the'
                     db    23,'clock/calendar program.'

Clock_choice_menu   db  5
                    db  1
                    db  12
Clock_file_1        db  '            '
                    db  2
                    db  12
Clock_file_2        db  '            '
                    db  3
                    db  12
Clock_file_3        db  '            '
                    db  4
                    db  46,'None of the above files is the clock/calendar.'
                    db  5
                    db  41,'Disk has been changed for different disk.'

Clock_choice_string db  5,1,2,3,4,5

;
; *** Calender clock variables
;

Calendar_clock_command     db  00
                           db  'xxxxxxxx.xxx'
                           db  carriage_return
                           db  line_feed

Calendar_clock_name        db  '           '

;
; *** Clock error prompt
;

Clock_error_prompt  db   3
                    db   48,'The clock/calendar program was not found on this'
                    db   47,'disk.  Please insert the clock/calendar disk in'
                    db   19,'drive '
Clock_error_drive   db      00,' then press '

;
; *** Clock read write errors
;

Not_legal_file_name    db  46,' SORRY: An empty file name has been selected. '

Read_clock_error       db  44,' SORRY: Unable to read clock/calendar file. '

Create_clock_error db 54,' SORRY: No room in directory for clock/calendar '
                   db    'file. '

Write_clock_error  db 57,' SORRY: No room on Working disk for clock/calendar '
                   db    'file. '

Close_clock_error  db 38,' SORRY: This is not the Working disk. '

Blank_clock_disk_message db  41,' SORRY: There are no files on this disk. '

;
; *** Directory buffer (use FILE_1_DTA)
;

Directory_buffer       db    112 dup ('           ')

Directory_buffer_end   dw    0000h

Directory_head    dw   0000h
Directory_tail    dw   0000h

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              PUT CLOCK                                |
; |                                                                       |
; |        Determine if there is a calendar clock and if so place        |
; |        the program on the working disk.                               |
; |                                                                       |
; -------------------------------------------------------------------------

Put_clock      proc     near

               call     clear_page

               mov      cx,offset clock_querry_prompt
               mov      si,offset clock_querry_menu
               call     display_menu

               mov      si,offset clock_querry_string
               call     function_choice

               cmp      al,3
               je       there_is_a_clock

               mov      calendar_clock_command,0

               jmp      put_clock_return

        There_is_a_clock:

               add      batch_size,14

               mov      calendar_clock_command,14

               call     determine_clock_name

               call     read_calendar_clock_file

               call     write_calendar_clock_file

        Put_clock_return:

               ret

Put_clock      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                       DETERMINE CLOCK NAME                            |
; |                                                                       |
; |                    Read in calendar clock file.                       |
; |                                                                       |
; -------------------------------------------------------------------------

Determine_clock_name proc near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

               call     clear_page

               mov      al,destination_drive
               mov      current_drive,al
               add      al,'A'
               mov      clock_drive,al

        Determine_clock_name_prompt:

               mov      si,offset clock_disk_prompt
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0826h
               call     display_function_key

               call     screen_page

        Read_clock_disk_response:

               call     check_heart_key

               jnc      read_clock_disk_response

               call     clear_page

               call     screen_page

;
; *** New disk fill up directory buffer
;

        New_clock_disk:

               call     get_directory

               jc       determine_clock_name_prompt  ; *** no files on disk
                                                     ; *** prompt for another
                                                     ; *** disk

;
; *** Get next set of three files
;

        New_file_list:

               call     fill_menu

;
; *** display choice menu
;

        Display_file_choice:

               call     clear_page

               mov      cx,offset clock_choice_prompt
               mov      si,offset clock_choice_menu
               call     display_menu

               mov      si,offset clock_choice_string
               call     function_choice

               cmp      al,1
               je       select_file_1

               cmp      al,2
               je       select_file_2

               cmp      al,3
               je       select_file_3

               cmp      al,4
               je       new_file_list

               call     clear_page
               call     screen_page

               jmp      new_clock_disk

        Select_file_1:

               mov      si,offset clock_file_1

               jmp      load_clock_name_file

        Select_file_2:

               mov      si,offset clock_file_2

               jmp      load_clock_name_file

        Select_file_3:

               mov      si,offset clock_file_3

;
; *** Load clock name in CALENDER_CLOCK_NAME and in CALENDER_CLOCK_COMMAND
;

        Load_clock_name_file:

               call     load_clock_name

               jnc      determine_clock_name_return

               mov      cx,offset not_legal_file_name

               call     display_error

               jmp      display_file_choice

        Determine_clock_name_return:

               pop      es
               pop      ds

               ret

Determine_clock_name endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           GET DIRECTORY                               |
; |                                                                       |
; |     Fill up DIRECTORY_BUFFER with all the file names on the disk      |
; |     and initialize the pointers DIRECTORY_HEAD and DIRECTORY_TAIL.    |
; |                                                                       |
; |     Output:                                                           |
; |             CY - 1 no files on disk,  CY - 0 successful load          |
; |                                                                       |
; -------------------------------------------------------------------------

Get_directory  proc     near

               cld

               mov      cx,11 * 112
               mov      al,' '
               mov      di,offset directory_buffer

               rep      stosb              ; *** flush directory buffer

               mov      ax,offset directory_buffer
               mov      directory_head,ax
               mov      directory_tail,ax

               mov      al,1
               mov      si,offset any_file_name 
               call     search_first_entry

               jnc      continue_directory_load

               jmp      clock_disk_is_blank

        Continue_directory_load:

               cld

               mov      cx,11
               mov      si,offset found_fcb
               inc      si
               mov      di,directory_tail

               rep      movsb

               mov      directory_tail,di

        Fill_directory_loop:

               call     search_next_entry

               jc       end_of_directory_load

               cld

               mov      cx,11
               mov      si,offset found_fcb
               inc      si
               mov      di,directory_tail

               rep      movsb

               mov      directory_tail,di

               mov      ax,offset directory_buffer_end
               cmp      di,ax
               jae      end_of_directory_load

               jmp      fill_directory_loop

        End_of_directory_load:

               clc

               jmp      get_directory_return

        Clock_disk_is_blank:

               mov      cx,offset blank_clock_disk_message

               call     display_error

               stc

        Get_directory_return:

               ret

Get_directory  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                               FILL MENU                               |
; |                                                                       |
; |       Fills the menu (3 soft keys) with the next 3 fill names from    |
; |       DIRECTORY_BUFFER. This continues until DIRECTORY_TAIL is        |
; |       reached. DIRECTORY_HEAD is also updated to represent the        |
; |       current position in DIRECTORY BUFFER.                           |
; |                                                                       |
; -------------------------------------------------------------------------

Fill_menu      proc     near

               mov      ax,directory_head
               cmp      ax,directory_tail
               jne      flush_menu

               mov      pitch,prompt_pitch
               call     error_beep

               jmp      fill_menu_return

;
; *** Flush CLOCK_FILE_1, CLOCK_FILE_2, CLOCK_FILE_3
;

        Flush_menu:

               cld

               mov      cx,12
               mov      al,' '
               mov      di,offset clock_file_1

               rep      stosb

               mov      cx,12
               mov      di,offset clock_file_2

               rep      stosb

               mov      cx,12
               mov      di,offset clock_file_3

               rep      stosb

;
; *** Load CLOCK_FILE_1
;

               mov      di,offset clock_file_1

               call     fill_menu_file

               jnc      load_clock_file_2

               jmp      fill_menu_return

;
; *** Load CLOCK_FILE_2
;

        Load_clock_file_2:

               mov      di,offset clock_file_2

               call     fill_menu_file

               jnc      load_clock_file_3

               jmp      fill_menu_return

;
; *** Load CLOCK_FILE_3
;

        Load_clock_file_3:

               mov      di,offset clock_file_3

               call     fill_menu_file               

        Fill_menu_return:

               ret

Fill_menu      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          FILL MENU FILE                               |
; |                                                                       |
; |         DI - offset of CLOCK_FILE_X                                   |
; |         CY - 1 end of DIRECTORY_BUFFER                                |
; |                                                                       |
; -------------------------------------------------------------------------

Fill_menu_file proc     near

               mov      si,directory_head
               cmp      si,directory_tail
               jbe      ok_to_get_file_name

               jmp      end_of_directory_buffer

        Ok_to_get_file_name:

               mov      cx,8

               rep      movsb

               mov      al,' '
               mov      [di],al
               inc      di

               mov      cx,3

               rep      movsb

               mov      directory_head,si

               cmp      si,directory_tail
               je       end_of_directory_buffer

               clc

               jmp      fill_menu_file_return

        End_of_directory_buffer:

               stc

        Fill_menu_file_return:

               ret

Fill_menu_file endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         LOAD CLOCK NAME                               |
; |                                                                       |
; |     Input:                                                            |
; |                                                                       |
; |        SI - offset of file selected                                   |
; |                                                                       |
; |        Setup CALENDER_CLOCK_NAME (11 digits lower case)               |
; |        Setup CALENDER_CLOCK_COMMAND (standard A> form xxxxxxxx.xxx)   |
; |                                                                       |
; |     Output:                                                           |
; |                                                                       |
; |        CY - 0 legal file name, CY - 1 illegal file (all blanks)       | 
; |                                                                       |
; -------------------------------------------------------------------------

Load_clock_name proc    near

               push     si

               mov      al,[si]
               cmp      al,' '
               jne      load_calendar_clock_name

               stc

               jmp      load_clock_name_return

;
; *** Load CALENDER_CLOCK_NAME, but first flush
;

        Load_calendar_clock_name:

               mov      al,' '
               mov      cx,11
               mov      di,offset calendar_clock_name

               rep      stosb

               pop      si
               push     si

               mov      cx,8
               mov      di,offset calendar_clock_name

               rep      movsb

               inc      si

               mov      cx,3

               rep      movsb

;
; *** Load CALENDER_CLOCK_COMMNAND   #### left off here ####
;

               mov      al,' '
               mov      cx,12
               mov      di,offset calendar_clock_command
               inc      di

               rep      stosb

               pop      si
               push     si

               mov      cx,8
               mov      di,offset calendar_clock_command
               inc      di

        First_half_loop:

               mov      al,[si]

               cmp      al,' '
               je       put_in_period

               mov      [di],al

               inc      si
               inc      di

               loop     first_half_loop

        Put_in_period:

               mov      al,'.'
               mov      [di],al

               inc      di

               pop      si
               push     si

               add      si,9

               mov      cx,3

               rep      movsb

        Load_clock_name_return:

               pop      si

               ret

Load_clock_name endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                        READ CALENDER CLOCK FILE                       |
; |                                                                       |
; -------------------------------------------------------------------------

Read_calendar_clock_file proc near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

               mov      current_disk,1

               jmp      read_clock_file

        Read_clock_error_prompt:

               call     clear_page

               mov      al,current_drive
               add      al,'A'
               mov      clock_error_drive,al

               mov      si,offset clock_error_prompt
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0922h
               call     display_function_key

               call     screen_page

        Read_clock_response:

               call     check_heart_key

               jnc      read_clock_response

               call     clear_page

               call     screen_page

;
; *** Check to see if calendar/clock is on disk.
;

        Read_clock_file:

               mov      al,0
               mov      dl,1
               mov      si,offset calendar_clock_name
               call     open_file

               jc       read_clock_error_prompt

               mov      al,1
               call     read_driver

               jnc      read_clock_return

               mov      cx,offset read_clock_error

               call     display_error

               jmp      read_clock_error_prompt

        Read_clock_return:

               pop      es
               pop      ds

               ret

Read_calendar_clock_file endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         WRITE CALENDER CLOCK FILE                     |
; |                                                                       |
; -------------------------------------------------------------------------

Write_calendar_clock_file proc near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

               mov      al,source_drive
               mov      current_drive,al
               mov      current_disk,2

               cmp      number_of_drives,2
               je       clock_write_verify

        Write_clock_error_prompt:

               call     work_error_prompt

        Clock_write_verify:

               call     verify_work

               jc       write_clock_error_prompt

;
; *** Create MODE.COM file
;

               mov      al,0
               mov      dl,1
               call     create_file

               jnc      write_clock_file

               mov      cx,offset create_clock_error

               jmp      display_write_clock_error

        Write_clock_file:

               mov      al,1
               call     write_driver

               jnc      close_clock

               mov      cx,offset write_clock_error

               jmp      display_write_clock_error

        Close_clock:

               mov      dl,1
               call     close_file

               jnc      write_clock_return

               mov      cx,offset close_clock_error

        Display_write_clock_error:

               call     display_error

               sub      batch_size,14

               mov      calendar_clock_command,0  ; disable clock command

        Write_clock_return:

               pop      es
               pop      ds

               ret

Write_calendar_clock_file endp

Code_seg       ends

                end
_e    ns

        ne  s
    e 
  e
 

dsbecokcmad

    rt_lc_eun        o   e        o   d        eWieclna_lc_ieedCd    non_ibm_monochrome_check

                jmp     ibm_monochrome

        Non_i