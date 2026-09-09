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
    jsr init_player
    jsr init_entities
    jsr spawn_wave

loop:
    ; Block until the next frame is ready
    lda frame_counter
    cmp last_frame
    beq loop
    sta last_frame

    jsr game_tick

    jmp loop

game_tick:

    lda #$00
    sta BORDER ; border color = black

    jsr joy2se
    jsr update_player_timed
    jsr run_ai
    jsr render_entities

    lda #$01
    sta BORDER ; border color = white — frame work done

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
