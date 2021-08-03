;------------------------------------------------------------------------------
; GBA Test Collection - GBA test ROMs written in ARM assembly.
; Copyright (C) 2021  Michelle-Marie Schiller
;------------------------------------------------------------------------------
; psr.inc - Useful Program Status Register definitions.
;------------------------------------------------------------------------------

; condition code flags
PSR_V = 1 shl 28
PSR_C = 1 shl 29
PSR_Z = 1 shl 30
PSR_N = 1 shl 31

; control flags
PSR_T = 1 shl 5
PSR_F = 1 shl 6
PSR_I = 1 shl 7

; mode flags
PSR_MUSR = 0x10
PSR_MFIQ = 0x11
PSR_MIRQ = 0x12
PSR_MSVC = 0x13
PSR_MABT = 0x17
PSR_MUND = 0x1B
PSR_MSYS = 0x1F

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
