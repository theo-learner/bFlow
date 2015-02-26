/*
 * This source file contains a Verilog description of an IP core
 * automatically generated by the SPIRAL HDL Generator.
 *
 * This product includes a hardware design developed by Carnegie Mellon University.
 *
 * Copyright (c) 2005-2011 by Peter A. Milder for the SPIRAL Project,
 * Carnegie Mellon University
 *
 * For more information, see the SPIRAL project website at:
 *   http://www.spiral.net
 *
 * This design is provided for internal, non-commercial research use only
 * and is not for redistribution, with or without modifications.
 * 
 * You may not use the name "Carnegie Mellon University" or derivations
 * thereof to endorse or promote products derived from this software.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY WARRANTY OF ANY KIND, EITHER
 * EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANY WARRANTY
 * THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS OR BE ERROR-FREE AND ANY
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 * TITLE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
 * BE LIABLE FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT,
 * SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN
 * ANY WAY CONNECTED WITH THIS SOFTWARE (WHETHER OR NOT BASED UPON WARRANTY,
 * CONTRACT, TORT OR OTHERWISE).
 *
 */

/* Portions of this design are protected by US Patent no. 8,321,823
 * (assignee: Carnegie Mellon University).
 */

//   Input/output stream: 2 complex words per cycle
//   Throughput: one transform every 2 cycles
//   Latency: 24 cycles

//   Resources required:
//     4 multipliers (4 x 4 bit)

// Generated on Thu Feb 26 00:16:22 EST 2015

// Latency: 24 clock cycles
// Throughput: 1 transform every 2 cycles


// We use an interleaved complex data format.  X0 represents the
// real portion of the first input, and X1 represents the imaginary
// portion.  The X variables are system inputs and the Y variables
// are system outputs.

// The design uses a system of flag signals to indicate the
// beginning of the input and output data streams.  The 'next'
// input (asserted high), is used to instruct the system that the
// input stream will begin on the following cycle.

// This system has a 'gap' of 2 cycles.  This means that
// 2 cycles must elapse between the beginning of the input
// vectors.

// The output signal 'next_out' (also asserted high) indicates
// that the output vector will begin streaming out of the system
 // on the following cycle.

// The system has a latency of 24 cycles.  This means that
// the 'next_out' will be asserted 24 cycles after the user
// asserts 'next'.

// The simple testbench below will demonstrate the timing for loading
// and unloading data vectors.
// The system reset signal is asserted high.

// Please note: when simulating floating point code, you must include
// Xilinx's DSP slice simulation module.

// Latency: 24
// Gap: 2
// module_name_is:dft_top
module spiraldft_4_4_stream_jacm(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [3:0] t0_0;
   wire [3:0] t0_1;
   wire [3:0] t0_2;
   wire [3:0] t0_3;
   wire next_0;
   wire [3:0] t1_0;
   wire [3:0] t1_1;
   wire [3:0] t1_2;
   wire [3:0] t1_3;
   wire next_1;
   wire [3:0] t2_0;
   wire [3:0] t2_1;
   wire [3:0] t2_2;
   wire [3:0] t2_3;
   wire next_2;
   wire [3:0] t3_0;
   wire [3:0] t3_1;
   wire [3:0] t3_2;
   wire [3:0] t3_3;
   wire next_3;
   wire [3:0] t4_0;
   wire [3:0] t4_1;
   wire [3:0] t4_2;
   wire [3:0] t4_3;
   wire next_4;
   wire [3:0] t5_0;
   wire [3:0] t5_1;
   wire [3:0] t5_2;
   wire [3:0] t5_3;
   wire next_5;
   wire [3:0] t6_0;
   wire [3:0] t6_1;
   wire [3:0] t6_2;
   wire [3:0] t6_3;
   wire next_6;
   assign t0_0 = X0;
   assign Y0 = t6_0;
   assign t0_1 = X1;
   assign Y1 = t6_1;
   assign t0_2 = X2;
   assign Y2 = t6_2;
   assign t0_3 = X3;
   assign Y3 = t6_3;
   assign next_0 = next;
   assign next_out = next_6;

// latency=4, gap=2
   rc82717 stage0(.clk(clk), .reset(reset), .next(next_0), .next_out(next_1),
    .X0(t0_0), .Y0(t1_0),
    .X1(t0_1), .Y1(t1_1),
    .X2(t0_2), .Y2(t1_2),
    .X3(t0_3), .Y3(t1_3));


// latency=2, gap=2
   codeBlock82719 stage1(.clk(clk), .reset(reset), .next_in(next_1), .next_out(next_2),
       .X0_in(t1_0), .Y0(t2_0),
       .X1_in(t1_1), .Y1(t2_1),
       .X2_in(t1_2), .Y2(t2_2),
       .X3_in(t1_3), .Y3(t2_3));


// latency=8, gap=2
   DirSum_82976 stage2(.next(next_2), .clk(clk), .reset(reset), .next_out(next_3),
       .X0(t2_0), .Y0(t3_0),
       .X1(t2_1), .Y1(t3_1),
       .X2(t2_2), .Y2(t3_2),
       .X3(t2_3), .Y3(t3_3));


// latency=4, gap=2
   rc82980 stage3(.clk(clk), .reset(reset), .next(next_3), .next_out(next_4),
    .X0(t3_0), .Y0(t4_0),
    .X1(t3_1), .Y1(t4_1),
    .X2(t3_2), .Y2(t4_2),
    .X3(t3_3), .Y3(t4_3));


// latency=2, gap=2
   codeBlock82982 stage4(.clk(clk), .reset(reset), .next_in(next_4), .next_out(next_5),
       .X0_in(t4_0), .Y0(t5_0),
       .X1_in(t4_1), .Y1(t5_1),
       .X2_in(t4_2), .Y2(t5_2),
       .X3_in(t4_3), .Y3(t5_3));


// latency=4, gap=2
   rc83063 stage5(.clk(clk), .reset(reset), .next(next_5), .next_out(next_6),
    .X0(t5_0), .Y0(t6_0),
    .X1(t5_1), .Y1(t6_1),
    .X2(t5_2), .Y2(t6_2),
    .X3(t5_3), .Y3(t6_3));


endmodule

// Latency: 4
// Gap: 2
module rc82717(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [7:0] t0;
   wire [7:0] s0;
   assign t0 = {X0, X1};
   wire [7:0] t1;
   wire [7:0] s1;
   assign t1 = {X2, X3};
   assign Y0 = s0[7:4];
   assign Y1 = s0[3:0];
   assign Y2 = s1[7:4];
   assign Y3 = s1[3:0];

   perm82715 instPerm83232(.x0(t0), .y0(s0),
    .x1(t1), .y1(s1),
   .clk(clk), .next(next), .next_out(next_out), .reset(reset)
);



endmodule

// Latency: 4
// Gap: 2
module perm82715(clk, next, reset, next_out,
   x0, y0,
   x1, y1);
   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;

   input [width-1:0]  x0;
   output [width-1:0]  y0;
   wire [width-1:0]  ybuff0;
   input [width-1:0]  x1;
   output [width-1:0]  y1;
   wire [width-1:0]  ybuff1;
   input 	      clk, next, reset;
   output 	     next_out;

   wire    	     next0;

   reg              inFlip0, outFlip0;
   reg              inActive, outActive;

   wire [logBanks-1:0] inBank0, outBank0;
   wire [logDepth-1:0] inAddr0, outAddr0;
   wire [logBanks-1:0] outBank_a0;
   wire [logDepth-1:0] outAddr_a0;
   wire [logDepth+logBanks-1:0] addr0, addr0b, addr0c;
   wire [logBanks-1:0] inBank1, outBank1;
   wire [logDepth-1:0] inAddr1, outAddr1;
   wire [logBanks-1:0] outBank_a1;
   wire [logDepth-1:0] outAddr_a1;
   wire [logDepth+logBanks-1:0] addr1, addr1b, addr1c;


   reg [logDepth-1:0]  inCount, outCount, outCount_d, outCount_dd, outCount_for_rd_addr, outCount_for_rd_data;  

   assign    addr0 = {inCount, 1'd0};
   assign    addr0b = {outCount, 1'd0};
   assign    addr0c = {outCount_for_rd_addr, 1'd0};
   assign    addr1 = {inCount, 1'd1};
   assign    addr1b = {outCount, 1'd1};
   assign    addr1c = {outCount_for_rd_addr, 1'd1};
    wire [width+logDepth-1:0] w_0_0, w_0_1, w_1_0, w_1_1;

    reg [width-1:0] z_0_0;
    reg [width-1:0] z_0_1;
    wire [width-1:0] z_1_0, z_1_1;

    wire [logDepth-1:0] u_0_0, u_0_1, u_1_0, u_1_1;

    always @(posedge clk) begin
    end

   assign inBank0[0] = addr0[1] ^ addr0[0];
   assign inAddr0[0] = addr0[0];
   assign outBank0[0] = addr0b[1] ^ addr0b[0];
   assign outAddr0[0] = addr0b[1];
   assign outBank_a0[0] = addr0c[1] ^ addr0c[0];
   assign outAddr_a0[0] = addr0c[1];

   assign inBank1[0] = addr1[1] ^ addr1[0];
   assign inAddr1[0] = addr1[0];
   assign outBank1[0] = addr1b[1] ^ addr1b[0];
   assign outAddr1[0] = addr1b[1];
   assign outBank_a1[0] = addr1c[1] ^ addr1c[0];
   assign outAddr_a1[0] = addr1c[1];

   shiftRegFIFO #(2, 1) shiftFIFO_83235(.X(next), .Y(next0), .clk(clk));


   shiftRegFIFO #(2, 1) shiftFIFO_83238(.X(next0), .Y(next_out), .clk(clk));


   memArray4_82715 #(numBanks, logBanks, depth, logDepth, width)
     memSys(.inFlip(inFlip0), .outFlip(outFlip0), .next(next), .reset(reset),
        .x0(w_1_0[width+logDepth-1:logDepth]), .y0(ybuff0),
        .inAddr0(w_1_0[logDepth-1:0]),
        .outAddr0(u_1_0), 
        .x1(w_1_1[width+logDepth-1:logDepth]), .y1(ybuff1),
        .inAddr1(w_1_1[logDepth-1:0]),
        .outAddr1(u_1_1), 
        .clk(clk));

    reg resetOutCountRd2_2;
    reg resetOutCountRd2_3;

    always @(posedge clk) begin
        if (reset == 1) begin
            resetOutCountRd2_2 <= 0;
            resetOutCountRd2_3 <= 0;
        end
        else begin
            resetOutCountRd2_2 <= (inCount == 1) ? 1'b1 : 1'b0;
            resetOutCountRd2_3 <= resetOutCountRd2_2;
            if (resetOutCountRd2_3 == 1'b1)
                outCount_for_rd_data <= 0;
            else
                outCount_for_rd_data <= outCount_for_rd_data+1;
        end
    end
   always @(posedge clk) begin
      if (reset == 1) begin
      z_0_0 <= 0;
      z_0_1 <= 0;
         inFlip0 <= 0; outFlip0 <= 1; outCount <= 0; inCount <= 0;
        outCount_for_rd_addr <= 0;
      end
      else begin
          outCount_d <= outCount;
          outCount_dd <= outCount_d;
         if (inCount == 1)
            outCount_for_rd_addr <= 0;
         else
            outCount_for_rd_addr <= outCount_for_rd_addr+1;
      z_0_0 <= ybuff0;
      z_0_1 <= ybuff1;
         if (inCount == 1) begin
            outFlip0 <= ~outFlip0;
            outCount <= 0;
         end
         else
            outCount <= outCount+1;
         if (inCount == 1) begin
            inFlip0 <= ~inFlip0;
         end
         if (next == 1) begin
            if (inCount >= 1)
               inFlip0 <= ~inFlip0;
            inCount <= 0;
         end
         else
            inCount <= inCount + 1;
      end
   end
    assign w_0_0 = {x0, inAddr0};
    assign w_0_1 = {x1, inAddr1};
    assign y0 = z_1_0;
    assign y1 = z_1_1;
    assign u_0_0 = outAddr_a0;
    assign u_0_1 = outAddr_a1;
    wire wr_ctrl_st_0;
    assign wr_ctrl_st_0 = inCount[0];

    switch #(logDepth+width) in_sw_0_0(.x0(w_0_0), .x1(w_0_1), .y0(w_1_0), .y1(w_1_1), .ctrl(wr_ctrl_st_0));
    wire rdd_ctrl_st_0;
    assign rdd_ctrl_st_0 = outCount_for_rd_data[0];

    switch #(width) out_sw_0_0(.x0(z_0_0), .x1(z_0_1), .y0(z_1_0), .y1(z_1_1), .ctrl(rdd_ctrl_st_0));
    wire rda_ctrl_st_0;
    assign rda_ctrl_st_0 = outCount_for_rd_addr[0];

    switch #(logDepth) rdaddr_sw_0_0(.x0(u_0_0), .x1(u_0_1), .y0(u_1_0), .y1(u_1_1), .ctrl(rda_ctrl_st_0));
endmodule

module memArray4_82715(next, reset,
                x0, y0,
                inAddr0,
                outAddr0,
                x1, y1,
                inAddr1,
                outAddr1,
                clk, inFlip, outFlip);

   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;
         
   input     clk, next, reset;
   input    inFlip, outFlip;
   wire    next0;
   
   input [width-1:0]   x0;
   output [width-1:0]  y0;
   input [logDepth-1:0] inAddr0, outAddr0;
   input [width-1:0]   x1;
   output [width-1:0]  y1;
   input [logDepth-1:0] inAddr1, outAddr1;
   shiftRegFIFO #(2, 1) shiftFIFO_83241(.X(next), .Y(next0), .clk(clk));


   memMod #(depth*2, width, logDepth+1) 
     memMod0(.in(x0), .out(y0), .inAddr({inFlip, inAddr0}),
	   .outAddr({outFlip, outAddr0}), .writeSel(1'b1), .clk(clk));   
   memMod #(depth*2, width, logDepth+1) 
     memMod1(.in(x1), .out(y1), .inAddr({inFlip, inAddr1}),
	   .outAddr({outFlip, outAddr1}), .writeSel(1'b1), .clk(clk));   
endmodule

module shiftRegFIFO(X, Y, clk);
   parameter depth=1, width=1;

   output [width-1:0] Y;
   input  [width-1:0] X;
   input              clk;

   reg [width-1:0]    mem [depth-1:0];
   integer            index;

   assign Y = mem[depth-1];

   always @ (posedge clk) begin
      for(index=1;index<depth;index=index+1) begin
         mem[index] <= mem[index-1];
      end
      mem[0]<=X;
   end
endmodule


module memMod(in, out, inAddr, outAddr, writeSel, clk);
   
   parameter depth=1024, width=16, logDepth=10;
   
   input [width-1:0]    in;
   input [logDepth-1:0] inAddr, outAddr;
   input 	        writeSel, clk;
   output [width-1:0] 	out;
   reg [width-1:0] 	out;
   
   // synthesis attribute ram_style of mem is block

   reg [width-1:0] 	mem[depth-1:0]; 
   
   always @(posedge clk) begin
      out <= mem[outAddr];
      
      if (writeSel)
        mem[inAddr] <= in;
   end
endmodule 



module memMod_dist(in, out, inAddr, outAddr, writeSel, clk);
   
   parameter depth=1024, width=16, logDepth=10;
   
   input [width-1:0]    in;
   input [logDepth-1:0] inAddr, outAddr;
   input 	        writeSel, clk;
   output [width-1:0] 	out;
   reg [width-1:0] 	out;
   
   // synthesis attribute ram_style of mem is distributed

   reg [width-1:0] 	mem[depth-1:0]; 
   
   always @(posedge clk) begin
      out <= mem[outAddr];
      
      if (writeSel)
        mem[inAddr] <= in;
   end
endmodule 

module switch(ctrl, x0, x1, y0, y1);
    parameter width = 16;
    input [width-1:0] x0, x1;
    output [width-1:0] y0, y1;
    input ctrl;
    assign y0 = (ctrl == 0) ? x0 : x1;
    assign y1 = (ctrl == 0) ? x1 : x0;
endmodule

// Latency: 2
// Gap: 1
module codeBlock82719(clk, reset, next_in, next_out,
   X0_in, Y0,
   X1_in, Y1,
   X2_in, Y2,
   X3_in, Y3);

   output next_out;
   input clk, reset, next_in;

   reg next;

   input [3:0] X0_in,
      X1_in,
      X2_in,
      X3_in;

   reg   [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   shiftRegFIFO #(1, 1) shiftFIFO_83244(.X(next), .Y(next_out), .clk(clk));


   wire signed [3:0] a69;
   wire signed [3:0] a70;
   wire signed [3:0] a71;
   wire signed [3:0] a72;
   wire signed [3:0] t45;
   wire signed [3:0] t46;
   wire signed [3:0] t47;
   wire signed [3:0] t48;
   wire signed [3:0] Y0;
   wire signed [3:0] Y1;
   wire signed [3:0] Y2;
   wire signed [3:0] Y3;


   assign a69 = X0;
   assign a70 = X2;
   assign a71 = X1;
   assign a72 = X3;
   assign Y0 = t45;
   assign Y1 = t46;
   assign Y2 = t47;
   assign Y3 = t48;

    addfxp #(4, 1) add82731(.a(a69), .b(a70), .clk(clk), .q(t45));    // 0
    addfxp #(4, 1) add82746(.a(a71), .b(a72), .clk(clk), .q(t46));    // 0
    subfxp #(4, 1) sub82761(.a(a69), .b(a70), .clk(clk), .q(t47));    // 0
    subfxp #(4, 1) sub82776(.a(a71), .b(a72), .clk(clk), .q(t48));    // 0


   always @(posedge clk) begin
      if (reset == 1) begin
      end
      else begin
         X0 <= X0_in;
         X1 <= X1_in;
         X2 <= X2_in;
         X3 <= X3_in;
         next <= next_in;
      end
   end
endmodule

// Latency: 8
// Gap: 2
module DirSum_82976(clk, reset, next, next_out,
      X0, Y0,
      X1, Y1,
      X2, Y2,
      X3, Y3);

   output next_out;
   input clk, reset, next;

   reg [0:0] i1;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   always @(posedge clk) begin
      if (reset == 1) begin
         i1 <= 0;
      end
      else begin
         if (next == 1)
            i1 <= 0;
         else if (i1 == 1)
            i1 <= 0;
         else
            i1 <= i1 + 1;
      end
   end

   codeBlock82798 codeBlockIsnt83245(.clk(clk), .reset(reset), .next_in(next), .next_out(next_out),
.i1_in(i1),
       .X0_in(X0), .Y0(Y0),
       .X1_in(X1), .Y1(Y1),
       .X2_in(X2), .Y2(Y2),
       .X3_in(X3), .Y3(Y3));

endmodule

module D4_82962(addr, out, clk);
   input clk;
   output [3:0] out;
   reg [3:0] out, out2, out3;
   input [0:0] addr;

   always @(posedge clk) begin
      out2 <= out3;
      out <= out2;
   case(addr)
      0: out3 <= 4'h0;
      1: out3 <= 4'h4;
      default: out3 <= 0;
   endcase
   end
// synthesis attribute rom_style of out3 is "block"
endmodule



module D2_82970(addr, out, clk);
   input clk;
   output [3:0] out;
   reg [3:0] out, out2, out3;
   input [0:0] addr;

   always @(posedge clk) begin
      out2 <= out3;
      out <= out2;
   case(addr)
      0: out3 <= 4'h4;
      1: out3 <= 4'h0;
      default: out3 <= 0;
   endcase
   end
// synthesis attribute rom_style of out3 is "block"
endmodule



// Latency: 8
// Gap: 1
module codeBlock82798(clk, reset, next_in, next_out,
   i1_in,
   X0_in, Y0,
   X1_in, Y1,
   X2_in, Y2,
   X3_in, Y3);

   output next_out;
   input clk, reset, next_in;

   reg next;
   input [0:0] i1_in;
   reg [0:0] i1;

   input [3:0] X0_in,
      X1_in,
      X2_in,
      X3_in;

   reg   [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   shiftRegFIFO #(7, 1) shiftFIFO_83248(.X(next), .Y(next_out), .clk(clk));


   wire signed [3:0] a53;
   wire signed [3:0] a42;
   wire signed [3:0] a56;
   wire signed [3:0] a46;
   wire signed [3:0] a57;
   wire signed [3:0] a58;
   reg signed [3:0] tm26;
   reg signed [3:0] tm30;
   reg signed [3:0] tm42;
   reg signed [3:0] tm49;
   reg signed [3:0] tm27;
   reg signed [3:0] tm31;
   reg signed [3:0] tm43;
   reg signed [3:0] tm50;
   wire signed [3:0] tm2;
   wire signed [3:0] a47;
   wire signed [3:0] tm3;
   wire signed [3:0] a49;
   reg signed [3:0] tm28;
   reg signed [3:0] tm32;
   reg signed [3:0] tm44;
   reg signed [3:0] tm51;
   reg signed [3:0] tm8;
   reg signed [3:0] tm9;
   reg signed [3:0] tm29;
   reg signed [3:0] tm33;
   reg signed [3:0] tm45;
   reg signed [3:0] tm52;
   reg signed [3:0] tm46;
   reg signed [3:0] tm53;
   wire signed [3:0] a48;
   wire signed [3:0] a50;
   wire signed [3:0] a51;
   wire signed [3:0] a52;
   reg signed [3:0] tm47;
   reg signed [3:0] tm54;
   wire signed [3:0] Y0;
   wire signed [3:0] Y1;
   wire signed [3:0] Y2;
   wire signed [3:0] Y3;
   reg signed [3:0] tm48;
   reg signed [3:0] tm55;


   assign a53 = X0;
   assign a42 = a53;
   assign a56 = X1;
   assign a46 = a56;
   assign a57 = X2;
   assign a58 = X3;
   assign a47 = tm2;
   assign a49 = tm3;
   assign Y0 = tm48;
   assign Y1 = tm55;

   D4_82962 instD4inst0_82962(.addr(i1[0:0]), .out(tm3), .clk(clk));

   D2_82970 instD2inst0_82970(.addr(i1[0:0]), .out(tm2), .clk(clk));

    multfix #(4, 2) m82897(.a(tm8), .b(tm29), .clk(clk), .q_sc(a48), .q_unsc(), .rst(reset));
    multfix #(4, 2) m82919(.a(tm9), .b(tm33), .clk(clk), .q_sc(a50), .q_unsc(), .rst(reset));
    multfix #(4, 2) m82937(.a(tm9), .b(tm29), .clk(clk), .q_sc(a51), .q_unsc(), .rst(reset));
    multfix #(4, 2) m82948(.a(tm8), .b(tm33), .clk(clk), .q_sc(a52), .q_unsc(), .rst(reset));
    subfxp #(4, 1) sub82926(.a(a48), .b(a50), .clk(clk), .q(Y2));    // 6
    addfxp #(4, 1) add82955(.a(a51), .b(a52), .clk(clk), .q(Y3));    // 6


   always @(posedge clk) begin
      if (reset == 1) begin
         tm8 <= 0;
         tm29 <= 0;
         tm9 <= 0;
         tm33 <= 0;
         tm9 <= 0;
         tm29 <= 0;
         tm8 <= 0;
         tm33 <= 0;
      end
      else begin
         i1 <= i1_in;
         X0 <= X0_in;
         X1 <= X1_in;
         X2 <= X2_in;
         X3 <= X3_in;
         next <= next_in;
         tm26 <= a57;
         tm30 <= a58;
         tm42 <= a42;
         tm49 <= a46;
         tm27 <= tm26;
         tm31 <= tm30;
         tm43 <= tm42;
         tm50 <= tm49;
         tm28 <= tm27;
         tm32 <= tm31;
         tm44 <= tm43;
         tm51 <= tm50;
         tm8 <= a47;
         tm9 <= a49;
         tm29 <= tm28;
         tm33 <= tm32;
         tm45 <= tm44;
         tm52 <= tm51;
         tm46 <= tm45;
         tm53 <= tm52;
         tm47 <= tm46;
         tm54 <= tm53;
         tm48 <= tm47;
         tm55 <= tm54;
      end
   end
endmodule

// Latency: 4
// Gap: 2
module rc82980(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [7:0] t0;
   wire [7:0] s0;
   assign t0 = {X0, X1};
   wire [7:0] t1;
   wire [7:0] s1;
   assign t1 = {X2, X3};
   assign Y0 = s0[7:4];
   assign Y1 = s0[3:0];
   assign Y2 = s1[7:4];
   assign Y3 = s1[3:0];

   perm82978 instPerm83249(.x0(t0), .y0(s0),
    .x1(t1), .y1(s1),
   .clk(clk), .next(next), .next_out(next_out), .reset(reset)
);



endmodule

// Latency: 4
// Gap: 2
module perm82978(clk, next, reset, next_out,
   x0, y0,
   x1, y1);
   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;

   input [width-1:0]  x0;
   output [width-1:0]  y0;
   wire [width-1:0]  ybuff0;
   input [width-1:0]  x1;
   output [width-1:0]  y1;
   wire [width-1:0]  ybuff1;
   input 	      clk, next, reset;
   output 	     next_out;

   wire    	     next0;

   reg              inFlip0, outFlip0;
   reg              inActive, outActive;

   wire [logBanks-1:0] inBank0, outBank0;
   wire [logDepth-1:0] inAddr0, outAddr0;
   wire [logBanks-1:0] outBank_a0;
   wire [logDepth-1:0] outAddr_a0;
   wire [logDepth+logBanks-1:0] addr0, addr0b, addr0c;
   wire [logBanks-1:0] inBank1, outBank1;
   wire [logDepth-1:0] inAddr1, outAddr1;
   wire [logBanks-1:0] outBank_a1;
   wire [logDepth-1:0] outAddr_a1;
   wire [logDepth+logBanks-1:0] addr1, addr1b, addr1c;


   reg [logDepth-1:0]  inCount, outCount, outCount_d, outCount_dd, outCount_for_rd_addr, outCount_for_rd_data;  

   assign    addr0 = {inCount, 1'd0};
   assign    addr0b = {outCount, 1'd0};
   assign    addr0c = {outCount_for_rd_addr, 1'd0};
   assign    addr1 = {inCount, 1'd1};
   assign    addr1b = {outCount, 1'd1};
   assign    addr1c = {outCount_for_rd_addr, 1'd1};
    wire [width+logDepth-1:0] w_0_0, w_0_1, w_1_0, w_1_1;

    reg [width-1:0] z_0_0;
    reg [width-1:0] z_0_1;
    wire [width-1:0] z_1_0, z_1_1;

    wire [logDepth-1:0] u_0_0, u_0_1, u_1_0, u_1_1;

    always @(posedge clk) begin
    end

   assign inBank0[0] = addr0[1] ^ addr0[0];
   assign inAddr0[0] = addr0[0];
   assign outBank0[0] = addr0b[1] ^ addr0b[0];
   assign outAddr0[0] = addr0b[1];
   assign outBank_a0[0] = addr0c[1] ^ addr0c[0];
   assign outAddr_a0[0] = addr0c[1];

   assign inBank1[0] = addr1[1] ^ addr1[0];
   assign inAddr1[0] = addr1[0];
   assign outBank1[0] = addr1b[1] ^ addr1b[0];
   assign outAddr1[0] = addr1b[1];
   assign outBank_a1[0] = addr1c[1] ^ addr1c[0];
   assign outAddr_a1[0] = addr1c[1];

   shiftRegFIFO #(2, 1) shiftFIFO_83252(.X(next), .Y(next0), .clk(clk));


   shiftRegFIFO #(2, 1) shiftFIFO_83255(.X(next0), .Y(next_out), .clk(clk));


   memArray4_82978 #(numBanks, logBanks, depth, logDepth, width)
     memSys(.inFlip(inFlip0), .outFlip(outFlip0), .next(next), .reset(reset),
        .x0(w_1_0[width+logDepth-1:logDepth]), .y0(ybuff0),
        .inAddr0(w_1_0[logDepth-1:0]),
        .outAddr0(u_1_0), 
        .x1(w_1_1[width+logDepth-1:logDepth]), .y1(ybuff1),
        .inAddr1(w_1_1[logDepth-1:0]),
        .outAddr1(u_1_1), 
        .clk(clk));

    reg resetOutCountRd2_2;
    reg resetOutCountRd2_3;

    always @(posedge clk) begin
        if (reset == 1) begin
            resetOutCountRd2_2 <= 0;
            resetOutCountRd2_3 <= 0;
        end
        else begin
            resetOutCountRd2_2 <= (inCount == 1) ? 1'b1 : 1'b0;
            resetOutCountRd2_3 <= resetOutCountRd2_2;
            if (resetOutCountRd2_3 == 1'b1)
                outCount_for_rd_data <= 0;
            else
                outCount_for_rd_data <= outCount_for_rd_data+1;
        end
    end
   always @(posedge clk) begin
      if (reset == 1) begin
      z_0_0 <= 0;
      z_0_1 <= 0;
         inFlip0 <= 0; outFlip0 <= 1; outCount <= 0; inCount <= 0;
        outCount_for_rd_addr <= 0;
      end
      else begin
          outCount_d <= outCount;
          outCount_dd <= outCount_d;
         if (inCount == 1)
            outCount_for_rd_addr <= 0;
         else
            outCount_for_rd_addr <= outCount_for_rd_addr+1;
      z_0_0 <= ybuff0;
      z_0_1 <= ybuff1;
         if (inCount == 1) begin
            outFlip0 <= ~outFlip0;
            outCount <= 0;
         end
         else
            outCount <= outCount+1;
         if (inCount == 1) begin
            inFlip0 <= ~inFlip0;
         end
         if (next == 1) begin
            if (inCount >= 1)
               inFlip0 <= ~inFlip0;
            inCount <= 0;
         end
         else
            inCount <= inCount + 1;
      end
   end
    assign w_0_0 = {x0, inAddr0};
    assign w_0_1 = {x1, inAddr1};
    assign y0 = z_1_0;
    assign y1 = z_1_1;
    assign u_0_0 = outAddr_a0;
    assign u_0_1 = outAddr_a1;
    wire wr_ctrl_st_0;
    assign wr_ctrl_st_0 = inCount[0];

    switch #(logDepth+width) in_sw_0_0(.x0(w_0_0), .x1(w_0_1), .y0(w_1_0), .y1(w_1_1), .ctrl(wr_ctrl_st_0));
    wire rdd_ctrl_st_0;
    assign rdd_ctrl_st_0 = outCount_for_rd_data[0];

    switch #(width) out_sw_0_0(.x0(z_0_0), .x1(z_0_1), .y0(z_1_0), .y1(z_1_1), .ctrl(rdd_ctrl_st_0));
    wire rda_ctrl_st_0;
    assign rda_ctrl_st_0 = outCount_for_rd_addr[0];

    switch #(logDepth) rdaddr_sw_0_0(.x0(u_0_0), .x1(u_0_1), .y0(u_1_0), .y1(u_1_1), .ctrl(rda_ctrl_st_0));
endmodule

module memArray4_82978(next, reset,
                x0, y0,
                inAddr0,
                outAddr0,
                x1, y1,
                inAddr1,
                outAddr1,
                clk, inFlip, outFlip);

   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;
         
   input     clk, next, reset;
   input    inFlip, outFlip;
   wire    next0;
   
   input [width-1:0]   x0;
   output [width-1:0]  y0;
   input [logDepth-1:0] inAddr0, outAddr0;
   input [width-1:0]   x1;
   output [width-1:0]  y1;
   input [logDepth-1:0] inAddr1, outAddr1;
   shiftRegFIFO #(2, 1) shiftFIFO_83258(.X(next), .Y(next0), .clk(clk));


   memMod #(depth*2, width, logDepth+1) 
     memMod0(.in(x0), .out(y0), .inAddr({inFlip, inAddr0}),
	   .outAddr({outFlip, outAddr0}), .writeSel(1'b1), .clk(clk));   
   memMod #(depth*2, width, logDepth+1) 
     memMod1(.in(x1), .out(y1), .inAddr({inFlip, inAddr1}),
	   .outAddr({outFlip, outAddr1}), .writeSel(1'b1), .clk(clk));   
endmodule

// Latency: 2
// Gap: 1
module codeBlock82982(clk, reset, next_in, next_out,
   X0_in, Y0,
   X1_in, Y1,
   X2_in, Y2,
   X3_in, Y3);

   output next_out;
   input clk, reset, next_in;

   reg next;

   input [3:0] X0_in,
      X1_in,
      X2_in,
      X3_in;

   reg   [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   shiftRegFIFO #(1, 1) shiftFIFO_83261(.X(next), .Y(next_out), .clk(clk));


   wire signed [3:0] a9;
   wire signed [3:0] a10;
   wire signed [3:0] a11;
   wire signed [3:0] a12;
   wire signed [3:0] t21;
   wire signed [3:0] t22;
   wire signed [3:0] t23;
   wire signed [3:0] t24;
   wire signed [3:0] Y0;
   wire signed [3:0] Y1;
   wire signed [3:0] Y2;
   wire signed [3:0] Y3;


   assign a9 = X0;
   assign a10 = X2;
   assign a11 = X1;
   assign a12 = X3;
   assign Y0 = t21;
   assign Y1 = t22;
   assign Y2 = t23;
   assign Y3 = t24;

    addfxp #(4, 1) add82994(.a(a9), .b(a10), .clk(clk), .q(t21));    // 0
    addfxp #(4, 1) add83009(.a(a11), .b(a12), .clk(clk), .q(t22));    // 0
    subfxp #(4, 1) sub83024(.a(a9), .b(a10), .clk(clk), .q(t23));    // 0
    subfxp #(4, 1) sub83039(.a(a11), .b(a12), .clk(clk), .q(t24));    // 0


   always @(posedge clk) begin
      if (reset == 1) begin
      end
      else begin
         X0 <= X0_in;
         X1 <= X1_in;
         X2 <= X2_in;
         X3 <= X3_in;
         next <= next_in;
      end
   end
endmodule

// Latency: 4
// Gap: 2
module rc83063(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [7:0] t0;
   wire [7:0] s0;
   assign t0 = {X0, X1};
   wire [7:0] t1;
   wire [7:0] s1;
   assign t1 = {X2, X3};
   assign Y0 = s0[7:4];
   assign Y1 = s0[3:0];
   assign Y2 = s1[7:4];
   assign Y3 = s1[3:0];

   perm83061 instPerm83262(.x0(t0), .y0(s0),
    .x1(t1), .y1(s1),
   .clk(clk), .next(next), .next_out(next_out), .reset(reset)
);



endmodule

// Latency: 4
// Gap: 2
module perm83061(clk, next, reset, next_out,
   x0, y0,
   x1, y1);
   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;

   input [width-1:0]  x0;
   output [width-1:0]  y0;
   wire [width-1:0]  ybuff0;
   input [width-1:0]  x1;
   output [width-1:0]  y1;
   wire [width-1:0]  ybuff1;
   input 	      clk, next, reset;
   output 	     next_out;

   wire    	     next0;

   reg              inFlip0, outFlip0;
   reg              inActive, outActive;

   wire [logBanks-1:0] inBank0, outBank0;
   wire [logDepth-1:0] inAddr0, outAddr0;
   wire [logBanks-1:0] outBank_a0;
   wire [logDepth-1:0] outAddr_a0;
   wire [logDepth+logBanks-1:0] addr0, addr0b, addr0c;
   wire [logBanks-1:0] inBank1, outBank1;
   wire [logDepth-1:0] inAddr1, outAddr1;
   wire [logBanks-1:0] outBank_a1;
   wire [logDepth-1:0] outAddr_a1;
   wire [logDepth+logBanks-1:0] addr1, addr1b, addr1c;


   reg [logDepth-1:0]  inCount, outCount, outCount_d, outCount_dd, outCount_for_rd_addr, outCount_for_rd_data;  

   assign    addr0 = {inCount, 1'd0};
   assign    addr0b = {outCount, 1'd0};
   assign    addr0c = {outCount_for_rd_addr, 1'd0};
   assign    addr1 = {inCount, 1'd1};
   assign    addr1b = {outCount, 1'd1};
   assign    addr1c = {outCount_for_rd_addr, 1'd1};
    wire [width+logDepth-1:0] w_0_0, w_0_1, w_1_0, w_1_1;

    reg [width-1:0] z_0_0;
    reg [width-1:0] z_0_1;
    wire [width-1:0] z_1_0, z_1_1;

    wire [logDepth-1:0] u_0_0, u_0_1, u_1_0, u_1_1;

    always @(posedge clk) begin
    end

   assign inBank0[0] = addr0[1] ^ addr0[0];
   assign inAddr0[0] = addr0[0];
   assign outBank0[0] = addr0b[1] ^ addr0b[0];
   assign outAddr0[0] = addr0b[1];
   assign outBank_a0[0] = addr0c[1] ^ addr0c[0];
   assign outAddr_a0[0] = addr0c[1];

   assign inBank1[0] = addr1[1] ^ addr1[0];
   assign inAddr1[0] = addr1[0];
   assign outBank1[0] = addr1b[1] ^ addr1b[0];
   assign outAddr1[0] = addr1b[1];
   assign outBank_a1[0] = addr1c[1] ^ addr1c[0];
   assign outAddr_a1[0] = addr1c[1];

   shiftRegFIFO #(2, 1) shiftFIFO_83265(.X(next), .Y(next0), .clk(clk));


   shiftRegFIFO #(2, 1) shiftFIFO_83268(.X(next0), .Y(next_out), .clk(clk));


   memArray4_83061 #(numBanks, logBanks, depth, logDepth, width)
     memSys(.inFlip(inFlip0), .outFlip(outFlip0), .next(next), .reset(reset),
        .x0(w_1_0[width+logDepth-1:logDepth]), .y0(ybuff0),
        .inAddr0(w_1_0[logDepth-1:0]),
        .outAddr0(u_1_0), 
        .x1(w_1_1[width+logDepth-1:logDepth]), .y1(ybuff1),
        .inAddr1(w_1_1[logDepth-1:0]),
        .outAddr1(u_1_1), 
        .clk(clk));

    reg resetOutCountRd2_2;
    reg resetOutCountRd2_3;

    always @(posedge clk) begin
        if (reset == 1) begin
            resetOutCountRd2_2 <= 0;
            resetOutCountRd2_3 <= 0;
        end
        else begin
            resetOutCountRd2_2 <= (inCount == 1) ? 1'b1 : 1'b0;
            resetOutCountRd2_3 <= resetOutCountRd2_2;
            if (resetOutCountRd2_3 == 1'b1)
                outCount_for_rd_data <= 0;
            else
                outCount_for_rd_data <= outCount_for_rd_data+1;
        end
    end
   always @(posedge clk) begin
      if (reset == 1) begin
      z_0_0 <= 0;
      z_0_1 <= 0;
         inFlip0 <= 0; outFlip0 <= 1; outCount <= 0; inCount <= 0;
        outCount_for_rd_addr <= 0;
      end
      else begin
          outCount_d <= outCount;
          outCount_dd <= outCount_d;
         if (inCount == 1)
            outCount_for_rd_addr <= 0;
         else
            outCount_for_rd_addr <= outCount_for_rd_addr+1;
      z_0_0 <= ybuff0;
      z_0_1 <= ybuff1;
         if (inCount == 1) begin
            outFlip0 <= ~outFlip0;
            outCount <= 0;
         end
         else
            outCount <= outCount+1;
         if (inCount == 1) begin
            inFlip0 <= ~inFlip0;
         end
         if (next == 1) begin
            if (inCount >= 1)
               inFlip0 <= ~inFlip0;
            inCount <= 0;
         end
         else
            inCount <= inCount + 1;
      end
   end
    assign w_0_0 = {x0, inAddr0};
    assign w_0_1 = {x1, inAddr1};
    assign y0 = z_1_0;
    assign y1 = z_1_1;
    assign u_0_0 = outAddr_a0;
    assign u_0_1 = outAddr_a1;
    wire wr_ctrl_st_0;
    assign wr_ctrl_st_0 = inCount[0];

    switch #(logDepth+width) in_sw_0_0(.x0(w_0_0), .x1(w_0_1), .y0(w_1_0), .y1(w_1_1), .ctrl(wr_ctrl_st_0));
    wire rdd_ctrl_st_0;
    assign rdd_ctrl_st_0 = outCount_for_rd_data[0];

    switch #(width) out_sw_0_0(.x0(z_0_0), .x1(z_0_1), .y0(z_1_0), .y1(z_1_1), .ctrl(rdd_ctrl_st_0));
    wire rda_ctrl_st_0;
    assign rda_ctrl_st_0 = outCount_for_rd_addr[0];

    switch #(logDepth) rdaddr_sw_0_0(.x0(u_0_0), .x1(u_0_1), .y0(u_1_0), .y1(u_1_1), .ctrl(rda_ctrl_st_0));
endmodule

module memArray4_83061(next, reset,
                x0, y0,
                inAddr0,
                outAddr0,
                x1, y1,
                inAddr1,
                outAddr1,
                clk, inFlip, outFlip);

   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;
         
   input     clk, next, reset;
   input    inFlip, outFlip;
   wire    next0;
   
   input [width-1:0]   x0;
   output [width-1:0]  y0;
   input [logDepth-1:0] inAddr0, outAddr0;
   input [width-1:0]   x1;
   output [width-1:0]  y1;
   input [logDepth-1:0] inAddr1, outAddr1;
   shiftRegFIFO #(2, 1) shiftFIFO_83271(.X(next), .Y(next0), .clk(clk));


   memMod #(depth*2, width, logDepth+1) 
     memMod0(.in(x0), .out(y0), .inAddr({inFlip, inAddr0}),
	   .outAddr({outFlip, outAddr0}), .writeSel(1'b1), .clk(clk));   
   memMod #(depth*2, width, logDepth+1) 
     memMod1(.in(x1), .out(y1), .inAddr({inFlip, inAddr1}),
	   .outAddr({outFlip, outAddr1}), .writeSel(1'b1), .clk(clk));   
endmodule


						module multfix(clk, rst, a, b, q_sc, q_unsc);
						   parameter WIDTH=35, CYCLES=6;

						   input signed [WIDTH-1:0]    a,b;
						   output [WIDTH-1:0]          q_sc;
						   output [WIDTH-1:0]              q_unsc;

						   input                       clk, rst;
						   
						   reg signed [2*WIDTH-1:0]    q[CYCLES-1:0];
						   wire signed [2*WIDTH-1:0]   res;   
						   integer                     i;

						   assign                      res = q[CYCLES-1];   
						   
						   assign                      q_unsc = res[WIDTH-1:0];
						   assign                      q_sc = {res[2*WIDTH-1], res[2*WIDTH-4:WIDTH-2]};
						      
						   always @(posedge clk) begin
						      q[0] <= a * b;
						      for (i = 1; i < CYCLES; i=i+1) begin
						         q[i] <= q[i-1];
						      end
						   end
						                  
						endmodule 
module addfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a+b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
   
endmodule

module subfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a-b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
  
endmodule