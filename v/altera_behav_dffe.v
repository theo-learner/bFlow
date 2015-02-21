module altera_behav_dffe (q, d, clk, ena, rsn, prn);

// port declaration

input   d, clk, ena, rsn, prn;
output  q;
reg     q;

always @ (posedge clk or negedge rsn or negedge prn) begin

//asynchronous active-low preset
    if (~prn)
        begin
        if (rsn)
            q = 1'b1;
        else
            q = 1'bx;
        end

//asynchronous active-low reset
     else if (~rsn)
        q = 1'b0;

//enable
     else if (ena)
        q = d;
end

endmodule
