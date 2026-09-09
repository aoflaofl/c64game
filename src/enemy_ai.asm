ai_vec: !byte 0,0

run_ai:
    ldx #0
.ai_entity_loop:
    lda ent_active,x
    beq .ai_entity_skip
    dec ent_timer,x
    bpl .ai_entity_skip                 ; not this entity's decision frame
    ldy ent_type,x
    lda typ_react,y
    sta ent_timer,x
    lda typ_ai_lo,y
    sta ai_vec
    lda typ_ai_hi,y
    sta ai_vec+1
    jsr call_ai               ; X = entity index, preserved by convention
.ai_entity_skip:
    inx
    cpx #MAX_ENT
    bne .ai_entity_loop
    rts
call_ai:
    jmp (ai_vec)

; --- AI routines. Enter with X = entity index; each must preserve X. ---

; Grunt: wander. Mostly keeps its heading, occasionally rolls a new random
; one, then steps a single cell.
ai_grunt:
    lda RANDOM
    cmp #$40
    bcs .ag_step             ; ~75%: keep the current heading
    lda RANDOM
    and #$03
    tay
    lda grunt_dx,y
    sta ent_dx,x
    lda grunt_dy,y
    sta ent_dy,x
.ag_step:
    jsr step_cell
    rts

ai_chaser:
    rts
ai_lurker:
    rts
ai_shooter:
    rts
ai_swarm:
    rts

grunt_dx: !byte $01, $ff, $00, $00
grunt_dy: !byte $00, $00, $01, $ff

; Move entity X one cell along ent_dx / ent_dy, clamped to the play area.
; Preserves X. Clobbers A.
step_cell:
    lda ent_dx,x
    beq .sc_vert
    bmi .sc_left
    lda ent_x,x
    cmp #39
    bcs .sc_vert
    inc ent_x,x
    jmp .sc_vert
.sc_left:
    lda ent_x,x
    beq .sc_vert
    dec ent_x,x
.sc_vert:
    lda ent_dy,x
    beq .sc_done
    bmi .sc_up
    lda ent_y,x
    cmp #24
    bcs .sc_done
    inc ent_y,x
    jmp .sc_done
.sc_up:
    lda ent_y,x
    beq .sc_done
    dec ent_y,x
.sc_done:
    rts
