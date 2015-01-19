//http://referencevoltage.com/?p=54

module uart_rx_only(errorOut, dataOut, dataAvailableOut, dataLoadIn, 
              serialIn, baudLoadHiIn, baudLoadLoIn, clk, reset);
  input serialIn, baudLoadHiIn, baudLoadLoIn, clk, reset;
  input [7:0] dataLoadIn; 
  output errorOut, dataAvailableOut;
  output [7:0] dataOut; 

  parameter S_idle = 0;  
  parameter S_shift = 1; 
  parameter S_waiting = 2; 

  //reg serialOut; 
  reg [1:0] state, nextState;
  reg [15:0] baudCount; 
  reg [15:0] stBaudCount;
  reg [15:0] baudPeriodHalf; 
  reg [15:0] baudPeriod; 
  reg [4:0] shiftCount; 
  reg [9:0] shiftReg; 
  reg errorOut;
  reg initializeData; 
  reg dataAvailableOut, enBaudClock, enStartBitCnt; 
  reg loadBaudH, loadBaudL;

  assign dataOut = shiftReg[8:1];

  always @ ( posedge clk) begin
    if( reset == 1) begin
      state <= S_idle;
    end
    else
      state <= nextState; 
  end 

  always @ ( * ) begin  
    nextState = S_idle;    
    dataAvailableOut = 0; 
    errorOut = 0; 
    enBaudClock = 0; 
    loadBaudH = 0;
    loadBaudL = 0;
    initializeData = 0; 
    enStartBitCnt = 0; 

    case (state)
      S_idle: begin
        if( reset == 1) nextState = S_idle; 
        else begin
          if( serialIn == 0) begin  // start bit....
            nextState = S_shift;
            initializeData = 1; 
          end
          if( baudLoadHiIn == 1)
            loadBaudH = 1;
          if( baudLoadLoIn == 1)
            loadBaudL = 1; 
        end
      end
      S_shift: begin
        if ( shiftCount == 10) begin
          dataAvailableOut = 1;  
          nextState = S_waiting;          
        end
        else begin
          if(shiftCount == 0) begin
            enStartBitCnt = 1; 
            nextState = S_shift; 
          end
          else begin
            enBaudClock = 1; 
            nextState = S_shift; 
          end 
        end            
      end
      S_waiting: begin
        dataAvailableOut = 1; 
        if( serialIn == 0) begin  // start bit....
          nextState = S_shift;
          initializeData = 1; 
        end
        else
          nextState = S_waiting;
        if( baudLoadHiIn == 1)
          loadBaudH = 1;
        if( baudLoadLoIn == 1)
          loadBaudL = 1; 
      end 
      default: 
        nextState = S_idle;
    endcase      
  end

  always @ ( posedge clk) begin
    if( initializeData == 1) begin
      shiftCount <= 0;  
      baudCount <= 0;
      stBaudCount <= 0; 
      shiftReg <= 8'hff;  
    end 
    if( enStartBitCnt == 1) begin
      if( stBaudCount == baudPeriodHalf) begin
        shiftCount <= 1; 
        shiftReg <= { serialIn, shiftReg[9:1]};//        
      end 
      else
        stBaudCount <= stBaudCount + 1; 
    end
    if( enBaudClock == 1) begin
      if( baudCount == baudPeriod) begin
        baudCount <= 0; 
        shiftReg <= { serialIn, shiftReg[9:1]};
        shiftCount <= shiftCount + 1;
      end
      else
        baudCount <= baudCount + 1;
    end
    if( loadBaudH == 1) begin
      baudPeriod[15:8] <= dataLoadIn;
      baudPeriodHalf[15:8] <= {1'b0, dataLoadIn[7:1]};
      baudPeriodHalf[7] <= dataLoadIn[0];      
    end
    if( loadBaudL == 1) begin
      baudPeriod[7:0] <= dataLoadIn;  
      baudPeriodHalf[6:0] <= dataLoadIn[7:1];
    end
  end
endmodule
