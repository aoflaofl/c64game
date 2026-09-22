ASM = acme
ifdef PROFILE
ASMFLAGS = -DPROFILE=1
endif
SRC = src/main.asm
DEPS = src/timing.asm src/random.asm src/hardware.asm src/zeropage.asm src/joystick.asm src/player.asm src/raster_irq.asm src/video.asm src/entity_types.asm src/entities.asm src/enemy_ai.asm src/projectiles.asm src/collision.asm src/renderer.asm src/hud.asm src/game_state.asm src/prof.asm
PRG = build/game.prg

.PHONY: all run clean

all: $(PRG)

$(PRG): $(SRC) $(DEPS)
	mkdir -p build
	$(ASM) $(ASMFLAGS) $(SRC)

run: $(PRG)
	x64sc +drive8truedrive -autostartprgmode 0 $(PRG)

clean:
	rm -rf build/*
