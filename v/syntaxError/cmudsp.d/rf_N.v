/*	File:	rf_N.v	  					*/

/*	module name: rf_N						*/

/*	Description:	The N register file of 4 16-bit register to be used in the AGU of the 56k core.	*/
/*					It has 3 read ports and 2 write ports. */

/*	Author: Nitzan Weinberg			*/


/*==============================================================================*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	rf_N																*/
/*																				*/
/********************************************************************************/

module rf_N (
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

wire [`addrbus] in1;
wire [`addrbus] in2;
wire [`rfbus] raddr1;
wire [`rfbus] raddr2;
wire [`rfbus] raddr3;
wire [`rfbus] waddr1;
wire [`rfbus] waddr2;
wire write1;
wire write2;

reg [`addrbus] out1;
reg [`addrbus] out2;
reg [`addrbus] out3;

wire Clk;

/*==============================================================================*/



/*===========	Internal Nets	================================================*/

reg [`addrbus] rf [3:0];	/* the 4 x 16 bit register file */

/*==============================================================================*/



/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

/*-------*/
/* write */
/*-------*/

always @(posedge Clk)
	begin
		if (write1)
			rf[waddr1] <= in1;	/* write rf */

		if (write2)
			rf[waddr2] <= in2;	/* write rf */
	end
	
/*------*/
/* read */
/*------*/

always @(	rf[raddr1] or
			rf[raddr2] or
			rf[raddr3]
			)
	begin
		out1 = rf[raddr1];	/* read  rf */
		out2 = rf[raddr2];	/* read  rf */
		out3 = rf[raddr3];	/* read  rf */
	end




endmodule	/* end module rf_N */
