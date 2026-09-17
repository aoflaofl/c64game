MAX_SHOT   = 8
; At 1 cell/frame, SHOT_LIFE is also the max range in cells; 40 covers the
; full play-field width so a shot can reach an enemy spawned clear across it.
SHOT_LIFE  = 40        ; frames before self-expire

sh_active: !fill MAX_SHOT, 0    ; 0 = free slot
sh_x:      !fill MAX_SHOT, 0    ; cell column 0..39
sh_y:      !fill MAX_SHOT, 0    ; cell row 0..24
sh_dx:     !fill MAX_SHOT, 0    ; heading, signed: $ff / $00 / $01
sh_dy:     !fill MAX_SHOT, 0
sh_life:   !fill MAX_SHOT, 0    ; frames remaining
sh_owner:  !fill MAX_SHOT, 0    ; 0 = player, 1 = enemy (reserved for shooter AI)

; spawn_projectile parameters
pj_x:      !byte 0
pj_y:      !byte 0
pj_dx:     !byte 0
pj_dy:     !byte 0
pj_owner:  !byte 0

; Zero every slot. Safe to call again to restart the game.
init_projectiles:
    lda #0
    ldx #MAX_SHOT - 1
.ip_loop:
    sta sh_active,x
    dex
    bpl .ip_loop
    rts

; Launch a projectile from pj_x/pj_y heading pj_dx/pj_dy, owner pj_owner.
; Does nothing if the pool is full. Clobbers A, X, Y.
spawn_projectile:
    ldx #0
.sp_find:
    lda sh_active,x
    beq .sp_found
    inx
    cpx #MAX_SHOT
    bne .sp_find
    rts                        ; pool full
.sp_found:
    lda #1
    sta sh_active,x
    lda pj_x
    sta sh_x,x
    lda pj_y
    sta sh_y,x
    lda pj_dx
    sta sh_dx,x
    lda pj_dy
    sta sh_dy,x
    lda pj_owner
    sta sh_owner,x
    lda #SHOT_LIFE
    sta sh_life,x
    ; point-blank: an enemy already on the muzzle cell dies now
    lda pj_owner
    bne .sp_done
    jsr shot_hitscan
.sp_done:
    rts

; Free shot X. Its previous image is removed by the next render pass.
despawn_shot:
    lda #0
    sta sh_active,x
    rts

; Per-frame: age, move (1 cell/frame), cull at the play-field edge, and test
; the entered cell against the shot's target -- every enemy for a player-owned
; shot, or just the player's cell for an enemy-owned one.
update_projectiles:
    ldx #0
.up_loop:
    lda sh_active,x
    beq .up_next

    dec sh_life,x
    beq .up_kill

    lda sh_x,x
    clc
    adc sh_dx,x
    sta sh_x,x
    cmp #40
    bcs .up_kill              ; off left/right edge (>=40, also $ff from 0-1)
    lda sh_y,x
    clc
    adc sh_dy,x
    sta sh_y,x
    cmp #25
    bcs .up_kill              ; off top/bottom edge

    lda sh_owner,x
    bne .up_enemy_shot
    jsr shot_hitscan
    jmp .up_next

.up_enemy_shot:
    lda player_x
    sta hit_test_x
    lda player_y
    sta hit_test_y
    jsr shot_near_target
    beq .up_next
    jsr player_hit
    jsr despawn_shot
    jmp .up_next

.up_kill:
    jsr despawn_shot
.up_next:
    inx
    cpx #MAX_SHOT
    bne .up_loop
    rts

; Scan the enemy pool for one within SHOT_HIT_RADIUS of shot X's cell. On a
; hit: kill the enemy (hit_enemy) and despawn the shot. Enter with X = shot
; slot. Preserves X. Clobbers A, Y.
shot_hitscan:
    ldy #0
.shs_loop:
    lda ent_active,y
    beq .shs_next
    lda ent_x,y
    sta hit_test_x
    lda ent_y,y
    sta hit_test_y
    jsr shot_near_target
    beq .shs_next
    jsr hit_enemy            ; Y = enemy slot; preserves X
    jsr despawn_shot         ; X = shot slot
    rts
.shs_next:
    iny
    cpy #MAX_ENT
    bne .shs_loop
    rts
