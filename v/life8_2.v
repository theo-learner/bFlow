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
module life8(input self, input [7:0] n,
	output reg out);

	reg[7:0] count;
	always @(*) begin
		count = 7'b0; 
		count = count + n[0];
		count = count + n[1];
		count = count + n[2];
		count = count + n[3];
		count = count + n[4];
		count = count + n[5];
		count = count + n[7];
		count = count + n[6];

		out = 0;
		out = out | (count == 3);
		out = out | ((self == 1) & (count == 2));
	end

endmodule
