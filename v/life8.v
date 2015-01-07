`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:36:02 11/20/2014 
// Design Name: 
// Module Name:    life8 
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
module life8(input self, input [7:0] n1,
input [7:0] n2,
input [7:0] n3,
input [7:0] n4,
input [7:0] n5,
input [7:0] n6,
input [7:0] n7,
input [7:0] n8,
	output reg out);

	reg[7:0] count;
	always @(*) begin
		count = 7'b0; 
		count = count + n1;
		count = count + n2;
		count = count + n3;
		count = count + n4;
		count = count + n5;
		count = count + n6;
		count = count + n7;
		count = count + n8;

		out = 0;
		out = out | (count == 3);
		out = out | ((self == 1) & (count == 2));
	end

endmodule
