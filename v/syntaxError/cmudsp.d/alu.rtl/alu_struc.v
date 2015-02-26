/*	File:	data_alu.v	  								*/

/*	module name: data_alu								*/

/*	Description: The data ALU block of the 56K core,  "structural" model.	*/

/*  Author:	Nitzan Weinberg, Ben Klass								*/

/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	data_alu															*/
/*																				*/
/********************************************************************************/

module alu_struc (
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

/* Data lines for parallel moves */

reg [`databus] XDB_out;	
reg [`databus] YDB_out;

reg [`databus] xy0, xy1;	/* from X, Y registers to parallel move */
wire [`databus] ab0, ab1;	/* from a, b registers to parallel move */


reg [`databus] pdb2;		/* an instruction inside stage 2 (Decode)	*/
reg [`databus] pdb3;		/* an instruction inside stage 3 (Execute)	*/

/* Internal registers */
wire [`databus] x1, x0;
wire [`databus] y1, y0;

reg [`databus] x1_in, x0_in;		/* inputs to x registers */
reg [`databus] y1_in, y0_in;		/* inputs to y registers */

wire x1_write, x0_write;	/* write enable signal for x registers */
wire y1_write, y0_write;	/* write enable signal for y registers */

/* Accumulators A and B: 56 bits broken into three fields */
reg [`ext]     a2;
reg [`databus] a1, a0;

reg [`ext]     b2;
reg [`databus] b1, b0;

/* register (write) enable signals for A and B */
wire a_write, b_write;

/* status register signals.  Sent to PCU to be latched */
wire S_in, L_in, E_in, U_in, N_in, Z_in, V_in, C_in;


/*----------------------------------------------*/
/*  module interface 				*/
/*  These are the wires that get tied to the modules */
/*----------------------------------------------*/

wire immediate;		/* flag for immediate data (absolute address extension) on PDB */

/*-------- Parallel Move ------*/
reg [`acc]	limit0_in, limit1_in;
wire		limit0_lsb, limit1_lsb;
wire	limit0_l, limit1_l;

/* Parallel Move control signals */
wire [1:0] xdb_out_ctl,ydb_out_ctl;
wire XDB_write, YDB_write;
wire [1:0] x0_in_ctl, x1_in_ctl, y0_in_ctl, y1_in_ctl;
wire [1:0] xy0_ctl, xy1_ctl;
/* register inputs for control signals that get latched */
wire [1:0] x0_in_ctl_d, x1_in_ctl_d, y0_in_ctl_d, y1_in_ctl_d;
wire x1_write_d, x0_write_d;	/* write enable signal for x registers */
wire y1_write_d, y0_write_d;	/* write enable signal for y registers */
wire move_from_ab;				/* 1 if A or B are source of data move */

/*-------- Data Path -----------*/
reg [`databus] 	mult_y, mult_x;
wire [47:0]	mult_prod;
reg [4:0] decode_in;
wire [`databus] decode_out;
reg [`acc] 	add_in1;
reg [`ext]	add_in2_2;
reg [`databus]	add_in2_1, add_in2_0;
wire [`acc] 	add_sum;
reg [`acc]	round_in;
wire [`acc]	round_out;
reg [`acc]	shift1_in;
wire [`acc]	shift1_out;
reg [`databus] logic_in1, logic_in2;
wire [`databus] logic_out;
/*------------ Control -------------*/
/* These are control inputs to data path modules */
wire 		add_nadd_sub;  
reg 		round_s0, round_s1;		/* not hooked to CONTROL */
wire		shift1_left, shift1_right;
wire	[2:0]	logic_c;

/*----------------------------------------------*/
/* Data Path control signals */
/*  these are the wires that tell the data path */
/*  modules what they should be hooked up to    */
/*----------------------------------------------*/
wire [2:0] mult_x_ctl, mult_y_ctl;
wire shift1_in_ctl;		/* A or B */
wire add_in1_ctl;		/* shift1 or 0 */
wire [3:0] add_in2_ctl;
wire round_ctl;   /* 1 if round, 0 if not */
wire [2:0] logic_in1_ctl, logic_in2_ctl;
wire ccr_affected;	/* 1 if ccr[5:1] is affected by the operation */


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
input [`databus] A;
input [`databus] B;

	begin
		case ({S1, S0})
			2'b00	:	/* no scaling	*/
						CCR_S = (A[46-24] ^ A[45-24]) || (A[46-24] ^ A[45-24]);
			2'b01	:	/* scale down	*/
						CCR_S = (A[47-24] ^ A[46-24]) || (A[47-24] ^ A[46-24]);
			2'b10	:	/* scale up		*/
						CCR_S = (A[45-24] ^ A[44-24]) || (A[45-24] ^ A[44-24]);
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
	else begin
		/* if REPEAT, use old instruction word */
		if (REPEAT)
			pdb2 <= pdb2;
		else
			pdb2 <= PDB;
	end /* else */
end /* always */
			

			
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
			/* move the instruction from the Decode to the Execute stage */
			pdb3 <= pdb2;	
	end
/* end always */


/*==================================================================================*/
/*===========				Immediate data check  							============*/
/*==================================================================================*/

/*===========	Module Instantiation	========================================*/

/* check_imm checks the pdb field to see if the following instruction has immediate data. */
/* If so, the immediate flag is set to 1.  This flag is used in control and control.v	*/
/* to ensure that no aliasing occurs 	*/


check_imm CHECK_IMM(
	.Clk(Clk), .reset(reset),
	.pdb(pdb2),	
	.immediate(immediate)
	);


/*==================================================================================*/
/*===========					Parallel Move  							============*/
/*==================================================================================*/

/*===========	Module Instantiation	========================================*/



/*--------------------------*/
/*		CONTROL_P				*/
/*--------------------------*/

 control_p CONTROL_P(
	.Clk(Clk), .reset(reset),
	.pdb(pdb2),
	.immediate(immediate),
	.x0_in_ctl(x0_in_ctl),
	.x1_in_ctl(x1_in_ctl),
	.y0_in_ctl(y0_in_ctl),
	.y1_in_ctl(y1_in_ctl),
	.x0_write(x0_write),
	.x1_write(x1_write),
	.y0_write(y0_write),
	.y1_write(y1_write),
	.limit0_lsb(limit0_lsb),
	.limit1_lsb(limit1_lsb),
	.xy0_ctl(xy0_ctl),
	.xy1_ctl(xy1_ctl),
	.xdb_out_ctl(xdb_out_ctl),
	.ydb_out_ctl(ydb_out_ctl),
	.XDB_write(XDB_write),
	.YDB_write(YDB_write),
	.move_from_ab(move_from_ab)
	);


/*--------------------------*/
/*		LIMIT				*/
/*--------------------------*/
limit LIMIT0(
	.in(limit0_in),
	.S1(S1), .S0(S0),
	.lsb(limit0_lsb),
	.out(ab0),
	.L(limit0_l)
	);

limit LIMIT1(
	.in(limit1_in),
	.S1(S1), .S0(S0),
	.lsb(limit1_lsb),
	.out(ab1),
	.L(limit1_l)
	);
	
XYreg X0_REG(
	.Clk(Clk), .reset(reset),
	.XDB(XDB), .YDB(YDB),
	.in_ctl(x0_in_ctl),
	.write(x0_write),
	.q(x0)
	);

XYreg X1_REG(
	.Clk(Clk), .reset(reset),
	.XDB(XDB), .YDB(YDB),
	.in_ctl(x1_in_ctl),
	.write(x1_write),
	.q(x1)
	);

XYreg Y0_REG(
	.Clk(Clk), .reset(reset),
	.XDB(XDB), .YDB(YDB),
	.in_ctl(y0_in_ctl),
	.write(y0_write),
	.q(y0)
	);

XYreg Y1_REG(
	.Clk(Clk), .reset(reset),
	.XDB(XDB), .YDB(YDB),
	.in_ctl(y1_in_ctl),
	.write(y1_write),
	.q(y1)
	);



/*===========	Select module inputs		=================================*/

always @(a2 or a1 or a0 or b2 or b1 or b0 or 
	limit0_lsb or limit1_lsb)
begin

	/* LIMIT0 inputs */
	/* Produces A MSB or B LSB */
	if (!limit0_lsb)
		limit0_in = {a2, a1, a0};
	else
		limit0_in = {b2, b1, b0};
	
	/* LIMIT1 inputs */
	/* Produces B MSB or A LSB */
	if (!limit1_lsb)
		limit1_in = {b2, b1, b0};
	else
		limit1_in = {a2, a1, a0};
		
	
end /* always */


/*===========	select X, Y registers as sources for moves	==================*/
/* this layer of muxes may not be necessary, but helps flexibility */

always @(x0 or x1 or y0 or y1 or xy1_ctl or xy0_ctl )
begin
	
	/* xy0 bus */
	case (xy0_ctl)
		`xyout_x0 : xy0 = x0;
		
		`xyout_x1 : xy0 = x1;

		`xyout_y0 : xy0 = y0;

		`xyout_y1 : xy0 = y1;
	
		default : xy0 = 24'h0;	/* not used */		
	endcase	
	
	/* xy0 bus */
	case (xy1_ctl)
		`xyout_x0 : xy1 = x0;
		
		`xyout_x1 : xy1 = x1;

		`xyout_y0 : xy1 = y0;

		`xyout_y1 : xy1 = y1;
	
		default : xy1 = 24'h0;			
	endcase	

end /* always */
	

/*===========	send outputs to busses	======================================*/

/* assign the output data to the XDB/YDB buses if a write enable is true */

assign XDB = (XDB_write) ? XDB_out : 24'hzzzzzz;
assign YDB = (YDB_write) ? YDB_out : 24'hzzzzzz;

/* determine which signals go to which output bus */
always @(xdb_out_ctl or ydb_out_ctl or xy0 or xy1 or ab0 or ab1)
begin
	
	/* XDB bus */
	case (xdb_out_ctl)
		`out_xy0 : XDB_out = xy0;
		
		`out_xy1 : XDB_out = xy1;

		`out_ab0 : XDB_out = ab0;

		`out_ab1 : XDB_out = ab1;
	
		default : XDB_out = 24'h0;			
	endcase	
	
	/* YDB bus */
	case (ydb_out_ctl)
		`out_xy0 : YDB_out = xy0;
		
		`out_xy1 : YDB_out = xy1;

		`out_ab0 : YDB_out = ab0;

		`out_ab1 : YDB_out = ab1;
	
		default : YDB_out = 24'h0;			
	endcase	

end /* always */
	

/*===========	get data into X, Y regiters	======================================*/

/* actually, this is all done inside the XYreg modules */
	


/*==================================================================================*/
/*===========						Data Path  							============*/
/*==================================================================================*/

/*===========	Module Instantiation	========================================*/

/*--------------------------*/
/*		CONTROL				*/
/*--------------------------*/

control CONRTOL (
	.Clk(Clk),
	.reset(reset),
	.pdb(pdb2),	
	.immediate(immediate),
	.mult_x_ctl(mult_x_ctl),
	.mult_y_ctl(mult_y_ctl),
	.shift1_in_ctl(shift1_in_ctl),
	.add_in1_ctl(add_in1_ctl),
	.add_in2_ctl(add_in2_ctl),
	.add_nadd_sub(add_nadd_sub),
	.a_ena(a_write),
	.b_ena(b_write),
	.round_ctl(round_ctl),
	.shift1_left(shift1_left),
	.shift1_right(shift1_right),
	.logic_in1_ctl(logic_in1_ctl),
	.logic_in2_ctl(logic_in2_ctl),
	.logic_c(logic_c),
	.ccr_affected(ccr_affected)
	);

/*--------------------------*/
/*		MULT				*/
/*--------------------------*/

mult MULT (
	.x(mult_x), .y(mult_y),
	.prod(mult_prod)
	);

/*--------------------------*/
/*		DECODE				*/
/*--------------------------*/

decode DECODE (
	.in(decode_in),
	.out(decode_out)
	);

/*--------------------------*/
/*		ADD (subtracts too)		*/
/*--------------------------*/

addsub ADD (
	.in1(add_in1), 
	.in2_2(add_in2_2), .in2_1(add_in2_1), .in2_0(add_in2_0), 
	.naddsub(add_nadd_sub),
	.sum(add_sum)
	);

/*--------------------------*/
/*		ROUND				*/
/*--------------------------*/

round ROUND (
	.s0(round_s0),.s1(round_s1), 
	.in(round_in),
	.out(round_out)
	);

/*--------------------------*/
/*		SHIFT1				*/
/*--------------------------*/
shift1 SHIFT1 (
	.left(shift1_left), .right(shift1_right),
	.in(shift1_in),
	.out(shift1_out)
	);
	
/*--------------------------*/
/*		LOGIC				*/
/*--------------------------*/
logic_unit LOGIC (
	.c(logic_c),
	.in1(logic_in1), .in2(logic_in2),
	.out(logic_out)
	);



/*===========	Select module inputs		======================================*/
/* need more inputs tothe always statement */

/* DECODE inputs */
always @(pdb3)
	decode_in = pdb3[12:8];


/* MULT inputs: mult_x and mult_y */
always @(mult_x_ctl or mult_y_ctl or
		 x0 or x1 or y0 or y1 or decode_out)
begin
	/* MULT inputs: mult_x and mult_y */
	case (mult_x_ctl)
		`m_x0 : mult_x = x0;
		
		`m_x1 : mult_x = x1;

		`m_y0 : mult_x = y0;

		`m_y1 : mult_x = y1;
		
		`m_p  : mult_x = decode_out;
	
		default : mult_x = 24'h0;			
	endcase		
	
	case (mult_y_ctl)
		`m_x0 : mult_y = x0;
		
		`m_x1 : mult_y = x1;

		`m_y0 : mult_y = y0;

		`m_y1 : mult_y = y1;
	
		default : mult_y = 24'h0;
	endcase
end /* always */

/* LOGIC inputs */
always @(logic_in1_ctl or logic_in2_ctl or 
		x0 or x1 or y0 or y1 or 
		a2 or a1 or a0 or b2 or b1 or b0)
begin

	case (logic_in1_ctl)
		`l_x0 : logic_in1 = x0;
		
		`l_x1 : logic_in1 = x1;

		`l_y0 : logic_in1 = y0;

		`l_y1 : logic_in1 = y1;
		
		`l_a  : logic_in1 = a1;
		
		`l_b  : logic_in1 = b1;
	
		default : logic_in1 = 24'h0;			
	endcase		
	
	case (logic_in2_ctl)
		`l_x0 : logic_in2 = x0;
		
		`l_x1 : logic_in2 = x1;

		`l_y0 : logic_in2 = y0;

		`l_y1 : logic_in2 = y1;
		
		`l_a  : logic_in2 = a1;
		
		`l_b  : logic_in2 = b1;
	
		default : logic_in2 = 24'h0;
	endcase
end	/* always */
	
	
/* SHIFT1 inputs*/
always @(shift1_in_ctl or
		x0 or x1 or y0 or y1 or 
		a2 or a1 or a0 or b2 or b1 or b0)
begin
	/* always go through SHIFT1, use left, right to control if used */
	if (shift1_in_ctl)
		/* B */
		shift1_in = {b2, b1, b0};
	else 
		/* A */
		shift1_in = {a2, a1, a0};
end	/* always */

		
/* ADD inputs*/
always @(add_in1_ctl or add_in2_ctl or
		mult_prod or shift1_out or logic_out or
		x0 or x1 or y0 or y1 or
		a2 or a1 or a0 or b2 or b1 or b0)
begin
	/* shift1_in1 is used for the input to add_in1, unless flow through */
	if (add_in1_ctl)
		add_in1 = shift1_out;
	else
		add_in1 = 56'b0;
	/* add_in2.  Sign extend if necessary */
	case (add_in2_ctl)
		`a_m : begin
			//	$display ($time, " add_in2 hooked to mult_prod: %h", mult_prod);
				add_in2_2 = {8{mult_prod[47]}};  /* sign extend */
				add_in2_1 = mult_prod[47:24];
				add_in2_0 = mult_prod[23:0];
			   end
		`a_a : begin
				{add_in2_2, add_in2_1, add_in2_0} = {a2, a1, a0};
			   end
		`a_b : begin
				{add_in2_2, add_in2_1, add_in2_0} = {b2, b1, b0};
			   end
		`a_x : begin
				add_in2_2 = {8{x1[23]}};  /* sign extend */
				add_in2_1 = x1;
				add_in2_0 = x0;
			   end
		`a_x0 : begin
				add_in2_2 = {8{x0[23]}};  /* sign extend */
				add_in2_1 = x0;
				add_in2_0 = 24'h0;
			   end
		`a_x1 : begin
				add_in2_2 = {8{x1[23]}};  /* sign extend */
				add_in2_1 = x1;
				add_in2_0 = 24'h0;
			   end
		`a_y : begin
				add_in2_2 = {8{y1[23]}};  /* sign extend */
				add_in2_1 = y1;
				add_in2_0 = y0;
			   end
		`a_y0 : begin
				add_in2_2 = {8{y0[23]}};  /* sign extend */
				add_in2_1 = y0;
				add_in2_0 = 24'h0;
			   end
		`a_y1 : begin
				add_in2_2 = {8{y1[23]}};  /* sign extend */
				add_in2_1 = y1;
				add_in2_0 = 24'h0;
			   end
		`a_la : begin
				add_in2_2 = a2;  
				add_in2_1 = logic_out;	/* only MSB chages */
				add_in2_0 = a0;
			   end
		`a_lb : begin
				add_in2_2 = b2;  
				add_in2_1 = logic_out;	/* only MSB chages */
				add_in2_0 = b0;
			   end
		default : begin
				add_in2_2 = 8'h0;  
				add_in2_1 = 24'h0;
				add_in2_0 = 24'h0;
			   end
	endcase		
end	/* always */

always @(round_ctl or add_sum or 
		 S1 or S0)
begin
	/* ROUND inputs*/
	/* always go through ROUND, use s1, s0 to control if used */
	round_in = add_sum;
	if (round_ctl)
		{round_s1, round_s0} = {S1, S0};
	else
		{round_s1, round_s0} = 2'b11;
end /* always */


/*===========	Latch data into A and B registers	==================================*/

always @(posedge Clk or posedge reset)
begin
	if (reset)
	begin
		{a2, a1, a0} <= 56'h0;
		{b2, b1, b0} <= 56'h0;
	end
	else begin
		/* A */
		if (a_write)
			{a2, a1, a0} <= round_out;
		else
			{a2, a1, a0} <= {a2, a1, a0};
		/* B */
		if (b_write)
			{b2, b1, b0} <= round_out;
		else
			{b2, b1, b0} <= {b2, b1, b0};
	end /* else */
end  /* always */


/*==============================================================================================*/
/*																								*/
/*	CCR																							*/
/*																								*/
/*==============================================================================================*/

/* CCR bits generated in the data alu, and go to the PCU */

assign CCR_from_alu = {S_in, L_in, E_in, U_in, N_in, Z_in, V_in, C_in};

/* these signals are only changed if A or B are source of data move */
assign S_in = (move_from_ab) ? CCR_S(S1, S0, {a2, a1, a0}, {b2, b1, b0}) : 1'b0;	/* NOT SUPPORTED */
assign L_in = (move_from_ab) ? (limit0_l || limit1_l) : 0;
/* these signals are only changed by ALU instrucitons */ 
assign E_in = (ccr_affected) ? CCR_E(S1, S0, add_sum[55:24]) : 1'b1;
assign U_in = (ccr_affected) ? CCR_U(S1, S0, add_sum[55:24]) : 1'b0;
assign N_in = (ccr_affected) ? CCR_N(add_sum) : 1'b0;
assign Z_in = (ccr_affected) ? CCR_Z(add_sum) : 1'b0;	/* NOT SUPPORTED */
assign V_in = 1'b0;	/* NOT SUPPORTED */


endmodule /* alu_struc */
			
				



