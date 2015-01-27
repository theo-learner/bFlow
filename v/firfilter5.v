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
//3-point averager
//////////////////////////////////////////////////////////////////////////////////
module firfilter5(input CLK, input reset, // initialize registers                
    input[7:0] Din, // Data input for load
    output reg [7:0] Dout);

  reg [7:0] D3, D1, D2; 
  
  always @(posedge CLK) begin
    if (reset) begin
      D3 <= 0; D1 <= 0; D2 <= 0;
    end else begin
      D3 <= Din; D2 <= D3; D1 <= D2; 
      Dout<= ( (D1) +  (D2) +  (D3))/3; 
    end 
  end 
  
endmodule
