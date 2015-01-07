module life(input self, input [7:0] neighbors,
	output reg out);

	integer count;	
	integer i;	
		
	always@(*)begin
		count = 0;
		for(i=0;i<8;i=i+1) count = count + neighbors[i];

		out = 0;
		out = out | (count == 3);
		out = out | ((self == 1) & (count == 2));
	end

endmodule
