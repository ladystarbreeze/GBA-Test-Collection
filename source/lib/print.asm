;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; print.asm - Text printing routines.
;------------------------------------------------------------------------------
	
    include   '../inc/memory.inc'
    include   '../inc/mmio.inc'

;------------------------------------------------------------------------------
; void InitPrint(u16 cBg, u16 cText)
;------------------------------------------------------------------------------
; Description:
; Initializes text colors and the display mode.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Background color.
; r1 - Text color.
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
InitPrint:
    ; initialize text colors
    orr       r1, r0, r1, lsl 16
    mov       r0, MEM_PRAM
    str       r1, [r0]

    ; initialize display mode
    mov       r0, MEM_MMIO
    mov       r1, DISPCNT_MODE4
    orr       r1, DISPCNT_BG2_ON
    strh      r1, [r0]

    bx        lr

End_InitPrint:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void PrintStr(const char *pStr, int x, int y)
;------------------------------------------------------------------------------
; Description:
; Prints a string to the screen.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Pointer to string to print.
; r1 - Initial X coordinate (8px steps).
; r2 - Initial Y coordinate (8px steps).
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
PrintStr:
    push      {r4-r6, lr}

    ; save arguments
    mov       r4, r0
    mov       r5, r1
    mov       r6, r2

    .Loop_Print:
        ; get next character
        ldrb      r0, [r4], 1

        ; return if char == 0
        movs      r0, r0
        beq       .Return

        ; set up PrintChar arguments
        mov       r1, r5
        mov       r2, r6

        bl        PrintChar

        add       r5, 1       ; increment X coordinate
        b         .Loop_Print

    .Return:
        pop       {r4-r6, pc}

End_PrintStr:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void PrintHex(u32 x, int n, int x, int y)
;------------------------------------------------------------------------------
; Description:
; Prints n hex digits of number x.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Number to print.
; r1 - Number of digits to print.
; r2 - Initial X coordinate (8px steps).
; r3 - Initial Y coordinate (8px steps).
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
PrintHex:
    push      {r4-r7, lr}

    ; save arguments
    mov       r4, r0
    mov       r5, r1
    mov       r6, r2
    mov       r7, r3

    .Loop_Print:
        sub       r5, 1 ; decrement n
		
        ; get next hex digit and right-shift x by 4
        and       r0, r4, 0xF
        mov       r4, r4, lsr 4
		
        ; get character
        cmp       r0, 9
        addls     r0, 0x30
        addhi     r0, 0x37
		
        ; set up PrintChar arguments
        add       r1, r6, r5
        mov       r2, r7

        bl        PrintChar

        ; return if n == 0
        movs      r5, r5
        bne       .Loop_Print

    pop       {r4-r7, pc}
End_PrintHex:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void PrintChar(char c, int x, int y)
;------------------------------------------------------------------------------
; Description:
; Prints a single character to the screen.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Character to print.
; r1 - X coordinate (8px steps).
; r2 - Y coordinate (8px steps).
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
PrintChar:
    push      {r4-r5, lr}
    
    mov       r4, MEM_VRAM
    sub       r0, 0x20

    ; get pixel offset (x * 4, y * 8)
    mov       r1, r1, lsl 2
    mov       r2, r2, lsl 3

    ; compute VRAM start address (MEM_VRAM + (y * 240) + x)
    mov       r3, 240
    mul       r3, r2, r3
    add       r4, r3
    add       r4, r1

    ; get font offset (Data_Font + (c * 64))
    adr       r3, Data_Font
    add       r0, r3, r0, lsl 6

    mov       r2, 8 ; initialize loop counter

    .Loop_Draw:
        subs      r2, 1

        ; pixel16 = (pixel8L + (pixel8H << 8))
        ldrb      r3, [r0], 1
        ldrb      r5, [r0], 1
        orr       r3, r3, r5, lsl 8
        strh      r3, [r4, r1]
        add       r1, 2

		; pixel16 = (pixel8L + (pixel8H << 8))
        ldrb      r3, [r0], 1
        ldrb      r5, [r0], 1
        orr       r3, r3, r5, lsl 8
        strh      r3, [r4, r1]
        add       r1, 2

        ; pixel16 = (pixel8L + (pixel8H << 8))
        ldrb      r3, [r0], 1
        ldrb      r5, [r0], 1
        orr       r3, r3, r5, lsl 8
        strh      r3, [r4, r1]
        add       r1, 2

        ; pixel16 = (pixel8L + (pixel8H << 8))
        ldrb      r3, [r0], 1
        ldrb      r5, [r0], 1
        orr       r3, r3, r5, lsl 8
        strh      r3, [r4, r1]
        add       r1, 2

        beq       .Return

        add       r4, 240    ; increment VRAM address by 240
        sub       r1, 8      ; decrement loop counter
        b         .Loop_Draw

    .Return:
        pop       {r4-r5, pc}

End_PrintChar:
;------------------------------------------------------------------------------

    include   'font.asm'
    align     4

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
