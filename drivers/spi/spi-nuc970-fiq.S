/* linux/drivers/spi/spi_nuc970_fiq.S
 *
 * Copyright 2009 Simtec Electronics
 *	Ben Dooks <ben@simtec.co.uk>
 *
 * NUC970 SPI - FIQ pseudo-DMA transfer code
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
*/

#include <linux/linkage.h>
#include <asm/assembler.h>

#include "spi-nuc970-fiq.h"

/* SPI registers */
#define SPI_CNTRL		0x00
#define SPI_DIVIDER		0x04
#define SPI_SSR			0x08
#define SPI_RX0			0x10
#define SPI_TX0			0x10
#define SPI_RX1			0x14
#define SPI_TX1			0x14
#define SPI_RX2			0x18
#define SPI_TX2			0x18
#define SPI_RX3			0x1C
#define SPI_TX3			0x1C

/* AIC registers */
#define AIC_IPER		0x118
#define AIC_EOSCR		0x150

	.text

	@ entry to these routines is as follows, with the register names
	@ defined in fiq.h so that they can be shared with the C files which
	@ setup the calling registers.
	@
	@ fiq_rirq	The base of the IRQ registers to find S3C2410_SRCPND
	@ fiq_rtmp	Temporary register to hold tx/rx data
	@ fiq_rspi	The base of the SPI register block
	@ fiq_rtx	The tx buffer pointer
	@ fiq_rrx	The rx buffer pointer
	@ fiq_rcount	The number of bytes to move

	@ each entry starts with a word entry of how long it is
	@ and an offset to the irq acknowledgment word

ENTRY(nuc970_spi_fiq_rx_8)
nuc970_spi_fiq_rx_8:
	.word	fiq_rx_8_end - fiq_rx_8_start
	.word	fiq_rx_8_irq_mask - fiq_rx_8_start
	.word	fiq_rx_8_irq_reg - fiq_rx_8_start
fiq_rx_8_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1

	@ put fill data to SPI
	mvn	fiq_rtmp, #0
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_rx_8_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_rx_8_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_rx_8_irq_mask:
	.word	0
fiq_rx_8_irq_reg:
	.word	0
fiq_rx_8_end:

ENTRY(nuc970_spi_fiq_txrx_8)
nuc970_spi_fiq_txrx_8:
	.word	fiq_txrx_8_end - fiq_txrx_8_start
	.word	fiq_txrx_8_irq_mask - fiq_txrx_8_start
	.word	fiq_txrx_8_irq_reg - fiq_txrx_8_start
fiq_txrx_8_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	strb	fiq_rtmp, [ fiq_rrx ], #1

	@ put four data items from buffer to SPI
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_txrx_8_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_txrx_8_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_txrx_8_irq_mask:
	.word	0
fiq_txrx_8_irq_reg:
	.word	0
fiq_txrx_8_end:

ENTRY(nuc970_spi_fiq_tx_8)
nuc970_spi_fiq_tx_8:
	.word	fiq_tx_8_end - fiq_tx_8_start
	.word	fiq_tx_8_irq_mask - fiq_tx_8_start
	.word	fiq_tx_8_irq_reg - fiq_tx_8_start
fiq_tx_8_start:

	@ put four data items from buffer to SPI
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldrb	fiq_rtmp, [ fiq_rtx ], #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_tx_8_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_tx_8_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_tx_8_irq_mask:
	.word	0
fiq_tx_8_irq_reg:
	.word	0
fiq_tx_8_end:


ENTRY(nuc970_spi_fiq_rx_16)
nuc970_spi_fiq_rx_16:
	.word	fiq_rx_16_end - fiq_rx_16_start
	.word	fiq_rx_16_irq_mask - fiq_rx_16_start
	.word	fiq_rx_16_irq_reg - fiq_rx_16_start
fiq_rx_16_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2

	@ put fill data to SPI
	mvn	fiq_rtmp, #0
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_rx_16_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_rx_16_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_rx_16_irq_mask:
	.word	0
fiq_rx_16_irq_reg:
	.word	0
fiq_rx_16_end:

ENTRY(nuc970_spi_fiq_txrx_16)
nuc970_spi_fiq_txrx_16:
	.word	fiq_txrx_16_end - fiq_txrx_16_start
	.word	fiq_txrx_16_irq_mask - fiq_txrx_16_start
	.word	fiq_txrx_16_irq_reg - fiq_txrx_16_start
fiq_txrx_16_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	strh	fiq_rtmp, [ fiq_rrx ], #2

	@ put four data items from buffer to SPI
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_txrx_16_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_txrx_16_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_txrx_16_irq_mask:
	.word	0
fiq_txrx_16_irq_reg:
	.word	0
fiq_txrx_16_end:

ENTRY(nuc970_spi_fiq_tx_16)
nuc970_spi_fiq_tx_16:
	.word	fiq_tx_16_end - fiq_tx_16_start
	.word	fiq_tx_16_irq_mask - fiq_tx_16_start
	.word	fiq_tx_16_irq_reg - fiq_tx_16_start
fiq_tx_16_start:

	@ put four data items from buffer to SPI
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldrh	fiq_rtmp, [ fiq_rtx ], #2
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_tx_16_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_tx_16_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_tx_16_irq_mask:
	.word	0
fiq_tx_16_irq_reg:
	.word	0
fiq_tx_16_end:



ENTRY(nuc970_spi_fiq_rx_32)
nuc970_spi_fiq_rx_32:
	.word	fiq_rx_32_end - fiq_rx_32_start
	.word	fiq_rx_32_irq_mask - fiq_rx_32_start
	.word	fiq_rx_32_irq_reg - fiq_rx_32_start
fiq_rx_32_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	str	fiq_rtmp, [ fiq_rrx ], #4

	@ put fill data to SPI
	mvn	fiq_rtmp, #0
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_rx_32_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_rx_32_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_rx_32_irq_mask:
	.word	0
fiq_rx_32_irq_reg:
	.word	0
fiq_rx_32_end:

ENTRY(nuc970_spi_fiq_txrx_32)
nuc970_spi_fiq_txrx_32:
	.word	fiq_txrx_32_end - fiq_txrx_32_start
	.word	fiq_txrx_32_irq_mask - fiq_txrx_32_start
	.word	fiq_txrx_32_irq_reg - fiq_txrx_32_start
fiq_txrx_32_start:

	@ get four data items from SPI to buffer
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX0 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX1 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX2 ]
	str	fiq_rtmp, [ fiq_rrx ], #4
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_RX3 ]
	str	fiq_rtmp, [ fiq_rrx ], #4

	@ put four data items from buffer to SPI
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_txrx_32_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_txrx_32_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_txrx_32_irq_mask:
	.word	0
fiq_txrx_32_irq_reg:
	.word	0
fiq_txrx_32_end:

ENTRY(nuc970_spi_fiq_tx_32)
nuc970_spi_fiq_tx_32:
	.word	fiq_tx_32_end - fiq_tx_32_start
	.word	fiq_tx_32_irq_mask - fiq_tx_32_start
	.word	fiq_tx_32_irq_reg - fiq_tx_32_start
fiq_tx_32_start:

	@ put four data items from buffer to SPI
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX0 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX1 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX2 ]
	ldr	fiq_rtmp, [ fiq_rtx ], #4
	str	fiq_rtmp, [ fiq_rspi, # SPI_TX3 ]

	@ clear IF and set GO_BUSY to start next SPI operation
	ldr	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]
	orr	fiq_rtmp, fiq_rtmp, #1
	str	fiq_rtmp, [ fiq_rspi, # SPI_CNTRL ]

	@ decrement counter
	subs	fiq_rcount, fiq_rcount, #4

	@ clear AIC interrupt line
	ldr	fiq_rtmp, [ fiq_rirq, # AIC_IPER ]
	str	fiq_rtmp, [ fiq_rirq, # AIC_EOSCR ]

	@ have more work, so return
	subnes	pc, lr, #4

	@ no data anymore, switching to IRQ mode

	@ construct pointer to one of AIC_SCRx into fiq_rirq
	@ we can trash registers here, because work is done
	ldr	fiq_rirq, fiq_tx_32_irq_reg
	@ apply mask
	ldr	fiq_rcount, fiq_tx_32_irq_mask
	ldr	fiq_rtmp, [ fiq_rirq ]
	orr	fiq_rtmp, fiq_rcount
	str	fiq_rtmp, [ fiq_rirq ]

	@ done
	subs	pc, lr, #4

fiq_tx_32_irq_mask:
	.word	0
fiq_tx_32_irq_reg:
	.word	0
fiq_tx_32_end:


	.end
