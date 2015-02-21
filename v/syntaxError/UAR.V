 // Universal Asynchronous Receiver

        // Start detection
        module start_detect (valid, clk, reset, gl_reset, dIn);
        output       valid;
        input        clk, reset, gl_reset, dIn;
        reg    [3:0] shift_reg;

        always @ (posedge clk) begin
             if (reset | gl_reset)
                  shift_reg = 0;
             else
                  shift_reg = { shift_reg[2:0], dIn };
             end

        assign valid = (shift_reg [0] == 0) &
                       (shift_reg [2] == 0) &
                       (shift_reg [3] == 1);

        endmodule

        // controller
        module counter (count72, count8, clk, enable);
        output       count72, count8;
        input        clk, enable;
        wire         each8;
        reg    [8:0] count_reg;

        always @ (posedge clk)
             if (enable == 0)
                  count_reg <= 0;
             else begin
                  count_reg <= count_reg + 1;
             end

        assign each8   = ((count_reg % 8) == 7);
        assign count72 = (count_reg == 71);
        assign count8  = each8 & ~count72;

        endmodule

        // serial parallel converter
        module ser_par_conv (dOut, clk, enable, dIn);
        output [7:0] dOut;
        input        clk, enable, dIn;
        reg    [7:0] dOut;

        always @ (posedge clk)
             if (enable == 1)
                  dOut = {dIn, dOut[7:1]};

        endmodule

        // flags for ready and data error
        module flags (dReady, dError,  clk, set,  reset, dIn);
        output dReady, dError;
        input  clk, set,  reset, dIn;
        reg    dReady, dError;

        always @(posedge clk)
             if (reset == 1) begin
                  dReady = 0;
                  dError = 0;
                  end
             else if (set == 1) begin
                  dReady <= dIn;
                  dError <= ~dIn;
                  end

        initial $monitor("dReady %b %b", dReady, dError, $time);

        endmodule

        // generating the run signals
        module control (running, clk, reset, gl_reset, set);
        output running;
        input  clk, reset, gl_reset, set;
        reg    running;

        always @ (posedge clk)
             if ((reset == 1) | (gl_reset == 1))
                  running  =  0;
             else if (set == 1)
                  running = 1;
        endmodule

        // overall receiver definition
        module uar (dOut, dReady, dError, clk, gl_reset, dIn);
        output [7:0] dOut;
        output       dReady, dError;
        input        clk, gl_reset, dIn;

        wire         running, finish, count8, start;

        start_detect s_d (start, clk, running, gl_reset, dIn);
        counter      cov (finish, count8, clk, running);
        ser_par_conv s_p (dOut, clk, count8, dIn);
        flags        fla (dReady, dError, clk, finish, start, dIn);
        control      con (running, clk, finish, gl_reset, start);

        endmodule

        // test module
        module mytest;
        reg   clk, gl_reset, dIn;
        wire  [7:0] dOut;
        wire  dReady, dError;

        reg [7:0] inWord;

        uar mod1 (dOut, dReady, dError, clk, gl_reset, dIn);

        always #5 clk = ~clk;

        initial begin

             #0
             clk = 0;
             gl_reset = 1;
             inWord = 0;
             dIn = 1;
             #10
             gl_reset = 0;

             #80
             repeat (4) begin
                  // start of cycle

                  inWord = {$random} /2 % 128;
                  dIn = 1;

                  #80
                  dIn = 0;
                  #80
                  $display ("inWord = %b", inWord, $time);
                  repeat (8) begin
                       dIn    <= inWord[0];
                       inWord <= inWord >> 1;
                       #80;
                       end
                  $display ("outWord = %b (%b %b)", dOut, dReady, dError);
                  end
             // error condition 1
             dIn = 1;
             #80
             dIn = 0;
             #800
             $display ("outWord = %b (%b %b)", dOut, dReady, dError);
             $finish;
             end
        endmodule
        
        