/*	File:	rf_R.v	  					*/

/*	module name: rf_R						*/

/*	Description:	The R register file of 4 16-bit register to be used in the AGU of the 56k core.	*/

/*	Author: Nitzan Weinberg				*/

/*==============================================================================*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:	rf_R																*/
/*																				*/
/********************************************************************************/

module rf_R (
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

/* allow writes only if the 2 addresses differ */

always @(posedge Clk)
	begin
		if ( write1 )
			rf[waddr1] <= in1;					/* write rf with port 1 */

		if ( write2 )
			rf[waddr2] <= in2;					/* write rf with port 2 */
	end
	


/*------*/
/* read */
/*------*/

always @(	rf[raddr1] or
			rf[raddr2] or
			rf[raddr3]
			)
	begin
		out1 = rf[raddr1];	/* read rf via port 1 */
		out2 = rf[raddr2];	/* read rf via port 2 */
		out3 = rf[raddr3];	/* read rf via port 3 */
	end




endmodule	/* end module rf_R */
