joyfire:   !byte 0
joyhoriz:  !byte 0
joyvert:   !byte 0

joy2se:
    lda #0
    sta joyhoriz
    sta joyvert
    sta joyfire

    lda CIAPRA
.joy_up:
    lsr
    bcs .joy_down
    dec joyvert
.joy_down:
    lsr
    bcs .joy_left
    inc joyvert
.joy_left:
    lsr
    bcs .joy_right
    dec joyhoriz
.joy_right:
    lsr
    bcs .joy_fire
    inc joyhoriz
.joy_fire:
    lsr
    bcs .joy_done
    inc joyfire

.joy_done:
    rts
