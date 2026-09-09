; --- per-type properties, indexed by ent_type ---
typ_char:    !byte $51, $52, $53, $54, $55
typ_color:   !byte  2,   5,   7,   4,   3
typ_speed:   !byte 32,  96,  16, 128,  48   ; fraction added per tick; cells/tick = n/256
typ_hp:      !byte  1,   3,   2,   1,   5
typ_weapon:  !byte  0,   0,   1,   2,   1   ; index into weapon tables (0 = melee/contact)
typ_aggr:    !byte  0, 255,  64, 180, 128   ; 0=wander … 255=beeline for player
typ_react:   !byte 16,   4,  40,   8,  24   ; frames between decisions
typ_ai_lo:   !byte <ai_grunt,<ai_chaser,<ai_lurker,<ai_shooter,<ai_swarm
typ_ai_hi:   !byte >ai_grunt,>ai_chaser,>ai_lurker,>ai_shooter,>ai_swarm
