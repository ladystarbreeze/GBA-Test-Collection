;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; entrypoint.asm - Entry point.
;------------------------------------------------------------------------------

    include   'inc/memory.inc'
    include   'inc/mmio.inc'
    include   'inc/psr.inc'

;------------------------------------------------------------------------------
; Function list:
;------------------------------------------------------------------------------
; Address  | Function
;------------------------------------------------------------------------------
; 3000000h | MemCpy32()
; 3000020h | MemSet32()
;------------------------------------------------------------------------------
Addr_MemCpy32 = MEM_IRAM + 0x00
Addr_MemSet32 = MEM_IRAM + 0x20

;------------------------------------------------------------------------------
; void EntryPoint()
;------------------------------------------------------------------------------
; Description: Initializes CPU registers and system memory.
;              Copies MemCpy32 and MemSet32 to IWRAM.
;------------------------------------------------------------------------------
; Parameters:
; None.
;------------------------------------------------------------------------------
; Returns:
; No return.
;------------------------------------------------------------------------------
EntryPoint:
    adr       r12, .Pool

    ; initialize IRQ mode stack pointer and SPSR
    msr       cpsr, PSR_MIRQ
    mov       lr, 0
    msr       spsr, lr
    ldr       sp, [r12]

    ; initialize SVC mode stack pointer and SPSR
    msr       cpsr, PSR_MSVC
    mov       lr, 0
    msr       spsr, lr
    ldr       sp, [r12, 4]

    ; initialize SYS mode stack pointer
    msr       cpsr, PSR_MSYS
    ldr       sp, [r12, 8]

    ; initialize WAITCNT
    mov       r0, MEM_MMIO
    ldr       r1, [r12, 0xC]
    str       r1, [r0, REG_WAITCNT]
	
    ; copy MemCpy32() to IWRAM + 00h
    add       r0, r12, 0x10
    ldmia     r0, {r0-r2}
    bl        MemCpy32
	
    ; copy MemSet32() to IWRAM + 20h
    add       r0, r12, 0x1C
    ldmia     r0, {r0-r2}
    bl        MemCpy32
	
    ldr       r11, [r12, 0x28]

    ; clear EWRAM
    add       r0, r12, 0x2C
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11

    ; clear IWRAM
    add       r0, r12, 0x38
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11

    ; clear Palette RAM
    add       r0, r12, 0x44
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11

    ; clear Video RAM
    add       r0, r12, 0x50
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11

    ; clear Object RAM
    add       r0, r12, 0x5C
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11

    ; jump to Main()
    bl        Main

    .Loop:
        b         .Loop

    .Pool:
        ; stack pointers (IRQ, SVC, SYS) [0x00]
        dw        MEM_IRAM + 0x7FA0, MEM_IRAM + 0x7FE0, MEM_IRAM + 0x7F00
        ; WAITCNT [0x0C]
        dw        0x4317
        ; MemCpy32 - copies MemCpy32 to IWRAM + 00h [0x10]
        dw        MEM_IRAM + 0x00, MEM_ROM0 + MemCpy32, Size_MemCpy32 / 4
        ; MemCpy32 - copies MemSet32 to IWRAM + 20h [0x1C]
        dw        MEM_IRAM + 0x20, MEM_ROM0 + MemSet32, Size_MemSet32 / 4
        ; MemSet32 address [0x28]
        dw        Addr_MemSet32
        ; MemSet32 - clear EWRAM [0x2C]
        dw        MEM_ERAM, 0, Size_MEM_ERAM / 4
        ; MemSet32 - clear IWRAM [0x38]
        dw        Addr_MemSet32 + Size_MemSet32, 0, (Size_MEM_IRAM - (Size_MemCpy32 + Size_MemSet32)) / 4
        ; MemSet32 - clear PRAM [0x44]
        dw        MEM_PRAM, 0, Size_MEM_PRAM / 4
        ; MemSet32 - clear VRAM [0x50]
        dw        MEM_VRAM, 0, Size_MEM_VRAM / 4
        ; MemSet32 - clear ORAM [0x5C]
        dw        MEM_ORAM, 0, Size_MEM_ORAM / 4
    
    .Includes:
        include   'lib/memcpy.asm'

End_EntryPoint:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
