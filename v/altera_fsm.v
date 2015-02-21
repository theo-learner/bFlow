module altera_fsm(clk, in, reset, out);

input clk, in, reset;
output [3:0] out;

reg [3:0] out;
reg [1:0] state;

parameter zero=0, one=1, two=2, three=3;

always @(state) 
     begin
          case (state)
               zero:
                    out = 4'b0000;
               one:
                    out = 4'b0001;
               two:
                    out = 4'b0010;
               three:
                    out = 4'b0100;
               default:
                    out = 4'b0000;
          endcase
     end

always @(posedge clk or posedge reset)
     begin
          if (reset)
               state = zero;
          else
               case (state)
                    zero:
                         state = one;
                    one:
                         if (in)
                              state = zero;
                         else
                              state = two;
                    two:
                         state = three;
                    three:
                         state = zero;
               endcase
     end

endmodule

