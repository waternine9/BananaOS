[BITS 16]
section .boot

Boot:
    

    ; NOTE: At boot the boot drive number is stored in DL,
    ;       Preserve it for later 
    mov   [DriveNumber], dl

    ; NOTE: Activate A20
    mov   ax, 0x2403
    int   0x15
    
    ; NOTE: SETUP VBE
    jmp SetupVbe
    %include "kernel/unkernel/vesa_vbe_setup.asm"
SetupVbe:
    call VesaVbeSetup

    ; NOTE: Load GDT and activate protected mode
    cli
    lgdt  [GDTDesc]
    mov   eax, cr0
    or    eax, 1
    mov   cr0, eax
    jmp   8:After

global DriveNumber
DriveNumber: db 0
[BITS 32]

After:
    ; NOTE: Setup segments.
    mov   ax, 16
    mov   ds, ax
    mov   es, ax
    mov   fs, ax
    mov   gs, ax
    mov   ss, ax
    
    mov dl, [DriveNumber]
    mov edi, unkernel_end
    mov ecx, 4
    call unkernel_read_ata

    jmp unkernel_end

MouseWaitData:
    in al, 0x64
    cmp al, 1
    jne MouseWaitData
    ret

GDTStart:
    dq 0 
GDTCode:
    dw 0xFFFF     ; Limit
    dw 0x0000     ; Base
    db 0x00       ; Base
    db 0b10011010 ; Access
    db 0b11001111 ; Flags + Limit
    db 0x00       ; Base
GDTData:
    dw 0xFFFF     ; Limit
    dw 0x0000     ; Base
    db 0x00       ; Base
    db 0b10010010 ; Access
    db 0b11001111 ; Flags + Limit
    db 0x00       ; Base
GDTEnd:

GDTDesc:
    .GDTSize dw GDTEnd - GDTStart ; GDT size 
    .GDTAddr dd GDTStart          ; GDT address

%include "kernel/unkernel/ata/ata.asm"

times 510-($-$$) db 0
dw 0xAA55
  
align 16
%include "kernel/unkernel/vesa_vbe_setup_vars.asm"

times 2048-($-$$) db 0

unkernel_end: