MAX_ENT = 32

ent_active:  !fill MAX_ENT, 0     ; 0 = free slot
ent_type:    !fill MAX_ENT, 0     ; index into type tables
ent_x:       !fill MAX_ENT, 0     ; cell column 0..39
ent_y:       !fill MAX_ENT, 0     ; cell row 0..24
ent_moveacc: !fill MAX_ENT, 0     ; step accumulator: += ent_speed each frame, step one cell on carry
ent_speed:   !fill MAX_ENT, 0     ; movement rate; cells/frame = n/256 (seeded from typ_speed)
ent_px:      !fill MAX_ENT, 0     ; previous drawn cell, for erase
ent_py:      !fill MAX_ENT, 0
ent_dx:      !fill MAX_ENT, 0     ; heading, signed: $ff / $00 / $01
ent_dy:      !fill MAX_ENT, 0
ent_state:   !fill MAX_ENT, 0     ; per-AI state-machine state
ent_timer:   !fill MAX_ENT, 0     ; generic countdown (reaction delay, cooldown)
ent_hp:      !fill MAX_ENT, 0

; spawn_entity parameters
sp_type:     !byte 0
sp_x:        !byte 0
sp_y:        !byte 0

; Zero every slot. Safe to call again to restart the game.
init_entities:
    lda #0
    ldx #MAX_ENT - 1
.ie_loop:
    sta ent_active,x
    dex
    bpl .ie_loop
    rts

; Spawn one entity described by sp_type / sp_x / sp_y.
; Does nothing if the pool is full. Clobbers A, X, Y.
spawn_entity:
    ldx #0
.se_find:
    lda ent_active,x
    beq .se_found
    inx
    cpx #MAX_ENT
    bne .se_find
    rts                     ; pool full
.se_found:
    lda #1
    sta ent_active,x
    lda sp_type
    sta ent_type,x
    lda sp_x
    sta ent_x,x
    sta ent_px,x
    lda sp_y
    sta ent_y,x
    sta ent_py,x
    lda #0
    sta ent_moveacc,x
    sta ent_state,x
    sta ent_dy,x
    lda #1
    sta ent_dx,x            ; start heading right
    lda RANDOM              ; stagger decision frames so the herd desyncs
    and #$0f
    sta ent_timer,x
    ldy sp_type
    lda typ_hp,y
    sta ent_hp,x
    lda typ_speed,y
    sta ent_speed,x
    jsr draw_entity
    rts

; Opening wave: 20 grunts (type 0) scattered across the play area.
spawn_wave:
    ldx #20
.sw_loop:
    txa
    pha
    lda #0
    sta sp_type
    lda RANDOM
    and #$1f
    clc
    adc #4
    sta sp_x                ; column 4..35
    lda RANDOM
    and #$0f
    clc
    adc #4
    sta sp_y                ; row 4..19
    jsr spawn_entity
    pla
    tax
    dex
    bne .sw_loop
    rts

; Draw entity X at its current cell. Preserves X. Clobbers A, Y.
draw_entity:
    lda ent_y,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy ent_type,x
    lda typ_color,y
    pha
    lda typ_char,y
    ldy ent_x,x
    sta (SCREEN_PTR),y
    pla
    sta (COLOR_PTR),y
    rts

; Blank the cell entity X was last drawn at. Preserves X. Clobbers A, Y.
erase_prev:
    lda ent_py,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy ent_px,x
    lda #BLANK_CHAR
    sta (SCREEN_PTR),y
    rts

; Redraw every entity whose cell changed since the last render.
render_entities:
    ldx #0
.re_loop:
    lda ent_active,x
    beq .re_next
    lda ent_x,x
    cmp ent_px,x
    bne .re_moved
    lda ent_y,x
    cmp ent_py,x
    beq .re_next            ; unchanged this frame
.re_moved:
    jsr erase_prev
    jsr draw_entity
    lda ent_x,x
    sta ent_px,x
    lda ent_y,x
    sta ent_py,x
.re_next:
    inx
    cpx #MAX_ENT
    bne .re_loop
    rts
