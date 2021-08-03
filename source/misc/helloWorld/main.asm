;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; main.asm - Hello World.
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
    adr       r12, .Pool_Main
	
    ; initialize print library
    mov       r0, 0
    mvn       r1, r0
    bl        InitPrint
	
    ; print "Hello, World." message
    mov       r0, r12
    ldmia     r0, {r0-r2}
    bl        PrintStr

    pop       {r12, pc}

    .Pool_Main:
        ; PrintStr - Hello World message [0x00]
        dw        MEM_ROM0 + Str_HelloWorld, 1, 1

End_Main:
;------------------------------------------------------------------------------

Str_HelloWorld:
    m_STR     "Hello, World."

Includes_Print:
    include   '../../lib/print.asm'

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
