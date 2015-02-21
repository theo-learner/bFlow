/*	File:	logic_unit.v	  						*/

/*	module name: logic_unit						*/

/*	Description: logic_unit */

/*		Perform 24 bit logical operations	*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module logic_unit (
	c,		/* control signals */
	in1, in2,
	out
	);


/*============	I/O direction	================================================*/

input [2:0]			c;	
input [`databus] 	in1, in2;
output [`databus]	out;

/*==============================================================================*/



/*============		I/O type	================================================*/

wire [`databus]	 out;

/*==============================================================================*/


/*===========	Function Declarations	========================================*/


/*------------------------------------------------------------------*/
/*																	*/
/*	function:	logic												*/
/*																	*/
/*																	*/
/*------------------------------------------------------------------*/

/* Convergent round with clearing of the LS 24-bits */

function [`databus] logic;

input [2:0] C;
input [`databus] data_in1, data_in2;

reg [`acc] test_rounding;

	begin
		case (C)
			3'b000	:	/* OR */
						logic = data_in1 & data_in2;
						
			3'b001	:	/* EOR */
						logic = data_in1 ^ data_in2;
						
			3'b010	:	/* AND */
						logic = data_in1 & data_in2;
				
			3'b011	:	/* Not 	*/
						logic = ~data_in1;
				
			3'b100	:	/* LSR 	*/
						logic = {1'b0,data_in1[23:1]};	
				
			3'b101	:	/* ROR 	*/
						logic = {data_in1[0],data_in1[23:1]};	
						
			3'b110	:	/* LSR 	*/
						logic = {data_in1[22:0], 1'b0};	
				
			3'b111	:	/* ROR 	*/
						logic = {data_in1[22:0],data_in1[23]};	
	
			default	:	;		/* no Action */
		endcase

	end
	
endfunction		/* logic */


/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

assign out =  logic(c, in1, in2);


endmodule	/* end module */
