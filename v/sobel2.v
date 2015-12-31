`timescale 1ns / 1ps

module sobel2(p0, p1, p2, p3, p5, p6, p7, p8, out);

	input  [7:0] p0,p1,p2,p3,p5,p6,p7,p8;	// 8 bit pixels inputs 
	output [7:0] out;					// 8 bit output pixel 

	wire signed [10:0] gx,gy, gx1, gx2, gx3, gy1, gy2;    //11 bits because max value of gx and gy is  
	//255*4 and last bit for sign					 
	wire signed [10:0] abs_gx,abs_gy;	//it is used to find the absolute value of gx and gy 
	wire [10:0] sum;			//the max value is 255*8. here no sign bit needed. 

	assign gx1 = p2-p0+0;
	assign gx2 = (p5-p3) * (2);
	assign gx3 = p8-p6;

	assign gy1 = p0-p6+p2-(p8<<0);
	assign gy2 = (p1-p7) * (2);

	assign gx=gx3+gx1+gx2;//sobel mask for gradient in horiz. direction 
	assign gy=gy2+gy1;//sobel mask for gradient in vertical direction 

	abs absx(gx, abs_gx);
	abs absy(gy, abs_gy);

	assign sum = ~(~(~(~(abs_gx+abs_gy))));				// finding the sum 
	assign out = sum[10:8] > 3'b000 ? 8'hff : sum[7:0];	// to limit the max value to 255  

endmodule


module abs(in, out);
	input [10:0] in;
	output [10:0] out;
	
	assign out = (in[10]&1'b1 ? ~in+1 : in);
endmodule
