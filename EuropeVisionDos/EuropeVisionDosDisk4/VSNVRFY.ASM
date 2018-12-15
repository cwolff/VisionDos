Name            VSNVRFY

Title           Bruce_&_James_Inc_Dos

Subttl          Vision_Verify

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

                extrn  sectors_per_track:byte
                extrn  dos_version:byte
                extrn  general_dta_1:word
                extrn  general_dta_2:word
                extrn  number_of_sides:byte
                extrn  first_sector_to_read:word
                extrn  disk_retry:byte
                extrn  current_drive:byte
                extrn  current_error:byte
                extrn  number_of_sectors_to_read:byte
                extrn  dos_segment:word
                extrn  dos_offset:word
                extrn  load_indicator:byte
                extrn  running_dos_version:byte

                extrn  disk_failure:near
                extrn  display_error:near
                extrn  search_first_entry:near

;
; *** Publics
;

                public  check_for_ibm_system
                public  verify_master
                public  verify_work
                public  verify_ibm
                public  verify_ibm_system
                public  hide_command_file
                public  write_protect_master_check

                public  ibm_bio_name
                public  ibm_dos_name
                public  xxx_bio_name
                public  xxx_dos_name
                public  command_name
                public  dos_format
                public  current_sector

;
; *** Equates
;

Loaded_by_boot           equ    0ffffh
Dos_version_unknown      equ    0ffh
Dos_version_10           equ    00h
Dos_version_11           equ    01h
Dos_version_20           equ    02h
Dos_version_compaq       equ    03h

Page

;
; *** Files names used to verify promper disks
;

Ibm_bio_name                    db     'ibmbio  com'

Ibm_dos_name                    db     'ibmdos  com'

Command_name                    db     'command com'

Vsn_dos_name                    db     'master disk'

Xxx_bio_name                    db     'iosys   com'

Xxx_dos_name                    db     'msdos   com'

;
; *** First three bytes of boot tracks used to verify DOS version
;

Dos_10                          db     0ebh,2fh,14h

Dos_11                          db     0ebh,27h,90h

Dos_20                          db     0ebh,2ch,90h

Compaq                          db     0fah,0bch,0e7h

;
; *** Verify disk variables
;

Current_sector                  db     00h    ; sector for check disk to read

Dos_format                      db     00h    ; First byte of FAT

;
; *** Wrong disk error messages
;

Not_pc_dos_disk            db     27,' SORRY: Not a PC-DOS disk. '

Not_standard_pc_dos_disk   db     36,' SORRY: Not a standard PC-DOS disk. '

Not_wv_master_disk         db     38,' SORRY: Not a Wordvision Master disk. '

Not_xxx_disk               db     24,' SORRY: Not a DOS disk. '

Bad_version_message        db     33,' SORRY: Not a standard DOS disk. '

Bad_disk_format_message    db     37,' SORRY: Not a floppy formatted disk. '

Not_working_message    db  36,' SORRY: This is not a Working disk. '

Not_master_message     db  46,' SORRY: This is not a Wordvision Master disk. '

Not_ibm_message        db  33,' SORRY: This is not PC-DOS disk. '

Not_xxx_message        db  32,' SORRY: This is not a DOS disk. '

;
; *** Not write protect error
;

Not_write_protected_message  db  47,' SORRY: Wordvision Master not write'
                             db     ' protected. '

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          CHECK DISK                                  |
; |                                                                      |
; |    Read in directory and verify that the first file listed is a      |
; |    file specified by the address of cs:si                            |
; |                                                                      |
; |              Input:                                                  |
; |                     CS:[SI] address of file to match                 |
; |                     DI offset into DTA for compare                   |
; |                                                                      |
; |              Output:                                                 |
; |                      CY - 0 This is a diskette prompted for          |
; |                      CY - 1 This is not a diskette prompted for      |
; |                                                                      |
; ------------------------------------------------------------------------

Check_disk     proc     near

               push     es

               mov      es,general_dta_1

               push     si
               push     di

               mov      disk_retry,3

        Check_disk_loop:

               mov      ax,0201h
               mov      ch,00h
               mov      cl,current_sector
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      convert_to_lower_case

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      check_disk_loop

               call     disk_failure

               pop      di
               pop      si

               stc

               jmp      check_disk_return

        Convert_to_lower_case:

               pop      di
               pop      si

               push     di

               mov      cx,0bh

               cld

        Convert_loop:

               or       byte ptr es:[di],20h
               inc      di

               loop     convert_loop

               pop      di

               mov      cx,0bh

               repz     cmpsb

               jz       valid_disk

               mov      al,1

               clc

               jmp      check_disk_return

        Valid_disk:

               mov      al,0

               clc

         Check_disk_return:

               pop      es

               ret

Check_disk     endp

Page

; ========================================================================
; |                                                                      |
; |                      CHECK FOR IBM SYSTEM                            |
; |                                                                      |
; |          AL - 0   contains operation system                          |
; |          AL - 1   dosnt contain operation system                     |
; |                                                                      |
; ========================================================================

Check_for_ibm_system proc near

                call    get_disk_format

                jnc     call_get_dos_version

                jmp     check_for_ibm_system_return

        Call_get_dos_version:

                call    get_dos_version

                jnc     determine_version_to_check

                jmp     check_for_ibm_system_return

        Determine_version_to_check:

                cmp     dos_version,dos_version_compaq
                jb      check_for_ibm_bio

        Check_for_xxx_bio:

                mov     si,offset xxx_bio_name
                mov     di,00h
                call    check_disk

                jc      check_for_ibm_system_return

                cmp     al,0
                je      check_for_xxx_dos

                jmp     invalid_dos_disk

        Check_for_xxx_dos:

                mov     si,offset xxx_dos_name
                mov     di,20h
                call    check_disk

                jc      check_for_ibm_system_return

                cmp     al,0
                je      check_for_ibm_system_return

                jmp     invalid_dos_disk

        Check_for_ibm_bio:

                mov     si,offset ibm_bio_name
                mov     di,00h
                call    check_disk

                jc      check_for_ibm_system_return

                cmp     al,0
                je      check_for_ibm_dos

                jmp     invalid_dos_disk

        Check_for_ibm_dos:

                mov     si,offset ibm_dos_name
                mov     di,20h
                call    check_disk

                jc      check_for_ibm_system_return

                cmp     al,0
                je      check_for_ibm_system_return

        Invalid_dos_disk:

                mov     al,1

                clc

        Check_for_ibm_system_return:

                ret

Check_for_ibm_system endp

Page

; =========================================================================
; |                                                                       |
; |                          GET DISK FORMAT                              |
; |                                                                       |
; |        Read in FAT to determine number of sectors per track and       |
; |        number of sides of disk. Determine first sector to read        |
; |        for boot load.                                                 |
; |        Also get the current sector for the directory                  |
; |                                                                       |
; =========================================================================

Get_disk_format proc  near

               push     es

               mov      es,general_dta_2

               mov      sectors_per_track,08h

               mov      disk_retry,3

        Read_fat_loop:

               mov      ax,0201h
               mov      cx,0002h
               mov      dh,00h
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      verify_disk_format

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      read_fat_loop

               call     disk_failure

               stc

               jmp      get_disk_format_return

        Verify_disk_format:

               xor      bx,bx
               mov      al,es:[bx]
               mov      dos_format,al

               cmp      al,0feh
               je       eight_sectors_1_side

               cmp      al,0ffh
               je       eight_sectors_2_sides

               cmp      al,0fch
               je       nine_sectors_1_side

               cmp      al,0fdh
               je       nine_sectors_2_sides

               mov      cx,offset bad_disk_format_message
               call     display_error

               stc

               jmp      get_dos_version_return

       Eight_sectors_1_side:

               mov      current_sector,04
               mov      number_of_sides,01h

               mov      sectors_per_track,08h
               mov      first_sector_to_read,0008h

               jmp      get_disk_format_return

       Eight_sectors_2_sides:

               mov      current_sector,04h
               mov      number_of_sides,02h

               mov      sectors_per_track,08h
               mov      first_sector_to_read,0103h

               jmp      get_disk_format_return

       Nine_sectors_1_side:

               mov      current_sector,06h
               mov      number_of_sides,01h

               mov      sectors_per_track,09h
               mov      first_sector_to_read,0101h

               jmp      get_disk_format_return

       Nine_sectors_2_sides:

               mov      current_sector,06h
               mov      number_of_sides,02h

               mov      sectors_per_track,09h
               mov      first_sector_to_read,0104h

        Get_disk_format_return:

               pop      es

               ret

Get_disk_format endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                        GET DOS VERSION                                |
; |                                                                       |
; |        Read in boot track to determine DOS version                    |
; |                                                                       |
; |        First 3 bytes - EB 2F 14 , DOS 1.0      Dos_version - 0        |
; |                        EB 27 90 , DOS 1.1                    1        |
; |                        EB 2C 90 , DOS 2.0                    2        |
; |                        FA BC E7 , Compaq                     3        |
; |                        all others                           ff        |
; |         Also determine number of sectors to read for boot load        |
; |         as well as boot load address.                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Get_dos_version proc    near

               push     es

               mov      es,general_dta_2

               mov      disk_retry,3

        Read_version_loop:

               mov      ax,0201h
               mov      cx,0001
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      verify_dos_version

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      read_version_loop

               call     disk_failure

               stc

               jmp      get_dos_version_return

        Verify_dos_version:

               cld

               mov      cx,3

               mov      si,offset dos_10
               mov      di,0

               repz     cmpsb

               jnz      check_for_dos_11

               jmp      version_dos_10

        Check_for_dos_11:

               mov      cx,3

               mov      si,offset dos_11
               mov      di,0

               repz     cmpsb

               jnz      check_for_dos_20

               jmp      version_dos_11

        Check_for_dos_20:

               mov      cx,3

               mov      si,offset dos_20
               mov      di,0

               repz     cmpsb

               jnz      check_for_compaq

               jmp      version_dos_20

        Check_for_compaq:

               mov      cx,3

               mov      si,offset compaq
               mov      di,0

               repz     cmpsb

               jnz      dont_recognize_version

               jmp      version_compaq

        Dont_recognize_version:

               mov      dos_version,dos_version_unknown

               clc

               jmp      get_dos_version_return

        Version_dos_10:

               mov      dos_version,dos_version_10
               mov      number_of_sectors_to_read,14h

               mov     ax,60h
               mov     dos_segment,ax
               xor     ax,ax
               mov     dos_offset,ax

               jmp      have_version

        Version_dos_11:

               mov      dos_version,dos_version_11
               mov      number_of_sectors_to_read,14h

               mov     ax,60h
               mov     dos_segment,ax
               xor     ax,ax
               mov     dos_offset,ax

               jmp      have_version

        Version_dos_20:

               mov      dos_version,dos_version_20
               mov      number_of_sectors_to_read,0

               jmp      have_version

        Version_compaq:

               mov      dos_version,dos_version_compaq
               mov      number_of_sectors_to_read,11h

               mov     ax,60h
               mov     dos_segment,ax
               xor     ax,ax
               mov     dos_offset,ax

         Have_version:

               clc

        Get_dos_version_return:

               pop      es

               ret

Get_dos_version endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              HIDE COMMAND FILE                        |
; |                                                                       |
; -------------------------------------------------------------------------

Hide_command_file proc near

                push    es

                mov     ax,general_dta_2
                mov     es,ax

                mov     current_sector,04h

                mov     disk_retry,3

        Read_directory_loop:

                mov     ax,0201h
                mov     ch,00h
                mov     cl,current_sector
                mov     dx,0
                mov     bx,0
                int     13h

                jnc     set_command_to_invisible

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     read_directory_loop
 
                call    disk_failure

                stc

                jmp     hide_command_file_return

        Set_command_to_invisible:

                mov     byte ptr es:[bx+11+32],06h

                mov     disk_retry,1

        Write_directory_loop:

                mov     ax,0301h
                mov     ch,00h
                mov     cl,current_sector
                mov     dx,0
                mov     bx,0
                int     13h

                jnc     hide_command_file_return

                mov     current_error,ah

                mov     ah,0
                int     13h

                dec     disk_retry
                jnz     write_directory_loop

                call    disk_failure

                stc

        Hide_command_file_return:

                pop     es

                ret

Hide_command_file endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                     WRITE PROTECT MASTER CHECK                       |
; |                                                                      |
; |                 Checks to see if MASTER is write protectd            |
; |                                                                      |
; ------------------------------------------------------------------------

Write_protect_master_check proc near

                push    es

                mov     ax,general_dta_2
                mov     es,ax

                mov     current_sector,04h

;
; ***  Read in a sector and try to write it back to verify write protect tab
;

                mov     disk_retry,3

        Protect_read_loop:

                mov     ax,0201h
                mov     ch,2h
                mov     cl,current_sector
                mov     dx,0000h
                mov     bx,0
                int     13h

                jnc     check_write_protect

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jnz     protect_read_loop

                call    disk_failure

                stc

                jmp     write_protect_master_return

        Check_write_protect:

                mov     disk_retry,1

         Protect_write_loop:

                mov     ax,0301h
                mov     ch,2h
                mov     cl,current_sector
                mov     dx,0000h
                mov     bx,0
                int     13h

                jnc     disk_not_write_protected

                mov     current_error,ah

                mov     ax,0
                int     13h

                mov     ah,current_error
                and     ah,03h
                cmp     ah,03h
                je      disk_write_protected

                dec     disk_retry
                jnz     protect_write_loop

                call    disk_failure

                stc

                jmp     write_protect_master_return

        Disk_not_write_protected:

                mov     cx,offset not_write_protected_message
                call    display_error

                stc

                jmp     write_protect_master_return

        Disk_write_protected:

                clc

        Write_protect_master_return:

                pop     es

                ret

Write_protect_master_check endp

Page

; =========================================================================
; |                                                                       |
; |                            VERIFY MASTER                              |
; |                                                                       |
; |                                                                       |
; =========================================================================

Verify_master   proc near

                call    get_disk_format

                jc      verify_master_return

                mov     current_sector,1       ; read boot track not directory

                mov     si,offset vsn_dos_name
                mov     di,03h
                call    check_disk

                jc      verify_master_return

                cmp     al,0
                je      verify_master_return

                mov     cx,offset not_master_message
                call    display_error

                stc

        Verify_master_return:

                ret

Verify_master   endp

Page

; ========================================================================
; |                                                                      |
; |                              VERIFY WORK                             |
; |                                                                      |
; |            Make sure its not a work vision master diskette           |
; |                                                                      |
; |          Output:                                                     |
; |                 CY - 1 blank diskette                                |
; |                                                                      |
; ========================================================================

Verify_work     proc near

                call    get_disk_format

                jc      verify_work_return

                mov     current_sector,1      ; make sure not master

                mov     si,offset vsn_dos_name
                mov     di,03h
                call    check_disk

                jc      verify_work_return

                cmp     al,1
                je      verify_work_return

                mov     cx,offset not_working_message
                call    display_error

                stc

        Verify_work_return:

                ret

Verify_work     endp

Page

; =========================================================================
; |                                                                       |
; |                          VERIFY IBM SYSTEM                            |
; |                                                                       |
; |                  Verify that is a IBM DOS diskette                    |
; |                                                                       |
; =========================================================================

Verify_ibm_system  proc    near

                call    check_for_ibm_system

                jc      verify_ibm_system_return

                cmp     al,1
                je      not_valid_dos_system

                mov     al,0
                mov     si,offset command_name              
                call    search_first_entry

                jc      not_valid_dos_system

                mov     al,0

                jmp     verify_ibm_system_return

        Not_valid_dos_system:

                mov     al,1

                clc

        Verify_ibm_system_return:

                ret

Verify_ibm_system endp

Page

; =========================================================================
; |                                                                       |
; |                          VERIFY IBM                                   |
; |                                                                       |
; |                  Verify that is a IBM DOS diskette                    |
; |                                                                       |
; |     Output                                                            |
; |            CY - 0,  Al - 0 valid disk,  AL - 1 running under pre 2.0  |
; |                                                release and disk is    |
; |                                                2.0                    |
; |            CY - not valid dos and error displayed                     |
; |                                                                       |
; =========================================================================

Verify_ibm      proc    near

                call    check_for_ibm_system

                jc      verify_ibm_return

                cmp     al,0
                jne     not_valid_dos_disk

                cmp     load_indicator,loaded_by_boot
                je      verify_ibm_return

                mov     al,0
                mov     si,offset command_name              
                call    search_first_entry

                jc      not_valid_dos_disk

;
; *** Determine if DOS 1.0,1.1 is tring to read DOS 2.0
;

                cmp     running_dos_version,dos_version_20
                jne     check_older_version

                clc

                mov     al,0

                jmp     verify_ibm_return  ; *** 2.0 can handle older versions

        Check_older_version:

                cmp     dos_version,dos_version_20
                je      incapatible_dos_version

                clc

                mov     al,0

                jmp     verify_ibm_return  ; *** 1.0,1.1 can not read 2.0

        Incapatible_dos_version:

                clc

                mov     al,1

                jmp     verify_ibm_return

;
; *** Determine what DOS is being checked
;

        Not_valid_dos_disk:

                cmp     dos_version,dos_version_compaq
                jb      not_ibm_disk

                mov     cx,offset not_xxx_message
                call    display_error

                stc

                jmp    verify_ibm_return

        Not_ibm_disk:

                mov     cx,offset not_ibm_message
                call    display_error

                stc

                jmp     verify_ibm_return

        Verify_ibm_return:

                ret

Verify_ibm      endp

Code_seg        ends

                end    eiyimrtr:

        eVrf_b   edCd_e    ed        ed  eymt:
    Vfb eC_  e    e em:  f _    m  _ m_   _b_eun

        