/*	File:	bus_switch.v	  												*/

/*	module name: bus_switch													*/

/*	Description: The internal DATA bus switch for the Motorola 56K core.	*/

/*	Author: Nitzan Weinberg */

/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	bus_switch															*/
/*																				*/
/********************************************************************************/

module bus_switch (
	reset,
	PDB,
	GDB,
	XDB,
	YDB,
	REPEAT,
	Clk
	);


/*==============================================================================*/
/*============	I/O direction	================================================*/
/*==============================================================================*/

input reset;
input [`databus] PDB;

inout [`databus] GDB;

inout [`databus] XDB;
inout [`databus] YDB;

input REPEAT;

input Clk;


/*==============================================================================*/
/*============		I/O type	================================================*/
/*==============================================================================*/

wire reset;
wire [`databus] PDB;
wire [`databus] GDB;		/* GDB bus	*/
wire [`databus] XDB;		/* XDB bus	*/
wire [`databus] YDB;		/* YDB bus	*/

wire REPEAT;				/* REP instruction signal coming from the PCU */

wire Clk;


/*==============================================================================*/
/*===========	Internal Nets	================================================*/
/*==============================================================================*/

reg [`databus] pdb2;			/* an instruction inside stage 2 (Decode)	*/
reg [`databus] pdb3;			/* an instruction inside stage 3 (Execute)	*/

reg [`databus] gdb_out;			/* data put on the GDB bus */
reg [`databus] gdb_out_2;		/* data towards GDB from stage 2 */
reg [`databus] gdb_out_3;		/* data towards GDB from stage 3 */
reg gdb_write;					/* write enable the GDB bus */
reg gdb_write_2;				/* write enable towards the GDB bus from stage 2 */
reg gdb_write_3;				/* write enable towards the GDB bus from stage 3 */

reg [`databus] xdb_out;			/* data put on the XDB bus */
reg [`databus] xdb_out_2;		/* data towards the XDB bus that come from stage 2 */
reg [`databus] xdb_out_3;		/* data towards the XDB bus that come from stage 3 */
reg xdb_write;					/* write enable the XDB bus */
reg xdb_write_2;				/* write enable towards the XDB bus from stage 2 */
reg xdb_write_3;				/* write enable towards the XDB bus from stage 3 */

reg [`databus] ydb_out;			/* data put on the YDB bus */
reg [`databus] ydb_out_2;		/* data towards the YDB bus that come from stage 2 */
reg [`databus] ydb_out_3;		/* data towards the YDB bus that come from stage 3 */
reg ydb_write;					/* write enable the YDB bus */
reg ydb_write_2;				/* write enable towards the YDB bus from stage 2 */
reg ydb_write_3;				/* write enable towards the YDB bus from stage 3 */
 

/*------------------------------------------------------------------------------------------------------*/
/* A flag  - when true signals that a source's absolute memory address or an immediate data is used.	*/
/* Such a use required TWO instruction words: The instruction and the absolute address/immediate data.	*/
/*------------------------------------------------------------------------------------------------------*/

reg immediate;		/* changed in stage 2 to reflect an immediate data in a TWO word instruction */

reg absolute;		/* signals an absolute address in a TWO word instruction, from stage 2 */


/*==============================================================================*/
/*																				*/
/*	Processes						Processes						Processes	*/
/*																				*/
/*==============================================================================*/


/*==============================================================================*/
/*																				*/
/*	GDB  XDB  YDB  buses														*/
/*																				*/
/*==============================================================================*/

/* assigning data to the GDB, XDB and YDB buses */

assign GDB = (gdb_write) ? gdb_out : 24'hzzzzzz;

assign XDB = (xdb_write) ? xdb_out : 24'hzzzzzz;

assign YDB = (ydb_write) ? ydb_out : 24'hzzzzzz;


/* choose the source that drives the data buses */

always @(	gdb_out_2 or
			gdb_out_3 or
			gdb_write_2 or
			gdb_write_3
			)
	begin
		if ( gdb_write_3 )		/* a write from stage 3 has priority over stage 2 */
			begin
				gdb_out = gdb_out_3;
				gdb_write = `true;
			end
		else if ( gdb_write_2 )
			begin
				gdb_out = gdb_out_2;
				gdb_write = `true;
			end
		else
			gdb_write = `false;	
	end		


always @(	xdb_out_2 or
			xdb_out_3 or
			xdb_write_2 or
			xdb_write_3
			)
	begin
		if ( xdb_write_3 )		/* a write from stage 3 has priority over stage 2 */
			begin
				xdb_out = xdb_out_3;
				xdb_write = `true;
			end
		else if ( xdb_write_2 )
			begin
				xdb_out = xdb_out_2;
				xdb_write = `true;
			end
		else
			xdb_write = `false;	
	end		


always @(	ydb_out_2 or
			ydb_out_3 or
			ydb_write_2 or
			ydb_write_3
			)
	begin
		if ( ydb_write_3 )		/* a write from stage 3 has priority over stage 2 */
			begin
				ydb_out = ydb_out_3;
				ydb_write = `true;
			end
		else if ( ydb_write_2 )
			begin
				ydb_out = ydb_out_2;
				ydb_write = `true;
			end
		else
			ydb_write = `false;	
	end		




/*==============================================================================*/
/*																				*/
/*	Stage 2 (Decode)					Stage 2							Stage 2	*/
/*																				*/
/*==============================================================================*/

always @(posedge Clk)
	begin
		if (reset)
			pdb2 <= `NOP;
		else if (REPEAT)
			pdb2 <= pdb2;	/* REP instruction is in effect */
		else
			pdb2 <= (absolute || immediate) ? `NOP : PDB;	/* Fetch the instruction from the PDB and into Decode stage */
	end


/*----------------------------------------------------------------------------------------------------------*/
/* Decode and carry out the parallel move specified by the move-fieled (pdb[23:8]) in every instruction.	*/
/*----------------------------------------------------------------------------------------------------------*/

always @(	pdb2 or
			PDB
			)
	begin

		/* initially the absolute/immediate mode is off */

		immediate = `false;
		absolute  = `false;
		
		
		/* initially don't allow writes to the GDB bus */
		
		gdb_write_2 = `false;
		
		
		/* initially don't allow writes to the XDB or YDB buses */
		
		xdb_write_2 = `false;
		ydb_write_2 = `false;
		

		/* initially the immediate mode is off */

		immediate = `false;


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
					/* Jump absolute address				*/
					/*--------------------------------------*/

				if (pdb2[13:8] == 6'b110000)
					absolute = `true;
					
			end		/* JMP Class II */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b0000_0110_11_0000_0000 )
			begin	/*--------------------------------------*/
					/*			DO Class IV					*/
					/*										*/
					/* Start Hardware Loop					*/
					/*--------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				/* This is the end-of-the-loop expression */

				absolute = `true;
				
				
			end		/* DO Class IV */




		else if ( {pdb2[23:14], pdb2[7:0]} == 18'b00000110_11_00100000 )
			begin	/*--------------------------------------*/
					/*				REP Class IV			*/
					/*										*/
					/* 	No Action							*/
					/*--------------------------------------*/
			end		/* REP Class IV */




		else if ( {pdb2[23:15], pdb2[7], pdb2[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I	or II			*/
					/*										*/
					/* No Action							*/
					/*--------------------------------------*/
			end		/* REP Class I or II */




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
					/* 	Start Hardware Loop					*/
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
				
				absolute = `true;

			end		/* JCLR/JSET Class III */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_01_0) ||
			      ({pdb2[23:14], pdb2[7], pdb2[5]} == 12'b00001011_01_0_1) )
			 
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class I		*/
					/*										*/
					/*	Bit Test and Clear / Set / Test		*/
					/*--------------------------------------*/

				/* check if an absolute address is used. If so nullify the next coming instruction. */
				
				if (pdb2[13:8] == 6'b110000)
					absolute  = `true;
				
			end		/* BCLR/BSET/BTST Class I */




		else if ( ({pdb2[23:14], pdb2[7]} == 11'b00001010_01_1) ||
				  ({pdb2[23:14], pdb2[7]} == 11'b00001010_00_1) )

			begin	/*------------------------------------------*/
					/*		JCLR / JSET Class I	or II			*/
					/*											*/
					/*	Jump if Bit Clear/Set - Class I or II	*/
					/*------------------------------------------*/

				/* An absolute address is ALWAYS supplied in the following program word. */
				
				absolute = `true;

			end		/* JCLR/JSET Class I or II */				




		else if ( pdb2[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U:					*/
					/*									*/
					/* No Action			 			*/
					/*----------------------------------*/
			end		/* U */



		else if ( {pdb2[23:16], pdb2[7], pdb2[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I or II			*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				if (pdb2[14])	/* Class I */
					begin
						if (pdb2[13:8] == 6'b110000)	/* absolute address */
							absolute = `true;


						if (pdb2[15])		/* a destination register is written */
							begin
								if (pdb2[4:3] == 2'b00)		/* M registers */
									begin
										if (pdb2[13:8] == 6'b110100)		/* immediate data */
											begin
												immediate = `true;

												gdb_out_2 = PDB;
												gdb_write_2 = `true;

											end		/* immediate data */
									end		/* M */
							end		/* destination */

					end		/* Class I */

			end		/* MOVEC Class I or II */



		else if ( {pdb2[23:17], pdb2[15:14]} == 9'b0000100_00 )
			begin	/*--------------------------------------------------------------*/
					/*						X:R Class II  							*/
					/*																*/
					/* No Action													*/
					/*--------------------------------------------------------------*/
			end		/* X:R Class II */
										



		else if ( {pdb2[23:17], pdb2[15:14]} == 9'b0000100_10 )
			begin	/*--------------------------------------------------------------*/
					/*						R:Y Class II  							*/
					/*																*/
					/* No Action													*/
					/*--------------------------------------------------------------*/
			end		/* R:Y Class II */




		else if ( pdb2[23:18] == 6'b001000 )
			begin	/*------------------------------------------*/
					/*				R:							*/
					/*											*/
					/* No Action								*/
					/*------------------------------------------*/
			end		/* R */




		else if ( {pdb2[23:20], pdb2[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/*	Long Data Memory Move			*/
					/*----------------------------------*/

				/* if an absolute address is used in Class I */
				
				if (pdb2[14:8] == 7'b1_110000)
						absolute = `true;
					
			end		/* L: */





		else if ( {pdb2[23:20], pdb2[14]} == 5'b0001_0 )
			begin	/*--------------------------------------------------------------*/
					/*						X:R Class I  							*/
					/*																*/
					/* X Memory and Register Data Move		Class I					*/
					/*																*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to get/put data from/towards the X data memory.		*/
					/*--------------------------------------------------------------*/

				if (pdb2[15])	/* a destination is getting data from X memory */
					begin
						if (pdb2[13:8] == 6'b110100)					/* immediate data */
							begin
								immediate = `true;

								case (pdb2[19:18])
									2'b11	:	begin
													ydb_out_2 = PDB;	/* B */
													ydb_write_2 = `true;
												end
									default	:	begin
													xdb_out_2 = PDB;	/* x0, x1 and A */
													xdb_write_2 = `true;
												end
								endcase
							end		/* immediate */

						else if (pdb2[13:8] == 6'b110000)				/* absolute address */
							absolute = `true;
					end

			end		/* X:R Class I */




		else if ( {pdb2[23:20], pdb2[14]} == 5'b0001_1 )
			begin	/*--------------------------------------------------------------*/
					/*						R:Y Class I  							*/
					/*																*/
					/* Register and Y Memory Data Move		Class I					*/
					/*																*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to get/put data from/towards the Y data memory.		*/
					/*--------------------------------------------------------------*/

				if (pdb2[15])	/* a destination is getting data from Y memory */
					begin
						if ( pdb2[13:8] == 6'b110100)			/* immediate data */
							begin
								immediate = `true;
								
								case (pdb2[17:16])
									2'b10	:	begin
													xdb_out_2 = PDB;		/* A */
													xdb_write_2 = `true;
												end
									default	:	begin
													ydb_out_2 = PDB;		/* y0, y1, B */
													ydb_write_2 = `true;
												end													
								endcase
							end		/* immediate */
						
						else if ( pdb2[13:8] == 6'b110000)		/* absolute address */
							absolute = `true;
					end

			end		/* R:Y Class I */




		else if ( pdb2[23:21] == 3'b001 )
			begin	/*----------------------------------*/
					/* 				I:					*/
					/*									*/
					/* No Action						*/
					/*----------------------------------*/
			end		/* I */
			



		else if ( {pdb2[23:22], pdb2[14]} == 3'b01_1 )
			begin	/*----------------------------------*/
					/* 			X:	or	Y:	Class I		*/
					/*									*/
					/* X or Y Memory Data Move			*/
					/*----------------------------------*/

				if (pdb2[15])		/* a destination register is written */
					begin
						if (pdb2[13:8] == 6'b110100)				/* immediate data */
							/*--------------------------------------*/
							/* Special instruction format:			*/
							/* Immediate Data: #xxxxxx, D	Type I	*/
							/*--------------------------------------*/
							begin
								if (pdb2[21])	/* the destination is an AGU register */
									begin
										gdb_out_2 = PDB;
										gdb_write_2 = `true;
									end
								else			/* the destination is a data alu register */
									case ({pdb2[21:20], pdb2[18:16]})
										`x0, `x1, `a2, `a1, `a0, `a	:	begin
																			xdb_out_2 = PDB;
																			xdb_write_2 = `true;
																		end
										`y0, `y1, `b2, `b1, `b0, `b	:	begin
																			ydb_out_2 = PDB;
																			ydb_write_2 = `true;
																		end
										default						:	;	/* no action */
									endcase

								immediate = `true;
							end		/* immediate */
							
						else if (pdb2[13:8] == 6'b110000)			/* absolute address */
							absolute = `true;
					end
					
			end		/* X: or Y: Class I */
			
			
			
	end	/* pdb2 */


		


/*==============================================================================*/
/*																				*/
/*	Stage 3 (Execute)															*/
/*																				*/
/*==============================================================================*/

always @(posedge Clk)
	begin
		if (reset)
			pdb3 <= `NOP;
		else
			pdb3 <= pdb2;
	end


/*----------------------------------------------------------------------------------------------------------*/
/* Decode and carry out the parallel move specified by the move-fieled (pdb[23:8]) in every instruction.	*/
/*----------------------------------------------------------------------------------------------------------*/

always @(	pdb3 or
			PDB or 
			GDB or 
			XDB or 
			YDB )

	begin

		
		
		/* initially don't allow writes to the GDB bus */
		
		gdb_write_3 = `false;
		
		
		/* initially don't allow writes to the XDB or YDB buses */
		
		xdb_write_3 = `false;
		ydb_write_3 = `false;
		
		
	
		
	
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



		else if ( {pdb3[23:14], pdb3[7:0]} == 18'b0000_1010_11_1000_0000 )
			begin	/*--------------------------------------*/
					/*				JMP Class II			*/
					/*	No Action							*/
					/*--------------------------------------*/
			end		/* JMP Class II */




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
					/* 	Repeat Next Instruction				*/
					/*--------------------------------------*/

				if ( pdb3[13:12] == 2'b00 )		/* from the data ALU - one of the internal registers */
					case (pdb3[12:8])	/* which is the source */
						`x0, `x1, `a0, `a1, `a2, `a	:	begin		/* data is on XDB bus */
															gdb_out_3 = XDB;
															gdb_write_3 = `true;
														end
						`y0, `y1, `b0, `b1, `b2, `b	:	begin		/* data is on YDB bus */
															gdb_out_3 = YDB;
															gdb_write_3 = `true;
														end
						default						:	;			/* no action */
					endcase

			end		/* REP Class IV */




		else if ( {pdb3[23:15], pdb3[7], pdb3[5:0]} == 16'b00000110_0_0_100000 )
			begin	/*--------------------------------------*/
					/*			REP Class I	or II			*/
					/*										*/
					/* Repeat Next Instruction				*/
					/*--------------------------------------*/
					

				if (pdb3[6])
					begin					/* the number of repetitions is coming from Y memory */
						gdb_out_3 = YDB;
						gdb_write_3 = `true;
					end
				else
					begin					/* the number of repetitions is coming from X memory */
						gdb_out_3 = XDB;
						gdb_write_3 = `true;
					end
				
			end		/* REP Class I or II */




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
					/*	No Action							*/
					/*--------------------------------------*/
			end		/* JCLR/JSET Class III */




		else if ( ({pdb3[23:14], pdb3[7]} == 11'b00001010_01_0) ||
			      ({pdb3[23:14], pdb3[7], pdb3[5]} == 12'b00001011_01_0_1) )
			 
			begin	/*--------------------------------------*/
					/*		BCLR / BSET / BTST Class I		*/
					/*										*/
					/*	No Action							*/
					/*--------------------------------------*/
			end		/* BCLR/BSET/BTST Class I */




		else if ( ({pdb3[23:14], pdb3[7]} == 11'b00001010_01_1) ||
				  ({pdb3[23:14], pdb3[7]} == 11'b00001010_00_1) )

			begin	/*------------------------------------------*/
					/*		JCLR / JSET Class I	or II			*/
					/*											*/
					/*	No Action								*/
					/*------------------------------------------*/
			end		/* JCLR/JSET Class I or II */				




		else if ( pdb3[23:13] == 11'b00100000_010 )
			begin	/*----------------------------------*/
					/*				U:					*/
					/*									*/
					/* No Action			 			*/
					/*----------------------------------*/
			end		/* U */



		else if ( {pdb3[23:16], pdb3[7], pdb3[5]} == 10'b00000101_0_1 )
			begin	/*----------------------------------*/
					/*		MOVEC Class I or II			*/
					/*									*/
					/* Move Control Register	 		*/
					/*----------------------------------*/

				if (pdb3[15])		/* a destination register is written */
					begin
						if (pdb3[4:3] == 2'b00)		/* M registers */
							begin
								if (pdb3[13:8] != 6'b110100)		/* NOT immediate data */
									begin
										gdb_out_3 = (pdb3[6]) ? YDB : XDB;
										gdb_write_3 = `true;
									end
							end		/* M */

						else
							begin	/* other registers */
							end

					end		/* destination */


				else				/* a source register is put on the data buses */
					begin
						if (pdb3[4:3] == 2'b00)
							begin	/* M register */
								if (pdb3[6])
									begin
										ydb_out_3 = GDB;
										ydb_write_3 = `true;
									end
								else
									begin
										xdb_out_3 = GDB;
										xdb_write_3 = `true;
									end
							end		/* M */
					end		/* source */

			end		/* MOVEC Class I or II */



		else if ( {pdb3[23:17], pdb3[15:14]} == 9'b0000100_00 )
			begin	/*--------------------------------------------------------------*/
					/*						X:R Class II  							*/
					/*																*/
					/* X Memory and Register Data Move		Class II				*/
					/*																*/
					/* Generates the effective address for a data write into X mem.	*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to put data towards the X data memory.					*/
					/*--------------------------------------------------------------*/

				/* data that come from the B register in the data alu appear on YDB. It is diverted to XDB. */
				
				if (pdb3[16])	/* B -> X:ea */
					begin
						xdb_out_3 = YDB;
						xdb_write_3 = `true;
					end

			end		/* X:R Class II */
										



		else if ( {pdb3[23:17], pdb3[15:14]} == 9'b0000100_10 )
			begin	/*--------------------------------------------------------------*/
					/*						R:Y Class II  							*/
					/*																*/
					/* Register and Y Memory Data Move		Class II				*/
					/*																*/
					/* Generates the effective address for a data write into Y mem.	*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to put data towards the Y data memory.					*/
					/*--------------------------------------------------------------*/

				/* data that come from the A register in the data alu appear on XDB. It is diverted to YDB. */

				if (~pdb3[16])	/* A -> Y:ea */
					begin
						ydb_out_3 = XDB;
						ydb_write_3 = `true;
					end

			end		/* R:Y Class II */




		else if ( pdb3[23:18] == 6'b001000 )
			begin	/*------------------------------------------*/
					/*				R:							*/
					/*											*/
					/* Register to Register Data Move			*/
					/*											*/
					/* Active whenever an AGU register is used.	*/
					/*------------------------------------------*/

				case ({pdb3[17], pdb3[12]})	/* {source, destination} */
					2'b00	:	begin
									/* Source: 		data alu register	*/
									/* Destination: data alu register	*/
									/* NO ACTION						*/
									/* (using ALU internal buses to		*/
									/* transfer source to destination.)	*/
								end
					2'b01	:	begin
									/* Source: 		data alu register	*/
									/* Destination: AGU register		*/
									case (pdb3[17:13])	/* which is the source */
										`x0, `x1, `a0, `a1, `a2, `a	:	begin		/* data is on XDB bus */
																			gdb_out_3 = XDB;
																			gdb_write_3 = `true;
																		end
										`y0, `y1, `b0, `b1, `b2, `b	:	begin		/* data is on YDB bus */
																			gdb_out_3 = YDB;
																			gdb_write_3 = `true;
																		end
										default						:	;			/* no action */
									endcase
								end
					2'b10	:	begin
									/* Source: 		AGU register		*/
									/* Destination: data alu register	*/
									case (pdb3[12:8])	/* which is the destination */
										`x0, `x1, `a0, `a1, `a2, `a	:	begin		/* data put on XDB bus */
																			xdb_out_3 = GDB;
																			xdb_write_3 = `true;
																		end
										`y0, `y1, `b0, `b1, `b2, `b	:	begin		/* data put on YDB bus */
																			ydb_out_3 = GDB;
																			ydb_write_3 = `true;
																		end
										default						:	;			/* no action */
									endcase
								end
					2'b11	:	begin
									/* Source: 		AGU register	*/
									/* Destination: AGU register	*/
									/* No Action */
								end
				endcase		/* {pdb3[17], pdb3[12]} */

			end		/* R */




		else if ( {pdb3[23:20], pdb3[18]} == 5'b0100_0 )
			begin	/*----------------------------------*/
					/* 				L:					*/
					/*	No Action						*/
					/*----------------------------------*/
			end		/* L: */




		else if ( {pdb3[23:20], pdb3[14]} == 5'b0001_0 )
			begin	/*--------------------------------------------------------------*/
					/*						X:R Class I  							*/
					/*																*/
					/* X Memory and Register Data Move		Class I					*/
					/*																*/
					/* Generates the effective address for a data read or write.	*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to get/put data from/towards the X data memory.		*/
					/*--------------------------------------------------------------*/

				if (pdb3[15])	/* a destination is getting data from X memory */
					begin
						if (pdb3[13:8] == 6'b110000)					/* absolute address */
							begin
								case (pdb3[19:18])
									2'b11	:	begin	/* B */
													ydb_out_3 = XDB;
													ydb_write_3 = `true;
												end
									default	:	;		/* no action for x0, x1 and A */
								endcase
							end		/* absolute */


						else	/* not absolute address or immediate data */
							case (pdb3[19:18])
								2'b11	:	begin	/* B */
												ydb_out_3 = XDB;
												ydb_write_3 = `true;
											end
								default	:	;	/* no action for x0, x1 and A */
							endcase
					end		/* pdb3[15]==1 */

				else			/* a source is coming out of the alu and into X memory */
					case (pdb3[19:18])
						2'b11	:	begin	/* B */
										xdb_out_3 = YDB;
										xdb_write_3 = `true;
									end
						default	:	;	/* no action for x0, x1 and A */
					endcase

			end		/* X:R Class I */




		else if ( {pdb3[23:20], pdb3[14]} == 5'b0001_1 )
			begin	/*--------------------------------------------------------------*/
					/*						R:Y Class I  							*/
					/*																*/
					/* Register and Y Memory Data Move		Class I					*/
					/*																*/
					/* Source and Destination registers are of the Data ALU ONLY.	*/
					/* Needs to get/put data from/towards the Y data memory.		*/
					/*--------------------------------------------------------------*/

				if (pdb3[15])	/* a destination is getting data from Y memory */
					begin
						if ( pdb3[13:8] == 6'b110000)			/* absolute address */
							begin
								case (pdb3[17:16])
									2'b10	:	begin	/* A */
													xdb_out_3 = YDB;
													xdb_write_3 = `true;
												end
									default	:	;		/* no action for y0, x1 and A */
								endcase
							end		/* absolute */


						else									/* not an immediate/absolute */
							case (pdb3[17:16])
								2'b10	:	begin	/* A */
												xdb_out_3 = YDB;
												xdb_write_3 = `true;
											end
								default	:	;	/* no action for y0, y1, b */
							endcase
					end		/* pdb3[15]==1 */

				else											/* a source is coming out of the alu and into Y memory */
					case (pdb3[17:16])
						2'b10	:	begin	/* A */
										ydb_out_3 = XDB;
										ydb_write_3 = `true;
									end
						default	:	;	/* no action for y0, y1, B */
					endcase

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
					/*----------------------------------*/

				if (pdb3[15:8] == 8'b11_110000)		/* absolute address, Class I */
					begin
						if (pdb3[21])	/* the destination for the incoming data is an AGU register */
							begin
								gdb_out_3 = (pdb3[19]) ? YDB : XDB;
								gdb_write_3 = `true;
							end

						else			/* the destination is a data alu register */
							case ({pdb3[21:20], pdb3[18:16]})
								`x0, `x1, `a2, `a1, `a0, `a	:	if (pdb3[19])	/* data arriving on YDB */
																	begin
																		xdb_out_3 = YDB;
																		xdb_write_3 = `true;
																	end
								`y0, `y1, `b2, `b1, `b0, `b	:	if (~pdb3[19])	/* data arriving on XDB */
																	begin
																		ydb_out_3 = XDB;
																		ydb_write_3 = `true;
																	end
								default						:	;	/* no action */
							endcase
					end		/* absolute */


				else

					/* for all the other addressing modes:				*/
					/* 4 cases: read/write from/to X or Y data memories */

					case ({pdb3[19], pdb3[15]})
						2'b00	:	/* read source register and write the X data memory */
									case ({pdb3[21:20], pdb3[18:16]})
										`x0, `x1, `a0, `a1, `a2, `a	:	;	/* no action */
										`y0, `y1, `b0, `b1, `b2, `b	:	begin
																			xdb_out_3 = YDB;
																			xdb_write_3 = `true;
																		end
										default						:	/* the source is an AGU register */
																		begin
																			xdb_out_3 = GDB;
																			xdb_write_3 = `true;
																		end
									endcase

						2'b01	:	/* read X data memory and write a destination register */
									case ({pdb3[21:20], pdb3[18:16]})
										`x0, `x1, `a0, `a1, `a2, `a	:	;	/* no action */
										`y0, `y1, `b0, `b1, `b2, `b	:	begin
																			ydb_out_3 = XDB;
																			ydb_write_3 = `true;
																		end
										default						:	/* the destination is an AGU register */
																		begin
																			gdb_out_3 = XDB;
																			gdb_write_3 = `true;
																		end
									endcase

						2'b10	:	/* read source register and write the Y data memory */
									case ({pdb3[21:20], pdb3[18:16]})
										`x0, `x1, `a0, `a1, `a2, `a	:	begin
																			ydb_out_3 = XDB;
																			ydb_write_3 = `true;
																		end
										`y0, `y1, `b0, `b1, `b2, `b	:	;	/* no action */
										default						:	/* the source is an AGU register */
																		begin
																			ydb_out_3 = GDB;
																			ydb_write_3 = `true;
																		end
									endcase

						2'b11	:	/* read Y data memory and write a destination register */
									case ({pdb3[21:20], pdb3[18:16]})
										`x0, `x1, `a0, `a1, `a2, `a	:	begin
																			xdb_out_3 = YDB;
																			xdb_write_3 = `true;
																		end
										`y0, `y1, `b0, `b1, `b2, `b	:	;	/* no action */
										default						:	/* the destination is an AGU register */
																		begin
																			gdb_out_3 = YDB;
																			gdb_write_3 = `true;
																		end
									endcase
					endcase		/* {pdb3[19], pdb3[15]} */

			end		/* X: or Y: */




		else if ( pdb3[23] )
			begin	/*----------------------*/
					/* 			X:Y:		*/
					/*						*/
					/* XY Memory Data Move	*/
					/*----------------------*/

				if (pdb3[15])	/* a destination is getting data from   X   memory */
					case (pdb3[19:18])
						2'b00,
						2'b01,
						2'b10	:	;	/* no action for x0, x1 and A */
						2'b11	:	/* b */
									begin
										ydb_out_3 = XDB;
										ydb_write_3 = `true;
									end
					endcase
				else			/* a source is coming out of the alu and into   X   memory */
					case (pdb3[19:18])
						2'b00,
						2'b01,
						2'b10	:	;	/* no action for x0, x1 and A */
						2'b11	:	/* b */
									begin
										xdb_out_3 = YDB;
										xdb_write_3 = `true;
									end
					endcase


				if (pdb3[22])	/* a destination is getting data from   Y   memory */
					case (pdb3[17:16])
						2'b10	:	/* A */
									begin
										xdb_out_3 = YDB;
										xdb_write_3 = `true;
									end
						default	:	;	/* no action for y0, y1, B */
					endcase
				else			/* a source is coming out of the alu and into   Y   memory */
					case (pdb3[17:16])
						2'b10	:	/* A */
									begin
										ydb_out_3 = XDB;
										ydb_write_3 = `true;
									end
						2'b11	:	;	/* no action for y0, y1, B */
					endcase

			end		/* X:Y: */




		else	/* if no operation is required */
			begin
			end
										
	

	end		/* @(pdb3) */





endmodule	/* bus_switch */
