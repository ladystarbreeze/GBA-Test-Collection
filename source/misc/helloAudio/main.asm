;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; main.asm - Simple audio demo.
;------------------------------------------------------------------------------

    format binary as 'gba'

    include   '../../inc/memory.inc'
    include   '../../inc/mmio.inc'
    include   '../../inc/psr.inc'

    include   '../../header.asm'
    include   '../../entrypoint.asm'

; null-terminated string macro
macro m_STR msg
{
    db        msg
    db        0
    align     4
}

; 16-byte aligned audio stream
macro m_AUDIO stream
{
    file      stream
    align     16
}

;------------------------------------------------------------------------------
; void Main()
;------------------------------------------------------------------------------
; Description: Main function.
;------------------------------------------------------------------------------
; Parameters:
; None.
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
Main:
    push      {r12, lr}
    mov       r4, MEM_MMIO
    adr       r12, .Pool
	
    ; initialize print library
    mov       r0, 0
    mvn       r1, r0
    bl        InitPrint
	
    ; print "Hello, Audio." message
    mov       r0, r12
    ldmia     r0, {r0-r2}
    bl        PrintStr

    ; enable sound circuit
    mov       r0, SOUNDCNT_X_ON
    strh      r0, [r4, REG_SOUNDCNT_X]

    ; set panning, reset audio FIFOs
    ldr       r0, [r12, 0xC]
    strh      r0, [r4, REG_SOUNDCNT_H]

    ; write dummy byte to audio FIFOs
    mov       r0, 0
    strb      r0, [r4, REG_FIFOA]
    strb      r0, [r4, REG_FIFOB]

    ; set up DMA1 and DMA2 registers
    add       r0, r12, 0x10
    ldmia     r0, {r0-r3}
    stmia     r0, {r1-r3}
    add       r0, r12, 0x20
    ldmia     r0, {r0-r3}
    stmia     r0, {r1-r3}

    ldr       r5, [r12, 0x30] ; sample counter

    ; enable DMA2 IRQs, clear IF
    mov       r6, IE_DMA2
    orr       r6, r6, lsl 16
    str       r6, [r4, REG_IE]

    ; start Timer 0
    ldr       r0, [r12, 0x34]
    str       r0, [r4, REG_TM0CNT]

    .Loop:
        ; clear IF, call SWI Halt()
        str       r6, [r4, REG_IE]
        swi       0x20000

        ; decrement sample counter
        subs      r5, 1
        bne       .Loop

        ; restart DMA channels, reset sample counter
        mov       r0, 0
        ldr       r1, [r12, 0x1C]
        ldr       r2, [r12, 0x2C]
        str       r0, [r4, REG_DMA1CNT]
        str       r0, [r4, REG_DMA2CNT]
        str       r1, [r4, REG_DMA1CNT]
        str       r2, [r4, REG_DMA2CNT]
        ldr       r5, [r12, 0x30]

        b         .Loop

    pop       {r12, pc}

    .Pool:
        ; PrintStr - Hello World message [0x00]
        dw        MEM_ROM0 + Str_HelloWorld, 1, 1
        ; SOUNDCNT_H [0x0C]
        dw        SOUNDCNT_H_DMAB_RESET + SOUNDCNT_H_DMAB_R + SOUNDCNT_H_DMAA_RESET + SOUNDCNT_H_DMAA_L
        ; DMA1SAD/DAD/CNT [0x10]
        dw        MEM_MMIO + REG_DMA1SAD
        dw        MEM_ROM0 + Data_AudioL, MEM_MMIO + REG_FIFOA
        dh        4, DMACNT_ON + DMACNT_SPECIAL + DMACNT_WORD + DMACNT_REPEAT + DMACNT_DST_FIXED
        ; DMA2SAD/DAD/CNT [0x20]
        dw        MEM_MMIO + REG_DMA2SAD
        dw        MEM_ROM0 + Data_AudioR, MEM_MMIO + REG_FIFOB
        dh        4, DMACNT_ON + DMACNT_IRQ + DMACNT_SPECIAL + DMACNT_WORD + DMACNT_REPEAT + DMACNT_DST_FIXED
        ; audio stream length [0x30]
        dw        (End_Data_AudioL - Data_AudioL) / 16
        ; Timer 0 [0x34]
        dh        0x10000 - 256, TMCNT_ON

End_Main:
;------------------------------------------------------------------------------

Str_HelloWorld:
    m_STR     "Hello, Audio."

Includes_Print:
    include   '../../lib/print.asm'

Data_AudioL:
    m_AUDIO   'audioL.bin'

End_Data_AudioL:

Data_AudioR:
    m_AUDIO   'audioR.bin'

End_Data_AudioR:

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
