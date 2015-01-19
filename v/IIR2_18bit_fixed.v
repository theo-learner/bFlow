//http://people.ece.cornell.edu/land/courses/ece5760/DE2/AudioFilter_oct2009/AudioFilter_oct2009/Audio_Filter_18bit_fixed.v

///////////////////////////////////////////////////////////////////
/// Second order IIR filter ///////////////////////////////////////
///////////////////////////////////////////////////////////////////
module IIR2_18bit_fixed (audio_out, audio_in, 
			scale, 
			b1, b2, b3, 
			a2, a3, 
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
output reg signed [15:0] audio_out ;
// one audio sample, 16 bit, 2's complement
input wire signed [15:0] audio_in ;
// shift factor for output
input wire [2:0] scale ;
// filter coefficients
input wire signed [17:0] b1, b2, b3, a2, a3 ;
input wire state_clk, lr_clk, reset ;

/// filter vars //////////////////////////////////////////////////
wire signed [17:0] f1_mac_new, f1_coeff_x_value ;
reg signed [17:0] f1_coeff, f1_mac_old, f1_value ;

// input to filter
reg signed [17:0] x_n ;
// input history x(n-1), x(n-2)
reg signed [17:0] x_n1, x_n2 ; 

// output history: y_n is the new filter output, BUT it is
// immediately stored in f1_y_n1 for the next loop through 
// the filter state machine
reg signed [17:0] f1_y_n1, f1_y_n2 ; 

// MAC operation
signed_mult f1_c_x_v (f1_coeff_x_value, f1_coeff, f1_value);
assign f1_mac_new = f1_mac_old + f1_coeff_x_value ;

// state variable 
reg [3:0] state ;
//oneshot gen to sync to audio clock
reg last_clk ; 
///////////////////////////////////////////////////////////////////

//Run the filter state machine FAST so that it completes in one 
//audio cycle
always @ (posedge state_clk) 
begin
	if (reset)
	begin
		state <= 4'd15 ; //turn off the state machine	
	end
	
	else begin
		case (state)
	
			1: 
			begin
				// set up b1*x(n)
				f1_mac_old <= 18'd0 ;
				f1_coeff <= b1 ;
				f1_value <= {audio_in, 2'b0} ;				
				//register input
				x_n <= {audio_in, 2'b0} ;				
				// next state
				state <= 4'd2;
			end
	
			2: 
			begin
				// set up b2*x(n-1) 
				f1_mac_old <= f1_mac_new ;
				f1_coeff <= b2 ;
				f1_value <= x_n1 ;				
				// next state
				state <= 4'd3;
			end
			
			3:
			begin
				// set up b3*x(n-2) 
				f1_mac_old <= f1_mac_new ;
				f1_coeff <= b3 ;
				f1_value <= x_n2 ;
				// next state
				state <= 4'd6;
			end
						
			6: 
			begin
				// set up -a2*y(n-1) 
				f1_mac_old <= f1_mac_new ;
				f1_coeff <= a2 ;
				f1_value <= f1_y_n1 ; 
				//next state 
				state <= 4'd7;
			end
			
			7: 
			begin
				// set up -a3*y(n-2) 
				f1_mac_old <= f1_mac_new ;
				f1_coeff <= a3 ;
				f1_value <= f1_y_n2 ; 				
				//next state 
				state <= 4'd10;
			end
			
			10: 
			begin
				// get the output 
				// and put it in the LAST output var
				// for the next pass thru the state machine
				//mult by four because of coeff scaling
				// to prevent overflow
				f1_y_n1 <= f1_mac_new<<scale ; 
				audio_out <= f1_y_n1[17:2] ;				
				// update output history
				f1_y_n2 <= f1_y_n1 ;				
				// update input history
				x_n1 <= x_n ;
				x_n2 <= x_n1 ;
				//next state 
				state <= 4'd15;
			end	
			
			15:
			begin
				// wait for the audio clock and one-shot it
				if (lr_clk && last_clk==1)
				begin
					state <= 4'd1 ;
					last_clk <= 1'h0 ;
				end
				// reset the one-shot memory
				else if (~lr_clk && last_clk==0)
				begin
					last_clk <= 1'h1 ;				
				end	
			end
			
			default:
			begin
				// default state is end state
				state <= 4'd15 ;
			end
		endcase
	end
end	

endmodule
//////////////////////////////////////////////////
//// signed mult of 3.24 format 2'comp////////////
//////////////////////////////////////////////////
module signed_mult (out, a, b);
	output 		[26:0]	out;
	input 	signed	[26:0] 	a;
	input 	signed	[26:0] 	b;
	wire	signed	[26:0]	out;
	wire 	signed	[53:0]	mult_out;
	assign mult_out = a * b;
	assign out = {mult_out[53], mult_out[49:24]};
endmodule
//////////////////////////////////////////////////

