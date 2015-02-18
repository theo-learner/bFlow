module test(input CLK, input reset, // initialize registers                
    input[3:0] Din, // Data input for load
    output reg [7:0] Dout);
 
  reg [3:0] D0, D1, D2, D3; 
  
  always @(posedge CLK) begin
    if (reset) begin
      D0 <= 0; D1 <= 0; D2 <= 0; D3 <= 0;
    end else begin
      D3 <= Din; D2 <= D3; D1 <= D2; D0 <= D1; 
      Dout<=  (D0*2) +  (D1*4) +  (D2*6) +  (D3*8); 
    end 
  end 
  
endmodule
// fir 

