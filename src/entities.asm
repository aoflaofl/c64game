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
    jsr grid_init
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
    jsr grid_set
    rts

; Type-mix tiers, tougher as wave_number climbs (see select_wave_tier).
; Weighted, table length a power of two so "RANDOM and #$07" is unbiased.
wave_types_tier0: !byte 0, 0, 1, 1, 2, 2, 3, 4   ; waves 1-2: 2:2:2:1:1 g:c:l:s:sw
wave_types_tier1: !byte 0, 1, 1, 2, 2, 3, 3, 4   ; waves 3-4: fewer grunts
wave_types_tier2: !byte 1, 1, 2, 2, 3, 3, 4, 4   ; waves 5+:  no grunts at all

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

; Spawn one entity of a random type drawn from the current wave's tier (see
; select_wave_tier / WAVE_TYPES_PTR) at a random interior position (column
; 4..35, row 4..19), rerolling the position (up to SPAWN_MAX_TRIES times) if
; it lands too close to the player -- so a spawn reads as "appeared elsewhere
; and is approaching," not a point-blank ambush. Also rerolls occupied cells,
; and gives up on the spawn if it can't find a free one.
; Does nothing if the pool is full (spawn_entity's own limit).
; Clobbers A, X, Y.
spawn_random_entity:
    lda RANDOM
    and #$07
    tay
    lda (WAVE_TYPES_PTR),y
    sta sp_type

    ldx #SPAWN_MAX_TRIES        ; X, not Y: grid_occupied_at_sp clobbers Y
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
    bne .sre_reroll          ; too close to the player
    jsr grid_occupied_at_sp
    beq .sre_use             ; free and far enough from the player: use it
.sre_reroll:
    dex
    bne .sre_retry
    ; Out of tries. Too close to the player is tolerable, but an occupied
    ; cell is not -- enemies never share a cell -- so skip this spawn.
    jsr grid_occupied_at_sp
    bne .sre_skip
.sre_use:
    jsr spawn_entity
.sre_skip:
    rts

; --- Discrete waves: a wave bursts its whole population at once, gets
;     whittled down by the player, and once it's fully cleared, a brief
;     pause leads into the next, bigger and tougher wave. ---
WAVE_POP_BASE     = 20    ; wave 1's population
WAVE_POP_STEP     = 2     ; population growth per wave
WAVE_POP_MAX      = 28    ; cap, leaving headroom under MAX_ENT = 32
WAVE_PAUSE_FRAMES = 100   ; breather between waves (~2s at 50Hz)

wave_number: !byte 1      ; current wave (1-based). Growth assumes this stays
                          ; well under ~100 (see wave_population); a real
                          ; playtest is nowhere near that many waves.
wave_pause:  !byte 0      ; >0 while pausing between waves; 0 = wave active
wave_target: !byte 0      ; this wave's population, stashed across the burst

; Point WAVE_TYPES_PTR at the type-mix tier for the current wave_number.
; Clobbers A.
select_wave_tier:
    lda wave_number
    cmp #5
    bcs .swt_tier2
    cmp #3
    bcs .swt_tier1
    lda #<wave_types_tier0
    sta WAVE_TYPES_PTR
    lda #>wave_types_tier0
    sta WAVE_TYPES_PTR + 1
    rts
.swt_tier1:
    lda #<wave_types_tier1
    sta WAVE_TYPES_PTR
    lda #>wave_types_tier1
    sta WAVE_TYPES_PTR + 1
    rts
.swt_tier2:
    lda #<wave_types_tier2
    sta WAVE_TYPES_PTR
    lda #>wave_types_tier2
    sta WAVE_TYPES_PTR + 1
    rts

; Returns this wave's population target in A: WAVE_POP_BASE plus
; WAVE_POP_STEP per wave past the first, capped at WAVE_POP_MAX.
; Clobbers A, X.
wave_population:
    lda wave_number
    sec
    sbc #1
    tax                        ; X = waves past the first
    lda #WAVE_POP_BASE
    cpx #0
    beq .wp_clamp
.wp_add_loop:
    clc
    adc #WAVE_POP_STEP
    dex
    bne .wp_add_loop
.wp_clamp:
    cmp #WAVE_POP_MAX + 1
    bcc .wp_done
    lda #WAVE_POP_MAX
.wp_done:
    rts

; Begin the current wave_number: select its type-mix tier, compute its
; population target, and burst-spawn that many entities. Clobbers A, X, Y.
start_wave:
    jsr select_wave_tier
    jsr wave_population
    sta wave_target
    ldx wave_target
.stw_loop:
    txa
    pha
    jsr spawn_random_entity
    pla
    tax
    dex
    bne .stw_loop
    rts

; Called once per frame from game_tick. While a wave is active, watches for
; it being fully cleared (no active entities); once cleared, pauses for
; WAVE_PAUSE_FRAMES, then advances wave_number and bursts the next wave.
; Clobbers A, X, Y.
spawn_director:
    lda wave_pause
    beq .sd_active
    dec wave_pause
    bne .sd_done
    inc wave_number
    jsr draw_wave
    jsr start_wave
    rts
.sd_active:
    jsr count_active_entities
    bne .sd_done               ; still enemies alive: wave in progress
    lda #WAVE_PAUSE_FRAMES
    sta wave_pause
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
