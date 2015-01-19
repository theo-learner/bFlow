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
module life_3(input self, input [7:0] n,
	output reg out);

	wire[7:0] count;

	assign count = n[0] + n[1] + n[2] + n[3] + n[4] + n[5] + n[6] + n[7];

	assign out = (self == 1) && (count == 2) ? 1'b1 : (count == 3) ? 1'b1 : 1'b0;


endmodule
