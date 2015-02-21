/*	File:	limit.v	  						*/

/*	module name: limit						*/

/*	Description: limit */

/*		limits register output to 24 bits 	*/
/*		and shifts data 1 bit, depending on S1 and S0	*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module limit (
	in,
	S1, S0,
	lsb,
	out,
	L
	);


/*============	I/O direction	================================================*/

input [`acc] 	in;
input 	S1, S0;					/* status bits */
input	lsb;					/* 1 if output LSB (in0) */
output [`databus]	out;
output	L;						/* has limiting occured */

/*==============================================================================*/



/*============		I/O type	================================================*/

reg [`databus]	 out;
reg L;

/*==============================================================================*/

reg [`ext]		in2;
reg [`databus] 	in1, in0;

/*===========	Function Declarations	========================================*/


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





/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

always @(in or S1 or S1)
begin
	{in2, in1, in0} = in;
	if ( CCR_E(S1, S0, {in2, in1}) )					/* Extention bits in use */
		begin
			if (lsb)
				out = ( in2[7] ) ? 24'h000000 : 24'hffffff;	/* limit */
			else
				out = ( in2[7] ) ? 24'h800000 : 24'h7fffff;	/* limit */
			L = 1'b1;						/* limiting has occurred */
		end
	else begin
		if (lsb)
			/* Now we do the shifting, based on scaling mode bits */
			case ({S1, S0})
				2'b00:	/* no scaling */
					out = in[23:0];
				2'b01:	/* scale down */
					out = in[24:1];
				2'b01:	/* scale up */
					out = {in[22:0],1'b0};
				default: /* ERROR */
					out = in[23:0];
			endcase		else begin
			/* Now we do the shifting, based on scaling mode bits */
			case ({S1, S0})
				2'b00:	/* no scaling */
					out = in[47:24];
				2'b01:	/* scale down */
					out = in[48:25];
				2'b01:	/* scale up */
					out = in[46:23];
				default: /* ERROR */
					out = in[47:24];
			endcase
			L = 1'b0;						/* limiting has not occurred */
		end /* else */
	end
end /* always */


endmodule	/* end module */
