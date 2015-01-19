///////////////////////////////////////////////////////////////////
/// CIC N=1 M=1 filter ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
module CIC_N1_M1_16bit_fixed (audio_out, rf_in, 
			rf_clk, lr_clk, reset) ;
// The filter is a 
// single integrator/comb CIC filter
//
// one audio sample, 16 bit, 2's complement
output reg signed [15:0] audio_out ;
input signed [15:0] rf_in ;
input wire rf_clk, lr_clk, reset ;

reg signed [39:0] integrator1, comb1, temp_int1 ;
wire signed [39:0] running_sum ;

// the integrator -- with sign extended input
always @(posedge rf_clk)
begin
	integrator1 <= integrator1 + { {24{rf_in[15]}}, rf_in} ;
end

// the comb
always @(posedge lr_clk)
begin
	temp_int1 <= integrator1 ;
	comb1 <=  temp_int1 ;
	// DC offset adds a bit or two to bits required at CIC filter output
	// use bits 25:10 with no offset
	// use bits 26:11 with 16'h4000 offset (1/2)
	audio_out <= running_sum[26:11]; 
end

assign running_sum = temp_int1 - comb1 ;

endmodule
