init_raster_irq:
    ; Disable interrupts while setting up the raster IRQ
    sei

    ; Set the raster line for the IRQ
    lda #01
    sta RASTER

    ; Mask out the highest bit of the vertical scroll register
    lda SCROLY
    and #%01111111
    sta SCROLY

    ; Enable the raster IRQ
    lda #%00000001
    sta IRQ_ENABLE

    ; Acknowledge any pending CIA interrupts
    lda #%01111111
    sta CIA_ICR

    ; Set the IRQ vector to point to our raster IRQ handler
    lda #<raster_irq
    sta $0314

    lda #>raster_irq
    sta $0315

    ; Enable the raster IRQ and set the highest bit of the vertical scroll register
    lda #%10000001
    sta IRQ_ENABLE

    ; Re-enable interrupts now that the raster IRQ is set up
    cli

    rts

raster_irq:
    ; Acknowledge the VIC raster interrupt before doing any visible work.
    lda #$01
    sta IRQ_STATUS
    inc frame_counter
  ;  ldx #$01
  ;  stx RASTER

    ; Continue through the normal KERNAL IRQ path so keyboard scanning and
    ; register restoration remain consistent with the system IRQ trampoline.
    jmp KERNEL_IRQ_CLEANUP
