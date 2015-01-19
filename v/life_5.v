module life_5(input self, input [7:0] n,
	output reg out);

	wire[7:0] count;

	assign count = n[0] + n[1] + n[2] + n[3] + n[4] + n[5] + n[6] + n[7];

	assign out = (count == 3) ? 1'b1 : (self == 1) ? (count == 2): 1'b0;


endmodule
