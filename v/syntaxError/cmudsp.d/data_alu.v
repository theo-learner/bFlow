/*	File:	data_alu.v	  								*/

/*	module name: data_alu								*/

/*	Description: The data ALU block of the 56K core.	*/


/*  Author:	Nitzan Weinberg								*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	data_alu															*/
/*																				*/
/********************************************************************************/

module data_alu (
	reset,
	PDB,
	XDB,
	YDB,
	REPEAT,
	AGU_C,
	S1,
	S0,
	CCR,
	CCR_from_alu,
	Swrite,
	Lwrite,
	J,
	Clk
	);


/*==================================================================================*/
/*============						I/O direction						============*/
/*==================================================================================*/

input reset;
input [`databus] PDB;

inout [`databus] XDB;
inout [`databus] YDB;

input REPEAT;
input AGU_C;
input S1;
input S0;
input [7:0] CCR;

output [7:0] CCR_from_alu;
output Swrite;
output Lwrite;
output J;

input Clk;



/*==================================================================================*/
/*============							I/O type						============*/
/*==================================================================================*/

wire reset;
wire [`databus] PDB;
wire [`databus] XDB;
wire [`databus] YDB;
wire REPEAT;				/* REP instruction is in progress - coming from the PCU */
wire AGU_C;					/* Carry bit coming from the AGU during BCLR/BSET/BTST inst that concern AGU registers. */
wire S1;					/* scaling bit in MR - from PCU */
wire S0;					/* scaling bit in MR - from PCU */
wire [7:0] CCR;				/* CCR register coming from the PCU */

wire [7:0] CCR_from_alu;		/* CCR bits generated in the data alu and go to the PCU to be latched in teh CCR regsiter */
reg J;						/* The tested bit for conditional jumps (JCLR/JSET) is passed on to the PCU. */

wire Clk;



/*==================================================================================*/
/*===========						Internal Nets						============*/
/*==================================================================================*/

reg [`databus] pdb2;		/* an instruction inside stage 2 (Decode)	*/
reg [`databus] pdb3;		/* an instruction inside stage 3 (Execute)	*/

reg [`databus] xdb_out_p2;	/* input into the xdb_out bus in the parallel section of stage 2 */
reg [`databus] xdb_out;		/* input into the XDB_out register that drives the XDB bus */
reg [`databus] XDB_out;		/* Register - drives the XDB bus */

reg xdb_out_write_p2;		/* signals data written on xdb_out_p2 */
reg xdb_out_write;			/* write enable to the XDB_out register */
reg XDB_write;				/* FF - write enable to the XDB bus */

reg [`databus] ydb_out_p2;	/* input into the ydb_out bus in the parallel section of stage 2 */
reg [`databus] ydb_out;		/* input into the YDB_out (from several sources) */
reg [`databus] YDB_out;		/* Register - drives the YDB bus */

reg ydb_out_write_p2;			/* signals data written on ydb_out_p2 */
reg ydb_out_write;				/* write enable to the YDB_out register */
reg YDB_write;				/* FF - write enable to the YDB bus */

reg [`acc] pre_round;		/* pre round intermediate result used as input to the rounding function in MPYR */

reg [`acc] cmpm_abs_s2;		/* the absolute value of source 2 in CMPM instruction */


/*------------------------------------------------------------------------------------------------------*/
/* absolute address / immediate data effective addressing mode											*/
/*																										*/
/* A flag  - when true signals that a source's absolute memory address or an immediate data is used.	*/
/* In this case TWO instruction words are required:														*/
/* The instruction and the absolute address/immediate data.												*/
/*------------------------------------------------------------------------------------------------------*/

reg absolute_immediate;		/* changed in stage 2 to reflect either an an absolute address or an immediate data in a TWO word instruction */


/*--------------------------------------------------------------*/
/* Status Register (SR) - Condition Code Register (CCR) portion */
/*--------------------------------------------------------------*/

/* All are TRUE condition code bits - `true when the condition is met	*/
/* They are changed EVERY instruction - there is no write enable for them */

/* latched	bits */

/* bit 7	:	S	Scaling			*/
wire S;
reg S_in;								/* The new S bit before latching										*/
reg S_p2;								/* The new S bit value coming from stage 2 parallel move section		*/
reg S_p2_2;								/* The new S bit value coming from stage 2 parallel moves:				*/
										/* X:Y:, X:R and Y:R (Class I) sections.								*/
										/* A second _p2 decleration is required	because TWO parallel			*/
										/* moves of A/B into 24-bit destinations are possible	 				*/
										/* (hence having two drivers to the same S CC bit).						*/
reg S_a2;								/* The new S bit value coming from stage 2 arithmetic section			*/
reg S_p3;								/* The new S bit value coming from stage 3 parallel move section		*/
reg S_a3;								/* The new S bit value coming from stage 3 arithmetic section			*/

wor Swrite;								/* The write enable to the S bit										*/
reg Swrite_p2;							/* The write enable for an S bit generated in stage 2 parallel section	*/
reg Swrite_p2_2;						/* The write enable for an S bit generated in stage 2 parallel section	*/
reg Swrite_a2;							/* The write enable for an S bit generated in stage 2 arith section		*/
reg Swrite_p3;							/* The write enable for an S bit generated in stage 3 parallel section	*/
reg Swrite_a3;							/* The write enable for an S bit generated in stage 3 arith section		*/


/* bit 6	:	L	Limit			*/
wire L;
wor L_in;								/* The new L bit before latching										*/
reg L_p2;								/* The new L bit value coming from stage 2 parallel move section		*/
reg L_p2_2;								/* The new L bit value coming from stage 2 parallel moves:				*/
										/* X:Y:, X:R and Y:R (Class I) sections.								*/
										/* A second _p2 decleration is required	because TWO parallel			*/
										/* moves of A/B into 24-bit destinations are possible	 				*/
										/* (hence having two drivers to the same S CC bit).						*/
reg L_a2;								/* The new L bit value coming from stage 2 arithmetic section			*/
reg L_p3;								/* The new L bit value coming from stage 3 parallel move section		*/
reg L_a3;								/* The new L bit value coming from stage 3 arithmetic section			*/

wor Lwrite;								/* The write enable to the L bit										*/
reg Lwrite_p2;							/* The write enable for an L bit generated in stage 2 parallel section	*/
reg Lwrite_p2_2;						/* The write enable for an L bit generated in stage 2 parallel section	*/
reg Lwrite_a2;							/* The write enable for an L bit generated in stage 2 arith section		*/
reg Lwrite_p3;							/* The write enable for an L bit generated in stage 3 parallel section	*/
reg Lwrite_a3;							/* The write enable for an L bit generated in stage 3 arith section		*/


/* NOT latched	bits	*/

/* The following bits are calculated from the result at the end of a data ALU operation.	*/

/* bit 5	:	E	Extension		*/
wire E;
wor E_in;								/* The new E bit from various drivers 		*/
reg E_p2;								/* E from parallel move section in stage 2 	*/
reg E_p3;								/* E from parallel move section in stage 3 	*/
reg E_a3;								/* E from arithmetic section in stage 3 	*/

/* bit 4	:	U	Unnormalized	*/
wire U;
wor U_in;								/* The new U bit from various drivers 		*/
reg U_p2;								/* U from parallel move section in stage 2 	*/
reg U_p3;								/* U from parallel move section in stage 3 	*/
reg U_a3;								/* U from arithmetic section in stage 3		*/

/* bit 3	:	N	Negative		*/
wire N;
wor N_in;								/* The new N bit from various drivers 		*/
reg N_p2;								/* N from parallel move section in stage 2	*/
reg N_p3;								/* N from parallel move section in stage 3 	*/
reg N_a3;								/* N from arithmetic section in stage 3 	*/

/* bit 2	:	Z	Zero			*/
wire Z;
wor Z_in;								/* The new Z bit from various drivers 		*/
reg Z_p2;								/* Z from parallel move section in stage 2 	*/
reg Z_p3;								/* Z from parallel move section in stage 3 	*/
reg Z_a3;								/* Z from arithmetic section in stage 3 	*/

/* bit 1	:	O	Overflow		*/
wire V;
wor V_in;								/* The new V bit from various drivers 		*/
reg V_p2;								/* V from parallel move section in stage 2 	*/
reg V_p3;								/* V from parallel move section in stage 3 	*/
reg V_a3;								/* V from arithmetic section in stage 3 	*/

/* bit 0	:	C	Carry			*/
wire C;
wor C_in;								/* The new C bit from various drivers 		*/
reg C_p2;								/* C from parallel move section in stage 2 	*/
reg C_p3;								/* C from parallel move section in stage 3 	*/
reg C_a3;								/* C from arithmetic section in stage 3 	*/


/*----------------------------------------------------------------------------------------------------------*/
/* internal register declaration																			*/
/*																											*/
/*     - the register itself																				*/
/* _p2  - a value from the parallel section in stage 2 that needs to be written into the register			*/
/* _a2  - a value from the arithmetic section in stage 2 that needs to be written into the register			*/
/* _p3  - a value from the parallel section in stage 3 that needs to be written into the register			*/
/* _a3  - a value from the arithmetic section in stage 3 that needs to be written into the register			*/
/* _in  - input into the register. This is the Wired-OR value of all the inputs into that register			*/
/*		 generated by NON-ATOMIC inst. (all but one are in High-Z state).									*/
/*	   * An atomic inst. (BCLR, BSET) is using _a2 and _a3 directly and not the _in bus (for A and B only).	*/
/*----------------------------------------------------------------------------------------------------------*/

/* registers x0, x1, y0 and y1 can be updated ONLY in the parallel sections of stages 2 and 3 */

reg [`databus] x0;			/* A register */
reg [`databus] x0_p2;
reg [`databus] x0_p3;
reg [`databus] x0_a3;
wor [`databus] x0_in;

reg [`databus] x1;			/* A register */
reg [`databus] x1_p2;
reg [`databus] x1_p3;
reg [`databus] x1_a3;
wor [`databus] x1_in;

reg [`databus] y0;			/* A register */
reg [`databus] y0_p2;
reg [`databus] y0_p3;
reg [`databus] y0_a3;
wor [`databus] y0_in;

reg [`databus] y1;			/* A register */
reg [`databus] y1_p2;
reg [`databus] y1_p3;
reg [`databus] y1_a3;
wor [`databus] y1_in;


/* Accumulators a0, a1, a2, b0, b1 and b2 are updated in both the parallel and the arithmetic section of stages 2 and 3	*/

reg [`databus] a0;			/* A register */
reg [`databus] a0_p2;
reg [`databus] a0_a2;
reg [`databus] a0_p3;
reg [`databus] a0_a3;
wor [`databus] a0_in;

reg [`databus] a1;			/* A register */
reg [`databus] a1_p2;
reg [`databus] a1_a2;
reg [`databus] a1_p3;
reg [`databus] a1_a3;
wor [`databus] a1_in;

reg [`ext] a2;				/* A register */
reg [`ext] a2_p2;
reg [`ext] a2_a2;
reg [`ext] a2_p3;
reg [`ext] a2_a3;
wor [`ext] a2_in;

reg [`databus] b0;			/* A register */
reg [`databus] b0_p2;
reg [`databus] b0_a2;
reg [`databus] b0_p3;
reg [`databus] b0_a3;
wor [`databus] b0_in;

reg [`databus] b1;			/* A register */
reg [`databus] b1_p2;
reg [`databus] b1_a2;
reg [`databus] b1_p3;
reg [`databus] b1_a3;
wor [`databus] b1_in;

reg [`ext] b2;				/* A register */
reg [`ext] b2_p2;
reg [`ext] b2_a2;
reg [`ext] b2_p3;
reg [`ext] b2_a3;
wor [`ext] b2_in;



/*------------------------------------------------------------------------------*/
/* internal registers and accumulators CONTROLs 								*/
/*																				*/
/* _p2 - comes from the parallel move section in stage 2						*/
/* _p3 - comes from the parallel move section in stage 3						*/
/* _a3 - comes from the arith/logic section in satge 3							*/
/* _or - the wired-OR write enables from all the stages. 						*/
/*		 This control is connected DIRECTLY to the register's write-enable		*/
/*	   * There is a special atomic write enable that overrides these controls.	*/
/*------------------------------------------------------------------------------*/

/* registers x0, x1, y0 and y1 can be written ONLY in the parallel sections of stages 2 and 3	*/

reg x0write_p2;
reg x0write_p3;
reg x0write_a3;
wor x0write_or;

reg x1write_p2;
reg x1write_p3;
reg x1write_a3;
wor x1write_or;

reg y0write_p2;
reg y0write_p3;
reg y0write_a3;
wor y0write_or;

reg y1write_p2;
reg y1write_p3;
reg y1write_a3;
wor y1write_or;


/* Accumulators a0, a1, a2, b0, b1 and b2 can be written in during the parallel or the arithmetic sections */

/* a */
reg a0write_p2;
reg a0write_p3;
reg a0write_a3;
wor a0write_or;

reg a1write_p2;
reg a1write_p3;
reg a1write_a3;
wor a1write_or;

reg a2write_p2;
reg a2write_p3;
reg a2write_a3;
wor a2write_or;

/* b */
reg b0write_p2;
reg b0write_p3;
reg b0write_a3;
wor b0write_or;

reg b1write_p2;
reg b1write_p3;
reg b1write_a3;
wor b1write_or;

reg b2write_p2;
reg b2write_p3;
reg b2write_a3;
wor b2write_or;


/*----------------------------------------------------------------------------------------------------------*/
/* Atomic register and accumulator write CONTROLs															*/
/*																											*/
/* _a2 - comes from the arithmetic section in stage 2														*/
/* _a3 - comes from the arithmetic section in stage 3														*/
/*		 These controls override other register write-enable controls.										*/
/* Since an atomic inst. that changes an a register (BCLR, BSET and BTST) takes 2 cycles to execute,		*/
/* the inst. right afterwards is not allowed to change the same register's content while it is in stage 2.	*/
/* If the following is an atomic inst. it doesn't have ANY effect (not even when it is in stage 3).			*/
/* Latched atomic flags and special write-enables are being used to differ atomic from regular inst.		*/
/*----------------------------------------------------------------------------------------------------------*/

/*-------------*/
/* xdb and ydb */
/*-------------*/

/* Output buses and selectors for atomic inst. (BCLR and BSET). */
/* They are used in stage 3 and prevent other inst. in stage 2 of writing to the same bus that the atomic inst in stage 3 is using. */

reg [`databus] xdb_out_atomic_a3;	/* Output into the xdb_out bus that is a result of an atomic inst. */
									/* Generated in the arithmetic section of stage 3 */
reg [`databus] ydb_out_atomic_a3;	/* Output into the ydb_out bus that is a result of an atomic inst. */
									/* Generated in the arithmetic section of stage 3 */

reg xdb_out_write_atomic_a3;		/* select the bus carrying the value of an atomic inst. rather than that of other inst. */
reg ydb_out_write_atomic_a3;		/* select the bus carrying the value of an atomic inst. rather than that of other inst. */


/*-------------------*/
/* X and Y registers */
/*-------------------*/

/* No need for a flag as atomic inst. write these registers ONLY in stage 3, therefore an atomic write to them	*/
/* has priority over other writes in stage 2.	*/

reg x0write_atomic_a3;
reg x1write_atomic_a3;

reg y0write_atomic_a3;
reg y1write_atomic_a3;


/*-----------------------*/
/* accumulator registers */
/*-----------------------*/

reg Aatomic;			/* Flag - latched */
reg Batomic;			/* Flag - latched */

reg Aread_atomic_a2;	/* reads accumulator A in stage 2 */

reg a2write_atomic_a2;	/* write enable from arithmetic section in stage 2 */
reg a1write_atomic_a2;	/* write enable from arithmetic section in stage 2 */
reg a0write_atomic_a2;	/* write enable from arithmetic section in stage 2  */

reg a2write_atomic_a3;	/* write enable from arithmetic section in stage 3 */
reg a1write_atomic_a3;	/* write enable from arithmetic section in stage 3 */
reg a0write_atomic_a3;	/* write enable from arithmetic section in stage 3 */

reg Bread_atomic_a2;	/* reads accumulator B in stage 2 */

reg b2write_atomic_a2;	/* write enable from arithmetic section in stage 2 */
reg b1write_atomic_a2;	/* write enable from arithmetic section in stage 2 */
reg b0write_atomic_a2;	/* write enable from arithmetic section in stage 2 */

reg b2write_atomic_a3;	/* write enable from arithmetic section in stage 3 */
reg b1write_atomic_a3;	/* write enable from arithmetic section in stage 3*/
reg b0write_atomic_a3;	/* write enable from arithmetic section in stage 3*/



/*==============================================================================================*/
/*																								*/
/*	Functions								Functions							Functions		*/
/*																								*/
/*==============================================================================================*/

/*------------------------------------------------------------------*/
/*																	*/
/*	function:	CCR_S												*/
/*																	*/
/*	Compute the Scaling Bit in CCR									*/
/*																	*/
/*------------------------------------------------------------------*/

function CCR_S;

input S1;
input S0;
input [`databus] acc;

	begin
		case ({S1, S0})
			2'b00	:	/* no scaling	*/
						CCR_S = acc[46-24] ^ acc[45-24];
			2'b01	:	/* scale down	*/
						CCR_S = acc[47-24] ^ acc[46-24];
			2'b10	:	/* scale up		*/
						CCR_S = acc[45-24] ^ acc[44-24];
			2'b11	:	/* Not Defined	*/
						CCR_S = 1'bx;
		endcase
	end
	
endfunction		/* CCR_S */



/*------------------------------------------------------------------*/
/*																	*/
/*	function:	CCR_E												*/
/*																	*/
/*	Compute the Extension Bit in CCR								*/
/*																	*/
/*------------------------------------------------------------------*/

function CCR_E;

input S1;

input S0;

input [31:0] acc;

	begin
		case ({S1, S0})
			2'b00	:	/* No Scaling	*/
						if ( (acc[55-24:47-24] == 9'b000000000) | (acc[55-24:47-24] == 9'b111111111) )
							CCR_E = 1'b0;
						else
							CCR_E = 1'b1;
			2'b01	:	/* Scale Down	*/
						if ( (acc[55-24:48-24] == 8'b00000000) | (acc[55-24:48-24] == 8'b11111111) )
							CCR_E = 1'b0;
						else
							CCR_E = 1'b1;
			2'b10	:	/* Scale Up		*/
						if ( (acc[55-24:46-24] == 10'b0000000000) | (acc[55-24:46-24] == 10'b1111111111) )
							CCR_E = 1'b0;
						else
							CCR_E = 1'b1;
			2'b11	:	/* Not Defined	*/
						CCR_E = 1'bx;
		endcase
	end
	
endfunction		/* CCR_E */


/*------------------------------------------------------------------*/
/*																	*/
/*	function:	CCR_U												*/
/*																	*/
/*	Compute the Unnormalized Bit in CCR								*/
/*																	*/
/*------------------------------------------------------------------*/

function CCR_U;

input S1;

input S0;

input [31:0] acc;

	begin
		case ({S1, S0})
			2'b00	:	/* No Scaling	*/
						CCR_U = acc[47-24] ~^ acc[46-24];
			2'b01	:	/* Scale Down	*/
						CCR_U = acc[48-24] ~^ acc[47-24];
			2'b10	:	/* Scale Up		*/
						CCR_U = acc[46-24] ~^ acc[45-24];
			2'b11	:	/* Not Defined	*/
						CCR_U = 1'bx;
		endcase
	end
	
endfunction		/* CCR_U */



/*------------------------------------------------------------------*/
/*																	*/
/*	function:	CCR_N												*/
/*																	*/
/*	Compute the Negative Bit in CCR									*/
/*																	*/
/*------------------------------------------------------------------*/

function CCR_N;

input acc;

	begin
		CCR_N = acc;
	end
	
endfunction		/* CCR_N */



/*------------------------------------------------------------------*/
/*																	*/
/*	function:	CCR_Z												*/
/*																	*/
/*	Compute the Zero Bit in CCR										*/
/*																	*/
/*------------------------------------------------------------------*/

function CCR_Z;

input [`acc] acc;

	begin
		if (acc == 56'h0)
			CCR_Z = 1'b1;
		else
			CCR_Z = 1'b0;
	end
	
endfunction		/* CCR_Z */


/*----------------------------------------------------------------------*/
/*																		*/
/*	function:	right_shifter											*/
/*																		*/
/*	Right shift a 24-bit signed number and sign extend it.				*/
/*	The source is initially places in MSB (47:24) and then shifted.		*/
/*	Can shift between 1 and 23 bits to the right.						*/
/*	The functions return a 56-bit signed number.						*/
/*																		*/
/*----------------------------------------------------------------------*/

function [`acc] right_shifter;

input [`databus] data_in;		/* source to be shifted */
input [4:0] shift;				/* the number of bits to shift */

reg [47:0] longdata;			/* the extended source to be shifted */


	begin
		longdata = { data_in, 24'h000000 };		/* the source is put at MSB position in the long word */
		
		case (shift)
			5'b00001	:	right_shifter = {{  9 {longdata[47]}}, longdata[47:1]  };
			5'b00010	:	right_shifter = {{ 10 {longdata[47]}}, longdata[47:2]  };
			5'b00011	:	right_shifter = {{ 11 {longdata[47]}}, longdata[47:3]  };
			5'b00100	:	right_shifter = {{ 12 {longdata[47]}}, longdata[47:4]  };
			5'b00101	:	right_shifter = {{ 13 {longdata[47]}}, longdata[47:5]  };
			5'b00110	:	right_shifter = {{ 14 {longdata[47]}}, longdata[47:6]  };
			5'b00111	:	right_shifter = {{ 15 {longdata[47]}}, longdata[47:7]  };
			5'b01000	:	right_shifter = {{ 16 {longdata[47]}}, longdata[47:8]  };
			5'b01001	:	right_shifter = {{ 17 {longdata[47]}}, longdata[47:9]  };
			5'b01010	:	right_shifter = {{ 18 {longdata[47]}}, longdata[47:10] };
			5'b01011	:	right_shifter = {{ 19 {longdata[47]}}, longdata[47:11] };
			5'b01100	:	right_shifter = {{ 20 {longdata[47]}}, longdata[47:12] };
			5'b01101	:	right_shifter = {{ 21 {longdata[47]}}, longdata[47:13] };
			5'b01110	:	right_shifter = {{ 22 {longdata[47]}}, longdata[47:14] };
			5'b01111	:	right_shifter = {{ 23 {longdata[47]}}, longdata[47:15] };
			5'b10000	:	right_shifter = {{ 24 {longdata[47]}}, longdata[47:16] };
			5'b10001	:	right_shifter = {{ 25 {longdata[47]}}, longdata[47:17] };
			5'b10010	:	right_shifter = {{ 26 {longdata[47]}}, longdata[47:18] };
			5'b10011	:	right_shifter = {{ 27 {longdata[47]}}, longdata[47:19] };
			5'b10100	:	right_shifter = {{ 28 {longdata[47]}}, longdata[47:20] };
			5'b10101	:	right_shifter = {{ 29 {longdata[47]}}, longdata[47:21] };
			5'b10110	:	right_shifter = {{ 30 {longdata[47]}}, longdata[47:22] };
			5'b10111	:	right_shifter = {{ 31 {longdata[47]}}, longdata[47:23] };
			default		:	;	/* No Action */
		endcase		/* shift */
	end


endfunction		/* right_shifter */



/*------------------------------------------------------------------*/
/*																	*/
/*	function:	round												*/
/*																	*/
/*	Convergent round a 56-bit number according to the scaling mode.	*/
/*																	*/
/*------------------------------------------------------------------*/

/* Convergent round with clearing of the LS 24-bits */

function [`acc] round;

input S1;
input S0;
input [`acc] data_in;

reg [`acc] test_rounding;

	begin
		case ({S1, S0})
			2'b00	:	/* No Scaling 	*/
						begin
							test_rounding = data_in + 56'h800000;
							if (test_rounding[23:0] == 24'h000000)
								round = {test_rounding[55:25], 25'h0000000};
							else
								round = {test_rounding[55:24], 24'h000000};
						end
						
			2'b01	:	/* Scale Down 	*/
						begin
							test_rounding = data_in + 56'h1000000;
							if (test_rounding[24:0] == 25'h0000000)
								round = {test_rounding[55:26], 26'h0000000};
							else
								round = {test_rounding[55:25], 25'h0000000};
						end
						
			2'b10	:	/* Scale Up 	*/
						begin
							test_rounding = data_in + 56'h400000;
							/* bit 23 doesn't count anyway in the MSB portion,			*/
							/* therefore no need to test the special convergence case.  */
							round = {test_rounding[55:24], 24'h000000};
						end
						
			default	:	;		/* no Action */
		endcase

	end
	
endfunction		/* round */



/*------------------------------------------------------------------*/
/*																	*/
/*	function:	abs													*/
/*																	*/
/*	Returns the absolute of a 56-bit input number.					*/
/*																	*/
/*------------------------------------------------------------------*/

function [`acc] abs;

input [`acc] data_in;

	begin
		if (data_in[55])
			abs = (~data_in) + 1'b1;
		else
			abs = data_in;	
	end

endfunction		/* abs */



/*------------------------------------------------------------------------------*/
/*																				*/
/*	function:	mul																*/
/*																				*/
/*	Multiply two 24-bit signed numbers and result in a 56-bit signed product.	*/
/*																				*/
/*------------------------------------------------------------------------------*/

function [`acc] mul;

input [`databus] data_in1;
input [`databus] data_in2;

reg [`databus] positive1;	/* the abs of first negative input */
reg [`databus] positive2;	/* the abs of second negative input */

reg [45:0] product;			/* the 46-bit unsigned product of the two POSITIVE inputs */

	begin
		case ( {data_in1[23], data_in2[23]} )
			2'b00	:	begin								/* data_in1 is positive, data_in2 is positive */
							product = data_in1[22:0] * data_in2[22:0];
							mul = { 9'h000, product, 1'b0 };
						end

			2'b01	:	begin								/* data_in1 is positive, data_in2 is negative */
							positive2 = 1 + (~data_in2);
							if (positive2[23])											/* data_in2 is (-1.0) */
								begin
									product = positive2 * data_in1[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;	
								end
							else
								begin
									product = positive2[22:0] * data_in1[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;
								end
						end

			2'b10	:	begin								/* data_in1 is negative, data_in2 is positive */
							positive1 = 24'h1 + (~data_in1);
							if (positive1[23])											/* data_in1 is (-1.0) */
								begin
									product = positive1 * data_in2[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;	
								end
							else
								begin
									product = positive1[22:0] * data_in2[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;
								end
						end

			2'b11	:	begin								/* data_in1 is negative, data_in2 is negative */
							positive1 = 24'h1 + (~data_in1);
							positive2 = 24'h1 + (~data_in2);

							case ( {positive1[23], positive2[23]} )
								2'b00	:	begin							/* data_in1 is NOT (-1.0) and data_in2 is NOT (-1.0) */
												product = positive1[22:0] * positive2[22:0];
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b01	:	begin							/* data_in1 is NOT (-1.0) but data_in2 is (-1.0) */
												product = positive1[22:0] * positive2;
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b10	:	begin							/* data_in1 is (-1.0) but data_in2 is NOT (-1.0) */
												product = positive1 * positive2[22:0];
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b11	:	begin							/* data_in1 is (-1.0) and data_in2 is (-1.0) */
												product = positive1[23:1] * positive2[23:1];
												mul = { 8'b00000000, product[44:0], 3'b000 };	
											end
							endcase
						end
							
		endcase		/* sign of the sources */
			
	end
	
endfunction		/* mul */



/*--------------------------------------------------------------------------------------*/
/*																						*/
/*	function:	bit_test																*/
/*																						*/
/*	Tests a bit in a register (or accumulator) and sets or clears it.					*/
/*	To be use with atomic instructions: BCLR, BSET										*/
/* 	Returns: {The value of the tested bit (1 bit), The updated register value (24 bit)}	*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

function [24:0] bit_test;

input [`databus] source;	/* The register to be tested */ 
input [4:0] bit;			/* Designates what bit to test */
input set_clear;			/* if equals one - set a bit, if zero - clear a bit */

	begin
		case (bit)		/* choose the bit to be tested and cleared */
			5'b00000	:	bit_test = {source[0],  source[23:1],  set_clear};
			5'b00001	:	bit_test = {source[1],  source[23:2],  set_clear, source[0]};
			5'b00010	:	bit_test = {source[2],  source[23:3],  set_clear, source[1:0]};
			5'b00011	:	bit_test = {source[3],  source[23:4],  set_clear, source[2:0]};
			5'b00100	:	bit_test = {source[4],  source[23:5],  set_clear, source[3:0]};
			5'b00101	:	bit_test = {source[5],  source[23:6],  set_clear, source[4:0]};
			5'b00110	:	bit_test = {source[6],  source[23:7],  set_clear, source[5:0]};
			5'b00111	:	bit_test = {source[7],  source[23:8],  set_clear, source[6:0]};
			5'b01000	:	bit_test = {source[8],  source[23:9],  set_clear, source[7:0]};
			5'b01001	:	bit_test = {source[9],  source[23:10], set_clear, source[8:0]};
			5'b01010	:	bit_test = {source[10], source[23:11], set_clear, source[9:0]};
			5'b01011	:	bit_test = {source[11], source[23:12], set_clear, source[10:0]};
			5'b01100	:	bit_test = {source[12], source[23:13], set_clear, source[11:0]};
			5'b01101	:	bit_test = {source[13], source[23:14], set_clear, source[12:0]};
			5'b01110	:	bit_test = {source[14], source[23:15], set_clear, source[13:0]};
			5'b01111	:	bit_test = {source[15], source[23:16], set_clear, source[14:0]};
			5'b10000	:	bit_test = {source[16], source[23:17], set_clear, source[15:0]};
			5'b10001	:	bit_test = {source[17], source[23:18], set_clear, source[16:0]};
			5'b10010	:	bit_test = {source[18], source[23:19], set_clear, source[17:0]};
			5'b10011	:	bit_test = {source[19], source[23:20], set_clear, source[18:0]};
			5'b10100	:	bit_test = {source[20], source[23:21], set_clear, source[19:0]};
			5'b10101	:	bit_test = {source[21], source[23:22], set_clear, source[20:0]};
			5'b10110	:	bit_test = {source[22], source[23],    set_clear, source[21:0]};
			5'b10111	:	bit_test = {source[23],                set_clear, source[22:0]};
			default		:	;		/* No Action */
		endcase		/* bit */
	end

endfunction		/* bit_test */




/*==============================================================================================*/
/*==============================================================================================*/
/*																								*/
/*	Processes								Processes							Processes		*/
/*																								*/
/*==============================================================================================*/
/*==============================================================================================*/


/*==============================================================================*/
/*																				*/
/*	atomic flags																*/
/*																				*/
/*==============================================================================*/

/* Active when an atomic inst. has either A or B accumulators as its destination. */

always @(posedge Clk)
	begin
		if (reset)
			begin
				Aatomic <= `false;
				Batomic <= `false;
			end
		else
			begin
				/* First read of an accumulator (A or B) by an atomic inst. sets the atomic flag. 					*/
				/* The flag is reset after one clock cycle when execution comes to it end in stage 3.				*/
				/* A write might not be neccessary in stage 2, but is always done in stage 3 (for BCLR and BSET).	*/
				
				/* A succeeding atomic inst. (the next clock cycle) that touches the same accumulator						*/
				/* won't have any effect! and so are inst. that write to any of the accumulator registers during stage 2.	*/
				
				Aatomic <= (Aatomic) ? 1'b0 : Aread_atomic_a2;
				Batomic <= (Batomic) ? 1'b0 : Bread_atomic_a2;
			end
	end




/*==============================================================================================*/
/*																								*/
/* Internal registers																			*/
/*																								*/
/*==============================================================================================*/


/*--------------------------------------------------------------------------*/
/* determine the write enable control for each of the internal registers	*/
/* connected in a wired-OR fashion											*/
/*--------------------------------------------------------------------------*/

assign x0write_or = x0write_p2;
assign x0write_or = x0write_p3;
assign x0write_or = x0write_a3;

assign x1write_or = x1write_p2;
assign x1write_or = x1write_p3;
assign x1write_or = x1write_a3;

assign y0write_or = y0write_p2;
assign y0write_or = y0write_p3;
assign y0write_or = y0write_a3;

assign y1write_or = y1write_p2;
assign y1write_or = y1write_p3;
assign y1write_or = y1write_a3;


assign a0write_or = a0write_p2;
assign a0write_or = a0write_p3;
assign a0write_or = a0write_a3;

assign a1write_or = a1write_p2;
assign a1write_or = a1write_p3;
assign a1write_or = a1write_a3;

assign a2write_or = a2write_p2;
assign a2write_or = a2write_p3;
assign a2write_or = a2write_a3;


assign b0write_or = b0write_p2;
assign b0write_or = b0write_p3;
assign b0write_or = b0write_a3;

assign b1write_or = b1write_p2;
assign b1write_or = b1write_p3;
assign b1write_or = b1write_a3;

assign b2write_or = b2write_p2;
assign b2write_or = b2write_p3;
assign b2write_or = b2write_a3;


/*--------------------------------------------------*/
/* Determine the input into each of the registers	*/
/* connected in a wired-OR fashion					*/
/*--------------------------------------------------*/

/* registers x0, x1, y0 and y1 */

assign x0_in = x0_p2;
assign x0_in = x0_p3;
assign x0_in = x0_a3;

assign x1_in = x1_p2;
assign x1_in = x1_p3;
assign x1_in = x1_a3;

assign y0_in = y0_p2;
assign y0_in = y0_p3;
assign y0_in = y0_a3;

assign y1_in = y1_p2;
assign y1_in = y1_p3;
assign y1_in = y1_a3;

/* Accumulators a0, a1, a2, b0, b1 and b2	*/

assign a0_in = a0_p2;
assign a0_in = a0_p3;
assign a0_in = a0_a3;

assign a1_in = a1_p2;
assign a1_in = a1_p3;
assign a1_in = a1_a3;

assign a2_in = a2_p2;
assign a2_in = a2_p3;
assign a2_in = a2_a3;

assign b0_in = b0_p2;
assign b0_in = b0_p3;
assign b0_in = b0_a3;

assign b1_in = b1_p2;
assign b1_in = b1_p3;
assign b1_in = b1_a3;

assign b2_in = b2_p2;
assign b2_in = b2_p3;
assign b2_in = b2_a3;


/*----------------------*/
/* register latching	*/
/*----------------------*/

always @(posedge Clk)
	begin
		if (x0write_atomic_a3)
			x0 <= x0_a3;
		else if (x0write_or)
			x0 <= x0_in;
		else
			x0 <= x0;
			
		if (x1write_atomic_a3)
			x1 <= x1_a3;
		else if (x1write_or)
			x1 <= x1_in;
		else
			x1 <= x1;
			
		if (y0write_atomic_a3)
			y0 <= y0_a3;
		else if (y0write_or)
			y0 <= y0_in;
		else
			y0 <= y0;
			
		if (y1write_atomic_a3)
			y1 <= y1_a3;
		else if (y1write_or)
			y1 <= y1_in;
		else
			y1 <= y1;
			
		
		/* A */
		
		if ( (~Aatomic) && a0write_atomic_a2 )
			a0 <= a0_a2;
		else if ( Aatomic && a0write_atomic_a3 )
			a0 <= a0_a3;
		else if ( (~Aatomic) && a0write_or )
			a0 <= a0_in;
		else
			a0 <= a0;
			
		if ( (~Aatomic) && a1write_atomic_a2 )
			a1 <= a1_a2;
		else if ( Aatomic && a1write_atomic_a3 )
			a1 <= a1_a3;
		else if ( (~Aatomic) && a1write_or )
			a1 <= a1_in;
		else
			a1 <= a1;
			
		if ( (~Aatomic) && a2write_atomic_a2 )
			a2 <= a2_a2;
		else if ( Aatomic && a2write_atomic_a3 )
			a2 <= a2_a3;
		else if ( (~Aatomic) && a2write_or )
			a2 <= a2_in;
		else
			a2 <= a2;

		
		/* B */
		
		if ( (~Batomic) && b0write_atomic_a2 )
			b0 <= b0_a2;
		else if ( Batomic && b0write_atomic_a3 )
			b0 <= b0_a3;
		else if ( (~Batomic) && b0write_or )
			b0 <= b0_in;
		else
			b0 <= b0;
			
		if ( (~Batomic) && b1write_atomic_a2 )
			b1 <= b1_a2;
		else if ( Batomic && b1write_atomic_a3 )
			b1 <= b1_a3;
		else if ( (~Batomic) && b1write_or )
			b1 <= b1_in;
		else
			b1 <= b1;
			
		if ( (~Batomic) && b2write_atomic_a2 )
			b2 <= b2_a2;
		else if ( Batomic && b2write_atomic_a3 )
			b2 <= b2_a3;
		else if ( (~Batomic) && b2write_or )
			b2 <= b2_in;
		else
			b2 <= b2;

	end



/*==============================================================================================*/
/*																								*/
/*	CCR																							*/
/*																								*/
/*==============================================================================================*/

/* CCR bits generated in the data alu, and go to the PCU */

assign CCR_from_alu = {S_in, L_in, E_in, U_in, N_in, Z_in, V_in, C_in};


/* CCR bits coming from the PCU */

assign S = CCR[7];
assign L = CCR[6];
assign E = CCR[5];
assign U = CCR[4];
assign N = CCR[3];
assign Z = CCR[2];
assign V = CCR[1];
assign C = CCR[0];


/*==============================================================================================*/
/*																								*/
/*	CCR bits are assigned values by multiple drivers, and their write enable					*/
/*																								*/
/*==============================================================================================*/

/* The multiple drivers for each condition code bit are connected with a WOR net, coming from both stages 2 and 3 */

always @(	S_p2 or
			S_p2_2 or
			S_a2 or
			S_p3 or
			S_a3
			)
	begin					/* a sticky bit that once it goes to '1', only an arithmetic operation can change */
		if (S)
			S_in = S_a3;	/* only an arithmetic operation can reset S */
		else
			S_in = (S_p2 || S_p2_2 || S_a2 || S_p3);
	end

assign Swrite = Swrite_p2;
assign Swrite = Swrite_p2_2;
assign Swrite = Swrite_a2;
assign Swrite = Swrite_p3;
assign Swrite = Swrite_a3;


assign L_in = L_p2;
assign L_in = L_a2;
assign L_in = L_p2_2;
assign L_in = L_p3;
assign L_in = L_a3;

assign Lwrite = Lwrite_p2;
assign Lwrite = Lwrite_p2_2;
assign Lwrite = Lwrite_a2;
assign Lwrite = Lwrite_p3;
assign Lwrite = Lwrite_a3;


assign E_in = E_p2;
assign E_in = E_p3;
assign E_in = E_a3;

assign U_in = U_p2;
assign U_in = U_p3;
assign U_in = U_a3;

assign N_in = N_p2;
assign N_in = N_p3;
assign N_in = N_a3;

assign Z_in = Z_p2;
assign Z_in = Z_p3;
assign Z_in = Z_a3;

assign V_in = V_p2;
assign V_in = V_p3;
assign V_in = V_a3;

assign C_in = C_p2;
assign C_in = C_p3;
assign C_in = C_a3;


/*==============================================================================================*/
/*																								*/
/*	Output Data to XDB and YDB Buses															*/
/*																								*/
/*==============================================================================================*/

/*---------*/
/* xdb_out */
/* ydb_out */
/* --------*/

/* select the data that appear on the xdb and ydb internal buses and a write enable */

always @(	xdb_out_p2 or 
			ydb_out_p2 or 
			xdb_out_write_p2 or 
			ydb_out_write_p2 or 
			xdb_out_atomic_a3 or 
			ydb_out_atomic_a3 or 
			xdb_out_write_atomic_a3 or 
			ydb_out_write_atomic_a3)

	begin
		/* X */
		
		if (xdb_out_write_atomic_a3)
			begin
				xdb_out = xdb_out_atomic_a3;
				xdb_out_write = xdb_out_write_atomic_a3;
			end
			
		else
			begin
				xdb_out = xdb_out_p2;
				xdb_out_write = xdb_out_write_p2;
			end

		
		/* Y */
		
		if (ydb_out_write_atomic_a3)
			begin
				ydb_out = ydb_out_atomic_a3;
				ydb_out_write = ydb_out_write_atomic_a3;
			end
			
		else
			begin
				ydb_out = ydb_out_p2;
				ydb_out_write = ydb_out_write_p2;
			end
	end


/*---------*/
/* XDB_out */
/* YDB_out */
/*---------*/

/* latch the output into the XDB_out and YDB_out registers as well as the write enable for the corresponding buses */

always @(posedge Clk)
	begin
		if (reset)
			begin
				XDB_write <= `false;
				XDB_out   <= 24'hzzzzzz;
			end
		else
			begin
				XDB_write <= xdb_out_write;
				XDB_out   <= (xdb_out_write) ? xdb_out : XDB_out;
			end
	end
	
	
always @(posedge Clk)
	begin
		if (reset)
			begin
				YDB_write <= `false;
				YDB_out   <= 24'hzzzzzz;
			end
		else
			begin
				YDB_write <= ydb_out_write;
				YDB_out   <= (ydb_out_write) ? ydb_out : YDB_out;
			end
	end
	

/*---------*/
/* XDB bus */
/* YDB bus */
/*---------*/

/* assign the output registers to the XDB/YDB buses if a write enable is true */

assign XDB = (XDB_write) ? XDB_out : 24'hzzzzzz;
assign YDB = (YDB_write) ? YDB_out : 24'hzzzzzz;






/*==============================================================================================*/
/*==============================================================================================*/
/*																								*/
/*	Stage 2 (Decode)					Stage 2 (Decode)					Stage 2 (Decode)	*/
/*																								*/
/*==============================================================================================*/
/*==============================================================================================*/

always @(posedge Clk)
	begin
		if (reset)
			pdb2 <= `NOP;
		else if (REPEAT)
			pdb2 <= pdb2;		/* REP instruction in progress */
		else
			begin
				/* Fetch the instruction from the PDB and into Decode stage */
				/* unless an absolute address or immediate data is used as a second instruction word. */
				
				pdb2 <= (absolute_immediate) ? `NOP : PDB;
				
			end	/* else */
	end
	

/*--------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------*/
/*																						*/
/* 									Parallel moves in Stage 2 							*/
/*																						*/
/*--------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------*/

/* Deals with parallel data move instructions.	*/


always @(	pdb2 or 
			x0 or 
			x1 or 
			y0 or 
			y1 or 
			a0 or 
			a1 or 
			a2 or 
			b0 or 
			b1 or 
			b2 or 
			xdb_out or 
			ydb_out or
			XDB or
			YDB)

	begin
		
		/* initially put all register write-enable controls in High-Z state	*/
		
		x0write_p2 = `false;
		x1write_p2 = `false;
		y0write_p2 = `false;
		y1write_p2 = `false;
		a0write_p2 = `false;
		a1write_p2 = `false;
		a2write_p2 = `false;
		b0write_p2 = `false;
		b1write_p2 = `false;
		b2write_p2 = `false;


		/* initilally High-Z all the inputs to the registers	*/
		
		x0_p2 = 24'hzzzzzz;
		x1_p2 = 24'hzzzzzz;
		y0_p2 = 24'hzzzzzz;
		y1_p2 = 24'hzzzzzz;
		a0_p2 = 24'hzzzzzz;
		a1_p2 = 24'hzzzzzz;
		a2_p2 =  8'hzz;
		b0_p2 = 24'hzzzzzz;
		b1_p2 = 24'hzzzzzz;
		b2_p2 =  8'hzz;


		/* initially the absolute/immediate mode is off */

		absolute_immediate = `false;


		/* Initially clear all the condition codes in CCR */

		S_p2 = 1'b0;
		S_p2_2 = 1'b0;
		
		Swrite_p2 = `false;
		Swrite_p2_2 = `false;

		L_p2 = 1'b0;
		L_p2_2 = 1'b0;
		
		Lwrite_p2 = `false;
		Lwrite_p2_2 = `false;

		E_p2 = 1'b0;
		U_p2 = 1'b0;
		N_p2 = 1'b0;
		Z_p2 = 1'b0;
		V_p2 = 1'b0;
		C_p2 = 1'b0;
			

		/* initially don't write the xdb or ydb buses */
		
		xdb_out_write_p2 = `false;
		ydb_out_write_p2 = `false;
		
		
		
		/*---------------------------------*/
		/* Decode the incoming instruction */
		/*---------------------------------*/
		
		if (pdb2[`movefield] == `no_parallel_data_move)
			begin	/*--------------------------------------*/
					/* No parallel data move is required	*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
			end
										



		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*										*/
					/* Jump with an effective address		*/
					/*--------------------------------------*/

				/* if an absolute address is in the second program word, nullify that word */
				
				if (pdb2[13:8] == 6'b110000)
					begin
						absolute_immediate = `true;
					end
				
			end		/* JMP Class II */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/
				
				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */

				absolute_immediate = `true;
				
			end		/* DO Class IV */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* 	Repeat Next Instruction				*/
					/*--------------------------------------*/
				case (pdb2[12:8])
					`x0	:	begin
								xdb_out_p2 = x0;
								xdb_out_write_p2 = `true;
							end
					`x1	:	begin
								xdb_out_p2 = x1;
								xdb_out_write_p2 = `true;
							end
					`y0	:	begin
								ydb_out_p2 = y0;
								ydb_out_write_p2 = `true;
							end
					`y1	:	begin
								ydb_out_p2 = y1;
								ydb_out_write_p2 =  `true;
							end
					`a0	:	begin
								xdb_out_p2 = a0;
								xdb_out_write_p2 = `true;
							end
					`b0	:	begin
								ydb_out_p2 = b0;
								ydb_out_write_p2 = `true;
							end
					`a2	:	begin
								xdb_out_p2 = {16'h0000, a2};
								xdb_out_write_p2 = `true;
							end
					`b2	:	begin
								ydb_out_p2 = {16'h0000, b2};
								ydb_out_write_p2 = `true;
							end
					`a1	:	begin
								xdb_out_p2 = a1;
								xdb_out_write_p2 = `true;
							end
					`b1	:	begin
								ydb_out_p2 = b1;
								ydb_out_write_p2 = `true;
							end

					`a	:	begin
								S_p2 = CCR_S(S1, S0, a1);
								Swrite_p2 = `true;
								
								xdb_out_write_p2 = `true;
								
								if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
									begin
										xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									xdb_out_p2 = a1;
							end

					`b	:	begin
								S_p2 = CCR_S(S1, S0, b1);
								Swrite_p2 = `true;

								ydb_out_write_p2 = `true;

								if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
									begin
										ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									ydb_out_p2 = b1;
							end

					default : ;		/* no action */

				endcase		/* pdb2[12:8] source */


			end 	/* REP Class IV */




		else if ( {pdb2[23:15], pdb2[7], pdb2[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I or II			*/
					/*										*/
					/* No action							*/
					/*--------------------------------------*/

			end		/* REP Class I or II */




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

				absolute_immediate = `true;
				
			end		/* DO Class III */




		else if ( ({pdb2[23:14], pdb2[7]}   == 11'b00001010_01_1) ||
				  ({pdb2[23:14], pdb2[7]}   == 11'b00001010_00_1) ||
				  ({pdb2[23:14], pdb2[7:6]} == 12'b00001010_11_00) )
			begin	/*----------------------------------------------*/
					/*		JCLR / JSET Class I, II or III			*/
					/*												*/
					/*	Jump if Bit Clear/Set - Class I, II or III	*/
					/*----------------------------------------------*/

				/* An absolute address WORD is ALWAYS supplied in the next program word. */
				
				absolute_immediate = `true;
					
			end		/* JCLR/JSET Class I, II or III */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_01_0) ||
				  ({pdb2[23:14], pdb2[7], pdb2[5]} == 12'b00001011_01_0_1) )
				  
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class I		*/
					/*										*/
					/*	Bit Test and Clear/Set - Class I	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction		*/
					
				/* check if an absolute address WORD is used. If so nullify the next coming instruction. */
				
				if (pdb2[13:8] == 6'b110000)
					absolute_immediate = `true;
					
			end		/* BCLR/BSET/BTST Class I */




		else if ( pdb2[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U					*/
					/*									*/
					/* No Action			 			*/
					/*----------------------------------*/
			end		/* U */




		else if ( {pdb2[23:16], pdb2[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC  Class IV */




		else if ( {pdb2[23:16], pdb2[7], pdb2[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/
					
				if (pdb2[14])		/* Class I */
					if ( (pdb2[13:8] == 6'b110000) || (pdb2[13:8] == 6'b110100) )
						absolute_immediate = `true;		/* absolute address or immediate data is in use */
						
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

				if (pdb2[15])
						/*----------------------------------*/
						/* R:Y Class II move instruction	*/
						/*----------------------------------*/
					begin
						if (pdb2[16])
							begin	/* Y0 -> B  &  B -> Y:ea */

								/*---------------------------------*/
								/* put B on the output bus ydb_bus */
								/*---------------------------------*/

								S_p2 = CCR_S(S1, S0, b1);
								Swrite_p2 = `true;
								
								ydb_out_write_p2 = `true;
								
								if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
									begin
										ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									ydb_out_p2 = b1;

								/*---------*/	
								/* Y0 -> B */
								/*---------*/

								b2_p2 = { 8 {y0[23]} };		/* sign extention */
								b1_p2 = y0;
								b0_p2 = 24'h000000;			/* zero */
								b2write_p2 = `true;
								b1write_p2 = `true;
								b0write_p2 = `true;

							end
						else
							begin	/* Y0 -> A  &  A -> Y:ea */

								/*----------------------------------*/
								/* put A on the output bus xdb_bus. */
								/*----------------------------------*/

								S_p2 = CCR_S(S1, S0, a1);
								Swrite_p2 = `true;
								
								xdb_out_write_p2 = `true;	/* write enable */
								
								if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
									begin
										xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									xdb_out_p2 = a1;

								/*---------*/	
								/* Y0 -> A */
								/*---------*/

								a2_p2 = { 8 {y0[23]} };		/* sign extention */
								a1_p2 = y0;
								a0_p2 = 24'h000000;			/* zero */
								a2write_p2 = `true;
								a1write_p2 = `true;
								a0write_p2 = `true;
							end

					end		/* R:Y */

				else
						/*----------------------------------*/
						/* X:R Class II move instruction	*/
						/*----------------------------------*/
					begin
						if (pdb2[16])
							begin	/* B -> x:ea & X0 -> B */

								/*------------------------------*/
								/* put B on output bus ydb_out. */
								/*------------------------------*/

								S_p2 = CCR_S(S1, S0, b1);
								Swrite_p2 = `true;
								
								ydb_out_write_p2 = `true;
								
								if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
									begin
										ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									ydb_out_p2 = b1;

								/*---------*/	
								/* X0 -> B */
								/*---------*/

								b2_p2 = { 8 {x0[23]} };		/* sign extention */
								b1_p2 = x0;
								b0_p2 = 24'h000000;			/* zero */
								b2write_p2 = `true;
								b1write_p2 = `true;
								b0write_p2 = `true;

							end
						else
							begin	/* A -> x:ea & X0 -> A */

								/*---------------------------------*/
								/* put A on the output bus xdb_out */
								/*---------------------------------*/

								S_p2 = CCR_S(S1, S0, a1);
								Swrite_p2 = `true;

								xdb_out_write_p2 = `true;	/* write enable */								

								if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
									begin
										xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									xdb_out_p2 = a1;

								/*---------*/	
								/* X0 -> A */
								/*---------*/

								a2_p2 = { 8 {x0[23]} };		/* sign extention */
								a1_p2 = x0;
								a0_p2 = 24'h000000;			/* zero */
								a2write_p2 = `true;
								a1write_p2 = `true;
								a0write_p2 = `true;
							end

					end		/* X:R */

			end		/* X:R Class II  or  R:Y Class II */




		else if ( pdb2[23:18] == 6'b001000 )
			begin	/*----------------------------------*/
					/*				R:					*/
					/*									*/
					/* Register to Register Data Move	*/
					/* Condition Codes ARE changed.		*/
					/*									*/
					/* Active when the SOURCE is		*/
					/* a data ALU register.				*/
					/*----------------------------------*/


				/*--------------------------------------------------------------*/
				/* When the destination is an AGU register: 					*/
				/* ----------------------------------------						*/
				/* The data alu register's contents appear on XDB bus during	*/
				/* the next clock cycle. That is, it is available to the AGU	*/
				/* during the Execute stage of that instruction.				*/
				/*																*/
				/* When the destination is a data ALU register:					*/
				/* --------------------------------------------					*/
				/* The (possibly shifted/saturated value) is captured by the	*/
				/* destination at the next clock cycle, by reading the xdb_out	*/
				/* bus INSIDE the data ALU.										*/
				/*--------------------------------------------------------------*/

				/*------------------------------------------------------------------*/
				/* If the SOURCE is a data alu register								*/
				/* place the source on either XDB or YDB data buses.				*/
				/*																	*/
				/* If a data alu register is ALSO a DESTINATION (pdb2[12] == 0),	*/
				/* DON'T allow that data to be written onto the						*/
				/* XDB and YDB buses.												*/
				/*------------------------------------------------------------------*/

				case (pdb2[17:13])
					`x0	:	begin
								xdb_out_p2 = x0;
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`x1	:	begin
								xdb_out_p2 = x1;
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`y0	:	begin
								ydb_out_p2 = y0;
								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`y1	:	begin
								ydb_out_p2 = y1;
								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`a0	:	begin
								xdb_out_p2 = a0;
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`b0	:	begin
								ydb_out_p2 = b0;
								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`a2	:	begin
								xdb_out_p2 = {16'h0000, a2};
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`b2	:	begin
								ydb_out_p2 = {16'h0000, b2};
								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`a1	:	begin
								xdb_out_p2 = a1;
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end
					`b1	:	begin
								ydb_out_p2 = b1;
								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;
							end

					`a	:	begin
								S_p2 = CCR_S(S1, S0, a1);
								Swrite_p2 = `true;
								
								xdb_out_write_p2 = (pdb2[12]) ? `true : `false;
								
								if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
									begin
										xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									xdb_out_p2 = a1;
							end

					`b	:	begin
								S_p2 = CCR_S(S1, S0, b1);
								Swrite_p2 = `true;

								ydb_out_write_p2 = (pdb2[12]) ? `true : `false;

								if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
									begin
										ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
										L_p2 = 1'b1;									/* limiting has occurred */
										Lwrite_p2 = `true;
									end
								else
									ydb_out_p2 = b1;
							end

					default : ;		/* no action */

				endcase		/* pdb2[17:13] source */


				/*--------------------------------------------------------------------------*/
				/* If the source is a data alu AND the destination is a data ALU register	*/
				/*--------------------------------------------------------------------------*/

				/* put the source data alu register on the input to the destination,	*/
				/* whether it's coming from the xdb_out or the ydb_out.					*/
				/* choose the destination data alu register	and enable a write.			*/

				if (~(pdb2[17]))	/* when the source is a data alu register */
					case (pdb2[12:8])	/* choose the data alu destination register */
						`x0	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	x0_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	x0_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									x0write_p2 = `true;
								end
						`x1	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	x1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	x1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									x1write_p2 = `true;
								end
						`y0	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	y0_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	y0_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									y0write_p2 = `true;
								end
						`y1	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	y1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	y1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									y1write_p2 = `true;
								end
						`a0	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	a0_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	a0_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									a0write_p2 = `true;
								end
						`b0	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	b0_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	b0_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									b0write_p2 = `true;
								end
						`a2	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	a2_p2 = xdb_out[`ext];
										`y0, `y1, `b0, `b1, `b2, `b	:	a2_p2 = ydb_out[`ext];
										default						:	;					/* no action */
									endcase
									a2write_p2 = `true;
								end
						`b2	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	b2_p2 = xdb_out[`ext];
										`y0, `y1, `b0, `b1, `b2, `b	:	b2_p2 = ydb_out[`ext];
										default						:	;					/* no action */
									endcase
									b2write_p2 = `true;
								end
						`a1	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	a1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	a1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									a1write_p2 = `true;
								end
						`b1	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	b1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	b1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase
									b1write_p2 = `true;
								end
						`a	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	a2_p2 = { 8 {xdb_out[23]} };	/* sign ext */
										`y0, `y1, `b0, `b1, `b2, `b	:	a2_p2 = { 8 {ydb_out[23]} };	/* sign ext	*/
										default						:	;					/* no action */
									endcase

									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	a1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	a1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase

									a0_p2 = 24'h000000;			/* zero */
									a2write_p2 = `true;
									a1write_p2 = `true;
									a0write_p2 = `true;
								end
						`b	:	begin
									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	b2_p2 = { 8 {xdb_out[23]} };	/* sign ext */
										`y0, `y1, `b0, `b1, `b2, `b	:	b2_p2 = { 8 {ydb_out[23]} };	/* sign ext */
										default						:	;					/* no action */
									endcase

									case (pdb2[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	b1_p2 = xdb_out;
										`y0, `y1, `b0, `b1, `b2, `b	:	b1_p2 = ydb_out;
										default						:	;					/* no action */
									endcase

									b0_p2 = 24'h000000;			/* zero */
									b2write_p2 = `true;
									b1write_p2 = `true;
									b0write_p2 = `true;
								end

						default : ;		/* no Action */
						
					endcase		/* pdb2[12:8] - destination	*/

			end		/* R */




		else if ( {pdb2[23:20], pdb2[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/*----------------------------------*/

				/* if an absolute address is used in Class I */
				
				if (pdb2[14:8] == 7'b1_110000)
					absolute_immediate = `true;
				
								
				if (~pdb2[15])
					begin		/* registers are written into memory */
						
						/* access data buses */
						xdb_out_write_p2 = `true;
						ydb_out_write_p2 = `true;

						/* LLL - choose the source registers */
						case ( {pdb2[19], pdb2[17:16]} )
							3'b000	:	/* A10 = A1  A0 */
										begin
											xdb_out_p2 = a1;
											ydb_out_p2 = a0;
										end

							3'b001	:	/* B10 = B1  B0 */
										begin
											xdb_out_p2 = b1;
											ydb_out_p2 = b0;
										end

							3'b010	:	/* X = X1  X0 */
										begin
											xdb_out_p2 = x1;
											ydb_out_p2 = x0;
										end

							3'b011	:	/* Y10 = Y1  Y0 */
										begin
											xdb_out_p2 = y1;
											ydb_out_p2 = y0;
										end

							3'b100	:	/* A = {A1,A0} */
										begin
											/* treat {a1,a0} as a 48-bit signed number and limit it if necessary */
											
											S_p2 = CCR_S(S1, S0, a1);
											Swrite_p2 = `true;

											if ( CCR_E(S1, S0, {a2, a1}) )								/* Extention bits in use */
												begin
													xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													ydb_out_p2 = ( a2[7] ) ? 24'h000000 : 24'hffffff;	/* limit */
													L_p2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2 = `true;
												end
											else
												begin
													xdb_out_p2 = a1;
													ydb_out_p2 = a0;
												end
										end		/* A */

							3'b101	:	/* B = {B1,B0} */
										begin
											/* treat {b1,b0} as a 48-bit signed number and limit it if necessary */
											
											S_p2 = CCR_S(S1, S0, b1);
											Swrite_p2 = `true;

											if ( CCR_E(S1, S0, {b2, b1}) )								/* Extention bits in use */
												begin
													xdb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													ydb_out_p2 = ( b2[7] ) ? 24'h000000 : 24'hffffff;	/* limit */
													L_p2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2 = `true;
												end
											else
												begin
													xdb_out_p2 = b1;
													ydb_out_p2 = b0;
												end
										end		/* B */

							3'b110	:	/* AB = A  B */
										begin
											/* treat A and B as seperate signed numbers and limit each of them if necessary */
											
											/* A */
											
											S_p2 = CCR_S(S1, S0, a1);
											Swrite_p2 = `true;

											if ( CCR_E(S1, S0, {a2, a1}) )								/* Extention bits in use */
												begin
													xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													L_p2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2 = `true;
												end
											else
												xdb_out_p2 = a1;
											
											
											/* B */
											
											S_p2_2 = CCR_S(S1, S0, b1);
											Swrite_p2_2 = `true;

											if ( CCR_E(S1, S0, {b2, b1}) )								/* Extention bits in use */
												begin
													ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													L_p2_2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2_2 = `true;
												end
											else
												ydb_out_p2 = b1;

										end		/* AB */

							3'b111	:	/* BA = B  A */
										begin
											/* treat A and B as seperate signed numbers and limit each of them if necessary */
											
											/* B onto XDB */
											
											S_p2 = CCR_S(S1, S0, b1);
											Swrite_p2 = `true;

											if ( CCR_E(S1, S0, {b2, b1}) )								/* Extention bits in use */
												begin
													xdb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													L_p2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2 = `true;
												end
											else
												xdb_out_p2 = b1;


											/* A onto YDB */
											
											S_p2_2 = CCR_S(S1, S0, a1);
											Swrite_p2_2 = `true;

											if ( CCR_E(S1, S0, {a2, a1}) )								/* Extention bits in use */
												begin
													ydb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
													L_p2_2 = 1'b1;										/* limiting has occurred */
													Lwrite_p2_2 = `true;
												end
											else
												ydb_out_p2 = a1;
											
										end		/* BA */
							
						endcase		/* LLL */

					end		/* W=0 */

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

					if ( ({pdb2[15], pdb2[13:8]} == 7'b1_110100) || ({pdb2[15], pdb2[13:8]} == 7'b1_110000) )
								/* Active if an absolute address or immediate data are used	*/
								/* (a TWO word instruction format).							*/
						begin
							absolute_immediate = `true;

							if (pdb2[14])
								begin	/*-------------*/
										/* R:Y Class I */
										/*-------------*/
										
									if (pdb2[13:8] == 6'b110100)		/* immediate data */
										case (pdb2[17:16])
											2'b00	:	/* y0 */
														begin
															y0_p2 = YDB;
															y0write_p2 = `true;
														end
											2'b01	:	/* y1 */
														begin	
															y1_p2 = YDB;
															y1write_p2 = `true;
														end
											2'b10	:	/* A */
														begin
															a2_p2 = { 8 {XDB[23]} };
															a1_p2 = XDB;
															a0_p2 = 24'h000000;
															a2write_p2 = `true;
															a1write_p2 = `true;
															a0write_p2 = `true;
														end
											2'b11	:	/* B */
														begin
															b2_p2 = { 8 {YDB[23]} };
															b1_p2 = YDB;
															b0_p2 = 24'h000000;
															b2write_p2 = `true;
															b1write_p2 = `true;
															b0write_p2 = `true;
														end
										endcase		/* pdb2[17:16] */
								end		/* R:Y Class I */

							else
								begin	/*-------------*/
										/* X:R Class I */
										/*-------------*/
									if (pdb2[13:8] == 6'b110100)		/* immediate data */
										case (pdb2[19:18])
											2'b00	:	/* x0 */
														begin
															x0_p2 = XDB;
															x0write_p2 = `true;
														end
											2'b01	:	/* x1 */
														begin	
															x1_p2 = XDB;
															x1write_p2 = `true;
														end
											2'b10	:	/* A */
														begin
															a2_p2 = { 8 {XDB[23]} };
															a1_p2 = XDB;
															a0_p2 = 24'h000000;
															a2write_p2 = `true;
															a1write_p2 = `true;
															a0write_p2 = `true;
														end
											2'b11	:	/* B */
														begin
															b2_p2 = { 8 {YDB[23]} };
															b1_p2 = YDB;
															b0_p2 = 24'h000000;
															b2write_p2 = `true;
															b1write_p2 = `true;
															b0write_p2 = `true;
														end
										endcase		/* pdb2[19:18] */
								
								end		/* X:R Class I */

						end		/* absolute/immediate */



					if (pdb2[14])
						/*------------------------------*/
						/* R:Y Class I move instruction	*/
						/*------------------------------*/

						begin

							/* move an accumulator into an X register, instruction format S1,D1 */

							case (pdb2[19:18])
								2'b00	:	/* A -> x0 */
											begin
												S_p2 = CCR_S(S1, S0, a1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
													begin
														x0_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													x0_p2 = a1;

												x0write_p2 = `true;
											end

								2'b01	:	/* A -> x1 */
											begin
												S_p2 = CCR_S(S1, S0, a1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
													begin
														x1_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													x1_p2 = a1;

												x1write_p2 = `true;
											end

								2'b10	:	/* B -> x0 */
											begin
												S_p2 = CCR_S(S1, S0, b1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
													begin
														x0_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													x0_p2 = b1;

												x0write_p2 = `true;
											end

								2'b11	:	/* B -> x1 */
											begin
												S_p2 = CCR_S(S1, S0, b1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
													begin
														x1_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													x1_p2 = b1;

												x1write_p2 = `true;
											end
							endcase		/* pdb2[19:18] */


							if (~pdb2[15])

								/* if a data alu register is to be writen into memory */

								case (pdb2[17:16])	/* choose the source */
									2'b00	:	begin
													ydb_out_p2 = y0;	/* y0 */
													ydb_out_write_p2 = `true;
												end
									2'b01	:	begin
													ydb_out_p2 = y1;	/* y1 */
													ydb_out_write_p2 = `true;
												end

									2'b10	:	begin			/* A */
													S_p2_2 = CCR_S(S1, S0, a1);
													Swrite_p2_2 = `true;
													
													xdb_out_write_p2 = `true;
													
													if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
														begin
															xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
															L_p2_2 = 1'b1;									/* limiting has occurred */
															Lwrite_p2_2 = `true;
														end
													else
														xdb_out_p2 = a1;
												end

									2'b11	:	begin			/* B */
													S_p2_2 = CCR_S(S1, S0, b1);
													Swrite_p2_2 = `true;
													
													ydb_out_write_p2 = `true;
													
													if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
														begin
															ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
															L_p2_2 = 1'b1;									/* limiting has occurred */
															Lwrite_p2_2 = `true;
														end
													else
														ydb_out_p2 = b1;
												end
								endcase		/* pdb2[17:16] */


						end		/* R:Y */

					else
						/*------------------------------*/
						/* X:R Class I move instruction */
						/*------------------------------*/

						begin

							/* move an accumulator into a Y register, instruction format S2,D2 */

							case (pdb2[17:16])
								2'b00	:	/* A -> y0 */
											begin
												S_p2 = CCR_S(S1, S0, a1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
													begin
														y0_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													y0_p2 = a1;

												y0write_p2 = `true;
											end

								2'b01	:	/* A -> y1 */
											begin
												S_p2 = CCR_S(S1, S0, a1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bit in use */
													begin
														y1_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													y1_p2 = a1;

												y1write_p2 = `true;
											end

								2'b10	:	/* B -> y0 */
											begin
												S_p2 = CCR_S(S1, S0, b1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
													begin
														y0_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													y0_p2 = b1;

												y0write_p2 = `true;
											end
								2'b11	:	/* B -> y1 */
											begin
												S_p2 = CCR_S(S1, S0, b1);
												Swrite_p2 = `true;
												
												if ( CCR_E(S1, S0, {b2, b1}) )							/* The Extention portion B2 is in use
												*/
													begin
														y1_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
														L_p2 = 1'b1;									/* limiting has occurred */
														Lwrite_p2 = `true;
													end
												else
													y1_p2 = b1;

												y1write_p2 = `true;
											end
							endcase		/* pdb2[17:16] */


							/* if a data alu register is to be written into memory */

							if (~pdb2[15])

								case (pdb2[19:18])	/* choose the source */
									2'b00	:	begin
													xdb_out_p2 = x0;	/* x0 */
													xdb_out_write_p2 = `true;
												end
									2'b01	:	begin
													xdb_out_p2 = x1;	/* x1 */
													xdb_out_write_p2 = `true;
												end

									2'b10	:	begin			/* A */
													S_p2_2 = CCR_S(S1, S0, a1);
													Swrite_p2_2 = `true;
													
													xdb_out_write_p2 = `true;
													
													if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
														begin
															xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
															L_p2_2 = 1'b1;									/* limiting has occurred */
															Lwrite_p2_2 = `true;
														end
													else
														xdb_out_p2 = a1;
												end

									2'b11	:	begin			/* B */
													S_p2_2 = CCR_S(S1, S0, b1);
													Swrite_p2_2 = `true;
													
													ydb_out_write_p2 = `true;
													
													if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
														begin
															ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
															L_p2_2 = 1'b1;									/* limiting has occurred */
															Lwrite_p2_2 = `true;
														end
													else
														ydb_out_p2 = b1;
												end
								endcase		/* pdb2[19:18] */

						end		/* X:R */

			end		/* X:R Class I  or  R:Y Class I */




		else if ( pdb2[23:21] == 3'b001 )
			begin	/*--------------------------------------------------*/
					/*					I:								*/
					/*													*/
					/* Immediate Short Data Move						*/
					/* Whenever a destination is a data ALU register	*/
					/* The Condition Codes are NOT Affected				*/
					/*--------------------------------------------------*/

				case (pdb2[20:16])
					`x0	:	begin
								x0_p2 = {pdb2[15:8], 16'h0000};
								x0write_p2 = `true;
							end
					`x1	:	begin
								x1_p2 = {pdb2[15:8], 16'h0000};
								x1write_p2 = `true;
							end
					`y0	:	begin
								y0_p2 = {pdb2[15:8], 16'h0000};
								y0write_p2 = `true;
							end
					`y1	:	begin
								y1_p2 = {pdb2[15:8], 16'h0000};
								y1write_p2 = `true;
							end
					`a0	:	begin
								a0_p2 = {16'h0000, pdb2[15:8]};
								a0write_p2 = `true;
							end
					`b0	:	begin
								b0_p2 = {16'h0000, pdb2[15:8]};
								b0write_p2 = `true;
							end
					`a2	:	begin
								a2_p2 = pdb2[15:8];
								a2write_p2 = `true;
							end
					`b2	:	begin
								b2_p2 = pdb2[15:8];
								b2write_p2 = `true;
							end
					`a1	:	begin
								a1_p2 = {16'h0000, pdb2[15:8]};
								a1write_p2 = `true;
							end
					`b1	:	begin
								b1_p2 = {16'h0000, pdb2[15:8]};
								b1write_p2 = `true;
							end
					`a	:	begin
								a2_p2 = { 8 {pdb2[15]} };	/* sign ext */
								a1_p2 = {pdb2[15:8], 16'h0000};
								a0_p2 = 24'h000000;			/* zero */
								a2write_p2 = `true;
								a1write_p2 = `true;
								a0write_p2 = `true;
							end
					`b	:	begin
								b2_p2 = { 8 {pdb2[15]} };	/* sign ext */
								b1_p2 = {pdb2[15:8], 16'h0000};
								b0_p2 = 24'h000000;			/* zero */
								b2write_p2 = `true;
								b1write_p2 = `true;
								b0write_p2 = `true;
							end
					default : ;		/* no action */
				endcase		/* pdb2[20:16] */

			end		/* I */




		else if ( pdb2[23:22] == 2'b01 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:				*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/* Condition codes ARE affected		*/
					/*----------------------------------*/

				if (~pdb2[15])
					/*--------------------------------------------------*/
					/* If the SOURCE is a data alu register				*/
					/* place the source on either the X or Y data buses	*/
					/*--------------------------------------------------*/

					case ({pdb2[21:20], pdb2[18:16]})
						`x0	:	begin
									xdb_out_p2 = x0;
									xdb_out_write_p2 = `true;
								end
						`x1	:	begin
									xdb_out_p2 = x1;
									xdb_out_write_p2 = `true;
								end
						`y0	:	begin
									ydb_out_p2 = y0;
									ydb_out_write_p2 = `true;
								end
						`y1	:	begin
									ydb_out_p2 = y1;
									ydb_out_write_p2 = `true;
								end
						`a0	:	begin
									xdb_out_p2 = a0;
									xdb_out_write_p2 = `true;
								end
						`b0	:	begin
									ydb_out_p2 = b0;
									ydb_out_write_p2 = `true;
								end
						`a2	:	begin
									xdb_out_p2 = {16'h0000, a2};
									xdb_out_write_p2 = `true;
								end
						`b2	:	begin
									ydb_out_p2 = {16'h0000, b2};
									ydb_out_write_p2 = `true;
								end
						`a1	:	begin
									xdb_out_p2 = a1;
									xdb_out_write_p2 = `true;
								end
						`b1	:	begin
									ydb_out_p2 = b1;
									ydb_out_write_p2 = `true;
								end
						`a	:	begin
									S_p2 = CCR_S(S1, S0, a1);
									Swrite_p2 = `true;
									
									xdb_out_write_p2 = `true;
									
									if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
										begin
											xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
											L_p2 = 1'b1;									/* limiting has occurred */
											Lwrite_p2 = `true;
										end
									else
										xdb_out_p2 = a1;
								end
						`b	:	begin
									S_p2 = CCR_S(S1, S0, b1);
									Swrite_p2 = `true;
									
									ydb_out_write_p2 = `true;
									
									if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
										begin
											ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
											L_p2 = 1'b1;									/* limiting has occurred */
											Lwrite_p2 = `true;
										end
									else
										ydb_out_p2 = b1;
								end
								
						default : ;		/* no Action */
						
					endcase		/* source */


				if ( (pdb2[15:8] == 8'b11_110000) || (pdb2[15:8] == 8'b11_110100) )
					begin
						/* Active if an absolute address or immediate data are used */
						/* (a TWO word instruction format).							*/

						absolute_immediate = `true;

						if (pdb2[10:8] == 3'b100)		/* immediate data */
							case ({pdb2[21:20], pdb2[18:16]})
								`x0	:	begin
											x0_p2 = XDB;
											x0write_p2 = `true;
										end
								`x1	:	begin
											x1_p2 = XDB;
											x1write_p2 = `true;
										end
								`y0	:	begin
											y0_p2 = YDB;
											y0write_p2 = `true;
										end
								`y1	:	begin
											y1_p2 = YDB;
											y1write_p2 = `true;
										end
								`a0	:	begin
											a0_p2 = XDB;
											a0write_p2 = `true;
										end
								`b0	:	begin
											b0_p2 = YDB;
											b0write_p2 = `true;
										end
								`a2	:	begin
											a2_p2 = XDB[`ext];
											a2write_p2 = `true;
										end
								`b2	:	begin
											b2_p2 = YDB[`ext];
											b2write_p2 = `true;
										end
								`a1	:	begin
											a1_p2 = XDB;
											a1write_p2 = `true;
										end
								`b1	:	begin
											b1_p2 = YDB;
											b1write_p2 = `true;
										end
								`a	:	begin
											a2_p2 = { 8 {XDB[23]} };
											a1_p2 = XDB;
											a0_p2 = 24'h000000;
											a2write_p2 = `true;
											a1write_p2 = `true;
											a0write_p2 = `true;
										end
								`b	:	begin
											b2_p2 = { 8 {YDB[23]} };
											b1_p2 = YDB;
											b0_p2 = 24'h000000;
											b2write_p2 = `true;
											b1write_p2 = `true;
											b0write_p2 = `true;
										end
								default :	;	/* no action */
							endcase		/* destination	*/

				end		/* absolute immediate */


			end	/* X: or Y: */




		else if ( pdb2[23] )
			begin	/*--------------------------------------*/
					/*				X:Y:					*/
					/*										*/
					/* XY Memory Data Move					*/
					/* Condition codes ARE affected			*/
					/*--------------------------------------*/

				/* A source comes from the data alu and put on the    X    data bus */

				if (~pdb2[15])
					case (pdb2[19:18])	/* choose the source */
						2'b00	:	begin
										xdb_out_p2 = x0;	/* x0 */
										xdb_out_write_p2 = `true;
									end
						2'b01	:	begin
										xdb_out_p2 = x1;	/* x1 */
										xdb_out_write_p2 = `true;
									end

						2'b10	:	begin			/* A */
										S_p2 = CCR_S(S1, S0, a1);
										Swrite_p2 = `true;
										
										xdb_out_write_p2 = `true;
										
										if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
											begin
												xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
												L_p2 = 1'b1;									/* limiting has occurred */
												Lwrite_p2 = `true;
											end
										else
											xdb_out_p2 = a1;
									end

						2'b11	:	begin			/* B */
										S_p2 = CCR_S(S1, S0, b1);
										Swrite_p2 = `true;
										
										ydb_out_write_p2 = `true;
										
										if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
											begin
												ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
												L_p2 = 1'b1;									/* limiting has occurred */
												Lwrite_p2 = `true;
											end
										else
											ydb_out_p2 = b1;
									end
					endcase		/* pdb2[19:18] */



				/* A source comes from the data alu and put on the    Y    data bus */

				if (~pdb2[22])
					case (pdb2[17:16])	/* choose the source */
						2'b00	:	begin
										ydb_out_p2 = y0;	/* y0 */
										ydb_out_write_p2 = `true;
									end
						2'b01	:	begin
										ydb_out_p2 = y1;	/* y1 */
										ydb_out_write_p2 = `true;
									end

						2'b10	:	begin			/* A */
										S_p2_2 = CCR_S(S1, S0, a1);
										Swrite_p2_2 = `true;
										
										xdb_out_write_p2 = `true;
										
										if ( CCR_E(S1, S0, {a2, a1}) )							/* Extention bits in use */
											begin
												xdb_out_p2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
												L_p2_2 = 1'b1;									/* limiting has occurred */
												Lwrite_p2_2 = `true;
											end
										else
											xdb_out_p2 = a1;
									end

						2'b11	:	begin			/* B */
										S_p2_2 = CCR_S(S1, S0, b1);
										Swrite_p2_2 = `true;
										
										ydb_out_write_p2 = `true;
										
										if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
											begin
												ydb_out_p2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
												L_p2_2 = 1'b1;									/* limiting has occurred */
												Lwrite_p2_2 = `true;
											end
										else
											ydb_out_p2 = b1;
									end
					endcase		/* pdb2[17:16] */

			end		/* X:Y: */


										

		else	/* if no operation is required */
			begin
			end
										

	end		/* @(pdb2) parallel move section	*/




/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/
/*																				*/
/* 						Arithmetic or Logic instructions 						*/
/*																				*/
/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/

always @(	pdb2 or 
			a0 or 
			a1 or 
			a2 or 
			b0 or 
			b1 or 
			b2)

	begin
		
		/* initilally High-Z all the inputs to the registers	*/
		
		a0_a2 = 24'hzzzzzz;
		a1_a2 = 24'hzzzzzz;
		a2_a2 =  8'hzz;
		b0_a2 = 24'hzzzzzz;
		b1_a2 = 24'hzzzzzz;
		b2_a2 =  8'hzz;


		/* initially clear the atomic read/write permissions */
		
		a2write_atomic_a2 = `false;
		a1write_atomic_a2 = `false;
		a0write_atomic_a2 = `false;

		b2write_atomic_a2 = `false;
		b1write_atomic_a2 = `false;
		b0write_atomic_a2 = `false;

		Aread_atomic_a2 = `false;
		Bread_atomic_a2 = `false;


		/* Initially clear all the condition codes in CCR */

		S_a2 = 1'b0;
		Swrite_a2 = `false;

		L_a2 = 1'b0;
		Lwrite_a2 = `false;

		
		
		/*----------------------------------*/
		/* Decode the incoming instruction	*/	
		/*----------------------------------*/


		if ( {pdb2[23:13], pdb2[7:4]} == 15'b00000100_010_0001 )
			begin	/*--------------------------------------*/
					/*					LUA					*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* LUA */




		else if ( {pdb2[23:14], pdb2[7:5]} == 13'b00001011_11_011 )
			begin	/*--------------------------------------*/
					/*				BTST Class III			*/
					/*										*/
					/*	Bit Test - Class III				*/
					/*										*/
					/*  A or B accumulator is the source	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction		*/
					/* Read changes the Atomic flag to true, preventing a later inst. from changing that accumulator */
					/* until the atomic inst retires. */
				
				if ( pdb2[13:11] == 3'b001 )
					if  (pdb2[8])
						Bread_atomic_a2 = `true;
					else
						Aread_atomic_a2 = `true;
						
			end		/* BTST Class III */




		else if ( {pdb2[23:14], pdb2[7:6]} == 12'b00001010_11_01 )
			begin	/*--------------------------------------*/
					/*			BCLR / BSET Class III		*/
					/*										*/
					/*	Bit Test and Clear/Set - Class III	*/
					/*										*/
					/*  A or B accumulator is the source	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction		*/

				if ( pdb2[13:11] == 3'b001 )
					if (pdb2[8])
						Bread_atomic_a2 = `true;
					else
						Aread_atomic_a2 = `true;
						
				
				if ( pdb2[13:8] == 6'b001_110 )
					begin	/* A */
						S_a2 = CCR_S(S1, S0, a1);
						Swrite_a2 = `true;

						if ( CCR_E(S1, S0, {a2, a1}) )
							begin												/* Extention bits in use */
								a2_a2 = ( a2[7] ) ? 8'hff : 8'h00;				/* sign extention */
								a1_a2 = ( a2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
								a0_a2 = 24'h000000;								/* cleared */

								L_a2 = 1'b1;									/* limiting has occurred */
								Lwrite_a2 = `true;
							end
						else
							begin												/* Extention bits NOT in use */
								a2_a2 = { 8 {a1[23]} };							/* sign extention */
								a1_a2 = a1;										/* No change */
								a0_a2 = 24'h000000;								/* cleared */
							end

						/* write enable */
						a2write_atomic_a2 = `true;
						a1write_atomic_a2 = `true;
						a0write_atomic_a2 = `true;

					end		/* A */


				else if ( pdb2[13:8] == 6'b001_111 )
					begin	/* B */
						S_a2 = CCR_S(S1, S0, b1);
						Swrite_a2 = `true;
						
						if ( CCR_E(S1, S0, {b2, b1}) )							/* Extention bits in use */
							begin
								b2_a2 = ( b2[7] ) ? 8'hff : 8'h00;				/* sign extention */
								b1_a2 = ( b2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
								b0_a2 = 24'h000000;								/* cleared */

								L_a2 = 1'b1;									/* limiting has occurred */
								Lwrite_a2 = `true;
							end
						else
							begin												/* Extention bits NOT in use */
								b2_a2 = { 8 {b1[23]} };							/* sign extention */
								b1_a2 = b1;										/* No change */
								b0_a2 = 24'h000000;								/* cleared */
							end

						/* read/write enable */
						b2write_atomic_a2 = `true;
						b1write_atomic_a2 = `true;
						b0write_atomic_a2 = `true;

					end		/* B */

			end		/* BCLR/BSET Class III */



		else if ( {pdb2[23:16], pdb2[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC  Class IV */




		else if ( {pdb2[23:16], pdb2[7], pdb2[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC Class I and II */






	end		/* @(pdb2) arithmetic section	*/






/*==============================================================================================*/
/*==============================================================================================*/
/*																								*/
/*	Stage 3 (Execute)						Stage 3 (Execute)				Stage 3 (Execute)	*/
/*																								*/
/*==============================================================================================*/
/*==============================================================================================*/

always @(posedge Clk)
	begin
		if (reset)
			pdb3 <= `NOP;
		else
			pdb3 <= pdb2;	/* move the instruction from the Decode to the Execute stage */
	end


/*--------------------------------------------------------------------------------------*/
/*																						*/
/* Parallel moves: deals with the parallel data move field in an instruction [23:8].	*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

always @(	pdb3 or 
			XDB or 
			YDB)
			
	begin

		/* initially put all register write-enable controls in High-Z state	*/
		
		x0write_p3 = `false;
		x1write_p3 = `false;
		y0write_p3 = `false;
		y1write_p3 = `false;
		a0write_p3 = `false;
		a1write_p3 = `false;
		a2write_p3 = `false;
		b0write_p3 = `false;
		b1write_p3 = `false;
		b2write_p3 = `false;


		/* initilally High-Z all the inputs to the registers	*/
		
		x0_p3 = 24'hzzzzzz;
		x1_p3 = 24'hzzzzzz;
		y0_p3 = 24'hzzzzzz;
		y1_p3 = 24'hzzzzzz;
		a0_p3 = 24'hzzzzzz;
		a1_p3 = 24'hzzzzzz;
		a2_p3 =  8'hzz;
		b0_p3 = 24'hzzzzzz;
		b1_p3 = 24'hzzzzzz;
		b2_p3 =  8'hzz;


		/* Initially clear all the condition codes in CCR */

		S_p3 = 1'b0;
		Swrite_p3 = `false;
		
		L_p3 = 1'b0;
		Lwrite_p3 = `false;
		
		E_p3 = 1'b0;
		U_p3 = 1'b0;
		N_p3 = 1'b0;
		Z_p3 = 1'b0;
		V_p3 = 1'b0;
		C_p3 = 1'b0;
			


		/*---------------------------------*/
		/* Decode the incoming instruction */
		/*---------------------------------*/

		if (pdb3[`movefield] == `no_parallel_data_move)
			begin	/*--------------------------------------*/
					/* No parallel data move is required	*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
			end




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end		/* REP Class IV */




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
				
			end		/* DO Class IV */




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
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* LUA */




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




		else if ( pdb3[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U					*/
					/*									*/
					/* No Action			 			*/
					/*----------------------------------*/
			end		/* U */




		else if ( {pdb3[23:16], pdb3[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC  Class IV */




		else if ( {pdb3[23:16], pdb3[7], pdb3[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC Class I and II */




		else if ( {pdb3[23:17], pdb3[14]} == 8'b0000100_0 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class II  or  R:Y  Class II					*/
					/*																*/
					/* No Action													*/
					/*--------------------------------------------------------------*/
			end		/* X:R Class II  or  R:Y  Class II */





		else if ( pdb3[23:18] == 6'b001000 )
			begin	/*----------------------------------*/
					/*				R:					*/
					/*									*/
					/* Register to Register Data Move	*/
					/* Condition Codes ARE changed.		*/
					/*									*/
					/* Active when the SOURCE is an AGU	*/
					/* register and the DESTINATION is	*/
					/* a data alu register.				*/
					/*----------------------------------*/

			if (pdb3[17])	/* the source is an AGU register */
				case (pdb3[12:8])
					`x0	:	begin
								x0_p3 = XDB;
								x0write_p3 = `true;
							end
					`x1	:	begin
								x1_p3 = XDB;
								x1write_p3 = `true;
							end
					`y0	:	begin
								y0_p3 = YDB;
								y0write_p3 = `true;
							end
					`y1	:	begin
								y1_p3 = YDB;
								y1write_p3 = `true;
							end
					`a0	:	begin
								a0_p3 = XDB;
								a0write_p3 = `true;
							end
					`b0	:	begin
								b0_p3 = YDB;
								b0write_p3 = `true;
							end
					`a2	:	begin
								a2_p3 = XDB[`ext];
								a2write_p3 = `true;
							end
					`b2	:	begin
								b2_p3 = YDB[`ext];
								b2write_p3 = `true;
							end
					`a1	:	begin
								a1_p3 = XDB;
								a1write_p3 = `true;
							end
					`b1	:	begin
								b1_p3 = YDB;
								b1write_p3 = `true;
							end
					`a	:	begin
								a2_p3 = { 8 {XDB[23]} };
								a1_p3 = XDB;
								a0_p3 = 24'h000000;
								a2write_p3 = `true;
								a1write_p3 = `true;
								a0write_p3 = `true;
							end
					`b	:	begin
								b2_p3 = { 8 {YDB[23]} };
								b1_p3 = YDB;
								b0_p3 = 24'h000000;
								b2write_p3 = `true;
								b1write_p3 = `true;
								b0write_p3 = `true;
							end
				endcase		/* pdb3[12:8]	*/

			end		/* R */




		else if ( {pdb3[23:20], pdb3[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/*									*/
					/* Long Memory Data Move			*/
					/*----------------------------------*/
				
				/* for Class I and II */
					
				
				/* latch incoming data from memories into registers */
				/* choose destination registers */
				
				if (pdb3[15])
					begin
						/* LLL - choose the source registers */
						case ( {pdb3[19], pdb3[17:16]} )
							3'b000	:	/* A10 = A1  A0 */
										begin
											a1_p3 = XDB;
											a0_p3 = YDB;
											a1write_p3 = `true;
											a0write_p3 = `true;
										end

							3'b001	:	/* B10 = B1  B0 */
										begin
											b1_p3 = XDB;
											b0_p3 = YDB;
											b1write_p3 = `true;
											b0write_p3 = `true;
										end

							3'b010	:	/* X = X1  X0 */
										begin
											x1 = XDB;
											x0 = YDB;
											x1write_p3 = `true;
											x0write_p3 = `true;
										end

							3'b011	:	/* Y10 = Y1  Y0 */
										begin
											y1 = XDB;
											y0 = YDB;
											y1write_p3 = `true;
											y0write_p3 = `true;
										end

							3'b100	:	/* A = {A1,A0} */
										begin
											a2_p3 = {8{XDB[23]}};	/* sign extend */
											a1_p3 = XDB;
											a0_p3 = YDB;
											a2write_p3 = `true;
											a1write_p3 = `true;
											a0write_p3 = `true;
										end		/* A */

							3'b101	:	/* B = {B1,B0} */
										begin
											b2_p3 = {8{XDB[23]}};	/* sign extend */
											b1_p3 = XDB;
											b0_p3 = YDB;
											b2write_p3 = `true;
											b1write_p3 = `true;
											b0write_p3 = `true;
										end		/* B */

							3'b110	:	/* AB = A  B */
										begin
											/* A */
											a2_p3 = {8{XDB[23]}};
											a1_p3 = XDB;
											a0_p3 = 24'h000000;
											a2write_p3 = `true;
											a1write_p3 = `true;
											a0write_p3 = `true;
											
											/* B */
											b2_p3 = {8{YDB[23]}};
											b1_p3 = YDB;
											b0_p3 = 24'h000000;
											b2write_p3 = `true;
											b1write_p3 = `true;
											b0write_p3 = `true;
										end		/* AB */

							3'b111	:	/* BA = B  A */
										begin
											/* B */
											b2_p3 = {8{XDB[23]}};
											b1_p3 = XDB;
											b0_p3 = 24'h000000;
											b2write_p3 = `true;
											b1write_p3 = `true;
											b0write_p3 = `true;

											/* A */
											a2_p3 = {8{YDB[23]}};
											a1_p3 = YDB;
											a0_p3 = 24'h000000;
											a2write_p3 = `true;
											a1write_p3 = `true;
											a0write_p3 = `true;
										end		/* BA */
							
						endcase		/* LLL */
					
					end		/* W = 1 */
					
			end	/* L: */




		else if ( {pdb3[23:20], pdb3[14]} == 5'b0001_0 )
			begin	/*--------------------------*/
					/* 		X:R Class I			*/
					/*--------------------------*/

				/* if a destination alu register is to be written */

				if ( pdb3[15] && (pdb3[13:8] != 6'b110100) )		/* not an immediate data mode */
					case (pdb3[19:18])
						2'b00	:	/* x0 */
									begin
										x0_p3 = XDB;
										x0write_p3 = `true;
									end
						2'b01	:	/* x1 */
									begin	
										x1_p3 = XDB;
										x1write_p3 = `true;
									end
						2'b10	:	/* A */
									begin
										a2_p3 = { 8 {XDB[23]} };
										a1_p3 = XDB;
										a0_p3 = 24'h000000;
										a2write_p3 = `true;
										a1write_p3 = `true;
										a0write_p3 = `true;
									end
						2'b11	:	/* B */
									begin
										b2_p3 = { 8 {YDB[23]} };
										b1_p3 = YDB;
										b0_p3 = 24'h000000;
										b2write_p3 = `true;
										b1write_p3 = `true;
										b0write_p3 = `true;
									end
					endcase		/* pdb3[19:18] */

			end		/* X:R Class I */




		else if ( {pdb3[23:20], pdb3[14]} == 5'b0001_1 )
			begin	/*--------------------------*/
					/* 		R:Y Class I			*/
					/*--------------------------*/

				/* if a destination alu register is to be written */

				if (pdb3[15] && pdb3[13:8] != 6'b110100)	/* not an immediate data mode */
					case (pdb3[17:16])
						2'b00	:	/* y0 */
									begin
										y0_p3 = YDB;
										y0write_p3 = `true;
									end
						2'b01	:	/* y1 */
									begin	
										y1_p3 = YDB;
										y1write_p3 = `true;
									end
						2'b10	:	/* A */
									begin
										a2_p3 = { 8 {XDB[23]} };
										a1_p3 = XDB;
										a0_p3 = 24'h000000;
										a2write_p3 = `true;
										a1write_p3 = `true;
										a0write_p3 = `true;
									end
						2'b11	:	/* B */
									begin
										b2_p3 = { 8 {YDB[23]} };
										b1_p3 = YDB;
										b0_p3 = 24'h000000;
										b2write_p3 = `true;
										b1write_p3 = `true;
										b0write_p3 = `true;
									end
					endcase		/* pdb3[17:16] */

			end		/* R:Y Class I */




		else if ( pdb3[23:21] == 3'b001 )
			begin	/*----------------------------------*/
					/* 				I:					*/
					/*									*/
					/* No Action						*/
					/*----------------------------------*/
			end		/* I */
			



		else if ( pdb3[23:22] == 2'b01 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:				*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/* Condition codes ARE affected		*/
					/*----------------------------------*/

				/* when a DESTINATION is a data alu register					*/
				/* choose that register.										*/
				/* The data is coming on the XDB in the X: type of move,		*/
				/* and on the YDB in the Y: type of move. The bus switch		*/
				/* diverts the data from and to the correct input data bus		*/
				/* that corresponds to the destination register. For example:	*/
				/* in X: move into y0 register, data coming on the XDB is		*/
				/* diverted to the YDB bus so that it can be read into the alu	*/
				/* and latched into y0 (that can be fed only by the YDB bus).	*/

				if (pdb3[15])
					case ({pdb3[21:20], pdb3[18:16]})
						`x0	:	begin
									x0_p3 = XDB;
									x0write_p3 = `true;
								end
						`x1	:	begin
									x1_p3 = XDB;
									x1write_p3 = `true;
								end
						`y0	:	begin
									y0_p3 = YDB;
									y0write_p3 = `true;
								end
						`y1	:	begin
									y1_p3 = YDB;
									y1write_p3 = `true;
								end
						`a0	:	begin
									a0_p3 = XDB;
									a0write_p3 = `true;
								end
						`b0	:	begin
									b0_p3 = YDB;
									b0write_p3 = `true;
								end
						`a2	:	begin
									a2_p3 = XDB[`ext];
									a2write_p3 = `true;
								end
						`b2	:	begin
									b2_p3 = YDB[`ext];
									b2write_p3 = `true;
								end
						`a1	:	begin
									a1_p3 = XDB;
									a1write_p3 = `true;
								end
						`b1	:	begin
									b1_p3 = YDB;
									b1write_p3 = `true;
								end
						`a	:	begin
									a2_p3 = { 8 {XDB[23]} };
									a1_p3 = XDB;
									a0_p3 = 24'h000000;
									a2write_p3 = `true;
									a1write_p3 = `true;
									a0write_p3 = `true;
								end
						`b	:	begin
									b2_p3 = { 8 {YDB[23]} };
									b1_p3 = YDB;
									b0_p3 = 24'h000000;
									b2write_p3 = `true;
									b1write_p3 = `true;
									b0write_p3 = `true;
								end
						default :	;	/* no action */
					endcase		/* destination	*/

			end		/* X: or Y: */
										


			
		else if ( pdb3[23] )
			begin	/*--------------------------------------*/
					/*				X:Y:					*/
					/*										*/
					/* XY Memory Data Move					*/
					/* Condition codes ARE affected			*/
					/*--------------------------------------*/

				/* if a destination alu register is to be written by using data from   X   memeory */

				if (pdb3[15])
					case (pdb3[19:18])
						2'b00	:	/* x0 */
									begin
										x0_p3 = XDB;
										x0write_p3 = `true;
									end
						2'b01	:	/* x1 */
									begin	
										x1_p3 = XDB;
										x1write_p3 = `true;
									end
						2'b10	:	/* A */
									begin
										a2_p3 = { 8 {XDB[23]} };
										a1_p3 = XDB;
										a0_p3 = 24'h000000;
										a2write_p3 = `true;
										a1write_p3 = `true;
										a0write_p3 = `true;
									end
						2'b11	:	/* B */
									begin
										b2_p3 = { 8 {YDB[23]} };
										b1_p3 = YDB;
										b0_p3 = 24'h000000;
										b2write_p3 = `true;
										b1write_p3 = `true;
										b0write_p3 = `true;
									end
					endcase		/* pdb3[19:18] */

				/* if a destination alu register is to be written by using data from   Y   memeory */

				if (pdb3[22])
					case (pdb3[17:16])
						2'b00	:	/* y0 */
									begin
										y0_p3 = YDB;
										y0write_p3 = `true;
									end
						2'b01	:	/* x1 */
									begin	
										y1_p3 = YDB;
										y1write_p3 = `true;
									end
						2'b10	:	/* A */
									begin
										a2_p3 = { 8 {XDB[23]} };
										a1_p3 = XDB;
										a0_p3 = 24'h000000;
										a2write_p3 = `true;
										a1write_p3 = `true;
										a0write_p3 = `true;
									end
						2'b11	:	/* B */
									begin
										b2_p3 = { 8 {YDB[23]} };
										b1_p3 = YDB;
										b0_p3 = 24'h000000;
										b2write_p3 = `true;
										b1write_p3 = `true;
										b0write_p3 = `true;
									end
					endcase		/* pdb3[17:16] */

			end		/* X:Y: */
										



		else	/* if no operation is required */
			begin
			end
										



	end		/* @(pdb3) parallel move section	*/
	
	
	
/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/
/*																				*/
/* 						Arithmetic or Logic instructions					 	*/
/*																				*/
/*------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/

always @(	pdb3 or 
			AGU_C or 
			Aatomic or 
			Batomic or 
			S or 
			L or 
			E or 
			U or 
			N or 
			Z or 
			V or 
			C or 
			x0 or 
			x1 or 
			y0 or 
			y1 or 
			a0 or 
			a1 or 
			a2 or 
			b0 or 
			b1 or 
			b2 or 
			XDB or 
			YDB)
			
	begin
	
		/* initially put all register write-enable controls in High-Z state	*/
		
		x0write_a3 = `false;
		x1write_a3 = `false;
		y0write_a3 = `false;
		y1write_a3 = `false;
		a0write_a3 = `false;
		a1write_a3 = `false;
		a2write_a3 = `false;
		b0write_a3 = `false;
		b1write_a3 = `false;
		b2write_a3 = `false;


		/* initially clear the atomic write permissions */

		xdb_out_write_atomic_a3 = `false;
		ydb_out_write_atomic_a3 = `false;

		x0write_atomic_a3 = `false;
		x1write_atomic_a3 = `false;

		y0write_atomic_a3 = `false;
		y1write_atomic_a3 = `false;
		
		
		a2write_atomic_a3 = `false;
		a1write_atomic_a3 = `false;
		a0write_atomic_a3 = `false;

		b2write_atomic_a3 = `false;
		b1write_atomic_a3 = `false;
		b0write_atomic_a3 = `false;


		/* initilally High-Z all the inputs to the Accumulators	*/
		
		x0_a3 = 24'hzzzzzz;
		x1_a3 = 24'hzzzzzz;
		y0_a3 = 24'hzzzzzz;
		y1_a3 = 24'hzzzzzz;
		a0_a3 = 24'hzzzzzz;
		a1_a3 = 24'hzzzzzz;
		a2_a3 =  8'hzz;
		b0_a3 = 24'hzzzzzz;
		b1_a3 = 24'hzzzzzz;
		b2_a3 =  8'hzz;


		/* Initially all the condition codes in CCR */

		S_a3 = 1'b1;		/* cleared ONLY by a bit-manipulating instruction */
		Swrite_a3 = `false;
		
		L_a3 = 1'b0;
		Lwrite_a3 = `false;

		E_a3 = 1'b0;
		U_a3 = 1'b0;
		N_a3 = 1'b0;
		Z_a3 = 1'b0;
		V_a3 = 1'b0;
		C_a3 = 1'b0;
			
		
		J = 1'bz;			/* Held in High-Z state until defined by JCLR/JSET. It goes to the PCU and might collide */
							/* with J coming from the AGU. That's why it must be kept at High-Z state if not defined. */


		
		/*--------------------------------------------------*/
		/* Decode the incoming instruction					*/	
		/*--------------------------------------------------*/


		if ( {pdb3[23:11], pdb3[7:4], pdb3[2:0]} == 20'b00000001_11011_0001_101 )
			begin	/*--------------------------------------*/
					/*					NORM				*/
					/*										*/
					/* Normalize Accumulator Iteration		*/
					/*--------------------------------------*/

				if (pdb3[3])	/* B */
					begin
						E_a3 = CCR_E(S1, S0, {b2,b1});
						U_a3 = CCR_U(S1, S0, {b2,b1});
						Z_a3 = CCR_Z({b2,b1,b0});

						if ( (~E) && U && (~Z) )			/* ASL */
							begin
								{b2_a3, b1_a3, b0_a3} = {b2[6:0], b1, b0, 1'b0};

								/* write enable */

								b2write_a3 = `true;
								b1write_a3 = `true;
								b0write_a3 = `true;

								/* condition code affected */

								N_a3 = CCR_N(b2_a3[7]);
								Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
								V_a3 = b2_a3[7] ^ b2[7];
							end

						else if (E)						/* ASR */
							begin
								{b2_a3, b1_a3, b0_a3} = {b2[7], b2, b1, b0[23:1]};

								/* write enable */

								b2write_a3 = `true;
								b1write_a3 = `true;
								b0write_a3 = `true;

								/* condition code affected */

								N_a3 = CCR_N(b2_a3[7]);
								Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
								V_a3 = 1'b0;
							end
					end		/* B */

				else			/* A */
					begin

						E_a3 = CCR_E(S1, S0, {a2,a1});
						U_a3 = CCR_U(S1, S0, {a2,a1});
						Z_a3 = CCR_Z({a2,a1,a0});

						if ( (~E) && U && (~Z) )			/* ASL */
							begin
								{a2_a3, a1_a3, a0_a3} = {a2[6:0], a1, a0, 1'b0};

								/* write enable */

								a2write_a3 = `true;
								a1write_a3 = `true;
								a0write_a3 = `true;

								/* condition code affected */

								N_a3 = CCR_N(a2_a3[7]);
								Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
								V_a3 = a2_a3[7] ^ a2[7];
							end		/* ASL */

						else if (E)						/* ASR */
							begin
								{a2_a3, a1_a3, a0_a3} = {a2[7], a2, a1, a0[23:1]};

								/* write enable */

								a2write_a3 = `true;
								a1write_a3 = `true;
								a0write_a3 = `true;

								/* condition code affected */

								N_a3 = CCR_N(a2_a3[7]);
								Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
								V_a3 = 1'b0;
							end		/* ASR */

					end		/* A */

			end		/* NORM */				




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end		/* JMP Class II */




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end		/* REP Class IV */




		else if ( {pdb3[23:15], pdb3[7], pdb3[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I	or II			*/
					/*										*/
					/* No action							*/
					/*--------------------------------------*/

			end		/* REP Class I or II */




		else if ( {pdb3[23:13], pdb3[7:6], pdb3[1:0]} == 15'b00000001_000_11_10 )
			begin	/*--------------------------------------*/
					/*					MAC					*/
					/*										*/
					/* Signed Multiply-Accumulate			*/
					/*--------------------------------------*/
					/*										*/
					/* 				MAC Format 2			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (y1, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (x0, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (y0, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (x1, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* write enable */

									b2write_a3 = `true;
									b1write_a3 = `true;
									b0write_a3 = `true;

									/* condition codes affected */

									L_a3 = b2_a3[7] ^ b2[7];
									E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
									U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
									N_a3 = CCR_N(b2_a3[7]);
									Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
									V_a3 = b2_a3[7] ^ b2[7];
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* B */

				else	/* Destination: A */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (y1, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? 
													{a2,a1,a0} - right_shifter (x0, pdb3[12:8]): 
													{a2,a1,a0} + right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (y0, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (x1, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* write enable */

									a2write_a3 = `true;
									a1write_a3 = `true;
									a0write_a3 = `true;

									/* condition codes affected */

									L_a3 = a2_a3[7] ^ a2[7];
									E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
									U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
									N_a3 = CCR_N(a2_a3[7]);
									Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
									V_a3 = a2_a3[7] ^ a2[7];
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* A */

			end		/* MAC Format 2 */




		else if ( {pdb3[23:13], pdb3[7:6], pdb3[1:0]} == 15'b00000001_000_11_11 )
			begin	/*--------------------------------------*/
					/*					MACR				*/
					/*										*/
					/* Signed Multiply-Accumulate and Round	*/
					/*--------------------------------------*/
					/*										*/
					/* 				MACR Format 2			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (y1, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (x0, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (y0, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{b2,b1,b0} - right_shifter (x1, pdb3[12:8]):
													{b2,b1,b0} + right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* round */
									
									{b2_a3, b1_a3, b0_a3} = round (S1, S0, pre_round);
									/* write enable */

									b2write_a3 = `true;
									b1write_a3 = `true;
									b0write_a3 = `true;

									/* condition codes affected */

									L_a3 = b2_a3[7] ^ pre_round[55];
									E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
									U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
									N_a3 = CCR_N(b2_a3[7]);
									Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
									V_a3 = b2_a3[7] ^ pre_round[55];
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* B */

				else	/* Destination: A */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (y1, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ? 
													{a2,a1,a0} - right_shifter (x0, pdb3[12:8]): 
													{a2,a1,a0} + right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (y0, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													{a2,a1,a0} - right_shifter (x1, pdb3[12:8]):
													{a2,a1,a0} + right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* round */
									
									{a2_a3, a1_a3, a0_a3} = round (S1, S0, pre_round);
									
									/* write enable */

									a2write_a3 = `true;
									a1write_a3 = `true;
									a0write_a3 = `true;

									/* condition codes affected */

									L_a3 = a2_a3[7] ^ pre_round[55];
									E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
									U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
									N_a3 = CCR_N(a2_a3[7]);
									Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
									V_a3 = a2_a3[7] ^ pre_round[55];		/* overflow because of the rounding */
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* A */

			end		/* MACR Format 2 */




		else if ( {pdb3[23:13], pdb3[7:6], pdb3[1:0]} == 15'b00000001_000_11_00 )
			begin	/*--------------------------------------*/
					/*					MPY					*/
					/*										*/
					/* Signed Multiply						*/
					/*--------------------------------------*/
					/*										*/
					/* 				MPY Format 2			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ?
													right_shifter (((~y1)+1), pdb3[12:8]) :
													right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ?
													right_shifter (((~x0)+1), pdb3[12:8]) :
													right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ?
													right_shifter (((~y0)+1), pdb3[12:8]) :
													right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ?
													right_shifter (((~x1)+1), pdb3[12:8]) :
													right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* write enable */

									b2write_a3 = `true;
									b1write_a3 = `true;
									b0write_a3 = `true;

									/* condition codes affected */

									E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
									U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
									N_a3 = CCR_N(b2_a3[7]);
									Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* B */

				else	/* Destination: A */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ?
													right_shifter (((~y1)+1), pdb3[12:8]) :
													right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? 
													right_shifter (((~x0)+1), pdb3[12:8]) : 
													right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ?
													right_shifter (((~y0)+1), pdb3[12:8]) :
													right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ?
													right_shifter (((~x1)+1), pdb3[12:8]) :
													right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* write enable into A and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* write enable */

									a2write_a3 = `true;
									a1write_a3 = `true;
									a0write_a3 = `true;

									/* condition codes affected */

									E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
									U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
									N_a3 = CCR_N(a2_a3[7]);
									Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* A */

			end		/* MPY Format 2 */




		else if ( {pdb3[23:13], pdb3[7:6], pdb3[1:0]} == 15'b00000001_000_11_01 )
			begin	/*--------------------------------------*/
					/*					MPYR				*/
					/*										*/
					/* Signed Multiply and Round			*/
					/*--------------------------------------*/
					/*										*/
					/* 				MPYR Format 2			*/
					/*										*/
					/*--------------------------------------*/
							
				if (pdb3[3])	/* Destination: B */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~y1)+1'b1), pdb3[12:8]) :
													right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~x0)+1'b1), pdb3[12:8]) :
													right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~y0)+1'b1), pdb3[12:8]) :
													right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~x1)+1'b1), pdb3[12:8]) :
													right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* round result, write enable into B and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* round */

									{b2_a3, b1_a3, b0_a3} = round (S1, S0, pre_round);

									/* write enable */

									b2write_a3 = `true;
									b1write_a3 = `true;
									b0write_a3 = `true;

									/* condition codes affected */

									L_a3 = b2_a3[7] ^ pre_round[55];														
									E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
									U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
									N_a3 = CCR_N(b2_a3[7]);
									Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
									V_a3 = b2_a3[7] ^ pre_round[55];		/* overflow because of the rounding */
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* B */

				else	/* Destination: A */
					begin
						case(pdb3[5:4])
							2'b00 :	/* Source : y1 */
									/* right shift y1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~y1)+1'b1), pdb3[12:8]) :
													right_shifter (y1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b01 :	/* Source : x0 */
									/* right shift x0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ? 
													right_shifter (((~x0)+1'b1), pdb3[12:8]) : 
													right_shifter (x0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b10 :	/* Source : y0 */
									/* right shift y0 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~y0)+1'b1), pdb3[12:8]) :
													right_shifter (y0, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

							2'b11 :	/* Source : x1 */
									/* right shift x1 by pdb3[12:8] bits and sign extend */
									case(pdb3[12:8])
										5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
										5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
										5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
										5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
										5'b10101, 5'b10110, 5'b10111 :
												pre_round = (pdb3[2]) ?
													right_shifter (((~x1)+1'b1), pdb3[12:8]) :
													right_shifter (x1, pdb3[12:8]);

										default	 : ;		/* No Action */
									endcase	/* pdb3[12:8] shift */

						endcase /* pdb3[5:4] Source */


						/* round result, write enable into A and CC */

						case(pdb3[12:8])
							5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101,
							5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010,
							5'b01011, 5'b01100, 5'b01101, 5'b01110, 5'b01111,
							5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100,
							5'b10101, 5'b10110, 5'b10111 :
								begin
									/* round */

									{a2_a3, a1_a3, a0_a3} = round (S1, S0, pre_round);

									/* write enable */

									a2write_a3 = `true;
									a1write_a3 = `true;
									a0write_a3 = `true;

									/* condition codes affected */

									L_a3 = a2_a3[7] ^ pre_round[55];
									E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
									U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
									N_a3 = CCR_N(a2_a3[7]);
									Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
									V_a3 = a2_a3[7] ^ pre_round[55];		/* overflow because of the rounding */
								end

							default	 : ;		/* No Action */
						endcase	/* pdb3[12:8] shift */

					end		/* A */

			end		/* MPYR Format 2 */




		else if ( {pdb3[23:13], pdb3[7:4]} == 15'b00000100_010_0001 )
			begin	/*--------------------------------------*/
					/*					LUA					*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
					
			end		/* LUA */




		else if ( {pdb3[23:16], pdb3[7:2]} == 14'b00000000_101110 )
			begin	/*--------------------------------------*/
					/*					ANDI				*/
					/*										*/
					/* And Immediate with Control Register	*/
					/*--------------------------------------*/

				case (pdb3[1:0])
					2'b00	:	;	/* No Action - MR is taken care of in the PCU */

					2'b01	:	/* CCR */
								begin
									S_a3 = (pdb3[15]) ? S : 1'b0;
									Swrite_a3 = `true;
									L_a3 = (pdb3[14]) ? L : 1'b0;
									Lwrite_a3 = `true;
									E_a3 = (pdb3[13]) ? E : 1'b0;
									U_a3 = (pdb3[12]) ? U : 1'b0;
									N_a3 = (pdb3[11]) ? N : 1'b0;
									Z_a3 = (pdb3[10]) ? Z : 1'b0;
									V_a3 = (pdb3[ 9]) ? V : 1'b0;
									C_a3 = (pdb3[ 8]) ? C : 1'b0;
								end

					2'b10	:	;	/* No Action - OMR is taken care of in the PCU */

					default	:	;	/* No Action */

				endcase		/* pdb3[1:0] */

			end		/* ANDI */




		else if ( ({pdb3[23:14], pdb3[7:6]} == 12'b00001010_11_01) ||
				  ({pdb3[23:14], pdb3[7:5]} == 13'b00001011_11_011) )
				  
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class III	*/
					/*										*/
					/*	Bit Test and Clear/Set - Class III	*/
					/*--------------------------------------*/

					/* This is an ATOMIC instruction		*/
					/* In case the BTST is executed, no writes are allowed to registers and accumulators. */
				
				if ( (pdb3[13:11] == 3'b010) || (pdb3[13:11] == 3'b011) ||(pdb3[13:11] == 3'b100) )

					begin		
						/* An AGU register is the source. A carry out (AGU_C) is received from the AGU.  */
						/* C from the AGU has a valid value only if the bit number is smaller than 16.   */
						if (~pdb3[4])
							C_a3 = AGU_C;
					end
					
				else if ( pdb3[13:10] == 4'b0001 )
					begin		/*--------------------------------------*/
								/* x0, x1, y0 and y1 data alu registers */
								/*--------------------------------------*/
					
						case (pdb3[9:8])
							2'b00	:	begin	/* x0 */
											{C_a3, x0_a3} = bit_test(x0, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	x0write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							2'b01	:	begin	/* x1 */
											{C_a3, x1_a3} = bit_test(x1, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	x1write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							2'b10	:	begin	/* y0 */
											{C_a3, y0_a3} = bit_test(y0, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	y0write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							2'b11	:	begin	/* y1 */
											{C_a3, y1_a3} = bit_test(y1, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	y1write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
						endcase		/* pdb3[9:8] */

					end		/* x0, x1, y0 and y1 */
				

				else if ( pdb3[13:11] == 3'b001 )
					begin		/*-------------------------------------------*/
								/* a2, a1, a0, A, b2, b1, b0, B accumulators */
								/*-------------------------------------------*/
					
						case (pdb3[10:8])
							3'b000	:	begin	/* a0 */
											{C_a3, a0_a3} = bit_test(a0, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	a0write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							3'b001	:	begin	/* b0 */
											{C_a3, b0_a3} = bit_test(b0, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	b0write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							3'b010	:	begin	/* a2 */
											case (pdb3[4:0])	/* choose the bit to be tested and cleared */
												5'b00000	:	{C_a3, a2_a3} = {a2[0],  a2[7:1],  pdb3[5]};
												5'b00001	:	{C_a3, a2_a3} = {a2[1],  a2[7:2],  pdb3[5], a2[0]};
												5'b00010	:	{C_a3, a2_a3} = {a2[2],  a2[7:3],  pdb3[5], a2[1:0]};
												5'b00011	:	{C_a3, a2_a3} = {a2[3],  a2[7:4],  pdb3[5], a2[2:0]};
												5'b00100	:	{C_a3, a2_a3} = {a2[4],  a2[7:5],  pdb3[5], a2[3:0]};
												5'b00101	:	{C_a3, a2_a3} = {a2[5],  a2[7:6],  pdb3[5], a2[4:0]};
												5'b00110	:	{C_a3, a2_a3} = {a2[6],  a2[7],    pdb3[5], a2[5:0]};
												5'b00111	:	{C_a3, a2_a3} = {a2[7],            pdb3[5], a2[6:0]};
												default		:	;		/* No Action */
											endcase
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b00000, 5'b00001, 5'b00010, 5'b00011,
												5'b00100, 5'b00101, 5'b00110, 5'b00111	:	a2write_atomic_a3 = (pdb3[16]) ? `false : `true;
												default		:	;	/* No action */
											endcase
										end
							3'b011	:	begin	/* b2 */
											case (pdb3[4:0])	/* choose the bit to be tested and cleared */
												5'b00000	:	{C_a3, b2_a3} = {b2[0],  b2[7:1],  pdb3[5]};
												5'b00001	:	{C_a3, b2_a3} = {b2[1],  b2[7:2],  pdb3[5], b2[0]};
												5'b00010	:	{C_a3, b2_a3} = {b2[2],  b2[7:3],  pdb3[5], b2[1:0]};
												5'b00011	:	{C_a3, b2_a3} = {b2[3],  b2[7:4],  pdb3[5], b2[2:0]};
												5'b00100	:	{C_a3, b2_a3} = {b2[4],  b2[7:5],  pdb3[5], b2[3:0]};
												5'b00101	:	{C_a3, b2_a3} = {b2[5],  b2[7:6],  pdb3[5], b2[4:0]};
												5'b00110	:	{C_a3, b2_a3} = {b2[6],  b2[7],    pdb3[5], b2[5:0]};
												5'b00111	:	{C_a3, b2_a3} = {b2[7],            pdb3[5], b2[6:0]};
												default		:	;		/* No Action */
											endcase
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b00000, 5'b00001, 5'b00010, 5'b00011,
												5'b00100, 5'b00101, 5'b00110, 5'b00111	:	b2write_atomic_a3 = (pdb3[16]) ? `false : `true;
												default		:	;	/* No action */
											endcase
										end
							3'b100	:	begin	/* a1 */
											{C_a3, a1_a3} = bit_test(a1, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	a1write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end
							3'b101	:	begin	/* b1 */
											{C_a3, b1_a3} = bit_test(b1, pdb3[4:0], pdb3[5]);
											
											/* write enable only for valid bit number (0-23) */
											case (pdb3[4:0])
												5'b11000, 5'b11001, 5'b11010, 5'b11011,
												5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
												default		:	b1write_atomic_a3 = (pdb3[16]) ? `false : `true;
											endcase
										end

							3'b110	:	begin	/* A */
											if (pdb3[16])		/* BTST : the limiter's output is used in testing. No writing are allowed. */
												begin
													S_a3 = CCR_S(S1, S0, a1);
													Swrite_a3 = `true;

													if ( CCR_E(S1, S0, {a2, a1}) )
														begin												/* Extention bits in use */
															if (Aatomic)
																begin
																	{C_a3, a1_a3} = ( a2[7] ) ? bit_test(24'h800000, pdb3[4:0], pdb3[5]) :
																								bit_test(24'h7fffff, pdb3[4:0], pdb3[5]);
																	L_a3 = 1'b1;		/* limiting has occurred */
																	Lwrite_a3 = `true;
																end
															else
																C_a3 = 1'b0;
														end
													else
														if (Aatomic)
															{C_a3, a1_a3} = bit_test(a1, pdb3[4:0], pdb3[5]);
														else
															C_a3 = 1'b0;

												end		/* BTST */

											else				/* BCLR or BSET */
												begin
													/* it's first part of the execution is in stage 2 */
													/* Here only a1 is updated */

													/* C and a1 are not affected if the atomic flag is clear, indicating that */
													/* this inst. immediatly followed a legal atomic inst., and therefore is ignored. */
												
													if (Aatomic)
														{C_a3, a1_a3} = bit_test(a1, pdb3[4:0], pdb3[5]);
													else
														C_a3 = 1'b0;

													/* write enable only for valid bit number (0-23) */
													case (pdb3[4:0])
														5'b11000, 5'b11001, 5'b11010, 5'b11011,
														5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
														default		:	a1write_atomic_a3 = `true;
													endcase
												end		/* BCLR or BSET */
										end		/* A */

							3'b111	:	begin	/* B */
											if (pdb3[16])		/* BTST : the limiter's output is used in testing. No writing are allowed. */
												begin
													S_a3 = CCR_S(S1, S0, b1);
													Swrite_a3 = `true;

													if ( CCR_E(S1, S0, {b2, b1}) )
														begin												/* Extention bits in use */
															if (Batomic)
																begin
																	{C_a3, b1_a3} = ( b2[7] ) ? bit_test(24'h800000, pdb3[4:0], pdb3[5]) :
																								bit_test(24'h7fffff, pdb3[4:0], pdb3[5]);
																	L_a3 = 1'b1;		/* limiting has occurred */
																	Lwrite_a3 = `true;
																end
															else
																C_a3 = 1'b0;
														end
													else
														if (Batomic)
															{C_a3, b1_a3} = bit_test(b1, pdb3[4:0], pdb3[5]);
														else
															C_a3 = 1'b0;

												end		/* BTST */

											else				/* BCLR or BSET */
												begin
													/* it's first part of the execution is in stage 2 */
													/* Here only b1 is updated */

													/* C and a1 are not affected if the atomic flag is clear, indicating that */
													/* this inst. immediatly followed a legal atomic inst., and therefore is ignored. */

													if (Batomic)
														{C_a3, b1_a3} = bit_test(b1, pdb3[4:0], pdb3[5]);
													else
														C_a3 = 1'b0;

													/* write enable only for valid bit number (0-23) */
													case (pdb3[4:0])
														5'b11000, 5'b11001, 5'b11010, 5'b11011,
														5'b11100, 5'b11101, 5'b11110, 5'b11111	:	;	/* No Action */
														default		:	b1write_atomic_a3 = `true;
													endcase
												end		/* BCLR or BSET */
										end		/* B */
						endcase		/* pdb3[13:11] */
						
					end		/* A and B accumulators */
					
					
				else if ( pdb3[13:11] == 3'b111 )
					begin		/*-------------------*/
								/* Control registers */
								/*-------------------*/
					
						case (pdb3[10:8])
							3'b000	:	;		/* No Action */
							3'b001	:	begin	/* SR  - only the CCR portion is manipulated in the data alu. The rest in the PCU */
											case (pdb3[4:0])
												5'b00000	:	C_a3 = (pdb3[16]) ? C : pdb3[5];	/* C */
												5'b00001	:	V_a3 = (pdb3[16]) ? V : pdb3[5];	/* V */
												5'b00010	:	Z_a3 = (pdb3[16]) ? Z : pdb3[5];	/* Z */
												5'b00011	:	N_a3 = (pdb3[16]) ? N : pdb3[5];	/* N */
												5'b00100	:	U_a3 = (pdb3[16]) ? U : pdb3[5];	/* U */
												5'b00101	:	E_a3 = (pdb3[16]) ? E : pdb3[5];	/* E */
												5'b00110	:	begin
																	L_a3 = (pdb3[16]) ? L : pdb3[5];	/* L */
																	Lwrite_a3 = `true;
																end
												5'b00111	:	begin
																	S_a3 = (pdb3[16]) ? S : pdb3[5];	/* S */
																	Swrite_a3 = `true;
																end
												default		:	;	/* No Action */
											endcase
										end
							default	:	;	/* No Action */
							
						endcase		/* pdb3[13:11] */
					
					end		/* control registers */
				
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
					/*		JCLR / JSET   Class III			*/
					/*										*/
					/*	Jump if Bit Clear/Set - Class III	*/
					/*--------------------------------------*/

				if ( pdb3[13:10] == 4'b0001 )
					begin		/*--------------------------------------*/
								/* x0, x1, y0 and y1 data alu registers */
								/*--------------------------------------*/
					
						case (pdb3[9:8])
							2'b00	:	begin	/* x0 */
											{J, x0_a3} = bit_test(x0, pdb3[4:0], pdb3[5]);
										end
							2'b01	:	begin	/* x1 */
											{J, x1_a3} = bit_test(x1, pdb3[4:0], pdb3[5]);
										end
							2'b10	:	begin	/* y0 */
											{J, y0_a3} = bit_test(y0, pdb3[4:0], pdb3[5]);
										end
							2'b11	:	begin	/* y1 */
											{J, y1_a3} = bit_test(y1, pdb3[4:0], pdb3[5]);
										end
						endcase		/* pdb3[9:8] */

					end		/* x0, x1, y0 and y1 */
				

				else if ( pdb3[13:11] == 3'b001 )
					begin		/*-------------------------------------------*/
								/* a2, a1, a0, A, b2, b1, b0, B accumulators */
								/*-------------------------------------------*/
					
						case (pdb3[10:8])
							3'b000	:	begin	/* a0 */
											{J, a0_a3} = bit_test(a0, pdb3[4:0], pdb3[5]);
										end
							3'b001	:	begin	/* b0 */
											{J, b0_a3} = bit_test(b0, pdb3[4:0], pdb3[5]);
										end
							3'b010	:	begin	/* a2 */
											case (pdb3[4:0])	/* choose the bit to be tested and cleared */
												5'b00000	:	{J, a2_a3} = {a2[0],  a2[7:1],  pdb3[5]};
												5'b00001	:	{J, a2_a3} = {a2[1],  a2[7:2],  pdb3[5], a2[0]};
												5'b00010	:	{J, a2_a3} = {a2[2],  a2[7:3],  pdb3[5], a2[1:0]};
												5'b00011	:	{J, a2_a3} = {a2[3],  a2[7:4],  pdb3[5], a2[2:0]};
												5'b00100	:	{J, a2_a3} = {a2[4],  a2[7:5],  pdb3[5], a2[3:0]};
												5'b00101	:	{J, a2_a3} = {a2[5],  a2[7:6],  pdb3[5], a2[4:0]};
												5'b00110	:	{J, a2_a3} = {a2[6],  a2[7],    pdb3[5], a2[5:0]};
												5'b00111	:	{J, a2_a3} = {a2[7],            pdb3[5], a2[6:0]};
												default		:	;		/* No Action */
											endcase
										end
							3'b011	:	begin	/* b2 */
											case (pdb3[4:0])	/* choose the bit to be tested and cleared */
												5'b00000	:	{J, b2_a3} = {b2[0],  b2[7:1],  pdb3[5]};
												5'b00001	:	{J, b2_a3} = {b2[1],  b2[7:2],  pdb3[5], b2[0]};
												5'b00010	:	{J, b2_a3} = {b2[2],  b2[7:3],  pdb3[5], b2[1:0]};
												5'b00011	:	{J, b2_a3} = {b2[3],  b2[7:4],  pdb3[5], b2[2:0]};
												5'b00100	:	{J, b2_a3} = {b2[4],  b2[7:5],  pdb3[5], b2[3:0]};
												5'b00101	:	{J, b2_a3} = {b2[5],  b2[7:6],  pdb3[5], b2[4:0]};
												5'b00110	:	{J, b2_a3} = {b2[6],  b2[7],    pdb3[5], b2[5:0]};
												5'b00111	:	{J, b2_a3} = {b2[7],            pdb3[5], b2[6:0]};
												default		:	;		/* No Action */
											endcase
										end
							3'b100	:	begin	/* a1 */
											{J, a1_a3} = bit_test(a1, pdb3[4:0], pdb3[5]);
										end
							3'b101	:	begin	/* b1 */
											{J, b1_a3} = bit_test(b1, pdb3[4:0], pdb3[5]);
										end

							3'b110	:	begin	/* A */
											S_a3 = CCR_S(S1, S0, a1);
											Swrite_a3 = `true;

											if ( CCR_E(S1, S0, {a2, a1}) )
												begin					/* Extention bits in use */
													{J, a1_a3} = ( a2[7] ) ? bit_test(24'h800000, pdb3[4:0], pdb3[5]) :
																			 bit_test(24'h7fffff, pdb3[4:0], pdb3[5]);
													L_a3 = 1'b1;		/* limiting has occurred */
													Lwrite_a3 = `true;
												end
											else
												{J, a1_a3} = bit_test(a1, pdb3[4:0], pdb3[5]);
										end		/* A */

							3'b111	:	begin	/* B */
											S_a3 = CCR_S(S1, S0, b1);
											Swrite_a3 = `true;

											if ( CCR_E(S1, S0, {b2, b1}) )
												begin					/* Extention bits in use */
													{J, b1_a3} = ( b2[7] ) ? bit_test(24'h800000, pdb3[4:0], pdb3[5]) :
																			 bit_test(24'h7fffff, pdb3[4:0], pdb3[5]);
													L_a3 = 1'b1;		/* limiting has occurred */
													Lwrite_a3 = `true;
												end
											else
													{J, b1_a3} = bit_test(b1, pdb3[4:0], pdb3[5]);
										end		/* B */
						endcase		/* pdb3[13:11] */
						
					end		/* A and B accumulators */
					
					
				else if ( pdb3[13:11] == 3'b111 )
					begin		/*-------------------*/
								/* Control registers */
								/*-------------------*/
					
						case (pdb3[10:8])
							3'b000	:	;		/* No Action */
							3'b001	:	begin	/* SR */
											case (pdb3[4:0])
												5'b00000	:	J = C;	/* C */
												5'b00001	:	J = V;	/* V */
												5'b00010	:	J = Z;	/* Z */
												5'b00011	:	J = N;	/* N */
												5'b00100	:	J = U;	/* U */
												5'b00101	:	J = E;	/* E */
												5'b00110	:	J = L;	/* L */
												5'b00111	:	J = S;	/* S */
												default		:	;	/* No Action */
											endcase
										end
							default	:	;	/* No Action - taken care of in the PCU */
						endcase		/* pdb3[13:11] */
					
					end		/* controller registers */
				
			end		/* JCLR/JSET Class III */




		else if ( ({pdb3[23:14], pdb3[7]} == 11'b00001010_01_0) || 
				  ({pdb3[23:14], pdb3[7]} == 11'b00001010_00_0) ||
				  ({pdb3[23:14], pdb3[7], pdb3[5]} == 12'b00001011_01_0_1) || 
				  ({pdb3[23:14], pdb3[7], pdb3[5]} == 12'b00001011_00_0_1) )
				  
			begin	/*----------------------------------------------*/
					/*		BCLR / BSET / BTST Class I or II		*/
					/*												*/
					/*	Bit Test and Clear/Set - Class I ro II		*/
					/*----------------------------------------------*/

					/* This is an ATOMIC instruction		*/
			
				/* write data back towards memory after passing through the bit_test function. */
				
				if (pdb3[6])
					begin												/* data to Y memory */
						{C_a3, ydb_out_atomic_a3} = bit_test(YDB, pdb3[4:0], pdb3[5]);
						ydb_out_write_atomic_a3 = (pdb3[16]) ? `false : `true;		/* don't write if BTST */
					end
				else
					begin												/* data to X memory */
						{C_a3, xdb_out_atomic_a3} = bit_test(XDB, pdb3[4:0], pdb3[5]);
						xdb_out_write_atomic_a3 = (pdb3[16]) ? `false : `true;		/* don't write if BTST */
					end

			end		/* BCLR/BSET/BTST Class I or II */




		else if ( ({pdb3[23:14], pdb3[7]} == 11'b00001010_01_1) ||
				  ({pdb3[23:14], pdb3[7]} == 11'b00001010_00_1) )
			begin	/*----------------------------------------------*/
					/*			JCLR / JSET Class I or II			*/
					/*												*/
					/*	Jump if Bit Clear/Set - Class I ro II		*/
					/*----------------------------------------------*/

				/* bit test the arriving data on the X or Y data buses. */
				/* The tested bit is put in J and passed on to the PCU. */
				
				/* !!! using the atomic buses but never write them. Just for convenience. !!! */
				
				if (pdb3[6])
					begin												/* data to Y memory */
						{J, ydb_out_atomic_a3} = bit_test(YDB, pdb3[4:0], pdb3[5]);
					end
				else
					begin												/* data to X memory */
						{J, xdb_out_atomic_a3} = bit_test(XDB, pdb3[4:0], pdb3[5]);
					end

			end		/* JCLR/JSET Class I or II */




		else if ( {pdb3[23:16], pdb3[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC  Class IV */




		else if ( {pdb3[23:16], pdb3[7], pdb3[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I and II		*/
					/*									*/
					/* No Action				 		*/
					/*----------------------------------*/
			end		/* MOVEC Class I and II */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0010_110 )
			begin	/*--------------------------------------*/
					/*					ABS					*/
					/*										*/
					/* Absolute Value						*/
					/*--------------------------------------*/

				if (pdb3[3])	/* B */
					begin
						if ({b2, b1, b0} == 56'h80_000000_000000)
							begin
								L_a3 = 1'b1;		/* an overflow occur */
								V_a3 = 1'b1;		/* an overflow occur */
							end
						else
							begin
								{b2_a3, b1_a3, b0_a3} = abs({b2, b1, b0});

								/* write enable */
								b2write_a3 = `true;
								b1write_a3 = `true;
								b0write_a3 = `true;
							end

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
					end
				else			/* A */
					begin
						if ({a2, a1, a0} == 56'h80_000000_000000)
							begin
								L_a3 = 1'b1;		/* an overflow occur */
								V_a3 = 1'b1;		/* an overflow occur */
							end
						else
							begin
								{a2_a3, a1_a3, a0_a3} = abs({a2, a1, a0});

								/* write enable */
								a2write_a3 = `true;
								a1write_a3 = `true;
								a0write_a3 = `true;
							end

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
					end

			end		/* ABS */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0011_010 )
			begin	/*--------------------------------------*/
					/*					ASL					*/
					/*										*/
					/* Arithmetic Shift Accumulator Left	*/
					/*--------------------------------------*/

				if (pdb3[3])		/* Destination: B */
					begin
						{b2_a3, b1_a3, b0_a3} = {b2[6:0], b1, b0, 1'b0};

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2[7] ^ b2_a3[7];
						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2[7] ^ b2_a3[7];				/* set if MSB was changed by the shift */
						C_a3 = b2[7];							/* gets the shifted out MSB */
					end		/* B */

				else		/* Destination: A */
					begin
						{a2_a3, a1_a3, a0_a3} = {a2[6:0], a1, a0, 1'b0};

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2[7] ^ a2_a3[7];
						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2[7] ^ a2_a3[7];				/* set if MSB was changed by the shift */
						C_a3 = a2[7];							/* gets the shifted out MSB */
					end		/* A */

			end		/* ASL */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0010_010 )
			begin	/*--------------------------------------*/
					/*					ASR					*/
					/*										*/
					/* Arithmetic Shift Accumulator Right	*/
					/*--------------------------------------*/

				if (pdb3[3])		/* Destination: B */
					begin
						{b2_a3, b1_a3, b0_a3} = {b2[7], b2, b1, b0[23:1]};

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = 1'b0;							/* always cleared */
						C_a3 = b0[0];							/* gets the shifted out LSB */
					end		/* B */

				else		/* Destination: A */
					begin
						{a2_a3, a1_a3, a0_a3} = {a2[7], a2, a1, a0[23:1]};

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = 1'b0;							/* always cleared */
						C_a3 = a0[0];							/* gets the shifted out LSB */
					end		/* A */

			end		/* ASR */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0011_011 )
			begin	/*--------------------------------------*/
					/*					LSL					*/
					/*										*/
					/* Logical Shift Left					*/
					/*--------------------------------------*/

				if (pdb3[3])		/* Destination: B */
					begin
						b1_a3 = {b1[22:0], 1'b0};

						/* write enable */

						b1write_a3 = `true;

						/* condition codes affected */

						N_a3 = CCR_N(b1_a3[23]);
						Z_a3 = CCR_Z({8'h00, b1_a3, 24'h000000});
						V_a3 = 1'b0;								/* always cleared */
						C_a3 = b1[23];								/* gets the shifted out bit 47 of B */
					end		/* B */

				else		/* Destination: A */
					begin
						a1_a3 = {a1[22:0], 1'b0};

						/* write enable */

						a1write_a3 = `true;

						/* condition codes affected */

						N_a3 = CCR_N(a1_a3[23]);
						Z_a3 = CCR_Z({8'h00, a1_a3, 24'h000000});
						V_a3 = 1'b0;								/* always cleared */
						C_a3 = a1[23];								/* gets the shifted out bit 47 of A */
					end		/* A */

			end		/* LSL */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0010_011 )
			begin	/*--------------------------------------*/
					/*					LSR					*/
					/*										*/
					/* Logical Shift Right					*/
					/*--------------------------------------*/

				if (pdb3[3])		/* Destination: B */
					begin
						b1_a3 = {1'b0, b1[23:1]};

						/* write enable */

						b1write_a3 = `true;

						/* condition codes affected */

						N_a3 = 1'b0;							/* always cleared */
						Z_a3 = CCR_Z({8'h00, b1_a3, 24'h000000});
						V_a3 = 1'b0;							/* always cleared */
						C_a3 = b1[0];							/* gets the shifted out bit 24 of B */
					end		/* B */

				else		/* Destination: A */
					begin
						a1_a3 = {1'b0, a1[23:1]};

						/* write enable */

						a1write_a3 = `true;

						/* condition codes affected */

						N_a3 = 1'b0;							/* always cleared */
						Z_a3 = CCR_Z({8'h00, a1_a3, 24'h000000});
						V_a3 = 1'b0;							/* always cleared */
						C_a3 = a1[0];							/* gets the shifted out bit 24 of A */
					end		/* A */

			end		/* LSR */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0011_111 )
			begin	/*--------------------------------------*/
					/*					ROL					*/
					/*										*/
					/* Rotate Left							*/
					/*--------------------------------------*/

				if (pdb3[3])		/* Destination: B */
					begin
						b1_a3 = {b1[22:0], C};

						/* write enable */

						b1write_a3 = `true;

						/* condition codes affected */

						N_a3 = CCR_N(b1_a3[23]);
						Z_a3 = CCR_Z({8'h00, b1_a3, 24'h000000});
						V_a3 = 1'b0;								/* always cleared */
						C_a3 = b1[23];								/* gets the shifted out bit 47 of B */
					end		/* B */

				else		/* Destination: A */
					begin
						a1_a3 = {a1[22:0], C};

						/* write enable */

						a1write_a3 = `true;

						/* condition codes affected */

						N_a3 = CCR_N(a1_a3[23]);
						Z_a3 = CCR_Z({8'h00, a1_a3, 24'h000000});
						V_a3 = 1'b0;								/* always cleared */
						C_a3 = a1[23];								/* gets the shifted out bit 47 of A */
					end		/* A */

			end		/* ROL */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0011_110 )
			begin	/*--------------------------------------*/
					/*					NEG					*/
					/*										*/
					/* Negate Accumulator					*/
					/*--------------------------------------*/

				if (pdb3[3])		/* B */
					begin
						{b2_a3, b1_a3, b0_a3} = 1 + (~{b2, b1, b0});

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2[7] && b2_a3[7];
						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2[7] && b2_a3[7];				/* set if the sign is 1 and wasn't changed by negating the accumulator */
					end		/* B */

				else			/* A */
					begin
						{a2_a3, a1_a3, a0_a3} = 1 + (~{a2, a1, a0});

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2[7] && a2_a3[7];
						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2[7] && a2_a3[7];				/* set if the sign is 1 and wasn't changed by negating the accumulator */
					end		/* A */

			end		/* NEG */



		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0001_001 )
			begin	/*--------------------------------------*/
					/*					RND					*/
					/*										*/
					/* Round Accumulator					*/
					/*--------------------------------------*/

				if (pdb3[3])	/* B */
					begin

						{b2_a3, b1_a3, b0_a3} = round (S1, S0, {b2, b1, b0});

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2_a3[7] ^ b2[7];
						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2_a3[7] ^ b2[7];

					end		/* B */

				else			/* A */
					begin

						{a2_a3, a1_a3, a0_a3} = round (S1, S0, {a2, a1, a0});

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2_a3[7] ^ a2[7];
						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2_a3[7] ^ a2[7];

					end		/* A */

			end		/* RND */



		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0001_011 )
			begin	/*--------------------------------------*/
					/*					CLR					*/
					/*										*/
					/* Clear Accumulator					*/
					/*--------------------------------------*/
			
				if (pdb3[3])	/* B */
					begin
						{b2_a3, b1_a3, b0_a3} = 56'h00_000000_000000;
						
						/* write enable */
						
						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;
						
						/* condition codes affected */

						E_a3 = 1'b0;
						U_a3 = 1'b1;
						N_a3 = 1'b0;
						Z_a3 = 1'b1;
						V_a3 = 1'b0;

					end		/* B */

				else			/* A */
					begin
						{a2_a3, a1_a3, a0_a3} = 56'h00_000000_000000;
						
						/* write enable */
						
						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;
						
						/* condition codes affected */

						E_a3 = 1'b0;
						U_a3 = 1'b1;
						N_a3 = 1'b0;
						Z_a3 = 1'b1;
						V_a3 = 1'b0;

					end		/* A */
				
			end		/* CLR */



		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0000_011 )
			begin	/*--------------------------------------*/
					/*					TST					*/
					/*										*/
					/* Clear Accumulator					*/
					/*--------------------------------------*/

				if (pdb3[4])	/* B */
					begin
						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {b2, b1});
						U_a3 = CCR_U(S1, S0, {b2, b1});
						N_a3 = CCR_N(b2[7]);
						Z_a3 = CCR_Z({b2, b1, b0});
						V_a3 = 1'b0;	/* always cleared */
					end
				else			/* A */
					begin
						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {a2, a1});
						U_a3 = CCR_U(S1, S0, {a2, a1});
						N_a3 = CCR_N(a2[7]);
						Z_a3 = CCR_Z({a2, a1, a0});
						V_a3 = 1'b0;	/* always cleared */
					end

			end		/* TST */




		else if ( {pdb3[7:4], pdb3[2:0]} == 7'b0001_010 )
			begin	/*--------------------------------------*/
					/*					ADDL				*/
					/*										*/
					/* Shift Left and Add Accumulators		*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B,  Source: A */
					begin

						{C_a3, b2_a3, b1_a3, b0_a3} = {b2[6:0], b1, b0, 1'b0} + {a2, a1, a0};
						
						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition code affected */

						L_a3 = (b2[7] ^ b2_a3[7]);						/* because of an in result only */
						E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = (b2[7] ^ b2_a3[7]) || (b2[7] ^ b2[6]);	/* in result or because of the left shift */
					end		/* B */

				else			/* Destination: A */
					begin

						{C_a3, a2_a3, a1_a3, a0_a3} = {a2[6:0], a1, a0, 1'b0} + {b2, b1, b0};
						
						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition code affected */

						L_a3 = a2[7] ^ a2_a3[7];						/* because of an overflow in result only */
						E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = (a2[7] ^ a2_a3[7]) || (a2[7] ^ a2[6]);	/* in result or because of the left shift */
					end		/* A */

			end		/* ADDL */




		else if ( {pdb3[7:6], pdb3[2:0]} == 5'b01_110 )
			begin	/*--------------------------------------*/
					/*					AND					*/
					/*										*/
					/* Logical AND							*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B (only b1 is changed) */
					begin
						case (pdb3[5:4])
							2'b00	:	b1_a3 = b1 & x0;
							2'b01	:	b1_a3 = b1 & y0;
							2'b10	:	b1_a3 = b1 & x1;
							2'b11	:	b1_a3 = b1 & y1;
						endcase
						
						/* write enable */
						b1write_a3 = `true;

						/* condition code affected */

						N_a3 = CCR_N(b1_a3[23]);
						Z_a3 = CCR_Z({8'h00, b1_a3, 24'h000000});
						V_a3 = 1'b0;	/* always cleared */
					end		/* B */

				else			/* Destination: A (only a1 is changed) */
					begin
						case (pdb3[5:4])
							2'b00	:	a1_a3 = a1 & x0;
							2'b01	:	a1_a3 = a1 & y0;
							2'b10	:	a1_a3 = a1 & x1;
							2'b11	:	a1_a3 = a1 & y1;
						endcase
						
						/* write enable */
						a1write_a3 = `true;

						/* condition code affected */

						N_a3 = CCR_N(a1_a3[23]);
						Z_a3 = CCR_Z({8'h00, a1_a3, 24'h000000});
						V_a3 = 1'b0;	/* always cleared */
					end		/* A */

			end		/* AND */




		else if ( {pdb3[7:6], pdb3[2:0]} == 5'b01_011 )
			begin	/*--------------------------------------*/
					/*					EOR					*/
					/*										*/
					/* Logical Exclusive OR					*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B (only b1 is changed) */
					begin
						case (pdb3[5:4])
							2'b00	:	b1_a3 = b1 ^ x0;
							2'b01	:	b1_a3 = b1 ^ y0;
							2'b10	:	b1_a3 = b1 ^ x1;
							2'b11	:	b1_a3 = b1 ^ y1;
						endcase
						
						/* write enable */
						b1write_a3 = `true;

						/* condition code affected */

						N_a3 = CCR_N(b1_a3[23]);
						Z_a3 = CCR_Z({8'h00, b1_a3, 24'h000000});
						V_a3 = 1'b0;	/* always cleared */
					end		/* B */

				else			/* Destination: A (only a1 is changed) */
					begin
						case (pdb3[5:4])
							2'b00	:	a1_a3 = a1 ^ x0;
							2'b01	:	a1_a3 = a1 ^ y0;
							2'b10	:	a1_a3 = a1 ^ x1;
							2'b11	:	a1_a3 = a1 ^ y1;
						endcase
						
						/* write enable */
						a1write_a3 = `true;

						/* condition code affected */

						N_a3 = CCR_N(a1_a3[23]);
						Z_a3 = CCR_Z({8'h00, a1_a3, 24'h000000});
						V_a3 = 1'b0;	/* always cleared */
					end		/* A */

			end		/* EOR */




		else if ( {pdb3[7], pdb3[2:0]} == 4'b0_000 )
			begin	/*--------------------------------------*/
					/*					ADD					*/
					/*										*/
					/* Add									*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B */
					begin
						case (pdb3[6:4])	/* C Condition code as the 57th bit */
							3'b001	:	{C_a3, b2_a3, b1_a3, b0_a3} = {a2,a1,a0} + {b2,b1,b0};						/* Source: A  */
							3'b010	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{x1[7]}}, x1,x0} 	+ {b2,b1,b0};			/* Source: X  */
							3'b011	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{y1[7]}}, y1,y0} 	+ {b2,b1,b0};			/* Source: Y  */
							3'b100	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{x0[7]}}, x0, 24'h000000} + {b2,b1,b0};	/* Source: x0 */
							3'b101	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{y0[7]}}, y0, 24'h000000} + {b2,b1,b0};	/* Source: y0 */
							3'b110	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{x1[7]}}, x1, 24'h000000} + {b2,b1,b0};	/* Source: x1 */
							3'b111	:	{C_a3, b2_a3, b1_a3, b0_a3} = {{8{y1[7]}}, y1, 24'h000000} + {b2,b1,b0};	/* Source: y1 */
							default	:	;																			/* No Action  */
						endcase	/* pdb3[6:4] */

						if (pdb3[6:4] != 3'b000)	/* when JJJ != 000 */
							begin
								/* write enable */

								b2write_a3 = `true;
								b1write_a3 = `true;
								b0write_a3 = `true;

								/* condition code affected */

								L_a3 = b2[7] ^ b2_a3[7];
								E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
								U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
								N_a3 = CCR_N(b2_a3[7]);
								Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
								V_a3 = b2[7] ^ b2_a3[7];
							end
					end		/* B */

				else			/* Destination: A */
					begin
						case (pdb3[6:4])	/* C Condition code as the 57th bit */
							3'b001	:	{C_a3, a2_a3, a1_a3, a0_a3} = {b2,b1,b0} + {a2,a1,a0};						/* Source: B  */
							3'b010	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{x1[7]}}, x1,x0} 	+ {a2,a1,a0};			/* Source: X  */
							3'b011	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{y1[7]}}, y1,y0} 	+ {a2,a1,a0};			/* Source: Y  */
							3'b100	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{x0[7]}}, x0, 24'h000000} + {a2,a1,a0};	/* Source: x0 */
							3'b101	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{y0[7]}}, y0, 24'h000000} + {a2,a1,a0};	/* Source: y0 */
							3'b110	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{x1[7]}}, x1, 24'h000000} + {a2,a1,a0};	/* Source: x1 */
							3'b111	:	{C_a3, a2_a3, a1_a3, a0_a3} = {{8{y1[7]}}, y1, 24'h000000} + {a2,a1,a0};	/* Source: y1 */
							default	:	;																			/* No Action  */
						endcase	/* pdb3[6:4] */

						if (pdb3[6:4] != 3'b000)	/* when JJJ != 000 */
							begin

								/* write enable */

								a2write_a3 = `true;
								a1write_a3 = `true;
								a0write_a3 = `true;

								/* condition code affected */

								L_a3 = a2[7] ^ a2_a3[7];
								E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
								U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
								N_a3 = CCR_N(a2_a3[7]);
								Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
								V_a3 = a2[7] ^ a2_a3[7];
							end
					end		/* A */

			end		/* ADD */



		else if ( {pdb3[7], pdb3[2:0]} == 4'b0_100 )
			begin	/*--------------------------------------*/
					/*					SUB					*/
					/*										*/
					/* Subtract								*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination: B */
					begin
						case (pdb3[6:4])
							3'b001	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {a2,a1,a0};						/* Source: A  */
							3'b010	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{x1[7]}}, x1,x0};				/* Source: X  */
							3'b011	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{y1[7]}}, y1,y0};				/* Source: Y  */
							3'b100	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{x0[7]}}, x0, 24'h000000};	/* Source: x0 */
							3'b101	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{y0[7]}}, y0, 24'h000000};	/* Source: y0 */
							3'b110	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{x1[7]}}, x1, 24'h000000};	/* Source: x1 */
							3'b111	:	{b2_a3,b1_a3,b0_a3} = {b2,b1,b0} - {{8{y1[7]}}, y1, 24'h000000};	/* Source: y1 */
							default	:	;																	/* No Action  */
						endcase	/* pdb3[6:4] */

						if (pdb3[6:4] != 3'b000)	/* when JJJ != 000 */
							begin
								/* write enable */

								b2write_a3 = `true;
								b1write_a3 = `true;
								b0write_a3 = `true;

								/* condition code affected */

								E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
								U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
								N_a3 = CCR_N(b2_a3[7]);
								Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
							end
					end		/* B */

				else			/* Destination: A */
					begin
						case (pdb3[6:4])
							3'b001	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {b2,b1,b0};						/* Source: B  */
							3'b010	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{x1[7]}}, x1,x0};				/* Source: X  */
							3'b011	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{y1[7]}}, y1,y0};				/* Source: Y  */
							3'b100	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{x0[7]}}, x0, 24'h000000};	/* Source: x0 */
							3'b101	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{y0[7]}}, y0, 24'h000000};	/* Source: y0 */
							3'b110	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{x1[7]}}, x1, 24'h000000};	/* Source: x1 */
							3'b111	:	{a2_a3,a1_a3,a0_a3} = {a2,a1,a0} - {{8{y1[7]}}, y1, 24'h000000};	/* Source: y1 */
							default	:	;																	/* No Action  */
						endcase	/* pdb3[6:4] */

						if (pdb3[6:4] != 3'b000)	/* when JJJ != 000 */
							begin

								/* write enable */

								a2write_a3 = `true;
								a1write_a3 = `true;
								a0write_a3 = `true;

								/* condition code affected */

								E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
								U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
								N_a3 = CCR_N(a2_a3[7]);
								Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
							end
					end		/* A */

			end		/* SUB */



		else if ( {pdb3[7], pdb3[2], pdb3[0]} == 3'b0_1_1 )
			begin	/*--------------------------------------*/
					/*				CMP / CMPM				*/
					/*										*/
					/* Compare Magnitude					*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Source 2 (ACC): B */
					begin
						cmpm_abs_s2 = abs( {b2, b1, b0} );		/* absolute of source 2 */

						case (pdb3[6:4])
							3'b000	:	{b2_a3, b1_a3, b0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( {a2, a1, a0} ) :
																			{b2, b1, b0}  -    {a2, a1, a0} ;						/* Source 1: A  */

							3'b100	:	{b2_a3, b1_a3, b0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{x0[7]}}, x0, 24'h000000 } ) :
																			{b2, b1 ,b0}  -    { {8{x0[7]}}, x0, 24'h000000 };		/* Source 1: x0 */

							3'b101	:	{b2_a3, b1_a3, b0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{y0[7]}}, y0, 24'h000000 } ) :
																			{b2, b1 ,b0}  -    { {8{y0[7]}}, y0, 24'h000000 };		/* Source 1: y0 */

							3'b110	:	{b2_a3, b1_a3, b0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{x1[7]}}, x1, 24'h000000 } ) :
																			{b2, b1 ,b0} -     { {8{x1[7]}}, x1, 24'h000000 };		/* Source 1: x1 */

							3'b111	:	{b2_a3, b1_a3, b0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{y1[7]}}, y1, 24'h000000 } ) :
																			{b2, b1 ,b0} -     { {8{y1[7]}}, y1, 24'h000000 };		/* Source 1: y1 */

							default	:	;		/* No Action  */
						endcase		/* pdb3[6:4] */

						/* condition code affected */

						case (pdb3[6:4])
							3'b000,
							3'b100,
							3'b101,
							3'b110,
							3'b111	:	begin
											case (pdb3[6:4])
												3'b000	:	L_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(a2[7])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && a2[7] && b2_a3[7] ;
																										  
												3'b100	:	L_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(x0[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && x0[23] && b2_a3[7] ;
																										  
												3'b101	:	L_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(y0[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && y0[23] && b2_a3[7] ;
												
												3'b110	:	L_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(x1[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && x1[23] && b2_a3[7] ;
												
												3'b111	:	L_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(y1[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && y1[23] && b2_a3[7] ;
												
												default	:	;	/* not defined */
											endcase

											E_a3 = CCR_E(S1, S0, {b2_a3, b1_a3});
											U_a3 = CCR_U(S1, S0, {b2_a3, b1_a3});
											N_a3 = CCR_N(b2_a3[7]);
											Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});

											/* An overflow occurs when:											*/
											/* CPM: source2 is pos, source1 is neg and the result is neg OR		*/
											/*		source2 is neg, source1 is pos and the result is pos.		*/
											/* CPMP: if b2=(-256) the compare is incorrect						*/
											case (pdb3[6:4])
												3'b000	:	V_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(a2[7])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && a2[7] && b2_a3[7] ;
																										  
												3'b100	:	V_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(x0[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && x0[23] && b2_a3[7] ;
																										  
												3'b101	:	V_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(y0[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && y0[23] && b2_a3[7] ;
												
												3'b110	:	V_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(x1[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && x1[23] && b2_a3[7] ;
												
												3'b111	:	V_a3 = (pdb3[1]) ? b2[7] && cmpm_abs_s2[55] : (b2[7] && (~(y1[23])) && (~(b2_a3[7]))) ||
																										  (~(b2[7])) && y1[23] && b2_a3[7] ;
												
												default	:	;	/* not defined */
											endcase

											/* set if borrow occured - MSB '0' becomes '1' */
											C_a3 = (pdb3[1]) ? (~(cmpm_abs_s2[55])) && b2_a3[7] : (~(b2[7])) && b2_a3[7] ;
										end

							default	:	;	/* No Action */

						endcase		/* pdb3[6:4] */

					end		/* B */

				else			/* Source 2 (ACC): A */
					begin
						cmpm_abs_s2 = abs( {a2, a1, a0} );		/* absolute of source 2 */

						case (pdb3[6:4])
							3'b001	:	{a2_a3, a1_a3, a0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( {b2, b1, b0} ) :
																			{a2, a1, a0} -     {b2, b1, b0};						/* Source: B  */

							3'b100	:	{a2_a3, a1_a3, a0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{x0[7]}}, x0, 24'h000000 } ) :
																			{a2, a1, a0} -     { {8{x0[7]}}, x0, 24'h000000 };		/* Source: x0 */

							3'b101	:	{a2_a3, a1_a3, a0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{y0[7]}}, y0, 24'h000000 } ) :
																			{a2, a1, a0} -     { {8{y0[7]}}, y0, 24'h000000 };		/* Source: y0 */

							3'b110	:	{a2_a3, a1_a3, a0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{x1[7]}}, x1, 24'h000000 } ) :
																			{a2, a1, a0} -     { {8{x1[7]}}, x1, 24'h000000 };		/* Source: x1 */

							3'b111	:	{a2_a3, a1_a3, a0_a3} = (pdb3[1]) ? cmpm_abs_s2 - abs( { {8{y1[7]}}, y1, 24'h000000 } ) :
																			{a2, a1, a0} -     { {8{y1[7]}}, y1, 24'h000000 };		/* Source: y1 */

							default	:	;			/* No Action  */
						endcase	/* pdb3[6:4] */

						/* condition code affected */

						case (pdb3[6:4])
							3'b000,
							3'b100,
							3'b101,
							3'b110,
							3'b111	:	begin
											case (pdb3[6:4])
												3'b000	:	L_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(b2[7])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && b2[7] && a2_a3[7] ;
																										  
												3'b100	:	L_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(x0[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && x0[23] && a2_a3[7] ;
																										  
												3'b101	:	L_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(y0[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && y0[23] && a2_a3[7] ;
												
												3'b110	:	L_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(x1[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && x1[23] && a2_a3[7] ;
												
												3'b111	:	L_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(y1[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && y1[23] && a2_a3[7] ;
												
												default	:	;	/* not defined */
											endcase

											E_a3 = CCR_E(S1, S0, {a2_a3, a1_a3});
											U_a3 = CCR_U(S1, S0, {a2_a3, a1_a3});
											N_a3 = CCR_N(a2_a3[7]);
											Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});

											/* An overflow occurs when:											*/
											/* CPM: source2 is pos, source1 is neg and the result is neg OR		*/
											/*		source2 is neg, source1 is pos and the result is pos.		*/
											/* CPMP: if b2=(-256) the compare is incorrect						*/
											case (pdb3[6:4])
												3'b000	:	V_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(b2[7])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && b2[7] && a2_a3[7] ;
																										  
												3'b100	:	V_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(x0[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && x0[23] && a2_a3[7] ;
																										  
												3'b101	:	V_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(y0[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && y0[23] && a2_a3[7] ;
												
												3'b110	:	V_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(x1[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && x1[23] && a2_a3[7] ;
												
												3'b111	:	V_a3 = (pdb3[1]) ? a2[7] && cmpm_abs_s2[55] : (a2[7] && (~(y1[23])) && (~(a2_a3[7]))) ||
																										  (~(a2[7])) && y1[23] && a2_a3[7] ;
												
												default	:	;	/* not defined */
											endcase

											/* set if borrow occured - MSB '0' becomes '1' */
											C_a3 = (pdb3[1]) ? (~(cmpm_abs_s2[55])) && a2_a3[7] : (~(a2[7])) && a2_a3[7] ;
										end

							default	:	;	/* No Action */
							
						endcase		/* pdb3[6:4] */

					end		/* A */

			end		/* CMP/CMPM */



		else if ( {pdb3[7], pdb3[1:0]} == 3'b1_10 )
			begin	/*--------------------------------------*/
					/*					MAC					*/
					/*										*/
					/* Signed Multiply-Accumulate			*/
					/*--------------------------------------*/
					/*										*/
					/* 				MAC Format 1			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination:  B */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(x0, x0)) : ({b2,b1,b0} + mul(x0, x0));

							3'b001	:	/* Sources:	 y0 * y0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(y0, y0)) : ({b2,b1,b0} + mul(y0, y0));

							3'b010	:	/* Sources:	 x1 * x0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(x1, x0)) : ({b2,b1,b0} + mul(x1, x0));

							3'b011	:	/* Sources:	 y1 * y0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(y1, y0)) : ({b2,b1,b0} + mul(y1, y0));

							3'b100	:	/* Sources:	 x0 * y1 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(x0, y1)) : ({b2,b1,b0} + mul(x0, y1));

							3'b101	:	/* Sources:	 y0 * x0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(y0, x0)) : ({b2,b1,b0} + mul(y0, x0));

							3'b110	:	/* Sources:	 x1 * y0 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(x1, y0)) : ({b2,b1,b0} + mul(x1, y0));

							3'b111	:	/* Sources:	 y1 * x1 */
										{b2_a3,b1_a3,b0_a3} = (pdb3[2]) ? ({b2,b1,b0} - mul(y1, x1)) : ({b2,b1,b0} + mul(y1, x1));
						endcase		/* 	pdb3[6:4] */

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2_a3[7] ^ b2[7];
						E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2_a3[7] ^ b2[7];

					end		/* B */

				else			/* Destination:  A */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(x0, x0)) : ({a2,a1,a0} + mul(x0, x0));

							3'b001	:	/* Sources:	 y0 * y0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(y0, y0)) : ({a2,a1,a0} + mul(y0, y0));

							3'b010	:	/* Sources:	 x1 * x0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(x1, x0)) : ({a2,a1,a0} + mul(x1, x0));

							3'b011	:	/* Sources:	 y1 * y0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(y1, y0)) : ({a2,a1,a0} + mul(y1, y0));

							3'b100	:	/* Sources:	 x0 * y1 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(x0, y1)) : ({a2,a1,a0} + mul(x0, y1));

							3'b101	:	/* Sources:	 y0 * x0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(y0, x0)) : ({a2,a1,a0} + mul(y0, x0));

							3'b110	:	/* Sources:	 x1 * y0 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(x1, y0)) : ({a2,a1,a0} + mul(x1, y0));

							3'b111	:	/* Sources:	 y1 * x1 */
										{a2_a3,a1_a3,a0_a3} = (pdb3[2]) ? ({a2,a1,a0} - mul(y1, x1)) : ({a2,a1,a0} + mul(y1, x1));
						endcase		/* 	pdb3[6:4] */

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2_a3[7] ^ a2[7];
						E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2_a3[7] ^ a2[7];

					end		/* A */

			end		/* MAC Format 1 */



		else if ( {pdb3[7], pdb3[1:0]} == 3'b1_11 )
			begin	/*--------------------------------------*/
					/*					MACR				*/
					/*										*/
					/* Signed Multiply-Accumulate and Round	*/
					/*--------------------------------------*/
					/*										*/
					/* 				MACR Format 1			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination:  B */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(x0, x0)) : ({b2,b1,b0} + mul(x0, x0));

							3'b001	:	/* Sources:	 y0 * y0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(y0, y0)) : ({b2,b1,b0} + mul(y0, y0));

							3'b010	:	/* Sources:	 x1 * x0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(x1, x0)) : ({b2,b1,b0} + mul(x1, x0));

							3'b011	:	/* Sources:	 y1 * y0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(y1, y0)) : ({b2,b1,b0} + mul(y1, y0));

							3'b100	:	/* Sources:	 x0 * y1 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(x0, y1)) : ({b2,b1,b0} + mul(x0, y1));

							3'b101	:	/* Sources:	 y0 * x0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(y0, x0)) : ({b2,b1,b0} + mul(y0, x0));

							3'b110	:	/* Sources:	 x1 * y0 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(x1, y0)) : ({b2,b1,b0} + mul(x1, y0));

							3'b111	:	/* Sources:	 y1 * x1 */
										pre_round = (pdb3[2]) ? ({b2,b1,b0} - mul(y1, x1)) : ({b2,b1,b0} + mul(y1, x1));
						endcase		/* 	pdb3[6:4] */

						/* round */
						
						{b2_a3, b1_a3, b0_a3} = round(S1, S0, pre_round);
						
						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2_a3[7] ^ pre_round[55];
						E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2_a3[7] ^ pre_round[55];

					end		/* B */

				else			/* Destination:  A */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(x0, x0)) : ({a2,a1,a0} + mul(x0, x0));

							3'b001	:	/* Sources:	 y0 * y0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(y0, y0)) : ({a2,a1,a0} + mul(y0, y0));

							3'b010	:	/* Sources:	 x1 * x0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(x1, x0)) : ({a2,a1,a0} + mul(x1, x0));

							3'b011	:	/* Sources:	 y1 * y0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(y1, y0)) : ({a2,a1,a0} + mul(y1, y0));

							3'b100	:	/* Sources:	 x0 * y1 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(x0, y1)) : ({a2,a1,a0} + mul(x0, y1));

							3'b101	:	/* Sources:	 y0 * x0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(y0, x0)) : ({a2,a1,a0} + mul(y0, x0));

							3'b110	:	/* Sources:	 x1 * y0 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(x1, y0)) : ({a2,a1,a0} + mul(x1, y0));

							3'b111	:	/* Sources:	 y1 * x1 */
										pre_round = (pdb3[2]) ? ({a2,a1,a0} - mul(y1, x1)) : ({a2,a1,a0} + mul(y1, x1));
						endcase		/* 	pdb3[6:4] */

						/* round */
						
						{a2_a3, a1_a3, a0_a3} = round( S1, S0, pre_round);
						
						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2_a3[7] ^ pre_round[55];
						E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2_a3[7] ^ pre_round[55];

					end		/* A */

			end		/* MACR Format 1 */




		else if ( {pdb3[7], pdb3[1:0]} == 3'b1_00 )
			begin	/*--------------------------------------*/
					/*					MPY					*/
					/*										*/
					/* Signed Multiply						*/
					/*--------------------------------------*/
					/*										*/
					/* 				MPY Format 1			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination:  B */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(x0, x0))) + 1) : mul(x0, x0);

							3'b001	:	/* Sources:	 y0 * y0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(y0, y0))) + 1) : mul(y0, y0);

							3'b010	:	/* Sources:	 x1 * x0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(x1, x0))) + 1) : mul(x1, x0);

							3'b011	:	/* Sources:	 y1 * y0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(y1, y0))) + 1) : mul(y1, y0);

							3'b100	:	/* Sources:	 x0 * y1 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(x0, y1))) + 1) : mul(x0, y1);

							3'b101	:	/* Sources:	 y0 * x0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(y0, x0))) + 1) : mul(y0, x0);

							3'b110	:	/* Sources:	 x1 * y0 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(x1, y0))) + 1) : mul(x1, y0);

							3'b111	:	/* Sources:	 y1 * x1 */
										{b2_a3, b1_a3, b0_a3} = (pdb3[2]) ? ((~(mul(y1, x1))) + 1) : mul(y1, x1);
						endcase		/* 	pdb3[6:4] */

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});

					end		/* B */

				else			/* Destination:  A */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(x0, x0))) + 1) : mul(x0, x0);

							3'b001	:	/* Sources:	 y0 * y0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(y0, y0))) + 1) : mul(y0, y0);

							3'b010	:	/* Sources:	 x1 * x0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(x1, x0))) + 1) : mul(x1, x0);

							3'b011	:	/* Sources:	 y1 * y0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(y1, y0))) + 1) : mul(y1, y0);

							3'b100	:	/* Sources:	 x0 * y1 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(x0, y1))) + 1) : mul(x0, y1);

							3'b101	:	/* Sources:	 y0 * x0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(y0, x0))) + 1) : mul(y0, x0);

							3'b110	:	/* Sources:	 x1 * y0 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(x1, y0))) + 1) : mul(x1, y0);

							3'b111	:	/* Sources:	 y1 * x1 */
										{a2_a3, a1_a3, a0_a3} = (pdb3[2]) ? ((~(mul(y1, x1))) + 1) : mul(y1, x1);
						endcase		/* 	pdb3[6:4] */

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});

					end		/* A */

			end		/* MPY Format 1 */




		else if ( {pdb3[7], pdb3[1:0]} == 3'b1_01 )
			begin	/*--------------------------------------*/
					/*					MPYR				*/
					/*										*/
					/* Signed Multiply and Round			*/
					/*--------------------------------------*/
					/*										*/
					/* 				MPYR Format 1			*/
					/*										*/
					/*--------------------------------------*/

				if (pdb3[3])	/* Destination:  B */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(x0, x0))) + 1'b1) : mul(x0, x0);

							3'b001	:	/* Sources:	 y0 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(y0, y0))) + 1'b1) : mul(y0, y0);

							3'b010	:	/* Sources:	 x1 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(x1, x0))) + 1'b1) : mul(x1, x0);

							3'b011	:	/* Sources:	 y1 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(y1, y0))) + 1'b1) : mul(y1, y0);

							3'b100	:	/* Sources:	 x0 * y1 */
										pre_round = (pdb3[2]) ? ((~(mul(x0, y1))) + 1'b1) : mul(x0, y1);

							3'b101	:	/* Sources:	 y0 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(y0, x0))) + 1'b1) : mul(y0, x0);

							3'b110	:	/* Sources:	 x1 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(x1, y0))) + 1'b1) : mul(x1, y0);

							3'b111	:	/* Sources:	 y1 * x1 */
										pre_round = (pdb3[2]) ? ((~(mul(y1, x1))) + 1'b1) : mul(y1, x1);
						endcase		/* 	pdb3[6:4] */

						/* round */

						{b2_a3, b1_a3, b0_a3} = round (S1, S0, pre_round);

						/* write enable */

						b2write_a3 = `true;
						b1write_a3 = `true;
						b0write_a3 = `true;

						/* condition codes affected */

						L_a3 = b2_a3[7] ^ pre_round[55];
						E_a3 = CCR_E(S1, S0, {b2_a3,b1_a3});
						U_a3 = CCR_U(S1, S0, {b2_a3,b1_a3});
						N_a3 = CCR_N(b2_a3[7]);
						Z_a3 = CCR_Z({b2_a3, b1_a3, b0_a3});
						V_a3 = b2_a3[7] ^ pre_round[55];		/* overflow because of the rounding */

					end		/* B */

				else			/* Destination:  A */
					begin
						case (pdb3[6:4])
							3'b000	:	/* Sources:	 x0 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(x0, x0))) + 1'b1) : mul(x0, x0);

							3'b001	:	/* Sources:	 y0 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(y0, y0))) + 1'b1) : mul(y0, y0);

							3'b010	:	/* Sources:	 x1 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(x1, x0))) + 1'b1) : mul(x1, x0);

							3'b011	:	/* Sources:	 y1 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(y1, y0))) + 1'b1) : mul(y1, y0);

							3'b100	:	/* Sources:	 x0 * y1 */
										pre_round = (pdb3[2]) ? ((~(mul(x0, y1))) + 1'b1) : mul(x0, y1);

							3'b101	:	/* Sources:	 y0 * x0 */
										pre_round = (pdb3[2]) ? ((~(mul(y0, x0))) + 1'b1) : mul(y0, x0);

							3'b110	:	/* Sources:	 x1 * y0 */
										pre_round = (pdb3[2]) ? ((~(mul(x1, y0))) + 1'b1) : mul(x1, y0);

							3'b111	:	/* Sources:	 y1 * x1 */
										pre_round = (pdb3[2]) ? ((~(mul(y1, x1))) + 1'b1) : mul(y1, x1);
						endcase		/* 	pdb3[6:4] */

						/* round */

						{a2_a3, a1_a3, a0_a3} = round (S1, S0, pre_round);

						/* write enable */

						a2write_a3 = `true;
						a1write_a3 = `true;
						a0write_a3 = `true;

						/* condition codes affected */

						L_a3 = a2_a3[7] ^ pre_round[55];
						E_a3 = CCR_E(S1, S0, {a2_a3,a1_a3});
						U_a3 = CCR_U(S1, S0, {a2_a3,a1_a3});
						N_a3 = CCR_N(a2_a3[7]);
						Z_a3 = CCR_Z({a2_a3, a1_a3, a0_a3});
						V_a3 = a2_a3[7] ^ pre_round[55];		/* overflow because of the rounding */

					end		/* A */

			end		/* MPYR Format 1 */


		else
			begin	/* No Action */
			
			end		/* NO Action */



	end		/* @(pdb3) arithmetic section	*/





endmodule		/* data_alu */
