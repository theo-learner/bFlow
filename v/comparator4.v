`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:10:52 11/21/2014 
// Design Name: 
// Module Name:    comparator4 
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
module lt4(

    input [3:0] data_a,
    input [3:0] data_b,

    output lt
);


	assign lt = (data_a < data_b);




endmodule
