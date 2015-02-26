/*	File:	sync_ram.v	  						*/

/*	module name: ram 							*/

/*	Description: core ram for X, Y and Prog, seperate input, output ports	*/
/*               write synchonous on falling edge, write signal active high	*/
/* 				 single bidirectional data port								*/


/*==============================================================================*/


/*=========================== Radix Definitions ================================*/
`define ramsize 0:255
`define ramaddr 7:0        /* portion of address that ram uses */

/********************************************************************************/
/*																				*/
/*	module:  RAM, asynchonous													*/	
/*																				*/
/********************************************************************************/

module async_ramb (
	reset,
	Clk,
	AB,             /* address bus */
	write,			/* write enable */
	oe,			/* output enable */
	DB     			/* data bus */
	);

/*============	Parameters	================================================*/

parameter	datawidth = 24;

/*============	I/O direction	================================================*/

input reset, Clk;
input [`addrbus] AB;               /* address bus */
input            write;            /* write enable */
input            oe;               /* output enable */
inout [(datawidth-1):0] DB;              /* data bus */

/*==============================================================================*/


/*============		I/O type	================================================*/

/*	wire [`addrbus] AB;                address bus */
/*	wire            write;                 write enable */
/*	wire [`databus] DB_in;                data bus */
	
/*	reg [`databus] DB; */              /* data bus */


/*==============================================================================*/



/*===========	Internal Nets	================================================*/

reg [(datawidth-1):0] RAMData[`ramsize];              /* Storage for RAM */
reg [(datawidth-1):0] DB_out;

/*==============================================================================*/



/*===========	Module Instantiation	========================================*/


/*==============================================================================*/



/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/
	
	assign DB = DB_out;
	
	/* add tristate to output */
	always @(AB or oe)
		if (oe)
			DB_out = RAMData[AB[`ramaddr]];
		else
			DB_out = 24'bz;
	
	/* input of RAM is registered to falling clock edge*/
	always @(negedge Clk)
		begin 
			if (write == 1)
				RAMData[AB[`ramaddr]] <= DB;
		end
			
endmodule	/* end module */




