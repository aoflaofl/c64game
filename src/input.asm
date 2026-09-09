joyfire:   !byte 0, 0
joyhoriz:  !byte 0, 0
joyvert:   !byte 0, 0

joy2se:
    ldx #1
joylp:
    lda #0
    sta joyhoriz,X
    sta joyvert,X
    sta joyfire,X

    lda CIAPRA,X
up:
    lsr
    bcs down
    dec joyvert,X
down:
    lsr
    bcs left
    inc joyvert,X
left:
    lsr
    bcs right
    dec joyhoriz,X
right:
    lsr
    bcs fire
    inc joyhoriz,X
fire:
    lsr
    bcs done
    inc joyfire,x

done:
    dex
    bpl joylp
    rts
