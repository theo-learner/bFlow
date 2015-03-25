/////////////////////////////////////////////////////////////////////
////                                                             ////
////  generic FIFO, uses LFSRs for read/write pointers           ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001, 2002 Richard Herveille                  ////
////                          richard@asics.ws                   ////
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

//
//  CVS Log
//
//  $Id: generic_fifo_lfsr.v,v 1.1 2002-10-29 19:45:07 rherveille Exp $
//
//  $Date: 2002-10-29 19:45:07 $
//  $Revision: 1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $

`include "timescale.v"

// set FIFO_RW_CHECK to prevent writing to a full and reading from an empty FIFO
//`define FIFO_RW_CHECK

// Long Pseudo Random Generators can generate (N^2 -1) combinations. This means
// 1 FIFO entry is unavailable. This might be a problem, especially for small
// FIFOs. Setting FIFO_ALL_ENTRIES creates additional logic that ensures that
// all FIFO entries are used at the expense of some additional logic.
`define FIFO_ALL_ENTRIES

module generic_fifo_lfsr (
	clk,
	nReset,
	rst,
	wreq,
	rreq,
	d,
	q,
	empty,
	full,
	aempty,
	afull
	);

	//
	// parameters
	//
	parameter aw =  3;                         // no.of entries (in bits; 2^7=128 entries)
	parameter dw =  8;                         // datawidth (in bits)

	//
	// inputs & outputs
	//
	input             clk;                     // master clock
	input nReset;                              // asynchronous active low reset
	input rst;                                 // synchronous active high reset

	input             wreq;                    // write request
	input             rreq;                    // read request
	input  [dw:1] d;                           // data-input
	output [dw:1] q;                           // data-output

	output            empty;                   // fifo empty
	output            full;                    // fifo full

	output            aempty;                  // fifo asynchronous/almost empty (1 entry left)
	output            afull;                   // fifo asynchronous/almost full (1 entry left)

	reg empty, full;

	//
	// Module body
	//
	reg  [aw:1] rp, wp;
	wire [dw:1] ramq;
	wire fwreq, frreq;

`ifdef FIFO_ALL_ENTRIES
	function lsb;
	   input [aw:1] q;
	   case (aw)
	       2: lsb = ~q[2];
	       3: lsb = &q[aw-1:1] ^ ~(q[3] ^ q[2]);
	       4: lsb = &q[aw-1:1] ^ ~(q[4] ^ q[3]);
	       5: lsb = &q[aw-1:1] ^ ~(q[5] ^ q[3]);
	       6: lsb = &q[aw-1:1] ^ ~(q[6] ^ q[5]);
	       7: lsb = &q[aw-1:1] ^ ~(q[7] ^ q[6]);
	       8: lsb = &q[aw-1:1] ^ ~(q[8] ^ q[6] ^ q[5] ^ q[4]);
	       9: lsb = &q[aw-1:1] ^ ~(q[9] ^ q[5]);
	      10: lsb = &q[aw-1:1] ^ ~(q[10] ^ q[7]);
	      11: lsb = &q[aw-1:1] ^ ~(q[11] ^ q[9]);
	      12: lsb = &q[aw-1:1] ^ ~(q[12] ^ q[6] ^ q[4] ^ q[1]);
	      13: lsb = &q[aw-1:1] ^ ~(q[13] ^ q[4] ^ q[3] ^ q[1]);
	      14: lsb = &q[aw-1:1] ^ ~(q[14] ^ q[5] ^ q[3] ^ q[1]);
	      15: lsb = &q[aw-1:1] ^ ~(q[15] ^ q[14]);
	      16: lsb = &q[aw-1:1] ^ ~(q[16] ^ q[15] ^ q[13] ^ q[4]);
	   endcase
	endfunction
`else
	function lsb;
	   input [aw:1] q;
	   case (aw)
	       2: lsb = ~q[2];
	       3: lsb = ~(q[3] ^ q[2]);
	       4: lsb = ~(q[4] ^ q[3]);
	       5: lsb = ~(q[5] ^ q[3]);
	       6: lsb = ~(q[6] ^ q[5]);
	       7: lsb = ~(q[7] ^ q[6]);
	       8: lsb = ~(q[8] ^ q[6] ^ q[5] ^ q[4]);
	       9: lsb = ~(q[9] ^ q[5]);
	      10: lsb = ~(q[10] ^ q[7]);
	      11: lsb = ~(q[11] ^ q[9]);
	      12: lsb = ~(q[12] ^ q[6] ^ q[4] ^ q[1]);
	      13: lsb = ~(q[13] ^ q[4] ^ q[3] ^ q[1]);
	      14: lsb = ~(q[14] ^ q[5] ^ q[3] ^ q[1]);
	      15: lsb = ~(q[15] ^ q[14]);
	      16: lsb = ~(q[16] ^ q[15] ^ q[13] ^ q[4]);
	   endcase
	endfunction
`endif

`ifdef RW_CHECK
  assign fwreq = wreq & ~full;
  assign frreq = rreq & ~empty;
`else
  assign fwreq = wreq;
  assign frreq = rreq;
`endif

	// hookup read-pointer
	always @(posedge clk or negedge nReset)
	  if (~nReset)    rp <= #1 0;
	  else if (rst)   rp <= #1 0;
	  else if (frreq) rp <= #1 {rp[aw-1:1], lsb(rp)};

	// hookup write-pointer
	always @(posedge clk or negedge nReset)
	  if (~nReset)    wp <= #1 0;
	  else if (rst)   wp <= #1 0;
	  else if (fwreq) wp <= #1 {wp[aw-1:1], lsb(wp)};

	// hookup RAM-block
	generic_dpram #(aw, dw)
	fiforam (
		// write section
		.wclk(clk),
		.wrst(1'b0),
		.wce(1'b1),
		.we(fwreq),
		.waddr(wp),
		.di(d),

		// read section
		.rclk(clk),
		.rrst(1'b0),
		.rce(1'b1),
		.oe(1'b1),
		.raddr(rp),
		.do(q)
	);

	// generate full/empty signals
	assign aempty = (rp[aw-1:1] == wp[aw:2]) & (lsb(rp) == wp[1]) & frreq & ~fwreq;
	always @(posedge clk or negedge nReset)
	  if (~nReset)
	    empty <= #1 1'b1;
	  else if (rst)
	    empty <= #1 1'b1;
	  else
	    empty <= #1 aempty | (empty & (~fwreq + frreq));

	assign afull = (wp[aw-1:1] == rp[aw:2]) & (lsb(wp) == rp[1]) & fwreq & ~frreq;
	always @(posedge clk or negedge nReset)
	  if (~nReset)
	    full <= #1 1'b0;
	  else if (rst)
	    full <= #1 1'b0;
	  else
	    full <= #1 afull | ( full & (~frreq + fwreq) );

	//
	// Simulation checks
	//
	// synopsys translate_off
	always @(posedge clk)
	  if (full & fwreq)
	    $display("Writing while FIFO full\n");

	always @(posedge clk)
	  if (empty & frreq)
	    $display("Reading while FIFO empty\n");
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
