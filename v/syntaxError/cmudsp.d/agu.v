/*-------------*/
/* buses width */
/*-------------*/

`define		databus			23:0			/* data bus width */

`define		addrbus			15:0			/* address bus width */

`define		ext				 7:0			/* accumulator extention portion */

`define		acc				55:0			/* data ALU accumulator width */

`define		rfbus			 1:0			/* register file address width */

/*	File:	agu.v	  					*/

/*	module name: agu					*/

/*	Description: Address Generation Unit for the 56k core.	*/

/* Author: Nitzan Weinberg */

/*==============================================================================*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	agu																	*/
/*																				*/
/********************************************************************************/

module agu (
	reset,
	PDB,
	GDB,
	REPEAT,
	E,
	U,
	Z,
	PAB,
	XAB,
	YAB,
	XWRITE,
	XREAD,
	YWRITE,
	YREAD,
	C,
	J,
	Clk
	);


/*==============================================================================*/
/*============	I/O direction	================================================*/
/*==============================================================================*/

input  reset;
input [`databus] PDB;

inout [`databus] GDB;

input REPEAT;
input E;
input U;
input Z;

output [`addrbus] PAB;
output [`addrbus] XAB;
output [`addrbus] YAB;
output XWRITE;
output XREAD;
output YWRITE;
output YREAD;
output C;
output J;

input  Clk;


/*==============================================================================*/
/*============		I/O type	================================================*/
/*=============================================================================*/

wire reset;

wire [`databus] PDB;	/* Program data bus (instruction) */
wire [`databus] GDB;	/* General internal data bus */

wire REPEAT;			/* REP instruction signal coming from the PCU */
wire E;					/* comes from the data alu during a NORM instruction */
wire U;					/* comes from the data alu during a NORM instruction */
wire Z;					/* comes from the data alu during a NORM instruction */

reg [`addrbus] PAB;		/* Program address bus */
reg [`addrbus] XAB;		/* X data memory address bus */
reg [`addrbus] YAB;		/* Y data memory address bus */

reg XWRITE;				/* X data memory write enable. When TRUE, the core is driving the XDB bus. */
reg XREAD;				/* X data memory read enable.  When TRUE, the X memory is driving the XDB bus. */
reg YWRITE;				/* Y data memory write enable. When TRUE, the core is driving the YDB bus. */
reg YREAD;				/* Y data memory read enable.  When TRUE, the Y memory is driving the YDB bus. */

reg C;					/* Generated for test bit inst. and passed to the data_alu during stage 3 */
reg J;					/* Generated for jump according to test bit inst. and passed to the PCU during stage 3 */

wire Clk;


/*=============================================================================*/
/*===========	Internal Nets	===============================================*/
/*=============================================================================*/

/*----------------------------------------------------------------------------------*/
/* fetched instruction coming from the PDB, and passed on along the pipeline stages */
/*----------------------------------------------------------------------------------*/

reg  [`databus] pdb2;	/* for pipeline stage 2 */
reg  [`databus] pdb3;	/* for pipeline stage 3 */


/*-------------------------------------------------------*/
/* X, Y and P memory address buses - internal to the AGU */
/*-------------------------------------------------------*/

reg [`addrbus] xab_2;			/* X address bus - from stage 2 (Decode) */
reg [`addrbus] xab_3;			/* X address bus - from stage 3 (Execute) */
reg [`addrbus] Xab;				/* X address bus - the input into the XAB register */

reg [`addrbus] yab_2;			/* Y address bus - from stage 2 (Decode) */
reg [`addrbus] yab_3;			/* Y address bus - from stage 3 (Execute) */
reg [`addrbus] Yab;				/* Y address bus - the input into the YAB register */

reg [`addrbus] PAB_2;			/* P Address bus - from stage 2 (Decode) */


/*------------------------------------------------------*/
/* X, Y memory read/write control - internal to the AGU */
/*------------------------------------------------------*/

reg xwrite_2;		/* write enable to the X data memory - from stage 2 (Decode) */
reg xwrite_3;		/* write enable to the X data memory - from stage 3 (Execute) */

reg xread_2;		/* read enable from the X data memory - in stage 2 (Decode) */
reg xread_3;		/* read enable from the X data memory - in stage 3 (Execute) */

reg ywrite_2;		/* write enable to the Y data memory - from stage 2 (Decode) */
reg ywrite_3;		/* write enable to the Y data memory - from stage 3 (Execute) */

reg yread_2;		/* read enable from the Y data memory - in stage 2 (Decode) */
reg yread_3;		/* read enable from the Y data memory - in stage 3 (Execute) */

reg PABwrite_2;		/* write program address bus - in stage 2 */

reg Xwrite;			/* The input to the write-enable XWRITE FF */
reg Xread;			/* The input to the read-enable  XREAD FF */

reg Ywrite;			/* The input to the write-enable YWRITE FF */
reg Yread;			/* The input to the read-enable  YREAD FF */

/*---------------------------------------------------------------------*/
/* The GDB output data bus and drive-control from the agu logic unit   */
/*---------------------------------------------------------------------*/

reg [`databus] gdb_out;			/* the AGU gdb output which is the input to the GDB_out register - from stage 2 */

reg [`databus] GDB_out;			/* register - the AGU gdb output that can drive the GDB bus */

reg gdb_write;					/* GDB_out write control - from stage 2 */

reg GDB_write;					/* FF - a write enable to the GDB bus */


/*--------------------------------------------------------------------------------------------------*/
/*	atomic flag and atomic-write enable																*/
/*																									*/
/*	The flag stays true as long as an atomic instrucion is being executed (BCLR, BSET, STST).		*/
/*	It prevents any other instruction from accessing the address and data buses that are			*/
/*	being used by the ongoing atomic instruction. Other requests for these buses are ignored		*/
/*	while the atomic instruction is being processed. This includes a newer atomic instruction		*/
/*	that arrives after the one that is still being executed.										*/
/*--------------------------------------------------------------------------------------------------*/

reg Xatomic;		/* Flag - signals that an atomic instruction that is using the XAB and XDB buses is in progress. */
reg xread_atomic;	/* read enable from the X data memory - generated by an atomic instruction in stage 2 */
reg xwrite_atomic;	/* write enable to the X data memory - generated by an atomic instruction in stage 3 */

reg Yatomic;		/* Flag - signals that an atomic instruction that is using the YAB and YDB buses is in progress. */
reg yread_atomic;	/* read enable from the Y data memory - generated by an atomic instruction in stage 2 */
reg ywrite_atomic;	/* write enable to the Y data memory - generated by an atomic instruction in stage 3 */


/*----------------------------------------*/
/* R register-files		Control and buses */
/*----------------------------------------*/

/* High */

wor [`addrbus] Rin1_H;			/* input bus into the High R */
reg [`addrbus] Rin1_H_2;		/* input bus into the High R from stage 2 */

wor [`addrbus] Rin2_H;			/* input bus into the High R */
reg [`addrbus] Rin2_H_3;		/* input bus into the High R from stage 3 */

wire [`addrbus] Rout1_H;		/* output bus 1 from the High R */
wire [`addrbus] Rout2_H;		/* output bus 2 from the High R */
wire [`addrbus] Rout3_H;		/* output bus 3 from the High R */

wor [`rfbus] Rraddr1_H;			/* the read  address from High R */
reg [`rfbus] Rraddr1_H_2;		/* the read  address from High R from stage 2 */

wor [`rfbus] Rraddr2_H;			/* the read  address from High R */
reg [`rfbus] Rraddr2_H_3;		/* the read  address from High R from stage 3 */

wor [`rfbus] Rraddr3_H;			/* the read  address from High R */
reg [`rfbus] Rraddr3_H_2;		/* the read  address from High R from stage 2 (for MOVE (X: or Y:) and (X:Y:) inst.) */

wor [`rfbus] Rwaddr1_H;			/* the write address from High R */
reg [`rfbus] Rwaddr1_H_2;		/* the write address from High R from stage 2 */

wor [`rfbus] Rwaddr2_H;			/* the write address from High R */
reg [`rfbus] Rwaddr2_H_3;		/* the write address from High R from stage 3 */

reg Rwrite1_H;					/* write enable into High R */
reg Rwrite1_H_2;				/* write enable into High R from stage 2 */

wor Rwrite2_H;					/* write enable into High R */
reg Rwrite2_H_3;				/* write enable into High R from stage 3 */


/* Low */

wor [`addrbus] Rin1_L;			/* input bus into the Low  R */
reg [`addrbus] Rin1_L_2;		/* input bus into the Low  R from stage 2 */

wor [`addrbus] Rin2_L;			/* input bus into the Low  R */
reg [`addrbus] Rin2_L_3;		/* input bus into the Low  R from stage 3 */

wire [`addrbus] Rout1_L;		/* output bus 1 from the Low  R */
wire [`addrbus] Rout2_L;		/* output bus 2 from the Low  R */
wire [`addrbus] Rout3_L;		/* output bus 3 from the Low  R */

wor [`rfbus] Rraddr1_L;			/* the read  address from Low  R */
reg [`rfbus] Rraddr1_L_2;		/* the read  address from Low  R from stage 2 */

wor [`rfbus] Rraddr2_L;			/* the read  address from Low  R */
reg [`rfbus] Rraddr2_L_3;		/* the read  address from Low  R from stage 3 */

wor [`rfbus] Rraddr3_L;			/* the read  address from Low R */
reg [`rfbus] Rraddr3_L_2;		/* the read  address from Low R from stage 2 (for MOVE (X: or Y:) and (X:Y:) inst.) */

wor [`rfbus] Rwaddr1_L;			/* the write address from Low  R */
reg [`rfbus] Rwaddr1_L_2;		/* the write address from Low  R from stage 2 */

wor [`rfbus] Rwaddr2_L;			/* the write address from Low  R */
reg [`rfbus] Rwaddr2_L_3;		/* the write address from Low  R from stage 3 */

reg Rwrite1_L;					/* write enable into Low  R */
reg Rwrite1_L_2;				/* write enable into Low  R from stage 2 */

wor Rwrite2_L;					/* write enable into Low  R */
reg Rwrite2_L_3;				/* write enable into Low  R from stage 3 */


/*----------------------------------------*/
/* N register-files		Control and buses */
/*----------------------------------------*/

/* High */

wor [`addrbus] Nin1_H;			/* input bus into the High N */
reg [`addrbus] Nin1_H_2;		/* input bus into the High N from stage 2 */

wor [`addrbus] Nin2_H;			/* input bus into the High N */
reg [`addrbus] Nin2_H_3;		/* input bus into the High N from stage 3 */

wire [`addrbus] Nout1_H;		/* output bus 1 from the High N */
wire [`addrbus] Nout2_H;		/* output bus 2 from the High N */
wire [`addrbus] Nout3_H;		/* output bus 3 from the High N */

wor [`rfbus] Nraddr1_H;			/* the read  address from High N */
reg [`rfbus] Nraddr1_H_2;		/* the read  address from High N from stage 2 */

wor [`rfbus] Nraddr2_H;			/* the read  address from High N */
reg [`rfbus] Nraddr2_H_3;		/* the read  address from High N from stage 3 */

wor [`rfbus] Nraddr3_H;			/* the read  address from High N */
reg [`rfbus] Nraddr3_H_2;		/* the read  address from High N from stage 2 (for MOVE X: or Y:) */

wor [`rfbus] Nwaddr1_H;			/* the write address from High N */
reg [`rfbus] Nwaddr1_H_2;		/* the write address from High N from stage 2 */

wor [`rfbus] Nwaddr2_H;			/* the write address from High N */
reg [`rfbus] Nwaddr2_H_3;		/* the write address from High N from stage 3 */

reg Nwrite1_H;					/* write enable into High N */
reg Nwrite1_H_2;				/* write enable into High N from stage 2 */

wor Nwrite2_H;					/* write enable into High N */
reg Nwrite2_H_3;				/* write enable into High N from stage 3 */


/* Low  */

wor [`addrbus] Nin1_L;			/* input bus into the Low  N */
reg [`addrbus] Nin1_L_2;		/* input bus into the Low  N from stage 2 */

wor [`addrbus] Nin2_L;			/* input bus into the Low  N */
reg [`addrbus] Nin2_L_3;		/* input bus into the Low  N from stage 3 */

wire [`addrbus] Nout1_L;		/* output bus 1 from the Low  N */
wire [`addrbus] Nout2_L;		/* output bus 2 from the Low  N */
wire [`addrbus] Nout3_L;		/* output bus 3 from the Low  N */

wor [`rfbus] Nraddr1_L;			/* the read  address from Low  N */
reg [`rfbus] Nraddr1_L_2;		/* the read  address from Low  N from stage 2 */

wor [`rfbus] Nraddr2_L;			/* the read  address from Low  N */
reg [`rfbus] Nraddr2_L_3;		/* the read  address from Low  N from stage 3 */

wor [`rfbus] Nraddr3_L;			/* the read  address from Low  N */
reg [`rfbus] Nraddr3_L_2;		/* the read  address from Low  N from stage 2 (for MOVE X: or Y:) */

wor [`rfbus] Nwaddr1_L;			/* the write address from Low  N */
reg [`rfbus] Nwaddr1_L_2;		/* the write address from Low  N from stage 2 */

wor [`rfbus] Nwaddr2_L;			/* the write address from Low  N */
reg [`rfbus] Nwaddr2_L_3;		/* the write address from Low  N from stage 3 */

reg Nwrite1_L;					/* write enable into Low  N */
reg Nwrite1_L_2;				/* write enable into Low  N from stage 2 */

wor Nwrite2_L;					/* write enable into Low  N */
reg Nwrite2_L_3;				/* write enable into Low  N from stage 3 */


/*----------------------------------------*/
/* M register-files		Control and buses */
/*----------------------------------------*/

/* High */

wor [`addrbus] Min1_H;			/* input bus into the High M */
reg [`addrbus] Min1_H_2;		/* input bus into the High M, coming from stage 2 */

wor [`addrbus] Min2_H;			/* input bus into the High M */
reg [`addrbus] Min2_H_3;		/* input bus into the High M, coming from stage 3 */

wire [`addrbus] Mout1_H;		/* output bus 1 from the High M */
wire [`addrbus] Mout2_H;		/* output bus 2 from the High M */
wire [`addrbus] Mout3_H;		/* output bus 3 from the High M */

wor [`rfbus] Mraddr1_H;			/* the read  address port 1 from High M */
reg [`rfbus] Mraddr1_H_2;		/* the read  address port 1 from High M, coming from stage 2 */

wor [`rfbus] Mraddr2_H;			/* the read  address port 2 from High M */
reg [`rfbus] Mraddr2_H_3;		/* the read  address port 2 from High M, coming from stage 3 */

wor [`rfbus] Mraddr3_H;			/* the read  address port 3 from High M */
reg [`rfbus] Mraddr3_H_2;		/* the read  address port 3 from High M, coming from stage 2 (the source in MOVEC class I and II) */

wor [`rfbus] Mwaddr1_H;			/* the write address from High M */
reg [`rfbus] Mwaddr1_H_2;		/* the write address from High M, coming from stage 2 */

wor [`rfbus] Mwaddr2_H;			/* the write address from High M */
reg [`rfbus] Mwaddr2_H_3;		/* the write address from High M, coming from stage 3 */

reg Mwrite1_H;					/* write enable into High M */
reg Mwrite1_H_2;				/* write enable into High M, coming from stage 2 */

wor Mwrite2_H;					/* write enable into High M */
reg Mwrite2_H_3;				/* write enable into High M, coming from stage 3 */


/* Low */

wor [`addrbus] Min1_L;			/* input bus into the Low  M */
reg [`addrbus] Min1_L_2;		/* input bus into the Low  M, coming from stage 2 */

wor [`addrbus] Min2_L;			/* input bus into the Low  M */
reg [`addrbus] Min2_L_3;		/* input bus into the Low  M, coming from stage 3 */

wire [`addrbus] Mout1_L;		/* output bus 1 from the Low  M */
wire [`addrbus] Mout2_L;		/* output bus 2 from the Low  M */
wire [`addrbus] Mout3_L;		/* output bus 3 from the Low  M */

wor [`rfbus] Mraddr1_L;			/* the read  address port 1 from Low  M */
reg [`rfbus] Mraddr1_L_2;		/* the read  address port 1 from Low  M, coming from stage 2 */

wor [`rfbus] Mraddr2_L;			/* the read  address port 2 from Low  M */
reg [`rfbus] Mraddr2_L_3;		/* the read  address port 2 from Low  M, coming from stage 3 */

wor [`rfbus] Mraddr3_L;			/* the read  address port 3 from Low  M */
reg [`rfbus] Mraddr3_L_2;		/* the read  address port 3 from Low  M, coming from stage 2 (the source in MOVEC class I and II) */

wor [`rfbus] Mwaddr1_L;			/* the write address from Low  M */
reg [`rfbus] Mwaddr1_L_2;		/* the write address from Low  M, coming from stage 2 */

wor [`rfbus] Mwaddr2_L;			/* the write address from Low  M */
reg [`rfbus] Mwaddr2_L_3;		/* the write address from Low  M, coming from stage 3 */

reg Mwrite1_L;					/* write enable into Low  M */
reg Mwrite1_L_2;				/* write enable into Low  M, coming from stage 3 */

wor Mwrite2_L;					/* write enable into Low  M */
reg Mwrite2_L_3;				/* write enable into Low  M, coming from stage 3 */


/*------------------------------------------------------------------------------------------------------*/
/* A flag  - when true signals that a source's absolute memory address or an immediate data is used.	*/
/* Such a use required TWO instruction words: The instruction and the absolute address/immediate data.	*/
/*------------------------------------------------------------------------------------------------------*/

reg absolute;		/* changed in stage 2 to signal an absolute DESTINATION address in a TWO word instruction.	*/
					/* Is used to nullify pdb2 when the address arrives on PDB and as a write permit of the		*/
					/* destination address onto the X or Y address buses.										*/
					
reg immediate;		/* changed in stage 2 to signal an immediate data in a TWO word instruction. */
					/* Is used to nullify pdb2 when the address arrives on PDB and write data into registers. */

reg absolute_jump;	/* changed in stage 2 to signal an absolute JUMP address in a TWO word instruction. */
					/* Is used to nullify pdb2 when the address arrives on PDB. */


/*----------------------------------------------*/
/*----------------------------------------------*/
/* aux R registers for testing purposes only.	*/
/*----------------------------------------------*/
/*----------------------------------------------*/

reg [`addrbus] R0;
reg [`addrbus] R1;
reg [`addrbus] R2;
reg [`addrbus] R3;
reg [`addrbus] R4;
reg [`addrbus] R5;
reg [`addrbus] R6;
reg [`addrbus] R7;


/*----------------------------------------------*/
/*----------------------------------------------*/


/*==============================================================================================*/
/*																								*/
/*	Functions								Functions							Functions		*/
/*																								*/
/*==============================================================================================*/

/*--------------------------------------------------------------------------------------*/
/*																						*/
/*	function:	bit_test																*/
/*																						*/
/*	Tests a bit in a register and sets or clears it.									*/
/*	To be use with atomic instructions: BCLR, BSET										*/
/* 	Returns: {The value of the tested bit (1 bit), The updated register value (16 bit)}	*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

function [16:0] bit_test;

input [`addrbus] source;	/* The register to be tested */ 
input [4:0] bit;			/* Designates what bit to test */
input set_clear;			/* if equals one - set a bit, if zero - clear a bit */

	begin
		case (bit)		/* choose the bit to be tested and cleared */
			5'b00000	:	bit_test = {source[0],  source[15:1],  set_clear};
			5'b00001	:	bit_test = {source[1],  source[15:2],  set_clear, source[0]};
			5'b00010	:	bit_test = {source[2],  source[15:3],  set_clear, source[1:0]};
			5'b00011	:	bit_test = {source[3],  source[15:4],  set_clear, source[2:0]};
			5'b00100	:	bit_test = {source[4],  source[15:5],  set_clear, source[3:0]};
			5'b00101	:	bit_test = {source[5],  source[15:6],  set_clear, source[4:0]};
			5'b00110	:	bit_test = {source[6],  source[15:7],  set_clear, source[5:0]};
			5'b00111	:	bit_test = {source[7],  source[15:8],  set_clear, source[6:0]};
			5'b01000	:	bit_test = {source[8],  source[15:9],  set_clear, source[7:0]};
			5'b01001	:	bit_test = {source[9],  source[15:10], set_clear, source[8:0]};
			5'b01010	:	bit_test = {source[10], source[15:11], set_clear, source[9:0]};
			5'b01011	:	bit_test = {source[11], source[15:12], set_clear, source[10:0]};
			5'b01100	:	bit_test = {source[12], source[15:13], set_clear, source[11:0]};
			5'b01101	:	bit_test = {source[13], source[15:14], set_clear, source[12:0]};
			5'b01110	:	bit_test = {source[14], source[15],    set_clear, source[13:0]};
			5'b01111	:	bit_test = {source[15],                set_clear, source[14:0]};
			default		:	;		/* No Action */
		endcase		/* bit */
	end


endfunction		/* bit_test */



/*--------------------------------------------------------------------------------------*/
/*																						*/
/*	function:	mod																		*/
/*																						*/
/*	Performs modulo addressing as specified by the modifier registers (M).				*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

function [`addrbus] mod;

input [`addrbus] linear;	/* The linear address calculated according to the address mode specified in the instruction */ 
input [`addrbus] R;			/* address register before calculating the linear address */
input [`addrbus] M;			/* The address modifier register that is invloved in the address calculation */

reg [`addrbus] lower;		/* The lower address in the modulo region */
reg [`addrbus] upper;		/* The upper address in the modulo region (in use for a wrap-around-once mode) */



	begin
		if ( (M >= 16'h0001) && (M <= 16'h7fff) )
			begin	/*------------------*/
					/* wrap around ONCE */
					/*------------------*/
					
				/* lower & upper addresses */
				/*-------------------------*/
				/* Calculate the lower boundary of the memory region for the modulo operation */
				/* based on the original R address and the most-significant-one in the M register. */
				/* The MS-one determines the number of bits that are zeroed in the R address, */
				/* since the lower address MUST have zeros in its lowest MSBs. */

				if (M[14])
					lower = {R[15],    15'h0000};

				else if (M[13])
					lower = {R[15:14], 14'h0000};

				else if (M[12])
					lower = {R[15:13], 13'h0000};

				else if (M[11])
					lower = {R[15:12], 12'h000 };

				else if (M[10])
					lower = {R[15:11], 11'h000 };

				else if (M[9])
					lower = {R[15:10], 10'h000 };

				else if (M[8])
					lower = {R[15: 9],  9'h000 };

				else if (M[7])
					lower = {R[15: 8],  8'h00  };

				else if (M[6])
					lower = {R[15: 7],  7'h00  };

				else if (M[5])
					lower = {R[15: 6],  6'h00  };

				else if (M[4])
					lower = {R[15: 5],  5'h00  };

				else if (M[3])
					lower = {R[15: 4],  4'h0   };

				else if (M[2])
					lower = {R[15: 3],  3'h0   };

				else if (M[1])
					lower = {R[15: 2],  2'h0   };

				else	/* M[0]==1 */
					lower = {R[15: 1],  1'h0   };


				/* The upper address of the memory region equals to the lower address plus M. */
				upper = lower + M;


				/* Check whether the linear address is outside of the modulo region and adjust it accordingly. */
				/* Since this mode is wrap-around-ONCE, only one adjustment is carried out. If linear is too */
				/* the final address might still be outside of the region. */
				
				if ( linear > upper )				/* bigger than the upper limit */
					mod = linear - M - 1'b1;

				else if ( linear < lower )			/* smaller than the lower limit */
					mod = linear + M + 1'b1;

				else								/* inside the region and not changed */
					mod = linear;

			end		/* wrap around ONCE */

			

		else if ( (M >= 16'h8001) && (M <= 16'hbfff) )
			begin	/*----------------------*/
					/* multiple wrap around */
					/*----------------------*/

				if ( M == 16'h8001 )
					mod = {R[15:1], linear[0]};

				if ( M == 16'h8003 )
					mod = {R[15:2], linear[1:0]};

				if ( M == 16'h8007 )
					mod = {R[15:3], linear[2:0]};

				if ( M == 16'h800f )
					mod = {R[15:4], linear[3:0]};

				if ( M == 16'h801f )
					mod = {R[15:5], linear[4:0]};

				if ( M == 16'h803f )
					mod = {R[15:6], linear[5:0]};

				if ( M == 16'h807f )
					mod = {R[15:7], linear[6:0]};

				if ( M == 16'h80ff )
					mod = {R[15:8], linear[7:0]};

				if ( M == 16'h81ff )
					mod = {R[15:9], linear[8:0]};

				if ( M == 16'h83ff )
					mod = {R[15:10], linear[9:0]};

				if ( M == 16'h87ff )
					mod = {R[15:11], linear[10:0]};

				if ( M == 16'h8fff )
					mod = {R[15:12], linear[11:0]};

				if ( M == 16'h9fff )
					mod = {R[15:13], linear[12:0]};

				if ( M == 16'hbfff )
					mod = {R[15:14], linear[13:0]};

			end		/* multiple wrap around */
			

		else	/* pass the linear address without any changes */
			mod = linear;
			
	end

endfunction		/* modulo */



/*==============================================================================*/
/*===========	Module Instantiations	 =======================================*/
/*==============================================================================*/

/*----------------------*/
/*  R register files:	*/
/*	R_H	:	R7-R4		*/
/*	R_L	:	R0-R3		*/
/*----------------------*/

/*------------------------------*/
/*				High			*/
/*------------------------------*/

rf_R R_H(
	.in1 (Rin1_H),
	.in2 (Rin2_H),
	.raddr1 (Rraddr1_H),
	.raddr2 (Rraddr2_H),
	.raddr3 (Rraddr3_H),
	.waddr1 (Rwaddr1_H),
	.waddr2 (Rwaddr2_H),
	.write1 (Rwrite1_H),
	.write2 (Rwrite2_H),
	.out1 (Rout1_H),
	.out2 (Rout2_H),
	.out3 (Rout3_H),
	.Clk (Clk)
	);


assign Rraddr1_H = Rraddr1_H_2;

assign Rraddr2_H = Rraddr2_H_3;

assign Rraddr3_H = Rraddr3_H_2;


assign Rin1_H = Rin1_H_2;

assign Rwaddr1_H = Rwaddr1_H_2;


assign Rin2_H = Rin2_H_3;

assign Rwaddr2_H = Rwaddr2_H_3;

assign Rwrite2_H = Rwrite2_H_3;



/*--------------*/
/* write enable */
/*--------------*/

always @(	Rwrite1_H_2 or
			Rwrite2_H or
			Rwaddr1_H or
			Rwaddr2_H
			)
	begin
		if ( Rwrite1_H_2 && Rwrite2_H && (Rwaddr1_H == Rwaddr2_H) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Rwrite1_H = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Rwrite1_H = Rwrite1_H_2;	/* coming from stage 2 */
			end
	end



/*------------------------------*/
/*				Low				*/
/*------------------------------*/

rf_R R_L(
	.in1 (Rin1_L),
	.in2 (Rin2_L),
	.raddr1 (Rraddr1_L),
	.raddr2 (Rraddr2_L),
	.raddr3 (Rraddr3_L),
	.waddr1 (Rwaddr1_L),
	.waddr2 (Rwaddr2_L),
	.write1 (Rwrite1_L),
	.write2 (Rwrite2_L),
	.out1 (Rout1_L),
	.out2 (Rout2_L),
	.out3 (Rout3_L),
	.Clk (Clk)
	);


assign Rraddr1_L = Rraddr1_L_2;

assign Rraddr2_L = Rraddr2_L_3;

assign Rraddr3_L = Rraddr3_L_2;


assign Rin1_L = Rin1_L_2;

assign Rwaddr1_L = Rwaddr1_L_2;


assign Rin2_L = Rin2_L_3;

assign Rwaddr2_L = Rwaddr2_L_3;

assign Rwrite2_L = Rwrite2_L_3;



/*--------------*/
/* write enable */
/*--------------*/

always @(	Rwrite1_L_2 or
			Rwrite2_L or
			Rwaddr1_L or
			Rwaddr2_L
			)
	begin
		if ( Rwrite1_L_2 && Rwrite2_L && (Rwaddr1_L == Rwaddr2_L) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Rwrite1_L = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Rwrite1_L = Rwrite1_L_2;	/* coming from stage 2 */
			end
	end



/*----------------------*/
/*  M register files:	*/
/*	M_H	:	M7-M4		*/
/*	M_L	:	M0-M3		*/
/*----------------------*/

/*------------------------------*/
/*				High			*/
/*------------------------------*/
 
rf_M M_H (
	.reset  (reset),
	.in1    (Min1_H),
	.in2    (Min2_H),
	.raddr1 (Mraddr1_H),
	.raddr2 (Mraddr2_H),
	.raddr3 (Mraddr3_H),
	.waddr1 (Mwaddr1_H),
	.waddr2 (Mwaddr2_H),
	.write1 (Mwrite1_H),
	.write2 (Mwrite2_H),
	.out1   (Mout1_H),	
	.out2   (Mout2_H),	
	.out3   (Mout3_H),	
	.Clk    (Clk)
	);


assign Mraddr1_H = Mraddr1_H_2;

assign Mraddr2_H = Mraddr2_H_3;

assign Mraddr3_H = Mraddr3_H_2;


assign Min1_H = Min1_H_2;

assign Min2_H = Min2_H_3;


assign Mwaddr1_H = Mwaddr1_H_2;

assign Mwaddr2_H = Mwaddr2_H_3;

assign Mwrite2_H = Mwrite2_H_3;


/*--------------*/
/* write enable */
/*--------------*/

always @(	Mwrite1_H_2 or
			Mwrite2_H or
			Mwaddr1_H or
			Mwaddr2_H
			)
	begin
		if ( Mwrite1_H_2 && Mwrite2_H && (Mwaddr1_H == Mwaddr2_H) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Mwrite1_H = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Mwrite1_H = Mwrite1_H_2;	/* coming from stage 2 */
			end
	end



/*------------------------------*/
/*				Low				*/
/*------------------------------*/

rf_M M_L (
	.reset  (reset),
	.in1    (Min1_L),
	.in2    (Min2_L),
	.raddr1 (Mraddr1_L),
	.raddr2 (Mraddr2_L),
	.raddr3 (Mraddr3_L),
	.waddr1 (Mwaddr1_L),
	.waddr2 (Mwaddr2_L),
	.write1 (Mwrite1_L),
	.write2 (Mwrite2_L),
	.out1   (Mout1_L),	
	.out2   (Mout2_L),	
	.out3   (Mout3_L),	
	.Clk    (Clk)
	);


assign Mraddr1_L = Mraddr1_L_2;

assign Mraddr2_L = Mraddr2_L_3;

assign Mraddr3_L = Mraddr3_L_2;


assign Min1_L = Min1_L_2;

assign Min2_L = Min2_L_3;


assign Mwaddr1_L = Mwaddr1_L_2;

assign Mwaddr2_L = Mwaddr2_L_3;

assign Mwrite2_L = Mwrite2_L_3;


/*--------------*/
/* write enable */
/*--------------*/

always @(	Mwrite1_L_2 or
			Mwrite2_L or
			Mwaddr1_L or
			Mwaddr2_L
			)
	begin
		if ( Mwrite1_L_2 && Mwrite2_L && (Mwaddr1_L == Mwaddr2_L) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Mwrite1_L = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Mwrite1_L = Mwrite1_L_2;	/* coming from stage 2 */
			end
	end



/*----------------------*/
/*  N register files:	*/
/*	N_H	:	N7-N4		*/
/*	N_L	:	N3-N0		*/
/*----------------------*/

/*------------------------------*/
/*				High			*/
/*------------------------------*/

rf_N N_H(
	.in1 (Nin1_H),
	.in2 (Nin2_H),
	.raddr1 (Nraddr1_H),
	.raddr2 (Nraddr2_H),
	.raddr3 (Nraddr3_H),
	.waddr1 (Nwaddr1_H),
	.waddr2 (Nwaddr2_H),
	.write1 (Nwrite1_H),
	.write2 (Nwrite2_H),
	.out1 (Nout1_H),
	.out2 (Nout2_H),
	.out3 (Nout3_H),
	.Clk (Clk)
	);


assign Nraddr1_H = Nraddr1_H_2;

assign Nraddr2_H = Nraddr2_H_3;

assign Nraddr3_H = Nraddr3_H_2;


assign Nin1_H = Nin1_H_2;

assign Nwaddr1_H = Nwaddr1_H_2;


assign Nin2_H = Nin2_H_3;

assign Nwaddr2_H = Nwaddr2_H_3;

assign Nwrite2_H = Nwrite2_H_3;



/*--------------*/
/* write enable */
/*--------------*/

always @(	Nwrite1_H_2 or
			Nwrite2_H or
			Nwaddr1_H or
			Nwaddr2_H
			)
	begin
		if ( Nwrite1_H_2 && Nwrite2_H && (Nwaddr1_H == Nwaddr2_H) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Nwrite1_H = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Nwrite1_H = Nwrite1_H_2;	/* coming from stage 2 */
			end
	end



/*------------------------------*/
/*				Low				*/
/*------------------------------*/


rf_N N_L(
	.in1 (Nin1_L),
	.in2 (Nin2_L),
	.raddr1 (Nraddr1_L),
	.raddr2 (Nraddr2_L),
	.raddr3 (Nraddr3_L),
	.waddr1 (Nwaddr1_L),
	.waddr2 (Nwaddr2_L),
	.write1 (Nwrite1_L),
	.write2 (Nwrite2_L),
	.out1 (Nout1_L),
	.out2 (Nout2_L),
	.out3 (Nout3_L),
	.Clk (Clk)
	);


assign Nraddr1_L = Nraddr1_L_2;

assign Nraddr2_L = Nraddr2_L_3;

assign Nraddr3_L = Nraddr3_L_2;


assign Nin1_L = Nin1_L_2;

assign Nwaddr1_L = Nwaddr1_L_2;


assign Nin2_L = Nin2_L_3;

assign Nwaddr2_L = Nwaddr2_L_3;

assign Nwrite2_L = Nwrite2_L_3;



/*--------------*/
/* write enable */
/*--------------*/

always @(	Nwrite1_L_2 or
			Nwrite2_L or
			Nwaddr1_L or
			Nwaddr2_L
			)
	begin
		if ( Nwrite1_L_2 && Nwrite2_L && (Nwaddr1_L == Nwaddr2_L) )
			begin	/* stage 2 and stage 3 try to write to the SAME register. The write from stage 3 has priority. */
				Nwrite1_L = `false;			/* stage 2 is not allowed to write into port 1 */
			end
		else
			begin
				Nwrite1_L = Nwrite1_L_2;	/* coming from stage 2 */
			end
	end





/*==============================================================================================================*/
/*																												*/
/*		Processes									Processes									Processes		*/
/*																												*/
/*==============================================================================================================*/

/*##############################################################################*/
/*##############################################################################*/
/*																				*/
/*	aux R registers for testing purposes only !!!								*/
/*																				*/
/*##############################################################################*/
/*##############################################################################*/

always @(posedge Clk)
	begin
		if      ( Rwrite1_L && (Rwaddr1_L==2'b00) )
			R0 <= Rin1_L;
		else if ( Rwrite2_L && (Rwaddr2_L==2'b00) )
			R0 <= Rin2_L;
		else
			R0 <= R0;

		if      ( Rwrite1_L && (Rwaddr1_L==2'b01) )
			R1 <= Rin1_L;
		else if ( Rwrite2_L && (Rwaddr2_L==2'b01) )
			R1 <= Rin2_L;
		else
			R1 <= R1;

		if      ( Rwrite1_L && (Rwaddr1_L==2'b10) )
			R2 <= Rin1_L;
		else if ( Rwrite2_L && (Rwaddr2_L==2'b10) )
			R2 <= Rin2_L;
		else
			R2 <= R2;

		if      ( Rwrite1_L && (Rwaddr1_L==2'b11) )
			R3 <= Rin1_L;
		else if ( Rwrite2_L && (Rwaddr2_L==2'b11) )
			R3 <= Rin2_L;
		else
			R3 <= R3;

		if      ( Rwrite1_H && (Rwaddr1_H==2'b00) )
			R4 <= Rin1_H;
		else if ( Rwrite2_H && (Rwaddr2_H==2'b00) )
			R4 <= Rin2_H;
		else
			R4 <= R4;

		if      ( Rwrite1_H && (Rwaddr1_H==2'b01) )
			R5 <= Rin1_H;
		else if ( Rwrite2_H && (Rwaddr2_H==2'b01) )
			R5 <= Rin2_H;
		else
			R5 <= R5;

		if      ( Rwrite1_H && (Rwaddr1_H==2'b10) )
			R6 <= Rin1_H;
		else if ( Rwrite2_H && (Rwaddr2_H==2'b10) )
			R6 <= Rin2_H;
		else
			R6 <= R6;

		if      ( Rwrite1_H && (Rwaddr1_H==2'b11) )
			R7 <= Rin1_H;
		else if ( Rwrite2_H && (Rwaddr2_H==2'b11) )
			R7 <= Rin2_H;
		else
			R7 <= R7;

	end

/*##############################################################################*/
/*##############################################################################*/


/*==============================================================================*/
/*																				*/
/*	GDB	bus, GDB_out register and write enable									*/
/*																				*/
/*==============================================================================*/

/*------------------*/
/* GDB_out register */
/*------------------*/

/* latch the output data coming from the AGU and towards the GDB bus */

always @(posedge Clk)
	begin
		GDB_out <= (gdb_write) ? gdb_out : GDB_out;
	end


/*--------------*/
/* GDB_write FF */
/*--------------*/

/* latch the write enable for data put towards the GDB bus */

always @(posedge Clk)
	begin
		if (reset)
			GDB_write <= `false;
		else
			GDB_write <= gdb_write;
	end


/*---------*/
/* GDB bus */
/*---------*/

/* On write permit, let the AGU drive the AGU bus, otherwise let it go (high-Z) */

assign GDB = (GDB_write) ? GDB_out : 24'hzzzzzz;



/*==============================================================================*/
/*																				*/
/*	PAB																			*/
/*																				*/
/*==============================================================================*/

always @(posedge Clk)
	begin
		PAB <= (PABwrite_2) ? PAB_2 : 16'hzzzz;
	end


/*==============================================================================*/
/*																				*/
/*	atomic flags																*/
/*																				*/
/*==============================================================================*/

/* Active when an atomic inst. is using the memory buses */

always @(posedge Clk)
	begin
		if (reset)
			begin
				Xatomic <= `false;
				Yatomic <= `false;
			end
		else
			begin
				/* first attempt to read by an atomic inst. sets the atomic flag (in stage 2). 	*/
				/* The flag stays high for one clock cycle and reset itself afterwards as the atomic inst completes execution (in stage 3). */
				
				Xatomic <= (Xatomic) ? 1'b0 : xread_atomic;
				Yatomic <= (Yatomic) ? 1'b0 : yread_atomic;
			end
	end


/*==============================================================================*/
/*																				*/
/*	X and Y memory buses and read/write controls								*/
/*																				*/
/*==============================================================================*/

always @(posedge Clk)
	begin
		
		/*--------------------------*/
		/* X data memory addressing */
		/*--------------------------*/
		
		if (reset)
			begin
				XWRITE <= `false;		/* initially don't write */
				XREAD  <= `false;		/* initially don't read */
			end

		else
			begin
				XWRITE <= Xwrite;		/* latch the write enable signal */
				XREAD  <= Xread;		/* latch the read enable signal */
				XAB    <= Xab;			/* latch the new address */
			end

			
		/*--------------------------*/
		/* Y data memory addressing */
		/*--------------------------*/

		if (reset)
			begin
				YWRITE <= `false;		/* initially don't write */
				YREAD  <= `false;		/* initially don't read */
			end

		else
			begin
				YWRITE <= Ywrite;		/* latch the write enable signal */
				YREAD  <= Yread;		/* latch the read enable signal */
				YAB    <= Yab;			/* latch the new address */
			end

	end




/*-------------------------------------------------------*/
/* X memory: read/write enable and address bus selectors */
/*-------------------------------------------------------*/

always @(	PDB or
			xab_2 or
			xab_3 or
			xwrite_2 or 
			xwrite_3 or 
			Xatomic or 
			xwrite_atomic or
			xread_atomic or
			xread_2 or 
			xread_3 or
			absolute
			)
	begin
		
		/* A read or write can come from either stage 2 or 3 */
		/* XAB will get its values from either xab_2 or xab_3, depending on both xread_2/xwrite_2 and xread_3/xwrite_3 */
		/* An atomic instruction has priority in gaining access to the buses over a newer instruction. */

		if ( (~Xatomic) && xread_atomic )		/* active in stage 2 of an atomic instruction that is reading from the X data memory */
			begin
				Xwrite = `false;
				Xread = xread_atomic;
				Xab = (absolute) ? PDB[`addrbus] : xab_2;		/* an absolute address is on PDB or an address coming from an AGU register */
			end

		else if ( Xatomic && xwrite_atomic )		/* active in stage 3 of an atomic instruction that is writing to the X data memory */
			begin
				Xwrite = xwrite_atomic;
				Xread = `false;
			end
			
		else if ( (~Xatomic) && (xwrite_2 || xread_2) && (~xwrite_3) && (~xread_3) )		/* access to X memory during stage 2 */
			begin
				Xwrite = xwrite_2;
				Xread  = xread_2;
				Xab = (absolute) ? PDB[`addrbus] : xab_2;		/* an absolute address is on PDB or an address coming from an AGU register */
			end

		else if ( (~Xatomic) && (~xwrite_2) && (~xread_2) && (xwrite_3 || xread_3) )		/* access to X memory during stage 3 */
			begin
				Xwrite = xwrite_3;
				Xread  = xread_3;
				Xab = xab_3;
			end

		else
			begin
				Xwrite = `false;
				Xread  = `false;
			end
	end


/*-------------------------------------------------------*/
/* Y memory: read/write enable and address bus selectors */
/*-------------------------------------------------------*/

always @(	PDB or
			yab_2 or
			yab_3 or
			ywrite_2 or 
			ywrite_3 or 
			Yatomic or 
			ywrite_atomic or
			yread_atomic or
			yread_2 or 
			yread_3 or
			absolute
			)
	begin
		
		/* A read or write can come from either stage 2 or 3 */
		/* YAB will get its values from either yab_2 or yab_3, depending on both yread_2/ywrite_2 and yread_3/ywrite_3 */
		/* An atomic instruction has priority in gaining access to the buses over a newer instruction. */

		if ( (~Yatomic) && yread_atomic )		/* active in stage 2 of an atomic instruction that is reading from the Y data memory */
			begin
				Ywrite = `false;
				Yread = yread_atomic;
				Yab = (absolute) ? PDB[`addrbus] : yab_2;		/* an absolute address is on PDB or an address coming from an AGU register */
			end

		else if ( Yatomic && ywrite_atomic )		/* active in stage 3 of an atomic instruction that is writing to the Y data memory */
			begin
				Ywrite = ywrite_atomic;
				Yread = `false;
			end
			
		else if ( (~Yatomic) && (ywrite_2 || yread_2) && (~ywrite_3) && (~yread_3) )		/* access to Y memory during stage 2 */
			begin
				Ywrite = ywrite_2;
				Yread  = yread_2;
				Yab = (absolute) ? PDB[`addrbus] : yab_2;		/* an absolute address is on PDB or an address coming from an AGU register */
			end

		else if ( (~Yatomic) && (~ywrite_2) && (~yread_2) && (ywrite_3 || yread_3) )		/* access to Y memory during stage 3 */
			begin
				Ywrite = ywrite_3;
				Yread  = yread_3;
				Yab = yab_3;
			end

		else
			begin
				Ywrite = `false;
				Yread  = `false;
			end
	end



/*======================================================================================*/
/*======================================================================================*/
/*																						*/
/*	Stage 2	(Decode)				Stage 2	(Decode)				Stage 2	(Decode)	*/
/*																						*/
/*======================================================================================*/
/*======================================================================================*/


/*--------------------------------------------------*/
/*													*/
/* 			instruction fetch into stage 2			*/
/*													*/
/*--------------------------------------------------*/

always @(posedge Clk)
	begin
		if (reset)
			pdb2 <= `NOP;
		else if (REPEAT)
			pdb2 <= pdb2;		/* REP instruction is in progress */
		else
			begin
				pdb2 <= (absolute || absolute_jump || immediate) ? `NOP : PDB;	/* Fetch the instruction from the PDB and into Decode stage */
			end	/* else */
	end


/*------------------------------------------------------------------------------*/
/*																				*/
/*						Decode and carry out the instruction.					*/
/*																				*/
/*------------------------------------------------------------------------------*/

always @(	reset or 
			pdb2 or 
			Rout1_L or 
			Rout2_L or 
			Rout3_L or 
			Rout1_H or 
			Rout2_H or 
			Rout3_H or 
			Mout1_L or 
			Mout2_L or 
			Mout3_L or 
			Mout1_H or 
			Mout2_H or 
			Mout3_H or 
			Nout1_L or 
			Nout2_L or 
			Nout3_L or 
			Nout1_H or
			Nout2_H or
			Nout3_H or
			Rin1_H or
			Rin1_L or
			Rin2_H or
			Rin2_L or
			GDB
			)
	begin

		/* Initially don't allow any writes to any of the register files */
															   
		Rwrite1_L_2 = `false;

		Rwrite1_H_2 = `false;

		
		Nwrite1_L_2 = `false;

		Nwrite1_H_2 = `false;
		

		Mwrite1_L_2 = `false;

		Mwrite1_H_2 = `false;
		
		
		
		/* initially don't read or write any of the memories (false) */
		
		xwrite_2 = `false;
		xread_2  = `false;
		
		ywrite_2 = `false;
		yread_2  = `false;
		
		PABwrite_2 = `false;


		/* initially don't write to the GDB bus */

		gdb_write = `false;


		/* initially the absolute/immediate mode is off */

		absolute = `false;
		absolute_jump = `false;
		immediate = `false;


		/* initially clear the atomic read permissions */
		
		xread_atomic = `false;
		yread_atomic = `false;



		/*--------------------------------------------------------------------------*/
		/*																			*/
		/* 					Decode the incoming instruction							*/
		/*																			*/
		/*--------------------------------------------------------------------------*/
		
		
		if ( pdb2[`movefield] == `no_parallel_data_move )
			begin	/*--------------------------------------*/
					/* No parallel data move is required	*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
			end




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */

				absolute = `true;
				
				/* choose the register that holds the number of iterations */
				if (pdb2[13:11] == 3'b010)
					begin		/* R */
						if (pdb2[10])
							begin		/* high */
								Rraddr1_H_2 = pdb2[9:8];					/* R read  address */
								gdb_out = Rout1_H;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
						else
							begin		/* low */
								Rraddr1_L_2 = pdb2[9:8];					/* R read  address */
								gdb_out = Rout1_L;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
					end		/* R */
				
				
				else if (pdb2[13:11] == 3'b011)
					begin		/* N */
						if (pdb2[10])
							begin		/* high */
								Nraddr1_H_2 = pdb2[9:8];					/* N read  address */
								gdb_out = Nout1_H;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
						else
							begin		/* low */
								Nraddr1_L_2 = pdb2[9:8];					/* N read  address */
								gdb_out = Nout1_L;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
					end		/* N */
				
					
				else if (pdb2[13:11] == 3'b100)
					begin		/* M */
						if (pdb2[10])
							begin		/* high */
								Mraddr1_H_2 = pdb2[9:8];					/* M read  address */
								gdb_out = Mout1_H;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
						else
							begin		/* low */
								Mraddr1_L_2 = pdb2[9:8];					/* M read  address */
								gdb_out = Mout1_L;							/* put data on gdb */
								gdb_write = `true;							/* allow write to gdb */
							end
					end		/* M */
				
			end		/* DO Class IV */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*										*/
					/* Jump with an effective address		*/
					/*--------------------------------------*/

				/* calculate the effective address for the jump and UPDATE the address register that is being used */
				
				case (pdb2[13:11])
					3'b000	:	/* (Rn)-Nn */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_H;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_L;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end		/* (Rn)-Nn */

					3'b001	:	/* (Rn)+Nn */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_H;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_L;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end		/* (Rn)+Nn */

					3'b010	:	/* (Rn)- */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_H;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_L;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* (Rn)- */

					3'b011	:	/* (Rn)+ */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_H;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										PAB_2 = Rout1_L;									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* (Rn)+ */

					3'b100	:	/* (Rn) */
								if (pdb2[10])
									begin	/* High */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

										PAB_2 = Rout1_H;									/* memory address */
										PABwrite_2  = `true;
									end
								else
									begin	/* Low */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

										PAB_2 = Rout1_L;									/* memory address */
										PABwrite_2  = `true;
									end		/* (Rn) */

					3'b101	:	/* (Rn+Nn) */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

										PAB_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);									/* memory address */
										PABwrite_2  = `true;
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

										PAB_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);									/* memory address */
										PABwrite_2  = `true;
									end		/* (Rn+Nn) */

					3'b110	:	/* Absolute address */
								/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
								/* Jump using a second program word as an absolute address	*/ 
								/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
								begin
									if (pdb2[10:8] == 3'b000)
										/* absolute address */
										absolute = `true;
								end

					3'b111	:	/* -(Rn) */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										PAB_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										PAB_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);									/* memory address */
										PABwrite_2  = `true;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* -(Rn) */

				endcase	/* pdb2[13:11] */
				

			end		/* JMP Class II */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/

				/* The number of repetitions is in one if the AGU registers. To be put on the GDB */
				
				case (pdb2[13:11])
					3'b010	:	begin	/*---*/
										/* R */
										/*---*/
									gdb_write = `true;							/* put on the GDB */
									
									if (pdb2[10])								/* choose the register */
										begin	/* High */
											Rraddr1_H_2 = pdb2[9:8];			/* R read  address */
											gdb_out = Rout1_H;
										end
									else
										begin	/* Low */
											Rraddr1_L_2 = pdb2[9:8];			/* R read  address */
											gdb_out = Rout1_L;									
										end		/* (Rn) */
								end		/* R */
								
					3'b011	:	begin	/*---*/
										/* N */
										/*---*/
									gdb_write = `true;							/* put on the GDB */
									
									if (pdb2[10])								/* choose the register */
										begin	/* High */
											Nraddr1_H_2 = pdb2[9:8];
											gdb_out = Nout1_H;
										end
									else
										begin	/* Low */
											Nraddr1_L_2 = pdb2[9:8];
											gdb_out = Nout1_L;
										end
								end		/* N */
								
					3'b100	:	begin	/*---*/
										/* M */
										/*---*/
									gdb_write = `true;							/* put on the GDB */
									
									if (pdb2[10])								/* choose the register */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];
											gdb_out = Mout1_H;
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];
											gdb_out = Mout1_L;
										end
								end		/* M */
								
					default	:	;	/* No Action */
				endcase

			end		/* REP Class IV */




		else if ( {pdb2[23:14], pdb2[7], pdb2[5:0]} == 17'b00000110_01_0_100000 )
			begin	/*--------------------------------------*/
					/*				REP Class I				*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				/*--------------------------------------------------------------------------*/
				/* 			Effective address calculation 									*/
				/*																			*/
				/* Read from X or Y memory. The read datum is the number of repetitions.	*/
				/*--------------------------------------------------------------------------*/

				case (pdb2[13:11])
					3'b000	:	begin	/* (Rn)-Nn */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)-Nn */

					3'b001	:	begin	/* (Rn)+Nn */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)+Nn */

					3'b010	:	begin	/* (Rn)- */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)- */

					3'b011	:	begin	/* (Rn)+ */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)+ */

					3'b100	:	begin	/* (Rn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;
										end
									else
										begin	/* Low */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;
										end
								end		/* (Rn) */

					3'b101	:	begin	/* (Rn+Nn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
										end
								end		/* (Rn+Nn) */

					3'b110	:	;		/* No action */

					3'b111	:	begin	/* -(Rn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* -(Rn) */

				endcase	/* pdb2[13:11] */
				
			end		/* REP Class I */




		else if ( {pdb2[23:14], pdb2[7], pdb2[5:0]} == 17'b00000110_00_0_100000 )
			begin	/*--------------------------------------*/
					/*				REP Class II			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				
				/* Short absolute address taken from the instruction word */

				/* memory address */
				if (pdb2[6])
					begin
						yab_2 = {10'h000, pdb2[13:8]};
						yread_2 = `true;
					end
				else
					begin
						xab_2 = {10'h000, pdb2[13:8]};
						xread_2 = `true;
					end

			end		/* REP Class II */




		else if ( {pdb2[23:13], pdb2[7:4]} == 15'b00000100_010_0001 )
			begin	/*--------------------------------------*/
					/*					LUA					*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* LUA */




		else if ( {pdb2[23:16], pdb2[7:4]} == 12'b00000110_1010 )
			begin	/*--------------------------------------*/
					/*			REP Class III				*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* REP Class III */




		else if ( {pdb2[23:16], pdb2[7:4]} == 12'b0000_0110_1000 )
			begin	/*--------------------------------------*/
					/*			DO Class III				*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */

				absolute = `true;
				
			end		/* DO Class III */




		else if ( {pdb2[23:14], pdb2[7:6]} == 12'b00001010_11_00 )
			begin	/*--------------------------------------*/
					/*		JCLR / JSET Class III			*/
					/*										*/
					/*	Jump if Bit Clear/Set - Class III	*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				
				absolute_jump = `true;
		
		end		/* JCLR/JSET Class III */




		else if ( {pdb2[23:14], pdb2[7]} == 11'b00001010_01_1 )

			begin	/*--------------------------------------*/
					/*		JCLR / JSET Class I				*/
					/*										*/
					/*	Jump if Bit Clear/Set - Class I		*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				
				absolute_jump = `true;
				
				
				/*--------------------------------------------------------------------------*/
				/* 			Effective address calculation 									*/
				/*																			*/
				/* Read from X or Y memory when the destination is a data memory word.		*/
				/* Address registers are ALWAYS updated regardless of the testing result.	*/
				/*--------------------------------------------------------------------------*/

				case (pdb2[13:11])
					3'b000	:	begin	/* (Rn)-Nn */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)-Nn */

					3'b001	:	begin	/* (Rn)+Nn */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)+Nn */

					3'b010	:	begin	/* (Rn)- */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)- */

					3'b011	:	begin	/* (Rn)+ */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)+ */

					3'b100	:	begin	/* (Rn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;
										end
									else
										begin	/* Low */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;
										end
								end		/* (Rn) */

					3'b101	:	begin	/* (Rn+Nn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
										end
								end		/* (Rn+Nn) */

					3'b110	:	;		/* No action */
					
					3'b111	:	begin	/* -(Rn) */
									if (pdb2[6])												/* memory access */
										yread_2 = `true;
									else
										xread_2 = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* -(Rn) */

				endcase	/* pdb2[13:11] */
			
			end		/* JCLR/JSET Class I */




		else if ( {pdb2[23:14], pdb2[7]} == 11'b00001010_00_1 )
			begin	/*--------------------------------------*/
					/*		JCLR / JSET Class II			*/
					/*										*/
					/*	Jump if Bit Clear/Set - Class II	*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				
				absolute_jump = `true;
				
				
				/* Short absolute address taken from the instruction word */

				/* memory address */
				if (pdb2[6])
					begin
						yab_2 = {10'h000, pdb2[13:8]};
						yread_2 = `true;
					end
				else
					begin
						xab_2 = {10'h000, pdb2[13:8]};
						xread_2 = `true;
					end

			end		/* JCLR/JSET Class II */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_01_0) ||
				  ({pdb2[23:14], pdb2[7], pdb2[5]} == 12'b00001011_01_0_1) )

			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class I		*/
					/*										*/
					/*	Bit Test and Clear/Set - Class I	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction regarding the data memories.		*/

				/*----------------------------------------------------------------------*/
				/* 			Effective address calculation 								*/
				/*																		*/
				/* Read from X or Y memory when the destination is a data memory word.	*/
				/*----------------------------------------------------------------------*/

				case (pdb2[13:11])
					3'b000	:	begin	/* (Rn)-Nn */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)-Nn */

					3'b001	:	begin	/* (Rn)+Nn */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)+Nn */

					3'b010	:	begin	/* (Rn)- */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
										end
								end		/* (Rn)- */

					3'b011	:	begin	/* (Rn)+ */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
										end
								end		/* (Rn)+ */

					3'b100	:	begin	/* (Rn) */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;
										end
									else
										begin	/* Low */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;
										end
								end		/* (Rn) */

					3'b101	:	begin	/* (Rn+Nn) */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
										end
								end		/* (Rn+Nn) */

					3'b110	:	/* Absolute address */
								if (pdb2[10:8] == 3'b000)
									begin
										/* absolute address */
										absolute = `true;
										if (pdb2[6])
											yread_atomic = `true;	/* Y: */
										else
											xread_atomic = `true;	/* X: */
									end

					3'b111	:	begin	/* -(Rn) */
									if (pdb2[6])												/* memory access */
										yread_atomic = `true;
									else
										xread_atomic = `true;

									if (pdb2[10])
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[6])										/* memory address */
												yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
										end
								end		/* -(Rn) */

				endcase	/* pdb2[13:11] */

			end		/* BCLR/BSET/BTST Class I */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_00_0) ||
				  ({pdb2[23:14], pdb2[7], pdb2[5]} == 12'b00001011_00_0_1) )

			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class II		*/
					/*										*/
					/*	Bit Test and Clear/Set - Class II	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction regarding the data memories.		*/
			
				/* Short absolute address taken from the instruction word */

				/* memory address */
				if (pdb2[6])
					begin
						yab_2 = {10'h000, pdb2[13:8]};
						yread_atomic = `true;
					end
				else
					begin
						xab_2 = {10'h000, pdb2[13:8]};
						xread_atomic = `true;
					end

			end		/* BCLR/BSET/BTST Class II */




		else if ( pdb2[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U:					*/
					/*									*/
					/* Address Register Update 			*/
					/*----------------------------------*/

				/* choose one of the effective addresses */

				case (pdb2[12:11])
					2'b00	:	/* (Rn)-Nn */
								if (pdb2[10])
									begin		/* High R */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read address */
										Rraddr1_H_2 = pdb2[9:8];
										Rwaddr1_H_2 = pdb2[9:8];

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin		/* Low  R */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read address */
										Rraddr1_L_2 = pdb2[9:8];
										Rwaddr1_L_2 = pdb2[9:8];

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end

					2'b01	:	/* (Rn)+Nn */
								if (pdb2[10])
									begin		/* High R */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read address */
										Rraddr1_H_2 = pdb2[9:8];
										Rwaddr1_H_2 = pdb2[9:8];

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin		/* Low  R */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read address */
										Rraddr1_L_2 = pdb2[9:8];
										Rwaddr1_L_2 = pdb2[9:8];

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end

					2'b10	:	/* (Rn)- */
								if (pdb2[10])
									begin		/* High R */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Rraddr1_H_2 = pdb2[9:8];
										Rwaddr1_H_2 = pdb2[9:8];

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin		/* Low  R */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Rraddr1_L_2 = pdb2[9:8];
										Rwaddr1_L_2 = pdb2[9:8];

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end

					2'b11	:	/* (Rn)+ */
								if (pdb2[10])
									begin		/* High R */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Rraddr1_H_2 = pdb2[9:8];
										Rwaddr1_H_2 = pdb2[9:8];

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin		/* Low  R */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Rraddr1_L_2 = pdb2[9:8];
										Rwaddr1_L_2 = pdb2[9:8];

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
									end
									
				endcase		/* pdb2[12:11] */

			end		/* U: */




		else if ( {pdb2[23:16], pdb2[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* Move Control Register	 		*/
					/* No Action						*/
					/*----------------------------------*/

			end		/* MOVEC Class IV */




		else if ( {pdb2[23:16], pdb2[7], pdb2[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				/*--------------------------------------------------------------*/
				/* 			Effective address calculation 						*/
				/*																*/
				/* Read from X or Y memory when the destination is a register.	*/
				/* Write to X or Y memory when the source is a register.		*/
				/*--------------------------------------------------------------*/

				if (pdb2[14])
					begin	/*------------------*/
							/*		Class I		*/
							/*------------------*/

						case (pdb2[13:11])
							3'b000	:	begin	/* (Rn)-Nn */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)-Nn */

							3'b001	:	begin	/* (Rn)+Nn */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)+Nn */

							3'b010	:	begin	/* (Rn)- */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)- */

							3'b011	:	begin	/* (Rn)+ */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)+ */

							3'b100	:	begin	/* (Rn) */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;
												end
											else
												begin	/* Low */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[6])										/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;
												end
										end		/* (Rn) */

							3'b101	:	begin	/* (Rn+Nn) */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[6])										/* memory address */
														yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
													else
														xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[6])										/* memory address */
														yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
													else
														xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
												end
										end		/* (Rn+Nn) */

							3'b110	:	/* Absolute address & Immediate data */
										begin
											if (pdb2[10:8] == 3'b100)						/* immediate data */
												begin
													if ( pdb2[15] )							/* write destination */
														begin
															immediate = `true;

															if ( pdb2[4:3] == 2'b00 )
																/*-------------------------*/
																/* Destination: M register */
																/*-------------------------*/

																if (pdb2[2])
																	begin	/* High */
																		Mwaddr1_H_2 = pdb2[1:0];		/* M write address */
																		Mwrite1_H_2 = `true;			/* enable write */
																		Min1_H_2 = GDB[`addrbus];		/* updated value */
																	end
																else
																	begin	/* Low */
																		Mwaddr1_L_2 = pdb2[1:0];		/* M write address */
																		Mwrite1_L_2 = `true;			/* enable write */
																		Min1_L_2 = GDB[`addrbus];		/* updated value */
																	end		/* M */
														end		/* write */
												end		/* immediate data */
												
												
											else if (pdb2[10:8] == 3'b000)					/* absolute address */
												begin
													absolute = `true;

													case ({pdb2[6], pdb2[15]})				/* memory access */
														2'b00	:	xwrite_2 = `true;
														2'b01	:	xread_2  = `true;
														2'b10	:	ywrite_2 = `true;
														2'b11	:	yread_2  = `true;
													endcase
												end
										end/* Absolute address & Immediate data */
										
							3'b111	:	begin	/* -(Rn) */
											case ({pdb2[6], pdb2[15]})									/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
													else
														xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[6])										/* memory address */
														yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
													else
														xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* -(Rn) */

						endcase	/* pdb2[13:11] */

					end		/* Class I */


				else		/* if pdb2[14]==0 */

					begin	/*------------------------------*/
							/* 			Class II			*/
							/*------------------------------*/

						/* memory access */
						case ({pdb2[6], pdb2[15]})
							2'b00	:	xwrite_2 = `true;
							2'b01	:	xread_2  = `true;
							2'b10	:	ywrite_2 = `true;
							2'b11	:	yread_2  = `true;
						endcase

						/* memory address */
						if (pdb2[6])
							yab_2 = { 10'b00000_00000, pdb2[13:8] };
						else
							xab_2 = { 10'b00000_00000, pdb2[13:8] };

					end	/* Class II */
					
				
				/*---------------------------------------------*/
				/* if a source register is written into memory */
				/*---------------------------------------------*/

				if (~pdb2[15])
					begin
						if (pdb2[4:3] == 2'b00)
							begin	/* M registers ^^^^ using port 3 ^^^^ */
								if (pdb2[2])
									begin		/* High */
										Mraddr3_H_2 = pdb2[1:0];
										gdb_out = {8'h00, Mout3_H};		/* put M on the GDB */
										gdb_write = `true;
									end
								else
									begin		/* Low */
										Mraddr3_L_2 = pdb2[1:0];
										gdb_out = {8'h00, Mout3_L};		/* put M on the GDB */
										gdb_write = `true;
									end
							end		/* M */
					end		/* read source */


					
			end		/* MOVEC Class I and II */




		else if ( {pdb2[23:17], pdb2[14]} == 8'b0000100_0 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class II  or  R:Y  Class II					*/
					/*																*/
					/* X Memory and Register Data Move		Class II				*/
					/* Register and Y Memory Data Move		Class II				*/
					/*																*/
					/* Generates the effective address for a data write.			*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Condition codes ARE affected.								*/
					/*--------------------------------------------------------------*/
				case (pdb2[13:11])
					3'b000	:	/* (Rn)-Nn */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_H;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_H;
												xwrite_2 = `true;
											end

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_L;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_L;
												xwrite_2 = `true;
											end

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end		/* (Rn)-Nn */

					3'b001	:	/* (Rn)+Nn */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_H;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_H;
												xwrite_2 = `true;
											end

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_L;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_L;
												xwrite_2 = `true;
											end

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end		/* (Rn)+Nn */

					3'b010	:	/* (Rn)- */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_H;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_H;
												xwrite_2 = `true;
											end

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_L;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_L;
												xwrite_2 = `true;
											end

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* (Rn)- */

					3'b011	:	/* (Rn)+ */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_H;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_H;
												xwrite_2 = `true;
											end

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_L;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_L;
												xwrite_2 = `true;
											end

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* (Rn)+ */

					3'b100	:	/* (Rn) */
								if (pdb2[10])
									begin	/* High */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_H;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_H;
												xwrite_2 = `true;
											end
									end
								else
									begin	/* Low */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = Rout1_L;
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = Rout1_L;
												xwrite_2 = `true;
											end
									end		/* (Rn) */

					3'b101	:	/* (Rn+Nn) */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
												xwrite_2 = `true;
											end
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
												xwrite_2 = `true;
											end
									end		/* (Rn+Nn) */

					3'b110	:	begin	/* No Action */
								end

					3'b111	:	/* -(Rn) */
								/* The source register is NEVER an AGU register	*/

								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
												xwrite_2 = `true;
											end

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										if (pdb2[15])										/* memory access */
											begin
												yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
												ywrite_2 = `true;
											end
										else
											begin
												xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
												xwrite_2 = `true;
											end

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end		/* -(Rn) */

				endcase	/* pdb2[13:11] */

			end		/* X:R Class II  or  R:Y Class II */




		else if ( pdb2[23:18] == 6'b001000 )
			begin	/*----------------------------------*/
					/*				R:					*/
					/*									*/
					/* Register to Register Data Move	*/
					/* Condition Codes ARE changed.		*/
					/*									*/
					/* Active when the source is either	*/
					/* an R or an N register.			*/
					/*----------------------------------*/

				/* 16 LS bits in gdb_out get the register contents and the upper 8 are zeroed */

				/* choose the source */
				
				if ( pdb2[17:16] == 2'b11 )
					begin	/*------------*/
							/* N register */
							/*------------*/
						
						gdb_write = `true;

						if (pdb2[15])
							begin	/* High */
								Nraddr1_H_2 = pdb2[14:13];
								gdb_out = {8'h00, Nout1_H};
							end
						else
							begin	/* Low */
								Nraddr1_L_2 = pdb2[14:13];
								gdb_out = {8'h00, Nout1_L};
							end
					end		/* N */
						

				else if ( pdb2[17:16] == 2'b10 )
					begin	/*------------*/
							/* R register */
							/*------------*/
							
						gdb_write = `true;
						
						if (pdb2[15])
							begin	/* High */
								Rraddr1_H_2 = pdb2[14:13];
								gdb_out = {8'h00, Rout1_H};
							end
						else
							begin	/* Low */
								Rraddr1_L_2 = pdb2[14:13];
								gdb_out = {8'h00, Rout1_L};
							end
					end		/* R */

			end		/* R: */





		else if ( {pdb2[23:20], pdb2[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/* 									*/
					/* Long Memory Data Move			*/
					/*----------------------------------*/
				
				if (pdb2[14])
					begin	/*------------------------------*/
							/*			L: Class I			*/
							/*------------------------------*/
						
						/* calculate the effective address. Both X and Y accesses are using the SAME effective address */
						
						case (pdb2[13:11])
							3'b000	:	begin	/* (Rn)-Nn */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_H;
													xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_L;
													xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)-Nn */

							3'b001	:	begin	/* (Rn)+Nn */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_H;
													xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_L;
													xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)+Nn */

							3'b010	:	begin	/* (Rn)- */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_H;
													xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_L;
													xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)- */

							3'b011	:	begin	/* (Rn)+ */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_H;
													xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													yab_2 = Rout1_L;
													xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)+ */

							3'b100	:	begin	/* (Rn) */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													yab_2 = Rout1_H;
													xab_2 = Rout1_H;
												end
											else
												begin	/* Low */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													yab_2 = Rout1_L;
													xab_2 = Rout1_L;
												end
										end		/* (Rn) */

							3'b101	:	begin	/* (Rn+Nn) */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
													xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
													xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
												end
										end		/* (Rn+Nn) */

							3'b110	:	if (pdb2[10:8] == 3'b000)	/* absolute address */
											begin
												absolute = `true;

												/* memory accesses */
												if (pdb2[15])
													begin					/* read from memory */
														xread_2 = `true;
														yread_2 = `true;
													end
												else
													begin					/* write to memory */
														xwrite_2 = `true;
														ywrite_2 = `true;
													end
											end		/* absolute address */
										
							3'b111	:	begin	/* -(Rn) */
											if (pdb2[15])				/* memory accesses */
												begin													/* read from memory */
													xread_2 = `true;
													yread_2 = `true;
												end
											else
												begin													/* write to memory */
													xwrite_2 = `true;
													ywrite_2 = `true;
												end

											if (pdb2[10])				/* effective address */
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
													xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
													xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* -(Rn) */

						endcase	/* pdb2[13:11] */

					end		/* L: Class I */

				else
					begin	/*----------------------*/
							/*		L: Class II		*/
							/*----------------------*/
						
						/* the address is an absolute short address in the instruction word */
						
						xab_2 = {10'b0000000000, pdb2[13:8]};
						yab_2 = {10'b0000000000, pdb2[13:8]};

						/* memory accesses */
						if (pdb2[15])
							begin					/* read from memory */
								xread_2 = `true;
								yread_2 = `true;
							end
						else
							begin					/* write to memory */
								xwrite_2 = `true;
								ywrite_2 = `true;
							end
							
					end		/* L: Class II */
						

			end	/* L: */





		else if ( pdb2[23:20] == 4'b0001 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class I  or  R:Y Class I					*/
					/*																*/
					/* X Memory and Register Data Move		Class I					*/
					/* Register and Y Memory Data Move		Class I					*/
					/*																*/
					/* Generates the effective address for a data read or write.	*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Condition codes ARE affected.								*/
					/*--------------------------------------------------------------*/
				case (pdb2[13:11])
					3'b000	:	begin	/* (Rn)-Nn */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)-Nn */

					3'b001	:	begin	/* (Rn)+Nn */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
										end
								end		/* (Rn)+Nn */

					3'b010	:	begin	/* (Rn)- */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)- */

					3'b011	:	begin	/* (Rn)+ */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* (Rn)+ */

					3'b100	:	begin	/* (Rn) */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_H;
											else
												xab_2 = Rout1_H;
										end
									else
										begin	/* Low */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[14])										/* memory address */
												yab_2 = Rout1_L;
											else
												xab_2 = Rout1_L;
										end
								end		/* (Rn) */

					3'b101	:	begin	/* (Rn+Nn) */
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[14])										/* memory address */
												yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

											if (pdb2[14])										/* memory address */
												yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
										end
								end		/* (Rn+Nn) */

					3'b110	:	/* Absolute address & Immediate data */
								begin
									if ( {pdb2[15], pdb2[10:8]} == 4'b1_100 )
										begin									/* immediate data */
											immediate = `true;
										end
										
									else if (pdb2[10:8] == 3'b000)
										begin									/* absolute address */
											absolute = `true;
											if (pdb2[14])
												yread_2 = `true;	/* Y: */
											else
												xread_2 = `true;	/* X: */
										end
								end

					3'b111	:	begin	/* -(Rn) */

									/* The source register is NEVER an AGU register	*/
								
									case ({pdb2[14], pdb2[15]})			/* memory access */
										2'b00	:	xwrite_2 = `true;
										2'b01	:	xread_2  = `true;
										2'b10	:	ywrite_2 = `true;
										2'b11	:	yread_2  = `true;
									endcase

									if (pdb2[10])						/* effective address */
										begin	/* High */
											Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
											else
												xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

											Rwrite1_H_2 = `true;								/* enable write */
											Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
										end
									else
										begin	/* Low */
											Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
											Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
											Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

											if (pdb2[14])										/* memory address */
												yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
											else
												xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

											Rwrite1_L_2 = `true;								/* enable write */
											Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
										end
								end		/* -(Rn) */

				endcase	/* pdb2[13:11] */

			end		/* X:R Class I  or  R:Y Class I */




		else if ( pdb2[23:21] == 3'b001 )
			begin	/*----------------------------------*/
					/* 				I:					*/
					/*									*/
					/* No Action						*/
					/*----------------------------------*/
			end		/* I: */
			



		else if ( pdb2[23:22] == 2'b01 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:				*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/* Condition codes ARE affected		*/
					/*----------------------------------*/


				if ( (~pdb2[15]) & (pdb2[13:11] != 3'b110) )

					begin	/*----------------------------------*/
							/* Source: a register				*/
							/* Destination : X or Y data memory	*/
							/*----------------------------------*/

						/* W = 0 : Put the content of a source register on gdb_out only if	*/
						/* the effective address is not one of:								*/
						/* absolute address or immediate data.								*/

						/*--------------------------*/
						/* Pick the source register */
						/*--------------------------*/

						if ( pdb2[21:20] == 2'b10 )
							begin	/*----------------------*/
									/* Source is R register */
									/*----------------------*/
									
								gdb_write = `true;								/* access gdb */

								if (pdb2[13:11] == 3'b111)						/* ea = Rn */
									begin
										/* if ea and the source are the same, the newly calculated value */
										/* should be taken and not the stored one. */

										if (pdb2[10:8] == pdb2[18:16])			/* the same register */
											begin
													/* ea and the source are the same register. */
													/* ea is used from the input to the appropriate bank -- port 1 --. */
												gdb_out = (pdb2[10]) ? {8'h00, Rin1_H} : {8'h00, Rin1_L};
											end
									end		/* ea = Rn */
									
								else											/* ea != Rn and other addressing modes */
									begin
										if (pdb2[18])	/* High */
											begin
												Rraddr3_H_2 = pdb2[17:16];		/* R read address -- using port 3 -- */
												gdb_out = {8'h00, Rout3_H};		/* take the existing value of Rn */
											end
										else			/* Low */
											begin
												Rraddr3_L_2 = pdb2[17:16];		/* R read address -- using port 3 -- */
												gdb_out = {8'h00, Rout3_L};		/* take the existing value of Rn */
											end
									end
							end		/* R */


						else if ( pdb2[21:20] == 2'b11 )
							/*----------------------*/
							/* Source is N register */
							/*----------------------*/
							
							if ( pdb2[18] )		/* High */
								begin
									Nraddr3_H_2 = pdb2[17:16];		/* using -- port 3 -- */
									gdb_out = {8'h00, Nout3_H};
									gdb_write = `true;
								end
							else				/* Low */
								begin
									Nraddr3_L_2 = pdb2[17:16];		/* using -- port 3 -- */
									gdb_out = {8'h00, Nout3_L};
									gdb_write = `true;
								end		/* N */

					end	/* choose a source */



				if (pdb2[14])
					begin	/*------------------------------*/
							/*								*/
							/* instruction format type 1	*/
							/*								*/
							/*------------------------------*/

						/*--------------------------------------------------------------*/
						/* 			Effective address calculation 						*/
						/*																*/
						/* Read from X or Y memory when the destination is a register.	*/
						/* Write to X or Y memory when the source is a register.		*/
						/*--------------------------------------------------------------*/

						case (pdb2[13:11])
							3'b000	:	begin	/* (Rn)-Nn */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)-Nn */

							3'b001	:	begin	/* (Rn)+Nn */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
												end
										end		/* (Rn)+Nn */

							3'b010	:	begin/* (Rn)- */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)- */

							3'b011	:	begin	/* (Rn)+ */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* (Rn)+ */

							3'b100	:	begin	/* (Rn) */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_H;
													else
														xab_2 = Rout1_H;
												end
											else
												begin	/* Low */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[19])					/* memory address */
														yab_2 = Rout1_L;
													else
														xab_2 = Rout1_L;
												end
										end		/* (Rn) */

							3'b101	:	begin	/* (Rn+Nn) */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[19])					/* memory address */
														yab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
													else
														xab_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */

													if (pdb2[19])					/* memory address */
														yab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
													else
														xab_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);
												end
										end		/* (Rn+Nn) */

							3'b110	:	/* Absolute address & Immediate data */
										begin
											if ( {pdb2[15], pdb2[10:8]} == 4'b1_100 )
												/*---------------------*/
												/* immediate data mode */
												/*---------------------*/

												/*--------------------------*/
												/* Destination: a REGISTER	*/
												/*--------------------------*/

												/* Registers R and N are the destination in the AGU.	*/
												/* Input data arrive from the GDB 16 LS bits 		*/

												begin
													immediate = `true;
													
													if ( pdb2[21:20] == 2'b10 )
														/*-------------------------*/
														/* Destination: R register */
														/*-------------------------*/
														
														if (pdb2[18])
															begin	/* High */
																Rwaddr1_H_2 = pdb2[17:16];		/* R write address */
																Rwrite1_H_2 = `true;			/* enable write */
																Rin1_H_2 = GDB[`addrbus];		/* updated value */
															end
														else
															begin	/* Low */
																Rwaddr1_L_2 = pdb2[17:16];		/* R write address */
																Rwrite1_L_2 = `true;			/* enable write */
																Rin1_L_2 = GDB[`addrbus];		/* updated value */
															end		/* R */
														
													else if ( pdb2[21:20] == 2'b11 )
														/*--------------------------*/
														/* Destination: N register	*/
														/*--------------------------*/

														if (pdb2[18])	/* High */
															begin
																Nwaddr1_H_2 = pdb2[17:16];
																Nwrite1_H_2 = `true;
																Nin1_H_2 = GDB[`addrbus];
															end
														else			/* Low */
															begin
																Nwaddr1_L_2 = pdb2[17:16];
																Nwrite1_L_2 = `true;
																Nin1_L_2 = GDB[`addrbus];
															end		/* N */

												end		/* immediate data	*/

											else if (pdb2[10:8] == 3'b000)
												begin	/*------------------*/	
														/* absolute address */
														/*------------------*/
														
													absolute = `true;
													if (pdb2[19])
														yread_2 = `true;			/* Y: */
													else
														xread_2 = `true;			/* X: */
												end		/* absolute address */
												
										end		/* absolute & immediate data */
										
							3'b111	:	begin	/* -(Rn) */
											case ({pdb2[19], pdb2[15]})				/* memory access */
												2'b00	:	xwrite_2 = `true;
												2'b01	:	xread_2  = `true;
												2'b10	:	ywrite_2 = `true;
												2'b11	:	yread_2  = `true;
											endcase

											if (pdb2[10])
												begin	/* High */
													Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);
													else
														xab_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);

													Rwrite1_H_2 = `true;								/* enable write */
													Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
												end
											else
												begin	/* Low */
													Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
													Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
													Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

													if (pdb2[19])					/* memory address */
														yab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);
													else
														xab_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);

													Rwrite1_L_2 = `true;								/* enable write */
													Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
												end
										end		/* -(Rn) */

						endcase	/* pdb2[13:11] */

					end	/* if pdb2[14]==1	instruction format type 1 */


				else		/* if pdb2[14]==0 */

					begin	/*------------------------------*/
							/*								*/
							/* instruction format type 2	*/
							/*								*/
							/* 6 bit absolute short address	*/
							/*------------------------------*/

						/* memory access */
						case ({pdb2[19], pdb2[15]})
							2'b00	:	xwrite_2 = `true;
							2'b01	:	xread_2  = `true;
							2'b10	:	ywrite_2 = `true;
							2'b11	:	yread_2  = `true;
						endcase

						/* memory address */
						if (pdb2[19])
							yab_2 = { 10'b00000_00000, pdb2[13:8] };
						else
							xab_2 = { 10'b00000_00000, pdb2[13:8] };

					end	/* if pdb2[14]==0	instruction format type 2 */

			end	/* X:  or  Y: */



		else if ( pdb2[23] )
			begin	/*--------------------------------------*/
					/*				X:Y:					*/
					/*										*/
					/* XY Memory Data Move					*/
					/*--------------------------------------*/

				/* the R registers that are used in ea calculations are coming from both banks, one from each using port 1. */
				
				/*------------------------------*/
				/* X memory effective address	*/
				/*------------------------------*/

				/* X memory access */

				if (pdb2[15])
					xread_2 = `true;
				else
					xwrite_2  = `true;


				/* choose addressing mode */
				
				/* R registers: using port 1 for read and write  */

				case (pdb2[12:11])
					2'b00	:	/* (Rn) */
								if (pdb2[10])
									begin	/* High */
										Rraddr1_H_2 = pdb2[9:8];		/* R read  address */
										xab_2 = Rout1_H;
									end
								else
									begin	/* Low */
										Rraddr1_L_2 = pdb2[9:8];		/* R read  address */
										xab_2 = Rout1_L;
									end
								
					2'b01	:	/* (Rn)+Nn */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_H_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Nraddr1_L_2 = pdb2[9:8];							/* N read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end

					2'b10	:	/* (Rn)- */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);		/* updated value */
									end

					2'b11	:	/* (Rn)+ */
								if (pdb2[10])
									begin	/* High */
										Mraddr1_H_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_H_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_H_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);		/* updated value */
									end
								else
									begin	/* Low */
										Mraddr1_L_2 = pdb2[9:8];							/* M read  address */
										Rraddr1_L_2 = pdb2[9:8];							/* R read  address */
										Rwaddr1_L_2 = pdb2[9:8];							/* R write address */

										xab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);		/* updated value */
									end

				endcase		/* X effective address */

				/*------------------------------*/
				/* Y memory effective address	*/
				/*------------------------------*/

				/* Y memory access */

				if (pdb2[22])
					yread_2 = `true;
				else
					ywrite_2  = `true;


				/* choose addressing mode */
				
				/* R registers: using port 1 for read and write. Guaranteed not to write to the same bank as x: addressing does. */
				
				/* If X address is using R4-R7, Y will use R0-R3 	*/
				/* If X address is using R0-R3, Y will use R4-R7 	*/
				/* pdb[10] chooses between the two register banks.	*/ 

				case (pdb2[21:20])
					2'b00	:	/* (Rn) */
								if (pdb2[10])
									begin	/* Y is from Low because X is from High */
										Rraddr1_L_2 = pdb2[14:13];						/* R read address */
										yab_2 = Rout1_L;
									end
								else
									begin	/* Y is from High because X is from Low */
										Rraddr1_H_2 = pdb2[14:13];						/* R read address */
										yab_2 = Rout1_H;
									end
								
					2'b01	:	/* (Rn)+Nn */
								if (pdb2[10])
									begin	/* Y is from Low because X is from High */
										Mraddr1_L_2 = pdb2[14:13];							/* M read  address */
										Nraddr1_L_2 = pdb2[14:13];							/* N read  address */
										Rraddr1_L_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_L_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + Nout1_L, Rout1_L, Mout1_L);/* updated value */
									end
								else
									begin	/* Y is from High because X is from Low */
										Mraddr1_H_2 = pdb2[14:13];							/* M read  address */
										Nraddr1_H_2 = pdb2[14:13];							/* N read  address */
										Rraddr1_H_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_H_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + Nout1_H, Rout1_H, Mout1_H);/* updated value */
									end

					2'b10	:	/* (Rn)- */
								if (pdb2[10])
									begin	/* Y is from Low because X is from High */
										Mraddr1_L_2 = pdb2[14:13];							/* M read  address */
										Rraddr1_L_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_L_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L - 1, Rout1_L, Mout1_L);	/* updated value */
									end
								else
									begin	/* Y is from High because X is from Low */
										Mraddr1_H_2 = pdb2[14:13];							/* M read  address */
										Rraddr1_H_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_H_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H - 1, Rout1_H, Mout1_H);	/* updated value */
									end

					2'b11	:	/* (Rn)+ */
								if (pdb2[10])
									begin	/* Y is from Low because X is from High */
										Mraddr1_L_2 = pdb2[14:13];							/* M read  address */
										Rraddr1_L_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_L_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_L;

										Rwrite1_L_2 = `true;								/* enable write */
										Rin1_L_2 = mod(Rout1_L + 1, Rout1_L, Mout1_L);	/* updated value */
									end
								else
									begin	/* Y is from High because X is from Low */
										Mraddr1_H_2 = pdb2[14:13];							/* M read  address */
										Rraddr1_H_2 = pdb2[14:13];							/* R read  address */
										Rwaddr1_H_2 = pdb2[14:13];							/* R write address */

										yab_2 = Rout1_H;

										Rwrite1_H_2 = `true;								/* enable write */
										Rin1_H_2 = mod(Rout1_H + 1, Rout1_H, Mout1_H);	/* updated value */
									end

				endcase		/* Y effective address */

			end		/* X:Y: */



		else	/* if no operation is required */
			begin
			end
										

	
	end		/* @(pdb2) */




/*======================================================================================*/
/*																						*/
/*	Stage 3	(Execute)				Stage 3	(Execute)				Stage 3	(Execute)	*/
/*																						*/
/*======================================================================================*/


/*------------------------------------------*/
/* Get the new instruction into stage 3		*/
/*------------------------------------------*/

always @(posedge Clk)
	begin
		if (reset)
			pdb3 <= `NOP;
		else
			pdb3 <= pdb2;	/* move the instruction from the Decode to the Execute stage */
	end


/*------------------------------------------*/
/* Decode and carry out the instruction.	*/
/*------------------------------------------*/

always @(	pdb3 or 
			reset or 
			E or 
			U or 
			Z or 
			GDB or 
			Rout1_H or 
			Rout2_H or 
			Rout3_H or 
			Rout1_L or 
			Rout2_L or 
			Rout3_L or 
			Nout1_H or 
			Nout2_H or 
			Nout3_H or 
			Nout1_L or 
			Nout2_L or 
			Nout3_L or 
			Mout1_H or 
			Mout2_H or 
			Mout3_H or 
			Mout1_L or
			Mout2_L or
			Mout3_L
			)

	begin

		/* Initially don't allow writes to any of the register files */
													   
		Rwrite2_L_3 = `false;

		Rwrite2_H_3 = `false;


		Nwrite2_L_3 = `false;

		Nwrite2_H_3 = `false;


		Mwrite2_L_3 = `false;

		Mwrite2_H_3 = `false;



		/* initially don't read or write any of the memories (false) */
		
		xwrite_3 = `false;
		xread_3  = `false;

		ywrite_3 = `false;
		yread_3  = `false;


		/* initially don't permit atomic writing into memory */
		
		xwrite_atomic = `false;
		ywrite_atomic = `false;


		/* initially the carry out is zero */
		
		C = 1'b0;
		
		/* Keep J that goes to PCU at High-Z state until defined by JCLR/LSET */
		/* Another J comes from the data alu and wire-or. */
		
		J = 1'bz;
		
		

		/*--------------------------------------------------------------------------*/
		/*																			*/
		/* 					Decode the incoming instruction							*/
		/*																			*/
		/*--------------------------------------------------------------------------*/

		if ( pdb3[`movefield] == `no_parallel_data_move )
			begin	/*-----------------------------------*/
					/* No parallel data move is required */
					/*-----------------------------------*/
			end
										


		else if ( {pdb3[23:11], pdb3[7:4], pdb3[2:0]} == 20'b00000001_11011_0001_101 )
			begin	/*----------------------------------*/
					/* 				NORM				*/
					/* 									*/
					/* Normalize Accumulator Iteration	*/
					/*----------------------------------*/

					/* This is the second participant in the NORM instruction. The first is data_alu. */

				if ({pdb3[7:4], pdb3[2:0]} == 7'b0001_101)		/* NORM */

					if ( (~E) & U & (~Z) )			/* ASL */
						begin
							if (pdb3[10])
								begin	/* High */
									Rraddr2_H_3 = pdb3[9:8];			/* R read  address */
									Rwaddr2_H_3 = pdb3[9:8];			/* R write address */

									Rwrite2_H_3 = `true;				/* enable write */
									Rin2_H_3 = Rout2_H - 1;				/* updated value */
								end
							else
								begin	/* Low */
									Rraddr2_L_3 = pdb3[9:8];			/* R read  address */
									Rwaddr2_L_3 = pdb3[9:8];			/* R write address */

									Rwrite2_L_3 = `true;				/* enable write */
									Rin2_L_3 = Rout2_L - 1;				/* updated value */
								end
						end		/* ASL */

					else if (E)						/* ASR */
						begin
							if (pdb3[10])
								begin	/* High */
									Rraddr2_H_3 = pdb3[9:8];			/* R read  address */
									Rwaddr2_H_3 = pdb3[9:8];			/* R write address */

									Rwrite2_H_3 = `true;				/* enable write */
									Rin2_H_3 = Rout2_H + 1;				/* updated value */
								end
							else
								begin	/* Low */
									Rraddr2_L_3 = pdb3[9:8];			/* R read  address */
									Rwaddr2_L_3 = pdb3[9:8];			/* R write address */

									Rwrite2_L_3 = `true;				/* enable write */
									Rin2_L_3 = Rout2_L + 1;				/* updated value */
								end
						end		/* ASR */

			end		/* NORM */
										



		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/
					/* No Action */
				
			end		/* DO Class IV */




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end		/* REP Class IV */




		else if ( {pdb3[23:15], pdb3[7], pdb3[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I or II			*/
					/*										*/
					/* No action							*/
					/*--------------------------------------*/

			end		/* REP Class I or II */




		else if ( {pdb3[23:13], pdb3[7:4]} == 15'b00000100_010_0001 )
			begin	/*--------------------------------------*/
					/*					LUA					*/
					/*										*/
					/* Load Updated Address					*/
					/*--------------------------------------*/

				/* choose one of the effective addresses */

				case (pdb3[12:11])
					2'b00	:	/* (Rn)-Nn */
								if (pdb3[10])
									begin		/* read High */
										Mraddr2_H_3 = pdb3[9:8];							/* M read address */
										Nraddr2_H_3 = pdb3[9:8];							/* N read address */
										Rraddr2_H_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];								/* N write address */
														Nwrite2_H_3 = `true;									/* enable write */
														Nin2_H_3 = mod(Rout2_H - Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];								/* N write address */
														Nwrite2_L_3 = `true;									/* enable write */
														Nin2_L_3 = mod(Rout2_H - Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];								/* R write address */
														Rwrite2_H_3 = `true;									/* enable write */
														Rin2_H_3 = mod(Rout2_H - Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];								/* R write address */
														Rwrite2_L_3 = `true;									/* enable write */
														Rin2_L_3 = mod(Rout2_H - Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* R */
									end		/* read High */
									
								else
									begin		/* read Low */
										Mraddr2_L_3 = pdb3[9:8];							/* M read address */
										Nraddr2_L_3 = pdb3[9:8];							/* N read address */
										Rraddr2_L_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];								/* N write address */
														Nwrite2_H_3 = `true;									/* enable write */
														Nin2_H_3 = mod(Rout2_L - Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];								/* N write address */
														Nwrite2_L_3 = `true;									/* enable write */
														Nin2_L_3 = mod(Rout2_L - Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];								/* R write address */
														Rwrite2_H_3 = `true;									/* enable write */
														Rin2_H_3 = mod(Rout2_L - Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];								/* R write address */
														Rwrite2_L_3 = `true;									/* enable write */
														Rin2_L_3 = mod(Rout2_L - Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* R */
									end		/* read Low */


					2'b01	:	/* (Rn)+Nn */
								if (pdb3[10])
									begin		/* read High */
										Mraddr2_H_3 = pdb3[9:8];							/* M read address */
										Nraddr2_H_3 = pdb3[9:8];							/* N read address */
										Rraddr2_H_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];								/* N write address */
														Nwrite2_H_3 = `true;									/* enable write */
														Nin2_H_3 = mod(Rout2_H + Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];								/* N write address */
														Nwrite2_L_3 = `true;									/* enable write */
														Nin2_L_3 = mod(Rout2_H + Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];								/* R write address */
														Rwrite2_H_3 = `true;									/* enable write */
														Rin2_H_3 = mod(Rout2_H + Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];								/* R write address */
														Rwrite2_L_3 = `true;									/* enable write */
														Rin2_L_3 = mod(Rout2_H + Nout2_H, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* R */
									end		/* read High */
									
								else
									begin		/* read Low */
										Mraddr2_L_3 = pdb3[9:8];							/* M read address */
										Nraddr2_L_3 = pdb3[9:8];							/* N read address */
										Rraddr2_L_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];								/* N write address */
														Nwrite2_H_3 = `true;									/* enable write */
														Nin2_H_3 = mod(Rout2_L + Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];								/* N write address */
														Nwrite2_L_3 = `true;									/* enable write */
														Nin2_L_3 = mod(Rout2_L + Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];								/* R write address */
														Rwrite2_H_3 = `true;									/* enable write */
														Rin2_H_3 = mod(Rout2_L + Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];								/* R write address */
														Rwrite2_L_3 = `true;									/* enable write */
														Rin2_L_3 = mod(Rout2_L + Nout2_L, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* R */
									end		/* read Low */

					2'b10	:	/* (Rn)- */
								if (pdb3[10])
									begin		/* read High */
										Mraddr2_H_3 = pdb3[9:8];							/* M read address */
										Rraddr2_H_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];						/* N write address */
														Nwrite2_H_3 = `true;							/* enable write */
														Nin2_H_3 = mod(Rout2_H - 1, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];						/* N write address */
														Nwrite2_L_3 = `true;							/* enable write */
														Nin2_L_3 = mod(Rout2_H - 1, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];						/* R write address */
														Rwrite2_H_3 = `true;							/* enable write */
														Rin2_H_3 = mod(Rout2_H - 1, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];						/* R write address */
														Rwrite2_L_3 = `true;							/* enable write */
														Rin2_L_3 = mod(Rout2_H - 1, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* R */
									end		/* read High */
									
								else
									begin		/* read Low */
										Mraddr2_L_3 = pdb3[9:8];							/* M read address */
										Rraddr2_L_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];						/* N write address */
														Nwrite2_H_3 = `true;							/* enable write */
														Nin2_H_3 = mod(Rout2_L - 1, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];						/* N write address */
														Nwrite2_L_3 = `true;							/* enable write */
														Nin2_L_3 = mod(Rout2_L - 1, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];						/* R write address */
														Rwrite2_H_3 = `true;							/* enable write */
														Rin2_H_3 = mod(Rout2_L - 1, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];						/* R write address */
														Rwrite2_L_3 = `true;							/* enable write */
														Rin2_L_3 = mod(Rout2_L - 1, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* R */
									end		/* read Low */

					2'b11	:	/* (Rn)+ */
								if (pdb3[10])
									begin		/* read High */
										Mraddr2_H_3 = pdb3[9:8];							/* M read address */
										Rraddr2_H_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];						/* N write address */
														Nwrite2_H_3 = `true;							/* enable write */
														Nin2_H_3 = mod(Rout2_H + 1, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];						/* N write address */
														Nwrite2_L_3 = `true;							/* enable write */
														Nin2_L_3 = mod(Rout2_H + 1, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];						/* R write address */
														Rwrite2_H_3 = `true;							/* enable write */
														Rin2_H_3 = mod(Rout2_H + 1, Rout2_H, Mout2_H);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];						/* R write address */
														Rwrite2_L_3 = `true;							/* enable write */
														Rin2_L_3 = mod(Rout2_H + 1, Rout2_H, Mout2_H);	/* updated value */
													end
											end		/* R */
									end		/* read High */
									
								else
									begin		/* read Low */
										Mraddr2_L_3 = pdb3[9:8];							/* M read address */
										Rraddr2_L_3 = pdb3[9:8];							/* R read address */

										if (pdb3[3])	/* choose a destination */
											begin											/* destination: N register */
												if (pdb3[2])
													begin		/* write high N */
														Nwaddr2_H_3 = pdb3[1:0];						/* N write address */
														Nwrite2_H_3 = `true;							/* enable write */
														Nin2_H_3 = mod(Rout2_L + 1, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  N */
														Nwaddr2_L_3 = pdb3[1:0];						/* N write address */
														Nwrite2_L_3 = `true;							/* enable write */
														Nin2_L_3 = mod(Rout2_L + 1, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* N */

										else
											begin											/* destiantion: R register */
												if (pdb3[2])
													begin		/* write high R */
														Rwaddr2_H_3 = pdb3[1:0];						/* R write address */
														Rwrite2_H_3 = `true;							/* enable write */
														Rin2_H_3 = mod(Rout2_L + 1, Rout2_L, Mout2_L);	/* updated value */
													end
												else
													begin		/* write Low  R */
														Rwaddr2_L_3 = pdb3[1:0];						/* R write address */
														Rwrite2_L_3 = `true;							/* enable write */
														Rin2_L_3 = mod(Rout2_L + 1, Rout2_L, Mout2_L);	/* updated value */
													end
											end		/* R */
									end		/* read Low */
									
				endcase		/* pdb3[12:11] */
					
			end		/* LUA */




		else if ( ({pdb3[23:14], pdb3[7:6]} == 12'b00001010_11_01) ||
				  ({pdb3[23:14], pdb3[7:5]} == 13'b00001011_11_011) )
				  
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class III	*/
					/*										*/
					/*	Bit Test and Clear/Set - Class III	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction regarding the AGU's registers.		*/
					/* If the inst. is BTST, no writes are permitted. */
			
				if ( pdb3[13:11] == 3'b010 )
					begin		/*-----------------------*/
								/* address registers (R) */
								/*-----------------------*/

						if (pdb3[10])	/* High */
							begin
								Rraddr2_H_3 = pdb3[9:8];
								{C, Rin2_H_3} = bit_test(Rout2_H, pdb3[4:0], pdb3[5]);

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])	/* the bit requested is less than 16 */
									begin
										Rwaddr2_H_3 = pdb3[9:8];
										Rwrite2_H_3 = (pdb3[16]) ? `false : `true;			/* don't write if BTST */
									end
							end			/* High */
							
						else			/* Low */
							begin
								Rraddr2_L_3 = pdb3[9:8];
								{C, Rin2_L_3} = bit_test(Rout2_L, pdb3[4:0], pdb3[5]);

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])	/* the bit requested is less than 16 */
									begin
										Rwaddr2_L_3 = pdb3[9:8];
										Rwrite2_L_3 = (pdb3[16]) ? `false : `true;			/* don't write if BTST */
									end
							end
					end		/* address registers (R) */
						

				else if ( pdb3[13:11] == 3'b011 )
					begin		/*------------------------------*/
								/* address offset registers (N)	*/
								/*------------------------------*/
								
						if (pdb3[10])
							begin		/* High */
								Nraddr2_H_3 = pdb3[9:8];
								{C, Nin2_H_3} = bit_test(Nout2_H, pdb3[4:0], pdb3[5]);
								Nwaddr2_H_3 = pdb3[9:8];

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])		/* the bit requested is less than 16 */
									Nwrite2_H_3 = (pdb3[16]) ? `false : `true;
							end
						else
							begin		/* Low */
								Nraddr2_L_3 = pdb3[9:8];
								{C, Nin2_L_3} = bit_test(Nout2_L, pdb3[4:0], pdb3[5]);
								Nwaddr2_L_3 = pdb3[9:8];

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])		/* the bit requested is less than 16 */
									Nwrite2_L_3 = (pdb3[16]) ? `false : `true;
							end
					end		/* address offset registers */


				else if ( pdb3[13:11] == 3'b100 )
					begin		/*----------------------------------*/
								/* address modifier registers (M)	*/
								/*----------------------------------*/
								
						if (pdb3[10])
							begin		/* High */
								Mraddr2_H_3 = pdb3[9:8];
								{C, Min2_H_3} = bit_test(Mout2_H, pdb3[4:0], pdb3[5]);
								Mwaddr2_H_3 = pdb3[9:8];

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])		/* the bit requested is less than 16 */
									Mwrite2_H_3 = (pdb3[16]) ? `false : `true;
							end
						else
							begin		/* Low */
								Mraddr2_L_3 = pdb3[9:8];
								{C, Min2_L_3} = bit_test(Mout2_L, pdb3[4:0], pdb3[5]);
								Mwaddr2_L_3 = pdb3[9:8];

								/* write enable only for valid bit number (0-15) */
								if (~pdb3[4])	/* the bit requested is less than 16 */
									Mwrite2_L_3 = (pdb3[16]) ? `false : `true;
							end
					end		/* address modifier registers */

			end		/* BCLR/BSET/BTST Class III */




		else if ( {pdb3[23:16], pdb3[7:4]} == 12'b00000110_1010 )
			begin	/*--------------------------------------*/
					/*			REP Class III				*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* REP Class III */




		else if ( {pdb3[23:16], pdb3[7:4]} == 12'b0000_0110_1000 )
			begin	/*--------------------------------------*/
					/*			DO Class III				*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end		/* DO Class III */




		else if ( {pdb3[23:14], pdb3[7:6]} == 12'b00001010_11_00 )
			begin	/*--------------------------------------*/
					/*		JCLR / JSET Class III			*/
					/*										*/
					/*	Jump if Bit Clear/Set - Class III	*/
					/*--------------------------------------*/

				if ( pdb3[13:11] == 3'b010 )
					begin		/*-----------------------*/
								/* address registers (R) */
								/*-----------------------*/
						
						/* since the tested register is not changed, putting Rin2_?_3 is just for convenience !!! */
						
						/* choose register R */
						
						if (pdb3[10])	/* High */
							begin
								Rraddr2_H_3 = pdb3[9:8];
								{J, Rin2_H_3} = bit_test(Rout2_H, pdb3[4:0], pdb3[5]);
							end
						else			/* Low */
							begin
								Rraddr2_L_3 = pdb3[9:8];
								{J, Rin2_L_3} = bit_test(Rout2_L, pdb3[4:0], pdb3[5]);
							end
							
					end		/* address registers (R) */
						

				else if ( pdb3[13:11] == 3'b011 )
					begin		/*------------------------------*/
								/* address offset registers (N)	*/
								/*------------------------------*/
								
						if (pdb3[10])
							begin		/* High */
								Nraddr2_H_3 = pdb3[9:8];
								{J, Nin2_H_3} = bit_test(Nout2_H, pdb3[4:0], pdb3[5]);
							end
						else
							begin		/* Low */
								Nraddr2_L_3 = pdb3[9:8];
								{J, Nin2_L_3} = bit_test(Nout2_L, pdb3[4:0], pdb3[5]);
							end
					end		/* address offset registers */


				else if ( pdb3[13:11] == 3'b100 )
					begin		/*----------------------------------*/
								/* address modifier registers (M)	*/
								/*----------------------------------*/
								
						if (pdb3[10])
							begin		/* High */
								Mraddr2_H_3 = pdb3[9:8];
								{J, Min2_H_3} = bit_test(Mout2_H, pdb3[4:0], pdb3[5]);
							end
						else
							begin		/* Low */
								Mraddr2_L_3 = pdb3[9:8];
								{J, Min2_L_3} = bit_test(Mout2_L, pdb3[4:0], pdb3[5]);
							end
					end		/* address modifier registers */

			end		/* JCLR/JSET Class III */




		else if ( ({pdb3[23:14], pdb3[7]} == 11'b00001010_01_0) ||
			 	  ({pdb3[23:14], pdb3[7]} == 11'b00001010_00_0) ||
			 	  ({pdb3[23:14], pdb3[7], pdb3[5]} == 12'b00001011_01_0_1) ||
			 	  ({pdb3[23:14], pdb3[7], pdb3[5]} == 12'b00001011_00_0_1) )
			 	  
			begin	/*------------------------------------------*/
					/*		BCLR / BSET / BTST Class I or II	*/
					/*											*/
					/*	Bit Test and Clear/Set - Class I or II	*/
					/*------------------------------------------*/

					/* This is an ATOMIC instruction regarding the data memories.		*/
			
				/* Enabling data to be written back into memory after alteration in the data alu. */
				/* This also resets the coresponding atomic flag. */
				/* If BTST is the inst. (pdb3[16]=1'b1) then no write is permitted. */
				
				if (pdb3[6])
					ywrite_atomic = (pdb3[16]) ? `false : `true;
				else
					xwrite_atomic = (pdb3[16]) ? `false : `true;
					
			end		/* BCLR/BSET/BTST Class I or II */




		else if ( pdb3[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U:					*/
					/* No Action 						*/
					/*----------------------------------*/
			end		/* U: */




		else if ( {pdb3[23:16], pdb3[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				/*------------------------------------------------------------------------*/
				/* ONLY Partially implemented to load immediate data into the M registers */
				/*------------------------------------------------------------------------*/
				
				/* always loads immediate short data from the inst word */

				if (pdb3[4:3] == 2'b00)

					/* Affects the M registers */

					begin

						/* the address of the M register */

						if (pdb3[2])
							Mwaddr2_H_3 = pdb3[1:0];		/* to the High M rf */
						else
							Mwaddr2_L_3 = pdb3[1:0];		/* to the Low  M rf */


						/* the immediate data is treated as an unsigned integer */

						if (pdb3[2])
							Min2_H_3 = {8'h00, pdb3[15:8]};		/* to the High rf */
						else
							Min2_L_3 = {8'h00, pdb3[15:8]};		/* to the Low rf */


						/* enable write to one of M's register files */

						Mwrite2_H_3 = pdb3[2];
						Mwrite2_L_3 = (~pdb3[2]);
					end

			end		/* MOVEC Class IV */




		else if ( {pdb3[23:16], pdb3[7], pdb3[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				if ( pdb3[15] && (pdb3[13:8] != 6'b110100) )		/* write destination register, NOT immediate data */
					begin
						if (pdb3[4:3] == 2'b00)

							/* Affects the M registers */

							begin

								/* the address of the M register */

								if (pdb3[2])
									Mwaddr2_H_3 = pdb3[1:0];		/* to the High M rf */
								else
									Mwaddr2_L_3 = pdb3[1:0];		/* to the Low  M rf */


								/* fetch data */

								if (pdb3[2])
									Min2_H_3 = GDB[`addrbus];		/* to the High rf */
								else
									Min2_L_3 = GDB[`addrbus];		/* to the Low rf */


								/* enable write to one of M's register files */

								Mwrite2_H_3 = pdb3[2];
								Mwrite2_L_3 = (~pdb3[2]);
							end
					end

				
			end		/* MOVEC Class I and II */




		else if ( {pdb3[23:15], pdb3[7]} == 10'b00001010_0_1 )
			begin	/*--------------------------------------*/
					/*		JCLR / JSET Class I or II		*/
					/*										*/
					/*	No Action							*/
					/*--------------------------------------*/
			end		/* JCLR / JSET Class I or II */




		else if ( {pdb3[23:17], pdb3[14]} == 8'b0000100_0 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class II  or  R:Y  Class II					*/
					/*																*/
					/* No Action													*/
					/*--------------------------------------------------------------*/
			end		/* X:R Class II  or  R:Y  Class II */
			



		else if ( pdb3[23:18] == 6'b001000 )
			begin	/*----------------------------------*/
					/*				R					*/
					/*									*/
					/* Register to Register Data Move	*/
					/* Condition Codes ARE changed.		*/
					/*									*/
					/* Active when the destination is	*/
					/* either an R or an N register.	*/
					/*----------------------------------*/

				/* A register gets the gdb 16 LS bits */

				if ( pdb3[12:11] == 2'b11 )
					/*-------------------------*/
					/* Destination: N register */
					/*-------------------------*/

					if (pdb3[10])
						begin		/* High */
							Nwaddr2_H_3 = pdb3[9:8];
							Nwrite2_H_3 = `true;
							Nin2_H_3 = GDB[`addrbus];
						end
					else
						begin		/* Low */
							Nwaddr2_L_3 = pdb3[9:8];
							Nwrite2_L_3 = `true;
							Nin2_L_3 = GDB[`addrbus];
						end

				else if ( pdb3[12:11] == 2'b10 )
					/*-------------------------*/
					/* Destination: R register */
					/*-------------------------*/

					if (pdb3[10])	/* High */
						begin
							Rwaddr2_H_3 = pdb3[9:8];
							Rwrite2_H_3 = `true;
							Rin2_H_3 = GDB[`addrbus];
						end
					else			/* Low */
						begin
							Rwaddr2_L_3 = pdb3[9:8];
							Rwrite2_L_3 = `true;
							Rin2_L_3 = GDB[`addrbus];
						end

			end		/* R */




		else if ( {pdb3[23:20], pdb3[18]} == 5'b0100_0 )
			begin	/*------------------------------*/
					/* 				L: 				*/
					/*------------------------------*/
			end		/* L: */
																



		else if ( pdb3[23:20] == 4'b0001 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class I  or  R:Y Class I					*/
					/*																*/
					/* No Action													*/
					/*--------------------------------------------------------------*/
			end		/* X:R Class I  or  R:Y Class I */




		else if ( pdb3[23:21] == 3'b001 )
			begin	/*----------------------------------*/
					/*				I:					*/
					/*									*/
					/* Immediate Short Data Move 		*/
					/* Condition Codes are NOT changed.	*/
					/*----------------------------------*/


				/* choose either R or N register type */

				if (pdb3[20:19] == 2'b11)
					begin	/*-------------*/
							/* N registers */
							/*-------------*/

						/* the address of the N register */

						if (pdb3[18])
							Nwaddr2_H_3 = pdb3[17:16];		/* to the High N rf */
						else
							Nwaddr2_L_3 = pdb3[17:16];		/* to the Low  N rf */


						/* the immediate data is treated as an unsigned integer */

						if (pdb3[18])
							Nin2_H_3 = {8'h00, pdb3[15:8]};		/* to the High rf */
						else
							Nin2_L_3 = {8'h00, pdb3[15:8]};		/* to the Low rf */


						/* enable write to one of N's register files */

						Nwrite2_H_3 = pdb3[18];
						Nwrite2_L_3 = (~pdb3[18]);
					end		/* N */
					

				else if (pdb3[20:19] == 2'b10)
					begin	/*-------------*/
							/* R registers */
							/*-------------*/
							
						/* the immediate data is treated as an unsigned integer */

						if (pdb3[18])	/* High */
							begin
								Rwaddr2_H_3 = pdb3[17:16];
								Rwrite2_H_3 = `true;
								Rin2_H_3 = {8'h00, pdb3[15:8]};
							end
						else			/* Low */
							begin
								Rwaddr2_L_3 = pdb3[17:16];
								Rwrite2_L_3 = `true;
								Rin2_L_3 = {8'h00, pdb3[15:8]};
							end
					end		/* R */

			end		/* I */



		else if ( pdb3[23:22] == 2'b01 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:				*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/* Condition codes ARE affected		*/
					/*----------------------------------*/

				if ( pdb3[15]  && (pdb3[13:8] != 6'b110100) )		/* it's not an immediate data mode */

					/*--------------------------*/
					/* Destination: a REGISTER	*/
					/*--------------------------*/

					/* Registers R and N are the destination in the AGU.	*/
					/* Input data arrive from the GDB 16 LS bits 		*/

					begin
						if ( pdb3[21:20] == 2'b10 )
							begin	/*-------------------------*/
									/* Destination: R register */
									/*-------------------------*/
									
								if (pdb3[18])	/* High */
									begin
										Rwaddr2_H_3 = pdb3[17:16];
										Rwrite2_H_3 = `true;
										Rin2_H_3 = GDB[`addrbus];
									end
								else			/* Low */
									begin
										Rwaddr2_L_3 = pdb3[17:16];
										Rwrite2_L_3 = `true;
										Rin2_L_3 = GDB[`addrbus];
									end
							end		/* R */
							

						else if ( pdb3[21:20] == 2'b11 )
							begin	/*-------------------------*/
									/* Destination: N register */
									/*-------------------------*/
									
								if (pdb3[18])	/* High */
									begin
										Nwaddr2_H_3 = pdb3[17:16];
										Nwrite2_H_3 = `true;
										Nin2_H_3 = GDB[`addrbus];
									end
								else			/* Low */
									begin
										Nwaddr2_L_3 = pdb3[17:16];
										Nwrite2_L_3 = `true;
										Nin2_L_3 = GDB[`addrbus];
									end
							end		/* N */

					end		/* pdb3[15]==1	*/

			end		/* X: or Y: */




		else if ( pdb3[23] )
			begin	/*--------------------------------------*/
					/*				X:Y:					*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
			end		/* X:Y: */
			


		else	/* if no operation is required */
			begin
			end 										

	
	end		/* @(pdb3) */



endmodule		/* agu */
