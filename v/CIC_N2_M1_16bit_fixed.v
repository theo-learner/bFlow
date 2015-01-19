///////////////////////////////////////////////////////////////////
/// CIC N=2 M=1 filter ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
module CIC_N2_M1_16bit_fixed (audio_out, rf_in, 
			rf_clk, lr_clk, reset) ;
// The filter is a 
// double integrator/comb CIC filter
//
// one audio sample, 16 bit, 2's complement
output reg signed [15:0] audio_out ;
input signed [15:0] rf_in ;
input wire rf_clk, lr_clk, reset ;

reg signed [39:0] integrator1, comb1 ; //[39:0]
reg signed [39:0] integrator2, comb2, temp_int2 ;
wire signed [39:0] running_sum1, running_sum2  ;

always @(posedge rf_clk)
begin
	if (reset)
	begin
		integrator1 <= 40'd0 ;
		integrator2 <= 40'd0 ;
	end
	else
	begin
		integrator1 <= integrator1 + { {24{rf_in[15]}}, rf_in} ;
		integrator2 <= integrator2 + integrator1 ;
	end
end

always @(posedge lr_clk)
begin
	temp_int2 <= integrator2 ;
	comb1 <=  temp_int2 ;
	comb2 <= running_sum1 ;
	audio_out <= running_sum2[35:20]; 
end

assign running_sum1 = temp_int2 - comb1 ;
assign running_sum2 = running_sum1 - comb2 ;
 
endmodule
