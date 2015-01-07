`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:35:15 11/20/2014 
// Design Name: 
// Module Name:    life_8c 
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
module life_8c(input self, input [7:0] n1,
input [7:0] n2,
input [7:0] n3,
input [7:0] n4,
input [7:0] n5,
input [7:0] n6,
input [7:0] n7,
input [7:0] n8,
input[7:0] three,
input[7:0] two,
	output reg out);

	wire[7:0] count;
	wire is3, is2;
	addTree8bit_3L_8I cnt(n1,n2,n3,n4,n5,n6,n7,n8, count);
	equal8Bit e3(count, three, is3);
	equal8Bit e2(count, two, is2);


	always@(*)begin
		out = 8'b00000000;
		out = out | is3;
		out = out | ((self == 1) & is2);
	end

endmodule

module equal8Bit(
input [7:0] num1,
input [7:0] num2,
output isequal);

	XOR2 x1(w1, num1[7], num2[7]);
	XOR2 x2(w2, num1[6], num2[6]);
	XOR2 x3(w3, num1[5], num2[5]);
	XOR2 x4(w4, num1[4], num2[4]);
	XOR2 x5(w5, num1[3], num2[3]);
	XOR2 x6(w6, num1[2], num2[2]);
	XOR2 x7(w7, num1[1], num2[1]);
	XOR2 x8(w8, num1[0], num2[0]);

	AND4 a1(w11, w1, w2, w3, w4);
	AND4 a2(w22, w5, w6, w7, w8);
	AND2 a3(eq, w11, w22);

	INV inv(isequal, eq);

endmodule