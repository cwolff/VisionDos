Name            VSNTNSFR

Title           Bruce_&_James_Command

Subttl          Vision_Transfer

Page 60,132

; *************************************************************************
; *                                                                       *
; *        (C)opyright 1983 Bruce & James Program Publishers Inc.         *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume  cs:code_seg

;
; *** External procedures
;

                extrn  clear_monitor:near
                extrn  disk_failure:near
                extrn  search_first_entry:near
                extrn  search_next_entry:near
                extrn  open_file:near
                extrn  read_driver:near
                extrn  create_file:near
                extrn  write_driver:near
                extrn  close_file:near
                extrn  read_boot:near
                extrn  write_boot:near
                extrn  master_failure:near
                extrn  work_failure:near
                extrn  master_prompt:near
                extrn  master_error_prompt:near
                extrn  ibm_prompt:near
                extrn  ibm_error_prompt:near
                extrn  work_prompt:near
                extrn  work_error_prompt:near
                extrn  verify_work:near
                extrn  verify_master:near
                extrn  verify_ibm:near
                extrn  display_error:near
                extrn  display_operation:near

                extrn  number_of_drives:byte
                extrn  destination_drive:byte
                extrn  source_drive:byte
                extrn  current_drive:byte
                extrn  current_disk:byte
                extrn  general_dta_seg:word
                extrn  ibm_bio_name:byte
                extrn  ibm_dos_name:byte
                extrn  xxx_bio_name:byte
                extrn  xxx_dos_name:byte
                extrn  command_name:byte
                extrn  load_indicator:word
                extrn  sectors_per_track:byte
                extrn  format_sectors_per_track:byte
                extrn  dos_version:byte
                extrn  end_of_memory:word
                extrn  operation_message:word
                extrn  operation_picture:word

;
; *** Public
;

                public   read_ibm_files
                public   write_ibm_files
                public   transfer_master_files
                public   check_memory_size

                public   current_memory_position
                public   search_fcb
                public   create_fcb
                public   file_1_dta
                public   file_1_fcb
                public   file_2_dta
                public   file_2_fcb
                public   file_3_dta
                public   file_3_fcb
                public   end_of_3_dta
                public   file_control_block
                public   any_file_name
                public   found_fcb

;
; *** Equates
;

Loaded_by_setup         equ   0fffeh

Dos_version_compaq      equ   03h

Page

;
; *** file transfer variaables
;

Current_memory_position      dw     0000h

Search_fcb                   db     44 dup (00)

Found_fcb                    db     44 dup (00)

Create_fcb                   db     44 dup (00)

File_1_dta                   dw     0000h

File_1_fcb                   db     44 dup (00)

File_2_dta                   dw     0000h

File_2_fcb                   db     44 dup (00)

File_3_dta                   dw     0000h

File_3_fcb                   db     44 dup (00)

End_of_3_dta                 dw     0000h

File_control_block           db     44 dup (00)

Any_file_name                db     11 dup ('?')

;
; *** Operation messages
;

Reading_message      db  02
                     db  28,'Now Reading Wordvision files'
                     db  17,'from Master copy.'

Reading_1_picture    db  07
                     db  1,25
                     db  10,192,26,26,'READING'

Reading_2_picture    db  07
                     db  11,'          ',25
                     db  11,' READING',27,27,217

Writing_message      db  02
                     db  28,'Now WRITING Wordvision files'
                     db  16,'to Working copy.'

Writing_picture      db  07
                     db  1,24
                     db  10,192,27,27,'WRITING'

;
; *** Ibm read error messages
;

Bad_version_message db 48,' SORRY: DOS 1.1 is unable to read DOS 2.0 disk. '

Ibm_open_error_message db 45,' SORRY: Unable to find PC-DOS files on disk. '

Ibm_read_error_message db 47,' SORRY: Unable to read PC-DOS files from disk. '

;
; *** Master read errors
;

Master_open_error_message  db  34,' SORRY: Wordvision file not found. '

Master_read_error_message   db  40,' SORRY: Unable to read Wordvision file. '

File_to_large_message  db  45,' SORRY: Wordvision file to large to tansfer. '

;
; *** Working write errors
;

Working_create_error_message  db  40,' SORRY: Working disk directory is full. '

Working_write_error_message   db  30,' SORRY: Working disk is full. '

Working_close_error_message   db  38,' SORRY: This is not the working disk. '

Page

; =========================================================================
; |                                                                       |
; |                             READ IBM FILES                            |
; |                                                                       |
; |                Read ibmbio.com ibmdos.com command.com                 |
; |                                                                       |
; =========================================================================

Read_ibm_files  proc    near

                push    ds
                push    es

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,1

                mov     dx,general_dta_seg
                add     dx,20h
                mov     file_1_dta,dx

;
; *** If called by setup than can not assume DOS disk in drive
;

                cmp     load_indicator,loaded_by_setup
                je      read_ibm_files_prompt

                cmp     number_of_drives,2
                je      read_ibm_file_verify

        Read_ibm_files_prompt:

                call    ibm_prompt

                jmp     read_ibm_file_verify

        Read_ibm_files_error_prompt:

                call    ibm_error_prompt

        Read_ibm_file_verify:

                call    verify_ibm

                jc      read_ibm_files_error_prompt

                cmp     al,0

                je      read_ibm_boot

                mov     cx,offset bad_version_message

                call    display_error

                jmp     read_ibm_files_error_prompt

;
; *** Process boot
;

        Read_ibm_boot:

                call    read_boot

                jc      fatal_ibm_read_error

;
; *** Process IBMBIO.COM
;

                mov     si,offset xxx_bio_name

                cmp     dos_version,dos_version_compaq
                jae     load_xxx_bio

                mov     si,offset ibm_bio_name

        Load_xxx_bio:

                mov     al,1
                mov     dl,1
                call    open_file

                jc      fatal_ibm_open_error

                mov     al,1
                call    read_driver

                jc      fatal_ibm_read_error

;
; *** Process IBMDOS.COM
;

                mov     si,offset xxx_dos_name

                cmp     dos_version,dos_version_compaq
                jae     load_xxx_dos

                mov     si,offset ibm_dos_name

        Load_xxx_dos:

                mov     al,1
                mov     dl,2
                call    open_file

                jc      fatal_ibm_open_error

                mov     al,2
                call    read_driver

                jc      fatal_ibm_read_error

;
; *** Process COMMAND.COM
;

                mov     al,0
                mov     dl,3
                mov     si,offset command_name
                call    open_file

                jc      fatal_ibm_open_error

                mov     al,3
                call    read_driver

                jc      fatal_ibm_read_error

                jmp     read_ibm_files_return

        Fatal_ibm_open_error:

                mov     cx,offset ibm_open_error_message
                jmp     display_ibm_read_error

        Fatal_ibm_read_error:

                mov     cx,offset ibm_read_error_message

        Display_ibm_read_error:

                call    display_error

                jmp     read_ibm_files_prompt

        Read_ibm_files_return:

                pop     es
                pop     ds

                ret

Read_ibm_files  endp

Page

; ========================================================================
; |                                                                      |
; |                          WRITE IBM FILES                             |
; |                                                                      |
; |                Write ibmbio.com ibm.com command.com                  |
; |                                                                      |
; ========================================================================

Write_ibm_files proc    near

                push    ds
                push    es

                mov     al,format_sectors_per_track
                mov     sectors_per_track,al

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,2

                jmp     verify_working_disk

        Verify_working_error_prompt:

                call    work_error_prompt

        Verify_working_disk:

                call    verify_work

                jc      verify_working_error_prompt

;
; *** Process boot track
;

                call     write_boot

                jnc      write_com_files

                jmp      fatal_ibm_write_error

;
; *** Process IBMBIO.COM
;

        Write_com_files:

                mov     al,1
                mov     dl,1
                call    create_file

                jc      fatal_ibm_create_error

                mov     al,1
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,1
                call    close_file

                jc      fatal_ibm_close_error

;
; *** Process IBMDOS.COM
;

                mov     al,1
                mov     dl,2
                call    create_file

                jc      fatal_ibm_create_error

                mov     al,2
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,2
                call    close_file

                jc      fatal_ibm_close_error

;
; *** Process COMMAND.COM
;

                mov     al,0
                mov     dl,3
                call    create_file

                jc      fatal_ibm_create_error

                mov     al,3
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,3
                call    close_file

                jc      fatal_ibm_close_error

                clc
                jmp     write_ibm_files_return

        Fatal_ibm_create_error:

                mov     cx,offset working_create_error_message
                jmp     display_ibm_write_error

        Fatal_ibm_write_error:

                mov     cx,offset working_write_error_message
                jmp     display_ibm_write_error

        Fatal_ibm_close_error:

                mov     cx,offset working_close_error_message

        Display_ibm_write_error:

                call    display_error

                stc

        Write_ibm_files_return:

                pop     es
                pop     ds
 
                ret

Write_ibm_files endp

Page

; =========================================================================
; |                                                                       |
; |                         TRANSFER MASTER FILES                         |
; |                                                                       |
; |                Transfer files form Master to working copy             |
; |                                                                       |
; =========================================================================

Transfer_master_files proc  near

                mov     dx,general_dta_seg
                add     dx,20h
                mov     file_1_dta,dx

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,0

                call    master_prompt

                jmp     transfer_master_verify

        Master_read_error_prompt:

                call    master_error_prompt

        Transfer_master_verify:

                call    verify_master

                jc      master_read_error_prompt

                mov     al,1
                mov     si,offset any_file_name
                call    search_first_entry

                jnc     open_first_file

                jmp     fatal_master_transfer_error

        Open_first_file:

                mov     al,0
                mov     dl,0
                mov     si,0
                call    open_file

                jnc     first_file_opened

                jmp     fatal_master_transfer_error

      First_file_opened:

                mov     ax,0100h      ; begin first search

;
; *** Load up file control blocks to read
;

        Transfer_file_loop:

                call    load_fcb

                jnc     successful_load

                jmp     fatal_master_transfer_error

        Successful_load:

                cmp     al,0
                jne     more_to_transfer

                jmp     transfer_return

        More_to_transfer:

                push    ax

                call    read_master

                pop     ax

                jnc     more_to_write

                jmp     fatal_master_transfer_error

;
; *** Determine if working prompt necessary
;

        More_to_write:

                push    ax

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,2

                cmp     number_of_drives,2
                je      transfer_work_verify

                call    work_prompt

                jmp     transfer_work_verify

        Work_write_error_prompt:

                call    work_error_prompt

        Transfer_work_verify:

                call    verify_work

                jc      work_write_error_prompt

                pop     ax
                push    ax

                call    write_working

                pop     ax

                jnc     successful_write_operation

                jmp     fatal_working_transfer_error

;
; *** Determine if master prompt required
;

        Successful_write_operation:

                push    ax

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,0

                cmp     number_of_drives,2
                je      transfer_master_verify_1

                call    master_prompt

                jmp     transfer_master_verify_1

        Master_read_error_prompt_1:

                call    master_error_prompt

        Transfer_master_verify_1:

                call    verify_master

                jc      master_read_error_prompt_1

;
; *** On 1 drive system dos becomes confused open file to clear things up
;

                mov     al,0
                mov     dl,1
                mov     si,0
                call    open_file

                pop     ax

                jmp     transfer_file_loop

        Fatal_master_transfer_error:

                call    master_failure

        Fatal_working_transfer_error:

                call    work_failure

        Transfer_return:

                ret

Transfer_master_files endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           READ MASTER                                 |
; |                                                                       |
; |              AL - number of files to read                             |
; |                                                                       |
; -------------------------------------------------------------------------

Read_master     proc    near

                push    ax

                mov     ax,offset reading_message
                mov     operation_message,ax

                cmp     number_of_drives,1
                je      on_drive_read

                mov     ax,offset reading_2_picture

                jmp     begin_read_master

        On_drive_read:

                mov     ax,offset reading_1_picture

        Begin_read_master:

                mov     operation_picture,ax

                pop     ax

                mov     sectors_per_track,08h

;
; *** Process first file
;

                cmp     al,1
                jae     read_first_file

                clc
                jmp     read_master_return

        Read_first_file:

                push    ax

                mov     al,1
                call    read_driver

                pop     ax

                jc      fatal_master_read_error

;
; *** Process second file
;

                cmp     al,2
                jae     read_second_file

                clc
                jmp     read_master_return

        Read_second_file:

                push    ax

                mov     al,2
                call    read_driver

                pop     ax

                jc      fatal_master_read_error

;
; *** Process third file
;

                cmp     al,3
                jae     read_3_file

                clc
                jmp     read_master_return

        Read_3_file:

                mov     al,3
                call    read_driver

                jc      fatal_master_read_error

                jmp     read_master_return

        Fatal_master_read_error:

                mov     cx,offset master_read_error_message

                call    display_error

                stc

        Read_master_return:

                mov     operation_message,0000h
                mov     operation_picture,0000h

                ret

Read_master     endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          WRITE WORKING                                |
; |                                                                       |
; |            AL - number of files to write                              |
; |                                                                       |
; -------------------------------------------------------------------------

Write_working   proc   near

                mov    bl,format_sectors_per_track
                mov    sectors_per_track,bl

                push   ax

                mov    ax,offset writing_message
                mov    operation_message,ax
                mov    ax,offset writing_picture
                mov    operation_picture,ax

                pop    ax

;
; *** Process first file
;

                cmp     al,1
                jae     write_1_file

                clc
                jmp     write_working_return

        Write_1_file:

                push    ax

                mov     al,0
                mov     dl,1
                call    create_file

                pop     ax

                jc      fatal_working_create_error

                push    ax

                mov     al,1
                call    write_driver

                pop     ax

                jc      fatal_working_write_error

                push    ax

                mov     dl,1
                call    close_file

                pop     ax

                jc      fatal_working_close_error

;
; *** Process second file
;

                cmp     al,2
                jae     write_2_file

                clc
                jmp     write_working_return

        Write_2_file:

                push    ax

                mov     al,0
                mov     dl,2
                call    create_file

                pop     ax

                jc      fatal_working_create_error

                push    ax

                mov     al,2
                call    write_driver

                pop     ax

                jc      fatal_working_write_error

                push    ax

                mov     dl,2
                call    close_file

                pop     ax

                jc      fatal_working_close_error

;
; *** Process third file
;

                cmp     al,3
                jae     write_3_file

                clc
                jmp     write_working_return

        Write_3_file:

                mov     al,0
                mov     dl,3
                call    create_file

                jc      fatal_working_create_error

                mov     al,3
                call    write_driver

                jc      fatal_working_write_error

                mov     dl,3
                call    close_file

                jc      fatal_working_close_error

                clc

                jmp     write_working_return

        Fatal_working_create_error:

                mov     cx,offset working_create_error_message
                jmp     display_fatal_working_error

        Fatal_working_write_error:

                mov     cx,offset working_write_error_message
                jmp     display_fatal_working_error

        Fatal_working_close_error:

                mov     cx,offset working_close_error_message

        Display_fatal_working_error:

                call    display_error

                stc

        Write_working_return:

                mov     operation_message,0000h
                mov     operation_picture,0000h

                ret

Write_working   endp

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       LOAD FILE CONTROL BLOCK                        |
; |                                                                      |
; ------------------------------------------------------------------------

Load_fcb        proc    near

                cmp     ah,1            ; determine if file is found
                jne     querry_first_file

                cld

                mov     cx,44
                mov     si,offset found_fcb
                mov     di,offset file_1_fcb

                rep     movsb

                jmp     file_already_to_go

;
; *** Process first file
;

        Querry_first_file:

                call    search_next_entry

                jnc     open_first_file_for_load

                mov     ax,0
                clc
                jmp     load_fcb_return

        Open_first_file_for_load:

                mov     al,0
                mov     dl,0
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

        File_already_to_go:

                mov     bx,file_1_dta
                mov     current_memory_position,bx

                mov     al,1
                call    check_memory_size

                jnc     querry_second_file

                mov     cx,offset file_to_large_message
                call    display_error

                mov     ax,0100h
                stc
                jmp     load_fcb_return

;
; *** Process second file
;

        Querry_second_file:

                call    search_next_entry

                jnc     open_second_file

                mov     ax,1
                clc
                jmp     load_fcb_return

        Open_second_file:

                mov     al,0
                mov     dl,0
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

                mov     al,2
                call    check_memory_size

                jnc     querry_third_file

                mov     ax,0101h
                clc
                jmp     load_fcb_return

;
; *** Process third file
;

        Querry_third_file:

                call    search_next_entry

                jnc     open_third_file

                mov     ax,2
                clc
                jmp     load_fcb_return

        Open_third_file:

                mov     al,0
                mov     dl,0
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

                mov     al,3
                call    check_memory_size

                jnc     all_fcb_loaded

                mov     ax,0102h
                clc     
                jmp     load_fcb_return

        All_fcb_loaded:

                mov     ax,0003h
                clc
                jmp     load_fcb_return

        Fatal_master_open_error:

                mov     cx,offset master_open_error_message
                call    display_error

                stc

        Load_fcb_return:

                ret

Load_fcb        endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         CHECK MEMORY SIZE                             |
; |                                                                       |
; |        Decide if the next file can fit into memory                    |
; |                                                                       |
; |        Input:                                                         |
; |                                                                       |
; |           AL - file control block to check                            |
; |                                                                       |
; -------------------------------------------------------------------------

Check_memory_size proc  near

                push    ax

                mov     bx,offset found_fcb

                mov     al,cs:[bx]
                cmp     al,0ffh
                jne     check_not_ext_fcb

                add     bx,7

        Check_not_ext_fcb:

                mov     ax,cs:[bx+16]
                mov     dx,cs:[bx+18]

                mov     cl,4
                shr     ax,cl
                and     ax,0fffh

                mov     cl,12
                shl     dx,cl
                and     dx,0f000h

                or      dx,ax
                inc     dx

                mov     ax,end_of_memory
                mov     cx,current_memory_position
                sub     ax,cx

                cmp     ax,dx             ; Is memory available > file size

                pop     ax

                ja      memory_available

                stc

                jmp     check_memory_size_return

        Memory_available:

                cmp     al,1
                jne     file_2_size

                mov     di,offset file_1_fcb
                jmp     transfer_fcb

        File_2_size:

                cmp     al,2
                jne     file_3_size

                mov     di,offset file_2_fcb
                jmp     transfer_fcb

        File_3_size:

                mov     di,offset file_3_fcb

        Transfer_fcb:

                add     cx,dx
                mov     current_memory_position,cx

                cld

                mov     cx,44
                mov     si,offset found_fcb

                rep     movsb

                clc

        Check_memory_size_return:

                ret

Check_memory_size endp

Code_seg        ends

                end
      ed    e  e  4
        o   iofe on_c          rp  mvb

        l      Cekmmr_iertr:

        e  Cekmmr_ieed  Cd_e    ed                                                                                                              