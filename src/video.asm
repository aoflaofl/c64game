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
