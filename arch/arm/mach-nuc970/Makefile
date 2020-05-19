#
# Makefile for the linux kernel.
#

# Object file lists.

obj-y				:= irq.o clk-ccf.o clk-apll.o clk-upll.o cpu.o mfp.o mach-nuc970.o pm.o suspend.o
ifeq ($(CONFIG_BOARD_DISP977),y)
obj-y				+= dev-disp977.o
NUC970_SPECIFIC_DEV = y
endif

ifeq ($(CONFIG_BOARD_LAN977),y)
obj-y				+= dev-lan977.o
NUC970_SPECIFIC_DEV = y
endif

ifeq ($(CONFIG_BOARD_BIODISP),y)
obj-y				+= dev-biodisp.o
NUC970_SPECIFIC_DEV = y
endif

ifeq ($(CONFIG_BOARD_BIOLAN),y)
obj-y				+= dev-biolan.o
NUC970_SPECIFIC_DEV = y
endif

ifneq ($(NUC970_SPECIFIC_DEV),y)
obj-y				+= dev.o
endif
NUC970_SPECIFIC_DEV =

obj-$(CONFIG_NUC970_CLK_TIMER)	+= time.o
obj-$(CONFIG_NUC970_CLK_ETIMER)	+= etime.o
obj-$(CONFIG_NUC970_FIQ)	+= fiq.o
obj-$(CONFIG_OF)		+= dt-nuc972-evb.o

