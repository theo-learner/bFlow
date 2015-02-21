/*	File:	globals.v	  					*/

/*	Description:	This file includes all the text global macro definitions used in the	 	*/
/*					description of the 56k core.												*/
/*					This file should be included with any other file describing the 56k core.	*/


/*==============================================================================*/

/*-----------------------*/
/* true false definition */
/*-----------------------*/

`define		true			1
`define		false			0


/*-------------*/
/* buses width */
/*-------------*/

`define		databus			23:0			/* data bus width */

`define		addrbus			15:0			/* address bus width */

`define		ext				 7:0			/* accumulator extention portion */

`define		acc				55:0			/* data ALU accumulator width */

`define		rfbus			 1:0			/* register file address width */


/*--------------------*/
/* No. of R registers */
/*--------------------*/

`define		Rfile			0:7				/* 8 R registers exist in the AGU */


/*--------------------*/
/* instruction fields */
/*--------------------*/

`define		opcode			7:0				/* opcode filed in a word instruction */

`define		movefield		23:8			/* the data bus move field in a word instruction */

`define		no_parallel_data_move		16'h2000	/* no parallel data move is required at that instruction */


/*---------------------------*/
/* opcode assignment (8 bit) */
/*---------------------------*/

`define		move			8'h00			/* move */


/*----------------------------*/
/* instructions code (24 bit) */
/*----------------------------*/

`define		NOP				24'h000000		/* a NOP code */
`define		debug			24'h000200		/* enter debug mode */
`define		enddo			24'h00008c		/* end current do loop */
`define		illegal			24'h000005		/* illegal instruction interrupt */
`define		reset			24'h000084		/* reset on-chip peripheral devices */
`define		rti				24'h000004		/* return from interrupt */
`define		rts				24'h00000c		/* return from subroutine */
`define		stop			24'h000087		/* stop instruction processing */
`define		swi				24'h000006		/* software interrupt */


/*------------------*/
/* memory addresses */
/*------------------*/

`define		program_start	16'h0000		/* the address of the first instruction to be exec */


/*-------------------------*/
/* symbolic register names */
/*-------------------------*/

`define		r0				3'b000
`define		r1				3'b001
`define		r2				3'b010
`define		r3				3'b011
`define		r4				3'b100
`define		r5				3'b101
`define		r6				3'b110
`define		r7				3'b111

`define		m0				3'b000
`define		m1				3'b001
`define		m2				3'b010
`define		m3				3'b011
`define		m4				3'b100
`define		m5				3'b101
`define		m6				3'b110
`define		m7				3'b111

`define		n0				3'b000
`define		n1				3'b001
`define		n2				3'b010
`define		n3				3'b011
`define		n4				3'b100
`define		n5				3'b101
`define		n6				3'b110
`define		n7				3'b111


/*------------------------------------------------------*/
/* symbolic data ALU register names for move operations	*/
/*------------------------------------------------------*/

`define		x0				5'b00100
`define		x1				5'b00101
`define		y0				5'b00110
`define		y1				5'b00111
`define		a0				5'b01000
`define		b0				5'b01001
`define		a2				5'b01010
`define		b2				5'b01011
`define		a1				5'b01100
`define		b1				5'b01101
`define		a				5'b01110
`define		b				5'b01111

