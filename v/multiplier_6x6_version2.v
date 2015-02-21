// created by verisplt.awk

		/* ------------------------------------ */
		/*					*/
		/*	      Macro  Library		*/
		/*					*/ 
		/*	    Advanced DSP Group		*/
		/*					*/
		/*   	   VLSI Tecnologies Lab		*/
		/*					*/
		/*		 --------		*/
		/*					*/
		/*	   Designer: Tim Pagden		*/
		/*					*/
		/*	      Date: Oct 1991		*/
		/*					*/ 
		/* ------------------------------------ */

`timescale 1ns/1ps

module multiplier_6x6_version2 (a,b,y);

input[5:0] a,b;
output[11:0] y;

wire lo,muxp0_sel,negate;
wire[1:0] mux21p0_sel;
wire[7:0] a2,a3,a4;
wire[5:0] zero,a1;
wire[2:0] cntl_2;
wire[2:0] cntl_1;
wire[8:0] a0,a5;

assign  lo = 0,
  zero = 6'b000_000;

muxi_4_8 mux21p0 (.a({{~a,~lo,~lo},{~a[5],~a,~lo},{~a[5],~a[5],~a},{~lo,~lo,~zero}}),.sel(mux21p0_sel),.yi(a2));
muxi_2_6 muxp0 (.a({~a,~zero}),.sel(muxp0_sel),.yi(a1));
scale_decoder_3 dec0 (cntl_2,{mux21p0_sel,negate,muxp0_sel});
adder_8 add8 (.a({a2}),.b({a1[5],a1[5],a1}),.c_in(lo),.y(a3));
muxi_2_8 xor_mux (.a({a3,~a3}),.sel(negate),.yi(a4));

scaler_3_6 sc1 (.a(a),.cntl(cntl_1),.y(a0));

adder_9 as0 (.a({a0[8],a0[8],a0[8],a0[8:3]}),.b({a4[7],a4}),
	.c_in(negate),.y(a5));

assign  cntl_1 = b[2:0],
	cntl_2 = b[5:3],
	y = {a5,a0[2:0]};

endmodule
