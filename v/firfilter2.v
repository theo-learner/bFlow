`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:58:23 11/17/2014 
// Design Name: 
// Module Name:    firfilter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module firfilter2(input CLK, input reset, // initialize registers                
    input[7:0] Din, // Data input for load
    output reg [7:0] Dout);

  reg [7:0] D0, D1, D2, D3; 
  
  always @(posedge CLK) begin
    if (reset) begin
      D0 <= 0; D1 <= 0; D2 <= 0; D3 <= 0;
    end else begin
      D3 <= Din; D2 <= D3; D1 <= D2; D0 <= D1; 
      Dout<=  (D0*1) +  (D1*2) +  (D2*3) +  (D3*4); 
    end 
  end 
  
endmodule
// fir 

