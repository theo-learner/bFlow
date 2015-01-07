`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:33:45 11/23/2014 
// Design Name: 
// Module Name:    addTree2bit_2L_2I 
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
module addTree4bit_4L_4I(
    input [3:0] data_a,
    input [3:0] data_b,
    input [3:0] data_c,
    input [3:0] data_d,

    output [3:0] ss1,
    output [3:0] ss2, 
    output [3:0] s 
    );

	wire [3:0] temp1;
	wire [3:0] temp2;

	assign temp1  = data_a + data_b;
	assign temp2  = data_c + data_d;
	assign s = temp1 + temp2;
	assign ss1 = temp1;
	assign ss2 = temp2;
	


endmodule
