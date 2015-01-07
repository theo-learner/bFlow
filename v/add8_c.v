`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:19:58 11/20/2014 
// Design Name: 
// Module Name:    add8_c 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module add8_c(A, B, S, CO
    );
	 
	 input[7:0] A, B;
	 output[7:0] S;
	 output CO;
	 wire w1, w2, w3, w4, w5, w6, w7;
	 
	ha ha0(A[0], B[0], S[0], w1);	
	fa fa1(A[1], B[1], w1, S[1], w2);
	fa fa2(A[2], B[2], w2, S[2], w3);
	fa fa3(A[3], B[3], w3, S[3], w4);
	fa fa4(A[4], B[4], w4, S[4], w5);
	fa fa5(A[5], B[5], w5, S[5], w6);
	fa fa6(A[6], B[6], w6, S[6], w7);
	fa fa7(A[7], B[7], w7, S[7], CO);

endmodule

module fa(A, B, C, S, CO);
	input A, B, C;
	output S, CO;
	wire w1, w2, w3;
	
	XOR2 x1(w1, A, B);
	XOR2 x2(S, w1, C);
	AND2 a1(w2, C, w1);
	AND2 a2(w3, A, B);
	OR2 o1(CO, w2, w3);
endmodule

module ha(A, B, S, CO);
	input A, B;
	output S, CO;
	XOR2 x1(S, A, B);
	AND2 a2(CO, A, B);
endmodule
