/*	File:	XYreg.v	  						*/

/*	module name: XYreg						*/

/*	Description: XYreg */

/*	 register for X, Y registers with input mux	*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module XYreg (
	Clk, reset,
	XDB, YDB,
	in_ctl,
	write,
	q,
	);


/*============	I/O direction	================================================*/

input				Clk, reset;
input [`databus] 	XDB, YDB;
input [1:0] 		in_ctl;
input 		 		write;
output [`databus]	q;

/*==============================================================================*/


/*============		I/O type	================================================*/

reg [`databus]	 q;

/*================ internal signals ============================================*/

reg [`databus] 	mux_out;

/*===========	Function Declarations	========================================*/

/*------------------------------------------------------------------*/
/*																	*/
/*	function:	select												*/
/*																	*/
/*	select input signal 											*/
/*																	*/
/*------------------------------------------------------------------*/

function [`databus] select;

input [1:0]	sel;

input [`databus] XDB, YDB;

	begin
		case (sel)
			`xy_x : select = XDB;
			
			`xy_y : select = YDB;
			
		endcase
	end
	
endfunction		/* select */



/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

always @(posedge Clk or posedge reset)
begin
	if (reset)
		q <= 24'h0;
	else
		if (write)
			q <= select(in_ctl, XDB, YDB);
		else
			q <= q;
end  /* always */

endmodule	/* end module */
