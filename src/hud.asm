; --- HUD: row 0 of the screen, reserved from the playfield (rows 1..24) for
;     score/lives/wave. Only renderer.asm's dynamic actor layer follows the
;     erase/redraw-every-frame model; the HUD is static text that's drawn
;     once and only touched again when the underlying value changes. ---

HUD_COLOR = COLOR_WHITE

SCORE_LABEL_COL  = 0
SCORE_DIGITS_COL = 6
SCORE_DIGITS     = 5
LIVES_LABEL_COL  = 14
LIVES_DIGIT_COL  = 20
WAVE_LABEL_COL   = 25
WAVE_DIGITS_COL  = 30

hud_score_label: !byte $13,$03,$0f,$12,$05,$20   ; "SCORE "
hud_lives_label: !byte $0c,$09,$16,$05,$13,$20   ; "LIVES "
hud_wave_label:  !byte $17,$01,$16,$05,$20        ; "WAVE "

score_lo:      !byte 0
score_hi:      !byte 0
score_tmp_lo:  !byte 0
score_tmp_hi:  !byte 0
score_digit:   !byte 0

; Place values for draw_score's repeated-subtraction binary-to-decimal
; conversion, most significant first.
score_place_lo: !byte <10000, <1000, <100, <10, <1
score_place_hi: !byte >10000, >1000, >100, >10, >1

; Draw the "SCORE"/"LIVES"/"WAVE" labels once. Row 0 only, so this writes
; SCREEN_RAM/COLOR_RAM directly rather than going through the row-lookup
; tables in renderer.asm. Clobbers A, X.
draw_hud_static:
    ldx #0
.dhs_score:
    lda hud_score_label,x
    sta SCREEN_RAM+SCORE_LABEL_COL,x
    lda #HUD_COLOR
    sta COLOR_RAM+SCORE_LABEL_COL,x
    inx
    cpx #6
    bne .dhs_score

    ldx #0
.dhs_lives:
    lda hud_lives_label,x
    sta SCREEN_RAM+LIVES_LABEL_COL,x
    lda #HUD_COLOR
    sta COLOR_RAM+LIVES_LABEL_COL,x
    inx
    cpx #6
    bne .dhs_lives

    ldx #0
.dhs_wave:
    lda hud_wave_label,x
    sta SCREEN_RAM+WAVE_LABEL_COL,x
    lda #HUD_COLOR
    sta COLOR_RAM+WAVE_LABEL_COL,x
    inx
    cpx #5
    bne .dhs_wave
    rts

; player_lives is always 0..3: a single digit, no conversion needed.
; Clobbers A.
draw_lives:
    lda player_lives
    clc
    adc #$30
    sta SCREEN_RAM+LIVES_DIGIT_COL
    lda #HUD_COLOR
    sta COLOR_RAM+LIVES_DIGIT_COL
    rts

; wave_number as two decimal digits (0..99). Clobbers A, X, Y.
draw_wave:
    lda wave_number
    ldy #0
.dw_div:
    cmp #10
    bcc .dw_done
    sec
    sbc #10
    iny
    jmp .dw_div
.dw_done:
    pha
    tya
    clc
    adc #$30
    sta SCREEN_RAM+WAVE_DIGITS_COL
    pla
    clc
    adc #$30
    sta SCREEN_RAM+WAVE_DIGITS_COL+1
    lda #HUD_COLOR
    sta COLOR_RAM+WAVE_DIGITS_COL
    sta COLOR_RAM+WAVE_DIGITS_COL+1
    rts

; Add A points to the 16-bit binary score and redraw it. Clobbers A.
add_score:
    clc
    adc score_lo
    sta score_lo
    lda score_hi
    adc #0
    sta score_hi
    jsr draw_score
    rts

; Render score_lo/score_hi as SCORE_DIGITS decimal digits via repeated
; subtraction of each place value (16-bit compare/subtract). Runs only on
; a score change (a few times a second at most), so this doesn't need to be
; fast. Clobbers A, X, Y.
draw_score:
    lda score_lo
    sta score_tmp_lo
    lda score_hi
    sta score_tmp_hi
    ldx #0
.ds_digit_loop:
    lda #0
    sta score_digit
.ds_sub_loop:
    lda score_tmp_hi
    cmp score_place_hi,x
    bcc .ds_next_digit          ; tmp_hi < place_hi: tmp < place, stop
    bne .ds_do_sub               ; tmp_hi > place_hi: tmp >= place
    lda score_tmp_lo
    cmp score_place_lo,x
    bcc .ds_next_digit          ; hi equal, lo < place_lo: tmp < place
.ds_do_sub:
    lda score_tmp_lo
    sec
    sbc score_place_lo,x
    sta score_tmp_lo
    lda score_tmp_hi
    sbc score_place_hi,x
    sta score_tmp_hi
    inc score_digit
    jmp .ds_sub_loop
.ds_next_digit:
    lda score_digit
    clc
    adc #$30
    sta SCREEN_RAM+SCORE_DIGITS_COL,x
    lda #HUD_COLOR
    sta COLOR_RAM+SCORE_DIGITS_COL,x
    inx
    cpx #SCORE_DIGITS
    bne .ds_digit_loop
    rts
