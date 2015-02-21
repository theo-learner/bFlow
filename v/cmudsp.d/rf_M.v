/*	File:	rf_M.v	  					*/

/*	module name: rf_M					*/

/*	Description:	A register file of 4 16-bit register, 2 read and one write ports.	*/
/*					Is used in the AGU of the 56k core for implementing the M (Modifier) registers.	*/

/* Author: Nitzan Weinberg */


/*==============================================================================*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	rf_M																*/
/*																				*/
/********************************************************************************/

module rf_M (
	reset,
	in1,
	in2,
	raddr1,
	raddr2,
	raddr3,
	waddr1,
	waddr2,
	write1,
	write2,
	out1,	
	out2,	
	out3,	
	Clk
	);


/*============	I/O direction	================================================*/

input reset;
input [`addrbus] in1;
input [`addrbus] in2;
input [`rfbus] raddr1;
input [`rfbus] raddr2;
input [`rfbus] raddr3;
input [`rfbus] waddr1;
input [`rfbus] waddr2;
input write1;
input write2;

output [`addrbus] out1;
output [`addrbus] out2;
output [`addrbus] out3;

input Clk;

/*==============================================================================*/



/*============		I/O type	================================================*/

wire reset;				/* reset of the 56K core */
wire [`addrbus] in1;	/* input data bus to the register file */
wire [`addrbus] in2;	/* input data bus to the register file */
wire [`rfbus] raddr1;	/* read port 1:  2-bit address bus selecting one register out of the 4 to put on the "out" bus. */
wire [`rfbus] raddr2;	/* read port 2:  2-bit address bus selecting one register out of the 4 to put on the "out" bus. */
wire [`rfbus] raddr3;	/* read port 3:  2-bit address bus selecting one register out of the 4 to put on the "out" bus. */
wire [`rfbus] waddr1;	/* write: 2-bit address bus selecting one register out of the 4 to be written using the data on the "in" bus. */
wire [`rfbus] waddr2;	/* write: 2-bit address bus selecting one register out of the 4 to be written using the data on the "in" bus. */
wire write1;			/* a synchronious write enable signal */
wire write2;			/* a synchronious write enable signal */

reg [`addrbus] out1;	/* output data bus port 1 from the register file, carrying the contents of the register that is read. */
reg [`addrbus] out2;	/* output data bus port 2 from the register file, carrying the contents of the register that is read. */
reg [`addrbus] out3;	/* output data bus port 3 from the register file, carrying the contents of the register that is read. */

wire Clk;

/*==============================================================================*/



/*===========	Internal Nets	================================================*/

reg [`addrbus] rf [3:0];	/* the 4 x 16 bit register file */

/*==============================================================================*/



/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

/*------------------------*/
/* core reset and a write */
/*------------------------*/

/* Synchronized reset sets the contents of the file register */

always @(posedge Clk)
	begin
		if (reset)
			begin
				rf[2'b00] = 16'hFFFF;
				rf[2'b01] = 16'hFFFF;
				rf[2'b10] = 16'hFFFF;
				rf[2'b11] = 16'hFFFF;
			end
		else
			begin
				if (write1)
					rf[waddr1] = in1;		/* write rf */

				if (write2)
					rf[waddr2] = in2;		/* write rf */
			end
	end
	
	
/*------*/
/* read */
/*------*/

always @(rf[raddr1] or rf[raddr2] or rf[raddr3])
	begin
		out1 = rf[raddr1];	/* read  rf */
		out2 = rf[raddr2];	/* read  rf */
		out3 = rf[raddr3];	/* read  rf */
	end




endmodule	/* end module rf_M */
