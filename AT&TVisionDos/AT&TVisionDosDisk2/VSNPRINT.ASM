Name            VSNPRINT

Title           Bruce_&_James_Inc_Command

Subttl          Vision_Print

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

                        extrn source_drive:byte
                        extrn destination_drive:byte
                        extrn current_drive:byte
                        extrn current_disk:byte
                        extrn number_of_drives:byte
                        extrn batch_size:word
                        extrn load_indicator:word

                        extrn clear_page:near
                        extrn check_heart_key:near
                        extrn display_function_key:near
                        extrn function_choice:near
                        extrn screen_page:near
                        extrn display_prompt:near
                        extrn display_menu:near
                        extrn open_file:near
                        extrn close_file:near
                        extrn create_file:near
                        extrn write_driver:near
                        extrn read_driver:near
                        extrn work_error_prompt:near
                        extrn verify_work:near
                        extrn display_error:near

;
; *** Publics
;

                        public printer_configuration

                        public serial_printer_command

;
; *** Equates
;

Loaded_by_go           equ    0fffeh

Carriage_return        equ    0dh
Line_feed              equ    0ah
Select                 equ    11h

Page

;
; *** Serial printer variables
;

Serial_printer_command     db  00
                           db  'mode lpt1:=com1:'
                           db  carriage_return
                           db  line_feed
                           db  'mode com'
Serial_port                db  '1:'
Baud_rate_high             dw  0000h
Baud_rate_low              dw  0000h
                           db  ','
Parity                     db  00h,','
Data_bits                  db  00h,',1'
                           db  carriage_return
                           db  line_feed

;
; *** Which port message
;

Which_port_message      db  1,43,'Which adapter is your printer connected to?'

Port_choice_menu        db  0           ; *** If loaded by Go only 3 choices
                        db  1           ; *** other wise 4 choices
                        db  16,'Parallel adapter'
                        db  2
                        db  14,'Serial adapter'
                        db  3
                        db  28,'Both adapters (two printers)'
                        db  4
                        db  23,'Not sure -- please test'

Port_choice_string      db  0,1,2,3,4   ; *** If loaded by Go only 3 choices
                                        ; *** other wise 4 choices

Which_serial_port_prompt db  1,47,'Which serial port is your printer '
                         db       'connected to?'

Serial_port_menu         db  2
                         db  1
                         db  20,'COM1 (Serial port 1)'
                         db  3
                         db  20,'COM2 (Serial port 2)'

Serial_port_string       db  2,1,3

;
; *** Which baud rate menu
;

Which_baud_rate_message db  3

db   48,'At what speed (baud rate) is your printer set to'
db   47,'receive data?  (If your',27h,'re not sure, check your'
db   28,'printer',27h,'s manual or dealer.)'

Baud_rate_choice_menu   db  5
                        db  1
                        db  08,'300 baud'
                        db  2
                        db  09,'1200 baud'
                        db  3
                        db  09,'2400 baud'
                        db  4
                        db  09,'9600 baud'
                        db  5
                        db  13,'Another speed'

Baud_rate_choice_string db  5,1,2,3,4,5

Other_baud_rate_choice_menu  db  5
                             db  1
                             db  08,'110 baud'
                             db  2
                             db  08,'150 baud'
                             db  3
                             db  08,'600 baud'
                             db  4
                             db  09,'4800 baud'
                             db  5
                             db  26,'Show first selection again'

Other_baud_rate_choice_string  db  5,1,2,3,4,5

;
; *** Printer test message
;

Printer_test_prompt   db   3

     db        52,'Please put paper in your printer, turn on it',27h,'s power'
     db        48,'and set it',27h,'s switches (if any) so it is ready to'
     db        24,'print. When ready press '

Print_ok_message      db   2

     db        48,'Did your printer print the following accurately?'
     db        52,'The quick brown fox jumped over the lazy yellow dog.'

Print_test_menu       db   2
                      db   1
                      db   2,'No'
                      db   3
                      db   3,'Yes'

Print_test_choice_string     db   2,1,3

Print_test_message db 67

          db   carriage_return,line_feed
          db   'The quick brown fox jumped over the lazy yellow dog.'
          db   carriage_return,12 dup (line_feed)

;
; *** Printer type messages
;

Printer_is_parallel_message db  2

   db         50,'Your printer is connected to the parallel adapter.'
   db         18,'To continue press '

Printer_is_serial_message  db  3

   db         54,'Your printer is not connected to the parallel adapter.'
   db         39,'Wordvision will use the serial adapter.'
   db         18,'To continue press '

;
; *** Parity choice menu
;

Which_parity_prompt    db  3

db 53,'Which type of "parity" is your printer set to receive'
db 58,'data?  (if you',27h,'re not sure, check your printer',27h,'s manual or'
db 08,'dealer.)'

Parity_choice_menu     db  3
                       db  1
                       db  3,'Odd'
                       db  2
                       db  4,'Even'
                       db  3
                       db  4,'None'

Parity_choice_string   db  3,1,2,3

;
; *** Read MODE.COM variables

Mode_name              db   'mode    com'

Mode_prompt            db   4

              db     47,'In order to use the serial printer the DOS file'
              db     46,'MODE.COM must be on your Working disk.  Please'
              db     50,'insert the DOS diskette that has the file MODE.COM'
              db     30,'in drive '
Mode_drive    db     00,'.  When ready press '

Mode_error_prompt      db   2

              db     44,'SORRY: Unable to find the DOS file MODE.COM.'
              db     43,'Please try another disk.  When ready press '

Read_mode_error  db 42,' SORRY: Unable to read DOS file MODE.COM. '

Create_mode_error  db  43,' SORRY: No room in directory for MODE.COM. '

Write_mode_error   db  46,' SORRY: No room on Working disk for MODE.COM. '

Close_mode_error   db  38,' SORRY: This is not the Working disk. '

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                         PRINTER CONFIGURATION                        |
; |                                                                      |
; |          Determine if printer has serial or parallel port.           |
; |          If serial get parameters to set up batch file.              |
; |                                                                      |
; ------------------------------------------------------------------------

Printer_configuration proc near

               mov      serial_printer_command,0

               int      11h

               test     ah,0eh

               jnz      serial_port_present

               jmp      printer_configuration_return

        Serial_port_present:

               test     ah,0c0h

               jnz      serial_and_parallel_present

               call     serial_configuration

               jmp      printer_configuration_return

        Serial_and_parallel_present:

               call     which_printer

        Printer_configuration_return:

               ret

Printer_configuration endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          WHICH PRINTER                                |
; |                                                                       |
; |     Computers has both parellel and serial ports. Find out if         |
; |     printer is conected to 1) parallel port                           |
; |                            2) serial port                             |
; |                            3) both parallel and serial                |
; |                                                                       |
; -------------------------------------------------------------------------

Which_printer  proc     near

               call     clear_page

;
; *** If loaded by Go then mode.com may be in system. If this is true
; *** the test to the parallel port will print on the serial printer.
; *** To avoid this problem the fourth option is not given (printer test)
; *** if loaded by Go.
;

               cmp      load_indicator,loaded_by_go
               je       no_test_option

               mov      port_choice_menu,4
               mov      port_choice_string,4

               jmp      display_port_choice

        No_test_option:

               mov      port_choice_menu,3
               mov      port_choice_string,3

        Display_port_choice:

               mov      cx,offset which_port_message
               mov      si,offset port_choice_menu
               call     display_menu

               mov      si,offset port_choice_string
               call     function_choice

               cmp      al,1
               je       which_printer_return

               cmp      al,2
               je       call_serial_configuration

               cmp      al,3
               je       call_serial_configuration

               call     printer_test

               jc       which_printer_return     ; not serial port

        Call_serial_configuration:

               call     serial_configuration

        Which_printer_return:

               ret

Which_printer  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            SERIAL CONFIGURATION                       |
; |                                                                       |
; |        Determine Baud Rate  300,1200,2400 and other                   |
; |                             odd,even none                             |
; |                             set 1 stop bit and 7 data bits            |
; |                                                                       |
; -------------------------------------------------------------------------

Serial_configuration proc  near

               call     clear_page

               mov      cx,offset which_baud_rate_message
               mov      si,offset baud_rate_choice_menu
               call     display_menu

               mov      si,offset baud_rate_choice_string
               call     function_choice

               cmp      al,1
               jne      check_1200_baud_rate

               mov      ax,'30'
               mov      bx,'0 '

               jmp      set_baud_rate

        Check_1200_baud_rate:

               cmp      al,2
               jne      check_2400_baud_rate

               mov      ax,'12'
               mov      bx,'00'

               jmp      set_baud_rate

        Check_2400_baud_rate:

               cmp      al,3
               jne      check_9600_baud_rate

               mov      ax,'24'
               mov      bx,'00'

               jmp      set_baud_rate

        Check_9600_baud_rate:

               cmp      al,4
               jne      other_baud_rate

               mov      ax,'96'
               mov      bx,'00'

               jmp      set_baud_rate

        Other_baud_rate:

               call     get_other_baud_rate

               jnc      set_baud_rate

               jmp      serial_configuration   ; display first choice again

        Set_baud_rate:

               xchg     ah,al
               mov      baud_rate_high,ax
               xchg     bh,bl
               mov      baud_rate_low,bx

               mov      ax,batch_size
               add      ax,40
               mov      batch_size,ax    ; *** incremnet size ofautoexec.bat

               mov      serial_printer_command,40

;
; *** Get parity
;

               call     get_parity

;
; *** Get serial port
;

               call     get_serial_port

;
; *** Need to get MODE.COM from DOS disk for serial port
;

               call     read_mode_com

               call     write_mode_com

        Serial_configuration_return:

               ret

Serial_configuration endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                                GET PARITY                            |
; |                                                                      |
; ------------------------------------------------------------------------

Get_parity     proc     near

               call     clear_page

               mov      cx,offset which_parity_prompt
               mov      si,offset parity_choice_menu
               call     display_menu

               mov      si,offset parity_choice_string
               call     function_choice

               cmp      al,1
               jne      check_even_parity

               mov      parity,'o'
               mov      data_bits,'7'
               jmp      get_parity_return

        Check_even_parity:

               cmp      al,2
               jne      no_parity

               mov      parity,'e'
               mov      data_bits,'7'
               jmp      get_parity_return

       No_parity:

               mov      parity,'n'
               mov      data_bits,'8'

       Get_parity_return:

               ret

Get_parity     endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                            GET SERIAL PORT                           |
; |                                                                      |
; ------------------------------------------------------------------------

Get_serial_port proc     near

               int      11h

               test     ah,0ch
               jz       get_serial_port_return

               call     clear_page

               mov      cx,offset which_serial_port_prompt
               mov      si,offset serial_port_menu
               call     display_menu

               mov      si,offset serial_port_string
               call     function_choice

               cmp      al,1
               jne      serial_port_2

               mov      serial_port,'1'
               jmp      get_serial_port_return

        Serial_port_2:

               mov      serial_port,'2'

       Get_serial_port_return:

               ret

Get_serial_port endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            PRINTER TEST                               |
; |                                                                       |
; -------------------------------------------------------------------------

Printer_test   proc     near

               call     clear_page

               mov      si,offset printer_test_prompt
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0927h
               call     display_function_key

               call     screen_page

        Printer_heart_key:

               call     check_heart_key

               jnc      printer_heart_key

;
; *** Clear page to acknowledge heart key and try and print message
; *** to parallel port
;

               call     clear_page

               call     screen_page

               mov      si,offset print_test_message
               call     print_message

;
; *** Ask if message was printed ok on printer
;

               call     clear_page

               mov      cx,offset print_ok_message
               mov      si,offset print_test_menu
               call     display_menu

               mov      si,offset print_test_choice_string
               call     function_choice

               cmp      al,1
               je       printer_is_serial

               jmp      printer_is_parallel

;
; *** Inform user printer is serial
;

        Printer_is_serial:

               call     clear_page

               mov      si,offset printer_is_serial_message
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0921h
               call     display_function_key

               call     screen_page

               clc

               pushf

               jmp      get_permission_to_continue

;
; *** Inform use that printer is parallel
;

        Printer_is_parallel:

               call     clear_page

               mov      si,offset printer_is_parallel_message
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0821h
               call     display_function_key

               call     screen_page

               stc

               pushf

;
; *** Get heart key to continue
;

        Get_permission_to_continue:

               call     check_heart_key

               jnc      get_permission_to_continue

               popf

        Printer_test_return:

               ret

Printer_test   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                        GET OTHER BAUD RATE                            |
; |                                                                       |
; -------------------------------------------------------------------------

Get_other_baud_rate proc near

               call     clear_page

               mov      cx,offset which_baud_rate_message
               mov      si,offset other_baud_rate_choice_menu
               call     display_menu

               mov      si,offset other_baud_rate_choice_string
               call     function_choice

               cmp      al,1
               jne      check_150_baud_rate

               mov      ax,'11'
               mov      bx,'0 '

               jmp      have_other_baud_rate

        Check_150_baud_rate:

               cmp      al,2
               jne      check_600_baud_rate

               mov      ax,'15'
               mov      bx,'0 '

               jmp      have_other_baud_rate

        Check_600_baud_rate:

               cmp      al,3
               jne      check_4800_baud_rate

               mov      ax,'60'
               mov      bx,'0 '

               jmp      have_other_baud_rate

        Check_4800_baud_rate:

               cmp      al,4
               jne      show_first_choice_again

               mov      ax,'48'
               mov      bx,'00'

               jmp      have_other_baud_rate

        Show_first_choice_again:

               stc

               jmp      get_other_baud_rate_return

        Have_other_baud_rate:

               clc

        Get_other_baud_rate_return:

               ret

Get_other_baud_rate endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             PRINT MESSAGE                             |
; |                                                                       |
; |                      Print message to printer.                        |
; |                                                                       |
; |        Input:                                                         |
; |                SI - offset of message to print                        |
; |                     L,XXX ... X                                       |
; |                     (L - length of message, XXX ... X message)        |
; |                                                                       |
; -------------------------------------------------------------------------

Print_message  proc     near

               push     ds

               push     cs
               pop      ds

               push     si

;
; *** Set cx to size of string
;

               xor      ch,ch
               mov      cl,[si]
               inc      si

        Print_message_loop:

               xor      ah,ah
               mov      al,[si]
               inc      si
               xor      dx,dx

               int      17h

               test     ah,25h
               jnz      print_message_return     ; printer error

               loop     print_message_loop

        Print_message_return:

               pop      si
               pop      ds

               ret

Print_message  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              READ MODE COM                            |
; |                                                                       |
; -------------------------------------------------------------------------

Read_mode_com  proc     near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

               mov      al,destination_drive
               mov      current_drive,al
               mov      current_disk,1

               call     clear_page

               mov      al,current_drive
               add      al,'A'
               mov      mode_drive,al

               mov      si,offset mode_prompt
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0a2dh
               call     display_function_key

               call     screen_page

               jmp      read_mode_response

        Read_mode_error_prompt:

               mov      si,offset mode_error_prompt
               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,083ah
               call     display_function_key

               call     screen_page

        Read_mode_response:

               call     check_heart_key

               jnc      read_mode_response

               call     clear_page

               call     screen_page

;
; *** Check to see if MODE.COM is on disk
;

               mov      al,0
               mov      dl,1
               mov      si,offset mode_name
               call     open_file

               jc       read_mode_error_prompt

               mov      al,1
               call     read_driver

               jnc      read_mode_com_return

               mov      cx,offset read_mode_error

               call     display_error

               jmp      read_mode_error_prompt

        Read_mode_com_return:

               pop      es
               pop      ds

               ret

Read_mode_com  endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             WRITE MODE COM                            |
; |                                                                       |
; -------------------------------------------------------------------------

Write_mode_com proc     near

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
               je       mode_write_verify

        Write_mode_error_prompt:

               call     work_error_prompt

        Mode_write_verify:

               call     verify_work

               jc       write_mode_error_prompt

;
; *** Create MODE.COM file
;

               mov      al,0
               mov      dl,1
               call     create_file

               jnc      write_mode_com_file

               mov      cx,offset create_mode_error

               jmp      display_write_mode_error

        Write_mode_com_file:

               mov      al,1
               call     write_driver

               jnc      close_mode_com

               mov      cx,offset write_mode_error

               jmp      display_write_mode_error

        Close_mode_com:

               mov      dl,1
               call     close_file

               jnc      write_mode_com_return

               mov      cx,offset close_mode_error

        Display_write_mode_error:

               call     display_error

        Write_mode_com_return:

               pop      es
               pop      ds

               ret

Write_mode_com endp

Code_seg       ends

                end


       pp   s
       pp   s

       rt

rt_oecmedCd_e    ns

        n
   p  
   p  
    t
toceC_ 