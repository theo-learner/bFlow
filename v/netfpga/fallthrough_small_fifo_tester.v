// synthesis translate_off
module fallthrough_small_fifo_tester();

   reg [31:0] din = 0;
   reg        wr_en = 0;
   reg        rd_en = 0;
   wire [31:0] dout;
   wire        full;
   wire        nearly_full;
   wire        prog_full;
   wire        empty;
   reg         clk = 0;
   reg         reset = 0;

   integer     count = 0;

   always #8 clk = ~clk;

   fallthrough_small_fifo
     #(.WIDTH (32),
       .MAX_DEPTH_BITS (3),
       .PROG_FULL_THRESHOLD (4))
       fifo
        (.din           (din),
         .wr_en         (wr_en),
         .rd_en         (rd_en),
         .dout          (dout),
         .full          (full),
         .nearly_full   (nearly_full),
         .prog_full     (prog_full),
         .empty         (empty),
         .reset         (reset),
         .clk           (clk)
         );

   always @(posedge clk) begin
      count <= count + 1;
      reset <= 0;
      wr_en <= 0;
      rd_en <= 0;
      if(count < 2) begin
         reset <= 1'b1;
      end
      else if(count < 2 + 9) begin
         wr_en <= 1;
         din <= din + 1'b1;
      end
      else if(count < 2 + 8 + 4) begin
         rd_en <= 1;
      end
      else if(count < 2 + 8 + 4 + 2) begin
         din <= din + 1'b1;
         wr_en <= 1'b1;
      end
      else if(count < 2 + 8 + 4 + 2 + 8) begin
         din <= din + 1'b1;
         wr_en <= 1'b1;
         rd_en <= 1'b1;
      end
      else if(count < 2 + 8 + 4 + 2 + 8 + 4) begin
         rd_en <= 1'b1;
      end
      else if(count < 2 + 8 + 4 + 2 + 8 + 4 + 8) begin
         din <= din + 1'b1;
         wr_en <= 1'b1;
         rd_en <= 1'b1;
      end
   end // always @ (posedge clk)
endmodule // fallthrough_small_fifo_tester
// synthesis translate_on
