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
; 220 (2.6x player speed) made the dash nearly unavoidable once aligned --
; there wasn't enough time to react and break alignment before it landed.
; 130 (~1.5x player) still reads as a burst but is outrunnable.
LURKER_DASH_SPEED = 130
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

; Fire one shot straight along the shared row or column, if the shooter and
; the player are currently aligned on one. Independent of ent_dx/ent_dy
; (which the movement step just above may have set to a wander direction) --
; alignment is checked fresh against actual positions. Fire rate is naturally
; capped by the caller's decision cadence (typ_react); no separate cooldown.
; Enter/leave with X = entity index. Preserves X. Clobbers A, Y.
shooter_try_fire:
    lda player_x
    cmp ent_x,x
    bne .stf_check_row
    ; column-aligned: vertical shot
    lda player_y
    cmp ent_y,x
    beq .stf_done              ; standing on the player: no shot
    bcs .stf_v_down
    lda #$ff
    jmp .stf_v_set
.stf_v_down:
    lda #1
.stf_v_set:
    sta pj_dy
    lda #0
    sta pj_dx
    jmp .stf_fire
.stf_check_row:
    lda player_y
    cmp ent_y,x
    bne .stf_done               ; not aligned on either axis
    ; row-aligned: horizontal shot
    lda player_x
    cmp ent_x,x
    bcs .stf_h_right
    lda #$ff
    jmp .stf_h_set
.stf_h_right:
    lda #1
.stf_h_set:
    sta pj_dx
    lda #0
    sta pj_dy
.stf_fire:
    lda ent_x,x
    sta pj_x
    lda ent_y,x
    sta pj_y
    lda #1
    sta pj_owner
    txa
    pha
    jsr spawn_projectile        ; clobbers X (shot-slot scratch); restored below
    pla
    tax
.stf_done:
    rts

; Shooter: moves via the same wander/chase blend as grunt/chaser/swarm (its
; own typ_aggr), and independently takes a shot whenever aligned.
ai_shooter:
    jsr ai_wander_or_chase
    jsr shooter_try_fire
    rts

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

; Candidate/target cells for step_cell (named globals, per the codebase's
; parameter-passing convention).
step_nx: !byte 0                ; heading applied to the current cell, clamped
step_ny: !byte 0
step_cx: !byte 0                ; candidate handed to step_commit_if_free
step_cy: !byte 0

; Move entity X one cell along ent_dx / ent_dy, clamped to the play area
; (rows 1..24 -- row 0 is the HUD -- and columns 0..39) and blocked by the
; occupancy grid: enemies never share a cell. A blocked diagonal slides along
; one axis (x first, then y); if both are blocked, or the entity is already
; against the wall, it stays put and tries again on its next step.
; Preserves X. Clobbers A, Y.
step_cell:
    lda ent_x,x
    sta step_nx
    lda ent_dx,x
    beq .sc_vert
    bmi .sc_left
    lda step_nx
    cmp #39
    bcs .sc_vert
    inc step_nx
    jmp .sc_vert
.sc_left:
    lda step_nx
    beq .sc_vert
    dec step_nx
.sc_vert:
    lda ent_y,x
    sta step_ny
    lda ent_dy,x
    beq .sc_try
    bmi .sc_up
    lda step_ny
    cmp #24
    bcs .sc_try
    inc step_ny
    jmp .sc_try
.sc_up:
    lda step_ny
    cmp #1
    beq .sc_try
    dec step_ny
.sc_try:
    lda step_nx                 ; 1st choice: the full move
    sta step_cx
    lda step_ny
    sta step_cy
    jsr step_commit_if_free
    bcs .sc_done
    lda step_nx                 ; blocked: slide along x only
    sta step_cx
    lda ent_y,x
    sta step_cy
    jsr step_commit_if_free
    bcs .sc_done
    lda ent_x,x                 ; still blocked: slide along y only
    sta step_cx
    lda step_ny
    sta step_cy
    jsr step_commit_if_free
.sc_done:
    rts

; Move entity X to (step_cx, step_cy) if that is a different cell and nothing
; occupies it, updating the occupancy grid. Returns C set if it moved.
; Preserves X. Clobbers A, Y.
step_commit_if_free:
    lda step_cx
    cmp ent_x,x
    bne .scf_check
    lda step_cy
    cmp ent_y,x
    beq .scf_no                 ; same cell it's already on: not a move
.scf_check:
    ldy step_cy
    lda grid_row_lo,y
    sta GRID_PTR
    lda grid_row_hi,y
    sta GRID_PTR + 1
    ldy step_cx
    iny
    lda (GRID_PTR),y
    bne .scf_no                 ; occupied
    jsr grid_clear              ; leave the old cell...
    lda step_cx
    sta ent_x,x
    lda step_cy
    sta ent_y,x
    jsr grid_set                ; ...and take the new one
    sec
    rts
.scf_no:
    clc
    rts
