/*
http://blessongeorgevlsi.blogspot.com/2012/04/design-of-universal-asynchronous.html
*/

module uart_tx(
                                clk,
                                rst_n,
                                write,
                                data,
                                txrdy,
                                tx);

         // Port declarations

              input       clk;
             input       rst_n;
             input       write;
             input [7:0] data;
             output      txrdy;
             output      tx;

       // Internal signal declarations

           reg         txdatardy;
          reg   [12:0] cnt;
          reg   [9:0]txdat;
          wire  [7:0] data_in;
          reg         baud_clk;
         wire        txrdy;
         reg         tx_sts;

        always @ (posedge clk)
             begin
                if(~rst_n)                                      tx_sts <= 1'b0;
                     else if(write&txrdy)               tx_sts <= 1'b1;
                    else if(txrdy)                            tx_sts <= 1'b0;
            end

       always @ (posedge clk)
           begin
                if(~rst_n)                                                        cnt <= 13'b0;
                 else if(tx_sts & (cnt[12:0] == 5208))           cnt <= 13'b0;
                 else if(tx_sts)                                                cnt <= cnt + 1;
             else                                                                   cnt <= 13'b0;
           end

          always @ (posedge clk)
              begin
                 if(~rst_n)                                             baud_clk <= 1'b0;
                else if(cnt[12:0] == 2601)                   baud_clk <= 1'b1;
                else                                                      baud_clk <= 1'b0;
             end

         always @ (posedge clk)
           begin
               if(~rst_n)                                             txdat <= 10'h0;
              else if(write & txrdy)                          txdat <= {1'b1,data,1'b0};
              else if(baud_clk)                                 txdat <= txdat>>1;
           end

     //assign data_in = {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]};
                assign tx      = txrdy ? 1'b1 : txdat[0];
                assign txrdy   = (!(|txdat));

           endmodule
