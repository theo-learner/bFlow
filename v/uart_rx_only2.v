//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module Name:    rxd_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// Dependencies: 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module uart_rx_only2(  input rst, input clk,input rxd,output reg [7:0] dout, output reg ready  );
  reg load;
  parameter st0 = 4'd0;
  parameter st1 = 4'd1;
  parameter st2 = 4'd2;
  // start condition detector
  reg tdr;
  always @(posedge clk)
  begin
  if(rst)
   tdr<=0;
  else
   tdr<=rxd;
  end
  wire start= tdr & !rxd;
  // Bud counter
  wire brc_pulse; // baud rate counter pulse
  reg [15:0] brc; // baud rate counter 
  always @(posedge clk)
  begin
  if(rst)
   brc<=0;
  else if((load==1'b1) |( brc_pulse==1'b1))
   brc<=0;
  else 
   brc<=brc+1;
  end
  assign brc_pulse=(brc==16'd27) ? 1'b1 : 1'b0;
  // counter for bit sampling
  wire w_shift;
  reg[4:0] bscnt; // middle of bit sampling counter
  always @(posedge clk)
  begin
  if(rst)
   bscnt<=0;
  else if((bscnt==16'd16) | (load==1'b1))
   bscnt<=0;
  else if (brc_pulse==1'b1)
   bscnt<=bscnt+1;
  else 
  bscnt<=bscnt;
 end
 assign w_shift =(bscnt==5'd7) ? 1'b1 : 1'b0;
 reg dff;
  always @(posedge clk)
  begin
  if(rst)
   dff<=0;
  else
   dff<=w_shift;
 end
 wire shift = ~dff & w_shift;
 // serial buffer
 reg[9:0] sbuf;
 always @(posedge clk)
 begin
  if(rst)
   sbuf<=0;
  else if(shift==1'b1)
   sbuf<={rxd,sbuf[9:1]};
  else
  sbuf<=sbuf;
 end
 // Bit counter
 reg [3:0] bit_cnt;
 always @(posedge clk)
 begin
  if(rst)
   bit_cnt<=0;
  else if(load==1'b1)
   bit_cnt<=0;
  else if(shift==1'b1)
   bit_cnt<=bit_cnt+1;
  else
   bit_cnt<=bit_cnt;
 end
 //
 always @(posedge clk)
 begin
  if(rst)
   dout<=0;
  else if(ready==1'b1)
   dout<=sbuf[8:1];
  else
   dout<=dout;
 end
 // state machine
 reg[3:0] current_state,next_state;
 always @(posedge clk)
 begin
  if(rst)
   current_state<=0;
  else
   current_state<=next_state;
 end
 always @(current_state or start or bit_cnt)
 begin
  load<=0;
  ready<=0;
  case(current_state)
  st0:
  begin
   if(start==1'b1)
   next_state<=4'd1;
   else
   next_state<=4'd0;
   load<=1;
  end
  st1:
  begin
   if(bit_cnt==10)
   next_state<=4'd2;
   else
   next_state<=4'd1;
  end
  st2:
  begin
   next_state<=4'd0;
   ready<=1'b1;
  end
  default:
  begin
   next_state<=0;
   ready<=0;
   load<=0;
  end
  endcase
 end
endmodule
