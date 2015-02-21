module altera_ram_infer
(
	input [7:0] data,
	input [5:0] read_addr, write_addr,
	input we, clk,
	output reg [7:0] q
);

	// Declare the RAM variable
	reg [7:0] ram[63:0];

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[write_addr] <= data;

		// Read (if read_addr == write_addr, return OLD data).	To return
		// NEW data, use = (blocking write) rather than <= (non-blocking write)
		// in the write assignment.	 NOTE: NEW data may require extra bypass
		// logic around the RAM.
		q <= ram[read_addr];
	end

endmodule
