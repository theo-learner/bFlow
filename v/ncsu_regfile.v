//http://www.ece.ncsu.edu/asic/lect_NTU/AppendixA.pdf

module ncsu_regfile(clock, reset, writeEnable, dest, source, dataIn, dataOut);

parameter WIDTH = 16;

parameter DEPTH = 32;

parameter ADDRESSWIDTH = 5;

integer i,j;

input clock, reset, writeEnable;

input [ADDRESSWIDTH-1 : 0] dest;

input [ADDRESSWIDTH-1 : 0] source;

input [WIDTH-1 : 0] dataIn;

output [WIDTH-1 : 0] dataOut;

reg [WIDTH-1 : 0] dataOut; // registered output

reg [WIDTH-1 : 0] rf [DEPTH-1 : 0];

wire [DEPTH-1 : 0] writeEnableDecoded;

assign writeEnableDecoded = (writeEnable << dest);

// flip-flop for data-out

always@(posedge clock)

begin

if(!reset) dataOut <= 0;

else dataOut <= rf[source];

end

// memory array

always@(posedge clock)

begin

if(!reset)

begin

for(i = 0; i<DEPTH; i=i+1)

rf[i] <= 0;

end

else

begin

for (j=0; j<DEPTH; j=j+1)

if(writeEnableDecoded[j]) rf[j] <= dataIn;

end

end //always 
endmodule
