; --- Collision: brute-force cell comparison, no spatial index yet.
;     hit_enemy is called from projectiles.asm; check_player_hit runs once per
;     frame from game_tick. The occupancy grid is a later milestone. ---

; Apply one hit to enemy Y. Despawns it when HP reaches 0.
; Enter with Y = enemy slot. Preserves X. Clobbers A.
; (6502 has no DEC abs,Y, so the enemy slot is moved into X for the work and
;  the caller's X is saved across the call.)
hit_enemy:
    txa
    pha                        ; save caller's X (shot slot)
    tya
    tax                        ; X = enemy slot
    dec ent_hp,x
    bne .he_alive              ; wounded but alive (future: slow / flash)
    lda #0
    sta ent_active,x
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
