/*	File:	mult.v	  						*/

/*	module name: mult						*/

/*	Description: multily/accumute module for ALU */

/*				Calculates x * y + a		*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module mult (
	x, y,
	prod
	);


/*============	I/O direction	================================================*/

input [`databus] x;
input [`databus] y;
output [47:0]	 prod;

/*==============================================================================*/



/*============		I/O type	================================================*/

wire [47:0]	 prod;

/*==============================================================================*/


/*===========	Function Declarations	========================================*/

/*------------------------------------------------------------------------------*/
/*																				*/
/*	function:	mul																*/
/*																				*/
/*	Multiply two 24-bit signed numbers and result in a 56-bit signed product.	*/
/*																				*/
/*------------------------------------------------------------------------------*/

function [`acc] mul;

input [`databus] data_in1;
input [`databus] data_in2;

reg [`databus] positive1;	/* the abs of first negative input */
reg [`databus] positive2;	/* the abs of second negative input */

reg [45:0] product;			/* the 46-bit unsigned product of the two POSITIVE inputs */

	begin
		case ( {data_in1[23], data_in2[23]} )
			2'b00	:	begin								/* data_in1 is positive, data_in2 is positive */
							product = data_in1[22:0] * data_in2[22:0];
							mul = { 9'h000, product, 1'b0 };
						end

			2'b01	:	begin								/* data_in1 is positive, data_in2 is negative */
							positive2 = 1 + (~data_in2);
							if (positive2[23])											/* data_in2 is (-1.0) */
								begin
									product = positive2 * data_in1[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;	
								end
							else
								begin
									product = positive2[22:0] * data_in1[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;
								end
						end

			2'b10	:	begin								/* data_in1 is negative, data_in2 is positive */
							positive1 = 24'h1 + (~data_in1);
							if (positive1[23])											/* data_in1 is (-1.0) */
								begin
									product = positive1 * data_in2[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;	
								end
							else
								begin
									product = positive1[22:0] * data_in2[22:0];
									mul = (~{ 9'b000000000, product, 1'b0 }) + 1'b1;
								end
						end

			2'b11	:	begin								/* data_in1 is negative, data_in2 is negative */
							positive1 = 24'h1 + (~data_in1);
							positive2 = 24'h1 + (~data_in2);

							case ( {positive1[23], positive2[23]} )
								2'b00	:	begin							/* data_in1 is NOT (-1.0) and data_in2 is NOT (-1.0) */
												product = positive1[22:0] * positive2[22:0];
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b01	:	begin							/* data_in1 is NOT (-1.0) but data_in2 is (-1.0) */
												product = positive1[22:0] * positive2;
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b10	:	begin							/* data_in1 is (-1.0) but data_in2 is NOT (-1.0) */
												product = positive1 * positive2[22:0];
												mul = { 9'b000000000, product, 1'b0 };	
											end
								2'b11	:	begin							/* data_in1 is (-1.0) and data_in2 is (-1.0) */
												product = positive1[23:1] * positive2[23:1];
												mul = { 8'b00000000, product[44:0], 3'b000 };	
											end
							endcase
						end
							
		endcase		/* sign of the sources */
			
	end
	
endfunction		/* mul */



/*==============================================================================*/



/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

assign prod =  mul(x, y);


endmodule	/* end module */
