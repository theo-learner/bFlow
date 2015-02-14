`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:25:47 11/20/2014 
// Design Name: 
// Module Name:    median 
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
module median_findHi(
    input [7:0] x2_y1,
    input [7:0] x2_y0,
    input [7:0] x2_ym1,

    output [7:0] m

);

    // Connection signals
    wire [7:0] node_u0_hi;
    wire [7:0] node_u0_lo;

    wire [7:0] node_u4_hi;
    wire [7:0] node_u4_lo;

    wire [7:0] node_u8_hi;
    wire [7:0] node_u8_lo;



    assign m = node_u8_lo;


	assign node_u0_hi= (x2_y1 < x2_y0) ? x2_y0: x2_y1;
	assign node_u0_lo= (x2_y1 < x2_y0) ? x2_y1: x2_y0;


	assign node_u4_hi= (node_u0_lo< x2_ym1) ?x2_ym1 :node_u0_lo ;
	assign node_u4_lo = (node_u0_lo< x2_ym1) ?node_u0_lo :x2_ym1 ;


	assign node_u8_hi = (node_u0_hi<node_u4_hi ) ?node_u4_hi :node_u0_hi ;
	assign node_u8_lo = (node_u0_hi<node_u4_hi ) ?node_u0_hi :node_u4_hi ;

 

endmodule

