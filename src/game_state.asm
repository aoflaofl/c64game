; --- Game-over / restart flow. game_tick (main.asm) checks game_over each
;     tick: while set, gameplay is frozen and only a fire press is watched
;     for, to reset back to a fresh wave 1. ---

; Fire is ignored for this many frames after the last life is lost, so a
; player who's mashing fire when they die doesn't instantly restart. ~3s at 50Hz.
GAME_OVER_LOCKOUT_FRAMES = 150

game_over:       !byte 0
game_over_timer: !byte 0    ; frames of restart lockout remaining

; Freeze gameplay and start the restart lockout. Enter once, from player_hit,
; on the life that brings player_lives to 0. The game-over screen itself is
; drawn by main.asm right after the tick's final render_frame, not here --
; trigger_game_over can run mid-tick, before that frame exists yet.
; Clobbers A.
trigger_game_over:
    lda #1
    sta game_over
    lda #GAME_OVER_LOCKOUT_FRAMES
    sta game_over_timer
    rts

; Reset all game state back to a fresh wave 1 and resume play. Mirrors the
; cold-boot sequence in main.asm's start:. Clobbers A, X, Y.
reset_game:
    jsr init_player
    jsr init_entities
    jsr init_projectiles
    jsr init_renderer
    lda #0
    sta score_lo
    sta score_hi
    sta wave_pause
    sta game_over
    lda #1
    sta wave_number
    jsr clear_screen
    jsr draw_hud_static
    jsr draw_score
    jsr draw_lives
    jsr draw_wave
    jsr start_wave
    rts
