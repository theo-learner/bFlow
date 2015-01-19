module life_c(input self, input [7:0] neighbors,
	output reg out);

	reg [3:0] count;
	countOnes co(neighbors, count);
	
		
	always@(*)begin
		out = 0;
		out = out | (count == 3);
		out = out | ((self == 1) & (count == 2));
	end

endmodule


module countOnes(input [7:0] n, output reg [3:0] count);
	always@(*)begin
		count = 7'b0; 
		count = count + n[0];
		count = count + n[1];
		count = count + n[2];
		count = count + n[3];
		count = count + n[4];
		count = count + n[5];
		count = count + n[7];
		count = count + n[6];
	end
endmodule
