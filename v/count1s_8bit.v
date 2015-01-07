`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:41:24 11/18/2014 
// Design Name: 
// Module Name:    count1s_8bit 
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

module count1s_8bit(input [7:0] register, output [3:0] numOnes);

	addTree1_4 at(register[3:0], register[7:4], numOnes);
		
endmodule


module addTree1_4(A, B, S);
	input[3:0] A, B;
	output[3:0] S;

	wire [1:0] s00, s01, s02, s03;
	ha ha0(A[0], B[0], s00[0], s00[1]);
	ha ha1(A[1], B[1], s01[0], s01[1]);
	ha ha2(A[2], B[2], s02[0], s02[1]);
	ha ha3(A[3], B[3], s03[0], s03[1]);

	wire [2:0] s10, s11;
	add2 a21(s00, s01, s10[1:0], s10[2]);
	add2 a22(s02, s03, s11[1:0], s11[2]);

	add3 a3(s10, s11, S[2:0], S[3]);

endmodule




module add3(A, B, S, CO);
	input [2:0] A, B;
	output [2:0]S;
	output CO;

	ha ha0(A[0], B[0], S[0], w1);	
	fa fa1(A[1], B[1], w1, S[1], w2);
	fa fa2(A[2], B[2], w2, S[2], CO);
endmodule


module add2(A, B, S, CO);
	input [1:0] A, B;
	output [1:0]S;
	output CO;
	wire w1;

	ha ha0(A[0], B[0], S[0], w1);	
	fa fa1(A[1], B[1], w1, S[1], CO);

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

