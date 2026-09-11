run_ai:
    ldx #0
.ai_entity_loop:
    lda ent_active,x
    beq .ai_entity_skip
    dec ent_timer,x
    bpl .ai_move                        ; not a decision frame; just move
    ldy ent_type,x
    lda typ_react,y
    sta ent_timer,x
    lda typ_ai_lo,y
    sta AI_VEC
    lda typ_ai_hi,y
    sta AI_VEC+1
    jsr call_ai               ; X = entity index, preserved by convention
.ai_move:
    jsr advance_entity        ; every frame: accumulate speed, step on carry
.ai_entity_skip:
    inx
    cpx #MAX_ENT
    bne .ai_entity_loop
    rts
call_ai:
    jmp (AI_VEC)

; --- AI routines. Enter with X = entity index; each must preserve X.
;     An AI routine only sets heading (ent_dx / ent_dy) and state (ent_state),
;     and may override ent_timer (think delay) or ent_speed (dash / slow). It
;     must not move the entity or touch ent_x / ent_y -- advance_entity owns
;     locomotion. ---

; Set ent_dx/ent_dy,x to one step toward the player (the sign of the offset on
; each axis; coordinates are small unsigned cell numbers so a plain cmp gives
; the ordering). May set both axes at once, i.e. diagonal movement.
; Enter/leave with X = entity index. Preserves X. Clobbers A.
face_player:
    lda player_x
    cmp ent_x,x
    beq .fp_x_zero
    bcs .fp_x_pos
    lda #$ff
    sta ent_dx,x
    jmp .fp_y
.fp_x_pos:
    lda #1
    sta ent_dx,x
    jmp .fp_y
.fp_x_zero:
    lda #0
    sta ent_dx,x
.fp_y:
    lda player_y
    cmp ent_y,x
    beq .fp_y_zero
    bcs .fp_y_pos
    lda #$ff
    sta ent_dy,x
    rts
.fp_y_pos:
    lda #1
    sta ent_dy,x
    rts
.fp_y_zero:
    lda #0
    sta ent_dy,x
    rts

; Grunt / chaser / swarm: roll against typ_aggr (0..255, "0 = always wander"
; .. "255 = always chase") to decide whether to face the player this decision,
; or wander like the original grunt behavior. Personality comes entirely from
; each type's aggr/speed/react data, not from separate code.
ai_wander_or_chase:
    ldy ent_type,x
    lda RANDOM
    cmp typ_aggr,y
    bcc .woc_chase            ; RANDOM < typ_aggr: chase this decision
    lda RANDOM
    cmp #$40
    bcs .woc_done             ; ~75%: keep the current heading
    lda RANDOM
    and #$03
    tay
    lda grunt_dx,y
    sta ent_dx,x
    lda grunt_dy,y
    sta ent_dy,x
.woc_done:
    rts
.woc_chase:
    jsr face_player
    rts

; Lurker: sits still until it shares a row or column with the player, then
; dashes along that line at a burst speed. Drops back to its resting
; speed/react the moment it loses alignment (passes the player, hits a wall,
; or the player steps off the line). ent_state: 0 = resting, 1 = dashing.
LURKER_DASH_SPEED = 220
LURKER_DASH_REACT = 6

ai_lurker:
    lda player_x
    cmp ent_x,x
    beq .lk_aligned
    lda player_y
    cmp ent_y,x
    beq .lk_aligned
    lda ent_state,x
    beq .lk_hold              ; already resting
    jsr lurker_rest
.lk_hold:
    lda #0
    sta ent_dx,x
    sta ent_dy,x
    rts
.lk_aligned:
    lda #LURKER_DASH_REACT
    sta ent_timer,x           ; re-check alignment often for as long as we dash
    lda ent_state,x
    bne .lk_face              ; already dashing
    lda #1
    sta ent_state,x
    lda #LURKER_DASH_SPEED
    sta ent_speed,x
.lk_face:
    jsr face_player
    rts

; Return a lurker to its resting speed/react and clear the dash flag.
; Enter/leave with X = entity index. Preserves X. Clobbers A, Y.
lurker_rest:
    lda #0
    sta ent_state,x
    ldy ent_type,x
    lda typ_speed,y
    sta ent_speed,x
    lda typ_react,y
    sta ent_timer,x
    rts

ai_shooter:
    rts                        ; needs enemy-owned projectiles (milestone 5)

grunt_dx: !byte $01, $ff, $00, $00
grunt_dy: !byte $00, $00, $01, $ff

; Per-frame locomotion. Add ent_speed to the step accumulator; on a byte
; overflow, advance one cell along the current heading. Speed is thus
; ent_speed/256 cells per frame (max ~1 cell/frame).
; Enter with X = entity index. Preserves X. Clobbers A.
advance_entity:
    lda ent_speed,x
    clc
    adc ent_moveacc,x
    sta ent_moveacc,x
    bcs step_cell
    rts

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
