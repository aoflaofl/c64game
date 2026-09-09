PLAYER_START_X = 20
PLAYER_START_Y = 12
PLAYER_CHAR    = $51
PLAYER_COLOR   = $01
BLANK_CHAR     = $20
; PLAYER_MOVE_DELAY = 2      ; move every other frame
PLAYER_MOVE_DELAY = 3    ; move every third frame

player_x:       !byte PLAYER_START_X
player_y:       !byte PLAYER_START_Y
player_move_timer: !byte 0

init_player:
    lda #PLAYER_START_X
    sta player_x
    lda #PLAYER_START_Y
    sta player_y
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
