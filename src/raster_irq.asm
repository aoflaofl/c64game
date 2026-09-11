init_raster_irq:
    ; Disable interrupts while setting up the raster IRQ
    sei

    ; Set the raster line for the IRQ
    lda #01
    sta RASTER

    ; Mask out the highest bit of the vertical scroll register
    ; This sets the highest bit of the vertical scroll register to 0
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

    ; Frame timing only -- game logic and rendering run once per frame from
    ; the main loop's game_tick (main.asm), not here, so they never race a
    ; raster IRQ landing mid-update.

    ; Register restoration is handled by the KERNEL_IRQ_CLEANUP routine
    jmp KERNEL_IRQ_CLEANUP
