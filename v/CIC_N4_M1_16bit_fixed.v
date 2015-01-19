///////////////////////////////////////////////////////////////////
/// CIC N=4 M=1 filter ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
module CIC_N4_M1_16bit_fixed (audio_out, rf_in, 
			rf_clk, lr_clk, reset) ;
// The filter is a 
// double integrator/comb CIC filter
//
// one audio sample, 16 bit, 2's complement
output reg signed [15:0] audio_out ;
input signed [15:0] rf_in ;
input wire rf_clk, lr_clk, reset ;

// reg length 16+4*log(1042) = 56 bits
reg [59:0] integrator1, comb1 ; //
reg [59:0] integrator2, comb2 ;
reg [59:0] integrator3, comb3 ;
reg [59:0] integrator4, comb4, temp_int4 ;
wire [59:0] running_sum1, running_sum2, running_sum3, running_sum4  ;

always @(posedge rf_clk)
begin
	integrator1 <= integrator1 + { {44{rf_in[15]}}, rf_in} ;
	integrator2 <= integrator2 + integrator1 ;
	integrator3 <= integrator3 + integrator2 ;
	integrator4 <= integrator4 + integrator3 ;
end

always @(posedge lr_clk)
begin
	temp_int4 <= integrator4 ;
	comb1 <=  temp_int4 ;
	comb2 <= running_sum1 ;
	comb3 <= running_sum2 ;
	comb4 <= running_sum3 ;
	audio_out <= running_sum4[54:39];
end

assign running_sum1 = temp_int4 - comb1 ;
assign running_sum2 = running_sum1 - comb2 ;
assign running_sum3 = running_sum2 - comb3 ;
assign running_sum4 = running_sum3 - comb4 ;
 
endmodule
