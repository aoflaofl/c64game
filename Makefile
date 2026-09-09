ASM = acme
SRC = src/main.asm
DEPS = src/gamestate.asm src/constants.asm src/zeropage.asm src/input.asm src/player.asm src/irq.asm src/screen.asm src/entity_types.asm src/entities.asm src/entity_ai.asm src/entities.asm src/entity_types.asm src/entity_ai.asm
PRG = build/game.prg

.PHONY: all run clean

all: $(PRG)

$(PRG): $(SRC) $(DEPS)
	mkdir -p build
	$(ASM) $(SRC)

run: $(PRG)
	x64sc -default +drive8truedrive -autostartprgmode 0 $(PRG)

clean:
	rm -f build/*
	rmdir build
