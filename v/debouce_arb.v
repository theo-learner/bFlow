/*
 * Copyright (c) 2008-2009, Kendall Correll
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

`timescale 1ns / 1ps

module debouncer #(
	parameter count = 1,
	parameter high_count = count,
	parameter low_count = count,
	parameter width = 1,
	parameter reset_value = {width{1'b0}}
)(
	input enable,
	input [width-1:0] in,
	output [width-1:0] out,
	output reg rising_pulse,
	output reg falling_pulse,
	output reg valid,
	
	input clock,
	input reset
);

`include "functions.v"

reg [width-1:0] in_reg;
reg [width-1:0] out_reg;

always @(posedge clock)
begin
	in_reg <= in;
end

// edge detector
wire rising;
wire falling;

assign rising = |(~in_reg & in);
assign falling = |(in_reg & ~in);

// counter width is the maximum size of the loaded value
parameter counter_width = max(flog2(count - 1) + 1,
	max(flog2(high_count - 1) + 1, flog2(low_count - 1) + 1));

reg [counter_width:0] counter;
reg [counter_width-1:0] counter_load;
wire counter_overflow;

assign counter_overflow = counter[counter_width];

// select counter value for rising or falling edge
always @(rising, falling)
begin
	case({rising, falling})
	'b11:
		counter_load = -count;
	'b10:
		counter_load = -high_count;
	'b01:
		counter_load = -low_count;
	default:
		counter_load = {counter_width{1'bx}};
	endcase
end

// the counter is reset on a rising or falling edge
// reset has priority over overflow, so the counter
// will not overflow until the input has been stable
// for a full count
always @(posedge clock, posedge reset)
begin
	if(reset)
		counter <= {counter_width{1'b0}};
	else
	begin
		if(rising | falling)
			counter <= { 1'b0, counter_load };
		else if(enable & ~counter_overflow)
			counter <= counter + 1;
	end
end

// output is gated by the counter overflow
assign out = out_reg;

always @(posedge clock, posedge reset)
begin
	if(reset)
		out_reg <= reset_value;
	else
	begin
		if(counter_overflow)
			out_reg <= in_reg;
	end
end

always @(posedge clock, posedge reset)
begin
	if(reset)
	begin
		rising_pulse <= 1'b0;
		falling_pulse <= 1'b0;
	end
	else
	begin
		rising_pulse <= counter_overflow & ~out_reg & in_reg;
		falling_pulse <= counter_overflow & out_reg & ~in_reg;
	end
end

always @(posedge clock, posedge reset)
begin
	if(reset)
		valid <= 1'b0;
	else
		valid <= counter_overflow;
end

endmodule

function integer min (
	input integer a, b
);
begin
	min = a < b ? a : b;
end
endfunction

function integer max (
	input integer a, b
);
begin
	max = a > b ? a : b;
end
endfunction

// compute the log base 2 of a number, rounded down to the
// nearest whole number
function integer flog2 (
	input integer number
);
integer i;
integer count;
begin
	flog2 = 0;
	for(i = 0; i < 32; i = i + 1)
	begin
		if(number&(1<<i))
			flog2 = i;
	end
end
endfunction

// compute the log base 2 of a number, rounded up to the
// nearest whole number
function integer clog2 (
	input integer number
);
integer i;
integer count;
begin
	clog2 = 0;
	count = 0;
	for(i = 0; i < 32; i = i + 1)
	begin
		if(number&(1<<i))
		begin
			clog2 = i;
			count = count + 1;
		end
	end
	// clog2 holds the largest set bit position and count
	// holds the number of bits set. More than one bit set
	// indicates that the input was not an even power of 2,
	// so round the result up.
	if(count > 1)
		clog2 = clog2 + 1;
end
endfunction

// compute the size of the interconnect for the arbiter's
// 'select' muxes
function integer mux_sum (
	input integer width, select_width
);
integer i, number;
begin
	mux_sum = 0;
	number = 1;
	for(i = select_width; i > 0 && number <= width; i = i - 1)
	begin
		mux_sum = mux_sum + i*(number);
		number = number * 2;
	end
end
endfunction
