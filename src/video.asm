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

init_video:
    ; Initialize the video hardware
    lda #%00011011
    sta SCROLY

    ; Set the vertical scroll register
    lda #%00001000
    sta SCROLX

    ; Set the video mode control register
    lda #%00010100
    sta VMCSB

    ; Set the border color
    ;lda #$00
    ;sta BORDER ; border color = black

    ; Set the background color
    ;lda #$06
    ;sta BACKGROUND ; background color = blue

    rts

clear_screen:
    ; Clear the screen by filling screen RAM with blank characters
    lda #BLANK_CHAR
    ldx #0
.loop:
    sta SCREEN_RAM, x
    sta SCREEN_RAM + 250, x
    sta SCREEN_RAM + 500, x
    sta SCREEN_RAM + 750, x
    inx
    cpx #250
    bne .loop
    rts

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
