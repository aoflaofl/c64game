; Zero-page memory allocations

SCREEN_PTR     = $fb
COLOR_PTR      = $fd

; AI dispatch vector for run_ai's JMP (AI_VEC). Pinned here rather than left
; in the code segment: a JMP (ptr) where ptr's address ends in $xxFF hits the
; classic 6502 indirect-JMP page-wrap bug, and a code-segment label can drift
; onto that boundary as the binary grows. $02 never will.
AI_VEC         = $02
