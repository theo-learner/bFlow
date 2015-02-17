module test(A, B, clk, out); 
	input A;
	input B;
	input clk;
	output out;

	assign out = A & B;     

	always@(posedge clk) begin
			
	end
endmodule
