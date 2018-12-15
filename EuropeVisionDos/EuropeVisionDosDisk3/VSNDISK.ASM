Name            VSNDISK

Title           Bruce_&_James_Command

Subttl          Vision_Disk

Page 60,132

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume  cs:code_seg

;
; *** External
;

                extrn   disk_failure:near
                extrn   verify_ibm:near
                extrn   verify_work:near
                extrn   ibm_error_prompt:near
                extrn   work_error_prompt:near
                extrn   display_operation:near

                extrn   current_drive:byte
                extrn   disk_retry:byte
                extrn   dos_version:byte
                extrn   current_error:byte
                extrn   format_number_of_sides:byte
                extrn   file_1_fcb:byte
                extrn   file_1_dta:word
                extrn   file_2_fcb:byte
                extrn   file_2_dta:word
                extrn   file_3_fcb:byte
                extrn   file_3_dta:word
                extrn   end_of_3_dta:word
                extrn   search_fcb:byte
                extrn   found_fcb:byte
                extrn   format_dos_version:byte
                extrn   format_marker:byte
                extrn   operation_picture:word
                extrn   general_dta_seg:word

;
; *** Public
;

                public   read_driver
                public   write_driver
                public   search_first_entry
                public   search_next_entry
                public   open_file
                public   close_file
                public   create_file
                public   read_file
                public   write_file
                public   read_boot
                public   write_boot
                public   rename_file

;
; *** Equates
;

Dos_version_10        equ    00h
Dos_version_11        equ    01h
Dos_version_20        equ    02h
Dos_version_compaq    equ    03h

Ss_8                  equ    0ffh
Ds_8                  equ    0feh
Ss_9                  equ    0fch
Ds_9                  equ    0fdh

;
; *** Block read variables
;

File_size_high  dw    0000h
FIle_size_low   dw    0000h

Dos_boot_20_18      db  001h,040h,040h,001h,0feh,001h,008h,001h

Dos_boot_20_28      db  002h,070h,080h,002h,0ffh,001h,008h,002h

Dos_boot_20_19      db  001h,040h,068h,001h,0fch,002h,009h,001h

Dos_boot_20_29      db  002h,070h,0d0h,002h,0fdh,002h,009h,002h

Page

; =========================================================================
; |                                                                       |
; |                           READ DRIVER                                 |
; |                                                                       |
; |    Read in the entire file into memory and set the next dta segmenr   |
; |                                                                       |
; |            Input:                                                     |
; |                   AL - file control block to read                     |
; |                                                                       |
; =========================================================================

Read_driver     proc    near

                push    ds

                cmp     al,1
                jne     read_fcb_2

                mov     bx,offset file_1_fcb
                mov     dx,file_1_dta
                mov     di,offset file_2_dta
                jmp     read_operation

        Read_fcb_2:

                cmp     al,2
                jne     read_fcb_3

                mov     bx,offset file_2_fcb
                mov     dx,file_2_dta
                mov     di,offset file_3_dta
                jmp     read_operation

        Read_fcb_3:

                mov     bx,offset file_3_fcb
                mov     dx,file_3_dta
                mov     di,offset end_of_3_dta

        Read_operation:

                push    di

                mov     ds,dx

                mov     ah,cs:[bx]
                cmp     ah,0ffh
                jne     not_extended_for_read

                add     bx,7

        Not_extended_for_read:

                mov     dx,cs:[bx+16]
                mov     cx,cs:[bx+18]

                mov     file_size_low,dx
                mov     file_size_high,cx

        Read_loop:

               call     calculate_size

                push    ax
                push    dx

                xor     dx,dx

                call    read_file

                cmp     al,02
                je      segment_full_error

                mov     dx,cx
                mov     cl,4
                shr     dx,cl
                inc     dx
                mov     ax,ds
                add     ax,dx
                mov     ds,ax

                pop     dx
                pop     ax

                or      dx,dx
                jnz     read_loop

                pop     di

                mov     cs:[di],ds

                clc

                jmp     read_driver_return

        Segment_full_error:

                pop     dx
                pop     ax
                pop     di

                stc

        Read_driver_return:

                pop     ds

                ret

Read_driver     endp

Page

; =========================================================================
; |                                                                       |
; |                              WRITE DRIVER                             |
; |                                                                       |
; |                 Write an entire file to the diskette                  |
; |                                                                       |
; |          Input:                                                       |
; |                 AL - file control block to write                      |
; |                                                                       |
; =========================================================================

Write_driver    proc    near

                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

                cmp     al,1
                jne     write_fcb_2

                mov     bx,offset file_1_fcb
                mov     dx,file_1_dta
                jmp     write_operation

        Write_fcb_2:

                cmp     al,2
                jne     write_fcb_3

                mov     bx,offset file_2_fcb
                mov     dx,file_2_dta
                jmp     write_operation

        Write_fcb_3:

                mov     bx,offset file_3_fcb
                mov     dx,file_3_dta

        Write_operation:

                mov     ds,dx

                mov     ah,cs:[bx]
                cmp     ah,0ffh
                jne     not_write_ext_file

                add     bx,7

        Not_write_ext_file:

                mov     dx,cs:[bx+16]
                mov     cx,cs:[bx+18]

                mov     file_size_low,dx
                mov     file_size_high,cx

        Write_loop:

                call    calculate_size

                push    ax
                push    dx

                xor     dx,dx

                call    write_file

                or      al,al
                jnz     disk_full_error

                mov     dx,cx
                mov     cl,4
                shr     dx,cl
                inc     dx
                mov     ax,ds
                add     ax,dx
                mov     ds,ax

                pop     dx
                pop     ax

                or      dx,dx
                jnz     write_loop

                mov     cx,0
                call    write_file

                clc

                jmp     write_driver_return

        Disk_full_error:

                pop     dx
                pop     ax

                stc

        Write_driver_return:

                pop     es
                pop     ds

                ret

Write_driver    endp

Page

; =========================================================================
; |                                                                       |
; |                          SEARCH FIRST ENTRY                           |
; |                                                                       |
; |           Used to find the first file on the Word Vision Master       |
; |                                                                       |
; |      Input:                                                           |
; |           AL - 0 convert to upper case AL - 1 leave as is             |
; |           SI - address of file to search for                          |
; |                                                                       |
; =========================================================================

Search_first_entry proc near

                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

                push    ax
                push    si

                mov     ah,1ah
                mov     dx,offset found_fcb
                int     21h

                pop     si
                pop     ax

                mov     bx,offset search_fcb
                mov     dx,bx
                mov     cl,current_drive
                inc     cl
                mov     [bx],cl
                mov     di,bx
                inc     di
                mov     cx,11

                cmp     al,0
                je      search_upper_case_loop

                rep     movsb

                jmp     search_operation

        Search_upper_case_loop:

                mov     al,[si]
                cmp     al,20h
                je      search_ignore_blank

                xor     al,20h

        Search_ignore_blank:

                mov     [di],al

                inc     si
                inc     di

                loop    search_upper_case_loop

        Search_operation:

                mov     ah,11h
                int     21h

                clc
                or      al,al
                jz      search_first_entry_return

                stc

        Search_first_entry_return:

                pop     es
                pop     ds

                ret

Search_first_entry endp

Page

; =========================================================================
; |                                                                       |
; |                          SEARCH NEXT ENTRY                            |
; |                                                                       |
; |      Used to find the rest of the files on the Word Vision Master     |
; |                                                                       |
; |                                                                       |
; =========================================================================

Search_next_entry proc    near

                push    ds

                push    cs
                pop     ds

                mov     ah,1ah
                mov     dx,offset found_fcb
                int     21h

                mov     bx,offset search_fcb
                mov     dx,bx
                mov     al,current_drive
                inc     al
                mov     [bx],al

                mov     ah,12h
                int     21h

                clc
                or      al,al
                jz      search_next_entry_return

                stc

        Search_next_entry_return:

                pop     ds

                ret

Search_next_entry endp

Page

; =========================================================================
; |                                                                       |
; |                            OPEN FILE                                  |
; |                                                                       |
; |          Entry:                                                       |  
; |                 AL - 0 normal fcb  AL - 1 hidden file (6)             |
; |                 DS:SI - address of name  (00,XXXXXXXXEEE)             |
; |                   if SI - 0 then name already loaded                  |
; |                 DL - file number (1-3)                                |
; |                                                                       |
; |          Exit:                                                        |
; |                 AL - 0 file opened                                    |
; |                 AL - ff no room in directory                          |
; |                                                                       |
; =========================================================================

Open_file       proc    near

                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

;
; *** Check what FCB is to be used
;

                cmp     dl,0
                jne     open_1

                mov     di,offset found_fcb
                jmp     set_up_fcb_for_open

        Open_1:

                cmp     dl,1
                jne     open_2

                mov     di,offset file_1_fcb
                jmp     set_up_fcb_for_open

        Open_2:

                cmp     dl,2
                jne     open_3

                mov     di,offset file_2_fcb
                jmp     set_up_fcb_for_open

        Open_3:

                mov     di,offset file_3_fcb

        Set_up_fcb_for_open:

                push    di

;
; *** Check to see if normal or extended file control block
;

                cmp     al,0
                je      open_block

                mov     al,0ffh
                mov     [di],al
                add     di,6
                mov     al,6
                mov     [di],al
                inc     di

;
; *** Check to see if name already loaded
;

        Open_block:

                mov     al,current_drive
                inc     al
                mov     [di],al

                mov     ax,di

                push    ax

                inc     di
;
; *** Check to see if file name is already present
;

                cmp     si,0
                je      open_file_operation

                mov     cx,11

        Open_upper_case_loop:

                mov     al,[si]
                cmp     al,20h
                je      open_ignore_blank

                xor     al,20h

        Open_ignore_blank:

                mov     [di],al

                inc     si
                inc     di

                loop    open_upper_case_loop

;
; *** FCB set open the file
;

        Open_file_operation:

                pop     ax

                pop     dx                 ; dx FCB address

                push    ax

                mov     ah,0fh
                int     21h

                pop     bx                ; file control block

                or      al,al
                jz      set_record_size

;
; *** Fatal open error
;

                stc
                jmp     open_file_return

        Set_record_size:

                mov     ax,01h
                mov     cs:[bx+14],ax
                mov     ax,0
                mov     cs:[bx+32],al
                mov     cs:[bx+33],ax
                mov     cs:[bx+35],ax

                clc

        Open_file_return:

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx

                ret

Open_file       endp

Page

; =========================================================================
; |                                                                       |
; |                            CLOSE FILE                                 |
; |                                                                       |
; |               Closes a selected File Clerk File                       |
; |                                                                       |
; |               Entry:                                                  |
; |                     DL - file number to close                         |
; |                                                                       |
; |               Exit:                                                   |
; |                     FCB for file number is zero filled                |
; |                     AL = 0 successful close                           |
; |                     AL = 1 diskette was changed                       |
; |                                                                       |
; =========================================================================

Close_file      proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

                push     cs
                pop      ds

;
; *** Check what FCB is to be used
;

                cmp     dl,1
                jne     check_2_close

                mov     dx,offset file_1_fcb
                jmp     close_function

        Check_2_close:

                cmp     dl,2
                jne     check_3_close

                mov     dx,offset file_2_fcb
                jmp     close_function

        Check_3_close:

                mov     dx,offset file_3_fcb

        Close_function:

                mov      ah,10h
                int      21h

                or       al,al
                jnz      close_error

                clc
                jmp      close_file_return

        Close_error:

                stc

         Close_file_return:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Close_file      endp

Page

; =========================================================================
; |                                                                       |
; |                          CREATE FILE                                  |
; |                                                                       |
; |          Entry:                                                       |  
; |                 AL - 0 normal fcb  AL - 1 hidden file (6)             |
; |                 DL - file number (1-3)                                |
; |                                                                       |
; |          Exit:                                                        |
; |                 AL - 0 file opened                                    |
; |                 AL - ff no room in directory                          |
; |                 BX - file size low word                               |
; |                 CX - file size high word (size of file that was read) |
; |                                                                       |
; =========================================================================

Create_file     proc    near

                push    dx
                push    si
                push    di

;
; *** Check what FCB is to be used
;

                cmp     dl,1
                jne     create_2_open

                mov     di,offset file_1_fcb
                jmp     set_up_fcb_for_create

        Create_2_open:

                cmp     dl,2
                jne     create_3_open

                mov     di,offset file_2_fcb
                jmp     set_up_fcb_for_create

        Create_3_open:

                mov     di,offset file_3_fcb

        Set_up_fcb_for_create:

                mov     dx,di

                mov     ah,current_drive
                inc     ah

;
; *** Set drive correctly and get file size that was read from disk
;

                cmp     al,0
                je      not_create_extended_fcb

                add     di,7

        Not_create_extended_fcb:

                mov     cs:[di],ah
                mov     bx,cs:[di+16]
                mov     cx,cs:[di+18]

                push    ds

                push    cs
                pop     ds

                mov     ah,16h
                int     21h

                pop     ds

                or      al,al
                jz      set_create_record_size

                stc

                jmp     create_file_return

;
; *** Set record size to 1 for file write operation and set random
; *** record number to zero
;

        Set_create_record_size:

                mov     ax,1
                mov     cs:[di+14],ax
                mov     cs:[di+16],bx
                mov     cs:[di+18],cx
                mov     ax,0
                mov     cs:[di+32],al
                mov     cs:[di+33],ax
                mov     cs:[di+35],ax

                clc

        Create_file_return:

                pop     di
                pop     si
                pop     dx

                ret

Create_file     endp

Page

; ========================================================================
; |                                                                      |
; |                             RENAME FILE                              |
; |                                                                      |
; |                           Renames a file                             |
; |                                                                      |
; |       Input:                                                         |
; |              SI - offset of file to be renamed                       |
; |              DI - offset of files new name                           |
; |                                                                      |
; ========================================================================

Rename_file    proc     near

               push     ds
               push     es

               push     cs
               push     cs

               pop      ds
               pop      es

;
; *** Load file name to be changed
;

               mov      bx,offset file_1_fcb
               mov      al,current_drive
               inc      al
               mov      [bx],al
               inc      bx

               push     di

               mov      cx,11
               mov      di,bx

               rep      movsb

;
; *** Load name to be changed to
;

               pop      si

               mov      cx,11
               add      di,5

               rep      movsb

               mov      dx,offset file_1_fcb

               mov      ah,17h
               int      21h

               or       al,al
               jz       file_name_changed

               stc

               jmp      rename_file_return

        File_name_changed:

               clc

        Rename_file_return:

               pop      es
               pop      ds

               ret

Rename_file    endp

Page

; =========================================================================
; |                                                                       |
; |                            READ FILE                                  |
; |                                                                       |
; |               Performs a random read on selected file                 |
; |                                                                       |
; |               Entry:                                                  |
; |                     AL - file number to read                          |
; |                     CX - record number                                |
; |                     DS:DX - DTA for file                              |
; |                                                                       |
; |               Exit:                                                   |
; |                     AL - 0 transfer was successful                    |
; |                     Al - 1 EOF                                        |
; |                     AL - 2 Not enough room in DTA                     |
; |                     AL - 3 partial record filled out with zero's      |
; |                                                                       |
; =========================================================================

Read_file       proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

                cmp      operation_picture,0000h
                je       begin_read

                mov      bx,operation_picture
                mov      byte ptr cs:[bx],0fh

                call     display_operation

;
; *** Check what FCB is to be used
;

        Begin_read:

                cmp     al,1
                jne     check_2_read

                mov     di,offset file_1_fcb
                jmp     set_read_dta

        Check_2_read:

                cmp     al,2
                jne     check_3_read

                mov     di,offset file_2_fcb
                jmp     set_read_dta

        Check_3_read:

                mov     di,offset file_3_fcb

        Set_read_dta:

                mov      ah,1ah
                int      21h

        Read_record:

                push     cs
                pop      ds

                mov      dx,di
                mov      ah,27h
                int      21h

        Read_return:

                cmp      operation_picture,0000h
                je       read_exit

                mov      bx,operation_picture
                mov      byte ptr cs:[bx],07h

                call     display_operation

        Read_exit:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Read_file       endp

Page

; =========================================================================
; |                                                                       |
; |                           WRITE FILE                                  |
; |                                                                       |
; |               Performs a random block write of file                   |
; |                                                                       |
; |               Entry:                                                  |
; |                     AL - file control block to write                  |
; |                     CX number of record to write                      |
; |                     DS:DX - DTA to use                                |
; |                                                                       |
; |               Exit:                                                   |
; |                     AL - 0 transfer was successful                    |
; |                     Al - 1 Diskette full                              |
; |                     AL - 2 Not enough room in DTA                     |
; |                                                                       |
; =========================================================================

Write_file      proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

                cmp     operation_picture,0000h
                je      begin_write

                mov      bx,operation_picture
                mov      byte ptr cs:[bx],0fh

                call     display_operation

;
; *** Check what FCB is to be used
;

        Begin_write:

                cmp     al,1
                jne     check_2_write

                mov     di,offset file_1_fcb
                jmp     set_write_dta

        Check_2_write:

                cmp     al,2
                jne     check_3_write

                mov     di,offset file_2_fcb
                jmp     set_write_dta

        Check_3_write:

                mov     di,offset file_3_fcb

        Set_write_dta:

                mov      ah,1ah
                int      21h

        Write_record:

                push     cs
                pop      ds

                mov      dx,di
                mov      ah,28h
                int      21h

        Write_return:

                cmp      operation_picture,0000h
                je       write_exit

                mov      bx,operation_picture
                mov      byte ptr cs:[bx],07h

                call     display_operation

        Write_exit:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Write_file      endp

Page

; =========================================================================
; |                                                                       |
; |                           READ BOOT                                   |
; |                                                                       |
; |                      Read Ibm Boot track                              |
; |                                                                       |
; =========================================================================

Read_boot       proc    near

                push    es

                mov     es,general_dta_seg

                mov     disk_retry,3

        Read_boot_loop:

                mov     ax,0201h
                mov     cx,0001h
                mov     dh,0
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     read_boot_return

                dec     disk_retry
                jnz     read_boot_loop

                call    handle_boot_error

                jc      read_boot_return

        Verify_ibm_boot:

                call    verify_ibm

                jnc     read_boot_retry

                call    ibm_error_prompt

                jmp     verify_ibm_boot

        Read_boot_retry:

                mov     disk_retry,3
                jmp     read_boot_loop

        Read_boot_return:

                pop     es

                ret

Read_boot       endp

Page

; =========================================================================
; |                                                                       |
; |                          WRITE BOOT                                   |
; |                                                                       |
; |                     Write Ibm Boot track                              |
; |                                                                       |
; =========================================================================

Write_boot      proc    near

                push    es

                mov     es,general_dta_seg

;
; *** Determine what version of DOS is being written
;

                cmp     format_dos_version,dos_version_10
                je      dos_10_boot

                cmp     format_dos_version,dos_version_11
                je      dos_11_boot

                cmp     format_dos_version,dos_version_20
                je      dos_20_boot

                cmp     format_dos_version,dos_version_compaq
                jne     dos_11_boot            ; unknown version treat as 1.1

                jmp     prepare_to_write_boot  ; compaq dosen't need change

;
; *** Dos 1.0 boot track leave as is (can only be single sided)
;

        Dos_10_boot:

                jmp     prepare_to_write_boot

;
; *** If not 10,11,20, or compaq treat as dos 11 (falls through from above)
; *** Determine is SS or DD
;

        Dos_11_boot:

                mov     bx,3
                cmp     format_number_of_sides,0
                je      dos_11_single_sided_drive

                mov     ax,103h
                mov     es:[bx],ax
                jmp     prepare_to_write_boot

        Dos_11_Single_sided_drive:

                mov     ax,0008h
                mov     es:[bx],ax

                jmp     prepare_to_write_boot

;
; *** Dos 20, determine format to set boot track
; *** Determine if SS/8 DS/8 SS/9 or DS/9
;

        Dos_20_boot:

                mov     si,offset dos_boot_20_18
                cmp     format_marker,ss_8
                je      dos_20_boot_prepare

                mov     si,offset dos_boot_20_28
                cmp     format_marker,ds_8
                je      dos_20_boot_prepare

                mov     si,offset dos_boot_20_19
                cmp     format_marker,ss_9
                je      dos_20_boot_prepare

                mov     si,offset dos_boot_20_29

        Dos_20_boot_prepare:

                xor     di,di

                mov     al,cs:[si]
                mov     es:[di+0dh],al
                mov     al,cs:[si+1]
                mov     es:[di+11h],al
                mov     al,cs:[si+2]
                mov     es:[di+13h],al
                mov     al,cs:[si+3]
                mov     es:[di+14h],al
                mov     al,cs:[si+4]
                mov     es:[di+15h],al
                mov     al,cs:[si+5]
                mov     es:[di+16h],al
                mov     al,cs:[si+6]
                mov     es:[di+18h],al
                mov     al,cs:[si+7]
                mov     es:[di+1ah],al

                jmp     prepare_to_write_boot

;
; *** Compaq has boot track with both single and double sided boot table
;

        Prepare_to_write_boot:

                mov     disk_retry,3

        Write_boot_loop:

                mov     ax,0301h
                mov     cx,0001h
                mov     dh,0
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     write_boot_return

                dec     disk_retry
                jnz     write_boot_loop

                call    handle_boot_error

                jc      write_boot_return

        Boot_work_verify:

                call    verify_work
                jnc     write_boot_retry

                call    work_error_prompt

                jmp     boot_work_verify

        Write_boot_retry:

                mov     disk_retry,3
                jmp     write_boot_loop

        Write_boot_return:

                pop     es

                ret

Write_boot      endp

Page

; =========================================================================
; |                                                                       |
; |                         HANDLE BOOT ERROR                             |
; |                                                                       |
; |      Output:                                                          |
; |             CARRY - 1 fatal error                                     |
; |                                                                       |
; =========================================================================

Handle_boot_error proc  near

                push    ax

                xor     ax,ax
                int     13h

                pop     ax

                cmp     ah,80h
                je      correct_error

                cmp     ah,03h
                je      correct_error

                stc

                jmp     handle_boot_error_return

        Correct_error:

                push    ax

                mov     current_error,ah

                call    disk_failure

                pop     ax

                clc

        Handle_boot_error_return:

               ret

Handle_boot_error endp

Page

; =========================================================================
; |                                                                       |
; |                            CALCULATE SIZE                             |
; |                                                                       |
; |      Input:                                                           |
; |               (File_size_high * 64k + File_size_low) - 0ffffh         |
; |               unless file less than 64k                               |
; |               results stored in file_size_high and file_size_low      |
; |                                                                       |
; |      Output:                                                          |
; |               If file size > 64k then DX = 1 and CX = 0ffffh          |
; |               Else DX = 0 and CX = size of file                       |
; |                                                                       |
; =========================================================================

Calculate_size proc     near

               push     bx

               mov      cx,file_size_high
               mov      bx,file_size_low

               or       cx,cx
               jz       less_than_64k

               sbb      bx,0ffffh
               jnc      no_carry_necessary

               dec      cx

        No_carry_necessary:

               mov      file_size_high,cx
               mov      file_size_low,bx

               mov      dx,1
               mov      cx,0ffffh

               jmp      calculate_size_return

        Less_than_64k:

               mov      cx,bx
               mov      dx,0

        Calculate_size_return:

               pop      bx

               ret

Calculate_size endp

Code_seg        ends

                end   o   d,    Cluaesz_eun        o   b        eCluaesz np

oesg    ns

   