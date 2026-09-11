; Hardware & Kernal constants for Commodore 64

SCROLY      = $d011
RASTER      = $d012

SCROLX      = $d016
VMCSB       = $d018
IRQ_ENABLE  = $d01a
IRQ_STATUS  = $d019

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
