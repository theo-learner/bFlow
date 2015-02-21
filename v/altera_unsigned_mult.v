module altera_unsigned_mult (out, a, b);
output [15:0] out;
	input  [7:0] a;
	input  [7:0] b;

	assign out = a * b;

endmodule
