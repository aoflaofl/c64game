MAX_ENT = 32

ent_active:  !fill MAX_ENT, 0     ; 0 = free slot
ent_type:    !fill MAX_ENT, 0     ; index into type tables
ent_x:       !fill MAX_ENT, 0     ; cell column 0..39
ent_y:       !fill MAX_ENT, 0     ; cell row 0..24
ent_moveacc: !fill MAX_ENT, 0     ; step accumulator: += ent_speed each frame, step one cell on carry
ent_speed:   !fill MAX_ENT, 0     ; movement rate; cells/frame = n/256 (seeded from typ_speed)
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
    lda sp_y
    sta ent_y,x
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
