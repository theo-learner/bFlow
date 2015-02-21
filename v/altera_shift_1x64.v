module altera_shift_1x64 (clk, 
		  	shift,
			sr_in,
			sr_out,
		   );
  
	input clk, shift;
	input sr_in;
	output sr_out;

	reg [63:0] sr;

	always@(posedge clk)
	begin
		if (shift == 1'b1)
		begin
			sr[63:1] <= sr[62:0];
			sr[0] <= sr_in;
		end
	end
	
	assign sr_out = sr[63];

endmodule
