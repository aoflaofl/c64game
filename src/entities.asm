MAX_ENT = 32

ent_active:  !fill MAX_ENT, 0     ; 0 = free slot
ent_type:    !fill MAX_ENT, 0     ; index into type tables
ent_x:       !fill MAX_ENT, 0     ; cell column 0..39
ent_y:       !fill MAX_ENT, 0     ; cell row 0..24
ent_moveacc: !fill MAX_ENT, 0     ; step accumulator: += ent_speed each frame, step one cell on carry
ent_speed:   !fill MAX_ENT, 0     ; movement rate; cells/frame = n/256 (seeded from typ_speed)
ent_dx:      !fill MAX_ENT, 0     ; heading, signed: $ff / $00 / $01
ent_dy:      !fill MAX_ENT, 0
ent_state:   !fill MAX_ENT, 0     ; per-AI state-machine state (e.g. ai_lurker's rest/dash flag)
ent_timer:   !fill MAX_ENT, 0     ; generic countdown (reaction delay, cooldown)
ent_hp:      !fill MAX_ENT, 0

; spawn_entity parameters
sp_type:     !byte 0
sp_x:        !byte 0
sp_y:        !byte 0

; Zero every slot. Safe to call again to restart the game.
init_entities:
    lda #0
    ldx #MAX_ENT - 1
.ie_loop:
    sta ent_active,x
    dex
    bpl .ie_loop
    rts

; Spawn one entity described by sp_type / sp_x / sp_y.
; Does nothing if the pool is full. Clobbers A, X, Y.
spawn_entity:
    ldx #0
.se_find:
    lda ent_active,x
    beq .se_found
    inx
    cpx #MAX_ENT
    bne .se_find
    rts                     ; pool full
.se_found:
    lda #$01
    sta ent_active,x
    lda sp_type
    sta ent_type,x
    lda sp_x
    sta ent_x,x
    lda sp_y
    sta ent_y,x
    lda #0
    sta ent_moveacc,x
    sta ent_state,x
    sta ent_dy,x
    lda #1
    sta ent_dx,x            ; start heading right
    lda RANDOM              ; stagger decision frames so the herd desyncs
    and #$0f
    sta ent_timer,x
    ldy sp_type
    lda typ_hp,y
    sta ent_hp,x
    lda typ_speed,y
    sta ent_speed,x
    rts

; Weighted 2:2:2:1:1 grunt:chaser:lurker:shooter:swarm. Table length is a
; power of two so "RANDOM and #$07" indexes it with no bias.
wave_types: !byte 0, 0, 1, 1, 2, 2, 3, 4

SPAWN_SAFE_RADIUS = 6   ; keep new spawns at least this far from the player...
SPAWN_MAX_TRIES   = 4   ; ...retrying the roll up to this many times for it

; Returns A=1 if sp_x/sp_y is within SPAWN_SAFE_RADIUS of the player on BOTH
; axes ("too close"), or A=0 if either axis already clears it ("ok to use").
; Clobbers A.
spawn_pos_too_close:
    lda sp_x
    sec
    sbc player_x
    bpl .spc_x_pos
    eor #$ff
    clc
    adc #1                  ; A = abs(sp_x - player_x)
.spc_x_pos:
    cmp #SPAWN_SAFE_RADIUS + 1
    bcs .spc_ok              ; x alone is already far enough
    lda sp_y
    sec
    sbc player_y
    bpl .spc_y_pos
    eor #$ff
    clc
    adc #1                  ; A = abs(sp_y - player_y)
.spc_y_pos:
    cmp #SPAWN_SAFE_RADIUS + 1
    bcs .spc_ok              ; y alone is already far enough
    lda #1                   ; both axes within radius: too close
    rts
.spc_ok:
    lda #0
    rts

; Spawn one entity of a random wave_types type at a random interior position
; (column 4..35, row 4..19), rerolling the position (up to SPAWN_MAX_TRIES
; times) if it lands too close to the player -- so a trickle-in enemy reads
; as "appeared elsewhere and is approaching," not a point-blank ambush.
; Does nothing if the pool is full (spawn_entity's own limit).
; Clobbers A, X, Y.
spawn_random_entity:
    lda RANDOM
    and #$07
    tay
    lda wave_types,y
    sta sp_type

    ldy #SPAWN_MAX_TRIES
.sre_retry:
    lda RANDOM
    and #$1f
    clc
    adc #4
    sta sp_x                ; column 4..35
    lda RANDOM
    and #$0f
    clc
    adc #4
    sta sp_y                ; row 4..19

    jsr spawn_pos_too_close
    beq .sre_use             ; far enough from the player: use it
    dey
    bne .sre_retry           ; out of tries: fall through and use it anyway
.sre_use:
    jsr spawn_entity
    rts

; Opening wave: 20 entities scattered across the play area.
spawn_wave:
    ldx #20
.sw_loop:
    txa
    pha
    jsr spawn_random_entity
    pla
    tax
    dex
    bne .sw_loop
    rts

; --- Spawn director: keeps the population near SPAWN_TARGET_POP after the
;     opening wave, trickling in one replacement at a time as enemies die. ---
SPAWN_TARGET_POP = 20   ; maintain at least this many enemies (MAX_ENT = 32)
SPAWN_INTERVAL   = 30   ; frames between trickle spawns (~0.6s at 50Hz)

spawn_timer: !byte SPAWN_INTERVAL

; Called once per frame from game_tick. Every SPAWN_INTERVAL frames, spawns
; one entity if the active count is below SPAWN_TARGET_POP. Clobbers A, X, Y.
spawn_director:
    dec spawn_timer
    bne .sd_done
    lda #SPAWN_INTERVAL
    sta spawn_timer

    jsr count_active_entities   ; -> A
    cmp #SPAWN_TARGET_POP
    bcs .sd_done                 ; already at or above the floor
    jsr spawn_random_entity
.sd_done:
    rts

; Count active entities. Returns the count in A. Clobbers A, X, Y.
count_active_entities:
    ldy #0
    ldx #0
.cae_loop:
    lda ent_active,x
    beq .cae_next
    iny
.cae_next:
    inx
    cpx #MAX_ENT
    bne .cae_loop
    tya
    rts
