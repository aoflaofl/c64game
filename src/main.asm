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

    jsr update_game

    lda #COLOR_RED
    sta BORDER ; border color = red - start frame update

    jsr render_frame

    lda #COLOR_WHITE
    sta BORDER ; border color = white — frame work done

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
!src "src/renderer.asm"
!src "src/hud.asm"
