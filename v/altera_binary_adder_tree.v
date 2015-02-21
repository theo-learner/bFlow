module altera_binary_adder_tree(A, B, C, D, E, clk, out);
   
	input	[15:0] A, B, C, D, E;
	input	clk;
	output	[15:0] out;

	wire	[15:0]    sum1, sum2, sum3, sum4;
	reg		[15:0]   sumreg1, sumreg2, sumreg3, sumreg4;

	// Registers
	always @ (posedge clk)
		begin
			sumreg1 <= sum1;
			sumreg2 <= sum2;
			sumreg3 <= sum3;
			sumreg4 <= sum4;
		end

	// 2-bit additions
	assign 			  sum1 = A + B;
	assign 			  sum2 = C + D;
	assign 			  sum3 = sumreg1 + sumreg2;
	assign 			  sum4 = sumreg3 + E;		  		
	assign 			  out = sumreg4;

endmodule
