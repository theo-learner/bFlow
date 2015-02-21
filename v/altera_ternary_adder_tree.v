module altera_ternary_adder_tree(A, B, C, D, E, CLK, OUT);
	parameter WIDTH = 16;
   
	input [WIDTH-1:0] A, B, C, D, E;
	input 			  CLK;
	output [WIDTH-1:0] OUT;

	wire [WIDTH-1:0]    sum1, sum2;
	
	reg [WIDTH-1:0]   sumreg1, sumreg2;

	// Registers
	always @ (posedge CLK)
		begin
			sumreg1 <= sum1;
			sumreg2 <= sum2;
		end

	// 3-bit additions
	assign 			  sum1 = A + B + C;
	assign 			  sum2 = sumreg1 + D + E; 			  
		
	assign 			  OUT = sumreg2;
   
endmodule
