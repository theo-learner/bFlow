/*	File:	core_test.v	  					*/

/*	module name: top						*/

/*	Description: TEST FILE					*/

/*	Tested Module name:	core1.v				*/


/*==============================================================================*/

/********************************************************************************/
/*																				*/
/*	module:	top																	*/
/*																				*/
/********************************************************************************/

module top;



/*============		I/O type	================================================*/

reg reset;

reg Clk;

reg [`addrbus]	AB;
wire [`databus]	PDB;
wire [`databus]	XDB;
wire [`databus]	YDB;
wire [`databus]	XDB_in;
wire [`databus]	YDB_in;
reg	REPEAT;
reg	AGU_C;
wire	E;
wire	U;
wire	Z;
wire	J;

reg 	S1;
reg 	S0;
reg [7:0]	CCR;
wire [7:0]	CCR_from_alu;
wire	Swrite;
wire	Lwrite;

/* signals with correct values to compare against */
wire [47:0]	Xreg, Yreg;
wire [`acc]	Areg;


/*==============================================================================*/



/*===========	Module Instantiations	 =======================================*/

alu_struc ALU(
	.reset(reset),
	.PDB(PDB),
	.XDB(XDB),
	.YDB(YDB),
	.REPEAT(REPEAT),
	.AGU_C(AGU_C),
	.S1(S1),
	.S0(S0),
	.CCR(CCR),
	.CCR_from_alu(CCR_from_alu),
	.Swrite(Swrite),
	.Lwrite(Lwrite),
	.J(J),
	.Clk(Clk)
	);


/* RAM to hold test vectors */
async_ramb XRAM(reset, Clk, AB, 1'b0, 1'b1, XDB_in);

async_ramb YRAM(reset, Clk, AB, 1'b0, 1'b1, YDB_in);

async_ramb  PRAM(reset, Clk, AB, 1'b0, 1'b1, PDB);

/* RAM to hold correct answers */
async_ramb #(48) XregRAM(reset, Clk, AB, 1'b0, 1'b1, Xreg);

async_ramb #(48) YregRAM(reset, Clk, AB, 1'b0, 1'b1, Yreg);
async_ramb #(56) AregRAM(reset, Clk, AB, 1'b0, 1'b1, Areg);


/*==============================================================================*/


/*==============================================================================*/
/*	initialize																		*/
/*==============================================================================*/

	assign YDB = YDB_in;
	assign XDB = XDB_in;

/* Advance address bus for memory. */
/* All memory uses same address, parser worries */
/* about pipeline effects */
always @(posedge Clk or posedge reset)
begin
	if (reset)
		AB <= 16'h10;
	else
		AB <= AB + 1;
end /* always */
		

initial
	begin

		/* read data from files into RAM modules */
		/* memory location RAMData.                 */
		/* start at RAMData[10]                     */
		$readmemh( "instr.mem", PRAM.RAMData, 8'h10);
		$readmemh( "xmem.mem", XRAM.RAMData, 8'h10);
		$readmemh( "ymem.mem", YRAM.RAMData, 8'h10);

		/*  data to check registers             */
		$readmemh( "xreg.mem", XregRAM.RAMData, 8'h10);
		$readmemh( "yreg.mem", YregRAM.RAMData, 8'h10);
		$readmemh( "aacc.mem", AregRAM.RAMData, 8'h10);
		
	
		
		$shm_open("alu.shm");		/* generates a dump file for Cwaves to use */
	
		$shm_probe("AS");			/* keep track of all signals in the current and lower modules in the hierarcy */
		


		$monitor($time, "\tPDB = %h\t XDB = %h\t YDB = %h\n",
				PDB, XDB, YDB,
			$time, " x1 = %h	x0 = %h\t\n",
					 ALU.x1, ALU.x0,
			$time, " y1 = %h	y0 = %h\t\n",
						 ALU.y1, ALU.y0,
			$time, " A = %h  B = %h \n",
					{ALU.a2, ALU.a1, ALU.a0},{ALU.b2, ALU.b1, ALU.b0}
					);



		
		Clk = 0;
		reset = 1;			/* for one clock cycle */

		/* set S1, S0 control registers */
		S1 = 0;
		S0 = 0;
		/* set REPEAT */
		REPEAT = 0;
	
		#100 reset = 0;		/* end of reset cycle */

		
		#4500 $finish;		/* end simulation */
		
		$shm_close;		 /* close the dump file */
	end



/*==============================================================================*/
/*	clock	5 units High, 5 units Low											*/
/*==============================================================================*/

always
	begin
		#50 Clk = 1;
		#50 Clk = 0;
	end
	

/* check to make sure values in registers match expected values */
always @(negedge Clk)
begin
	if (Xreg != {ALU.x1,ALU.x0})
		$display ($time, " ERROR: X register has incorrect data\n",
				"\t\t expected %h, got %h",
				Xreg, {ALU.x1,ALU.x0} );
	if (Yreg != {ALU.y1,ALU.y0})
		$display($time, " ERROR: Y register has incorrect data\n",
				"\t\t expected %h, got %h",
				Yreg, {ALU.y1,ALU.y0} );
	if (Areg != {ALU.a2, ALU.a1, ALU.a0})
		$display($time, " ERROR: A register has incorrect data\n",
				"\t\t expected %h, got %h",
				Areg, {ALU.a2, ALU.a1,ALU.a0} );

end /* always */

endmodule	/* end module top */