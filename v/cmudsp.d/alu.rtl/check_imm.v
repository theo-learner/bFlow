/*	File:	check_imm.v	  						*/

/*	module name: check_imm						*/

/*	Description: 		 						*/

/*		Control logic to check if instruction uses 	*/
/*		immediate data field in next instruction word	*/



/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module check_imm (
	Clk, reset,
	pdb,	
	immediate
	);


/*============	I/O direction	================================================*/

input	Clk, reset;
input [`databus] 	pdb;
output	immediate;		/* Does instruction use immediate data field */

/*=============	I/O type	===================================================*/

reg immediate;

/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/

/* check for any instruction that uses address extension */
/* Based on appendix A.9, might miss some instructions	*/
/* More instructions than supported by CMU version included */


always @(posedge Clk or posedge reset)
begin
	if (reset)
		immediate <= 0;
	else begin
		casex (pdb[23:8])
			/* parallel moves */
			24'b01xxxxxxx1110x00xxxxxxxx,	/* X:,Y:, L: */
			24'b0001xxxxxx110x00xxxxxxxx:	/* X:R , R:Y*/
				immediate <= 1;
			24'b0000101x11110x001010xxxx,	/* JScc */
			24'b0000101x11110x0010000000:	/* JSR, JMP */
				immediate <= 1;
			24'b0000101x_10xxxxxx_1xxxxxxx,	/* JSCLR, JSET */
			24'b0000101x_01xxxxxx_1xxxxxxx,	/* JSCLR, JSET */
			24'b0000101x_00xxxxxx_1xxxxxxx,	/* JSCLR, JSET */
			24'b0000101x_11xxxxxx_00xxxxxx:	/* JSCLR, JSET */
				immediate <= 1;
			24'b0000101x_01110x00_0xxxxxxx:	/* BCHG, BSET, BTST, BCLR */
				immediate <= 1;
			24'b0000100x_x1110x00_1xxxxxxx,	/* MOVEP */
			24'b0000100x_x1110x00_01xxxxxx:	/* MOVEP */
				immediate <= 1;
			24'b00000111_x1110x00_10xxxxxx:	/* MOVE(M) */
				immediate <= 1;
			24'b00000110_xxxxxxxx_1000xxxx,	/* DO (the one FIR uses) */
			24'b00000110_11xxxxxx_00000000,	/* DO */
			24'b00000110_01xxxxxx_0x000000,	/* DO */
			24'b00000110_00xxxxxx_0x000000:	/* DO */
				immediate <= 1;
			24'b00000101_x1110x00_0x1xxxxx:	/* MOVE(C) */
				immediate <= 1;
			default:
				immediate <= 0;
		endcase
	end /* else */
end /* always */
		
endmodule
