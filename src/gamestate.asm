frame_counter:  !byte 0
last_frame:     !byte 0

; Initialize SID voice 3 for random numbers.
rdinit:
  lda #$ff     ; Set voice 3 frequency (high byte) to maximum
  sta FREHI3
  lda #%10000000
  sta VCREG3   ; Select noise waveform and start release for voice 3
  sta SIGVOL   ; Turn off volume and disconnect output of voice 3
  rts
