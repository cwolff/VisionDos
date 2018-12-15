Name            VSNWSS

Title           Bruce_&_James_Inc_Command

Subttl          Vision_Write_System_Set

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

               extrn    color:byte
               extrn    labels:byte
               extrn    vertical:byte
               extrn    number_of_drives:byte
               extrn    destination_drive:byte
               extrn    file_1_fcb:byte
               extrn    file_1_dta:word
               extrn    current_drive:byte
               extrn    source_drive:byte
               extrn    current_disk:byte
               extrn    screen_step_message:word
               extrn    screen_step:byte

               extrn    create_file:near
               extrn    write_driver:near
               extrn    close_file:near
               extrn    display_error:near
               extrn    work_prompt:near
               extrn    work_error_prompt:near
               extrn    verify_work:near
               extrn    display_trailer:near
               extrn    screen_trailer:near

;
; *** Publics
;

               public   write_system_set

Page

;
; *** System set message
;

Writing_system_set_message  db 36,'Writing SYSTEM.SET to Working disk. '

;
; *** System.set error message
;

System_set_name      db        'SYSTEM  SET'

System_create_error_message db 63,' SORRY: No room in Working disk '
                            db    'directory for SYSTEM.SET file. '

System_write_error_message  db 53,' SORRY: No room on Working disk '
                            db    'for SYSTEM.SET file. '

System_close_error_message  db 65,' SORRY: Can not close SYSTEM.SET, '
                            db    'Working disk has been changed. '

Page

; =========================================================================
; |                                                                       |
; |                        WRITE SYSTEM SET                               |
; |                                                                       |
; =========================================================================

Write_system_set  proc  near

               push     cs
               push     cs

               pop      ds
               pop      es

               mov      cx,offset writing_system_set_message
               mov      screen_step_message,cx

               mov      screen_step,'3'

               call     display_trailer
               call     screen_trailer

               mov      al,source_drive
               mov      current_drive,al
               mov      current_disk,2

               cmp      number_of_drives,2
               je       system_work_verify

               call     work_prompt

               jmp      system_work_verify

        System_work_error_prompt:

               call     work_error_prompt

        System_work_verify:

               call     verify_work

               jc       system_work_error_prompt

;
; *** Write system.set file
;

               cld

               mov      cx,11
               mov      si,offset system_set_name
               mov      di,offset file_1_fcb
               mov      al,current_drive
               inc      al
               mov      [di],al
               inc      di

               rep      movsb

;
; *** Set file size to eight bytes
;


               mov      bx,offset file_1_fcb

               mov      ax,8
               mov      [bx+16],ax
               xor      ax,ax
               mov      [bx+18],ax

               mov      al,0
               mov      dl,1
               call     create_file

               jc       system_set_create_error

;
; *** Place system configuration in system.set
;

               push     ds

               mov      ds,file_1_dta
               xor      bx,bx

               xor      ah,ah
               mov      al,color
               mov      [bx],ax
               mov      al,vertical
               mov      [bx+2],ax
               mov      al,destination_drive
               inc      al
               mov      [bx+4],ax
               mov      al,labels
               mov      [bx+6],ax

               pop      ds

               mov      al,1
               call     write_driver

               jc       system_set_write_error

               mov      dl,1
               call     close_file

               jc       system_set_close_error

               jmp      write_system_set_return

        System_set_create_error:

               mov      cx,offset system_create_error_message
               call     display_error

               jmp      write_system_set_return

        System_set_write_error:

               mov      cx,offset system_write_error_message
               call     display_error

               jmp      write_system_set_return

        System_set_close_error:

               mov      cx,offset system_close_error_message
               call     display_error

        Write_system_set_return:

               ret

Write_system_set  endp

Code_seg        ends

                end





_ls_ro:

       mv   xofe ytmcoeerrmsae
       cl   ipa_ro    Wiesse_e_eun        eWiesse_e edCd_e    ed        ed DIEO  w  TALRMSAE ( IIINPCUE , O SER uHC_O_B_YTM @ êHC_ER_E{ ‘  DS_RMT = Ω
RO_EP F Œ IC√ ¡k ECPOP‘ ∆ò VNRP} V