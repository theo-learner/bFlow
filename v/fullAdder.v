//-----------------------------------------------------
// Design Name : full_adder_gates
// File Name   : full_adder_gates.v
// Function    : Full Adder Using Gates
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module fullAdder(A, B, C, S, CO);
	input A, B, C;
	output S, CO;

	XOR2 x1(w1, A, B);
	XOR2 x2(S, w1, CO);
	
	AND2 a1(w2, C, w1);
	AND2 a2(w3, A, B);

	OR2 o1(CO, w1, w2);

endmodule
