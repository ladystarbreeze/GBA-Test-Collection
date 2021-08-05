;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; main.asm - Checks IRQ return addresses.
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

; TODO: use fixed ROM addresses to verify the return addresses.

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
    adr       r12, .Pool

    mov       r4, MEM_MMIO
    mov       r5, MEM_ERAM
    mov       r11, MEM_IRAM
	
    ; initialize print library
    mov       r0, 0
    mvn       r1, r0
    bl        InitPrint

    ; print test strings
    mov       r0, r12
    ldmia     r0, {r0-r2}
    bl        PrintStr
    add       r0, r12, 0xC
    ldmia     r0, {r0-r2}
    bl        PrintStr

    ; copy and install IRQ handler
    add       r0, r12, 0x30
    ldmia     r0, {r0-r2}
    mov       lr, pc
    bx        r11
    add       r0, r11, 0x100
    str       r0, [r4, -4]

    ; enable VBLANK IRQ generation
    mov       r0, DISPSTAT_VBLANK_IRQ
    strh      r0, [r4, REG_DISPSTAT]

    ; acknowledge all IRQs, disable IRQs, enable interrupts
    mvn       r0, 0
    mov       r0, r0, lsl 16
    str       r0, [r4, REG_IE]
    mov       r0, 1
    str       r0, [r4, REG_IME]

    ; run tests

    ; test #1 - ARM state IRQ return address
    bl        VBLANKWait
    ldr       r11, [r12, 0x3C]
    mov       lr, pc
    bx        r11

    ; test #2 - Thumb state IRQ return address
    bl        VBLANKWait
    mov       r1, 0x200
    ldr       r11, [r12, 0x40]
    mov       lr, pc
    bx        r11

    ; print out results
    mov       r7, 0
    
    .Loop:
        ; get return address offset
        ldr       r6, [r5, r7, lsl 2]
        movs      r6, r6   ; if r6 == 0, the return address is correct
        adreq     r0, Str_OK
        adrne     r0, Str_NG
        mov       r1, 13
        mov       r2, 3
        mul       r2, r7
        add       r2, 1
        bl        PrintStr
        movs      r6, r6
        beq       .Check

        ; print out error message
        adr       r0, Str_Error
        mov       r1, 1
        mov       r2, 3
        mul       r2, r7
        add       r2, 2
        bl        PrintStr

        ; get sign of offset
        movs      r6, r6
        negmi     r6, r6
        movmi     r0, '+'
        movpl     r0, '-'
        mov       r1, 18
        mov       r2, 3
        mul       r2, r7
        add       r2, 2
        bl        PrintChar

        ; print offset (255 bytes max)
        mov       r0, r6
        mov       r1, 2
        mov       r2, 19
        mov       r3, 3
        mul       r3, r7
        add       r3, 2
        bl        PrintHex
        
        .Check:
            cmp       r7, 1
            beq       .Return
            add       r7, 1
            b         .Loop

    .Return:
        pop       {r12, pc}

    .Pool:
        ; Test string #1 - ARM state IRQ [0x00]
        dw        MEM_ROM0 + Str_IRQARM, 1, 1
        ; Test string #2 - Thumb state IRQ [0x0C]
        dw        MEM_ROM0 + Str_IRQThumb, 1, 4
        ; Test string #3 - ARM state SWI [0x18] (UNUSED)
        dw        MEM_ROM0 + Str_SWIARM, 1, 7
        ; Test string #4 - Thumb state SWI [0x24] (UNUSED)
        dw        MEM_ROM0 + Str_SWIThumb, 1, 10
        ; MemCpy32 - IRQ handler [0x30]
        dw        MEM_IRAM + 0x100, MEM_ROM0 + IRQHandler, (End_IRQHandler - IRQHandler) / 4
        ; Test #1 - Address [0x3C]
        dw        MEM_ROM0 + Test1
        ; Test #2 - Address [0x40]
        dw        MEM_ROM0 + Test2 + 1

End_Main:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void VBLANKWait()
;------------------------------------------------------------------------------
; Description: Busy waits for the vertical blanking period.
;------------------------------------------------------------------------------
; Parameters:
; None.
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
VBLANKWait:
    .Loop1:
        ; this routine is always called from Main(), which means that r4 is a valid pointer to the MMIO region
        ldrh      r0, [r4, REG_DISPSTAT]
        tst       r0, DISPSTAT_VBLANK
        beq       .Loop1

    .Loop2:
        ldrh      r0, [r4, REG_DISPSTAT]
        tst       r0, DISPSTAT_VBLANK
        bne       .Loop2

    bx        lr

End_VBLANKWait:
;------------------------------------------------------------------------------

; tests ARM state IRQ return address
Test1:
    push      {r6, lr}

    adr       r6, .Pool
    ldr       r6, [r6]
    add       r6, 4

    ; enable VBLANK IRQs
    mov       r0, IE_VBLANK
    str       r0, [r4, REG_IE]

    .Loop:
        ; wait for an interrupt
        b         .Loop
    
    ; write return address offset to EWRAM
    adr       r0, .Pool
    ldr       r0, [r0]
    sub       r0, r6
    str       r0, [r5]

    pop       {r6, pc}

    .Pool:
        ; correct lr_irq return address
        dw        MEM_ROM0 + .Loop + 4

End_Test1:

; tests Thumb state IRQ return address
Test2:
    CODE16
    push      {r6, lr}

    adr       r6, .Pool
    ldr       r6, [r6]
    add       r6, 2

    ; enable VBLANK IRQs
    mov       r0, IE_VBLANK
    str       r0, [r4, r1]

    .Loop:
        ; wait for an interrupt
        b         .Loop
    
    ; switch to ARM state
    adr       r0, .SwitchState
    bx        r0
    align     4

    .SwitchState:

    CODE32
    
    ; write return address offset to EWRAM
    adr       r0, .Pool
    ldr       r0, [r0]
    sub       r0, r6
    str       r0, [r5, 4]

    pop       {r6, pc}

    .Pool:
        ; correct lr_irq return address
        dw        MEM_ROM0 + .Loop + 4

End_Test2:

IRQHandler:
    ; acknowledge and disable VBLANK IRQ
    mov       r0, IE_VBLANK shl 16
    str       r0, [r4, REG_IE]

    ; adjust return address
    add       r0, sp, 0x14
    swp       r6, r6, [r0]

    bx        lr

End_IRQHandler:

; test strings
Str_IRQARM:
    m_STR     "IRQ (ARM)"

Str_IRQThumb:
    m_STR     "IRQ (Thumb)"

Str_SWIARM:
    m_STR     "SWI (ARM)"

Str_SWIThumb:
    m_STR     "SWI (Thumb)"

; result strings
Str_OK:
    m_STR     "- OK!"

Str_NG:
    m_STR     "- NG!"

Str_Error:
    m_STR     "Result is off by    h bytes." ; I hope no one manages to break this.

Includes_Print:
    include   '../../lib/print.asm'

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
