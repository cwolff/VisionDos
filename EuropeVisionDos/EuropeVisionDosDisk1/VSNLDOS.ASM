Name            VSNLDOS

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Load_DOS

Page 60,126

; *************************************************************************
; *                                                                       *
; *      (C)opyright 1983 Bruce & James Program Publishers Inc.           *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Page

Code_seg       segment public 'code'

               assume  cs:code_seg

               org     100h

;
; *** Externals
;

                        extrn  ibm_dos_error_prompt:near
                        extrn  clear_page:near
                        extrn  verify_ibm:near
                        extrn  ibm_dos_prompt:near
                        extrn  vsn_dos_error_prompt:near
                        extrn  vsn_dos_prompt:near
                        extrn  can_not_boot_dos:near
                        extrn  verify_master:near
                        extrn  disk_failure:near
                        extrn  display_error:near

                        extrn  source_drive:byte
                        extrn  destination_drive:byte
                        extrn  number_of_drives:byte
                        extrn  current_drive:byte
                        extrn  current_disk:byte
                        extrn  general_dta_1:word
                        extrn  general_dta_2:word
                        extrn  dos_offset:word
                        extrn  dos_segment:word
                        extrn  current_sector:byte
                        extrn  sectors_per_track:byte
                        extrn  number_of_sides:byte
                        extrn  can_not_boot_10_message:byte
                        extrn  can_not_boot_20_message:byte
                        extrn  can_not_boot_xx_message:byte

;
; *** Publics
;

                        public  disk_retry
                        public  dos_version
                        public  current_error
                        public  first_sector_to_read
                        public  number_of_sectors_to_read
                        public  load_dos

;
; *** Equates
;

Dos_version_10                  equ   00h
Dos_version_11                  equ   01h
Dos_version_20                  equ   02h
Dos_version_compaq              equ   03h

;
; *** DOS boot parameters
;

Number_of_sectors_to_read       dw     0000h

First_sector_to_read            dw     0000

Sector_size                     dw     200h

Current_error                   db     0

Disk_retry                      db     0

Dos_version                     db     00

;
; *** Error messages
;

Not_standard_pc_dos_disk        db     35,' SORRY: Not a standard PC-DOS disk '

Page

; =========================================================================
; |                                                                       |
; |                             LOAD DOS                                  |
; |                                                                       |
; |     Load ibm files if it DOS 1.0, 1.1, or Compaq. If DOS 2.0 then     |
; |     inform user that the working copy can not be made this way.       |
; |     If DOS is loaded successfully then prompt for working disk and    |
; |     jump to the start of DOS. If DOS can not be loaded inform the     |
; |     user and explain how they can successfully create a working       |
; |     copy. Then prompt for DOS and exit to operation system.           |
; |                                                                       |
; =========================================================================

Load_dos       proc     near

               call     clear_page

               mov      al,destination_drive
               mov      current_drive,al
               mov      current_disk,1

;
; *** IBM DOS prompt
;

               call     ibm_dos_prompt

               jmp      check_for_system

        Check_for_system_error_prompt:

               call     ibm_dos_error_prompt

        Check_for_system:

               call     verify_ibm

               jc       check_for_system_error_prompt

               mov      si,offset can_not_boot_10_message
               cmp      dos_version,dos_version_10
               je       unbootable_version

               mov      si,offset can_not_boot_20_message
               cmp      dos_version,dos_version_20
               je       unbootable_version

               mov      si,offset can_not_boot_xx_message
               cmp      dos_version,dos_version_compaq
               jb       continue_dos_verification

        Unbootable_version:

               call     can_not_boot_dos   ; EXIT to operating system

        Continue_dos_verification:

;
; *** Check for patch (prevent loading a hard disk version of DOS)
;

               call    check_for_patched_ibm

               jc      check_for_system_error_prompt

               call    load_ibm_files

               jc      check_for_system_error_prompt

;
; *** Ibm system file has been read in
; *** Instruct the user to to insert their working diskette
;

               mov     al,source_drive
               mov     current_drive,al
               mov     current_disk,0

               cmp     number_of_drives,2
               je      vsn_dos_check

               call    vsn_dos_prompt

               jmp     vsn_dos_check

        Display_vsn_dos_error_prompt:

               call    vsn_dos_error_prompt

        Vsn_dos_check:

               call    verify_master

               jc      display_vsn_dos_error_prompt

               call    visible_command

               jc      display_vsn_dos_error_prompt

               ret

Load_dos       endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       CHECK FOR PATCHED IBM                          |
; |                                                                      |
; |    Read in directory and verify that their are only 2 protected      |
; |    files. Any more than that shows a modified IBM DOS diskette.      |
; |                                                                      |
; |              Output:                                                 |
; |                      CY - 0 This is the diskette prompted for        |
; |                      CY - 1 This is not the diskette prompted for.   |
; |                                                                      |
; ------------------------------------------------------------------------

Check_for_patched_ibm   proc     near

               push     es

               mov      es,general_dta_1

               cmp      dos_version,dos_version_11
               jbe      prepare_to_check_for_patch

;
; *** Not 1.0 or 1.1 so don't check for patch
;

               clc

               jmp      check_ibm_return

        Prepare_to_check_for_patch:

               mov      disk_retry,3

        Check_for_patch_loop:

               mov      ax,0201h
               mov      ch,00h
               mov      cl,current_sector
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      check_for_protected_files

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      check_for_patch_loop

               call     disk_failure

               stc

               jmp      check_ibm_return

        Check_for_protected_files:

               mov      al,es:[bx+11]
               cmp      al,6
               jne      invalid_ibm

               mov      al,es:[bx+11+32]
               cmp      al,6
               jne      invalid_ibm

               mov      al,es:[bx+11+32+32]
               cmp      al,0
               je       valid_ibm

        Invalid_ibm:

               mov     cx,offset not_standard_pc_dos_disk
       	       call    display_error

               stc

               jmp      check_ibm_return

        Valid_ibm:

               clc

         Check_ibm_return:

               pop      es

               ret

Check_for_patched_ibm   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             VISIBLE COMMAND                           |
; |                                                                       |
; |     Make Master disk COMMAND.COM visible so it can be loaded by       |
; |     XXXDOS.COM.                                                       |
; |                                                                       |
; -------------------------------------------------------------------------

Visible_command proc  near

               push     es

               mov      es,general_dta_2
               mov      current_sector,4

               mov      disk_retry,3

        Read_directory_loop:

               mov      ax,0201h
               mov      ch,00
               mov      cl,current_sector
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      set_command_to_visible

               mov      current_error,ah

               mov      ah,0
               int      13h

               dec      disk_retry
               jnz      read_directory_loop

               call     disk_failure

               stc

               jmp      visible_return

        Set_command_to_visible:

               xor      bx,bx
               mov      byte ptr es:[bx+11+32],00
 
               mov      disk_retry,1

        Write_directory_loop:

               mov      ax,0301h
               mov      ch,00h
               mov      cl,current_sector
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      visible_return

               mov      current_error,ah

               mov      ah,0
               int      13h

               dec      disk_retry
               jnz      write_directory_loop

               call     disk_failure

               stc

        Visible_return:

               pop      es

               ret

Visible_command endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            LOAD IBM FILES                             |
; |                                                                       |
; -------------------------------------------------------------------------

Load_ibm_files  proc    near

                push    es

                mov     es,dos_segment

                mov     bx,dos_offset
                mov     cx,first_sector_to_read

                push    cx

                mov     al,sectors_per_track
                inc     al
                sub     al,cl
                mov     ah,0
                mov     si,ax

                mov     disk_retry,3

        Read_ibm_loop:

                push    si
                push    bx

                xor     dx,dx
                xor     ax,ax
                mov     al,ch
                div     number_of_sides
                mov     ch,al
                mov     dh,ah
                mov     dl,current_drive
                mov     ax,si
                mov     ah,02

                int     13h

                jnc     continue_ibm_read

                mov     current_error,ah

                xor     ax,ax
                int     13h

                pop     bx
                pop     si
                pop     cx

                push    cx

                dec     disk_retry
                jnz     read_ibm_loop

                call    disk_failure

; Make sure there is still a IBM DOS disk present

                pop     cx

                stc

                jmp     load_ibm_files_return

        Continue_ibm_read:

                pop     bx
                pop     si
                pop     cx

                sub     number_of_sectors_to_read,si
                jz      load_ibm_files_return

                mov     ax,si
                mul     sector_size
                add     bx,ax
                inc     ch
                mov     cl,01

                push    cx

                xor     dx,dx
                mov     dl,sectors_per_track
                mov     si,dx
                cmp     si,number_of_sectors_to_read
                jl      end_of_ibm_read_loop

                mov     si,number_of_sectors_to_read

        End_of_ibm_read_loop:

                mov     disk_retry,3

                jmp     read_ibm_loop

        Load_ibm_files_return:

                pop     es

                ret

Load_ibm_files  endp

Code_seg        ends

                end
        n               o   ikrty3

        m   edimlo    La_b_ie_eun        pp  e        rt

odimfls np

oesg    ns

                                                                                                           