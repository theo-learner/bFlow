(* techmap_simplemap *)
(* techmap_celltype = "ADD" *)
module \$add (A, B, Y);

parameter A_SIGNED = 0;
parameter B_SIGNED = 0;
parameter A_WIDTH = 0;
parameter B_WIDTH = 0;
parameter Y_WIDTH = 0;

input  [A_WIDTH-1:0] A;
input  [B_WIDTH-1:0] B;
output [Y_WIDTH-1:0] Y;

wire _TECHMAP_FAIL_ = A_WIDTH != B_WIDTH;

endmodule
