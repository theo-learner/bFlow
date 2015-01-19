//http://people.ece.cornell.edu/land/courses/ece5760/DE2/AudioFilter_oct2009/AudioFilter_oct2009/Audio_Filter_18bit_float.v

///////////////////////////////////////////////////////////////////
/// Sixth order IIR filter -- written as 3 SOS ////////////////////
///////////////////////////////////////////////////////////////////
module IIR6sos_18bit_fp (audio_out, audio_in,  
			b11, b12, b13, 
			a12, a13, 
			b21, b22, b23, 
			a22, a23,
			b31, b32, b33, 
			a32, a33, 
			gain, 
			state_clk, lr_clk, reset) ;
// The filter is a "Direct Form II Transposed"
// but is factored into two second order filters and a gain
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

// filter coefficients
input wire [17:0] b11, b12, b13, a12, a13, 
                  b21, b22, b23, a22, a23, 
                  b31, b32, b33, a32, a33,
                  gain ;
input wire state_clk, lr_clk, reset ;

/// filter vars //////////////////////////////////////////////////
wire [17:0] f_mac_new, f_coeff_x_value ;
reg [17:0] f_coeff, f_mac_old, f_value ;

// input to filters
reg [17:0] x1_n, x2_n, x3_n ;
// input history x(n-1), x(n-2)
reg [17:0] x1_n1, x1_n2, x2_n1, x2_n2, x3_n1, x3_n2 ; 

// output history: y_n is the new filter output, BUT it is
// immediately stored in f1_y_n1 for the next loop through 
// the filter state machine
reg [17:0] f1_y_n1, f1_y_n2, f2_y_n1, f2_y_n2, f3_y_n1, f3_y_n2 ; 

// i/o conversion
// int output of FP calc
wire [9:0] audio_out_int ;
reg [17:0] audio_out_FP ;
wire [17:0] audio_in_FP ;
int2fp f_input(audio_in_FP, audio_in[15:6], 0) ;
fp2int f_output(audio_out_int, audio_out_FP, 0) ;
assign audio_out = {audio_out_int, 6'h0} ;

// MAC operation
fpmult f_c_x_v (f_coeff_x_value, f_coeff, f_value);
fpadd f_mac_add (f_mac_new, f_mac_old, f_coeff_x_value) ;

// state variable 
reg [4:0] state ;
//oneshot gen to sync to audio clock
reg last_clk ; 
///////////////////////////////////////////////////////////////////

//Run the filter state machine FAST so that it completes in one 
//audio cycle
always @ (posedge state_clk) 
begin
	if (reset)
	begin
		state <= 5'd31 ; //turn off the state machine	
	end
	
	else begin
		case (state)
	
			1: 
			begin
				// set up b11*x(n)
				f_mac_old <= 18'd0 ;
				f_coeff <= b11 ;
				f_value <= audio_in_FP ;				
				//register input
				x1_n <= audio_in_FP ;				
				// next state
				state <= 4'd2;
			end
	
			2: 
			begin
				// set up b12*x(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b12 ;
				f_value <= x1_n1 ;				
				// next state
				state <= 4'd3;
			end
			
			3:
			begin
				// set up b13*x(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b13 ;
				f_value <= x1_n2 ;
				// next state
				state <= 4'd4;
			end
			
			4:
			begin
				// set up a12*y(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a12 ;
				f_value <= f1_y_n1 ;
				// next state
				state <= 4'd5;
			end
			
			5:
			begin
				// set up a13*y(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a13 ;
				f_value <= f1_y_n2 ;
				// next state
				state <= 4'd6;
			end
			
			6: 
			begin
				// get the output of the first SOS
				// and put it in the LAST output var
				// for the next pass thru the state machine
				f1_y_n1 <= f_mac_new ; 
				// link first SOS to second SOS
				x2_n <= f_mac_new ;				
				// update output history
				f1_y_n2 <= f1_y_n1 ;			
				// update input history
				x1_n1 <= x1_n ;
				x1_n2 <= x1_n1 ;
				//next state 
				state <= 4'd8;
			end
			
			8: 
			begin
				// set up b21*x(n)
				f_mac_old <= 18'd0 ;
				f_coeff <= b21 ;
				f_value <= x2_n ;								
				// next state
				state <= 4'd9;
			end
	
			9: 
			begin
				// set up b22*x(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b22 ;
				f_value <= x2_n1 ;				
				// next state
				state <= 4'd10;
			end
			
			10:
			begin
				// set up b23*x(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b23 ;
				f_value <= x2_n2 ;
				// next state
				state <= 4'd11;
			end
			
			11:
			begin
				// set up a22*y(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a22 ;
				f_value <= f2_y_n1 ;
				// next state
				state <= 4'd12;
			end
			
			12:
			begin
				// set up a23*y(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a23 ;
				f_value <= f2_y_n2 ;
				// next state
				state <= 4'd13;
			end
			
			13: 
			begin
				// get the output 
				// and put it in the LAST output var
				// for the next pass thru the state machine
				f2_y_n1 <= f_mac_new ; 
				// link to next section
				x3_n <= f_mac_new ;				
				// update output history
				f2_y_n2 <= f2_y_n1 ;			
				// update input history
				x2_n1 <= x2_n ;
				x2_n2 <= x2_n1 ;
				//next state 
				state <= 4'd14;
			end
			
			14: 
			begin
				// set up b31*x(n)
				f_mac_old <= 18'd0 ;
				f_coeff <= b31 ;
				f_value <= x3_n ;								
				// next state
				state <= 5'd15;
			end
	
			15: 
			begin
				// set up b32*x(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b32 ;
				f_value <= x3_n1 ;				
				// next state
				state <= 5'd16;
			end
			
			16:
			begin
				// set up b33*x(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= b33 ;
				f_value <= x3_n2 ;
				// next state
				state <= 5'd17;
			end
			
			17:
			begin
				// set up a32*y(n-1) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a32 ;
				f_value <= f3_y_n1 ;
				// next state
				state <= 5'd18;
			end
			
			18:
			begin
				// set up a33*y(n-2) 
				f_mac_old <= f_mac_new ;
				f_coeff <= a33 ;
				f_value <= f3_y_n2 ;
				// next state
				state <= 5'd19;
			end
			
			19: 
			begin
				// get the output 
				// and put it in the LAST output var
				// for the next pass thru the state machine
				f3_y_n1 <= f_mac_new ; 
				// apply the final gain mult
				f_value <= f_mac_new ;
				f_coeff <= gain ;				
				// update output history
				f3_y_n2 <= f3_y_n1 ;			
				// update input history
				x3_n1 <= x3_n ;
				x3_n2 <= x3_n1 ;
				//next state 
				state <= 5'd20;
			end
			
			20:
			begin
				audio_out_FP <= f_coeff_x_value ;
				//next state 
				state <= 5'd31;
			end
			
			31:
			begin
				// wait for the audio clock and one-shot it
				if (lr_clk && last_clk==1)
				begin
					state <= 5'd1 ;
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
				state <= 5'd31 ;
			end
		endcase
	end
end	

endmodule

//////////////////////////////////////////////////////////
// floating point multiply 
// -- sign bit -- 8-bit exponent -- 9-bit mantissa
// Similar to fp_mult from altera
// NO denorms, no flags, no NAN, no infinity, no rounding!
//////////////////////////////////////////////////////////
// f1 = {s1, e1, m1), f2 = {s2, e2, m2)
// If either is zero (zero MSB of mantissa) then output is zero
// If e1+e2<129 the result is zero (underflow)
///////////////////////////////////////////////////////////	
module fpmult (fout, f1, f2);

	input [17:0] f1, f2 ;
	output [17:0] fout ;
	
	wire [17:0] fout ;
	reg sout ;
	reg [8:0] mout ;
	reg [8:0] eout ; // 9-bits for overflow
	
	wire s1, s2;
	wire [8:0] m1, m2 ;
	wire [8:0] e1, e2, sum_e1_e2 ; // extend to 9 bits to avoid overflow
	wire [17:0] mult_out ;	// raw multiplier output
	
	// parse f1
	assign s1 = f1[17]; 	// sign
	assign e1 = {1'b0, f1[16:9]};	// exponent
	assign m1 = f1[8:0] ;	// mantissa
	// parse f2
	assign s2 = f2[17];
	assign e2 = {1'b0, f2[16:9]};
	assign m2 = f2[8:0] ;
	
	// first step in mult is to add extended exponents
	assign sum_e1_e2 = e1 + e2 ;
	
	// build output
	// raw integer multiply
	unsigned_mult mm(mult_out, m1, m2);
	 
	// assemble output bits
	assign fout = {sout, eout[7:0], mout} ;
	
	always @(*)
	begin
		// if either is denormed or exponents are too small
		if ((m1[8]==1'd0) || (m2[8]==1'd0) || (sum_e1_e2 < 9'h82)) 
		begin 
			mout = 0;
			eout = 0;
			sout = 0; // output sign
		end
		else // both inputs are nonzero and no exponent underflow
		begin
			sout = s1 ^ s2 ; // output sign
			if (mult_out[17]==1)
			begin // MSB of product==1 implies normalized -- result >=0.5
				eout = sum_e1_e2 - 9'h80;
				mout = mult_out[17:9] ;
			end
			else // MSB of product==0 implies result <0.5, so shift ome left
			begin
				eout = sum_e1_e2 - 9'h81;
				mout = mult_out[16:8] ;
			end	
		end // nonzero mult logic
	end // always @(*)
	
endmodule

///////////////////////////////////////
// low level integer multiply
// From Altera HDL style manual
///////////////////////////////////////
module unsigned_mult (out, a, b);
	output [17:0] out;
	input [8:0] a;
	input [8:0] b;
	assign out = a * b;
endmodule


/////////////////////////////////////////////////////////////////////////////
// floating point Add 
// -- sign bit -- 8-bit exponent -- 9-bit mantissa
// NO denorms, no flags, no NAN, no infinity, no rounding!
/////////////////////////////////////////////////////////////////////////////
// f1 = {s1, e1, m1), f2 = {s2, e2, m2)
// If either input is zero (zero MSB of mantissa) then output is the remaining input.
// If either input is <(other input)/2**9 then output is the remaining input.
// Sign of the output is the sign of the greater magnitude input
// Add the two inputs if their signs are the same. 
// Subtract the two inputs (bigger-smaller) if their signs are different
//////////////////////////////////////////////////////////////////////////////	
module fpadd (fout, f1, f2);

	input [17:0] f1, f2 ;
	output [17:0] fout ;
	
	wire  [17:0] fout ;
	wire sout ;
	reg [8:0] mout ;
	reg [7:0] eout ;
	reg [9:0] shift_small, denorm_mout ; //9th bit is overflow bit
	
	wire s1, s2 ; // input signs
	reg  sb, ss ; // signs of bigger and smaller
	wire [8:0] m1, m2 ; // input mantissas
	reg  [8:0] mb, ms ; // mantissas of bigger and smaller
	wire [7:0] e1, e2 ; // input exp
	wire [7:0] ediff ;  // exponent difference
	reg  [7:0] eb, es ; // exp of bigger and smaller
	reg  [7:0] num_zeros ; // high order zeros in the difference calc
	
	// parse f1
	assign s1 = f1[17]; 	// sign
	assign e1 = f1[16:9];	// exponent
	assign m1 = f1[8:0] ;	// mantissa
	// parse f2
	assign s2 = f2[17];
	assign e2 = f2[16:9];
	assign m2 = f2[8:0] ;
	
	// find biggest magnitude
	always @(*)
	begin
		if (e1>e2) // f1 is bigger
		begin
			sb = s1 ; // the bigger number (absolute value)
			eb = e1 ;
			mb = m1 ;
			ss = s2 ; // the smaller number
			es = e2 ;
			ms = m2 ;
		end
		else if (e2>e1) //f2 is bigger
		begin
			sb = s2 ; // the bigger number (absolute value)
			eb = e2 ;
			mb = m2 ;
			ss = s1 ; // the smaller number
			es = e1 ;
			ms = m1 ;
		end
		else // e1==e2, so need to look at mantissa to determine bigger/smaller
		begin
			if (m1>m2) // f1 is bigger
			begin
				sb = s1 ; // the bigger number (absolute value)
				eb = e1 ;
				mb = m1 ;
				ss = s2 ; // the smaller number
				es = e2 ;
				ms = m2 ;
			end
			else // f2 is bigger or same size
			begin
				sb = s2 ; // the bigger number (absolute value)
				eb = e2 ;
				mb = m2 ;
				ss = s1 ; // the smaller number
				es = e1 ;
				ms = m1 ;
			end
		end
	end //found the bigger number
	
	// sign of output is the sign of the bigger (magnitude) input
	assign sout = sb ;
	// form the output
	assign fout = {sout, eout, mout} ;	
	
	// do the actual add:
	// -- equalize exponents
	// -- add/sub
	// -- normalize
	assign ediff = eb - es ; // the actual difference in exponents
	always @(*)
	begin
		if ((ms[8]==0) && (mb[8]==0))  // both inputs are zero
		begin
			mout = 9'b0 ;
			eout = 8'b0 ; 
		end
		else if ((ms[8]==0) || ediff>8)  // smaller is too small to matter
		begin
			mout = mb ;
			eout = eb ;
		end
		else  // shift/add/normalize
		begin
			// now shift but save the low order bits by extending the registers
			// need a high order bit for 1.0<sum<2.0
			shift_small = {1'b0, ms} >> ediff ;
			// same signs means add -- different means subtract
			if (sb==ss) //do the add
			begin
				denorm_mout = {1'b0, mb} + shift_small ;
				// normalize --
				// when adding result has to be 0.5<sum<2.0
				if (denorm_mout[9]==1) // sum bigger than 1
				begin
					mout = denorm_mout[9:1] ; // take the top bits (shift-right)
					eout = eb + 1 ; // compensate for the shift-right
				end
				else //0.5<sum<1.0
				begin
					mout = denorm_mout[8:0] ; // drop the top bit (no-shift-right)
					eout = eb ; // 
				end
			end // end add logic
			else // otherwise sb!=ss, so subtract
			begin
				denorm_mout = {1'b0, mb} - shift_small ;
				// the denorm_mout is always smaller then the bigger input
				// (and never an overflow, so bit 9 is always zero)
				// and can be as low as zero! Thus up to 8 shifts may be necessary
				// to normalize denorm_mout
				if (denorm_mout[8:0]==9'd0)
				begin
					mout = 9'b0 ;
					eout = 8'b0 ;
				end
				else
				begin
					// detect leading zeros
					casex (denorm_mout[8:0])
						9'b1xxxxxxxx: num_zeros = 8'd0 ;
						9'b01xxxxxxx: num_zeros = 8'd1 ;
						9'b001xxxxxx: num_zeros = 8'd2 ;
						9'b0001xxxxx: num_zeros = 8'd3 ;
						9'b00001xxxx: num_zeros = 8'd4 ;
						9'b000001xxx: num_zeros = 8'd5 ;
						9'b0000001xx: num_zeros = 8'd6 ;
						9'b00000001x: num_zeros = 8'd7 ;
						9'b000000001: num_zeros = 8'd8 ;
						default:       num_zeros = 8'd9 ;
					endcase	
					// shift out leading zeros
					// and adjust exponent
					eout = eb - num_zeros ;
					mout = denorm_mout[8:0] << num_zeros ;
				end
			end // end subtract logic
			// format the output
			//fout = {sout, eout, mout} ;	
		end // end shift/add(sub)/normailize/
	end // always @(*) to compute sum/diff	
endmodule 

/////////////////////////////////////////////////////////////////////////////
// integer to floating point  
// input: 10-bit signed integer and scale factor (-100 to +100) powers of 2
// output: -- sign bit -- 8-bit exponent -- 9-bit mantissa 
// fp_out = {sign, exp, mantissa}
// NO denorms, no flags, no NAN, no infinity, no rounding!
/////////////////////////////////////////////////////////////////////////////
module int2fp(fp_out, int_in, scale_in) ;
	input signed  [9:0] int_in ;
	input signed  [7:0] scale_in ;
	output wire [17:0] fp_out ; 
	
	wire [9:0] abs_int ;
	reg sign ;
	reg [8:0] mout ; // mantissa
	reg [7:0] eout ; // exponent
	reg [7:0] num_zeros ; // count leading zeros in input integer
	
	// get absolute value of int_in
	assign abs_int = (int_in[9])? (~int_in)+10'd1 : int_in ;
	
	// build output
	assign fp_out = {sign, eout, mout} ;
	 
	// detect leading zeros of absolute value
	// detect leading zeros
	// normalize and form exponent including leading zero shift and scaling
	always @(*)
	begin
		if (abs_int[8:0] == 0)
		begin // zero value
			eout = 0 ;
			mout = 0 ;
			sign = 0 ;
			num_zeros = 8'd0 ;
		end 
		else // not zero
		begin
			casex (abs_int[8:0])
				9'b1xxxxxxxx: num_zeros = 8'd0 ;
				9'b01xxxxxxx: num_zeros = 8'd1 ;
				9'b001xxxxxx: num_zeros = 8'd2 ;
				9'b0001xxxxx: num_zeros = 8'd3 ;
				9'b00001xxxx: num_zeros = 8'd4 ;
				9'b000001xxx: num_zeros = 8'd5 ;
				9'b0000001xx: num_zeros = 8'd6 ;
				9'b00000001x: num_zeros = 8'd7 ;
				9'b000000001: num_zeros = 8'd8 ;
				default:       num_zeros = 8'd9 ;
			endcase 
			mout = abs_int[8:0] << num_zeros ; 
			eout = scale_in + (8'h89 - num_zeros) ; // h80 is offset, h09 normalizes
			sign = int_in[9] ;
		end // if int_in!=0
	end // always @
	
endmodule

/////////////////////////////////////////////////////////////////////////////
// floating point to integer 
// output: 10-bit signed integer 
// input: -- sign bit -- 8-bit exponent -- 9-bit mantissa 
// and scale factor (-100 to +100) powers of 2
// fp_out = {sign, exp, mantissa}
// NO denorms, no flags, no NAN, no infinity, no rounding!
/////////////////////////////////////////////////////////////////////////////
module fp2int(int_out, fp_in, scale_in) ;
	output signed  [9:0] int_out ;
	input signed  [7:0] scale_in ;
	input wire [17:0] fp_in ; 
	
	wire [9:0] abs_int ;
	wire sign ;
	wire [8:0] m_in ; // mantissa
	wire [7:0] e_in ; // exponent
	
	//reg [7:0] num_zeros ; // count leading zeros in input integer
	
	assign sign = (m_in[8])? fp_in[17] : 1'h0 ;
	assign m_in = fp_in[8:0] ;
	assign e_in = fp_in[16:9] ;
	//
	assign abs_int = (e_in>8'h80)? (m_in >> (8'h89 - e_in)) : 10'd0 ;
	//assign int_out = (m_in[8])? {sign, (sign? (~abs_int)+9'd1 : abs_int)} : 10'd0 ;
	
	assign int_out = (sign? (~abs_int)+10'd1 : abs_int)  ;
	//assign int_out = {sign, sign? (~abs_int)+9'd1 : abs_int}  ;
endmodule
/////////////////////////////////////////////////////////////////////////////
