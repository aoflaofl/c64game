PLAYER_START_X = 20
PLAYER_START_Y = 12
PLAYER_CHAR    = $51
PLAYER_COLOR   = $01
BLANK_CHAR     = $20
; PLAYER_MOVE_DELAY = 2      ; move every other frame
PLAYER_MOVE_DELAY = 3    ; move every third frame

PLAYER_LIVES_START = 3
PLAYER_FIRE_CD     = 10  ; frames between auto-fire shots
PLAYER_IFRAMES     = 75  ; invulnerable frames after a hit (~1.5s)

player_x:       !byte PLAYER_START_X
player_y:       !byte PLAYER_START_Y
player_move_timer: !byte 0
player_dx:      !byte 0          ; facing, signed: $ff / $00 / $01
player_dy:      !byte $ff        ; default facing = up
player_fire_cd: !byte 0
player_iframes: !byte 0
player_lives:   !byte PLAYER_LIVES_START

init_player:
    lda #PLAYER_START_X
    sta player_x
    lda #PLAYER_START_Y
    sta player_y
    lda #0
    sta player_dx
    sta player_fire_cd
    sta player_iframes
    lda #$ff
    sta player_dy            ; face up
    lda #PLAYER_LIVES_START
    sta player_lives
    jsr draw_player
    rts

update_player_timed:
    lda player_move_timer
    beq move_this_frame

    dec player_move_timer
    rts

move_this_frame:
    lda #PLAYER_MOVE_DELAY - 1
    sta player_move_timer

    jsr update_player
    rts

update_player:
    lda joyhoriz
    bne move_player
    lda joyvert
    bne move_player
    rts

move_player:
    jsr erase_player

    ; Capture the full facing vector for this movement, including zeroes.
    lda joyhoriz
    sta player_dx
    lda joyvert
    sta player_dy

    lda joyhoriz
    beq move_vertical
    bmi move_left
    lda player_x
    cmp #39
    beq move_vertical
    inc player_x
    jmp move_vertical

move_left:
    lda player_x
    beq move_vertical
    dec player_x

move_vertical:
    lda joyvert
    beq draw_player
    bmi move_up
    lda player_y
    cmp #24
    beq draw_player
    inc player_y
    jmp draw_player

move_up:
    lda player_y
    beq draw_player
    dec player_y

draw_player:
    jsr set_player_pointers
    ldy player_x
    lda #PLAYER_CHAR
    sta (SCREEN_PTR),y
    lda #PLAYER_COLOR
    sta (COLOR_PTR),y
    rts

erase_player:
    jsr set_player_pointers
    ldy player_x
    lda #BLANK_CHAR
    sta (SCREEN_PTR),y
    rts

set_player_pointers:
    ldy player_y
    jsr set_screen_color_ptrs_for_y
    rts

; Auto-fire: while fire is held and the cooldown has expired, launch a bullet
; one cell ahead of the player along the current facing. Called every frame.
player_fire:
    lda player_fire_cd
    beq .pf_ready
    dec player_fire_cd
    rts
.pf_ready:
    lda joyfire                 ; port 2 fire: 0 or 1
    beq .pf_done
    lda #PLAYER_FIRE_CD
    sta player_fire_cd

    lda player_x
    clc
    adc player_dx
    sta pj_x
    cmp #40
    bcs .pf_done               ; muzzle off-field (at edge, facing outward)
    lda player_y
    clc
    adc player_dy
    sta pj_y
    cmp #25
    bcs .pf_done

    lda player_dx
    sta pj_dx
    lda player_dy
    sta pj_dy
    lda #0
    sta pj_owner
    jsr spawn_projectile
.pf_done:
    rts

; Enemy contact: lose a life, recentre the player, grant invulnerability.
; Ignored while already invulnerable.
player_hit:
    lda player_iframes
    bne .ph_done
    dec player_lives
    ; TODO: game over when player_lives == 0 (later milestone)
    jsr erase_player
    lda #PLAYER_START_X
    sta player_x
    lda #PLAYER_START_Y
    sta player_y
    lda #PLAYER_IFRAMES
    sta player_iframes
    jsr draw_player
.ph_done:
    rts
