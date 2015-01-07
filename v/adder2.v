module add2(A, B, S, CO);
	input [1:0] A, B;
	input C;
	output [1:0] S;
	output CO;

	ha ha0(A[0], B[0], S[0], w1);	
	fa fa1(A[1], B[1], w1, S[1], CO);

endmodule

module fa(A, B, C, S, CO);
	input A, B, C;
	output S, CO;
	XOR2 x1(w1, A, B);
	XOR2 x2(S, w1, CO);
	AND2 a1(w2, C, w1);
	AND2 a2(w3, A, B);
	OR2 o1(CO, w1, w2);
endmodule

module ha(A, B, S, CO);
	input A, B;
	output S, CO;
	XOR2 x1(w1, A, B);
	AND2 a2(w3, A, B);
endmodule;







