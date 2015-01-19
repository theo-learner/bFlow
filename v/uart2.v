/*

Copyright (c) 2014 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

https://github.com/alexforencich/verilog-uart

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * AXI4-Stream UART
 */

module uart2 #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  input_axis_tdata,
    input  wire                   input_axis_tvalid,
    output wire                   input_axis_tready,

    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  output_axis_tdata,
    output wire                   output_axis_tvalid,
    input  wire                   output_axis_tready,

    /*
     * UART interface
     */
    input  wire                   rxd,
    output wire                   txd,

    /*
     * Status
     */
    output wire                   tx_busy,
    output wire                   rx_busy,
    output wire                   rx_overrun_error,
    output wire                   rx_frame_error,

    /*
     * Configuration
     */
    input  wire [15:0]            prescale

);


reg input_axis_tready_reg = 0;

reg txd_reg = 1;

reg busy_reg_tx = 0;

reg [DATA_WIDTH:0] data_reg_tx = 0;
reg [18:0] prescale_reg_tx = 0;
reg [3:0] bit_cnt_tx = 0;

assign input_axis_tready = input_axis_tready_reg;
assign txd = txd_reg;

assign tx_busy = busy_reg_tx;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_axis_tready_reg <= 0;
        txd_reg <= 1;
        prescale_reg_tx <= 0;
        bit_cnt_tx <= 0;
        busy_reg_tx <= 0;
    end else begin
        if (prescale_reg_tx > 0) begin
            input_axis_tready_reg <= 0;
            prescale_reg_tx <= prescale_reg_tx - 1;
        end else if (bit_cnt_tx == 0) begin
            input_axis_tready_reg <= 1;
            busy_reg_tx <= 0;

            if (input_axis_tvalid) begin
                input_axis_tready_reg <= ~input_axis_tready_reg;
                prescale_reg_tx <= (prescale << 3)-1;
                bit_cnt_tx <= DATA_WIDTH+1;
                data_reg_tx <= {1'b1, input_axis_tdata};
                txd_reg <= 0;
                busy_reg_tx <= 1;
            end
        end else begin
            if (bit_cnt_tx > 1) begin
                bit_cnt_tx <= bit_cnt_tx - 1;
                prescale_reg_tx <= (prescale << 3)-1;
                {data_reg_tx, txd_reg} <= {1'b0, data_reg_tx};
            end else if (bit_cnt_tx == 1) begin
                bit_cnt_tx <= bit_cnt_tx - 1;
                prescale_reg_tx <= (prescale << 3);
                txd_reg <= 1;
            end
        end
    end
end


reg [DATA_WIDTH-1:0] output_axis_tdata_reg = 0;
reg output_axis_tvalid_reg = 0;

reg busy_reg_rx = 0;
reg overrun_error_reg = 0;
reg frame_error_reg = 0;

reg [DATA_WIDTH-1:0] data_reg_rx = 0;
reg [18:0] prescale_reg_rx = 0;
reg [3:0] bit_cnt_rx = 0;

assign output_axis_tdata = output_axis_tdata_reg;
assign output_axis_tvalid = output_axis_tvalid_reg;

assign rx_busy = busy_reg_rx;
assign rx_overrun_error = overrun_error_reg;
assign rx_frame_error = frame_error_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        output_axis_tdata_reg <= 0;
        output_axis_tvalid_reg <= 0;
        prescale_reg_rx <= 0;
        bit_cnt_rx <= 0;
        busy_reg_rx <= 0;
        overrun_error_reg <= 0;
        frame_error_reg <= 0;
    end else begin
        overrun_error_reg <= 0;
        frame_error_reg <= 0;

        if (output_axis_tvalid & output_axis_tready) begin
            output_axis_tvalid_reg <= 0;
        end

        if (prescale_reg_rx > 0) begin
            prescale_reg_rx <= prescale_reg_rx - 1;
        end else if (bit_cnt_rx > 0) begin
            if (bit_cnt_rx > DATA_WIDTH+1) begin
                if (~rxd) begin
                    bit_cnt_rx <= bit_cnt_rx - 1;
                    prescale_reg_rx <= (prescale << 3)-1;
                end else begin
                    bit_cnt_rx <= 0;
                    prescale_reg_rx <= 0;
                end
            end else if (bit_cnt_rx > 1) begin
                bit_cnt_rx <= bit_cnt_rx - 1;
                prescale_reg_rx <= (prescale << 3)-1;
                data_reg_rx <= {rxd, data_reg_rx[DATA_WIDTH-1:1]};
            end else if (bit_cnt_rx == 1) begin
                bit_cnt_rx <= bit_cnt_rx - 1;
                if (rxd) begin
                    output_axis_tdata_reg <= data_reg_rx;
                    output_axis_tvalid_reg <= 1;
                    overrun_error_reg <= output_axis_tvalid_reg;
                end else begin
                    frame_error_reg <= 1;
                end
            end
        end else begin
            busy_reg_rx <= 0;
            if (~rxd) begin
                prescale_reg_rx <= (prescale << 2)-2;
                bit_cnt_rx <= DATA_WIDTH+2;
                data_reg_rx <= 0;
                busy_reg_rx <= 1;
            end
        end
    end
end


endmodule



