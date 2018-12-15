Name            VSNBOOT

Title           Bruce_&_James_Inc_Boot

Subttl          Vision_Boot

Page 60,132

; *************************************************************************
; *                                                                       *
; *      (C)opyright 1983 Bruce & James Program Publishers Inc.           *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                            Vision DOS                               |
; |                                                                      |
; |      Set up label for sliboot to jump to after reading from disk     |
; |                                                                      |
; ------------------------------------------------------------------------

Vsn_dos_seg     segment at 0800h

                org     100h

Vsndos          label   far

Vsn_dos_seg      ends

Page

Code_seg        segment public 'code'

                org   7c00h

                assume  cs:code_seg

; =========================================================================
; *                                                                       *
; *                             Vision BOOT                               *
; *                                                                       *
; *      Boot is read into memory by the PROM interrupt 19h. It check to  *
; *    to see if SLIDOS is present on the disk. If so read in SLIDOS and  *
; *      transfers control to it. (location 800:0)                        *
; *                                                                       *
; =========================================================================

Vsn_boot        proc    far

                jmp     start_vsn_boot

;
; *** Data Area to be used by boot
;

Master_name                     db     'master disk'

Total_no_of_sectors_to_read     db     52

No_of_sectors_to_read           db     1

Sector_size                     dw     200h

Current_track                   db     0

Current_sector                  db     8

Loaded_by_vsnboot               dw      0ffffh

;
; *** Boot messages
;

Boot_failure_message            db     05h,0fh
                                db     'The disk drive is not '
                                db     'working properly. Please restart '
                                db     'the Computer. '
                                db     0ffh

Copyright_message               db     '(C)opyright 1983 Bruce & James '
                                db     'Program Publishers Inc.'

Author_message                  db     'Author,Cameron L Wolff'

        Start_vsn_boot:
     
                cli

;
; *** Set up segment registers and stack pointer
;

                mov     ax,cs
                mov     ds,ax
                mov     ax,vsn_dos_seg
                mov     es,ax
                xor     ax,ax
                mov     ss,ax
                mov     sp,7c00h

                sti

;
; *** Reset the disk system
;

                xor     ax,ax
                int     13h

                jnc     read_vsn_dos

                call    boot_failure

;
; *** Read in COMMAND.COM and transfer control to it.
; *** COMMAND.COM is a system file hence it will be loaded by an absolute
; *** disk address read. The number of sectors to be read are determined
; *** by the variable total_no_of_sectors_to_read. Boot will read consecutively
; *** from track 0 sector 8 until all the COMMAND.COM sectors are read.
;

        Read_vsn_dos:

                mov     bx,100h            ; starting offset

;
; *** Disk read loop.
;

        Vsn_dos_read_loop:

                mov     ah,2
                mov     al,no_of_sectors_to_read
                mov     ch,current_track
                mov     cl,current_sector
                xor     dx,dx
                int     13h

                jnc     check_if_done

                call    boot_failure       ; boot failure inform user

;
; *** Check to see if all the sectors have been read
;

        Check_if_done:

                cmp     total_no_of_sectors_to_read,0
                jz      vsn_dos_jump

;
; *** Calculate next offset within segment 80h to read
;

                mov     al,no_of_sectors_to_read
                cbw
                mul     sector_size
                add     bx,ax

;
; *** Update disk read parameters
;

                mov     al,total_no_of_sectors_to_read
                cmp     total_no_of_sectors_to_read,8
                ja      more_than_full_track

                mov     no_of_sectors_to_read,al
                mov     total_no_of_sectors_to_read,0
                jmp     update_disk_info

        More_than_full_track:

                sub     al,no_of_sectors_to_read
                mov     total_no_of_sectors_to_read,al
                mov     no_of_sectors_to_read,8

        Update_disk_info:

                inc     current_track
                mov     current_sector,1
                jmp     vsn_dos_read_loop

;
; *** Vsndos.com has been read in transfer control to it
;

        Vsn_dos_jump:

                push    es
                mov     ax,100h
                push    ax

                mov     es,loaded_by_vsnboot

                ret

Vsn_boot        endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                              BOOT FAILURE                            |
; |                                                                      |
; |                  Disk boot failure, disk drive failed.               |
; |                  Inform user and stay in infinite loop.              |
; |                                                                      |
; ------------------------------------------------------------------------

Boot_failure    proc    near

                mov     si,offset boot_failure_message
                call    display_message

        Infinite_loop:

                jmp     infinite_loop

Boot_failure    endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          DISPLAY MESSAGE                             |
; |                                                                      |
; |  Display message driver. Display string until a 0ffh is encountered  |
; |                                                                      |
; |              Input:                                                  |
; |                      CS:SI - contains address of message             |
; |                                                                      |
; ------------------------------------------------------------------------

Display_message proc    near

                mov     bx,0007h

                mov     ah,2
                mov     dx,cs:[si]
                int     10h 

                add     si,2

        Display_loop:

                mov     al,cs:[si]
                cmp     al,0ffh
                je      display_return

                mov     ah,0eh
                int     10h

                inc     si
                jmp     display_loop

        Display_return:

                mov     ah,2
                mov     dx,0ffffh
                int     10h 

                ret

Display_message endp

Code_seg        ends

                end     vsn_boot
dslylo  