/*	File:	pcu.v	  													*/

/*	module name: pcu													*/

/*	Description: The Program Control Unit for the Motorola 56K core.	*/


/*  Author:	Nitzan Weinberg												*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	pcu																	*/
/*																				*/
/********************************************************************************/

module pcu (
	reset,
	PDB,
	GDB,
	PAB_in,
	CCR_from_alu,
	Swrite,
	Lwrite,
	J,
	PAB_out,
	REPEAT,
	CCR,
	S1,
	S0,
	Clk
	);


/*==================================================================================*/
/*============						I/O direction						============*/
/*==================================================================================*/

input reset;
input [`databus] PDB;
input [`addrbus] GDB;
input [`addrbus] PAB_in;
input [7:0] CCR_from_alu;
input Swrite;
input Lwrite;
input J;

output [`addrbus] PAB_out;
output REPEAT;
output [7:0] CCR;
output S1;
output S0;

input Clk;


/*==================================================================================*/
/*============							I/O type						============*/
/*==================================================================================*/

wire reset;
wire [`databus] PDB;
wire [`addrbus] GDB;
wire [`addrbus] PAB_in;
wire [7:0] CCR;				/* condition code register from the data alu */
wire J;						/* jump indicated by the AGU or the data alu */

reg [`addrbus] PAB_out;		/* program address bus for use with branch commands */
reg REPEAT;					/* repeat last word instruction signal */

wire Clk;


/*==================================================================================*/
/*===========						Internal Nets						============*/
/*==================================================================================*/

reg [`databus] pdb2;		/* program instruction that is processed during stage 2 (Decode) */
reg [`databus] pdb3;		/* program instruction that is processed during stage 3 (Execute) */

reg [`addrbus] jump_address;	/* the absolute jump address coming from program memory for JCLR/JSET */

reg PABwrite;				/* write enable to the PAB */


/*----------*/
/* PC		*/
/*----------*/

reg [`addrbus] PC;			/* program counter REGISTER 									*/
reg [`addrbus] PC_in;		/* the input to the program counter register					*/
reg [`addrbus] PC_in_2;		/* the new value for the program counter from stage 2			*/
reg [`addrbus] PC_in_3;		/* the new value for the program counter from stage 3			*/
reg PCwrite;				/* PC register write enable										*/
reg PCwrite_2;				/* program counter write enable for value coming from stage 2	*/
reg PCwrite_3;				/* program counter write enable for value coming from stage 3	*/


/*--------------*/
/* System Stack */
/*--------------*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/* Attention!																				*/
/* System Stack in the DSP56K holds 15 words, whereas in this module it has 16 words.		*/
/* But, word ZERO is not written in normal usage of the stack (when SP doesn't underflow).	*/
/* The first word normally used is ONE.														*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

reg [`addrbus] SP;				/* Stack pointer REGISTER 					*/
reg [`addrbus] SP_in;			/* the input for the stack pointer register	*/
reg [`addrbus] SP_in_2;			/* the new value for the SP from stage 2	*/
reg [`addrbus] SP_in_3;			/* the new value for the SP from stage 3	*/
reg SPwrite;					/* stack pointer write enable				*/
reg SPwrite_2;					/* SP write enable from stage 2				*/
reg SPwrite_3;					/* SP write enable from stage 3				*/

reg [`addrbus] SSL [`addrbus];	/* System Stack Low bank 					*/
reg [`addrbus] SSL_in;			/* System Stack Low input					*/
reg [`addrbus] SSL_in_2;		/* System Stack Low input from stage 2		*/
reg [`addrbus] SSL_in_3;		/* System Stack Low input from stage 3		*/
reg SSLwrite;					/* SSL write enable							*/
reg SSLwrite_2;					/* SSL write enable from stage 2			*/
reg SSLwrite_3;					/* SSL write enable from stage 3			*/

reg [`addrbus] SSH [`addrbus];	/* System Stack High bank 					*/
reg [`addrbus] SSH_in;			/* System Stack High input					*/
reg [`addrbus] SSH_in_2;		/* System Stack High input from stage 2		*/
reg [`addrbus] SSH_in_3;		/* System Stack High input from stage 3		*/
reg SSHwrite;					/* SSH write enable							*/
reg SSHwrite_2;					/* SSH write enable from stage 2			*/
reg SSHwrite_3;					/* SSH write enable from stage 3			*/


/*----------*/
/* LC		*/
/*----------*/

reg [`addrbus] LC;				/* Loop counter REGISTER										*/
reg [`addrbus] LC_in;			/* the input to the loop counter register						*/
reg [`addrbus] LC_repeat;		/* the initial number of repetitions for a REP inst				*/
reg [`addrbus] LC_do;			/* the initial number of iterations for a DO loop, from stage 3	*/

reg [`addrbus] TEMP;			/* the temporary REGISTER holding the previous LC while a REP inst. is running */
								/* LC is restored from this register at the end of REP. 		*/
reg [`addrbus] TEMP_in;			/* the input to the TEMP register								*/
reg TEMPwrite;					/* the write enable for the TEMP register, created by REP inst.	*/

reg LCwrite;					/* the write enable for the loop counter register				*/ 
reg LCwrite_repeat;				/* the write enable for the loop counter's initial value		*/ 
reg LCwrite_do;					/* the write enable for the loop counter from stage 3 (DO)		*/ 


/*----------*/
/* LA		*/
/*----------*/

reg [`addrbus] LA;				/* Loop address REGISTER					*/
reg [`addrbus] LA_in;			/* the new input to the loop address		*/
reg LAwrite;					/* LA register write enable					*/ 
reg LAwrite_2;					/* loop address write enable from stage 2	*/ 


/*--------*/
/* repeat */
/*--------*/

reg REPEATset;				/* set the repeat signal (flip-flop) */
reg REPEATreset;			/* reset the repeat signal (flip-flop) */
reg REPEAT_async_reset;		/* async bring REPEAT to zero when only one repetition is required (in REP inst) */


/*----------------------*/
/* MR - mode register	*/
/*----------------------*/

wire [7:0] MR;				/* mode register */


/*---------------------------------------------------*/
/* Status Register (SR) - Mode Register (MR) portion */
/*---------------------------------------------------*/

reg LF;						/* bit 15 - Loop Flag */
reg LF_in;								/* The new LF bit before latching */
reg LF_in_3;							/* A new LF bit coming from stage 3 (DO instruction begins) */
reg LFwrite;							/* write enable */
reg LFwrite_3;							/* write enable from stage 3 to start a DO loop */
reg LF_reset;							/* reset LF at the end of a DO instruction */
reg LF_restore;							/* restore LF at the end of the last DO loop from the SSH */

reg DM;						/* bit 14 - Double Precision Multiply Mode */
reg DM_in;								/* The new DM bit before latching */
reg DMwrite;							/* write enable */

reg S1;						/* bit 11 - scaling mode */
reg S1_in;								/* The new S1 bit before latching */
reg S1write;							/* write enable */

reg S0;						/* bit 10 - scaling mode */
reg S0_in;								/* The new S0 bit before latching */
reg S0write;							/* write enable */

reg I1;						/* bit  9 - Interrupt Mask */
reg I1_in;								/* The new I1 bit before latching */
reg I1write;							/* write enable */

reg I0;						/* bit  8 - Interrupt Mask */
reg I0_in;								/* The new I0 bit before latching */
reg I0write;							/* write enable */


/*----------------------------------*/
/* Operating Mode Register (OMR)	*/
/*----------------------------------*/

reg [23:0] OMR;				/* Latched OMR */
reg [23:0] OMR_in;			/* The new OMR content before latching */

reg OMRwrite;				/* write enable */


/*--------------------------------------------------------------*/
/* Status Register (SR) - Condition Code Register (CCR) portion */
/*--------------------------------------------------------------*/

/* All are TRUE condition code bits - `true when the condition is met	*/

/* latched	bits */
/*---------------*/
reg S;						/* bit 7 - Scaling		*/

reg L;						/* bit 6 - Limit		*/


/* NOT latched	bits	*/
/*----------------------*/

/* The following bits are calculated from the result at the end of a data ALU operation.	*/

reg E;						/* bit 5 - Extension	*/

reg U;						/* bit 4 - Unnormalized	*/

reg N;						/* bit 3 - Negative		*/

reg Z;						/* bit 2 - Zero			*/

reg V;						/* bit 1 - Overflow		*/

reg C;						/* bit 0 - Carry		*/





/*------------------------------------------------------------------------------------------------------*/
/* absolute address / immediate data effective addressing mode											*/
/*																										*/
/* A flag  - when true signals that a source's absolute memory address or an immediate data is used.	*/
/* In this case TWO instruction words are required:														*/
/* The instruction and the absolute address/immediate data.												*/
/*------------------------------------------------------------------------------------------------------*/

reg absolute_immediate;		/* changed in stage 2 to reflect either an an absolute address or an immediate data in a TWO word instruction */



/*==================================================================================*/
/*===========					Module Instantiation					============*/
/*==================================================================================*/



/*==============================================================================================*/
/*==============================================================================================*/
/*																								*/
/*	Processes								Processes							Processes		*/
/*																								*/
/*==============================================================================================*/
/*==============================================================================================*/


/*==============================================================================================*/
/*																								*/
/*	Mode Register (MR) Bits																		*/
/*																								*/
/*==============================================================================================*/

assign MR = {LF, DM, 1'b0, 1'b0, S1, S0, I1, I0};


always @(posedge Clk)
	begin
		if (reset)
			begin	/* clear all MR bits */
				LF <= 1'b0;			/* clear */
				DM <= 1'b0;			/* clear */
				S1 <= 1'b0;			/* clear */
				S0 <= 1'b0;			/* clear */
				I1 <= 1'b1;			/* set */
				I0 <= 1'b1;			/* set */
				OMR <= 24'h000000;	/* clear */
			end
		else
			begin
				LF <= (LFwrite) ? LF_in : LF;
				DM <= (DMwrite) ? DM_in : DM;
				S1 <= (S1write) ? S1_in : S1;
				S0 <= (S0write) ? S0_in : S0;
				I1 <= (I1write) ? I1_in : I1;
				I0 <= (I0write) ? I0_in : I0;

				OMR <= (OMRwrite) ? OMR_in : OMR;
			end
	end



/*==============================================================================================*/
/*																								*/
/*	Latched Status Register Bits																*/
/*																								*/
/*==============================================================================================*/

assign CCR = {S, L, E, U, N, Z, V, C};


always @(posedge Clk)
	begin
		if (reset)
			begin	/* clear all CCR bits */
				S  <= 1'b0;			/* clear */
				L  <= 1'b0;			/* clear */
			end
		else
			begin
				S <= (Swrite) ? CCR_from_alu[7] : S;
				L <= (Lwrite) ? CCR_from_alu[6] : L;
			end
	end


/*==============================================================================================*/
/*																								*/
/*	Non Latched Status Register Bits															*/
/*																								*/
/*==============================================================================================*/

always @(posedge Clk)
	begin
		if (reset)
			begin
				E <= 1'b0;
				U <= 1'b0;
				N <= 1'b0;
				Z <= 1'b0;
				V <= 1'b0;
				C <= 1'b0;
			end
		else
			begin
				E <= CCR_from_alu[5];
				U <= CCR_from_alu[4];
				N <= CCR_from_alu[3];
				Z <= CCR_from_alu[2];
				V <= CCR_from_alu[1];
				C <= CCR_from_alu[0];
			end
	end



/*==============================================================================*/
/*																				*/
/*	LF mode bit																	*/
/*																				*/
/*==============================================================================*/

/* select the input to the LF bit */

reg [15:0] tmp;

always @(	LF_in_3 or
			LFwrite_3 or
			LF or
			LA or
			PC or
			LC or
			tmp
			)
	begin
		if ( LF && (LA == PC) && (LC == 16'h1) )	/* is this the end of the last iteration of a loop (DO inst)? */
			begin									/* executed while the last word in the loop is fetched */
				tmp = SSL[SP[3:0]];
				LF_in = tmp[15];					/* restore LF from SSL */
				LFwrite = `true;
			end

		else
			begin									/* change LF when a DO instruction starts, coming from stage 3 */
				LF_in = LF_in_3;
				LFwrite = LFwrite_3;
			end
	end



/*==============================================================================*/
/*																				*/
/*	Program Address Bus (PAB_out)												*/
/*																				*/
/*==============================================================================*/

/*---------------------------------------------------------------*/
/* select PAB write enable based on the PC and the REPEAT signal */
/*---------------------------------------------------------------*/

always @(	reset or
			PCwrite or
			REPEAT or
			REPEATset or
			REPEATreset
			)
	begin
		if (reset)
			PABwrite = `false;

		/* stop driving the bus when REP starts, using REPEATset signal, and until REP starts its last repetition, when REPEATreset goes high */
		else if ( (REPEAT || REPEATset) && (~REPEATreset) )
			PABwrite = `false;

		else
			PABwrite = PCwrite;
	end


/*------------------------------------*/
/* PAB register: latching the new PAB */
/*------------------------------------*/

always @(posedge Clk)
	begin
		if (reset)
			PAB_out <= 16'h0000;						/* initial program addressing is zero */
		else
			PAB_out <= (PABwrite) ? PC_in : 16'hzzzz;	/* if not required, high-Z the bus */
	end



/*==============================================================================================*/
/*																								*/
/*	Program Counter (PC)																		*/
/*																								*/
/*==============================================================================================*/

/*--------------------------------------------------*/
/* select the new value for the PC and write enable */
/*--------------------------------------------------*/

always @(	reset or
			LF or
			PC or
			LA or
			SP or
			PCwrite_2 or
			PCwrite_3 or
			PC_in_2 or
			PC_in_3 or
			REPEAT or
			REPEATset or
			REPEATreset
			)
			
	begin
		if (reset)
			PCwrite = `false;


		/* ---  DO  --- */
		
		else if (LF && (LA == PC) && (LC != 16'h1) )		/* at the END of a loop iteration (DO instruction) */
			begin											/* executed while the last word in the loop is fetched */
				PC_in = SSH[SP[3:0]];						/* PC gets the address of the first inst in the loop */
				PCwrite = `true;
			end


		/* ---  REP  --- */
		
		/* stop counting when REPEAT signal goes high, which at that time PC already contains the new PC for the instruction */
		/* after the repeated one. resume counting when the last repetition is starting in stage 2 and REPEATreset goes high. */

		else if ( (REPEAT) && (~REPEATreset))	/* while REP is in progress, don't advance the PC */
			PCwrite = `false;		


		/* ---  non DO or REP inst gets the following two cases...  --- */
		
		else if ( PCwrite_3 )								/* writing from stage 3 has priority over those from stage 2 */
			begin
				PC_in = PC_in_3;
				PCwrite = `true;
			end

		else if ( PCwrite_2 && (~PCwrite_3) )				/* write new PC from stage 2 */
			begin
				PC_in = PC_in_2;
				PCwrite = `true;
			end

		else
			PCwrite = `false;
	end


/*----------------------------------*/
/* PC register: latching the new PC */
/*----------------------------------*/

always @(posedge Clk)
	begin
		if (reset)
			PC <= 16'h0000;
		else
			PC <= (PCwrite) ? PC_in : PC;
	end




/*==============================================================================================*/
/*																								*/
/*	REPEAT signal																				*/
/*																								*/
/*==============================================================================================*/

/* should be a sync set/reset flip-flop */

always @(	posedge Clk or
			REPEAT_async_reset)
			
	begin
		if (REPEAT_async_reset)				/* async reset coming from stage 3 by REP inst of only one repetition */
			REPEAT <= `false;
			
		else if (reset || REPEATreset)		/* reset */
			REPEAT <= `false;
			
		else if (REPEATset)					/* set */
			REPEAT <= `true;

		else
			REPEAT <= REPEAT;				/* const */
	end




/*==============================================================================================*/
/*																								*/
/*	Loop Counter (LC) and TEMP register															*/
/*																								*/
/*==============================================================================================*/

/*-------------*/
/* LC register */
/*-------------*/

always @(posedge Clk)
	begin
		if (reset)
			LC <= 16'h0000;
		else
			LC <= (LCwrite) ? LC_in : LC;	/* latch new loop counter value */
	end


/*---------------*/
/* TEMP register */
/*---------------*/

always @(posedge Clk)
	begin
		if (reset)
			TEMP <= 16'h0000;
		else
			TEMP <= (TEMPwrite) ? TEMP_in : TEMP;	/* store previous loop counter while REP is in progress */
	end


/*---------------------------------------*/
/* loop counting and repeat-signal reset */
/*---------------------------------------*/

always @(	reset or
			REPEAT or
			LC or
			LC_in or
			LC_repeat or
			LC_do or
			LCwrite_repeat or
			LCwrite_do or
			TEMP or
			LF or
			LA or
			PC or
			SP
			)
	begin
		if (reset)
			begin
				LCwrite = `false;
				REPEATreset   = `false;
			end

		/* ************** */
		/*   REP   inst   */
		/* ************** */
			
		else if (REPEAT && LCwrite_repeat)		/* REP first cycle - load initial repetitions and decrease by one */
			begin
				if ( (LC_repeat - 1'b1) == 16'h1)		/* REP requested 2 repetitions only! */
					begin
						/* prepare for last repetition */
						REPEATreset = `true;			/* reset the repeat signal once repetition should cease */
						LCwrite     = `false;			/* LC need not change at all */
					end
				else
					begin
						/* allow to start repeating the same instruction */
						LC_in =  LC_repeat - 1'b1;		/* decrease the number of repetitions using the initial value */
						REPEATreset   = `false;			/* REP is still in effect */
						LCwrite = `true;				/* keep counting down */
					end
			end		/* REP 1st cycle */
			

		else if (REPEAT && (~LCwrite_repeat))	/* REP non-first cycle */
			begin
				if ( (LC - 1'b1) == 16'h1)				/* conclude REP execution? */
					begin
						/* prepare for last repetition */
						REPEATreset = `true;			/* reset the repeat signal when repetition should cease */
						LCwrite     = `true;			/* enable LC to be restored from TEMP register */
						LC_in		= TEMP;				/* restore LC from the TEMP register */
					end
				else
					begin
						/* continue repeating the same instruction */
						REPEATreset = `false;			/* REP is still in effect */
						LCwrite     = `true;			/* keep counting down */
						LC_in =  LC - 1'b1;				/* decrease the number of repetitions using the STORED LC */
					end
			end		/* REP non-1st cycle */
			

		/* ************* */
		/*   DO   inst   */
		/* ************* */

		else if ((~REPEAT) && LCwrite_do)		/* DO instruction first iteration */
														/* Effective while the first instruction in the loop is fetched for the fisrt time. */
			begin
				LC_in = LC_do;							/* number of repetitions for the DO loop - coming from stage 3 */
				LCwrite = `true;						/* enable write into LC */
			end


		else if ((~REPEAT) && LF && (LA == PC) && (LC != 16'h1) )
			begin								/* DO instruction is in progress - and is NOT the last iteration */
														/* executed while the last word in the loop is fetched */
														/* update LC at the end of each iteration */
				LC_in = LC - 1'b1;						/* count down the number of remaining iterations */
				LCwrite = `true;						/* continue count down */
			end

		else if ((~REPEAT) && LF && (LA == PC) && (LC == 16'h1) )
			begin								/* conclude DO execution - LAST iteration is about to be over */
														/* executed while the last word in the loop is fetched */
				LC_in = SSL[SP[3:0] - 1'h1];			/* Restore LC from SSL (one slot below where SP is currently pointing) */
				LCwrite = `true;						/* enable LC to get its previous value from SSL */
			end
		
		else
			begin
				REPEATreset = `false;
				LCwrite = `false;
			end

	end		/* LC */




/*==============================================================================================*/
/*																								*/
/*	Loop Address (LA)																			*/
/*																								*/
/*==============================================================================================*/

/* Latch new loop address which is always the second word in a DO instruction */
/* The Address given in the second word is of the instruction AFTER the last instruction inside the loop. */
/* That's why the last address is that address minus one. */

always @(	PDB or
			LF or
			LA or
			PC or
			LC or
			SP or
			LAwrite_2
			)
	begin
		if ( LF && (LA == PC) && (LC == 16'h1) )		/* is this the end of the LAST iteration of a loop (DO inst) */
			begin										/* executed while the last word in the loop is fetched */
				LA_in = SSH[SP[3:0] - 1'h1];			/* restore LA from SSH (one slot below where SP is currently pointing) */
				LAwrite = `true;
			end
		else
			begin
				LA_in = PDB[`addrbus] - 1'b1;			/* input to the LA register for a DO inst. */
				LAwrite = LAwrite_2;					/* write enable from stage 2 (DO inst) */
			end
	end


/*-------------*/
/* LA register */
/*-------------*/

always @(posedge Clk)
	begin
		LA <= (LAwrite) ? LA_in : LA;	/* latch new loop address */
	end



/*==============================================================================================*/
/*																								*/
/*	Stack Pointer (SP)																			*/
/*																								*/
/*==============================================================================================*/

/* select the new value for the stack pointer */

always @(	SP_in_2 or
			SP_in_3 or
			SPwrite_2 or
			SPwrite_3 or
			LF or
			LA or
			PC or
			LC or
			SP
			)
	begin
		if ( LF && (LA == PC) && (LC == 16'h1) )		/* is this the end of the last iteration of a loop (DO inst) */
			begin										/* executed while the last word in the loop is fetched */
				SP_in = SP[5:0] - 2'h2;					/* let SP point back to where it pointed before this loop began */
				SPwrite = `true;
			end

		else if ( SPwrite_2 && (~SPwrite_3) )			/* from stage 2 */
			begin
				SP_in = SP_in_2;
				SPwrite = SPwrite_2;
			end

		else if ( (~SPwrite_2) && SPwrite_3 )			/* from stage 3 */
			begin
				SP_in = SP_in_3;
				SPwrite = SPwrite_3;
			end

		else
			SPwrite = `false;
	end



/*-------------*/
/* SP register */
/*-------------*/

always @(posedge Clk)
	begin
		if (reset)
			SP <= 16'h0000;		/* zero on reset */
		else
			SP <= (SPwrite) ? SP_in : SP;	/* update the stack pointer */
	end



/*==============================================================================================*/
/*																								*/
/*	System Stack (SSL & SSH)																	*/
/*																								*/
/*==============================================================================================*/

/* System Stack input and write enable selectors */

/*---------------*/
/* SSL selectors */
/*---------------*/

always @(	SSL_in_2 or
			SSL_in_3 or
			SSLwrite_2 or
			SSLwrite_3
			)
	begin
		if ( SSLwrite_2 && (~SSLwrite_3) )			/* from stage 2 */
			begin
				SSL_in = SSL_in_2;
				SSLwrite = SSLwrite_2;
			end
		else if ( (~SSLwrite_2) && SSLwrite_3 )		/* from stage 3 */
			begin
				SSL_in = SSL_in_3;
				SSLwrite = SSLwrite_3;
			end
		else
			SSLwrite = `false;
	end		/* SSL */


/*---------------*/
/* SSH selectors */
/*---------------*/

always @(	SSH_in_2 or
			SSH_in_3 or
			SSHwrite_2 or
			SSHwrite_3
			)
	begin
		if ( SSHwrite_2 && (~SSHwrite_3) )			/* from stage 2 */
			begin
				SSH_in = SSH_in_2;
				SSHwrite = SSHwrite_2;
			end
		else if ( (~SSHwrite_2) && SSHwrite_3 )		/* from stage 3 */
			begin
				SSH_in = SSH_in_3;
				SSHwrite = SSHwrite_3;
			end
		else
			SSHwrite = `false;
	end		/* SSH */



/*-----------*/
/* SSL & SSH */
/*-----------*/

always @(posedge Clk)
	begin
		/* When writing into the stack, the address is SP_in which is the soon-to-be new SP. */
		/* This way, when the stack isn't empty, SP points to the last slot occupied in the Stack. */
		/* If the stack is empty SP is zero. */
		
		if (SSLwrite)
			SSL[SP_in] <= SSL_in;
			
		if (SSHwrite)
			SSH[SP_in] <= SSH_in;
	end



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
			pdb2 <= pdb2;				/* repeat the last word instruction */
			
		else
					/* Fetch the instruction from the PDB and into Decode stage */
					/* unless an absolute address or immediate data is used as a second instruction word. */
			pdb2 <= (absolute_immediate) ? `NOP : PDB;


		jump_address <= PDB[`addrbus];	/* is for JCLR/ JSET, used in stage 3 as the jump address (while pdb2 holds NOP). */
										/* This way, the jump address is stored until the jump condition is resolved (in stage 3). */
										/* Therefore, only in stage 3 it is known and the jump address is used to change the PC/PAB.*/
	end


/*--------------------------------------------------------------------------------------*/
/*																						*/
/* 		Logic Section																	*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

always @(	pdb2 or 
			reset or
			REPEAT or
			PC or
			LA or
			LC or
			SP or
			PDB
			)
	begin

		/*--------------------------*/
		/* initialize controls		*/
		/*--------------------------*/

		PCwrite_2 = `false;
				
		REPEATset = `false;

		absolute_immediate =`false;

		SSLwrite_2 = `false;

		SSHwrite_2 = `false;

		SPwrite_2 = `false;
		
		LAwrite_2 = `false;
		
		
		
		/*---------------------------------*/
		/* Decode the incoming instruction */
		/*---------------------------------*/
		
	
		if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*										*/
					/* Jump with an effective address		*/
					/*--------------------------------------*/
					
				/* The effective address is generated by the AGU */
				/* That's why for all cases but absolute address the PCU doesn't drive the PAB bus. */

				/* if an absolute address is in the second program word, nullify that word */
				
				if (pdb2[13:8] == 6'b110000)
					begin
						PC_in_2 = PDB[`addrbus];		/* the new program address is on the PDB */
						PCwrite_2 = `true;
						absolute_immediate = `true;		/* the absolute address is the second word */
					end
				
			end		/* JMP Class II */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/

				/* push LA and LC into the system stack */
				
				SSH_in_2 = LA;			/* save the current LA into SSH */
				SSHwrite_2 = `true;
				
				SSL_in_2 = LC;			/* save the current LC into SSL */
				SSLwrite_2 = `true;
				
				SP_in_2 = SP[5:0] + 1'h1;	/* adjust the stack pointer, only 6 LSBs are used */
				SPwrite_2 = `true;
				
				LAwrite_2 = `true;		/* latch the new address loop */


				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */
				
				absolute_immediate = `true;

				
				/* advance the PC */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;
				
			end		/* DO Class IV */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/

				/* number of repetitions in coming from the AGU, data ALU or the PCU itself */
				
				REPEATset = `true;	/* set the repeat signal */
				
				PC_in_2 = PC + 1;
				PCwrite_2 = `true;

			end		/* REP Class IV */




		else if ( {pdb2[23:15], pdb2[7], pdb2[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I or II			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				/* The effective address is generated by the AGU */

				REPEATset = `true;	/* set the repeat signal */

				PC_in_2 = PC + 1;
				PCwrite_2 = `true;
				
			end		/* REP Class I or II */




		else if ( {pdb2[23:16], pdb2[7:2]} == 14'b00000000_101110 )
			begin	/*--------------------------------------*/
					/*					ANDI				*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/

			end	/* ANDI */




		else if ( {pdb2[23:16], pdb2[7:4]} == 12'b00000110_1010 )
			begin	/*--------------------------------------*/
					/*			REP Class III				*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				/* Immediate data in the program instruction */

				REPEATset = `true;	/* set the repeat signal */

				PC_in_2 = PC + 1;
				PCwrite_2 = `true;
				
			end		/* REP Class III */




		else if ( pdb2[23:12] == 12'b0000_1100_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class I				*/
					/*										*/
					/* Jump with a short immediate address	*/
					/*--------------------------------------*/
				
				/* an absolute address is encoded in the program word */
				
				PC_in_2 = {4'h0, pdb2[11:0]};		/* zero extended */
				PCwrite_2 = `true;
				
			end		/* JMP Class I */
			



		else if ( {pdb2[23:16], pdb2[7:4]} == 12'b0000_0110_1000 )
			begin	/*--------------------------------------*/
					/*			DO Class III				*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/
				
				/* push LA and LC into the system stack */
				
				SSH_in_2 = LA;			/* save the current LA into SSH */
				SSHwrite_2 = `true;
				
				SSL_in_2 = LC;			/* save the current LC into SSL */
				SSLwrite_2 = `true;
				
				SP_in_2 = SP[5:0] + 1'h1;	/* adjust the stack pointer, only 6 LSBs are used */
				SPwrite_2 = `true;
				
				LAwrite_2 = `true;		/* latch the new address loop */

				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */
				
				absolute_immediate = `true;

				
				/* advance the PC */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;
				
			end		/* DO Class III */
			



		else if ( ({pdb2[23:14], pdb2[7]}   == 11'b00001010_01_1) ||
				  ({pdb2[23:14], pdb2[7]}   == 11'b00001010_00_1) ||
				  ({pdb2[23:14], pdb2[7:6]} == 12'b00001010_11_00) )
			begin	/*----------------------------------------------*/
					/*		JCLR / JSET Class I, II	or III			*/
					/*												*/
					/*	Jump if Bit Clear/Set - Class I, II or III	*/
					/*----------------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				
				absolute_immediate = `true;

				/* bring the next program word which is an absolute jump address */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;


			end		/* JCLR/JSET Class I, II or III */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_01_0) ||
			 	  ({pdb2[23:14], pdb2[7], pdb2[5]} == 12'b00001011_01_0_1) )
			 
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class I		*/
					/*										*/
					/*	Bit Test and Clear/Set - Class I	*/
					/*--------------------------------------*/

				/* check if an absolute address is used. */
				
				if (pdb2[13:8] == 6'b110000)
					absolute_immediate  = `true;
				
				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;

			end		/* BCLR/BSET/BTST Class I */




		else if ( {pdb2[23:16], pdb2[7:5]} == 11'b00000101_101 )
			begin	/*----------------------------------*/
					/*		MOVEC Class IV				*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;

			end		/* MOVEC  Class IV */




		else if ( {pdb2[23:16], pdb2[7], pdb2[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I or II			*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				/* check if an absolute address or immediate data is used. */

				if (pdb2[14])	/* Class I */
					if ( (pdb2[13:8] == 6'b110000) || (pdb2[13:8] == 6'b110100) )
						absolute_immediate  = `true;

				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;

			end		/* MOVEC Class I and II */




		else if ( {pdb2[23:20], pdb2[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/*----------------------------------*/

				/* if an absolute address is used in Class I */
				
				if (pdb2[14:8] == 7'b1_110000)
					absolute_immediate = `true;

				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;
				
			end		/* L: */




		else if ( pdb2[23:20] == 4'b0001 )
			begin	/*--------------------------------------------------------------*/
					/*				X:R Class I  or  R:Y Class I					*/
					/*																*/
					/* X Memory and Register Data Move		Class I					*/
					/* Register and Y Memory Data Move		Class I					*/
					/*																*/
					/*--------------------------------------------------------------*/

				if ({pdb2[15], pdb2[13:11]} == 4'b1_110)

					/* Active if an absolute address or immediate data are used	*/
					/* (a TWO word instruction format).							*/

					absolute_immediate = `true;


				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;

			end		/* X:R Class I  or  R:Y Class I */




		else if ( pdb2[23:22] == 2'b01 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:				*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/* Condition codes ARE affected		*/
					/*----------------------------------*/

				if (pdb2[15:11] == 5'b1_1_110)

					/* Active if an absolute address or immediate data are used */
					/* (a TWO word instruction format).							*/

					absolute_immediate = `true;


				/* bring the next program word */
				
				PC_in_2 = PC + 1'b1;
				PCwrite_2 = `true;

			end	/* X: or Y: */



		else
			begin	/*--------------------------------------*/
					/*				default					*/
					/*										*/
					/* increment the program address by one */
					/*--------------------------------------*/
					
				PC_in_2 = (REPEAT) ? PC : (PC + 1'b1);		/* while REP is in progress don't advance the PC */
				PCwrite_2 = `true;
			end

			
	end		/* @(pdb2) */





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
			pdb3 <= pdb2;
	end


/*--------------------------------------------------------------------------------------*/
/*																						*/
/* 		Logic Section																	*/
/*																						*/
/*--------------------------------------------------------------------------------------*/

always @(	pdb3 or 
			reset or 
			PAB_in or
			GDB or
			jump_address or 
			J or
			CCR or
			MR or
			PC or
			LC or
			LC_repeat or
			SP
			)
	begin

		/*---------------------*/
		/* initialize controls */
		/*---------------------*/

		PCwrite_3 = `false;
		
		LCwrite_repeat = `false;

		LCwrite_do = `false;
		
		REPEAT_async_reset = `false;		
		
		TEMPwrite = `false;

		SSLwrite_3 = `false;		
		SSHwrite_3 = `false;		

		SPwrite_3 = `false;

		/* initialize Mode Register bits, and their write enable */

		LFwrite_3 = `false;
		DMwrite = `false;
		S1write = `false;
		S0write = `false;
		I1write = `false;
		I0write = `false;

		OMRwrite = `false;



		/*---------------------------------*/
		/* Decode the incoming instruction */
		/*---------------------------------*/
		
		if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*										*/
					/* Jump with an effective address		*/
					/*--------------------------------------*/
					
				/* The effective address is generated by the AGU */
				/* Get the new address from the PAB_in and increment it by 1 in preparation for the next cycle */

				if (pdb3[13:8] != 6'b110000)
					begin
						PC_in_3 = PAB_in + 1;				/* generated by the AGU and increment it by one */
						PCwrite_3 = `true;					/* This update has priority over an update of an old PC in stage 2, */
															/* becuase stage 2 doesn't know of the new PAB generated by the AGU. */
					end
				
			end		/* JMP Class II */
			



		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/

				
				SSH_in_3 = PC;					/* load the PC of the first instruction in the loop in SSH */
				SSHwrite_3 = `true;
				
				SSL_in_3 = {MR, CCR};			/* load the current SR = {MR, CCR} in the SSL */
				SSLwrite_3 = `true;

				SP_in_3 = SP[5:0] + 1'h1;		/* adjust the stack pointer */
				SPwrite_3 = `true;
				
				LF_in_3 = `true;				/* set loop flag */
				LFwrite_3 = `true;
				

				/* choose the source that holds the number of repetitions */
				
				if ( (pdb3[13:11] == 3'b010) || (pdb3[13:11] == 3'b011) ||	(pdb3[13:11] == 3'b100) )
						/* the number of repetitions is coming via the GDB */
						/* --- notice: this version supports sources from the AGU only !!! --- */
					begin
						LC_do = GDB;			/* from GDB */
						LCwrite_do = `true;		/* enable the LC to get its new value */
					end		/* from GDB */
				
			end		/* DO Class IV */




		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/

				/* number of repetitions is coming on the GDB from either the AGU or the data ALU */
				
				if ( (pdb3[13:10] == 4'b0001) || (pdb3[13:11] == 3'b001) || (pdb3[13:11] == 3'b010) || (pdb3[13:11] == 3'b011) || (pdb3[13:11] == 3'b100) )
					begin
						LC_repeat = GDB;			/* 16 bit only */

						if (LC_repeat == 16'h1)		/* repeat once doesn't require the rise of the REPEAT signal */
							begin
								REPEAT_async_reset = `true;
							end
						else
							begin
								LCwrite_repeat = `true;		/* enable latching of the initial loop counter coming from memory on the GDB bus */
								TEMPwrite = `true;			/* enable storage of current LC into TEMP register */
								TEMP_in = LC;				/* current LC is to be stored in TEMP register */
							end
					end
					
			end		/* REP Class IV */




		else if ( {pdb3[23:15], pdb3[7], pdb3[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I	or II			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				LC_repeat = GDB;			/* 16 bit only */
				
				if (LC_repeat == 16'h1)		/* repeat once doesn't require the rise of the REPEAT signal */
					begin
						REPEAT_async_reset = `true;
					end
				else
					begin
						LCwrite_repeat = `true;		/* enable latching of the initial loop counter coming from memory on the GDB bus */
						TEMPwrite = `true;			/* enable storage of current LC into TEMP register */
						TEMP_in = LC;				/* current LC is to be stored in TEMP register */
					end

				
			end		/* REP Class I or II */




		else if ( {pdb3[23:16], pdb3[7:2]} == 14'b00000000_101110 )
			begin	/*--------------------------------------*/
					/*					ANDI				*/
					/*										*/
					/* And Immediate with Control Register	*/
					/*--------------------------------------*/

				case (pdb3[1:0])
					2'b00	:	/* MR */
								begin
									LF_in_3 = pdb3[15] && LF;
									LFwrite_3 = `true;
									DM_in = pdb3[14] && DM;
									DMwrite = `true;
									S1_in = pdb3[11] && S1;
									S1write = `true;
									S0_in = pdb3[10] && S0;
									S0write = `true;
									I1_in = pdb3[ 9] && I1;
									I1write = `true;
									I0_in = pdb3[ 8] && I0;
									I0write = `true;
								end

					2'b01	:	;	/* No Action - CCR are taken care of in the data alu */

					2'b10	:	/* OMR */
								begin
									OMR_in[7:0] = pdb3[15:8] & OMR[7:0];
									OMRwrite = `true;
								end

					default	:	;		/* No Action */

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
					/* In case the BTST is executed (pdb3[16]==1), no writes are allowed. */
				
				if ( pdb3[13:11] == 3'b111 )
					begin		/*-------------------*/
								/* Control registers */
								/*-------------------*/
					
						case (pdb3[10:8])
							3'b000	:	;		/* No Action */
							3'b001	:	begin	/* SR */
											case (pdb3[4:0])
												5'b00000,
												5'b00001,
												5'b00010,
												5'b00011,
												5'b00100,
												5'b00101,
												5'b00110,
												5'b00111	:	;	/* No Action - taken care of in the data alu */
												5'b01000	:	if (~(pdb3[16]))
																	begin
																		I0_in = pdb3[5];	/* I0 */
																		I0write = `true;
																	end
												5'b01001	:	if (~(pdb3[16]))
																	begin
																		I1_in = pdb3[5];	/* I1 */
																		I1write = `true;
																	end
												5'b01010	:	if (~(pdb3[16]))
																	begin
																		S0_in = pdb3[5];	/* S0 */
																		S0write = `true;
																	end
												5'b01011	:	if (~(pdb3[16]))
																	begin
																		S1_in = pdb3[5];	/* S1 */
																		S1write = `true;
																	end
												5'b01100	:	;	/* No Action */
												5'b01101	:	;	/* No Action */
												5'b01110	:	if (~(pdb3[16]))
																	begin
																		DM_in = pdb3[5];	/* DM */
																		DMwrite = `true;
																	end
												5'b01111	:	if (~(pdb3[16]))
																	begin
																		LF_in_3 = pdb3[5];	/* LF */
																		LFwrite_3 = `true;
																	end
												default		:	;	/* No Action */
											endcase
										end
							3'b010	:	begin	/* OMR */
//											{C_a3, OMR_in} = bit_test(OMR, pdb3[4:0], pdb3[5]);
//											OMRwrite = (pdb3[16]) ? `false : `true;
										end
							3'b011	:	begin	/* SP */
										end
							3'b100	:	begin	/* SSH */
										end
							3'b101	:	begin	/* SSL */
										end
							3'b110	:	begin	/* LA */
										end
							3'b111	:	begin	/* LC */
										end
						endcase		/* pdb3[13:11] */
					
					end		/* control registers */
				
			end		/* BCLR/BSET/BTST Class III */




		else if ( {pdb3[23:16], pdb3[7:4]} == 12'b00000110_1010 )
			begin	/*--------------------------------------*/
					/*			REP Class III				*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					
				/* Immediate data in the program instruction */

				LC_repeat = {4'b0000, pdb3[3:0], pdb3[15:8]};	/* pay attention to the special concatenation !!! */

				if (LC_repeat == 16'h1)		/* repeat once doesn't require the rise of the REPEAT signal */
					begin
						REPEAT_async_reset = `true;
					end
				else
					begin
						LCwrite_repeat = `true;		/* enable latching of the initial loop counter coming from memory on the GDB bus */

						TEMPwrite = `true;			/* enable storage of current LC into TEMP register */
						TEMP_in = LC;				/* current LC is to be stored in TEMP register */
					end
				
			end		/* REP Class III */




		else if ( {pdb3[23:16], pdb3[7:4]} == 12'b0000_0110_1000 )
			begin	/*--------------------------------------*/
					/*			DO Class III				*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/
				
				
				SSH_in_3 = PC;				/* load the PC of the first instruction in the loop in SSH */
				SSHwrite_3 = `true;
				
				SSL_in_3 = {MR, CCR};		/* load the current SR = {MR, CCR} in the SSL */
				SSLwrite_3 = `true;

				SP_in_3 = SP[5:0] + 1'h1;		/* adjust the stack pointer */
				SPwrite_3 = `true;
				
				LF_in_3 = `true;				/* set loop flag */
				LFwrite_3 = `true;
				
				
				/* an immediate short repetition number is encoded in the program word */

				LC_do = {4'b0000, pdb3[3:0], pdb3[15:8]};		/* immediate short data */
				LCwrite_do = `true;								/* enable the LC to get its new value */

			end		/* DO Class III */
			



		else if ( ({pdb3[23:14], pdb3[7]}   == 11'b00001010_01_1) ||
				  ({pdb3[23:14], pdb3[7]}   == 11'b00001010_00_1) ||
				  ({pdb3[23:14], pdb3[7:6]} == 12'b00001010_11_00) )
			begin	/*----------------------------------------------*/
					/*		JCLR / JSET Class I, II or III			*/
					/*												*/
					/*	Jump if Bit Clear/Set - Class I, II or III	*/
					/*----------------------------------------------*/

				if ( pdb3[13:11] == 3'b111 )
					begin		/*-------------------*/
								/* Control registers */
								/*-------------------*/
					
						case (pdb3[10:8])
							3'b000	:	;		/* No Action */
							3'b001	:	;		/* No Action */
							3'b010	:	begin	/* OMR */
//											{J, OMR_in} = bit_test(OMR, pdb3[4:0], pdb3[5]);
										end
							3'b011	:	begin	/* SP */
										end
							3'b100	:	begin	/* SSH */
										end
							3'b101	:	begin	/* SSL */
										end
							3'b110	:	begin	/* LA */
										end
							3'b111	:	begin	/* LC */
										end
						endcase		/* pdb3[13:11] */
					
					end		/* controller registers */


				if (pdb3[5])
					begin	/* JSET */
						PC_in_3 = jump_address;				/* the absolute address is coming from the program memory */
						PCwrite_3 = (J) ? `true : `false;	/* decide upon test result from either the AGU or the data alu */
					end
				else
					begin	/* JCLR */
						PC_in_3 = jump_address;				/* the absolute address is coming from the program memory */
						PCwrite_3 = (J) ? `false : `true;	/* decide upon test result from either the AGU or the data alu */
					end

			end		/* JCLR/JSET Class I, II or III */




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






	end		/* @(pdb3) */





endmodule	/* pcu */
