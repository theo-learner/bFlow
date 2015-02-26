/*
 * Copyright (c) 2008, Kendall Correll
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

module counter_arb#(
	parameter count = 1,
	parameter toggle = 0
)(
	input enable,
	output reg out,
	
	input clock,
	input reset
);

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


// counter width is the size of the loaded value
parameter counter_width = flog2(count - 1) + 1;

reg [counter_width:0] counter;
wire [counter_width-1:0] counter_load;
wire counter_overflow;

assign counter_overflow = counter[counter_width];
assign counter_load = -count;

always @(posedge clock, posedge reset)
begin
	if(reset)
		out <= 1'b0;
	else
	begin
		if(toggle)
			out <= out ^ counter_overflow;
		else
			out <= counter_overflow;
	end
end

always @(posedge clock, posedge reset)
begin
	if(reset)
		counter <= {counter_width{1'b1}};
	else
	begin
		if(counter_overflow)
			counter <= { 1'b0, counter_load };
		else if(enable)
			counter <= counter + 1;
	end
end

endmodule

