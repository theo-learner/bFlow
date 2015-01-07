`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:11:07 11/21/2014 
// Design Name: 
// Module Name:    comparator8 
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
module lt8(

    input [7:0] data_a,
    input [7:0] data_b,

    output lt
);


	assign lt = (data_a < data_b);




endmodule
