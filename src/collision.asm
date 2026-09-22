; --- Collision: brute-force cell comparison, no spatial index yet.
;     hit_enemy is called from projectiles.asm; check_player_hit runs once per
;     frame from game_tick. The occupancy grid is a later milestone. ---

; Shots only travel in the 8 fixed directions, so landing an exact-cell hit
; against a moving target is hard even when aimed well. shot_near_target
; gives shots a forgiving hitbox instead of an exact-cell one; contact damage
; (check_player_hit above) stays exact, since that's "did you walk into it,"
; not "did your shot's line pass close enough."
SHOT_HIT_RADIUS = 1

; shot_near_target parameters
hit_test_x: !byte 0
hit_test_y: !byte 0

; Returns A=1 if shot X's current cell is within SHOT_HIT_RADIUS of
; (hit_test_x, hit_test_y) on both axes ("close enough to hit"), else A=0.
; Enter with X = shot slot. Preserves X. Clobbers A.
shot_near_target:
    lda sh_x,x
    sec
    sbc hit_test_x
    bpl .snt_x_pos
    eor #$ff
    clc
    adc #1                   ; A = abs(sh_x - hit_test_x)
.snt_x_pos:
    cmp #SHOT_HIT_RADIUS + 1
    bcs .snt_far              ; x alone is already out of range
    lda sh_y,x
    sec
    sbc hit_test_y
    bpl .snt_y_pos
    eor #$ff
    clc
    adc #1                   ; A = abs(sh_y - hit_test_y)
.snt_y_pos:
    cmp #SHOT_HIT_RADIUS + 1
    bcs .snt_far              ; y alone is already out of range
    lda #1                    ; within radius on both axes: a hit
    rts
.snt_far:
    lda #0
    rts

; Apply one hit to enemy Y. Despawns it when HP reaches 0.
; Enter with Y = enemy slot. Preserves X. Clobbers A, Y.
; (6502 has no DEC abs,Y, so the enemy slot is moved into X for the work and
;  the caller's X is saved across the call.)
hit_enemy:
    txa
    pha                        ; save caller's X (shot slot)
    tya
    tax                        ; X = enemy slot
    dec ent_hp,x
    bne .he_alive              ; wounded but alive (future: slow / flash)
    jsr grid_clear
    lda #0
    sta ent_active,x
    ldy ent_type,x
    lda typ_score,y
    jsr add_score
.he_alive:
    pla
    tax                        ; restore shot slot
    rts

; Enemy-vs-player contact. Counts i-frames down and, while invulnerable, skips
; the scan entirely. On contact: jsr player_hit. Clobbers A, X.
check_player_hit:
    lda player_iframes
    beq .cph_scan
    dec player_iframes
    rts
.cph_scan:
    ldx #0
.cph_loop:
    lda ent_active,x
    beq .cph_next
    lda ent_x,x
    cmp player_x
    bne .cph_next
    lda ent_y,x
    cmp player_y
    bne .cph_next
    jsr player_hit
    rts                        ; one contact per frame is enough
.cph_next:
    inx
    cpx #MAX_ENT
    bne .cph_loop
    rts
