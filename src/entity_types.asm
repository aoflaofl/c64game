; --- per-type properties, indexed by ent_type ---
;
; Column order (index : name : personality):
;   0 : grunt   - wanders randomly, never chases (aggr 0). Slow, harmless
;                 filler that pads out a wave.
;   1 : chaser  - almost always beelines straight for the player (aggr 255)
;                 and re-aims often (react 4). The most aggressive melee type.
;   2 : lurker  - holds still until it shares a row or column with the
;                 player, then dashes across at a burst speed (see
;                 LURKER_DASH_SPEED in enemy_ai.asm), dropping back to its
;                 resting speed the moment alignment breaks.
;   3 : shooter - wanders/chases like grunt/chaser (aggr 180), and
;                 independently fires a shot whenever it's aligned with the
;                 player on a row or column (see ai_shooter/shooter_try_fire).
;   4 : swarm   - wanders/chases with a roughly 50/50 blend (aggr 128); looks
;                 like a flock only because several spawn together, not from
;                 true neighbor-flocking (not implemented).
typ_char:    !byte $51, $52, $53, $54, $55
typ_color:   !byte  2,   5,   7,   4,   3
; Player moves 1 cell / 3 frames = ~85 (cells/sec = n/5.12; player is ~16.7).
; Every type now sits below player speed so a straight chase can be outrun.
typ_speed:   !byte 32,  64,  16,  64,  40   ; fraction added per tick; cells/tick = n/256
typ_hp:      !byte  1,   1,   1,   1,   1   ; one-shot for now; wounding comes later
typ_weapon:  !byte  0,   0,   1,   2,   1   ; index into weapon tables (0 = melee/contact) - For future expansion
typ_aggr:    !byte  0, 255,  64, 180, 128   ; 0=wander … 255=beeline for player (read by ai_wander_or_chase)
typ_react:   !byte 16,   4,  40,   8,  24   ; frames between decisions
; grunt, chaser, and swarm all share ai_wander_or_chase; typ_aggr is what
; makes them behave differently (0 = always wander .. 255 = almost always chase).
typ_ai_lo:   !byte <ai_wander_or_chase,<ai_wander_or_chase,<ai_lurker,<ai_shooter,<ai_wander_or_chase
typ_ai_hi:   !byte >ai_wander_or_chase,>ai_wander_or_chase,>ai_lurker,>ai_shooter,>ai_wander_or_chase
