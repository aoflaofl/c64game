!to "build/game.prg", cbm

;ACME 0.95

!sl "build/main.l"

* = $0801

; BASIC stub: 10 SYS 2064
!byte $0b,$08,$0a,$00,$9e,$32,$30,$36,$34,$00,$00,$00

* = $0810

!src "src/hardware.asm"
!src "src/zeropage.asm"

start:
    jsr init_random   ; Initialize SID voice 3 for random numbers
    jsr clear_screen
    jsr init_raster_irq
    jsr init_video
    jsr init_renderer
    jsr init_player
    jsr init_entities
    jsr init_projectiles
    jsr draw_hud_static
    jsr draw_score
    jsr draw_lives
    jsr draw_wave
    jsr start_wave
    jsr render_frame

loop:
    ; Block until the next frame is ready
    lda frame_counter
    cmp last_frame
    beq loop
    sta last_frame

    jsr game_tick

    jmp loop

game_tick:

    lda #COLOR_BLACK
    sta BORDER ; border color = black - start game state update

    jsr joy2se

    lda game_over
    beq .gt_active
    lda game_over_timer
    beq .gt_armed
    dec game_over_timer   ; lockout: joystick ignored while it counts down
    bne .gt_done
    jsr draw_restart_prompt   ; lockout just expired: show the prompt
    jmp .gt_done
.gt_armed:
    lda joyfire
    beq .gt_done          ; frozen, no restart requested yet
    jsr reset_game        ; falls through into a normal tick below

.gt_active:
    jsr update_game
!ifdef PROFILE {
    ldx #0
    jsr prof_mark
}

    lda #COLOR_RED
    sta BORDER ; border color = red - start frame update

    jsr render_frame

    lda #COLOR_WHITE
    sta BORDER ; border color = white — frame work done
!ifdef PROFILE {
    ldx #1
    jsr prof_mark
}

    lda game_over
    beq .gt_done
    jsr draw_game_over_screen   ; just transitioned this tick: overlay once
.gt_done:
    rts

update_game:
    jsr update_player_timed
    jsr player_fire
    jsr run_ai
    jsr update_projectiles
    jsr check_player_hit
    jsr spawn_director
    rts

!src "src/timing.asm"
!src "src/random.asm"
!src "src/joystick.asm"
!src "src/player.asm"
!src "src/raster_irq.asm"
!src "src/video.asm"
!src "src/entity_types.asm"
!src "src/entities.asm"
!src "src/enemy_ai.asm"
!src "src/projectiles.asm"
!src "src/collision.asm"
!src "src/grid.asm"
!src "src/renderer.asm"
!src "src/hud.asm"
!src "src/game_state.asm"
!ifdef PROFILE {
!src "src/prof.asm"
}
