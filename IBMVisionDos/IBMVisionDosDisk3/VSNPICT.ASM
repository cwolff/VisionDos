Name            VSNPICT

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Picture

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
; *** Externals varibales
;

                extrn  number_of_drives:byte
                extrn  current_drive:byte
                extrn  current_error:byte
                extrn  current_disk:byte
                extrn  labels:byte
                extrn  vertical:byte
                extrn  screen_step:byte
                extrn  screen_step_message:word
                extrn  keyboard_fk2_message:byte
                extrn  keyboard_1_message:byte
                extrn  keyboard_heart_message:byte
                extrn  keyboard_2_message:byte
                extrn  header_attribute:byte
                extrn  header_text_attribute_high:byte
                extrn  header_text_attribute_low:byte
                extrn  trailer_attribute:byte
                extrn  trailer_text_attribute:byte
                extrn  main_text_attribute:byte
                extrn  diagram_attribute_high:byte
                extrn  diagram_attribute_low:byte
                extrn  error_attribute:byte
                extrn  disk_write_protect_error:byte
                extrn  master_write_protect_tab:byte

;
; *** External routines
;

                extrn  final_step:near
                extrn  flush_keyboard:near
                extrn  display_message:near
                extrn  display_prompt:near
                extrn  clear_monitor:near
                extrn  clear_page:near
                extrn  screen_header:near
                extrn  screen_trailer:near
                extrn  screen_page:near

;
; *** Public
;

                public display_opening_screen
                public display_header
                public display_trailer
                public display_vision_picture
                public vision_picture
                public display_disks
                public drive_on
                public disk_on
                public drive_off
                public disk_off
                public m_disk
                public d_disk
                public w_disk
                public display_disks
                public display_operation
                public operation_message
                public operation_picture

                public trailer_message

Page

;
; *** Variables
;

M_disk               db   00h
W_disk               db   00h
D_disk               db   00h

Operation_message           dw   0000h
Operation_picture           dw   0000h

;
; *** Header messages
;

Wv_message           db   19,'W O R D V I S I O N'

Header_message       db   21,'Making A Working Copy'

Tm_message           db   2,'tm'

Header_1_message     db   77,201,75 dup (205),187

Header_2_message     db   1,186

Header_3_message     db   77,200,75 dup (205),188

;
; *** Define vision computer picture
;

Chasis_0_display    db  37,218,35 dup (196),191

Chasis_1_display    db  37,179,32,32,254,32 dup (32),179

Chasis_2_display_1  db  37,179,14 dup (32),3 dup (205),219,3 dup (205)
                    db  14 dup (32),179

Chasis_2_display_2  db  37,179,14 dup (32),3 dup (205),219,3 dup (205)
                    db  32,32,32,3 dup (205),219,3 dup (205),32,32,32,32,179

Chasis_3_display    db  37,179,32,32,5 dup (19),28 dup (32),179

Chasis_4_display    db  37,192,35 dup (196),217

;
; *** Define vision disk picture
;

Disk_0_display      db  15,218,13 dup (196),191

Disk_1_display      db  15,179,32,5 dup (219),223,5 dup (219),32,179

Disk_2_display      db  15,179,32,5 dup (219),32,5 dup (219),32,179

Disk_3_display      db  15,179,32,5 dup (219),223,5 dup (219),32,179

Disk_4_display      db  15,179,32
Disk_tab            db  32,10 dup (219),32,179

Disk_5_display      db  15,179,32,11 dup (219),32,179

Disk_6_display      db  15,192,13 dup (196),217

;
; *** Disks in drive display
;

In_drive_0_display      db  15,218,13 dup (196),191

In_drive_1_display      db  15,179,13 dup (' '),179

In_drive_2_display      db  15,179,'  Should be  ',179

In_drive_3_display      db  15,179,13 dup (' '),179

In_drive_4_display      db  15,179,' in drive '
In_drive_disk           db  'x: ',179

In_drive_5_display      db  15,179,13 dup (' '),179

In_drive_6_display      db  15,192,13 dup (196),217

;
; *** Disk label messages
;

Disks_message       db  46,221,'MASTER',222,13 dup (219)
                    db     221,'DOS',222,13 dup (219)
                    db     221,'BLANK',222

Disk_top_display    db  15,218,13 dup (196),191

Disk_side_display   db  1,179

Disk_bottom_display db  15,192,13 dup (196),217

Disk_tab_display    db  1,177

Open_drive_display   db  1,196

Closed_drive_display db  1,' '

Drive_display          db  7,7 dup (205)

;
; *** Trailer messages
;

Trailer_message     db  78,78 dup (205)

Stop_message        db  16,' STOP to cancel '

Esc_message         db  15,' ESC to cancel '

Trailer_buffer_message  db  78,78 dup (32)

Step_message        db  14,' Step '
Step_number         db  00
                    db  ' of 5: '

Legal_message       db  68,'(c) 1983, Bruce & James Program Publishers, Inc. '
                    db     'All rights reserved'

Tab_display         db  1,176

;
; *** Opening message display
;

Introduction_message db 56

   db      'This "master copy" of the Wordvision program is used for'
   db      56,'only one purpose: To make "working copy" disks custom-  '
   db      56,'tailored to your computer system and preferences.       '
   db      56,'                                                        '
   db      56,'To start, have at hand your Disk Operating System (DOS) '
   db      56,'disk and a blank disk to become the working copy. Also  '
   db      56,'have Wordvision',39,'s special labels or caps already on     '
   db      56,'your keyboard (unless you plan to do without them).     '
   db      56,'                                                        '
   db      56,'Begin by picking one of the choices below and pressing  '
   db      56,'the key pictured next to it.                            '
   db      0ffh

Page

; =========================================================================
; |                                                                       |
; |                           DISPLAY OPENING SCREEN                      |
; |                                                                       |
; =========================================================================

Display_opening_screen proc near

                call   display_header

                mov    labels,1

                call   display_trailer

                mov    bl,main_text_attribute
                mov    cx,offset introduction_message
                mov    si,cx
                mov    dx,04ffh

        Introduction_display_loop:

                call   display_message

                mov    al,cs:[si]
                xor    ah,ah
                add    cx,ax
                inc    cx
                mov    si,cx
                mov    al,cs:[si]

                cmp    al,0ffh
                je     display_opening_screen_choices

                inc    dh

                jmp    introduction_display_loop

        Display_opening_screen_choices:

               mov      bl,0f0h
               mov      cx,offset keyboard_fk2_message
               mov      dx,1114h
               call     display_message

               mov      bl,07h
               mov      cx,offset keyboard_1_message
               mov      dx,1120h
               call     display_message

               mov      bl,0f0h
               mov      cx,offset keyboard_heart_message
               mov      dx,1314h
               call     display_message

               mov      bl,07h
               mov      cx,offset keyboard_2_message
               mov      dx,1320h
               call     display_message

               call     screen_header

               call     screen_trailer

               call     screen_page

        Display_opening_screen_return:

                ret

Display_opening_screen endp

Page

; ==========================================================================
; |                                                                        |
; |                         DISPLAY VISION PICTURE                         |
; |                                                                        |
; ==========================================================================

Display_vision_picture proc near

               call     clear_page

               call     vision_picture

               call     screen_page

               ret

Display_vision_picture endp

Page

; ==========================================================================
; |                                                                        |
; |                             VSN PICTURE                                |
; |                                                                        |
; |      Display a picture of a IBM computer (monitor and main chasis)     |
; |      along with three disk labeled, Master, IBM DOS Disk, Working Disk |
; |                                                                        |
; |      Input:                                                            |
; |             AL - 0 monochrome display                                  |
; |             AL - 1 color display                                       |
; |                                                                        |
; ==========================================================================

Vision_picture proc     near

        Display_ibm_chasis:

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_0_display
                mov     dx,0626h
                call    display_message

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_1_display
                mov     dx,0726h
                call    display_message

                cmp     number_of_drives,1
                jne     display_two_drives

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_2_display_1
                mov     dx,0826h
                call    display_message

                jmp     chasis_continue

        Display_two_drives:

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_2_display_2
                mov     dx,0826h
                call    display_message

        Chasis_continue:

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_3_display
                mov     dx,0926h
                call    display_message

                mov     bl,diagram_attribute_low
                mov     cx,offset chasis_4_display
                mov     dx,0a26h
                call    display_message

; Display 3 disks

        Display_3_disks:

                call    display_disks

; Display disk message

               mov     bl,diagram_attribute_low
               mov     cl,4
               rol     bl,cl
               mov     cx,offset disks_message
               mov     dx,140fh
               call    display_message

        Vision_picture_return:

                ret

Vision_picture  endp

Page

; =========================================================================
; |                                                                       |
; |                          DISPLAY DISKS                                |
; |                                                                       |
; =========================================================================

Display_disks  proc     near

               cmp      disk_write_protect_error,0
               je       put_master_on_screen

               cmp      m_disk,2
               je       put_master_on_screen

               mov      al,0
               mov      ah,m_disk
               call     disk_in_drive

               jmp      do_dos_disk

        Put_master_on_screen:

               mov      disk_tab,' '

               cmp      master_write_protect_tab,0
               je       no_master_tab

               mov      disk_tab,177

        No_master_tab:

               mov      al,0
               call     disk_on_screen

        Do_dos_disk:

               cmp      disk_write_protect_error,1
               je       put_dos_on_screen

               cmp      d_disk,2
               je       put_dos_on_screen

               mov      al,1
               mov      ah,d_disk
               call     disk_in_drive

               jmp      do_work_disk

        Put_dos_on_screen:

               mov      disk_tab,' '

               mov      al,1
               call     disk_on_screen

        Do_work_disk:

               cmp      disk_write_protect_error,2
               je       put_work_on_screen

               cmp      w_disk,2
               je       put_work_on_screen

               mov      al,2
               mov      ah,w_disk
               call     disk_in_drive

               jmp      display_disks_return

        Put_work_on_screen:

               mov      disk_tab,' '

               mov      al,2
               call     disk_on_screen

        Display_disks_return:

               ret

Display_disks  endp

Page

; =========================================================================
; |                                                                       |
; |                            DISK ON SCREEN                             |
; |                                                                       |
; |        AL - screen loacation                                          |
; |             0 - Master disk                                           |
; |             1 - Dos disk                                              |
; |             2 - Working disk                                          |
; |                                                                       |
; =========================================================================

Disk_on_screen proc     near

               cmp     al,0
               je      screen_master

               cmp     al,1
               je      screen_dos

               mov     dl,32h
               jmp     put_on_screen

        Screen_master:

               mov     dl,0ch
               jmp     put_on_screen

        Screen_dos:

               mov     dl,1fh

        Put_on_screen:

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_0_display
               mov     dh,0dh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_1_display
               mov     dh,0eh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_2_display
               mov     dh,0fh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_3_display
               mov     dh,10h
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_4_display
               mov     dh,11h
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset disk_5_display
               mov     dh,12h
               call    display_message
 
               mov     bl,diagram_attribute_low
               mov     cx,offset disk_6_display
               mov     dh,13h
               call    display_message

               ret

Disk_on_screen endp

Page

; =========================================================================
; |                                                                       |
; |                           DISK IN DRIVE                               |
; |                                                                       |
; |       AL - Screen location                                            |
; |            0 - Master disk                                            |
; |            1 - Dos disk                                               |
; |            2 - Working disk                                           |
; |       AH - Drive disk it is in.                                       |
; |                                                                       |
; =========================================================================

Disk_in_drive  proc     near

               cmp     al,0
               je      drive_master

               cmp     al,1
               je      drive_dos

               mov     dl,32h
               jmp     put_in_drive

        Drive_master:

               mov     dl,0ch
               jmp     put_in_drive

        Drive_dos:

               mov     dl,1fh

        Put_in_drive:

               add     ah,'A'
               mov     in_drive_disk,ah

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_0_display
               mov     dh,0dh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_1_display
               mov     dh,0eh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_2_display
               mov     dh,0fh
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_3_display
               mov     dh,10h
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_4_display
               mov     dh,11h
               call    display_message

               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_5_display
               mov     dh,12h
               call    display_message
 
               mov     bl,diagram_attribute_low
               mov     cx,offset in_drive_6_display
               mov     dh,13h
               call    display_message

               ret

Disk_in_drive  endp

Page

; =========================================================================
; |                                                                       |
; |                             DRIVE ON                                  |
; |                                                                       |
; =========================================================================

Drive_on        proc    near

                cmp     al,0
                jne     target_drive_on

                mov     dx,0835h
                jmp     turn_drive_on

        Target_drive_on:

                mov     dx,083fh

        Turn_drive_on:

                push    dx

                mov     bl,diagram_attribute_high
                mov     cx,offset open_drive_display
                dec     dh
                add     dl,3
                call    display_message

                pop     dx

                mov     bl,diagram_attribute_high
                mov     cx,offset drive_display
                call    display_message

                ret

Drive_on        endp

Page

; =========================================================================
; |                                                                       |
; |                           DRIVE OFF                                   |
; |                                                                       |
; =========================================================================

Drive_off       proc    near

                cmp     al,0
                jne     target_drive_off

                mov     dx,0835h
                jmp     turn_drive_off

        Target_drive_off:

                mov     dx,083fh

        Turn_drive_off:

                push    dx

                mov     bl,diagram_attribute_low
                mov     cx,offset open_drive_display
                dec     dh
                add     dl,3
                call    display_message

                pop     dx

                mov     bl,diagram_attribute_low
                mov     cx,offset drive_display
                call    display_message

                ret

Drive_off       endp

Page

; =========================================================================
; |                                                                       |
; |                         DISK ON                                       |
; |                                                                       |
; =========================================================================

Disk_on         proc    near

                cmp     al,0
                jne     disk_2_on

                mov     dl,0ch
                jmp     turn_disk_on

        Disk_2_on:

                cmp     al,1
                jne     disk_3_on

                mov     dl,1fh
                jmp     turn_disk_on

        Disk_3_on:

                mov     dl,32h

        Turn_disk_on:

                mov     bl,diagram_attribute_high
                mov     cx,offset disk_top_display
                mov     dh,0dh
                call    display_message

                inc     dh

                mov     cx,5

        Side_on_display_loop:

                push    cx

                mov     bl,diagram_attribute_high
                mov     cx,offset disk_side_display
                call    display_message

                push    dx

                add     dl,14

                mov     bl,diagram_attribute_high
                mov     cx,offset disk_side_display
                call    display_message

                inc     dh

                mov     bh,dh

                pop     dx
                pop     cx

                mov     dh,bh

                loop    side_on_display_loop

                cmp     disk_write_protect_error,3
                je      display_bottom_line_on

                push    dx

                sub     dh,2
                add     dl,2

                mov     bl,diagram_attribute_high
                mov     cx,offset disk_tab_display
                call    display_message

                pop     dx

        Display_bottom_line_on:

                mov     bl,diagram_attribute_high
                mov     cx,offset disk_bottom_display
                call    display_message

                ret

Disk_on         endp

Page

; =========================================================================
; |                                                                       |
; |                             DISK OFF                                  |
; |                                                                       |
; =========================================================================

Disk_off        proc    near

                cmp     al,0
                jne     disk_2_off

                mov     dl,0ch
                jmp     turn_disk_off

        Disk_2_off:

                cmp     al,1
                jne     disk_3_off

                mov     dl,1fh
                jmp     turn_disk_off

        Disk_3_off:

                mov     dl,32h

        Turn_disk_off:

                mov     bl,diagram_attribute_low
                mov     cx,offset disk_top_display
                mov     dh,0dh
                call    display_message

                inc     dh

                mov     cx,5

        Side_off_display_loop:

                push    cx

                mov     bl,diagram_attribute_low
                mov     cx,offset disk_side_display
                call    display_message

                push    dx

                add     dl,14

                mov     bl,diagram_attribute_low
                mov     cx,offset disk_side_display
                call    display_message

                inc     dh

                mov     bh,dh

                pop     dx
                pop     cx

                mov     dh,bh

                loop    side_off_display_loop

                cmp     disk_write_protect_error,3
                je      display_bottom_line_off

                push    dx

                sub     dh,2
                add     dl,2

                mov     bl,diagram_attribute_low
                mov     cx,offset disk_tab_display
                call    display_message

                pop     dx

        Display_bottom_line_off:

                mov     bl,diagram_attribute_low
                mov     cx,offset disk_bottom_display
                call    display_message

                ret

Disk_off        endp

Page

; =========================================================================
; |                                                                       |
; |                         DISPLAY HEADER                                |
; |                                                                       |
; =========================================================================

Display_header  proc    near

                mov     bl,header_attribute
                mov     cx,offset header_1_message
                mov     dx,0001h
                call    display_message

                mov     bl,header_attribute
                mov     cx,offset header_2_message
                mov     dx,0101h
                call    display_message

                mov     bl,header_attribute
                mov     cx,offset header_2_message
                mov     dx,014dh
                call    display_message

                mov     bl,header_attribute
                mov     cx,offset header_3_message
                mov     dx,0201h
                call    display_message

                mov    bl,header_text_attribute_low
                mov    cx,offset wv_message
                mov    dx,0103h
                call   display_message

                mov    bl,header_text_attribute_low
                mov    cx,offset tm_message
                mov    dx,0017h
                call   display_message

                mov    bl,header_text_attribute_high
                mov    cx,offset header_message
                mov    dx,0120h
                call   display_message

                ret

Display_header  endp

Page

; =========================================================================
; |                                                                       |
; |                           DISPLAY TRAILER                             |
; |                                                                       |
; =========================================================================

Display_trailer  proc   near

               push     ds
               push     es
               push     di
               push     si

               mov      ax,cs
               mov      ds,ax
               mov      es,ax

; Prepare first part of trailer text message

               cld

               mov      al,screen_step
               mov      step_number,al

               mov      si,offset step_message
               xor      ch,ch
               mov      cl,[si]
               mov      al,cl
               inc      si
               mov      di,offset trailer_buffer_message
               inc      di

               rep      movsb

               mov      si,screen_step_message
               xor      ch,ch
               mov      cl,[si]
               add      al,cl
               inc      si

               rep      movsb

               mov      bl,trailer_text_attribute
               mov      cx,offset trailer_buffer_message
               mov      trailer_buffer_message,al
               mov      dx,1701h
               call     display_message

; Display trailer bar message

               mov      bl,trailer_attribute
               mov      cx,offset trailer_message
               add      dl,al
               mov      al,3fh
               sub      al,dl
               inc      al                     ; in case of ESC message
               mov      trailer_message,al
               call     display_message

; Display stop or esc message

               mov      bl,trailer_text_attribute
               mov      cx,offset stop_message
               mov      dl,3fh

               cmp      labels,1
               je       vision_labels

               mov      cx,offset esc_message
               inc      dl

        Vision_labels:

               call     display_message

               mov    bl,07h
               mov    cx,offset legal_message
               mov    dx,18ffh
               call   display_message

               pop      si
               pop      di
               pop      es
               pop      ds

               ret

Display_trailer  endp

Page

; =========================================================================
; |                                                                       |
; |                            DISPLAY OPERATION                          |
; |                                                                       |
; |     OPERATION MESSAGE - offset of message (in prompt area)            |
; |     OPERATION PICTURE - offset of operation                           |
; | (attribute,length 1, ... message 1 ... ,length 2, ... message 2 ... ) |
; |                                                                       |
; =========================================================================

Display_operation proc  near

               push     ax
               push     bx
               push     cx
               push     dx
               push     si

               mov      ax,operation_message
               or       ax,operation_picture
               jz       display_operation_return

               call     clear_monitor

               cmp      operation_message,0000h
               je       check_operation

               mov      dx,702h
               mov      si,operation_message
               call     display_prompt

        Check_operation:

               cmp      operation_picture,0000h
               je       move_to_screen

               mov      si,operation_picture
               mov      bl,cs:[si]
               inc      si
               mov      cx,si
               mov      dx,0b38h
               call     display_message

               xor      ah,ah
               mov      al,cs:[si]
               inc      al
               add      cx,ax
               inc      dh
               call     display_message

        Move_to_screen:

               call     screen_page

        Display_operation_return:

               pop      si
               pop      dx
               pop      cx
               pop      bx
               pop      ax

               ret

Display_operation endp

Code_seg        ends

                end
     o   d        o   c        o   b        o   a