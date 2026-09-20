;
; renderer.asm owns the dynamic actor layer (rows 1..24: player, enemies,
; projectiles), erased and redrawn every frame. hud.asm owns row 0 and the
; game-over overlay -- static text, touched only when the underlying value
; changes, not on the erase/redraw-every-frame model below.
;

BLANK_CHAR   = $20
PLAYER_CHAR  = $51
PLAYER_COLOR = $01
SHOT_CHAR    = $2a             ; '*' placeholder glyph
SHOT_COLOR   = $01

screen_row_lo:
    !byte <(SCREEN_RAM + 0 * 40), <(SCREEN_RAM + 1 * 40)
    !byte <(SCREEN_RAM + 2 * 40), <(SCREEN_RAM + 3 * 40)
    !byte <(SCREEN_RAM + 4 * 40), <(SCREEN_RAM + 5 * 40)
    !byte <(SCREEN_RAM + 6 * 40), <(SCREEN_RAM + 7 * 40)
    !byte <(SCREEN_RAM + 8 * 40), <(SCREEN_RAM + 9 * 40)
    !byte <(SCREEN_RAM + 10 * 40), <(SCREEN_RAM + 11 * 40)
    !byte <(SCREEN_RAM + 12 * 40), <(SCREEN_RAM + 13 * 40)
    !byte <(SCREEN_RAM + 14 * 40), <(SCREEN_RAM + 15 * 40)
    !byte <(SCREEN_RAM + 16 * 40), <(SCREEN_RAM + 17 * 40)
    !byte <(SCREEN_RAM + 18 * 40), <(SCREEN_RAM + 19 * 40)
    !byte <(SCREEN_RAM + 20 * 40), <(SCREEN_RAM + 21 * 40)
    !byte <(SCREEN_RAM + 22 * 40), <(SCREEN_RAM + 23 * 40)
    !byte <(SCREEN_RAM + 24 * 40)

screen_row_hi:
    !byte >(SCREEN_RAM + 0 * 40), >(SCREEN_RAM + 1 * 40)
    !byte >(SCREEN_RAM + 2 * 40), >(SCREEN_RAM + 3 * 40)
    !byte >(SCREEN_RAM + 4 * 40), >(SCREEN_RAM + 5 * 40)
    !byte >(SCREEN_RAM + 6 * 40), >(SCREEN_RAM + 7 * 40)
    !byte >(SCREEN_RAM + 8 * 40), >(SCREEN_RAM + 9 * 40)
    !byte >(SCREEN_RAM + 10 * 40), >(SCREEN_RAM + 11 * 40)
    !byte >(SCREEN_RAM + 12 * 40), >(SCREEN_RAM + 13 * 40)
    !byte >(SCREEN_RAM + 14 * 40), >(SCREEN_RAM + 15 * 40)
    !byte >(SCREEN_RAM + 16 * 40), >(SCREEN_RAM + 17 * 40)
    !byte >(SCREEN_RAM + 18 * 40), >(SCREEN_RAM + 19 * 40)
    !byte >(SCREEN_RAM + 20 * 40), >(SCREEN_RAM + 21 * 40)
    !byte >(SCREEN_RAM + 22 * 40), >(SCREEN_RAM + 23 * 40)
    !byte >(SCREEN_RAM + 24 * 40)

color_row_lo:
    !byte <(COLOR_RAM + 0 * 40), <(COLOR_RAM + 1 * 40)
    !byte <(COLOR_RAM + 2 * 40), <(COLOR_RAM + 3 * 40)
    !byte <(COLOR_RAM + 4 * 40), <(COLOR_RAM + 5 * 40)
    !byte <(COLOR_RAM + 6 * 40), <(COLOR_RAM + 7 * 40)
    !byte <(COLOR_RAM + 8 * 40), <(COLOR_RAM + 9 * 40)
    !byte <(COLOR_RAM + 10 * 40), <(COLOR_RAM + 11 * 40)
    !byte <(COLOR_RAM + 12 * 40), <(COLOR_RAM + 13 * 40)
    !byte <(COLOR_RAM + 14 * 40), <(COLOR_RAM + 15 * 40)
    !byte <(COLOR_RAM + 16 * 40), <(COLOR_RAM + 17 * 40)
    !byte <(COLOR_RAM + 18 * 40), <(COLOR_RAM + 19 * 40)
    !byte <(COLOR_RAM + 20 * 40), <(COLOR_RAM + 21 * 40)
    !byte <(COLOR_RAM + 22 * 40), <(COLOR_RAM + 23 * 40)
    !byte <(COLOR_RAM + 24 * 40)

color_row_hi:
    !byte >(COLOR_RAM + 0 * 40), >(COLOR_RAM + 1 * 40)
    !byte >(COLOR_RAM + 2 * 40), >(COLOR_RAM + 3 * 40)
    !byte >(COLOR_RAM + 4 * 40), >(COLOR_RAM + 5 * 40)
    !byte >(COLOR_RAM + 6 * 40), >(COLOR_RAM + 7 * 40)
    !byte >(COLOR_RAM + 8 * 40), >(COLOR_RAM + 9 * 40)
    !byte >(COLOR_RAM + 10 * 40), >(COLOR_RAM + 11 * 40)
    !byte >(COLOR_RAM + 12 * 40), >(COLOR_RAM + 13 * 40)
    !byte >(COLOR_RAM + 14 * 40), >(COLOR_RAM + 15 * 40)
    !byte >(COLOR_RAM + 16 * 40), >(COLOR_RAM + 17 * 40)
    !byte >(COLOR_RAM + 18 * 40), >(COLOR_RAM + 19 * 40)
    !byte >(COLOR_RAM + 20 * 40), >(COLOR_RAM + 21 * 40)
    !byte >(COLOR_RAM + 22 * 40), >(COLOR_RAM + 23 * 40)
    !byte >(COLOR_RAM + 24 * 40)

set_screen_color_ptrs_for_y:
    lda screen_row_lo,y
    sta SCREEN_PTR
    lda screen_row_hi,y
    sta SCREEN_PTR + 1
    lda color_row_lo,y
    sta COLOR_PTR
    lda color_row_hi,y
    sta COLOR_PTR + 1
    rts

; Renderer-owned snapshot of what was drawn during the previous frame.
render_player_x:       !byte 0
render_player_y:       !byte 0
render_player_visible: !byte 0

render_ent_x:          !fill MAX_ENT, 0
render_ent_y:          !fill MAX_ENT, 0
render_ent_visible:    !fill MAX_ENT, 0

render_shot_x:         !fill MAX_SHOT, 0
render_shot_y:         !fill MAX_SHOT, 0
render_shot_visible:   !fill MAX_SHOT, 0

; Clear the renderer snapshot. Game-state initialization does not draw.
init_renderer:
    lda #0
    sta render_player_visible

    ldx #MAX_ENT - 1
.ir_entities:
    sta render_ent_visible,x
    dex
    bpl .ir_entities

    ldx #MAX_SHOT - 1
.ir_shots:
    sta render_shot_visible,x
    dex
    bpl .ir_shots
    rts

; Remove the previous dynamic layer, then rebuild it from current game state.
; Layer priority is enemies, projectiles, player.
render_frame:
    jsr erase_previous_frame
    jsr draw_current_entities
    jsr draw_current_projectiles
    jsr draw_current_player
    rts

; Erase only what actually needs it: an actor that died, or one that moved off
; the cell it was last drawn at. An actor that is still active and still on
; the same cell is left alone here -- the draw pass below redraws every active
; actor unconditionally, so it "wins" that cell back regardless of anything
; else that touched it. Skipping the erase just saves the redundant blank.
erase_previous_frame:
    lda render_player_visible
    beq .epf_entities
    lda player_x
    cmp render_player_x
    bne .epf_player_erase
    lda player_y
    cmp render_player_y
    beq .epf_entities          ; unchanged: draw phase will redraw it in place
.epf_player_erase:
    ldy render_player_y
    jsr set_screen_color_ptrs_for_y
    ldy render_player_x
    lda #BLANK_CHAR
    sta (SCREEN_PTR),y
    lda #0
    sta render_player_visible

.epf_entities:
    ldx #0
.epf_entity_loop:
    lda render_ent_visible,x
    beq .epf_entity_next        ; wasn't on screen: nothing to erase
    lda ent_active,x
    beq .epf_entity_erase       ; died since last frame: must erase
    lda ent_x,x
    cmp render_ent_x,x
    bne .epf_entity_erase
    lda ent_y,x
    cmp render_ent_y,x
    beq .epf_entity_next        ; unchanged & still active: skip the erase
.epf_entity_erase:
    lda render_ent_y,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy render_ent_x,x
    lda #BLANK_CHAR
    sta (SCREEN_PTR),y
    lda #0
    sta render_ent_visible,x
.epf_entity_next:
    inx
    cpx #MAX_ENT
    bne .epf_entity_loop

    ldx #0
.epf_shot_loop:
    lda render_shot_visible,x
    beq .epf_shot_next
    lda sh_active,x
    beq .epf_shot_erase
    lda sh_x,x
    cmp render_shot_x,x
    bne .epf_shot_erase
    lda sh_y,x
    cmp render_shot_y,x
    beq .epf_shot_next          ; unchanged & still active: skip the erase
.epf_shot_erase:
    lda render_shot_y,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy render_shot_x,x
    lda #BLANK_CHAR
    sta (SCREEN_PTR),y
    lda #0
    sta render_shot_visible,x
.epf_shot_next:
    inx
    cpx #MAX_SHOT
    bne .epf_shot_loop
    rts

draw_current_entities:
    ldx #0
.dce_loop:
    lda ent_active,x
    beq .dce_next

    lda ent_y,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy ent_type,x
    lda typ_color,y
    pha
    lda typ_char,y
    ldy ent_x,x
    sta (SCREEN_PTR),y
    pla
    sta (COLOR_PTR),y

    lda ent_x,x
    sta render_ent_x,x
    lda ent_y,x
    sta render_ent_y,x
    lda #1
    sta render_ent_visible,x
.dce_next:
    inx
    cpx #MAX_ENT
    bne .dce_loop
    rts

draw_current_projectiles:
    ldx #0
.dcp_loop:
    lda sh_active,x
    beq .dcp_next

    lda sh_y,x
    tay
    jsr set_screen_color_ptrs_for_y
    ldy sh_x,x
    lda #SHOT_CHAR
    sta (SCREEN_PTR),y
    lda #SHOT_COLOR
    sta (COLOR_PTR),y

    lda sh_x,x
    sta render_shot_x,x
    lda sh_y,x
    sta render_shot_y,x
    lda #1
    sta render_shot_visible,x
.dcp_next:
    inx
    cpx #MAX_SHOT
    bne .dcp_loop
    rts

draw_current_player:
    ldy player_y
    jsr set_screen_color_ptrs_for_y
    ldy player_x
    lda #PLAYER_CHAR
    sta (SCREEN_PTR),y
    lda #PLAYER_COLOR
    sta (COLOR_PTR),y

    lda player_x
    sta render_player_x
    lda player_y
    sta render_player_y
    lda #1
    sta render_player_visible
    rts
