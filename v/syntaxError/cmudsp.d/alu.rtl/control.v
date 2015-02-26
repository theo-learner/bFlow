/*	File:	control.v	  						*/

/*	module name: control						*/

/*	Description: 		 						*/

/*		Control logic for data path				*/

/*		all signals latched			*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module control (
	Clk, reset,
	pdb,
	immediate,	
	mult_x_ctl,
	mult_y_ctl,
	shift1_in_ctl,
	add_in1_ctl,
	add_in2_ctl,
	add_nadd_sub,
	a_ena,
	b_ena ,
	round_ctl,
	shift1_left,
	shift1_right,
	logic_in1_ctl,
	logic_in2_ctl,
	logic_c,
	ccr_affected
	);


/*============	I/O direction	================================================*/

input	Clk, reset;
input [`databus] 	pdb;	/* instruction word */
input	immediate;		/* flag for immediate data on pdb */	

/*------------ Control -------------*/
/*- These are control inputs to data path modules -*/
output 		add_nadd_sub;  
output 		shift1_left, shift1_right;
output [2:0]	logic_c;
output		a_ena, b_ena;

/*----------------------------------------------*/
/* Data Path control signals */
/* these are the wires that tell the modules what they should be hooked up to */
/*----------------------------------------------*/
output [2:0] 	mult_x_ctl, mult_y_ctl;
output 		shift1_in_ctl;		/* A or B */
output 		add_in1_ctl;		/* shift1 or 0 */
output [3:0] 	add_in2_ctl;
output 		round_ctl;   		/* 1 if round, 0 if not */
output [2:0] 	logic_in1_ctl, logic_in2_ctl;

/*-------------------- CCR control ------------*/
output		ccr_affected;

/*==============================================================================*/


/*============		I/O type	================================================*/


reg 		add_nadd_sub;  
reg 		shift1_left, shift1_right;
reg	[2:0]	logic_c;
reg			a_ena, b_ena;

/*----------------------------------------------*/
/* Data Path control signals */
/* these are the wires that tell the modules what they should be hooked up to */
/*----------------------------------------------*/
reg [2:0] mult_x_ctl, mult_y_ctl;
reg shift1_in_ctl;		/* A or B */
reg add_in1_ctl;		/* shift1 or 0 */
reg [3:0] add_in2_ctl;
reg round_ctl;   		/* 1 if round, 0 if not */
reg [2:0] logic_in1_ctl, logic_in2_ctl;

/*-------------------- CCR control ------------*/
reg		ccr_affected;

/*=============================	Internal Signals	=================================*/

reg 		add_nadd_sub_d;  
reg 		shift1_left_d, shift1_right_d;
reg	[2:0]	logic_c_d;
reg			a_ena_d, b_ena_d;

/*----------------------------------------------*/
/* Data Path control signals */
/* these are the wires that tell the modules what they should be hooked up to */
/*----------------------------------------------*/
reg [2:0] mult_x_ctl_d, mult_y_ctl_d;
reg shift1_in_ctl_d;		/* A or B */
reg add_in1_ctl_d;		/* shift1 or 0 */
reg [3:0] add_in2_ctl_d;
reg round_ctl_d;   		/* 1 if round, 0 if not */
reg [2:0] logic_in1_ctl_d, logic_in2_ctl_d;
reg legal_inst_probe;	/* lets us see result of legal_inst function */

/*-------------------- CCR control ------------*/
reg		ccr_affected_d;


/*==============================================================================*/

/*===========	Function Declarations	========================================*/


/*--------------------------------------------------------------------------------------*/
/*																						*/
/*	function:	legal_inst																*/
/*																						*/
/*	Checks if instruction can be an alu instruction											*/
/*	Tries to check data move field for all possible instructions that are compatible with */
/*	alu operations.  "(masking possible)" means that some "illegal" operations of that    */
/*	type are possible, e.g. R type MOVE with ddddd = 00000 is not specxified.           */
/*																						*/
/*--------------------------------------------------------------------------------------*/

function legal_inst;

input [23:0] pdb;

begin
	casex (pdb[23:8])
		16'b0010000000000000,	/* No parallel data move */
		16'b001001xxxxxxxxxx, 16'b00101xxxxxxxxxxx, 16'b0011xxxxxxxxxxxx,	/* I */
		16'b001000xxxxxxxxxx,	/* R (masking possible) */
		16'b00100000010xxxxx,	/* U */
		16'b0100x1xxxxxxxxxx, 16'b0101xxxxxxxxxxxx, 16'b011xxxxxxxxxxxx,	/* X:,Y: */
		16'b0001xxxxxxxxxxxx,	/* X:R , R:Y*/
		16'b0000100xx0xxxxxx,	/* X:R, R:Y (masking possible) */
		16'b0100x0xxxxxxxxxx,	/* L: (shared with X:, Y: */
		16'b1xxxxxxxxxxxxxxx:	/* X: Y: */
			legal_inst = 1;
		16'b00000001000xxxxx:	/* MAC, MACR, MPY, MPYR format 2 */
		begin
			if (pdb[7:6] == 2'b11)
				legal_inst = 1;
			else
				legal_inst = 0;
		end
		default:	legal_inst = 0;
	endcase
end

endfunction

/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

/*===========	Data path cotrol logic	====================================*/

always @(pdb or immediate)
begin
	/* Set default values */
	mult_x_ctl_d = `m_0;
	mult_y_ctl_d = `m_0;
	shift1_in_ctl_d = 0;
	add_in1_ctl_d = 0;
	add_in2_ctl_d = `a_0;
	add_nadd_sub_d = 0;
	a_ena_d = `false;
	b_ena_d = `false;
	round_ctl_d = 0;
	shift1_left_d = 0;
	shift1_right_d = 0;
	logic_in1_ctl_d = `l_0;
	logic_in2_ctl_d = `l_0;
	logic_c_d = 3'b011;
	ccr_affected_d = 0;

	/* probe */
	legal_inst_probe = legal_inst(pdb);

	/* Chek high bits to make sure it is a move */
	if (legal_inst(pdb) && !immediate) begin
	$display($time, " Legal Instruction.");
	casex (pdb[7:0])	
	/*--------------------------------------*/
	/*					CLR					*/
	/*										*/
	/* Add:	0 -> D							*/
	/*--------------------------------------*/
	/*if ( {pdb[7], pdb[1:0]} == 3'b0_00 )*/
	8'b0001x011 : begin
		$display($time, " CLR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 0;
		if (pdb[3])
		begin
			/* B */
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			a_ena_d = `true;	b_ena_d = `false; 
		end
	end /* CLR */	
	/*--------------------------------------*/
	/*				ADD, SUB				*/
	/*										*/
	/* Add:	D + S -> D						*/
	/* Add:	D - S -> D						*/
	/*--------------------------------------*/
	/*if ( {pdb[7], pdb[1:0]} == 3'b0_00 )*/
	8'b0xxxxx00 : begin
	if (pdb[6:4] != 3'b000) begin	
		$display($time, " ADD, SUB activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		case (pdb[6:4])	/* source */
			3'b001	:	if (pdb[3])
							add_in2_ctl_d = `a_a;
						else 
							add_in2_ctl_d = `a_b;
			3'b010	:	/* Source: X  */
							add_in2_ctl_d = `a_x;
			3'b011	:	/* Source: Y  */
							add_in2_ctl_d = `a_y;
			3'b100	:	/* Source: x0 */
							add_in2_ctl_d = `a_x0;
			3'b101	:	/* Source: y0 */
							add_in2_ctl_d = `a_y0;
			3'b110	:	/* Source: x1 */
							add_in2_ctl_d = `a_x1;
			3'b111	:	/* Source: y1 */
							add_in2_ctl_d = `a_y1;
			default	:	;																			/* No Action  */
		endcase	/* pdb[6:4] */
		/* add or subtract */
		add_nadd_sub_d = pdb[2];
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* do not round result */
		round_ctl_d = 0;
	end /* if */
	end /* ADD, SUB */
	/*--------------------------------------*/
	/*		ADDL, ADDR, SUBL, SUBR				*/
	/*										*/
	/* AddR:	D/2 + S -> D						*/
	/* AddL:	D/2 + S -> D						*/
	/* SubR:	D*2 - S -> D						*/
	/* SubL:	D*2 - S -> D						*/
	/*--------------------------------------*/
	/*else if ( {pdb[7:5], pdb[1:0]} == 5'b000_10 ) */
	8'b000xxx10 : begin	
		$display($time, " ADDL, ADDR, SUBL, SUBR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* add or subtract */
		add_nadd_sub_d = pdb[2];
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			add_in2_ctl_d = `a_a;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			add_in2_ctl_d = `a_b;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* shift left or right */
		if (pdb[4])
			shift1_left_d = 1;
		else
			shift1_right_d = 1;
		/* do not round result */
		round_ctl_d = 0;
	end /* ADDL, ADDR, SUBL, SUBR */
	/*--------------------------------------*/
	/*		ASL, ASR				*/
	/*										*/
	/* ASR:	D/2 -> D						*/
	/* ASL:	D*2 -> D						*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:5], pdb[2:0]} == 6'b001_010 ) */
	8'b001xx010 : begin	
		$display($time, " ASL, ASR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* set adder_in2 to 0, same as default */
		add_in2_ctl_d = `a_0;
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* shift left or right */
		if (pdb[4])
			shift1_left_d = 1;
		else
			shift1_right_d = 1;
		/* do not round result */
		round_ctl_d = 0;
	end /* ASL, ASR */
	/*--------------------------------------*/
	/*			AND, OR, EOR				*/
	/*										*/
	/*		( only D[47:24] )				*/
	/* AND:	D & S -> D						*/
	/* OR:	D ^ S -> D						*/
	/* EOR:	D | S -> D						*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:6], pdb[1]} == 6'b01_1 ) */
	8'b01xxxx1x : begin	
	if (pdb[2:0] != 3'b111) begin	/* make sure it's not CMPM */
		$display($time, " AND, OR, EOR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* set adder_in1 to 0, same as default */
		add_in1_ctl_d = 0;
		/* logic unit input/output: logic_in2 */
		case (pdb[5:4])
			2'b00 : logic_in2_ctl_d = `l_x0;
			
			2'b10 : logic_in2_ctl_d = `l_x1;
			
			2'b01 : logic_in2_ctl_d = `l_y0;
			
			2'b11 : logic_in2_ctl_d = `l_y1;
		endcase
			
		/* logic unit input/output: logic_in1 and register to store result */
		add_in1_ctl_d = 0;
		if (pdb[3])
		begin
			/* B */
			logic_in1_ctl_d = `l_b;
			add_in2_ctl_d = `a_lb;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			logic_in1_ctl_d = `l_a;
			add_in2_ctl_d = `a_la;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* operation, leading zero for this operation group */
		logic_c_d = {1'b0, pdb[2], pdb[0]};
		/* do not round result */
		round_ctl_d = 0;
	end
	end /* AND, OR, EOR */
	/*--------------------------------------*/
	/*					NOT					*/
	/*										*/
	/*		( only D[47:24] )				*/
	/* NOT:	~D  -> D						*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:6], pdb[1]} == 6'b01_1 ) */
	8'b0001x111 : begin	
		$display($time, " NOT activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* set adder_in1 to 0, same as default */
		add_in1_ctl_d = 0;
		/* logic unit input/output: logic_in2 not used */
		logic_in2_ctl_d = `l_0;
			
		/* logic unit input/output: logic_in1 and register to store result */
		add_in1_ctl_d = 0;
		if (pdb[3])
		begin
			/* B */
			logic_in1_ctl_d = `l_b;
			add_in2_ctl_d = `a_lb;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			logic_in1_ctl_d = `l_a;
			add_in2_ctl_d = `a_la;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* operation, leading zero for this operation group */
		logic_c_d = {1'b0, pdb[2], pdb[0]};
		/* do not round result */
		round_ctl_d = 0;
	end /* AND, OR, EOR */
	/*--------------------------------------*/
	/*		LSL, LSR, ROL, ROR				*/
	/*										*/
	/*		( only D[47:24] )				*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:5], pdb[1:0]} == 6'b001_11 ) */
	8'b001xxx11 : begin	
		$display($time, " LSL, LSR, ROL, ROR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* set adder_in1 to 0, same as default */
		add_in1_ctl_d = 0;
		/* logic unit input/output: logic_in2 */
		logic_in2_ctl_d = `l_0;
		/* logic unit input/output: logic_in1 and register to store result */
		add_in1_ctl_d = 0;
		if (pdb[3])
		begin
			/* B */
			logic_in1_ctl_d = `l_b;
			add_in2_ctl_d = `a_lb;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			logic_in1_ctl_d = `l_a;
			add_in2_ctl_d = `a_la;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* operation, leading one for this operation group */
		logic_c_d = {1'b1, pdb[2], pdb[0]};
		/* do not round result */
		round_ctl_d = 0;
	end /* LSL, LSR, ROL, ROR */
	/*--------------------------------------*/
	/*					MAC					*/
	/*										*/
	/* Signed Multiply-Accumulate			*/
	/*--------------------------------------*/
	/* else if ( {pdb[7], pdb[1:0]} == 3'b1_10 ) */
	8'b1xxxxx10 : begin	
		$display($time, " MAC activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* multiplier inputs: mult_x and mult_y */
		/*--------------------------------------*/
		/*										*/
		/* 				MAC Format 1			*/
		/*										*/
		/*--------------------------------------*/
		if ( pdb[23:13] != 11'b00000001_000 )
			/* we could just do mult_y_ctl = pdb[5:4]... */
			case (pdb[6:4])
				3'b000 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_x0;
						  end
				3'b001 : begin
							mult_x_ctl_d = `m_y0;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b010 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b011 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b100 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_y1;
						  end
		
				3'b101 : begin
							mult_x_ctl_d = `m_y0; 
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b110 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b111 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_x1;
						  end
			endcase		/* 	pdb[6:4] */
		/*--------------------------------------*/
		/*										*/
		/* 				MAC Format 2			*/
		/*										*/
		/*--------------------------------------*/
		else begin
			mult_x_ctl_d = `m_p;
			case (pdb[6:4])
		
				3'b100 : mult_y_ctl_d = `m_y1;
		
				3'b101 : mult_y_ctl_d = `m_x0;
		
				3'b110 : mult_y_ctl_d = `m_y0;
		
				3'b111 : mult_y_ctl_d = `m_x1;
				
				default: /* ILLEGAL: pdb[6] should always be 1 */
						 /* note that mult_y decode same as format 1 */
						 mult_y_ctl_d = `m_0;
						 
			endcase		/* 	pdb[6:4] */
		end /* else */
		/*--------------------------------------*/
		/*										*/
		/* 				Both formats			*/
		/*										*/
		/*--------------------------------------*/
		/* MULT_result goes to ADD_in2 */
		add_in2_ctl_d = `a_m;
		/* add or subtract */
		add_nadd_sub_d = pdb[2];
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* do not round result */
		round_ctl_d = 0;
	end /* MAC  */
	/*--------------------------------------*/
	/*					MACR					*/
	/*										*/
	/* Signed Multiply-Accumulate round		*/
	/*--------------------------------------*/
	/* if ( {pdb[7], pdb[1:0]} == 3'b1_11 )*/
	8'b1xxxxx11 : begin	
		$display($time, " MACR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* multiplier inputs: mult_x and mult_y */
		/*--------------------------------------*/
		/*										*/
		/* 				MACR Format 1			*/
		/*										*/
		/*--------------------------------------*/
		if ( pdb[23:13] != 11'b00000001_000 )
			/* we could just do mult_y_ctl = pdb[5:4]... */
			case (pdb[6:4])
				3'b000 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_x0;
						  end
				3'b001 : begin
							mult_x_ctl_d = `m_y0;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b010 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b011 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b100 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_y1;
						  end
		
				3'b101 : begin
							mult_x_ctl_d = `m_y0; 
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b110 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b111 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_x1;
						  end
			endcase		/* 	pdb[6:4] */
		/*--------------------------------------*/
		/*										*/
		/* 				MACR Format 2			*/
		/*										*/
		/*--------------------------------------*/
		else begin
			mult_x_ctl_d = `m_p;
			case (pdb[6:4])
		
				3'b100 : mult_y_ctl_d = `m_y1;
		
				3'b101 : mult_y_ctl_d = `m_x0;
		
				3'b110 : mult_y_ctl_d = `m_y0;
		
				3'b111 : mult_y_ctl_d = `m_x1;
				
				default: /* ILLEGAL: pdb[6] should always be 1 */
						 /* note that mult_y decode same as format 1 */
						 mult_y_ctl_d = `m_0;
						 
			endcase		/* 	pdb[6:4] */
		end /* else */
		/*--------------------------------------*/
		/*										*/
		/* 				Both formats			*/
		/*										*/
		/*--------------------------------------*/
		/* MULT_result goes to ADD_in2 */
		add_in2_ctl_d = `a_m;
		/* add or subtract */
		add_nadd_sub_d = pdb[2];
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* round result */
		round_ctl_d = 1;
	end /* MACR  */
	/*--------------------------------------*/
	/*			MPY, MPYR					*/
	/*										*/
	/* Signed Multiply ( round )			*/
	/*--------------------------------------*/
	/* if ( {pdb[7], pdb[1]} == 3'b1_0 ) */
	8'b1xxxxx0x : begin
		$display($time, " MPY, MPYR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* multiplier inputs: mult_x and mult_y */
		/*--------------------------------------*/
		/*										*/
		/* 				 Format 1				*/
		/*										*/
		/*--------------------------------------*/
		if ( pdb[23:13] != 11'b00000001_000 )
			case (pdb[6:4])
				3'b000 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_x0;
						  end
				3'b001 : begin
							mult_x_ctl_d = `m_y0;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b010 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b011 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b100 : begin
							mult_x_ctl_d = `m_x0;
							mult_y_ctl_d = `m_y1;
						  end
		
				3'b101 : begin
							mult_x_ctl_d = `m_y0; 
							mult_y_ctl_d = `m_x0;
						  end
		
				3'b110 : begin
							mult_x_ctl_d = `m_x1;
							mult_y_ctl_d = `m_y0;
						  end
		
				3'b111 : begin
							mult_x_ctl_d = `m_y1;
							mult_y_ctl_d = `m_x1;
						  end
			endcase		/* 	pdb[6:4] */
		/*--------------------------------------*/
		/*										*/
		/* 				Format 2				*/
		/*										*/
		/*--------------------------------------*/
		else begin
			mult_x_ctl_d = `m_p;
			/* we could just do mult_y_ctl_d = pdb[5:4]... */
			case (pdb[6:4])
		
				3'b100 : mult_y_ctl_d = `m_y1;
		
				3'b101 : mult_y_ctl_d = `m_x0;
		
				3'b110 : mult_y_ctl_d = `m_y0;
		
				3'b111 : mult_y_ctl_d = `m_x1;
				
				default: /* ILLEGAL: pdb[6] should always be 1 */
						 /* note that mult_y decode same as format 1 */
						 mult_y_ctl= `m_0;
						 
			endcase		/* 	pdb[6:4] */
		end /* else */
		/*--------------------------------------*/
		/*										*/
		/* 				Both formats			*/
		/*										*/
		/*--------------------------------------*/
		/* MULT_result goes to ADD_in2 */
		add_in2_ctl_d = `a_m;
		/* add or subtract (from zero)*/
		add_nadd_sub_d = pdb[2];
		add_in1_ctl_d = 0;
		/* acumulator input/output: add_in1 and register to store result */
		if (pdb[3])
		begin
			/* B */
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* round result */
		round_ctl_d = pdb[0];
	end /* MACR  */
	/*--------------------------------------*/
	/*					RND					*/
	/*										*/
	/* Round Accumulator					*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:4], pdb[2:0]} == 7'b0001_001 ) */
	8'b0001x001 : begin	
		$display($time, " RND activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		/* Flow through adder */
		add_in2_ctl_d = `a_0;
		/* acumulator input/output: add_in1 and register to store result */
		add_in1_ctl_d = 1;
		if (pdb[3])
		begin
			/* B */
			shift1_in_ctl_d = 1;
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			shift1_in_ctl_d = 0;
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* round result */
		round_ctl_d = 1;
	end /* RND */
	/*--------------------------------------*/
	/*					TFR					*/
	/*										*/
	/* Transfer data						*/
	/*--------------------------------------*/
	/* else if ( {pdb[7:4], pdb[2:0]} == 7'b0001_001 ) */
	8'b0000x001 : begin	
	if (!((pdb[6:4] == 3'b001) || (pdb[6:5] == 2'b01))) begin	/* no aliasing */
		$display($time, " TFR activated.  PDB = %h", pdb);
		ccr_affected_d = 1;
		case (pdb[6:4])	/* source */
			3'b001	:	if (pdb[3])
							add_in2_ctl_d = `a_a;
						else 
							add_in2_ctl_d = `a_b;
			3'b010	:	/* Source: X  */
							add_in2_ctl_d = `a_x;
			3'b011	:	/* Source: Y  */
							add_in2_ctl_d = `a_y;
			3'b100	:	/* Source: x0 */
							add_in2_ctl_d = `a_x0;
			3'b101	:	/* Source: y0 */
							add_in2_ctl_d = `a_y0;
			3'b110	:	/* Source: x1 */
							add_in2_ctl_d = `a_x1;
			3'b111	:	/* Source: y1 */
							add_in2_ctl_d = `a_y1;
			default	:	;																			/* No Action  */
		endcase	/* pdb[6:4] */
		/* flow through adder */
		add_nadd_sub_d = 0;
		add_in1_ctl_d = 0;
		/* acumulator output: register to store result */
		if (pdb[3])
		begin
			/* B */
			a_ena_d = `false;	b_ena_d = `true;  
		end
		else begin
			/* A */
			a_ena_d = `true;	b_ena_d = `false; 
		end 
		/* do not round result */
		round_ctl_d = 0;
	end /* if */
	end /* TFR */
	/******************************/
	/* Instructions not supported */
	/******************************/
	default : 	/* Use default values */;
	endcase
	end	/* if (legal_inst(pdb)) */
end /* always */



always @(posedge Clk or posedge reset)
begin
	if (reset)
	begin
		/* Set default values */
		mult_x_ctl = `m_0;
		mult_y_ctl = `m_0;
		shift1_in_ctl = 0;
		add_in1_ctl = 0;
		add_in2_ctl = `a_0;
		add_nadd_sub = 0;
		a_ena = `false;
		b_ena = `false;
		round_ctl = 0;
		shift1_left = 0;
		shift1_right = 0;
		logic_in1_ctl = `l_0;
		logic_in2_ctl = `l_0;
		logic_c = 3'b011;
		ccr_affected = 1'b0;
	end
	else begin
		mult_x_ctl = mult_x_ctl_d;
		mult_y_ctl = mult_y_ctl_d;
		shift1_in_ctl = shift1_in_ctl_d;
		add_in1_ctl = add_in1_ctl_d;
		add_in2_ctl = add_in2_ctl_d;
		add_nadd_sub = add_nadd_sub_d;
		a_ena =a_ena_d;
		b_ena =b_ena_d;
		round_ctl = round_ctl_d;
		shift1_left = shift1_left_d;
		shift1_right = shift1_right_d;
		logic_in1_ctl =logic_in1_ctl_d;
		logic_in2_ctl =logic_in2_ctl_d;
		logic_c = logic_c_d;
		ccr_affected = ccr_affected_d;
	end
end	/* always */
	

endmodule	/* end module */
