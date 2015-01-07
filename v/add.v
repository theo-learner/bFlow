//-----------------------------------------------------
// Design Name : full_adder_gates
// File Name   : full_adder_gates.v
// Function    : Full Adder Using Gates
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module add(A, B, C, S, SUM, CO);
	input [3:0]A, B, C;
	input S;
	output [3:0] SUM;
	output CO;

	assign{CO, SUM} = S ? A + B : A + C;

endmodule
