// created by verisplt.awk


        /*---------------------------------\
        | Advanced DSP Architectures Group |
        |          Macro  Library          |
        |       Designer: Tim Pagden       |
        |    ---- ----        ---- ----    |
        | Opened: 22 Jan 1992              |
        | Closed:                          |
        \_Modifications:__________________*/

`timescale 1ns/1ps

module mult_para_recurs_32_32_2sC (a,b,clk,reset,y);

input[31:0] a,b;
input clk,reset;
output[63:0] y;

  /*---------------------------------------\
  | _Function: always @ posedge clk        |
  |   y(t=0) = a(t-32) * b(t-32)           |
  \---------------------------------------*/

  /*---------------------------------------\
  | _Simulation:                           |
  |                                        |
  \---------------------------------------*/

reg[31:0] aR[32:0];
reg[31:0] bR[32:0];
reg[63:0] yR[32:0];

always @ (posedge clk)
  begin
    aR[32] = aR[31]; // pipeline statements
    bR[32] = bR[31];
    yR[32] = yR[31];
    aR[31] = aR[30];
    bR[31] = bR[30];
    yR[31] = yR[30];
    aR[30] = aR[29]; 
    bR[30] = bR[29];
    yR[30] = yR[29];
    aR[29] = aR[28]; 
    bR[29] = bR[28];
    yR[29] = yR[28];
    aR[28] = aR[27]; 
    bR[28] = bR[27];
    yR[28] = yR[27];
    aR[27] = aR[26]; 
    bR[27] = bR[26];
    yR[27] = yR[26];
    aR[26] = aR[25];
    bR[26] = bR[25];
    yR[26] = yR[25];
    aR[25] = aR[24];
    bR[25] = bR[24];
    yR[25] = yR[24];
    aR[24] = aR[23];
    bR[24] = bR[23];
    yR[24] = yR[23];
    aR[23] = aR[22];
    bR[23] = bR[22];
    yR[23] = yR[22];
    aR[22] = aR[21];
    bR[22] = bR[21];
    yR[22] = yR[21];
    aR[21] = aR[20];
    bR[21] = bR[20];
    yR[21] = yR[20];
    aR[20] = aR[19]; 
    bR[20] = bR[19];
    yR[20] = yR[19];
    aR[19] = aR[18]; 
    bR[19] = bR[18];
    yR[19] = yR[18];
    aR[18] = aR[17]; 
    bR[18] = bR[17];
    yR[18] = yR[17];
    aR[17] = aR[16]; 
    bR[17] = bR[16];
    yR[17] = yR[16];
    aR[16] = aR[15];
    bR[16] = bR[15];
    yR[16] = yR[15];
    aR[15] = aR[14];
    bR[15] = bR[14];
    yR[15] = yR[14];
    aR[14] = aR[13];
    bR[14] = bR[13];
    yR[14] = yR[13];
    aR[13] = aR[12];
    bR[13] = bR[12];
    yR[13] = yR[12];
    aR[12] = aR[11];
    bR[12] = bR[11];
    yR[12] = yR[11];
    aR[11] = aR[10];
    bR[11] = bR[10];
    yR[11] = yR[10];
    aR[10] = aR[9]; 
    bR[10] = bR[9];
    yR[10] = yR[9];
    aR[9] = aR[8]; 
    bR[9] = bR[8];
    yR[9] = yR[8];
    aR[8] = aR[7]; 
    bR[8] = bR[7];
    yR[8] = yR[7];
    aR[7] = aR[6]; 
    bR[7] = bR[6];
    yR[7] = yR[6];
    aR[6] = aR[5];
    bR[6] = bR[5];
    yR[6] = yR[5];
    aR[5] = aR[4];
    bR[5] = bR[4];
    yR[5] = yR[4];
    aR[4] = aR[3];
    bR[4] = bR[3];
    yR[4] = yR[3];
    aR[3] = aR[2];
    bR[3] = bR[2];
    yR[3] = yR[2];
    aR[2] = aR[1];
    bR[2] = bR[1];
    yR[2] = yR[1];
    aR[1] = aR[0];
    bR[1] = bR[0];
    yR[1] = yR[0];
                   // multiply result (a*b) appears after +clk
    aR[0] = a;
    bR[0] = b;
    yR[0] = multiply_32_32_2sC (aR[0],bR[0]);
  end

function[63:0] multiply_32_32_2sC;
input[31:0] a,b;

  /*---------------------------------------\
  | _Function:                             |
  |   y = a * b, in 2's complement format  |
  |   see, mult_para_recurs_32_32_2sC.v    |
  \---------------------------------------*/

  /*----------------------------------------\
  | _Simulation:                            |
  |  see, sim_mult_para_recurs_32_32_2sC.vs |
  \----------------------------------------*/

reg[31:0] a_mag,b_mag;
reg[62:0] y_mag;
reg[62:0] y_neg;
begin
  case (a[31])
    0: a_mag = a[30:0];
    1: a_mag = 32'd2147483648 - a[30:0];           // max(a_mag) = 2147483648, thus 32 bits
  endcase
  case (b[31])
    0: b_mag = b[30:0];
    1: b_mag = 32'd2147483648 - b[30:0];
  endcase
  y_mag = a_mag * b_mag;                       // max(y_mag) = 4611686018427387904, thus 63 bits
  if ((a[31] ^ b[31]) & (y_mag != 0))          // if (a * b) is -ve AND non-zero
  begin                                        // y_mag >=1, < 4611686018427387904, thus need only 62 bits
    y_neg = 64'd9223372036854775808 - y_mag[61:0]; // max(y_neg) = 9223372036854775807, thus need 63 bits
    multiply_32_32_2sC = {1'b1,y_neg}; 
  end
  else
    multiply_32_32_2sC = y_mag;
end
endfunction

assign y = yR[31];

endmodule
