; Random numbers via SID voice 3.
;
; With voice 3 set to the noise waveform, its oscillator output register
; (RANDOM = $d41b) returns a fresh pseudo-random byte on every read. init_random
; must run once at startup; after that, `lda RANDOM` anywhere is a random byte.

init_random:
    lda #$ff        ; voice 3 frequency high byte = maximum -> fastest noise
    sta FREHI3
    lda #%10000000
    sta VCREG3      ; voice 3 waveform = noise
    sta SIGVOL      ; master volume 0, voice 3 disconnected from output
    rts
