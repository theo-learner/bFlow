`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:45:17 11/20/2014 
// Design Name: 
// Module Name:    addTree8bit_3L_8I 
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


module addTree8bit_3L_8I(n1, n2, n3, n4, n5, n6, n7, n8, S
    );
	 
	 input [7:0] n1, n2, n3, n4, n5, n6, n7, n8;
	 output [7:0] S;
	 wire[7:0] S1, S2, S3, S4, S11, S22;

	 
	 add8_c a0(n1, n2, S1, );
	 add8_c a1(n3, n4, S2, );
	 add8_c a2(n5, n6, S3, );
	 add8_c a3(n7, n8, S4, );
	 
	 add8_c a00(S1, S2, S11, );
	 add8_c a11(S3, S4, S22, );
	 
	 add8_c a000(S11, S22, S, );

endmodule
