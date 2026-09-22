; --- Optional frame-time profiler. Build with `make PROFILE=1`.
;
; game_tick samples the raster line twice per tick: probe 0 right after
; update_game, probe 1 at the very end of the tick. The raster IRQ fires at
; line 1, so a probe's raster line is (approximately) how far into the frame
; that stage finished. A tick that runs past the next IRQ is counted as an
; overrun instead of being averaged in. Read the results from the VICE
; monitor; nothing is drawn. Per-probe arrays are indexed by probe (0/1). ---

prof_lo:      !byte 0            ; current raster line, low byte
prof_hi:      !byte 0            ; ...and bit 8 (0/1)

prof_max_lo:  !fill 2, 0
prof_max_hi:  !fill 2, 0
prof_sum0:    !fill 2, 0         ; 24-bit running sum of sampled lines
prof_sum1:    !fill 2, 0
prof_sum2:    !fill 2, 0
prof_n_lo:    !fill 2, 0         ; 16-bit count of frames folded into the sum
prof_n_hi:    !fill 2, 0
prof_over_lo: !fill 2, 0         ; 16-bit count of overrun frames
prof_over_hi: !fill 2, 0

; Read the current raster line (9 bits) into prof_lo/prof_hi. Retries if
; bit 8 changes between the two reads, so the pair is always consistent.
; Clobbers A.
prof_sample:
.ps_retry:
    lda SCROLY
    and #$80
    sta prof_hi
    lda RASTER
    sta prof_lo
    lda SCROLY
    and #$80
    cmp prof_hi
    bne .ps_retry
    lda prof_hi
    asl                          ; bit 7 -> carry
    lda #0
    rol                          ; A = 0/1
    sta prof_hi
    rts

; Record a probe. Enter with X = probe index (0 = after update, 1 = end of
; tick). Preserves X. Clobbers A.
prof_mark:
    jsr prof_sample
    lda frame_counter
    cmp last_frame
    beq .pm_ok
    inc prof_over_lo,x           ; IRQ already fired again: this tick overran
    bne .pm_done
    inc prof_over_hi,x
.pm_done:
    rts
.pm_ok:
    inc prof_n_lo,x
    bne .pm_sum
    inc prof_n_hi,x
.pm_sum:
    lda prof_sum0,x
    clc
    adc prof_lo
    sta prof_sum0,x
    lda prof_sum1,x
    adc prof_hi
    sta prof_sum1,x
    lda prof_sum2,x
    adc #0
    sta prof_sum2,x
    lda prof_hi
    cmp prof_max_hi,x
    bcc .pm_done
    bne .pm_new
    lda prof_lo
    cmp prof_max_lo,x
    bcc .pm_done
    beq .pm_done
.pm_new:
    lda prof_lo
    sta prof_max_lo,x
    lda prof_hi
    sta prof_max_hi,x
    rts
