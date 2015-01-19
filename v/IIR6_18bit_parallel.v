///////////////////////////////////////////////////////////////////
/// Sixth order IIR filter ///////////////////////////////////////
///////////////////////////////////////////////////////////////////
module IIR6_18bit_parallel (audio_out, audio_in, 
			scale, 
			b1, b2, b3, b4, b5, b6, b7,
			a2, a3, a4, a5, a6, a7,
			state_clk, lr_clk, reset) ;
// The filter is a "Direct Form II Transposed"
// 
//    a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
//                          - a(2)*y(n-1) - ... - a(na+1)*y(n-na)
// 
//    If a(1) is not equal to 1, FILTER normalizes the filter
//    coefficients by a(1). 
//
// one audio sample, 16 bit, 2's complement
output wire signed [15:0] audio_out ;
// one audio sample, 16 bit, 2's complement
input wire signed [15:0] audio_in ;
// shift factor for output
input wire [2:0] scale ;
// filter coefficients
input wire signed [17:0] b1, b2, b3, b4, b5, b6, b7, a2, a3, a4, a5, a6, a7 ;
input wire state_clk, lr_clk, reset ;

/// filter vars //////////////////////////////////////////////////
wire signed [17:0] b1_in, b2_in, b3_in, b4_in, b5_in, b6_in, b7_in ;
wire signed [17:0] a2_out, a3_out, a4_out, a5_out, a6_out, a7_out ;

// history pipeline regs
reg signed [17:0] f1_n1, f1_n2, f1_n3, f1_n4, f1_n5, f1_n6 ; 
// history pipeline inputs
wire signed [17:0] f1_n1_input, f1_n2_input, f1_n3_input, 
					f1_n4_input, f1_n5_input, f1_n6_input, f1_n0 ; 

// convert input to 18-bits and mult by filter coeff
signed_mult b1in (b1_in, b1, {audio_in, 2'b0});
signed_mult b2in (b2_in, b2, {audio_in, 2'b0});
signed_mult b3in (b3_in, b3, {audio_in, 2'b0});
signed_mult b4in (b4_in, b4, {audio_in, 2'b0});
signed_mult b5in (b5_in, b5, {audio_in, 2'b0});
signed_mult b6in (b6_in, b6, {audio_in, 2'b0});
signed_mult b7in (b7_in, b7, {audio_in, 2'b0});
signed_mult a2out (a2_out, a2, f1_n0);
signed_mult a3out (a3_out, a3, f1_n0);
signed_mult a4out (a4_out, a4, f1_n0);
signed_mult a5out (a5_out, a5, f1_n0);
signed_mult a6out (a6_out, a6, f1_n0);
signed_mult a7out (a7_out, a7, f1_n0);

// add operations
assign f1_n1_input = b2_in + f1_n2 + a2_out ;
assign f1_n2_input = b3_in + f1_n3 + a3_out ;
assign f1_n3_input = b4_in + f1_n4 + a4_out ;
assign f1_n4_input = b5_in + f1_n5 + a5_out ;
assign f1_n5_input = b6_in + f1_n6 + a6_out ;
assign f1_n6_input = b7_in + a7_out ;

// scale the output and turncate for audio codec
assign f1_n0 = (f1_n1 + b1_in) << scale ;
assign audio_out = f1_n0[17:2] ;

///////////////////////////////////////////////////////////////////

//Run the filter state machine at audio sample rate
//audio cycle
always @ (posedge lr_clk) 
begin
	if (reset)
	begin
		f1_n1 <= 0;
		f1_n2 <= 0;	
		f1_n3 <= 0;
		f1_n4 <= 0;
		f1_n5 <= 0;
		f1_n6 <= 0;	
	end

	else 
	begin
		f1_n1 <= f1_n1_input ;
		f1_n2 <= f1_n2_input ;	
		f1_n3 <= f1_n3_input ;
		f1_n4 <= f1_n4_input ;
		f1_n5 <= f1_n5_input ;
		f1_n6 <= f1_n6_input ;		
	end
end	
endmodule
///////////////////////////////////////////////////
//// signed mult of 2.16 format 2'comp ////////////
///////////////////////////////////////////////////
module signed_mult (out, a, b);

	output 		[17:0]	out;
	input 	signed	[17:0] 	a;
	input 	signed	[17:0] 	b;
	
	wire	signed	[17:0]	out;
	wire 	signed	[35:0]	mult_out;

	assign mult_out = a * b;
	//FilterMult m1(a, b, mult_out) ;
	//assign out = mult_out[33:17];
	assign out = {mult_out[35], mult_out[32:16]};
endmodule
/////////////////////////////////////////////////
