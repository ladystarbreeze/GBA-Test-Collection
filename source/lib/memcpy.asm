;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; memcpy.asm - Memory copy and set routines.
;------------------------------------------------------------------------------

Size_MemCpy32 = End_MemCpy32 - MemCpy32 ; size of MemCpy32 (in Bytes)
Size_MemSet32 = End_MemSet32 - MemSet32 ; size of MemSet32 (in Bytes)

;------------------------------------------------------------------------------
; void MemCpy32(u32 *pDst, u32 *pSrc, u32 nWords)
;------------------------------------------------------------------------------
; Description: 32-bit memory copy operation.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Destination pointer. (has to be aligned to a word boundary)
; r1 - Source pointer. (has to be aligned to a word boundary)
; r2 - Number of 32-bit words to copy.
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
MemCpy32:
    ; return if nWords == 0
    movs      r2, r2
    bxeq      lr

    ; pEnd = pDst + nWords * 4
    add       r3, r0, r2, lsl 2

    .Loop:
        ; *pDst++ = *pSrc++
        ldr       r2, [r1], 4
        str       r2, [r0], 4

        ; if (pDst != pEnd) goto .Loop_MemCpy32
        cmp       r0, r3
        bne       .Loop

    bx        lr

End_MemCpy32:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; void MemSet32(u32 *pDst, u32 data, u32 nWords)
;------------------------------------------------------------------------------
; Description: 32-bit memory set operation.
;------------------------------------------------------------------------------
; Parameters:
; r0 - Destination pointer. (has to be aligned to a word boundary)
; r1 - Memory set data.
; r2 - Number of 32-bit words to set.
;------------------------------------------------------------------------------
; Returns:
; Nothing.
;------------------------------------------------------------------------------
MemSet32:
    ; return if nWords == 0
    movs      r2, r2
    bxeq      lr

    ; pEnd = pDst + nWords * 4
    add       r3, r0, r2, lsl 2

    .Loop:
        ; *pDst = data
        str       r1, [r0], 4

        ; if (pDst != pEnd) goto .Loop_MemCpy32
        cmp       r0, r3
        bne       .Loop

    bx        lr

End_MemSet32:
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
