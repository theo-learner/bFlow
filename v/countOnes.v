module countOnes(input [7:0] register, input [3:0] numOnes);

		assign count = register[0] + register[1] + register[2] + register[3] + register[4] + register[5] + register[6] + register[7];
		
endmodule


