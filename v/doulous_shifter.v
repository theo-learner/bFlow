// Shifter
// 
// +-----------------------------+
// |    Copyright 1996 DOULOS    |
// |     Library: Sequential     |
// |   designer : John Aynsley   |
// +-----------------------------+

module doulous_shifter (Clk, EN, WR, RD, SI, SO, Data);
  // synopsys template

  parameter Length = 8;

  input Clk, EN, WR, RD, SI;
  output SO;
  inout [Length-1:0] Data;

  reg SO;
  reg [Length-1:0] Reg;

  assign Data = !RD ? Reg : {Length{1'bz}};

  always @(posedge Clk)
    if (!EN)
    begin
      SO <= Reg[0];
      Reg = Reg >> 1;
      Reg[Length-1] = SI;
    end
    else if (!WR)
      Reg = Data;

  always @(WR or EN)
    if (!WR & !EN)
      $display("Error, Wr and En both active");

endmodule


