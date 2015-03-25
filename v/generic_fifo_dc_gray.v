/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Universal FIFO Dual Clock, gray encoded                    ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  D/L from: http://www.opencores.org/cores/generic_fifos/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////



//  CVS Log
//
//  $Id: generic_fifo_dc_gray.v,v 1.2 2004-01-13 09:11:55 rudi Exp $
//
//  $Date: 2004-01-13 09:11:55 $
//  $Revision: 1.2 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.1  2003/10/14 09:34:41  rudi
//               Dual clock FIFO Gray Code encoded version.
//
//
//
//
//


`include "timescale.v"

/*

Description
===========

I/Os
----
rd_clk	Read Port Clock
wr_clk	Write Port Clock
rst	low active, either sync. or async. master reset (see below how to select)
clr	synchronous clear (just like reset but always synchronous), high active
re	read enable, synchronous, high active
we	read enable, synchronous, high active
din	Data Input
dout	Data Output

full	Indicates the FIFO is full (driven at the rising edge of wr_clk)
empty	Indicates the FIFO is empty (driven at the rising edge of rd_clk)

wr_level	indicates the FIFO level:
		2'b00	0-25%	 full
		2'b01	25-50%	 full
		2'b10	50-75%	 full
		2'b11	%75-100% full

rd_level	indicates the FIFO level:
		2'b00	0-25%	 empty
		2'b01	25-50%	 empty
		2'b10	50-75%	 empty
		2'b11	%75-100% empty

Status Timing
-------------
All status outputs are registered. They are asserted immediately
as the full/empty condition occurs, however, there is a 2 cycle
delay before they are de-asserted once the condition is not true
anymore.

Parameters
----------
The FIFO takes 2 parameters:
dw	Data bus width
aw	Address bus width (Determines the FIFO size by evaluating 2^aw)

Synthesis Results
-----------------
In a Spartan 2e a 8 bit wide, 8 entries deep FIFO, takes 97 LUTs and runs
at about 113 MHz (IO insertion disabled). 

Misc
----
This design assumes you will do appropriate status checking externally.

IMPORTANT ! writing while the FIFO is full or reading while the FIFO is
empty will place the FIFO in an undefined state.

*/


module generic_fifo_dc_gray(	rd_clk, wr_clk, rst, clr, din, we,
		dout, re, full, empty, wr_level, rd_level );

parameter dw=16;
parameter aw=8;

input			rd_clk, wr_clk, rst, clr;
input	[dw-1:0]	din;
input			we;
output	[dw-1:0]	dout;
input			re;
output			full; 
output			empty;
output	[1:0]		wr_level;
output	[1:0]		rd_level;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

reg	[aw:0]		wp_bin, wp_gray;
reg	[aw:0]		rp_bin, rp_gray;
reg	[aw:0]		wp_s, rp_s;
reg			full, empty;

wire	[aw:0]		wp_bin_next, wp_gray_next;
wire	[aw:0]		rp_bin_next, rp_gray_next;

wire	[aw:0]		wp_bin_x, rp_bin_x;
reg	[aw-1:0]	d1, d2;

reg			rd_rst, wr_rst;
reg			rd_rst_r, wr_rst_r;
reg			rd_clr, wr_clr;
reg			rd_clr_r, wr_clr_r;

////////////////////////////////////////////////////////////////////
//
// Reset Logic
//

always @(posedge rd_clk or negedge rst)
	if(!rst)	rd_rst <= 1'b0;
	else
	if(rd_rst_r)	rd_rst <= 1'b1;		// Release Reset

always @(posedge rd_clk or negedge rst)
	if(!rst)	rd_rst_r <= 1'b0;
	else		rd_rst_r <= 1'b1;

always @(posedge wr_clk or negedge rst)
	if(!rst)	wr_rst <= 1'b0;
	else
	if(wr_rst_r)	wr_rst <= 1'b1;		// Release Reset

always @(posedge wr_clk or negedge rst)
	if(!rst)	wr_rst_r <= 1'b0;
	else		wr_rst_r <= 1'b1;

always @(posedge rd_clk or posedge clr)
	if(clr)		rd_clr <= 1'b1;
	else
	if(!rd_clr_r)	rd_clr <= 1'b0;		// Release Clear

always @(posedge rd_clk or posedge clr)
	if(clr)		rd_clr_r <= 1'b1;
	else		rd_clr_r <= 1'b0;

always @(posedge wr_clk or posedge clr)
	if(clr)		wr_clr <= 1'b1;
	else
	if(!wr_clr_r)	wr_clr <= 1'b0;		// Release Clear

always @(posedge wr_clk or posedge clr)
	if(clr)		wr_clr_r <= 1'b1;
	else		wr_clr_r <= 1'b0;

////////////////////////////////////////////////////////////////////
//
// Memory Block
//

generic_dpram  #(aw,dw) u0(
	.rclk(		rd_clk		),
	.rrst(		!rd_rst		),
	.rce(		1'b1		),
	.oe(		1'b1		),
	.raddr(		rp_bin[aw-1:0]	),
	.do(		dout		),
	.wclk(		wr_clk		),
	.wrst(		!wr_rst		),
	.wce(		1'b1		),
	.we(		we		),
	.waddr(		wp_bin[aw-1:0]	),
	.di(		din		)
	);

////////////////////////////////////////////////////////////////////
//
// Read/Write Pointers Logic
//

always @(posedge wr_clk)
	if(!wr_rst)	wp_bin <= {aw+1{1'b0}};
	else
	if(wr_clr)	wp_bin <= {aw+1{1'b0}};
	else
	if(we)		wp_bin <= wp_bin_next;

always @(posedge wr_clk)
	if(!wr_rst)	wp_gray <= {aw+1{1'b0}};
	else
	if(wr_clr)	wp_gray <= {aw+1{1'b0}};
	else
	if(we)		wp_gray <= wp_gray_next;

assign wp_bin_next  = wp_bin + {{aw{1'b0}},1'b1};
assign wp_gray_next = wp_bin_next ^ {1'b0, wp_bin_next[aw:1]};

always @(posedge rd_clk)
	if(!rd_rst)	rp_bin <= {aw+1{1'b0}};
	else
	if(rd_clr)	rp_bin <= {aw+1{1'b0}};
	else
	if(re)		rp_bin <= rp_bin_next;

always @(posedge rd_clk)
	if(!rd_rst)	rp_gray <= {aw+1{1'b0}};
	else
	if(rd_clr)	rp_gray <= {aw+1{1'b0}};
	else
	if(re)		rp_gray <= rp_gray_next;

assign rp_bin_next  = rp_bin + {{aw{1'b0}},1'b1};
assign rp_gray_next = rp_bin_next ^ {1'b0, rp_bin_next[aw:1]};

////////////////////////////////////////////////////////////////////
//
// Synchronization Logic
//

// write pointer
always @(posedge rd_clk)	wp_s <= wp_gray;

// read pointer
always @(posedge wr_clk)	rp_s <= rp_gray;

////////////////////////////////////////////////////////////////////
//
// Registered Full & Empty Flags
//

assign wp_bin_x = wp_s ^ {1'b0, wp_bin_x[aw:1]};	// convert gray to binary
assign rp_bin_x = rp_s ^ {1'b0, rp_bin_x[aw:1]};	// convert gray to binary

always @(posedge rd_clk)
        empty <= (wp_s == rp_gray) | (re & (wp_s == rp_gray_next));

always @(posedge wr_clk)
        full <= ((wp_bin[aw-1:0] == rp_bin_x[aw-1:0]) & (wp_bin[aw] != rp_bin_x[aw])) |
        (we & (wp_bin_next[aw-1:0] == rp_bin_x[aw-1:0]) & (wp_bin_next[aw] != rp_bin_x[aw]));

////////////////////////////////////////////////////////////////////
//
// Registered Level Indicators
//
reg	[1:0]		wr_level;
reg	[1:0]		rd_level;
reg	[aw-1:0]	wp_bin_xr, rp_bin_xr;
reg			full_rc;
reg			full_wc;

always @(posedge wr_clk)	full_wc <= full;
always @(posedge wr_clk)	rp_bin_xr <=  ~rp_bin_x[aw-1:0] + {{aw-1{1'b0}}, 1'b1};
always @(posedge wr_clk)	d1 <= wp_bin[aw-1:0] + rp_bin_xr[aw-1:0];

always @(posedge wr_clk)	wr_level <= {d1[aw-1] | full | full_wc, d1[aw-2] | full | full_wc};

always @(posedge rd_clk)	wp_bin_xr <=  ~wp_bin_x[aw-1:0];
always @(posedge rd_clk)	d2 <= rp_bin[aw-1:0] + wp_bin_xr[aw-1:0];

always @(posedge rd_clk)	full_rc <= full;
always @(posedge rd_clk)	rd_level <= full_rc ? 2'h0 : {d2[aw-1] | empty, d2[aw-2] | empty};

////////////////////////////////////////////////////////////////////
//
// Sanity Check
//

// synopsys translate_off
always @(posedge wr_clk)
	if(we && full)
		$display("%m WARNING: Writing while fifo is FULL (%t)",$time);

always @(posedge rd_clk)
	if(re && empty)
		$display("%m WARNING: Reading while fifo is EMPTY (%t)",$time);
// synopsys translate_on

endmodule

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Dual-Port Synchronous RAM                           ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common dual-port               ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  dual-port synchronous RAM.                                  ////
////  It also contains a fully synthesizeable model for FPGAs.    ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Dual-Port Sync RAM                                ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage 2-port Sync RAM                                    ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Generic FPGA (VENDOR_FPGA)                                ////
////    Tested RAMs: Altera, Xilinx                               ////
////    Synthesis tools: LeonardoSpectrum, Synplicity             ////
////  - Xilinx (VENDOR_XILINX)                                    ////
////  - Altera (VENDOR_ALTERA)                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - fix Avant!                                               ////
////   - add additional RAMs (VS etc)                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - Richard Herveille, richard@asics.ws                   ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.2  2001/11/08 19:11:31  samg
// added valid checks to behvioral model
//
// Revision 1.1.1.1  2001/09/14 09:57:10  rherveille
// Major cleanup.
// Files are now compliant to Altera & Xilinx memories.
// Memories are now compatible, i.e. drop-in replacements.
// Added synthesizeable generic FPGA description.
// Created "generic_memories" cvs entry.
//
// Revision 1.1.1.2  2001/08/21 13:09:27  damjan
// *** empty log message ***
//
// Revision 1.1  2001/08/20 18:23:20  damjan
// Initial revision
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//
 
//`include "timescale.v"
 
//`define VENDOR_FPGA
//`define VENDOR_XILINX
//`define VENDOR_ALTERA
 
module generic_dpram(
	// Generic synchronous dual-port RAM interface
	rclk, rrst, rce, oe, raddr, do,
	wclk, wrst, wce, we, waddr, di
);
 
	//
	// Default address and data buses width
	//
	parameter aw = 5;  // number of bits in address-bus
	parameter dw = 16; // number of bits in data-bus
 
	//
	// Generic synchronous double-port RAM interface
	//
	// read port
	input           rclk;  // read clock, rising edge trigger
	input           rrst;  // read port reset, active high
	input           rce;   // read port chip enable, active high
	input           oe;	   // output enable, active high
	input  [aw-1:0] raddr; // read address
	output [dw-1:0] do;    // data output
 
	// write port
	input          wclk;  // write clock, rising edge trigger
	input          wrst;  // write port reset, active high
	input          wce;   // write port chip enable, active high
	input          we;    // write enable, active high
	input [aw-1:0] waddr; // write address
	input [dw-1:0] di;    // data input
 
	//
	// Module body
	//
 
`ifdef VENDOR_FPGA
	//
	// Instantiation synthesizeable FPGA memory
	//
	// This code has been tested using LeonardoSpectrum and Synplicity.
	// The code correctly instantiates Altera EABs and Xilinx BlockRAMs.
	//
 
	reg [dw-1 :0] mem [(1<<aw) -1:0]; // instantiate memory
	reg [dw-1:0] do;                  // data output registers
 
	// read operation
 
	/*
	always@(posedge rclk)
		if (rce)                      // clock enable instructs Xilinx tools to use SelectRAM (LUTS) instead of BlockRAM
			do <= #1 mem[raddr];
	*/
 
	always@(posedge rclk)
		do <= #1 mem[raddr];
 
	// write operation
	always@(posedge wclk)
		if (we && wce)
			mem[waddr] <= #1 di;
 
`else
 
`ifdef VENDOR_XILINX
	//
	// Instantiation of FPGA memory:
	//
	// Virtex/Spartan2 BlockRAMs
	//
	xilinx_ram_dp xilinx_ram(
		// read port
		.CLKA(rclk),
		.RSTA(rrst),
		.ENA(rce),
		.ADDRA(raddr),
		.DIA( {dw{1'b0}} ),
		.WEA(1'b0),
		.DOA(do),
 
		// write port
		.CLKB(wclk),
		.RSTB(wrst),
		.ENB(wce),
		.ADDRB(waddr),
		.DIB(di),
		.WEB(we),
		.DOB()
	);
 
	defparam
		xilinx_ram.dwidth = dw,
		xilinx_ram.awidth = aw;
 
`else
 
`ifdef VENDOR_ALTERA
	//
	// Instantiation of FPGA memory:
	//
	// Altera FLEX/APEX EABs
	//
	altera_ram_dp altera_ram(
		// read port
		.rdclock(rclk),
		.rdclocken(rce),
		.rdaddress(raddr),
		.q(do),
 
		// write port
		.wrclock(wclk),
		.wrclocken(wce),
		.wren(we),
		.wraddress(waddr),
		.data(di)
	);
 
	defparam
		altera_ram.dwidth = dw,
		altera_ram.awidth = aw;
 
`else
 
`ifdef VENDOR_ARTISAN
 
	//
	// Instantiation of ASIC memory:
	//
	// Artisan Synchronous Double-Port RAM (ra2sh)
	//
	art_hsdp #(dw, 1<<aw, aw) artisan_sdp(
		// read port
		.qa(do),
		.clka(rclk),
		.cena(~rce),
		.wena(1'b1),
		.aa(raddr),
		.da( {dw{1'b0}} ),
		.oena(~oe),
 
		// write port
		.qb(),
		.clkb(wclk),
		.cenb(~wce),
		.wenb(~we),
		.ab(waddr),
		.db(di),
		.oenb(1'b1)
	);
 
`else
 
`ifdef VENDOR_AVANT
 
	//
	// Instantiation of ASIC memory:
	//
	// Avant! Asynchronous Two-Port RAM
	//
	avant_atp avant_atp(
		.web(~we),
		.reb(),
		.oeb(~oe),
		.rcsb(),
		.wcsb(),
		.ra(raddr),
		.wa(waddr),
		.di(di),
		.do(do)
	);
 
`else
 
`ifdef VENDOR_VIRAGE
 
	//
	// Instantiation of ASIC memory:
	//
	// Virage Synchronous 2-port R/W RAM
	//
	virage_stp virage_stp(
		// read port
		.CLKA(rclk),
		.MEA(rce_a),
		.ADRA(raddr),
		.DA( {dw{1'b0}} ),
		.WEA(1'b0),
		.OEA(oe),
		.QA(do),
 
		// write port
		.CLKB(wclk),
		.MEB(wce),
		.ADRB(waddr),
		.DB(di),
		.WEB(we),
		.OEB(1'b1),
		.QB()
	);
 
`else
 
	//
	// Generic dual-port synchronous RAM model
	//
 
	//
	// Generic RAM's registers and wires
	//
	reg	[dw-1:0]	mem [(1<<aw)-1:0];	// RAM content
	reg	[dw-1:0]	do_reg;            // RAM data output register
 
	//
	// Data output drivers
	//
	assign do = (oe & rce) ? do_reg : {dw{1'bz}};
 
	// read operation
	always @(posedge rclk)
		if (rce)
          		do_reg <= #1 (we && (waddr==raddr)) ? {dw{1'b x}} : mem[raddr];
 
	// write operation
	always @(posedge wclk)
		if (wce && we)
			mem[waddr] <= #1 di;
 
 
	// Task prints range of memory
	// *** Remember that tasks are non reentrant, don't call this task in parallel for multiple instantiations. 
	task print_ram;
	input [aw-1:0] start;
	input [aw-1:0] finish;
	integer rnum;
  	begin
    		for (rnum=start;rnum<=finish;rnum=rnum+1)
      			$display("Addr %h = %h",rnum,mem[rnum]);
  	end
	endtask
 
`endif // !VENDOR_VIRAGE
`endif // !VENDOR_AVANT
`endif // !VENDOR_ARTISAN
`endif // !VENDOR_ALTERA
`endif // !VENDOR_XILINX
`endif // !VENDOR_FPGA
 
endmodule
