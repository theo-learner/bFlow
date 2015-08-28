`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:53:24 11/20/2014 
// Design Name: 
// Module Name:    prewitt 
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
module sobel_t7(p0, p1, p2, p3, p5, p6, p7, p8, out);

input  [7:0] p0,p1,p2,p3,p5,p6,p7,p8;	// 8 bit pixels inputs 
output [7:0] out;					// 8 bit output pixel 

wire signed [10:0] gx,gy;    //11 bits because max value of gx and gy is  
wire signed [10:0] gx1,gx2,gx3, gy1, gy2, gy3;    //11 bits because max value of gx and gy is  
//255*4 and last bit for sign					 
wire signed [10:0] abs_gx,abs_gy;	//it is used to find the absolute value of gx and gy 
wire [10:0] sum;			//the max value is 255*8. here no sign bit needed. 

assign gx1=(p2-p0);//sobel mask for gradient in horiz. direction 
assign gx2=((p5-p3)<<1);//sobel mask for gradient in horiz. direction 
assign gx3=(p8-p6);//TODO:T1 //sobel mask for gradient in horiz. direction 
assign gy1=(p0-p6);//TODO:T2 sobel mask for gradient in vertical direction 
assign gy2=((p1-p7)<<1);//sobel mask for gradient in vertical direction 
assign gy3=(p2-p8);//TODO:T3 sobel mask for gradient in vertical direction 

assign gx=(gx1+gx2+gx3);//TODO:T4 sobel mask for gradient in horiz. direction 
assign gy=(gy1+gy2+gy3);//sobel mask for gradient in vertical direction 

assign abs_gx = (gx[10]? ~gx+1 : gx);	//TODO:T5 to find the absolute value of gx. 
assign abs_gy = (gy[10]? ~gy+1 : gy);	// to find the absolute value of gy. 

assign sum = (abs_gx+abs_gy);				//TODO:T6 finding the sum 

assign out = (sum[10:8] > 8'hff) ? 8'hff : sum[7:0];	// to limit the max value to 255  
//assign out = (|sum[10:8])?8'hff : sum[7:0];	// to limit the max value to 255  

endmodule



