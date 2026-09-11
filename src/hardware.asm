; Hardware & Kernal constants for Commodore 64

SCROLY      = $d011
RASTER      = $d012

SCROLX      = $d016
VMCSB       = $d018
IRQ_ENABLE  = $d01a
IRQ_STATUS  = $d019

COLOR_BLACK   = $00
COLOR_WHITE   = $01
COLOR_RED     = $02
COLOR_CYAN    = $03
COLOR_PURPLE  = $04
COLOR_GREEN   = $05
COLOR_BLUE    = $06
COLOR_YELLOW  = $07
COLOR_ORANGE  = $08
COLOR_BROWN   = $09
COLOR_LIGHT_RED = $0a
COLOR_DARK_GREY = $0b
COLOR_GREY    = $0c
COLOR_LIGHT_GREEN = $0d
COLOR_LIGHT_BLUE  = $0e
COLOR_LIGHT_GREY  = $0f

BORDER      = $d020
BACKGROUND  = $d021
SCREEN_RAM  = $0400
COLOR_RAM   = $d800

CIAPRA      = $dc00
CIA_ICR     = $dc0d

KERNEL_IRQ_CLEANUP = $ea7e

FREHI3 = $d40f ; Voice 3 frequency control register (high byte)
VCREG3 = $d412 ; Voice 3 control register
SIGVOL = $d418 ; Volume and filter select register
RANDOM = $d41b ; Oscillator 3/random number generator
