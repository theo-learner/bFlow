/*	File:	round.v	  						*/

/*	module name: round						*/

/*	Description: round */

/*		Rounds input using convergent rounding	*/
/*		Do NOT round if {s1, s0} = 11		*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module round (
	s0, s1,
	in,
	out
	);


/*============	I/O direction	================================================*/

input		s0, s1;	
input [`acc] 	in;
output [`acc]	 out;

/*==============================================================================*/



/*============		I/O type	================================================*/

wire [`acc]	 out;

/*==============================================================================*/


/*===========	Function Declarations	========================================*/


/*------------------------------------------------------------------*/
/*									*/
/*	function:	round						*/
/*									*/
/*	Convergent round a 56-bit number according to the scaling mode.	*/
/*									*/
/*------------------------------------------------------------------*/

/* Convergent round with clearing of the LS 24-bits */

function [`acc] round_f;

input S1;
input S0;
input [`acc] data_in;

reg [`acc] test_rounding;

	begin
		case ({S1, S0})
			2'b00	:	/* No Scaling 	*/
						begin
							test_rounding = data_in + 56'h800000;
							if (test_rounding[23:0] == 24'h000000)
								round_f = {test_rounding[55:25], 25'h0000000};
							else
								round_f = {test_rounding[55:24], 24'h000000};
						end
						
			2'b01	:	/* Scale Down 	*/
						begin
							test_rounding = data_in + 56'h1000000;
							if (test_rounding[24:0] == 25'h0000000)
								round_f = {test_rounding[55:26], 26'h0000000};
							else
								round_f = {test_rounding[55:25], 25'h0000000};
						end
						
			2'b10	:	/* Scale Up 	*/
						begin
							test_rounding = data_in + 56'h400000;
							/* bit 23 doesn't count anyway in the MSB portion,			*/
							/* therefore no need to test the special convergence case.  */
							round_f = {test_rounding[55:24], 24'h000000};
						end
				
			2'b11	:	/* Don't round -- flow through 	*/
					round_f = data_in;		
			default	:	;		/* no Action */
		endcase

	end
	
endfunction		/* round_f */


/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

assign out =  round_f(s1, s0, in);


endmodule	/* end module */
