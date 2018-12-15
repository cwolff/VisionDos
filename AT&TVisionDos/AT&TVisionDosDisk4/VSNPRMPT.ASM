Name            VSNPRMPT

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Prompt

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

                extrn  number_of_drives:byte
                extrn  current_drive:byte
                extrn  current_disk:byte
                extrn  source_drive:byte
                extrn  destination_drive:byte
                extrn  pitch:byte
                extrn  m_disk:byte
                extrn  d_disk:byte
                extrn  w_disk:byte
                extrn  disk_write_protect_error:byte

                extrn  display_prompt:near
                extrn  display_function_key:near
                extrn  drive_on:near
                extrn  disk_on:near
                extrn  drive_off:near
                extrn  disk_off:near
                extrn  clear_monitor:near
                extrn  flush_keyboard:near
                extrn  screen_page:near
                extrn  check_heart_key:near
                extrn  display_message:near
                extrn  clear_page:near
                extrn  vision_picture:near
                extrn  display_disks:near
                extrn  error_beep:near

;
; *** Public
;

                public  disk_prompt
                public  vsn_dos_prompt
                public  vsn_dos_error_prompt
                public  ibm_dos_prompt
                public  ibm_dos_error_prompt
                public  ibm_prompt
                public  ibm_error_prompt
                public  master_prompt
                public  master_error_prompt
                public  blank_prompt
                public  blank_error_prompt
                public  work_prompt
                public  work_error_prompt
                public  write_protect_prompt
                public  write_protect_error_prompt

;
; *** Equates
;

Prompt_pitch         equ      08h

Page

;
; ***   The first two set of prompts are used before making working copy ***
;

;
; *** Prompt message for IBM DOS (inorder to load xxxbio, xxxdos to reboot)
;

Ibm_dos_prompt_a_message    db    3,29,'Remove Wordvision Master from'
                            db      27,'drive A and put DOS disk in'
                            db      20,'Drive A, then press '

Ibm_dos_prompt_b_message    db    2,31,'Please put DOS disk in drive B,'
                            db      11,'then press '

Ibm_dos_error_prompt_message    db    2,31,'Please put DOS disk in drive '
Ibm_dos_error_disk              db      'X,'
                                db      11,'then press '

;
; *** Prompt message for VSN DOS
;

Vsn_dos_prompt_a_message    db    3,28,'Remove DOS disk from drive A'
                            db      28,'and put Wordvision Master in'
                            db      20,'drive A, then press '

Vsn_dos_prompt_b_message    db    2,31,'Please put Wordvision Master in'
                            db      20,'drive A: then press '

Vsn_dos_error_prompt_message    db    2,31,'Please put Wordvision Master in'
                                db      20,'drive '
Vsn_dos_error_disk              db         'X, then press '

;
; *** The following of prompts are used durning/after making working copy ***
;

;
; *** Prompt message for Master Disk
;

Master_prompt_a_message    db    3,32,'Remove Working disk from drive A'
                           db      28,'and put Wordvision Master in'
                           db      20,'drive A, then press '

Master_prompt_b_message    db    3,28,'Remove DOS disk from drive B'
                           db      28,'and put Wordvision Master in'
                           db      20,'drive B, then press '

Master_error_prompt_message  db  2,30,'Please place Wordvision Master'
                             db    23,'in drive '
Master_error_disk            db       'X, then press '

;
; *** Prompt message for IBM DOS (in order to format the disk)
;

Ibm_prompt_a_message    db    3,29,'Remove Wordvision Master from'
                        db      27,'drive A and put DOS disk in'
                        db      20,'Drive A, then press '

Ibm_prompt_b_message    db    2,31,'Please put DOS disk in drive B,'
                        db      11,'then press '

Ibm_error_prompt_message    db    2,31,'Please put DOS disk in drive '
Ibm_error_disk              db      'X,'
                            db      11,'then press '

;
; *** Prompt message for Blank Disk
;

Blank_prompt_a_message     db    3,20,'Remove DOS disk from'
                           db      27,'drive A and replace it with'
                           db      27,'the Blank disk, then press '

Blank_prompt_b_message     db    3,29,'Remove Wordvision Master from'
                           db      27,'drive A and replace it with'
                           db      27,'the Blank disk, then press '

Blank_error_prompt_message db    2,33,'Please place Blank disk in drive '
                           db      14
Blank_error_disk           db      'X, then press '

;
; *** Prompt message for Work Disk
;

Work_prompt_a_message      db   3,35,'Remove Wordvision Master from drive'
                           db     33,'A and replace it with the Working'
                           db     25,'(Blank) disk, then press '

Work_prompt_b_message      db   2,33,'Place the Working (Blank) disk in'
                           db     20,'drive A, then press '

Work_error_prompt_message  db   2,35,'Please place Working disk in drive '
                           db     14
Work_error_disk            db     'X, then press '

;
; *** Write protect prompt
;

Write_protect_message      db   4,29,'Remove Wordvision Master from'
                           db     30,'drive A, place a write protect'
                           db     29,'on it and replace in drive A.'
                           db     11,'Then press '

Write_protect_error_message  db   3,28,'Please place a write protect'
                             db     28,'tab on Wordvision Master and'
                             db     29,'place in drive '
Write_protect_error_disk     db        'X, then press '

;
; *** Disk prompt messages
;

Drive_closed_top_display        db    1,' '
Drive_closed_bottom_display     db    7,3 dup (205),219,3 dup (205)

Page

; =========================================================================
; |                                                                       |
; |                         IBM DOS PROMPT                                |
; |                                                                       |
; =========================================================================

Ibm_dos_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                mov     d_disk,al

                cmp     number_of_drives,1
                jne     ibm_dos_two_drives

                mov     m_disk,2
                mov     w_disk,2

                mov     dx,0702h
                mov     si,offset ibm_dos_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,0916h
                call    display_function_key

                jmp     ibm_dos_prompt_return

        Ibm_dos_two_drives:

                mov     dx,0702h
                mov     si,offset ibm_dos_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,080dh
                call    display_function_key

        Ibm_dos_prompt_return:

                call    disk_prompt

                ret

Ibm_dos_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                         IBM DOS ERROR PROMPT                          |
; |                                                                       |
; =========================================================================

Ibm_dos_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     ibm_dos_error_disk,al

                mov     dx,0702h
                mov     si,offset ibm_dos_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,080dh
                call    display_function_key

        Ibm_error_dos_prompt_return:

                call    disk_prompt

                ret

Ibm_dos_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                              VSN DOS PROMPT                           |
; |                                                                       |
; =========================================================================

Vsn_dos_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                mov     m_disk,al

                cmp     number_of_drives,1
                jne     vsn_dos_two_drives

                mov     d_disk,2
                mov     w_disk,2

                mov     dx,0702h
                mov     si,offset vsn_dos_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,0916h
                call    display_function_key

                jmp     vsn_dos_prompt_return

        Vsn_dos_two_drives:

                mov     dx,0702h
                mov     si,offset vsn_dos_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,00816h
                call    display_function_key

        Vsn_dos_prompt_return:

                call    disk_prompt

                ret

Vsn_dos_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                         VSN DOS ERROR PROMPT                          |
; |                                                                       |
; =========================================================================

Vsn_dos_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     vsn_dos_error_disk,al

                mov     dx,0702h
                mov     si,offset vsn_dos_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,0816h
                call    display_function_key

        Vsn_dos_error_prompt_return:

                call    disk_prompt

                ret

Vsn_dos_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                             IBM PROMPT                                |
; |                                                                       |
; =========================================================================

Ibm_prompt      proc    near

                call    clear_page

                mov     al,current_drive
                mov     d_disk,al

                cmp     number_of_drives,1
                jne     ibm_two_drives

                mov     m_disk,2
                mov     w_disk,2

                mov     dx,0702h
                mov     si,offset ibm_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,0916h
                call    display_function_key

                jmp     ibm_prompt_return

        Ibm_two_drives:

                mov     dx,0702h
                mov     si,offset ibm_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,080dh
                call    display_function_key

        Ibm_prompt_return:

                call    disk_prompt

                ret

Ibm_prompt      endp

Page

; =========================================================================
; |                                                                       |
; |                            IBM ERROR PROMPT                           |
; |                                                                       |
; =========================================================================

Ibm_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     ibm_error_disk,al

                mov     dx,0702h
                mov     si,offset ibm_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,080dh
                call    display_function_key

        Ibm_error_prompt_return:

                call    disk_prompt

                ret

Ibm_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                              MASTER PROMPT                            |
; |                                                                       |
; =========================================================================

Master_prompt   proc    near

                call    clear_page

                mov     al,current_drive
                mov     m_disk,al

                cmp     number_of_drives,1
                jne     master_two_drives

                mov     d_disk,2
                mov     w_disk,2

                mov     dx,0702h
                mov     si,offset master_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,0916h
                call    display_function_key

                jmp     master_prompt_return

        Master_two_drives:

                mov     d_disk,2

                mov     dx,0702h
                mov     si,offset master_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,0916h
                call    display_function_key

        Master_prompt_return:

                call    disk_prompt

                ret

Master_prompt   endp

Page

; =========================================================================
; |                                                                       |
; |                         MASTER ERROR PROMPT                           |
; |                                                                       |
; =========================================================================

Master_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     master_error_disk,al

                mov     dx,0702h
                mov     si,offset master_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,0819h
                call    display_function_key

        Master_error_prompt_return:

                call    disk_prompt

                ret

Master_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                               BLANK PROMPT                            |
; |                                                                       |
; =========================================================================

Blank_prompt    proc    near

                call    clear_page

                mov     al,current_drive
                mov     w_disk,al

                cmp     number_of_drives,2
                je      blank_two_drives

                mov     m_disk,2
                mov     d_disk,2

                mov     dx,0702h
                mov     si,offset blank_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,091dh
                call    display_function_key

                jmp     blank_prompt_return

        Blank_two_drives:

                mov     m_disk,2

                mov     dx,0702h
                mov     si,offset blank_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,0091dh
                call    display_function_key

        Blank_prompt_return:

                call    disk_prompt

                ret

Blank_prompt    endp

Page

; =========================================================================
; |                                                                       |
; |                           BLANK ERROR PROMPT                          |
; |                                                                       |
; =========================================================================

Blank_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     blank_error_disk,al

                mov     dx,0702h
                mov     si,offset blank_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,0810h
                call    display_function_key

        Blank_error_prompt_return:

                call    disk_prompt

                ret

Blank_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                                WORK PROMPT                            |
; |                                                                       |
; =========================================================================

Work_prompt     proc    near

                call    clear_page

                mov     al,current_drive
                mov     w_disk,al

                cmp     number_of_drives,1
                jne     work_two_drives

                mov     m_disk,2
                mov     d_disk,2

                mov     dx,0702h
                mov     si,offset work_prompt_a_message
                call    display_prompt

                mov     al,3
                mov     dx,091bh
                call    display_function_key

                jmp     work_prompt_return

        Work_two_drives:

                mov     dx,0702h
                mov     si,offset work_prompt_b_message
                call    display_prompt

                mov     al,3
                mov     dx,00816h
                call    display_function_key

        Work_prompt_return:

                call    disk_prompt

                ret

Work_prompt     endp

Page

; =========================================================================
; |                                                                       |
; |                            WORK ERROR PROMPT                          |
; |                                                                       |
; =========================================================================

Work_error_prompt  proc    near

                call    clear_page

                mov     al,current_drive
                add     al,'A'
                mov     work_error_disk,al

                mov     dx,0702h
                mov     si,offset work_error_prompt_message
                call    display_prompt

                mov     al,3
                mov     dx,0810h
                call    display_function_key

        Work_error_prompt_return:

                call    disk_prompt

                ret

Work_error_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                          WRITE PROTECT PROMPT                         |
; |                                                                       |
; =========================================================================

Write_protect_prompt proc    near

                call    clear_page

                mov     disk_write_protect_error,0

                mov     dx,0702h
                mov     si,offset write_protect_message
                call    display_prompt

                mov     al,3
                mov     dx,0a0dh
                call    display_function_key

                call    disk_prompt

                ret

Write_protect_prompt  endp

Page

; =========================================================================
; |                                                                       |
; |                      WRITE PROTECT ERROR PROMPT                       |
; |                                                                       |
; =========================================================================

Write_protect_error_prompt  proc    near

                call    clear_page

                mov     disk_write_protect_error,0

                mov     al,current_drive
                add     al,'A'
                mov     write_protect_error_disk,al

                mov     dx,0702h
                mov     si,offset write_protect_error_message
                call    display_prompt

                mov     al,3
                mov     dx,091fh
                call    display_function_key

        Write_protect_error_return:

                call    disk_prompt

                ret

Write_protect_error_prompt  endp

Page

; ========================================================================
; |                                                                      |
; |                           DISK PROMPT                                |
; |                                                                      |
; ========================================================================

Disk_prompt    proc     near

               call    flush_keyboard

               call    vision_picture

               call    screen_page

               mov     pitch,prompt_pitch
               call    error_beep

        Disk_prompt_loop:

               mov     al,current_drive
               call    drive_on

               mov     al,current_disk
               call    disk_on

               call    screen_page

               call    check_heart_key
               jc      disk_prompt_loop_end

               mov     al,current_drive
               call    drive_off

               mov     al,current_disk
               call    disk_off

               call    screen_page

               call    check_heart_key
               jc      disk_prompt_loop_end

               jmp     disk_prompt_loop

;
; *** Close disk door
;

        Disk_prompt_loop_end:

               mov     disk_write_protect_error,3

               call    display_disks

               mov     dx,0738h

               cmp     current_drive,0
               je      close_drive

               mov     dl,42h

        Close_drive:

               mov     bl,07h
               mov     cx,offset drive_closed_top_display
               call    display_message

               mov     bl,07h
               mov     cx,offset drive_closed_bottom_display
               inc     dh
               sub     dl,3
               call    display_message

               call    clear_monitor

               call    screen_page

               ret

Disk_prompt    endp

Code_seg        ends

                end
          al  cenpg          e  Ds_rmt  np

oesg    ns

        no     l ep     e srt p
eg  s
        p  estpe s    