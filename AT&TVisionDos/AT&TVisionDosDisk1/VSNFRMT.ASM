Name            VSNFRMT

Title           Bruce_&_James_Command

Subttl          Vision_Format

Page 60,132

; *************************************************************************
; *                                                                       *
; *         (C)opyright 1983 Bruce & James Program Publishers Inc.        *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume  cs:code_seg

;
; *** External procedures
;

                extrn   display_vision_picture:near
                extrn   disk_failure:near
                extrn   verify_work:near
                extrn   verify_ibm_system:near
                extrn   read_ibm_files:near
                extrn   write_ibm_files:near
                extrn   search_first_entry:near
                extrn   search_next_entry:near
                extrn   blank_prompt:near
                extrn   blank_error_prompt:near
                extrn   display_menu:near
                extrn   clear_page:near
                extrn   screen_page:near
                extrn   function_choice:near
                extrn   can_not_boot_dos:near
                extrn   display_operation:near

                extrn   dos_version:byte
                extrn   number_of_drives:byte
                extrn   sectors_per_track:byte
                extrn   source_drive:byte
                extrn   destination_drive:byte
                extrn   current_drive:byte
                extrn   current_disk:byte
                extrn   current_error:byte
                extrn   file_control_block:byte
                extrn   any_file_name:byte
                extrn   ibm_bio_name:byte
                extrn   ibm_dos_name:byte
                extrn   command_name:byte
                extrn   general_dta_1:word
                extrn   general_dta_2:word
                extrn   disk_retry:byte
                extrn   operation_message:word
                extrn   operation_picture:word
                extrn   can_not_boot_10_message:byte
                extrn   running_dos_version:byte

;
; *** Public procedure
;

                public  format_work_copy
                public  number_of_sides
                public  format_number_of_sides
                public  format_dos_version
                public  format_marker
                public  format_sectors_per_track

;
; *** Equates
;

Dos_version_10      equ      0
Dos_version_20      equ      2

Page

Number_of_sides              db     00h

Format_number_of_sides       db     00h

Current_track_side           dw     00h

Format_dos_version           db     00h

Current_length               db     00h
Current_directory_sector     db     00h
Directory_empty_marker       db     00h
Format_marker                db     00h
Format_sectors_per_track     dw     00h

Format_block                db      00,00,01,02
                            db      00,00,02,02
                            db      00,00,03,02
                            db      00,00,04,02
                            db      00,00,05,02
                            db      00,00,06,02
                            db      00,00,07,02
                            db      00,00,08,02
                            db      00,00,09,02

Disk_io_parameters          db      4 dup (00)

;
; *** Format operation message
;

Format_operation_message    db   1
                            db   30,'Now FORMATTING the Blank disk.'

Format_attribute            label byte
Format_operation_picture    db   07
                            db   1,24
                            db   13,192,27,27,'FORMATTING'

;
; ** Not a blank disk prompt
;

Files_prompt db 2,53,'There are already files on the disk you are using for'
             db   54,'the Working copy. Do you want to use a different disk?' 

Three_choice_menu db        3
                 db        1
                 db        39,'No. Erase disk completely and go ahead.'
                 db        2
                 db        46,'No. Add Wordvision files to those now on disk.'
                 db        3
                 db        47,'Yes. Disk has been changed for different blank.'

Two_choice_menu  db        2
                 db        1
                 db        39,'No. Erase disk completely and go ahead.'
                 db        3
                 db        47,'Yes. Disk has been changed for different blank.'

Three_choice_string db 3,1,2,3

Two_choice_string  db 2,1,3

Page

; =========================================================================
; |                                                                       |
; |                            FORMAT WORK COPY                           |
; |                                                                       |
; |      Format working copy only if it is not formatted. If there        |
; |      are files check to see if there is enough room on the disk       |
; |      for the Word Vision working copy files. If there isnt            |
; |      enough room inform the user. If there is enough room inform      |
; |      the user that there are files on the disk and ask them if        |
; |      1) they want them destroyed or 2) they want the word vision      |
; |      added to the disk.                                               |
; |                                                                       |
; =========================================================================

Format_work_copy proc   near

                call    read_ibm_files

                mov     al,dos_version
                mov     format_dos_version,al

                cmp     dos_version,dos_version_10
                jne     format_work_copy_retry

                mov     si,offset can_not_boot_10_message
                call    can_not_boot_dos         ; EXIT to operating system

;
; *** Format work copy
;

        Format_work_copy_retry:

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,2

                call    blank_prompt

                jmp     blank_disk_check

        Format_work_copy_error_prompt:

                call    blank_error_prompt

        Blank_disk_check:

                call    check_if_blank_disk

                jc      format_work_copy_error_prompt

                cmp     al,0
                jne     inform_user_disk_not_empty

                jmp     format_disk_operation

;
; *** Disk not blank, inform user if this is what they want
;

        Inform_user_disk_not_empty:

                call    verify_work

                jc      format_work_copy_error_prompt

                call   verify_size

                jc      format_work_copy_error_prompt

                cmp     al,0
                jne     no_space_option

                call    verify_ibm_system

                jc      format_work_copy_error_prompt

                cmp     al,0
                jne     no_space_option    ; *** Does not contain system

                cmp     running_dos_version,dos_version_20
                je      enough_space_options

                cmp     dos_version,dos_version_20
                jne     no_space_option   ; *** DOS 1.0,1.1 can not read
                                          ; *** read DOS 2.0

;
; ***  Three choice menu
;

        Enough_space_options:

                call    clear_page

                mov     cx,offset files_prompt
                mov     si,offset three_choice_menu
                call    display_menu

                mov     si,offset three_choice_string
                call    function_choice

                jmp     process_function_choice

;
; *** Two choice menu
;

        No_space_option:

                call    clear_page

                mov     cx,offset files_prompt
                mov     si,offset two_choice_menu
                call    display_menu

                mov     si,offset two_choice_string
                call    function_choice

        Process_function_choice:

                push    ax

                call    display_vision_picture

                pop     ax

                cmp     al,1
                je      format_disk_operation_check

                cmp     al,2
                je      format_work_copy_return

                jmp     blank_disk_check

        Format_disk_operation_check:

                call     screen_page

                call     verify_work

                jnc      format_disk_operation

                jmp      format_work_copy_error_prompt

        Format_disk_operation:

                call   format_driver

                jnc    write_dos_files

                jmp    format_work_copy_error_prompt

        Write_dos_files:

                call   write_ibm_files

                jnc    format_work_copy_return

                mov    al,source_drive
                mov    current_drive,al
                mov    current_disk,2

                jmp    format_work_copy_error_prompt

        Format_work_copy_return:

                ret

Format_work_copy endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          CHECK IF BLANK DISK                          |
; |                                                                       |
; |                       Determine if disk is blank                      |
; |       Also verifies that it is not a word vision master diskette      |
; |                                                                       |
; |         Output:                                                       |
; |                 CY - 1  fatal disk error                              |
; |                      CY - 0 successful test                           |
; |                           AL - 0 blank disk                           |
; |                           AL - 1 not blank disk                       |
; |                                                                       |
; |                                                                       |
; -------------------------------------------------------------------------

Check_if_blank_disk proc near

                mov     disk_retry,3

        Blank_test_loop:

                mov     ax,0408h
                mov     cx,0001h
                mov     dh,0
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     disk_not_blank

                mov     current_error,ah

                xor     ax,ax
                int     13h

                test    current_error,00010110b
                jz      blank_test_error

                jmp     blank_disk

        Blank_test_error:

                dec     disk_retry
                jnz     blank_test_loop

                call    disk_failure

                stc

                jmp     check_if_blank_return

        Disk_not_blank:

                mov     al,1
                mov     si,offset any_file_name
                call    search_first_entry

                jnc     not_blank

        Blank_disk:

                clc

                mov     al,0

                jmp     check_if_blank_return

        Not_blank:

                clc

                mov     al,1

        Check_if_blank_return:

                ret

Check_if_blank_disk endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             FORMAT DRIVER                             |
; |                                                                       |
; |         Determine if single or double sided format of diskette        |
; |                                                                       |
; |          CY - 0 succeful operation CY - 1 fatal error                 |
; |                                                                       |
; -------------------------------------------------------------------------

Format_driver   proc    near

                mov     format_sectors_per_track,08h
                mov     sectors_per_track,08h

                cmp     format_dos_version,dos_version_20
                jne     check_first_side

                mov     format_sectors_per_track,09h
                mov     sectors_per_track,09h

        Check_first_side:

                mov     disk_retry,3

        Format_driver_loop:

                mov     ax,0000h
                call    set_format_parameters

                int     13h

                jnc     check_dos_version

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jnz     format_driver_loop

                call    disk_failure

                stc

                jmp     format_driver_return

;
; *** Format second side and verify to check if two heads on drive
; *** unless DOS 1.0 then set to single side regarless
;

        Check_dos_version:

                mov     format_number_of_sides,0

                cmp     format_dos_version,dos_version_10
                je      format_disk

        Check_second_side:

                mov     ax,0001h
                call    set_format_parameters

                int     13h

                xor     ax,ax
                int     13h

                mov     ax,0408h
                mov     cx,0001h
                mov     dh,01              ; second side
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jc      format_disk

                mov     format_number_of_sides,1

        Format_disk:

                mov     ax,0100h
                mov     current_track_side,ax
                mov     disk_retry,3

                mov     dx,offset format_operation_message
                mov     operation_message,dx
                mov     dx,offset format_operation_picture
                mov     operation_picture,dx

        Format_disk_loop:

                mov     format_attribute,0fh
                call    display_operation

                call    set_format_parameters

                int     13h

                jnc     next_track_or_side

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jz      format_disk_error

                mov     ax,current_track_side
                jmp     format_disk_loop

        Format_disk_error:

                call    disk_failure

                stc

                jmp     format_driver_return

        Next_track_or_side:

                mov     format_attribute,07h
                call    display_operation

                cmp     format_number_of_sides,0
                je      next_track
 
                mov     ax,current_track_side
                cmp     al,0
                jne     next_track

                mov     al,1
                mov     current_track_side,ax
                jmp     format_disk_loop

        Next_track:

                mov     ax,current_track_side
                mov     al,0
                inc     ah
                mov     current_track_side,ax

                cmp     ah,40
                je      format_done

                jmp     format_disk_loop

        Format_done:

                call    set_fat

                jc      format_driver_return

                call    set_directory

        Format_driver_return:

                mov     operation_message,0000h
                mov     operation_picture,0000h

                ret

Format_driver   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                       SET FORMAT PARAMETERS                           |
; |                                                                       |
; |          Sets format parameters and set the registers for the         |
; |                       next format operations                          |
; |                                                                       |
; |         CY - 0 successful operation    CY - 1 fatal error             |
; |                                                                       |
; -------------------------------------------------------------------------

Set_format_parameters proc near

                mov     bx,offset format_block

                mov     dl,1
                mov     dh,2

                xor     ch,ch
                mov     cl,sectors_per_track

        Set_block_loop:

                mov     [bx],ah
                mov     [bx+1],al
                mov     [bx+2],dl
                mov     [bx+3],dh

                add     bx,4
                inc     dl

                loop    set_block_loop

;
; *** Set registers for next format operation
;

                mov     bx,offset format_block

                mov     ah,05h
                mov     al,sectors_per_track
                mov     ch,[bx]
                mov     cl,1
                mov     dh,[bx+1]
                mov     dl,current_drive

                ret

Set_format_parameters endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             SET FAT                                   |
; |                                                                       |
; |                   Set the file allocation table                       |
; |                                                                       | 
; |              CY - 1 fatal error                                       |
; |              CY - 0 successful operation                              |
; |                                                                       |
; -------------------------------------------------------------------------

Set_fat         proc near

                push    es

                mov     ax,general_dta_1   ; may need to read two sectors
                mov     es,ax

                mov     current_length,1
                mov     format_marker,0feh

                cmp     format_dos_version,dos_version_20
                jne     read_fat

                mov     current_length,2
                mov     format_marker,0fch

        Read_fat:

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],2
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],2
                mov     byte ptr [si+3],0

                call    fat_dir_disk_io

                jnc     initialize_fat

                jmp     set_fat_return

        Initialize_fat:

                cmp     format_dos_version,dos_version_20
                jne     initialize_dos_x

                cmp     format_number_of_sides,0
                je      dos_2_single_side

                mov     dx,216h
                jmp     format_fat

        Dos_2_single_side:

                mov     dx,212h
                jmp     format_fat

        Initialize_dos_x:

                cmp     format_number_of_sides,0
                je      dos_x_single_sided

                mov     dx,1dch
                jmp     format_fat

        Dos_x_single_sided:

                mov     dx,1d9h

        Format_fat:

                mov     di,0
                mov     cx,dx
                mov     al,00h

                rep     stosb

                mov     ax,0ffffh

                mov     bx,1
                mov     es:[bx],ax

                mov     ah,format_marker
                or      ah,format_number_of_sides
                mov     format_marker,ah

                mov     bx,0
                mov     es:[bx],ah

;
; *** Write fat table to track 0 sector 2 and 3
;

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],3
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],2
                mov     byte ptr [si+3],0
                mov     cx,2

        Write_fat_loop:

                call    fat_dir_disk_io

                jc      set_fat_return

                inc     byte ptr [si+2]

                cmp     format_dos_version,dos_version_20
                jne     end_of_fat_write_loop

                inc     byte ptr [si+2]

        End_of_fat_write_loop:

                loop    write_fat_loop

                clc

        Set_fat_return:

                pop     es

                ret

Set_fat         endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            SET DIRECTORY                              |
; |                                                                       |
; |                         Set the directory                             |
; |                                                                       |
; |          Output:                                                      |
; |                  CY - 0 success                                       |
; |                  CY - 1 failure                                       |
; |                                                                       |
; -------------------------------------------------------------------------

Set_directory  proc     near

               push     es

               mov      es,general_dta_2

                mov     current_length,1

                mov     current_directory_sector,4
                mov     directory_empty_marker,0e5h

                cmp     format_dos_version,dos_version_20
                jne     read_directory

                mov     current_directory_sector,6
                mov     directory_empty_marker,00h


;
; *** Read in sector for directory
;

        Read_directory:

                mov     si,offset disk_io_parameters
                mov     al,current_directory_sector

                mov     byte ptr [si],2
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],al
                mov     byte ptr [si+3],0

                call    fat_dir_disk_io

                jnc     initialize_directory

                jmp     set_dir_return

        Initialize_directory:

                mov     bx,0
                mov     cx,16
                mov     al,directory_empty_marker

        Initialize_directory_loop:

                mov     es:[bx],al
                add     bx,20h

                loop    initialize_directory_loop

;
; *** Set directory from starting directory sector to
; *** starting directory sector + 4, then check if double sided 
;

                mov     si,offset disk_io_parameters
                mov     al,current_directory_sector

                mov     byte ptr [si],3
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],al
                mov     byte ptr [si+3],0

                mov     cx,4

        Write_directory_loop:

                call    fat_dir_disk_io

                jc      set_dir_return

                inc     byte ptr [si+2]

                loop    write_directory_loop

        Check_for_second_side:

                cmp     format_number_of_sides,0
                je      set_dir_return

;
; *** Double sided disk expand directory
;

                cmp     format_dos_version,dos_version_20
                jne     dos_x_second_side

                mov     cx,3

                jmp     dos_2_second_side

        Dos_x_second_side:

                call    fat_dir_disk_io    ; sector 8 side 0

                jc      set_dir_return

                mov     cx,2

         Dos_2_second_side:

                mov     byte ptr [si+2],1
                mov     byte ptr [si+3],1

        Dir_second_side_loop:

                call    fat_dir_disk_io

                jc      set_dir_return

                inc     byte ptr [si+2]

                loop    dir_second_side_loop

                clc

        Set_dir_return:

                pop     es

                ret

Set_directory   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            FAT DIR DISK IO                            |
; |                                                                       |
; |        Input:                                                         |
; |                SI - address of operation string                       |
; |                     [si] - operation                                  |
; |                     [si+1] - track number                             |
; |                     [si+2] - sector number                            |
; |                     [si+3] - head number                              |
; |                                                                       |
; |       Output:                                                         |
; |                CY - 0 Succeful operation                              |
; |                CY - 1 Fatal error                                     |
; |                                                                       |
; -------------------------------------------------------------------------

Fat_dir_disk_io proc    near

                push    cx

                mov     disk_retry,3

        Fat_dir_disk_io_loop:

                mov     ah,[si]
                mov     al,current_length
                mov     ch,[si+1]
                mov     cl,[si+2]
                mov     dh,[si+3]
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     fat_dir_disk_io_return

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     fat_dir_disk_io_loop

                call    disk_failure

                stc

        Fat_dir_disk_io_return:

                pop     cx

                ret

Fat_dir_disk_io endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             VERIFY SIZE                               |
; |                                                                       |
; |         Determines if there is enough space on diskette for word      |
; |         vision                                                        |
; |                                                                       |
; -------------------------------------------------------------------------

Verify_size     proc    near

                mov     ah,0eh
                mov     dl,current_drive
                int     21h

                call    verify_disk_space

                jnc     check_directory_for_space

                jmp     not_enough_space

;
; *** Check to see if there is enough space in directory for 30 files
;

        Check_directory_for_space:

                push    cx                 ; save record/allocation units

                mov     al,1
                mov     si,offset any_file_name
                call    search_first_entry

                mov     cl,0

                jc      file_count_done

        File_count_loop:

                mov     cl,1

                push    cx

                call    search_next_entry

                pop     cx

                jc      file_count_done

                inc     cl
                jmp     file_count_loop

        File_count_done:

                pop     dx

                cmp     dl,1
                jne     double_sided_directory

                cmp     cl,33
                ja      not_enough_space

                jmp     enough_space

        Double_sided_directory:

                cmp     cl,81
                ja      not_enough_space

        Enough_space:

                 clc
                 mov     al,0

                 jmp     verify_size_return

        Not_enough_space:

                clc
                mov      al,1

        Verify_size_return:

                ret

Verify_size     endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         VERIFY AVAILABLE SECTORS                      |
; |                                                                       |
; |    Ouput:                                                             |
; |                                                                       |
; |      Carry set  - if not enough space                                 |
; |      CX - 1 single sided disk                                         |
; |           2 double sided disk                                         |
; |                                                                       |
; -------------------------------------------------------------------------

Verify_disk_space proc  near

               cmp      running_dos_version,dos_version_20
               jne      check_older_dos

               mov      dl,0
               mov      ah,36h
               int      21h

               push     ax

               sub      dx,bx              ; DX - # of clusters free

               cmp      al,1
               jne      two_sectors_per_cluster

               cmp      dx,298
               jb       not_enough_20_disk_space

               clc

               jmp      end_20_size_check

        Two_sectors_per_cluster:

               cmp      dx,149
               jb       not_enough_20_disk_space

               clc

               jmp      end_20_size_check

        Not_enough_20_disk_space:

               stc

        End_20_size_check:

               pop      cx

               jmp      verify_disk_space_return

;
; *** Get File Allocation Table
;

        Check_older_dos:

               push    ds

               mov     ah,1bh
               int     21h

               push    ax                 ; save # record per allocation

               mov     cx,dx
               mov     ax,0

;
; *** Determine number of free allocation units
;

        Fat_free_loop:

               add     bx,3
               mov     dx,[bx]
               and     dx,0fffh
               jnz     sector_used

               inc     ax

        Sector_used:

               dec     cx
               jz      size_check_done

               mov     dx,[bx+1]
               and     dx,0fff0h
               jnz     sector_used_also

               inc     ax

        Sector_used_also:

               loop     fat_free_loop

        Size_check_done:

               pop      cx

               pop      ds

;
; *** AX = number of allocation unit free CL = no of record per allocation unit
;

               cmp      cl,1
               je       one_record_per_unit

               cmp      ax,298
               jb       not_enough_disk_space

               clc

               jmp      verify_disk_space_return

        One_record_per_unit:

               cmp      ax,149
               jb       not_enough_disk_space

               clc

               jmp      verify_disk_space_return

        Not_enough_disk_space:

               stc

        Verify_disk_space_return:

               ret

Verify_disk_space endp

Code_seg        ends

                end
ed
e

  cc

       jp   eiyds_pc_eun

    o_nuhds_pc:

       sc

    eiyds_pc_eun        eVrf_iksaeedCd_e    ed                    cmp     format_dos_version,dos_version_compaq
                jne     dos_11_boot            ; unknown versio