ASM = acme
SRC = src/main.asm
DEPS = src/timing.asm src/random.asm src/hardware.asm src/zeropage.asm src/joystick.asm src/player.asm src/raster_irq.asm src/video.asm src/entity_types.asm src/entities.asm src/enemy_ai.asm src/projectiles.asm src/collision.asm src/renderer.asm
PRG = build/game.prg

.PHONY: all run clean

all: $(PRG)

$(PRG): $(SRC) $(DEPS)
	mkdir -p build
	$(ASM) $(SRC)

run: $(PRG)
	x64sc -default +drive8truedrive -autostartprgmode 0 $(PRG)

clean:
	rm -rf build/*
