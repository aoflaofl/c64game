; --- Occupancy grid: which enemy (if any) stands on each cell.
;
; One byte per cell, holding enemy slot + 1 (0 = empty). Enemies only -- the
; player is a single known cell and shots are few. Enemies are never allowed
; to share a cell (step_cell blocks the move, spawn_random_entity rerolls), so
; one byte per cell is always enough.
;
; The grid has a 1-cell zero border on every side so a 3x3 neighborhood scan
; around any playfield cell never needs an edge check: columns -1..40 (stride
; 42, so grid column = x + 1) and rows 0..25 (playfield is rows 1..24; row 0
; is the HUD and row 25 is below the screen, both always empty).
;
; Maintained from exactly four places, since these are the only writers of an
; enemy's position/liveness: spawn_entity (grid_set), step_cell
; (grid_clear + grid_set), hit_enemy (grid_clear) and init_entities
; (grid_init). Lives in RAM outside the program image, so it costs no PRG size. ---

GRID        = $c000
GRID_STRIDE = 42
GRID_ROWS   = 26

grid_row_lo:
!for gi, 0, GRID_ROWS - 1 {
    !byte <(GRID + gi * GRID_STRIDE)
}
grid_row_hi:
!for gi, 0, GRID_ROWS - 1 {
    !byte >(GRID + gi * GRID_STRIDE)
}

; Empty every cell. Clears 5 whole pages ($c000-$c4ff), which covers the
; 1092-byte grid. Clobbers A, X.
grid_init:
    lda #0
    tax
.gi_loop:
    sta GRID,x
    sta GRID + $100,x
    sta GRID + $200,x
    sta GRID + $300,x
    sta GRID + $400,x
    inx
    bne .gi_loop
    rts

; Point GRID_PTR at enemy X's grid row and return Y = its grid column, so
; (GRID_PTR),Y is its cell. Enter with X = enemy slot. Preserves X.
; Clobbers A, Y.
grid_point:
    ldy ent_y,x
    lda grid_row_lo,y
    sta GRID_PTR
    lda grid_row_hi,y
    sta GRID_PTR + 1
    ldy ent_x,x
    iny
    rts

; Mark enemy X's current cell as occupied by it. Enter with X = enemy slot.
; Preserves X. Clobbers A, Y.
grid_set:
    jsr grid_point
    txa
    clc
    adc #1
    sta (GRID_PTR),y
    rts

; Mark enemy X's current cell as empty. Call it before the enemy's position
; changes or it despawns. Enter with X = enemy slot. Preserves X.
; Clobbers A, Y.
grid_clear:
    jsr grid_point
    lda #0
    sta (GRID_PTR),y
    rts

; Is the cell at (sp_x, sp_y) -- spawn_random_entity's candidate position --
; already occupied? Returns A = the occupant's slot + 1 (0 = free), with Z set
; when free. Clobbers A, Y.
grid_occupied_at_sp:
    ldy sp_y
    lda grid_row_lo,y
    sta GRID_PTR
    lda grid_row_hi,y
    sta GRID_PTR + 1
    ldy sp_x
    iny
    lda (GRID_PTR),y
    rts

; grid_find_near parameters.
gf_x: !byte 0
gf_y: !byte 0
gfn_col0: !byte 0

; Row/column offsets for the nine cells of a 3x3 box, in lockstep -- this
; mirrors collision.asm's SHOT_HIT_RADIUS = 1 (a shot's forgiving hitbox),
; just as a spatial-index lookup instead of a scan over every enemy.
gf_dy9: !byte $ff,$ff,$ff,   0,  0,  0,   1,  1,  1
gf_dx9: !byte $ff,  0,  1, $ff,  0,  1, $ff,  0,  1

; Search the 3x3 box centered on (gf_x, gf_y) for an occupied cell. Returns,
; on a hit, A = occupant's enemy slot (0-based) with carry set; with carry
; clear if the whole box is empty (A undefined). Any occupant in the box is
; an equally valid result -- there's no nearest-first ordering.
; Clobbers A, X, Y.
grid_find_near:
    lda gf_x
    clc
    adc #1
    sta gfn_col0             ; center column, border-offset
    ldx #0
.gfn_loop:
    lda gf_y
    clc
    adc gf_dy9,x
    tay
    lda grid_row_lo,y
    sta GRID_PTR
    lda grid_row_hi,y
    sta GRID_PTR + 1
    lda gfn_col0
    clc
    adc gf_dx9,x
    tay
    lda (GRID_PTR),y
    beq .gfn_next
    sec
    sbc #1                   ; A = occupant slot (0-based); C stays set
    rts
.gfn_next:
    inx
    cpx #9
    bne .gfn_loop
    clc                      ; empty box
    rts
