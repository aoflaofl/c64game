; --- Collision: check_player_hit and shot_hitscan (projectiles.asm) both
;     query grid.asm's occupancy grid instead of scanning the enemy pool.
;     hit_enemy is called from projectiles.asm; check_player_hit runs once per
;     frame from game_tick. shot_near_target stays a direct O(1) check --
;     it's shot-vs-player (projectiles.asm), and the player isn't in the
;     grid. ---

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
; the check entirely. Otherwise a single occupancy-grid lookup at the
; player's own cell replaces what used to be a scan over every enemy -- the
; player isn't in the grid, so this can't see itself, and contact is exact
; (no SHOT_HIT_RADIUS tolerance; that's "did you walk into it," not "did your
; shot's line pass close enough"). On contact: jsr player_hit. Clobbers A, Y.
check_player_hit:
    lda player_iframes
    beq .cph_check
    dec player_iframes
    rts
.cph_check:
    ldy player_y
    lda grid_row_lo,y
    sta GRID_PTR
    lda grid_row_hi,y
    sta GRID_PTR + 1
    ldy player_x
    iny
    lda (GRID_PTR),y
    beq .cph_done
    jsr player_hit
.cph_done:
    rts
