Name            VSNERR

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Error

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

                extrn  error_attribute:byte
                extrn  number_of_drives:byte
                extrn  current_drive:byte
                extrn  current_disk:byte
                extrn  current_error:byte
                extrn  source_drive:byte
                extrn  destination_drive:byte
                extrn  trailer_message:byte
                extrn  screen_step:byte
                extrn  trailer_text_attribute:byte
                extrn  trailer_attribute:byte
                extrn  main_text_attribute:byte
                extrn  dos_version:byte
                extrn  pitch:byte
                extrn  m_disk:byte
                extrn  d_disk:byte
                extrn  w_disk:byte
                extrn  disk_write_protect_error:byte
                extrn  rom_reboot:dword

                extrn  display_message:near
                extrn  display_menu:near
                extrn  display_header:near
                extrn  display_trailer:near
                extrn  screen_trailer:near
                extrn  disk_prompt:near
                extrn  display_prompt:near
                extrn  display_function_key:near
                extrn  check_for_ibm_system:near
                extrn  verify_master:near
                extrn  verify_ibm:near
                extrn  clear_page:near
                extrn  clear_monitor:near
                extrn  error_beep:near
                extrn  screen_page:near
                extrn  check_heart_key:near
                extrn  clear_page:near
                extrn  ibm_error_prompt:near
                extrn  master_error_prompt:near
                extrn  display_operation:near

;
; *** Public
;

                public  disk_failure
                public  can_not_boot_dos
                public  esc_prompt
                public  final_step
                public  master_failure
                public  dos_error_handler
                public  display_error
                public  work_failure
                public  ibm_path_message
                public  can_not_boot_10_message
                public  can_not_boot_20_message
                public  can_not_boot_xx_message
                public  dos_exit

;
; *** Equates
;

Error_pitch             equ   10h

Page

;
; *** Disk drive error messages
;

Drive_not_ready_message db   27,' Please adjust disk drive. '

Not_formatted_message   db   36,' SORRY: This disk is not formatted. '

Write_protect_message   db   38,' Please remove the write protect tab. '

Damaged_disk_message    db   32,' SORRY: This disk is defective. '

Vsn_damaged_disk_message db 50,' SORRY: This Wordvision Master disk is '
                         db  'defective. '

;
; *** Fatal messages
;

Fatal_master_message db 56,' SORRY: Unable to make a Working copy with this'
                     db    ' Master. '

Master_failure_prompt db 2,24,'Place PC-DOS in drive A,'
                      db   11,'then press '

Fatal_work_message db 50,' SORRY: Failed to make a Working Copy, try again. '

Work_failure_prompt   db 2,26,'Place Wordvision Master in'
                      db   20,'drive A, then press '

Esc_prompt_message    db 2,24,'Place the PC-DOS disk in'
                      db   20,'drive A, then press '

When_ready_message    db 17,'When ready press '

;
; *** Can not boot messages
;

Ibm_path_message         db 5
         db 54,'To make a working copy of Wordvision do the following:'
         db 36,'Put DOS disk in drive A, then press '
         db  1,' '
         db 51,'Wait, then when A> appears on screen put Wordvision'
         db 45,'Master in drive A, then type GO and press ',17,196,217

Can_not_boot_10_message  db 5
         db 51,'SORRY: Can not proceed automatically under DOS 1.0.'
         db 36,'Put DOS disk in drive A, then press '
         db  1,' '
         db 51,'Use DOS commands to format a blank disk with system'
         db 43,'then copy Wordvision files to Working disk.'

Can_not_boot_20_message  db 5
         db 49,'SORRY: Can not proceed automatically with DOS 2.0'
         db 36,'Put DOS disk in drive A, then press '
         db  1,' '
         db 51,'Wait, then when A> appears on screen put Wordvision'
         db 45,'Master in drive A, then type GO and press ',17,196,217

Can_not_boot_xx_message  db 5
         db 50,'SORRY: Can not proceed automatically with this DOS'
         db 36,'Put DOS disk in drive A, then press '
         db  1,' '
         db 51,'Wait, then when A> appears on screen put Wordvision'
         db 45,'Master in drive A, then type GO and press ',17,196,217



;
; *** Final step message
;

Final_step_message    db   12,' Final step '

Page

; ========================================================================
; |                                                                      |
; |                              DOS EXIT                                |
; |                                                                      |
; ========================================================================

Dos_exit       proc     near

               mov     ax,0600h
               mov     bh,07h
               mov     cx,0
               mov     dx,184fh
               int     10h

               cli

               mov     ax,40h
               mov     ds,ax

               mov     bx,72h
               mov     word ptr [bx],1234h

               jmp     rom_reboot         ; jump to power on location

Dos_exit       endp

Page

; ========================================================================
; |                                                                      |
; |                         CAN NOT BOOT DOS                             |
; |                                                                      |
; |    Input:                                                            |
; |            SI - offset of can not boot message                       |
; |                                                                      |
; ========================================================================

Can_not_boot_dos proc   near

               call     clear_page

               mov      al,source_drive
               mov      current_drive,al
               mov      d_disk,al
               mov      current_disk,1

               mov      m_disk,2
               mov      w_disk,2

               mov      dx,070fh
               call     display_prompt

               mov      al,3
               mov      dx,0833h
               call     display_function_key

               mov     screen_step,0
               call    final_step

               call     screen_page

        Illegal_disk_loop:

               call     check_heart_key

               jnc      illegal_disk_loop

               call     verify_ibm

               jc       illegal_disk_loop

               jmp      dos_exit

Can_not_boot_dos endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                            ESC PROMPT                                |
; |                                                                      |
; ------------------------------------------------------------------------

Esc_prompt      proc    near

                call    clear_page

                mov     disk_write_protect_error,3

                mov     screen_step,0
                call    final_step

                mov     al,source_drive
                mov     current_drive,al
                mov     d_disk,al
                mov     current_disk,1

                mov     m_disk,2
                mov     w_disk,2

                mov     dx,0702h
                mov     si,offset esc_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,0816h
                call    display_function_key

        Esc_dos_prompt:

                call    ibm_error_prompt

                call    verify_ibm

                jc      esc_dos_prompt

                jmp     dos_exit

Esc_prompt      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          MASTER FAILURE                               |
; |                                                                       |
; -------------------------------------------------------------------------

Master_failure  proc    near

                call    clear_page

                mov     al,source_drive
                mov     current_drive,al
                mov     d_disk,al
                mov     current_disk,1

                mov     m_disk,2
                mov     w_disk,2

                mov     screen_step,0
                call    final_step

                mov     cx,offset fatal_master_message
                call    display_error

        Failure_dos_prompt:

                call    ibm_error_prompt

                call    verify_ibm

                jc      failure_dos_prompt

                jmp     dos_exit

Master_failure  endp

Page

; =========================================================================
; |                                                                       |
; |                           WORK FAILURE                                |
; |                                                                       |
; =========================================================================

Work_failure    proc     near

                call     clear_page

                mov      al,source_drive
                mov      current_drive,al
                mov      m_disk,al
                mov      current_disk,0

                mov      d_disk,2
                mov      w_disk,2

                mov      screen_step,0
                call     final_step

                mov      cx,offset fatal_work_message
                call     display_error

        Failure_master_prompt:

                call     master_error_prompt

                call     verify_master

                jc       failure_master_prompt

                jmp      dos_exit

Work_failure    endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK FAILURE                               |
; |                                                                       |
; |       Input:                                                          |
; |                                                                       |
; |             current_error - disk error code                           |
; |             current_drive - 0,drive a: 1,drive b:                     |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_failure    proc    near

                cmp     current_error,80h
                jne     check_format_error

                mov     cx,offset drive_not_ready_message
                jmp     display_disk_error

        Check_format_error:

                cmp     current_error,04h
                jne     check_write_protect_error

                mov     cx,offset not_formatted_message
                jmp     display_disk_error

        Check_write_protect_error:

                cmp     current_error,03h
                jne     fatal_error

                mov     al,current_disk
                mov     disk_write_protect_error,al

                mov     cx,offset write_protect_message
                jmp     display_disk_error

        Fatal_error:

                cmp     current_disk,0
                jne     not_word_vision_diskette

                call    master_failure

        Not_word_vision_diskette:

                mov     cx,offset damaged_disk_message

        Display_disk_error:

                call    display_error

                mov     current_error,0

                ret

Disk_failure    endp

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                           DOS ERROR HANDLER                           $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Dos_error_handler proc near

                push    bx
                push    cx
                push    dx
                push    bp
                push    si
                push    di
                push    ds
                push    es

                sti

                mov     ax,cs
                mov     ds,ax

                test    ah,10000000b
                jz      disk_error

                jmp     dos_error_return

;
; *** Disk error inform user which one
;

        Disk_error:

                and    di,00ffh

                cmp    di,0
                jne    check_drive_not_ready

                mov    current_error,03h
                jmp    process_error

        Check_drive_not_ready:

               cmp      di,2
               jne      cant_fix_error

               mov      current_error,80h
               jmp      process_error

        Cant_fix_error:

               cmp      current_disk,0
               jne      not_master_failure

               call     master_failure

        Not_master_failure:

               call     work_failure

        Process_error:

               call     disk_failure

               call     clear_monitor

               mov      bl,main_text_attribute
               mov      cx,offset when_ready_message
               mov      dx,0702h
               call     display_message

               mov      al,3
               mov      dx,0713h
               call     display_function_key

               call     disk_prompt

               call     display_operation

               mov      al,1               ; *** Retry the operation

        Dos_error_return:

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     bp
                pop     dx
                pop     cx
                pop     bx

                iret

Dos_error_handler endp

Page

; =========================================================================
; |                                                                       |
; |                           FINAL STEP                                  |
; |                                                                       |
; =========================================================================

Final_step     proc     near

               mov      bl,trailer_text_attribute
               mov      cx,offset final_step_message
               mov      dx,offset 1701h
               call     display_message

               mov      bl,trailer_attribute
               mov      cx,offset trailer_message
               mov      al,54
               mov      trailer_message,al
               mov      dx,170dh
               call     display_message

               mov      bl,trailer_text_attribute
               mov      cx,offset final_step_message
               mov      dx,offset 1743h
               call     display_message

               call     screen_trailer

               ret

Final_step     endp

Page

; =========================================================================
; |                                                                       |
; |                        DISPLAY ERROR                                  |
; |                                                                       |
; =========================================================================

Display_error  proc     near

               mov      bl,error_attribute
               mov      dx,17ffh
               call     display_message

               call     screen_trailer

               mov      pitch,error_pitch
               call     error_beep

               mov      al,0fh

               mov      cx,7fffh

        Error_pause:

               loop     error_pause

               dec      al
               jnz      error_pause

               cmp      screen_step,0      ; final step active
               jne      not_final_step

               call     final_step

               jmp      display_error_return

        Not_final_step:

               call     display_trailer

               call     screen_trailer

        Display_error_return:

               ret

Display_error  endp

Code_seg       ends

                end
              