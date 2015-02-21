////////////////////////////////////////////////////////////////////////////////
//  File name : am29bdd160g.v
//-----------------------------------------------------------------------------
//  Copyright (C) 2003-2004 Free Model Foundry; http://www.FreeModelFoundry.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MODIFICATION HISTORY :
//
//  version: | author:    | mod date: | changes made:
//   v1.0     A.Savic       15 Aug 03  Initial release
//   v1.1     A.Savic       28 Aug 03  Bottom boot model implementation
//                                     Debugged
//   v1.2     A.Savic       03 Sep 03  DYB/PPBLock Status command, BA latched
//                                     Autoselect read - erase suspended sector
//                                     Unlock cycles address latch
//                                     Sector Address Window reset bug fix
//   v1.3     A.Savic       10 Sep 03  Clock period check added
//                                     PathDelaySection/PathConditions changed
//                                     according to AMD comments (access time)
//                                     Usertask added - fetch path delay values
//                                     using PLI
//   v1.4     A.Savic       12 Sep 03  Status checks changes
//                                     Status check bug fix
//   v1.5     A.Savic       02 Oct 03  PLI fetch_delays removed
//   v1.6     A.Savic       08 Oct 03  Top/Bottom architecture detect
//   v1.7     A.Savic       12 Nov 03  SM illegal commands fix
//                                     WP# pin erase protection fix
//                                     tdevice_CERASE removed
//   v1.8     A.Savic       11 Dec 03  RDY is an open drain output
//   v1.9     A.Savic       18 Dec 03  No bank restriction for Sector Erase
//                                     Suspended/Resumed for all banks
//   v1.10    A.Savic       14 Jan 04  Specify block path expansion for
//                                     unique ModelSim/NCSim Verilog SDF
//   v1.11    A.Savic       16 Jan 04  Preload section update - sector
//                                     contents independent preload
//
//------------------------------------------------------------------------------
//  PART DESCRIPTION:
//
//  Library:        AMD
//  Technology:     Flash Memory
//  Part:           AM29BDD160G
//
//  Description:    16Mbit (512x32-Bit/1Mx16-Bit)
//                  Burst Mode, Dual Boot, Simultaneous Read
//
//------------------------------------------------------------------------------
//  Known Bugs:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ns

module am29bdd160g
(
    A18      ,
    A17      ,
    A16      ,
    A15      ,
    A14      ,
    A13      ,
    A12      ,
    A11      ,
    A10      ,
    A9       ,
    A8       ,
    A7       ,
    A6       ,
    A5       ,
    A4       ,
    A3       ,
    A2       ,
    A1       ,
    A0       ,
    Am1      ,

    DQ31     ,
    DQ30     ,
    DQ29     ,
    DQ28     ,
    DQ27     ,
    DQ26     ,
    DQ25     ,
    DQ24     ,
    DQ23     ,
    DQ22     ,
    DQ21     ,
    DQ20     ,
    DQ19     ,
    DQ18     ,
    DQ17     ,
    DQ16     ,
    DQ15     ,
    DQ14     ,
    DQ13     ,
    DQ12     ,
    DQ11     ,
    DQ10     ,
    DQ9      ,
    DQ8      ,
    DQ7      ,
    DQ6      ,
    DQ5      ,
    DQ4      ,
    DQ3      ,
    DQ2      ,
    DQ1      ,
    DQ0      ,

    CENeg    ,
    OENeg    ,
    WENeg    ,
    RESETNeg ,
    ADVNeg   ,
    WPNeg    ,
    WORDNeg  ,
    CLK      ,
    RY       ,
    INDNeg
);

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////

    input  A18  ;
    input  A17  ;
    input  A16  ;
    input  A15  ;
    input  A14  ;
    input  A13  ;
    input  A12  ;
    input  A11  ;
    input  A10  ;
    input  A9   ;
    input  A8   ;
    input  A7   ;
    input  A6   ;
    input  A5   ;
    input  A4   ;
    input  A3   ;
    input  A2   ;
    input  A1   ;
    input  A0   ;
    input  Am1  ;

    inout  DQ31  ;
    inout  DQ30  ;
    inout  DQ29  ;
    inout  DQ28  ;
    inout  DQ27  ;
    inout  DQ26  ;
    inout  DQ25  ;
    inout  DQ24  ;
    inout  DQ23  ;
    inout  DQ22  ;
    inout  DQ21  ;
    inout  DQ20  ;
    inout  DQ19  ;
    inout  DQ18  ;
    inout  DQ17  ;
    inout  DQ16  ;
    inout  DQ15  ;
    inout  DQ14  ;
    inout  DQ13  ;
    inout  DQ12  ;
    inout  DQ11  ;
    inout  DQ10  ;
    inout  DQ9   ;
    inout  DQ8   ;
    inout  DQ7   ;
    inout  DQ6   ;
    inout  DQ5   ;
    inout  DQ4   ;
    inout  DQ3   ;
    inout  DQ2   ;
    inout  DQ1   ;
    inout  DQ0   ;

    input  CENeg    ;
    input  OENeg    ;
    input  WENeg    ;
    input  RESETNeg ;
    input  ADVNeg   ;
    input  WPNeg    ;
    input  WORDNeg  ;
    input  CLK      ;
    output RY       ;
    output INDNeg   ;

// interconnect path delay signals
    wire  A18_ipd  ;
    wire  A17_ipd  ;
    wire  A16_ipd  ;
    wire  A15_ipd  ;
    wire  A14_ipd  ;
    wire  A13_ipd  ;
    wire  A12_ipd  ;
    wire  A11_ipd  ;
    wire  A10_ipd  ;
    wire  A9_ipd   ;
    wire  A8_ipd   ;
    wire  A7_ipd   ;
    wire  A6_ipd   ;
    wire  A5_ipd   ;
    wire  A4_ipd   ;
    wire  A3_ipd   ;
    wire  A2_ipd   ;
    wire  A1_ipd   ;
    wire  A0_ipd   ;

    wire [18 : 0] A;
    assign A = {A18_ipd,
                A17_ipd,
                A16_ipd,
                A15_ipd,
                A14_ipd,
                A13_ipd,
                A12_ipd,
                A11_ipd,
                A10_ipd,
                A9_ipd,
                A8_ipd,
                A7_ipd,
                A6_ipd,
                A5_ipd,
                A4_ipd,
                A3_ipd,
                A2_ipd,
                A1_ipd,
                A0_ipd };

    wire  DQ31_ipd  ;
    wire  DQ30_ipd  ;
    wire  DQ29_ipd  ;
    wire  DQ28_ipd  ;
    wire  DQ27_ipd  ;
    wire  DQ26_ipd  ;
    wire  DQ25_ipd   ;
    wire  DQ24_ipd   ;
    wire  DQ23_ipd   ;
    wire  DQ22_ipd   ;
    wire  DQ21_ipd   ;
    wire  DQ20_ipd   ;
    wire  DQ19_ipd   ;
    wire  DQ18_ipd   ;
    wire  DQ17_ipd   ;
    wire  DQ16_ipd   ;
    wire  DQ15_ipd  ;
    wire  DQ14_ipd  ;
    wire  DQ13_ipd  ;
    wire  DQ12_ipd  ;
    wire  DQ11_ipd  ;
    wire  DQ10_ipd  ;
    wire  DQ9_ipd   ;
    wire  DQ8_ipd   ;
    wire  DQ7_ipd   ;
    wire  DQ6_ipd   ;
    wire  DQ5_ipd   ;
    wire  DQ4_ipd   ;
    wire  DQ3_ipd   ;
    wire  DQ2_ipd   ;
    wire  DQ1_ipd   ;
    wire  DQ0_ipd   ;

    wire [31 : 0 ] DIn;
    assign DIn = {DQ31_ipd,
                  DQ30_ipd,
                  DQ29_ipd,
                  DQ28_ipd,
                  DQ27_ipd,
                  DQ26_ipd,
                  DQ25_ipd,
                  DQ24_ipd,
                  DQ23_ipd,
                  DQ22_ipd,
                  DQ21_ipd,
                  DQ20_ipd,
                  DQ19_ipd,
                  DQ18_ipd,
                  DQ17_ipd,
                  DQ16_ipd,
                  DQ15_ipd,
                  DQ14_ipd,
                  DQ13_ipd,
                  DQ12_ipd,
                  DQ11_ipd,
                  DQ10_ipd,
                  DQ9_ipd,
                  DQ8_ipd,
                  DQ7_ipd,
                  DQ6_ipd,
                  DQ5_ipd,
                  DQ4_ipd,
                  DQ3_ipd,
                  DQ2_ipd,
                  DQ1_ipd,
                  DQ0_ipd };

    wire [31 : 0 ] DOut;
    assign DOut = {
                  DQ31,
                  DQ30,
                  DQ29,
                  DQ28,
                  DQ27,
                  DQ26,
                  DQ25,
                  DQ24,
                  DQ23,
                  DQ22,
                  DQ21,
                  DQ20,
                  DQ19,
                  DQ18,
                  DQ17,
                  DQ16,
                  DQ15,
                  DQ14,
                  DQ13,
                  DQ12,
                  DQ11,
                  DQ10,
                  DQ9,
                  DQ8,
                  DQ7,
                  DQ6,
                  DQ5,
                  DQ4,
                  DQ3,
                  DQ2,
                  DQ1,
                  DQ0 };

    wire  CENeg_ipd    ;
    wire  OENeg_ipd    ;
    wire  WENeg_ipd    ;
    wire  RESETNeg_ipd ;
    wire  ADVNeg_ipd   ;
    wire  WPNeg_ipd    ;
    wire  WORDNeg_ipd  ;
    wire  CLK_ipd      ;
    wire  Am1_ipd      ;

//  internal delays
    reg WPProg_in;
    reg WPProg_out;
    reg PErase_in;
    reg PErase_out;
    reg SUS_in;
    reg SUS_out;
    reg CErase_in;
    reg CErase_out;
    reg SAWindow_in;
    reg SAWindow_out;
    reg RESInterval_in;
    reg RESInterval_out;
    reg NVProg_in;
    reg NVProg_out;
    reg NVErs_in;
    reg NVErs_out;

    wire  DQ31_zd  ;
    wire  DQ30_zd  ;
    wire  DQ29_zd  ;
    wire  DQ28_zd  ;
    wire  DQ27_zd  ;
    wire  DQ26_zd  ;
    wire  DQ25_zd  ;
    wire  DQ24_zd  ;
    wire  DQ23_zd  ;
    wire  DQ22_zd  ;
    wire  DQ21_zd  ;
    wire  DQ20_zd  ;
    wire  DQ19_zd  ;
    wire  DQ18_zd  ;
    wire  DQ17_zd  ;
    wire  DQ16_zd  ;
    wire  DQ15_zd  ;
    wire  DQ14_zd  ;
    wire  DQ13_zd  ;
    wire  DQ12_zd  ;
    wire  DQ11_zd  ;
    wire  DQ10_zd  ;
    wire  DQ9_zd   ;
    wire  DQ8_zd   ;
    wire  DQ7_zd   ;
    wire  DQ6_zd   ;
    wire  DQ5_zd   ;
    wire  DQ4_zd   ;
    wire  DQ3_zd   ;
    wire  DQ2_zd   ;
    wire  DQ1_zd   ;
    wire  DQ0_zd   ;

    reg [31 : 0] DOut_zd;
    //reg [31 : 0] DOut_pass;
    assign {DQ31_zd,
            DQ30_zd,
            DQ29_zd,
            DQ28_zd,
            DQ27_zd,
            DQ26_zd,
            DQ25_zd,
            DQ24_zd,
            DQ23_zd,
            DQ22_zd,
            DQ21_zd,
            DQ20_zd,
            DQ19_zd,
            DQ18_zd,
            DQ17_zd,
            DQ16_zd,
            DQ15_zd,
            DQ14_zd,
            DQ13_zd,
            DQ12_zd,
            DQ11_zd,
            DQ10_zd,
            DQ9_zd,
            DQ8_zd,
            DQ7_zd,
            DQ6_zd,
            DQ5_zd,
            DQ4_zd,
            DQ3_zd,
            DQ2_zd,
            DQ1_zd,
            DQ0_zd  } = DOut_zd;

    reg RY_zd;
    reg INDNeg_zd;

    parameter UserPreload     = 0;
    parameter mem_file_name   = "none";
    parameter prot_file_name  = "none";
    parameter secsi_file_name = "none";

    parameter TimingModel = "DefaultTimingModel";

    parameter PartID    = "AM29BDD160G";
    parameter HiAddrBit = 18;
    parameter MaxData   = 16'hFFFF;
    parameter ADDRRange = 20'hFFFFF;
    parameter SmallSecSize = 16'hFFF;
    parameter SecSiSize = 128;  // 256B or 128W
    parameter SecNum    = 45;
    parameter GroupNum  = 23;

    //varaibles to resolve if bottom or top architecture is used
    reg [20*8-1:0] tmp_timing;//stores copy of TimingModel
    reg [7:0] tmp_char;//stores "t" or "b" character
    reg found = 1'b0;
    reg TopArch;

    parameter tcomm     = 1;
    parameter ttran     = 10;

    parameter OW0 = 6'b011010;
    parameter OW1 = 6'b011110;
    parameter PL0 = 6'b001010;
    parameter PL1 = 6'b001110;
    parameter SL0 = 6'b010010;
    parameter SL1 = 6'b010110;
    parameter WP0 = 6'b111010;
    parameter WP1 = 6'b111110;

 parameter DUMMY                =5'd0;
 parameter READ_ASYNC           =5'd1;
 parameter READ_SYNC            =5'd2;
 parameter CANNOTREAD           =5'd3;
 parameter PROGCYC              =5'd4;
 parameter CRVERIFY             =5'd5;
 parameter CRWRITE              =5'd6;
 parameter BITSTATUS            =5'd7;
 parameter DYB_WE               =5'd8;
 parameter DYBPPBSTATUS         =5'd9;
 parameter WRITESTATUS          =5'd10;
 parameter ASEL                 =5'd11;
 parameter READ_CFI             =5'd12;
 parameter CESTATUS             =5'd13;
 parameter SESTATUS             =5'd14;
 parameter PPB_STATUS           =5'd15;
 parameter PPB_ALL_STATUS       =5'd16;
 parameter READ_ESP             =5'd17;
 parameter WRITESTATUS_ESP      =5'd18;
 parameter READ_PSP             =5'd19;
 parameter PROGCYC_E            =5'd20;
 parameter READ_PSP_E           =5'd21;
 parameter WRITESTATUS_E        =5'd22;
 parameter PASS_PROGRAM_STATUS  =5'd23;
 parameter PASS_UNLOCK_STATUS   =5'd24;
 parameter PASS_VERIFY          =5'd25;
 parameter READ_BURST           =5'd26;
 parameter STATUS_SYNC          =5'd27;
 parameter NV_STATUS            =5'd28;
 parameter PPB_VERIFY           =5'd29;

 //parameter DUMMY              =5'd0;
 parameter INIT                 =5'd1;
 parameter IRREG                =5'd2;
 parameter WRITECYC             =5'd3;
 parameter RESET_OR_IGNORE      =5'd4;
 parameter TWO_UNLOCK           =5'd5;
 parameter CERASESEQ            =5'd6;
 parameter CERASESEQ_UBP        =5'd7;
 parameter CE                   =5'd8;
 parameter BITOP                =5'd9;
 parameter SecEXIT              =5'd10;
 parameter PROGRAM              =5'd11;
 parameter PROGRAM_UBP          =5'd12;
 parameter PROGRAM_E            =5'd13;
 parameter PROGRAM_PASS         =5'd14;
 parameter PROGRAM_NV           =5'd15;
 parameter PASS_PROGRAM         =5'd16;
 parameter PASS_UNLOCK          =5'd17;
 parameter UBP                  =5'd18;
 parameter UBPRESET             =5'd19;
 parameter SETIMEOUT            =5'd20;
 parameter SE                   =5'd21;
 parameter ESP                  =5'd22;
 parameter ESP_CFI              =5'd23;
 parameter ESP_ASEL             =5'd24;
 parameter PSP                  =5'd25;
 parameter PSP_E                =5'd26;
 parameter PSP_CFI              =5'd27;
 parameter PSP_E_CFI            =5'd28;
 parameter PSP_ASEL             =5'd29;
 parameter PSP_E_ASEL           =5'd30;

 parameter SMALL                =1'd0;
 parameter LARGE                =1'd1;

 reg  [4:0] CurrentState;
 reg  [4:0] CommandCurrentState;
 reg  [4:0] CurrentBack;
 reg  [4:0] CommandBack;

   reg Viol = 1'b0;
   reg[15:0] Zzz  = 16'bzzzzzzzzzzzzzzzz;

   // dual boot parameters
   integer SecSiSector;
   integer HWProtect1;
   integer HWProtect2;

   // detecting command cycles
   integer CommandRegAddr;
   integer CommandRegData;
   event   CommandDataLatched;
   event   ReadAddrLatched;
   reg[HiAddrBit:0] LatchAddr;
   reg LatchAddrLSB;
   reg[31:0] LatchData;
   integer   SectorID;
   integer   GroupID;

   // device mode parameters and protection bits
   reg SYNC = 0;
   reg SecSiENABLED =0;
   reg UNLOCKBYPASS =0;
   reg PersistentMODELock;
   reg PasswordMODELock;
   reg SecSiPB;
   reg[SecNum:0] DYB;
   reg[15:0]     ConfReg;
   reg[31:0]     StatusReg;
   reg PPBLockBit;
   reg[GroupNum:0] PPB;

   reg[15:0] PasswordRegion[0:3];
   integer SecSiRegion[0:SecSiSize-1];

   reg     EraseSecFlag[SecNum:0];
   time SETime;

   reg PassWindow = 1'b0;
   reg ProgStart;
   reg ProgResume;
   reg ProgSuspend;
   reg ProgDone;
   reg PassProgDone;
   reg SEStart;
   reg SEStartSuspend;
   reg SEDone;
   reg SEResume;
   reg SESuspend;

   integer PPBSequenceProg    = 0;
   integer PPBSequenceErase   = 0;
   integer SSBSequence        = 0;
   integer PPMLBSequence      = 0;
   integer SPMLBSequence      = 0;
   integer CESeq              = 0;
   integer CESeqUBP           = 0;
   integer RESSeqUBP          = 0;
   integer SecSiPBSequence    = 0;
   integer PassProgSequence   = 0;
   integer PassUnlockSequence = 0;

   reg EraseBankSMALL;
   reg EraseBankLARGE;

   reg CRVerifySmallBank;
   reg BankProg;
   //reg BankErase;
   reg BankASEL;
   reg BankDYBPPB;

   integer AddrLOW;
   integer AddrHIGH;

   reg ASELFlag;

   reg RESET_D = 1;
   // glitch protection
   reg OENeg_gl;
   reg CENeg_gl;
   reg WENeg_gl;
   reg PoweredUp = 0;

   reg OE_burst;

   event LatchNow_A;
   event LatchNow_D;
   event ReadNow;

   event SYNC_T;
   event SYNCSTATUS_T;
   event SYNCBACK_T;
   event DUMMY_T;

   event ProgDoneE;
   event PassProgDoneE;
   event PassWindowE;
   event SEDoneE;

   // Command Detect
   reg latched = 1'b0;

   // CommandStateGen
   reg FirstUnlockCycle = 1'b0;
   reg IrregularSeq     = 1'b0;
   integer SecSiEE;
   reg ESPProg;
   reg AllProtected;
   reg SEProtected;
   reg PassWORD;
   reg UNLOCK_1;
   reg UNLOCK_2;
   reg VALIDCYC;
   reg[31:0] PassData;
   integer   PassAddr;
   integer   PassORDER=0;
   reg UnlockPassOK = 1'b1;
   //Functional
   integer   Flash[0:ADDRRange];
   integer   CFI_array[0:197];
   integer   ASEL_array[0:15];
   integer   AddrConv;
   reg[31:0] DataProg;

   integer CFIIndex;

   integer AddrProg;
   integer WORDProg;
   integer SectorProg;
   integer GroupProg;

   integer SEC;
   reg[19:0] HelpSLV;

   reg[19:0] BurstAddr[0:31];
   integer BurstBorder;
   integer BurstCount;
   integer BurstInd;
   integer BurstDelay;
   integer ReadOK;
   reg[31:0]  SyncData;
   reg[31:0]  ReadData;

   reg[18:0] RdA;
   reg RdAm1;
   reg[31:0] DOut_temp;

   time EPAStart;
   time EPAInterval;
   time SECEStart;
   time SEInterval;

   time OEDQ_t;
   time CEDQ_t;
   time OENeg_event;
   time CENeg_event;
   reg FROMOE;
   reg FROMCE;
   reg SWITCH;
   // will be fetched by PLI routine called from usertask
   integer   OEDQ_01;
   integer   CEDQ_01;

   wire SYNCn;

   integer i,j;

    integer border = 8'hFE;
    wire deg;
    reg deq;

   reg[31:0] FlashData;
   reg[15:0] R1;
   reg[15:0] R2;


///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////


 buf   (A18_ipd, A18);
 buf   (A17_ipd, A17);
 buf   (A16_ipd, A16);
 buf   (A15_ipd, A15);
 buf   (A14_ipd, A14);
 buf   (A13_ipd, A13);
 buf   (A12_ipd, A12);
 buf   (A11_ipd, A11);
 buf   (A10_ipd, A10);
 buf   (A9_ipd , A9 );
 buf   (A8_ipd , A8 );
 buf   (A7_ipd , A7 );
 buf   (A6_ipd , A6 );
 buf   (A5_ipd , A5 );
 buf   (A4_ipd , A4 );
 buf   (A3_ipd , A3 );
 buf   (A2_ipd , A2 );
 buf   (A1_ipd , A1 );
 buf   (A0_ipd , A0 );
 buf   (Am1_ipd, Am1);

 buf   (DQ31_ipd, DQ31);
 buf   (DQ30_ipd, DQ30);
 buf   (DQ29_ipd, DQ29);
 buf   (DQ28_ipd, DQ28);
 buf   (DQ27_ipd, DQ27);
 buf   (DQ26_ipd, DQ26);
 buf   (DQ25_ipd, DQ25);
 buf   (DQ24_ipd, DQ24);
 buf   (DQ23_ipd, DQ23);
 buf   (DQ22_ipd, DQ22);
 buf   (DQ21_ipd, DQ21);
 buf   (DQ20_ipd, DQ20);
 buf   (DQ19_ipd, DQ19);
 buf   (DQ18_ipd, DQ18);
 buf   (DQ17_ipd, DQ17);
 buf   (DQ16_ipd, DQ16);
 buf   (DQ15_ipd, DQ15);
 buf   (DQ14_ipd, DQ14);
 buf   (DQ13_ipd, DQ13);
 buf   (DQ12_ipd, DQ12);
 buf   (DQ11_ipd, DQ11);
 buf   (DQ10_ipd, DQ10);
 buf   (DQ9_ipd , DQ9 );
 buf   (DQ8_ipd , DQ8 );
 buf   (DQ7_ipd , DQ7 );
 buf   (DQ6_ipd , DQ6 );
 buf   (DQ5_ipd , DQ5 );
 buf   (DQ4_ipd , DQ4 );
 buf   (DQ3_ipd , DQ3 );
 buf   (DQ2_ipd , DQ2 );
 buf   (DQ1_ipd , DQ1 );
 buf   (DQ0_ipd , DQ0 );

 buf   (CENeg_ipd    , CENeg    );
 buf   (OENeg_ipd    , OENeg    );
 buf   (WENeg_ipd    , WENeg    );
 buf   (RESETNeg_ipd , RESETNeg );
 buf   (ADVNeg_ipd   , ADVNeg   );
 buf   (WPNeg_ipd    , WPNeg    );
 buf   (WORDNeg_ipd  , WORDNeg  );
 buf   (CLK_ipd      , CLK      );

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
 nmos   (DQ31,   DQ31_zd , 1);
 nmos   (DQ30,   DQ30_zd , 1);
 nmos   (DQ29,   DQ29_zd , 1);
 nmos   (DQ28,   DQ28_zd , 1);
 nmos   (DQ27,   DQ27_zd , 1);
 nmos   (DQ26,   DQ26_zd , 1);
 nmos   (DQ25,   DQ25_zd , 1);
 nmos   (DQ24,   DQ24_zd , 1);
 nmos   (DQ23,   DQ23_zd , 1);
 nmos   (DQ22,   DQ22_zd , 1);
 nmos   (DQ21,   DQ21_zd , 1);
 nmos   (DQ20,   DQ20_zd , 1);
 nmos   (DQ19,   DQ19_zd , 1);
 nmos   (DQ18,   DQ18_zd , 1);
 nmos   (DQ17,   DQ17_zd , 1);
 nmos   (DQ16,   DQ16_zd , 1);
 nmos   (DQ15,   DQ15_zd , 1);
 nmos   (DQ14,   DQ14_zd , 1);
 nmos   (DQ13,   DQ13_zd , 1);
 nmos   (DQ12,   DQ12_zd , 1);
 nmos   (DQ11,   DQ11_zd , 1);
 nmos   (DQ10,   DQ10_zd , 1);
 nmos   (DQ9 ,   DQ9_zd  , 1);
 nmos   (DQ8 ,   DQ8_zd  , 1);
 nmos   (DQ7 ,   DQ7_zd  , 1);
 nmos   (DQ6 ,   DQ6_zd  , 1);
 nmos   (DQ5 ,   DQ5_zd  , 1);
 nmos   (DQ4 ,   DQ4_zd  , 1);
 nmos   (DQ3 ,   DQ3_zd  , 1);
 nmos   (DQ2 ,   DQ2_zd  , 1);
 nmos   (DQ1 ,   DQ1_zd  , 1);
 nmos   (DQ0 ,   DQ0_zd  , 1);

 nmos   (RY    ,   1'b0     , ~RY_zd);
 nmos   (INDNeg,   INDNeg_zd, 1     );

 specify

        // tipd delays: interconnect path delays , mapped to input port delays.
        // In Verilog is not necessary to declare any tipd_ delay variables,
        // they can be taken from SDF file
        // With all the other delays real delays would be taken from SDF file

        // tpd delays
     specparam           tpd_A0_DQ0              =1;
     specparam           tpd_CENeg_DQ0           =1;
     specparam           tpd_CENeg_INDNeg        =1;
                       //(tCE,tCE,tDF,-,tDF,-)
     specparam           tpd_OENeg_DQ0           =1;
     specparam           tpd_OENeg_INDNeg        =1;
                       //(tOE,tOE,tDF,-,tDF,-)
     specparam           tpd_CLK_DQ0             =1;
     specparam           tpd_CLK_INDNeg          =1;
     specparam           tpd_CENeg_RY            =1;    //tBUSY
     specparam           tpd_WENeg_RY            =1;    //tBUSY

       // tsetup values: setup time

     specparam           tsetup_CENeg_CLK         =1;
     specparam           tsetup_ADVNeg_CLK        =1;
     specparam           tsetup_A0_CLK            =1;
     specparam           tsetup_CENeg_WENeg       =1;
     specparam           tsetup_A0_WENeg          =1;
     specparam           tsetup_DQ0_WENeg         =1;
     specparam           tsetup_WENeg_CLK         =1;
     specparam           tsetup_WENeg_ADVNeg      =1;
     specparam           tsetup_WPNeg_WENeg       =1;
     specparam           tsetup_WENeg_CENeg       =1;

       // thold values: hold times
     specparam           thold_ADVNeg_CLK        =1;
     specparam           thold_A0_CLK            =1;
     specparam           thold_INDNeg_CLK        =1;
     specparam           thold_CENeg_WENeg       =1;
     specparam           thold_WENeg_CENeg       =1;
     specparam           thold_A0_WENeg          =1;
     specparam           thold_DQ0_WENeg         =1;
     specparam           thold_WENeg_ADVNeg      =1;
     specparam           thold_CENeg_RESETNeg    =1;
     specparam           thold_WENeg_RESETNeg    =1;
     specparam           thold_OENeg_RESETNeg    =1;
     specparam           thold_OENeg_WENeg       =1;
     specparam           thold_WENeg_OENeg       =1;

         // tpw values: pulse width
     specparam           tpw_RESETNeg_negedge    =1;
     specparam           tpw_WENeg_negedge       =1;
     specparam           tpw_WENeg_posedge       =1;
     specparam           tpw_CENeg_negedge       =1;
     specparam           tpw_CENeg_posedge       =1;
     specparam           tpw_CLK_negedge         =1;
     specparam           tpw_CLK_posedge         =1;
     specparam           tpw_ADVNeg_negedge      =1;

     specparam           trecovery_OENeg_WENeg   =1;
     specparam           trecovery_OENeg_CENeg   =1;

     specparam           tperiod_CLK             =1;

        // tdevice values: values for internal delays

     specparam   tdevice_WPProg                  = 1000;
     specparam   tdevice_PErase                  = 100000;
     specparam   tdevice_UNLOCK                  = 2000;
     specparam   tdevice_RESEMB                  = 11000;
     specparam   tdevice_EPA16                   = 15000;
     specparam   tdevice_EPA32                   = 18000;
     specparam   tdevice_SUSPEND                 = 8000;

     specparam   tdevice_SE                      = 1000000000;
     specparam   tdevice_NVPROG                  = 150000;
     specparam   tdevice_NVERS                   = 15000000;
     specparam   tdevice_SAWIN                   = 80000;

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////

    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ0 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ1 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ2 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ3 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ4 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ5 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ6 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ7 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ8 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ9 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ10 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ11 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ12 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ13 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ14 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ15 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ16 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ17 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ18 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ19 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ20 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ21 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ22 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ23 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ24 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ25 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ26 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ27 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ28 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ29 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ30 ) = tpd_CENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMCE))
        ( CENeg => DQ31 ) = tpd_CENeg_DQ0;

    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ0 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ1 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ2 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ3 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ4 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ5 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ6 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ7 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ8 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ9 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ10 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ11 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ12 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ13 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ14 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ15 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ16 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ17 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ18 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ19 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ20 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ21 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ22 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ23 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ24 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ25 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ26 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ27 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ28 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ29 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ30 ) = tpd_OENeg_DQ0;
    if (~SWITCH || (SWITCH && FROMOE))
        ( OENeg => DQ31 ) = tpd_OENeg_DQ0;

        ( A0 => DQ0 ) = tpd_A0_DQ0;
        ( A0 => DQ1 ) = tpd_A0_DQ0;
        ( A0 => DQ2 ) = tpd_A0_DQ0;
        ( A0 => DQ3 ) = tpd_A0_DQ0;
        ( A0 => DQ4 ) = tpd_A0_DQ0;
        ( A0 => DQ5 ) = tpd_A0_DQ0;
        ( A0 => DQ6 ) = tpd_A0_DQ0;
        ( A0 => DQ7 ) = tpd_A0_DQ0;
        ( A0 => DQ8 ) = tpd_A0_DQ0;
        ( A0 => DQ9 ) = tpd_A0_DQ0;
        ( A0 => DQ10 ) = tpd_A0_DQ0;
        ( A0 => DQ11 ) = tpd_A0_DQ0;
        ( A0 => DQ12 ) = tpd_A0_DQ0;
        ( A0 => DQ13 ) = tpd_A0_DQ0;
        ( A0 => DQ14 ) = tpd_A0_DQ0;
        ( A0 => DQ15 ) = tpd_A0_DQ0;
        ( A0 => DQ16 ) = tpd_A0_DQ0;
        ( A0 => DQ17 ) = tpd_A0_DQ0;
        ( A0 => DQ18 ) = tpd_A0_DQ0;
        ( A0 => DQ19 ) = tpd_A0_DQ0;
        ( A0 => DQ20 ) = tpd_A0_DQ0;
        ( A0 => DQ21 ) = tpd_A0_DQ0;
        ( A0 => DQ22 ) = tpd_A0_DQ0;
        ( A0 => DQ23 ) = tpd_A0_DQ0;
        ( A0 => DQ24 ) = tpd_A0_DQ0;
        ( A0 => DQ25 ) = tpd_A0_DQ0;
        ( A0 => DQ26 ) = tpd_A0_DQ0;
        ( A0 => DQ27 ) = tpd_A0_DQ0;
        ( A0 => DQ28 ) = tpd_A0_DQ0;
        ( A0 => DQ29 ) = tpd_A0_DQ0;
        ( A0 => DQ30 ) = tpd_A0_DQ0;
        ( A0 => DQ31 ) = tpd_A0_DQ0;
        ( A1 => DQ0 ) = tpd_A0_DQ0;
        ( A1 => DQ1 ) = tpd_A0_DQ0;
        ( A1 => DQ2 ) = tpd_A0_DQ0;
        ( A1 => DQ3 ) = tpd_A0_DQ0;
        ( A1 => DQ4 ) = tpd_A0_DQ0;
        ( A1 => DQ5 ) = tpd_A0_DQ0;
        ( A1 => DQ6 ) = tpd_A0_DQ0;
        ( A1 => DQ7 ) = tpd_A0_DQ0;
        ( A1 => DQ8 ) = tpd_A0_DQ0;
        ( A1 => DQ9 ) = tpd_A0_DQ0;
        ( A1 => DQ10 ) = tpd_A0_DQ0;
        ( A1 => DQ11 ) = tpd_A0_DQ0;
        ( A1 => DQ12 ) = tpd_A0_DQ0;
        ( A1 => DQ13 ) = tpd_A0_DQ0;
        ( A1 => DQ14 ) = tpd_A0_DQ0;
        ( A1 => DQ15 ) = tpd_A0_DQ0;
        ( A1 => DQ16 ) = tpd_A0_DQ0;
        ( A1 => DQ17 ) = tpd_A0_DQ0;
        ( A1 => DQ18 ) = tpd_A0_DQ0;
        ( A1 => DQ19 ) = tpd_A0_DQ0;
        ( A1 => DQ20 ) = tpd_A0_DQ0;
        ( A1 => DQ21 ) = tpd_A0_DQ0;
        ( A1 => DQ22 ) = tpd_A0_DQ0;
        ( A1 => DQ23 ) = tpd_A0_DQ0;
        ( A1 => DQ24 ) = tpd_A0_DQ0;
        ( A1 => DQ25 ) = tpd_A0_DQ0;
        ( A1 => DQ26 ) = tpd_A0_DQ0;
        ( A1 => DQ27 ) = tpd_A0_DQ0;
        ( A1 => DQ28 ) = tpd_A0_DQ0;
        ( A1 => DQ29 ) = tpd_A0_DQ0;
        ( A1 => DQ30 ) = tpd_A0_DQ0;
        ( A1 => DQ31 ) = tpd_A0_DQ0;
        ( A2 => DQ0 ) = tpd_A0_DQ0;
        ( A2 => DQ1 ) = tpd_A0_DQ0;
        ( A2 => DQ2 ) = tpd_A0_DQ0;
        ( A2 => DQ3 ) = tpd_A0_DQ0;
        ( A2 => DQ4 ) = tpd_A0_DQ0;
        ( A2 => DQ5 ) = tpd_A0_DQ0;
        ( A2 => DQ6 ) = tpd_A0_DQ0;
        ( A2 => DQ7 ) = tpd_A0_DQ0;
        ( A2 => DQ8 ) = tpd_A0_DQ0;
        ( A2 => DQ9 ) = tpd_A0_DQ0;
        ( A2 => DQ10 ) = tpd_A0_DQ0;
        ( A2 => DQ11 ) = tpd_A0_DQ0;
        ( A2 => DQ12 ) = tpd_A0_DQ0;
        ( A2 => DQ13 ) = tpd_A0_DQ0;
        ( A2 => DQ14 ) = tpd_A0_DQ0;
        ( A2 => DQ15 ) = tpd_A0_DQ0;
        ( A2 => DQ16 ) = tpd_A0_DQ0;
        ( A2 => DQ17 ) = tpd_A0_DQ0;
        ( A2 => DQ18 ) = tpd_A0_DQ0;
        ( A2 => DQ19 ) = tpd_A0_DQ0;
        ( A2 => DQ20 ) = tpd_A0_DQ0;
        ( A2 => DQ21 ) = tpd_A0_DQ0;
        ( A2 => DQ22 ) = tpd_A0_DQ0;
        ( A2 => DQ23 ) = tpd_A0_DQ0;
        ( A2 => DQ24 ) = tpd_A0_DQ0;
        ( A2 => DQ25 ) = tpd_A0_DQ0;
        ( A2 => DQ26 ) = tpd_A0_DQ0;
        ( A2 => DQ27 ) = tpd_A0_DQ0;
        ( A2 => DQ28 ) = tpd_A0_DQ0;
        ( A2 => DQ29 ) = tpd_A0_DQ0;
        ( A2 => DQ30 ) = tpd_A0_DQ0;
        ( A2 => DQ31 ) = tpd_A0_DQ0;
        ( A3 => DQ0 ) = tpd_A0_DQ0;
        ( A3 => DQ1 ) = tpd_A0_DQ0;
        ( A3 => DQ2 ) = tpd_A0_DQ0;
        ( A3 => DQ3 ) = tpd_A0_DQ0;
        ( A3 => DQ4 ) = tpd_A0_DQ0;
        ( A3 => DQ5 ) = tpd_A0_DQ0;
        ( A3 => DQ6 ) = tpd_A0_DQ0;
        ( A3 => DQ7 ) = tpd_A0_DQ0;
        ( A3 => DQ8 ) = tpd_A0_DQ0;
        ( A3 => DQ9 ) = tpd_A0_DQ0;
        ( A3 => DQ10 ) = tpd_A0_DQ0;
        ( A3 => DQ11 ) = tpd_A0_DQ0;
        ( A3 => DQ12 ) = tpd_A0_DQ0;
        ( A3 => DQ13 ) = tpd_A0_DQ0;
        ( A3 => DQ14 ) = tpd_A0_DQ0;
        ( A3 => DQ15 ) = tpd_A0_DQ0;
        ( A3 => DQ16 ) = tpd_A0_DQ0;
        ( A3 => DQ17 ) = tpd_A0_DQ0;
        ( A3 => DQ18 ) = tpd_A0_DQ0;
        ( A3 => DQ19 ) = tpd_A0_DQ0;
        ( A3 => DQ20 ) = tpd_A0_DQ0;
        ( A3 => DQ21 ) = tpd_A0_DQ0;
        ( A3 => DQ22 ) = tpd_A0_DQ0;
        ( A3 => DQ23 ) = tpd_A0_DQ0;
        ( A3 => DQ24 ) = tpd_A0_DQ0;
        ( A3 => DQ25 ) = tpd_A0_DQ0;
        ( A3 => DQ26 ) = tpd_A0_DQ0;
        ( A3 => DQ27 ) = tpd_A0_DQ0;
        ( A3 => DQ28 ) = tpd_A0_DQ0;
        ( A3 => DQ29 ) = tpd_A0_DQ0;
        ( A3 => DQ30 ) = tpd_A0_DQ0;
        ( A3 => DQ31 ) = tpd_A0_DQ0;
        ( A4 => DQ0 ) = tpd_A0_DQ0;
        ( A4 => DQ1 ) = tpd_A0_DQ0;
        ( A4 => DQ2 ) = tpd_A0_DQ0;
        ( A4 => DQ3 ) = tpd_A0_DQ0;
        ( A4 => DQ4 ) = tpd_A0_DQ0;
        ( A4 => DQ5 ) = tpd_A0_DQ0;
        ( A4 => DQ6 ) = tpd_A0_DQ0;
        ( A4 => DQ7 ) = tpd_A0_DQ0;
        ( A4 => DQ8 ) = tpd_A0_DQ0;
        ( A4 => DQ9 ) = tpd_A0_DQ0;
        ( A4 => DQ10 ) = tpd_A0_DQ0;
        ( A4 => DQ11 ) = tpd_A0_DQ0;
        ( A4 => DQ12 ) = tpd_A0_DQ0;
        ( A4 => DQ13 ) = tpd_A0_DQ0;
        ( A4 => DQ14 ) = tpd_A0_DQ0;
        ( A4 => DQ15 ) = tpd_A0_DQ0;
        ( A4 => DQ16 ) = tpd_A0_DQ0;
        ( A4 => DQ17 ) = tpd_A0_DQ0;
        ( A4 => DQ18 ) = tpd_A0_DQ0;
        ( A4 => DQ19 ) = tpd_A0_DQ0;
        ( A4 => DQ20 ) = tpd_A0_DQ0;
        ( A4 => DQ21 ) = tpd_A0_DQ0;
        ( A4 => DQ22 ) = tpd_A0_DQ0;
        ( A4 => DQ23 ) = tpd_A0_DQ0;
        ( A4 => DQ24 ) = tpd_A0_DQ0;
        ( A4 => DQ25 ) = tpd_A0_DQ0;
        ( A4 => DQ26 ) = tpd_A0_DQ0;
        ( A4 => DQ27 ) = tpd_A0_DQ0;
        ( A4 => DQ28 ) = tpd_A0_DQ0;
        ( A4 => DQ29 ) = tpd_A0_DQ0;
        ( A4 => DQ30 ) = tpd_A0_DQ0;
        ( A4 => DQ31 ) = tpd_A0_DQ0;
        ( A5 => DQ0 ) = tpd_A0_DQ0;
        ( A5 => DQ1 ) = tpd_A0_DQ0;
        ( A5 => DQ2 ) = tpd_A0_DQ0;
        ( A5 => DQ3 ) = tpd_A0_DQ0;
        ( A5 => DQ4 ) = tpd_A0_DQ0;
        ( A5 => DQ5 ) = tpd_A0_DQ0;
        ( A5 => DQ6 ) = tpd_A0_DQ0;
        ( A5 => DQ7 ) = tpd_A0_DQ0;
        ( A5 => DQ8 ) = tpd_A0_DQ0;
        ( A5 => DQ9 ) = tpd_A0_DQ0;
        ( A5 => DQ10 ) = tpd_A0_DQ0;
        ( A5 => DQ11 ) = tpd_A0_DQ0;
        ( A5 => DQ12 ) = tpd_A0_DQ0;
        ( A5 => DQ13 ) = tpd_A0_DQ0;
        ( A5 => DQ14 ) = tpd_A0_DQ0;
        ( A5 => DQ15 ) = tpd_A0_DQ0;
        ( A5 => DQ16 ) = tpd_A0_DQ0;
        ( A5 => DQ17 ) = tpd_A0_DQ0;
        ( A5 => DQ18 ) = tpd_A0_DQ0;
        ( A5 => DQ19 ) = tpd_A0_DQ0;
        ( A5 => DQ20 ) = tpd_A0_DQ0;
        ( A5 => DQ21 ) = tpd_A0_DQ0;
        ( A5 => DQ22 ) = tpd_A0_DQ0;
        ( A5 => DQ23 ) = tpd_A0_DQ0;
        ( A5 => DQ24 ) = tpd_A0_DQ0;
        ( A5 => DQ25 ) = tpd_A0_DQ0;
        ( A5 => DQ26 ) = tpd_A0_DQ0;
        ( A5 => DQ27 ) = tpd_A0_DQ0;
        ( A5 => DQ28 ) = tpd_A0_DQ0;
        ( A5 => DQ29 ) = tpd_A0_DQ0;
        ( A5 => DQ30 ) = tpd_A0_DQ0;
        ( A5 => DQ31 ) = tpd_A0_DQ0;
        ( A6 => DQ0 ) = tpd_A0_DQ0;
        ( A6 => DQ1 ) = tpd_A0_DQ0;
        ( A6 => DQ2 ) = tpd_A0_DQ0;
        ( A6 => DQ3 ) = tpd_A0_DQ0;
        ( A6 => DQ4 ) = tpd_A0_DQ0;
        ( A6 => DQ5 ) = tpd_A0_DQ0;
        ( A6 => DQ6 ) = tpd_A0_DQ0;
        ( A6 => DQ7 ) = tpd_A0_DQ0;
        ( A6 => DQ8 ) = tpd_A0_DQ0;
        ( A6 => DQ9 ) = tpd_A0_DQ0;
        ( A6 => DQ10 ) = tpd_A0_DQ0;
        ( A6 => DQ11 ) = tpd_A0_DQ0;
        ( A6 => DQ12 ) = tpd_A0_DQ0;
        ( A6 => DQ13 ) = tpd_A0_DQ0;
        ( A6 => DQ14 ) = tpd_A0_DQ0;
        ( A6 => DQ15 ) = tpd_A0_DQ0;
        ( A6 => DQ16 ) = tpd_A0_DQ0;
        ( A6 => DQ17 ) = tpd_A0_DQ0;
        ( A6 => DQ18 ) = tpd_A0_DQ0;
        ( A6 => DQ19 ) = tpd_A0_DQ0;
        ( A6 => DQ20 ) = tpd_A0_DQ0;
        ( A6 => DQ21 ) = tpd_A0_DQ0;
        ( A6 => DQ22 ) = tpd_A0_DQ0;
        ( A6 => DQ23 ) = tpd_A0_DQ0;
        ( A6 => DQ24 ) = tpd_A0_DQ0;
        ( A6 => DQ25 ) = tpd_A0_DQ0;
        ( A6 => DQ26 ) = tpd_A0_DQ0;
        ( A6 => DQ27 ) = tpd_A0_DQ0;
        ( A6 => DQ28 ) = tpd_A0_DQ0;
        ( A6 => DQ29 ) = tpd_A0_DQ0;
        ( A6 => DQ30 ) = tpd_A0_DQ0;
        ( A6 => DQ31 ) = tpd_A0_DQ0;
        ( A7 => DQ0 ) = tpd_A0_DQ0;
        ( A7 => DQ1 ) = tpd_A0_DQ0;
        ( A7 => DQ2 ) = tpd_A0_DQ0;
        ( A7 => DQ3 ) = tpd_A0_DQ0;
        ( A7 => DQ4 ) = tpd_A0_DQ0;
        ( A7 => DQ5 ) = tpd_A0_DQ0;
        ( A7 => DQ6 ) = tpd_A0_DQ0;
        ( A7 => DQ7 ) = tpd_A0_DQ0;
        ( A7 => DQ8 ) = tpd_A0_DQ0;
        ( A7 => DQ9 ) = tpd_A0_DQ0;
        ( A7 => DQ10 ) = tpd_A0_DQ0;
        ( A7 => DQ11 ) = tpd_A0_DQ0;
        ( A7 => DQ12 ) = tpd_A0_DQ0;
        ( A7 => DQ13 ) = tpd_A0_DQ0;
        ( A7 => DQ14 ) = tpd_A0_DQ0;
        ( A7 => DQ15 ) = tpd_A0_DQ0;
        ( A7 => DQ16 ) = tpd_A0_DQ0;
        ( A7 => DQ17 ) = tpd_A0_DQ0;
        ( A7 => DQ18 ) = tpd_A0_DQ0;
        ( A7 => DQ19 ) = tpd_A0_DQ0;
        ( A7 => DQ20 ) = tpd_A0_DQ0;
        ( A7 => DQ21 ) = tpd_A0_DQ0;
        ( A7 => DQ22 ) = tpd_A0_DQ0;
        ( A7 => DQ23 ) = tpd_A0_DQ0;
        ( A7 => DQ24 ) = tpd_A0_DQ0;
        ( A7 => DQ25 ) = tpd_A0_DQ0;
        ( A7 => DQ26 ) = tpd_A0_DQ0;
        ( A7 => DQ27 ) = tpd_A0_DQ0;
        ( A7 => DQ28 ) = tpd_A0_DQ0;
        ( A7 => DQ29 ) = tpd_A0_DQ0;
        ( A7 => DQ30 ) = tpd_A0_DQ0;
        ( A7 => DQ31 ) = tpd_A0_DQ0;
        ( A8 => DQ0 ) = tpd_A0_DQ0;
        ( A8 => DQ1 ) = tpd_A0_DQ0;
        ( A8 => DQ2 ) = tpd_A0_DQ0;
        ( A8 => DQ3 ) = tpd_A0_DQ0;
        ( A8 => DQ4 ) = tpd_A0_DQ0;
        ( A8 => DQ5 ) = tpd_A0_DQ0;
        ( A8 => DQ6 ) = tpd_A0_DQ0;
        ( A8 => DQ7 ) = tpd_A0_DQ0;
        ( A8 => DQ8 ) = tpd_A0_DQ0;
        ( A8 => DQ9 ) = tpd_A0_DQ0;
        ( A8 => DQ10 ) = tpd_A0_DQ0;
        ( A8 => DQ11 ) = tpd_A0_DQ0;
        ( A8 => DQ12 ) = tpd_A0_DQ0;
        ( A8 => DQ13 ) = tpd_A0_DQ0;
        ( A8 => DQ14 ) = tpd_A0_DQ0;
        ( A8 => DQ15 ) = tpd_A0_DQ0;
        ( A8 => DQ16 ) = tpd_A0_DQ0;
        ( A8 => DQ17 ) = tpd_A0_DQ0;
        ( A8 => DQ18 ) = tpd_A0_DQ0;
        ( A8 => DQ19 ) = tpd_A0_DQ0;
        ( A8 => DQ20 ) = tpd_A0_DQ0;
        ( A8 => DQ21 ) = tpd_A0_DQ0;
        ( A8 => DQ22 ) = tpd_A0_DQ0;
        ( A8 => DQ23 ) = tpd_A0_DQ0;
        ( A8 => DQ24 ) = tpd_A0_DQ0;
        ( A8 => DQ25 ) = tpd_A0_DQ0;
        ( A8 => DQ26 ) = tpd_A0_DQ0;
        ( A8 => DQ27 ) = tpd_A0_DQ0;
        ( A8 => DQ28 ) = tpd_A0_DQ0;
        ( A8 => DQ29 ) = tpd_A0_DQ0;
        ( A8 => DQ30 ) = tpd_A0_DQ0;
        ( A8 => DQ31 ) = tpd_A0_DQ0;
        ( A9 => DQ0 ) = tpd_A0_DQ0;
        ( A9 => DQ1 ) = tpd_A0_DQ0;
        ( A9 => DQ2 ) = tpd_A0_DQ0;
        ( A9 => DQ3 ) = tpd_A0_DQ0;
        ( A9 => DQ4 ) = tpd_A0_DQ0;
        ( A9 => DQ5 ) = tpd_A0_DQ0;
        ( A9 => DQ6 ) = tpd_A0_DQ0;
        ( A9 => DQ7 ) = tpd_A0_DQ0;
        ( A9 => DQ8 ) = tpd_A0_DQ0;
        ( A9 => DQ9 ) = tpd_A0_DQ0;
        ( A9 => DQ10 ) = tpd_A0_DQ0;
        ( A9 => DQ11 ) = tpd_A0_DQ0;
        ( A9 => DQ12 ) = tpd_A0_DQ0;
        ( A9 => DQ13 ) = tpd_A0_DQ0;
        ( A9 => DQ14 ) = tpd_A0_DQ0;
        ( A9 => DQ15 ) = tpd_A0_DQ0;
        ( A9 => DQ16 ) = tpd_A0_DQ0;
        ( A9 => DQ17 ) = tpd_A0_DQ0;
        ( A9 => DQ18 ) = tpd_A0_DQ0;
        ( A9 => DQ19 ) = tpd_A0_DQ0;
        ( A9 => DQ20 ) = tpd_A0_DQ0;
        ( A9 => DQ21 ) = tpd_A0_DQ0;
        ( A9 => DQ22 ) = tpd_A0_DQ0;
        ( A9 => DQ23 ) = tpd_A0_DQ0;
        ( A9 => DQ24 ) = tpd_A0_DQ0;
        ( A9 => DQ25 ) = tpd_A0_DQ0;
        ( A9 => DQ26 ) = tpd_A0_DQ0;
        ( A9 => DQ27 ) = tpd_A0_DQ0;
        ( A9 => DQ28 ) = tpd_A0_DQ0;
        ( A9 => DQ29 ) = tpd_A0_DQ0;
        ( A9 => DQ30 ) = tpd_A0_DQ0;
        ( A9 => DQ31 ) = tpd_A0_DQ0;
        ( A10 => DQ0 ) = tpd_A0_DQ0;
        ( A10 => DQ1 ) = tpd_A0_DQ0;
        ( A10 => DQ2 ) = tpd_A0_DQ0;
        ( A10 => DQ3 ) = tpd_A0_DQ0;
        ( A10 => DQ4 ) = tpd_A0_DQ0;
        ( A10 => DQ5 ) = tpd_A0_DQ0;
        ( A10 => DQ6 ) = tpd_A0_DQ0;
        ( A10 => DQ7 ) = tpd_A0_DQ0;
        ( A10 => DQ8 ) = tpd_A0_DQ0;
        ( A10 => DQ9 ) = tpd_A0_DQ0;
        ( A10 => DQ10 ) = tpd_A0_DQ0;
        ( A10 => DQ11 ) = tpd_A0_DQ0;
        ( A10 => DQ12 ) = tpd_A0_DQ0;
        ( A10 => DQ13 ) = tpd_A0_DQ0;
        ( A10 => DQ14 ) = tpd_A0_DQ0;
        ( A10 => DQ15 ) = tpd_A0_DQ0;
        ( A10 => DQ16 ) = tpd_A0_DQ0;
        ( A10 => DQ17 ) = tpd_A0_DQ0;
        ( A10 => DQ18 ) = tpd_A0_DQ0;
        ( A10 => DQ19 ) = tpd_A0_DQ0;
        ( A10 => DQ20 ) = tpd_A0_DQ0;
        ( A10 => DQ21 ) = tpd_A0_DQ0;
        ( A10 => DQ22 ) = tpd_A0_DQ0;
        ( A10 => DQ23 ) = tpd_A0_DQ0;
        ( A10 => DQ24 ) = tpd_A0_DQ0;
        ( A10 => DQ25 ) = tpd_A0_DQ0;
        ( A10 => DQ26 ) = tpd_A0_DQ0;
        ( A10 => DQ27 ) = tpd_A0_DQ0;
        ( A10 => DQ28 ) = tpd_A0_DQ0;
        ( A10 => DQ29 ) = tpd_A0_DQ0;
        ( A10 => DQ30 ) = tpd_A0_DQ0;
        ( A10 => DQ31 ) = tpd_A0_DQ0;
        ( A11 => DQ0 ) = tpd_A0_DQ0;
        ( A11 => DQ1 ) = tpd_A0_DQ0;
        ( A11 => DQ2 ) = tpd_A0_DQ0;
        ( A11 => DQ3 ) = tpd_A0_DQ0;
        ( A11 => DQ4 ) = tpd_A0_DQ0;
        ( A11 => DQ5 ) = tpd_A0_DQ0;
        ( A11 => DQ6 ) = tpd_A0_DQ0;
        ( A11 => DQ7 ) = tpd_A0_DQ0;
        ( A11 => DQ8 ) = tpd_A0_DQ0;
        ( A11 => DQ9 ) = tpd_A0_DQ0;
        ( A11 => DQ10 ) = tpd_A0_DQ0;
        ( A11 => DQ11 ) = tpd_A0_DQ0;
        ( A11 => DQ12 ) = tpd_A0_DQ0;
        ( A11 => DQ13 ) = tpd_A0_DQ0;
        ( A11 => DQ14 ) = tpd_A0_DQ0;
        ( A11 => DQ15 ) = tpd_A0_DQ0;
        ( A11 => DQ16 ) = tpd_A0_DQ0;
        ( A11 => DQ17 ) = tpd_A0_DQ0;
        ( A11 => DQ18 ) = tpd_A0_DQ0;
        ( A11 => DQ19 ) = tpd_A0_DQ0;
        ( A11 => DQ20 ) = tpd_A0_DQ0;
        ( A11 => DQ21 ) = tpd_A0_DQ0;
        ( A11 => DQ22 ) = tpd_A0_DQ0;
        ( A11 => DQ23 ) = tpd_A0_DQ0;
        ( A11 => DQ24 ) = tpd_A0_DQ0;
        ( A11 => DQ25 ) = tpd_A0_DQ0;
        ( A11 => DQ26 ) = tpd_A0_DQ0;
        ( A11 => DQ27 ) = tpd_A0_DQ0;
        ( A11 => DQ28 ) = tpd_A0_DQ0;
        ( A11 => DQ29 ) = tpd_A0_DQ0;
        ( A11 => DQ30 ) = tpd_A0_DQ0;
        ( A11 => DQ31 ) = tpd_A0_DQ0;
        ( A12 => DQ0 ) = tpd_A0_DQ0;
        ( A12 => DQ1 ) = tpd_A0_DQ0;
        ( A12 => DQ2 ) = tpd_A0_DQ0;
        ( A12 => DQ3 ) = tpd_A0_DQ0;
        ( A12 => DQ4 ) = tpd_A0_DQ0;
        ( A12 => DQ5 ) = tpd_A0_DQ0;
        ( A12 => DQ6 ) = tpd_A0_DQ0;
        ( A12 => DQ7 ) = tpd_A0_DQ0;
        ( A12 => DQ8 ) = tpd_A0_DQ0;
        ( A12 => DQ9 ) = tpd_A0_DQ0;
        ( A12 => DQ10 ) = tpd_A0_DQ0;
        ( A12 => DQ11 ) = tpd_A0_DQ0;
        ( A12 => DQ12 ) = tpd_A0_DQ0;
        ( A12 => DQ13 ) = tpd_A0_DQ0;
        ( A12 => DQ14 ) = tpd_A0_DQ0;
        ( A12 => DQ15 ) = tpd_A0_DQ0;
        ( A12 => DQ16 ) = tpd_A0_DQ0;
        ( A12 => DQ17 ) = tpd_A0_DQ0;
        ( A12 => DQ18 ) = tpd_A0_DQ0;
        ( A12 => DQ19 ) = tpd_A0_DQ0;
        ( A12 => DQ20 ) = tpd_A0_DQ0;
        ( A12 => DQ21 ) = tpd_A0_DQ0;
        ( A12 => DQ22 ) = tpd_A0_DQ0;
        ( A12 => DQ23 ) = tpd_A0_DQ0;
        ( A12 => DQ24 ) = tpd_A0_DQ0;
        ( A12 => DQ25 ) = tpd_A0_DQ0;
        ( A12 => DQ26 ) = tpd_A0_DQ0;
        ( A12 => DQ27 ) = tpd_A0_DQ0;
        ( A12 => DQ28 ) = tpd_A0_DQ0;
        ( A12 => DQ29 ) = tpd_A0_DQ0;
        ( A12 => DQ30 ) = tpd_A0_DQ0;
        ( A12 => DQ31 ) = tpd_A0_DQ0;
        ( A13 => DQ0 ) = tpd_A0_DQ0;
        ( A13 => DQ1 ) = tpd_A0_DQ0;
        ( A13 => DQ2 ) = tpd_A0_DQ0;
        ( A13 => DQ3 ) = tpd_A0_DQ0;
        ( A13 => DQ4 ) = tpd_A0_DQ0;
        ( A13 => DQ5 ) = tpd_A0_DQ0;
        ( A13 => DQ6 ) = tpd_A0_DQ0;
        ( A13 => DQ7 ) = tpd_A0_DQ0;
        ( A13 => DQ8 ) = tpd_A0_DQ0;
        ( A13 => DQ9 ) = tpd_A0_DQ0;
        ( A13 => DQ10 ) = tpd_A0_DQ0;
        ( A13 => DQ11 ) = tpd_A0_DQ0;
        ( A13 => DQ12 ) = tpd_A0_DQ0;
        ( A13 => DQ13 ) = tpd_A0_DQ0;
        ( A13 => DQ14 ) = tpd_A0_DQ0;
        ( A13 => DQ15 ) = tpd_A0_DQ0;
        ( A13 => DQ16 ) = tpd_A0_DQ0;
        ( A13 => DQ17 ) = tpd_A0_DQ0;
        ( A13 => DQ18 ) = tpd_A0_DQ0;
        ( A13 => DQ19 ) = tpd_A0_DQ0;
        ( A13 => DQ20 ) = tpd_A0_DQ0;
        ( A13 => DQ21 ) = tpd_A0_DQ0;
        ( A13 => DQ22 ) = tpd_A0_DQ0;
        ( A13 => DQ23 ) = tpd_A0_DQ0;
        ( A13 => DQ24 ) = tpd_A0_DQ0;
        ( A13 => DQ25 ) = tpd_A0_DQ0;
        ( A13 => DQ26 ) = tpd_A0_DQ0;
        ( A13 => DQ27 ) = tpd_A0_DQ0;
        ( A13 => DQ28 ) = tpd_A0_DQ0;
        ( A13 => DQ29 ) = tpd_A0_DQ0;
        ( A13 => DQ30 ) = tpd_A0_DQ0;
        ( A13 => DQ31 ) = tpd_A0_DQ0;
        ( A14 => DQ0 ) = tpd_A0_DQ0;
        ( A14 => DQ1 ) = tpd_A0_DQ0;
        ( A14 => DQ2 ) = tpd_A0_DQ0;
        ( A14 => DQ3 ) = tpd_A0_DQ0;
        ( A14 => DQ4 ) = tpd_A0_DQ0;
        ( A14 => DQ5 ) = tpd_A0_DQ0;
        ( A14 => DQ6 ) = tpd_A0_DQ0;
        ( A14 => DQ7 ) = tpd_A0_DQ0;
        ( A14 => DQ8 ) = tpd_A0_DQ0;
        ( A14 => DQ9 ) = tpd_A0_DQ0;
        ( A14 => DQ10 ) = tpd_A0_DQ0;
        ( A14 => DQ11 ) = tpd_A0_DQ0;
        ( A14 => DQ12 ) = tpd_A0_DQ0;
        ( A14 => DQ13 ) = tpd_A0_DQ0;
        ( A14 => DQ14 ) = tpd_A0_DQ0;
        ( A14 => DQ15 ) = tpd_A0_DQ0;
        ( A14 => DQ16 ) = tpd_A0_DQ0;
        ( A14 => DQ17 ) = tpd_A0_DQ0;
        ( A14 => DQ18 ) = tpd_A0_DQ0;
        ( A14 => DQ19 ) = tpd_A0_DQ0;
        ( A14 => DQ20 ) = tpd_A0_DQ0;
        ( A14 => DQ21 ) = tpd_A0_DQ0;
        ( A14 => DQ22 ) = tpd_A0_DQ0;
        ( A14 => DQ23 ) = tpd_A0_DQ0;
        ( A14 => DQ24 ) = tpd_A0_DQ0;
        ( A14 => DQ25 ) = tpd_A0_DQ0;
        ( A14 => DQ26 ) = tpd_A0_DQ0;
        ( A14 => DQ27 ) = tpd_A0_DQ0;
        ( A14 => DQ28 ) = tpd_A0_DQ0;
        ( A14 => DQ29 ) = tpd_A0_DQ0;
        ( A14 => DQ30 ) = tpd_A0_DQ0;
        ( A14 => DQ31 ) = tpd_A0_DQ0;
        ( A15 => DQ0 ) = tpd_A0_DQ0;
        ( A15 => DQ1 ) = tpd_A0_DQ0;
        ( A15 => DQ2 ) = tpd_A0_DQ0;
        ( A15 => DQ3 ) = tpd_A0_DQ0;
        ( A15 => DQ4 ) = tpd_A0_DQ0;
        ( A15 => DQ5 ) = tpd_A0_DQ0;
        ( A15 => DQ6 ) = tpd_A0_DQ0;
        ( A15 => DQ7 ) = tpd_A0_DQ0;
        ( A15 => DQ8 ) = tpd_A0_DQ0;
        ( A15 => DQ9 ) = tpd_A0_DQ0;
        ( A15 => DQ10 ) = tpd_A0_DQ0;
        ( A15 => DQ11 ) = tpd_A0_DQ0;
        ( A15 => DQ12 ) = tpd_A0_DQ0;
        ( A15 => DQ13 ) = tpd_A0_DQ0;
        ( A15 => DQ14 ) = tpd_A0_DQ0;
        ( A15 => DQ15 ) = tpd_A0_DQ0;
        ( A15 => DQ16 ) = tpd_A0_DQ0;
        ( A15 => DQ17 ) = tpd_A0_DQ0;
        ( A15 => DQ18 ) = tpd_A0_DQ0;
        ( A15 => DQ19 ) = tpd_A0_DQ0;
        ( A15 => DQ20 ) = tpd_A0_DQ0;
        ( A15 => DQ21 ) = tpd_A0_DQ0;
        ( A15 => DQ22 ) = tpd_A0_DQ0;
        ( A15 => DQ23 ) = tpd_A0_DQ0;
        ( A15 => DQ24 ) = tpd_A0_DQ0;
        ( A15 => DQ25 ) = tpd_A0_DQ0;
        ( A15 => DQ26 ) = tpd_A0_DQ0;
        ( A15 => DQ27 ) = tpd_A0_DQ0;
        ( A15 => DQ28 ) = tpd_A0_DQ0;
        ( A15 => DQ29 ) = tpd_A0_DQ0;
        ( A15 => DQ30 ) = tpd_A0_DQ0;
        ( A15 => DQ31 ) = tpd_A0_DQ0;
        ( A16 => DQ0 ) = tpd_A0_DQ0;
        ( A16 => DQ1 ) = tpd_A0_DQ0;
        ( A16 => DQ2 ) = tpd_A0_DQ0;
        ( A16 => DQ3 ) = tpd_A0_DQ0;
        ( A16 => DQ4 ) = tpd_A0_DQ0;
        ( A16 => DQ5 ) = tpd_A0_DQ0;
        ( A16 => DQ6 ) = tpd_A0_DQ0;
        ( A16 => DQ7 ) = tpd_A0_DQ0;
        ( A16 => DQ8 ) = tpd_A0_DQ0;
        ( A16 => DQ9 ) = tpd_A0_DQ0;
        ( A16 => DQ10 ) = tpd_A0_DQ0;
        ( A16 => DQ11 ) = tpd_A0_DQ0;
        ( A16 => DQ12 ) = tpd_A0_DQ0;
        ( A16 => DQ13 ) = tpd_A0_DQ0;
        ( A16 => DQ14 ) = tpd_A0_DQ0;
        ( A16 => DQ15 ) = tpd_A0_DQ0;
        ( A16 => DQ16 ) = tpd_A0_DQ0;
        ( A16 => DQ17 ) = tpd_A0_DQ0;
        ( A16 => DQ18 ) = tpd_A0_DQ0;
        ( A16 => DQ19 ) = tpd_A0_DQ0;
        ( A16 => DQ20 ) = tpd_A0_DQ0;
        ( A16 => DQ21 ) = tpd_A0_DQ0;
        ( A16 => DQ22 ) = tpd_A0_DQ0;
        ( A16 => DQ23 ) = tpd_A0_DQ0;
        ( A16 => DQ24 ) = tpd_A0_DQ0;
        ( A16 => DQ25 ) = tpd_A0_DQ0;
        ( A16 => DQ26 ) = tpd_A0_DQ0;
        ( A16 => DQ27 ) = tpd_A0_DQ0;
        ( A16 => DQ28 ) = tpd_A0_DQ0;
        ( A16 => DQ29 ) = tpd_A0_DQ0;
        ( A16 => DQ30 ) = tpd_A0_DQ0;
        ( A16 => DQ31 ) = tpd_A0_DQ0;
        ( A17 => DQ0 ) = tpd_A0_DQ0;
        ( A17 => DQ1 ) = tpd_A0_DQ0;
        ( A17 => DQ2 ) = tpd_A0_DQ0;
        ( A17 => DQ3 ) = tpd_A0_DQ0;
        ( A17 => DQ4 ) = tpd_A0_DQ0;
        ( A17 => DQ5 ) = tpd_A0_DQ0;
        ( A17 => DQ6 ) = tpd_A0_DQ0;
        ( A17 => DQ7 ) = tpd_A0_DQ0;
        ( A17 => DQ8 ) = tpd_A0_DQ0;
        ( A17 => DQ9 ) = tpd_A0_DQ0;
        ( A17 => DQ10 ) = tpd_A0_DQ0;
        ( A17 => DQ11 ) = tpd_A0_DQ0;
        ( A17 => DQ12 ) = tpd_A0_DQ0;
        ( A17 => DQ13 ) = tpd_A0_DQ0;
        ( A17 => DQ14 ) = tpd_A0_DQ0;
        ( A17 => DQ15 ) = tpd_A0_DQ0;
        ( A17 => DQ16 ) = tpd_A0_DQ0;
        ( A17 => DQ17 ) = tpd_A0_DQ0;
        ( A17 => DQ18 ) = tpd_A0_DQ0;
        ( A17 => DQ19 ) = tpd_A0_DQ0;
        ( A17 => DQ20 ) = tpd_A0_DQ0;
        ( A17 => DQ21 ) = tpd_A0_DQ0;
        ( A17 => DQ22 ) = tpd_A0_DQ0;
        ( A17 => DQ23 ) = tpd_A0_DQ0;
        ( A17 => DQ24 ) = tpd_A0_DQ0;
        ( A17 => DQ25 ) = tpd_A0_DQ0;
        ( A17 => DQ26 ) = tpd_A0_DQ0;
        ( A17 => DQ27 ) = tpd_A0_DQ0;
        ( A17 => DQ28 ) = tpd_A0_DQ0;
        ( A17 => DQ29 ) = tpd_A0_DQ0;
        ( A17 => DQ30 ) = tpd_A0_DQ0;
        ( A17 => DQ31 ) = tpd_A0_DQ0;
        ( A18 => DQ0 ) = tpd_A0_DQ0;
        ( A18 => DQ1 ) = tpd_A0_DQ0;
        ( A18 => DQ2 ) = tpd_A0_DQ0;
        ( A18 => DQ3 ) = tpd_A0_DQ0;
        ( A18 => DQ4 ) = tpd_A0_DQ0;
        ( A18 => DQ5 ) = tpd_A0_DQ0;
        ( A18 => DQ6 ) = tpd_A0_DQ0;
        ( A18 => DQ7 ) = tpd_A0_DQ0;
        ( A18 => DQ8 ) = tpd_A0_DQ0;
        ( A18 => DQ9 ) = tpd_A0_DQ0;
        ( A18 => DQ10 ) = tpd_A0_DQ0;
        ( A18 => DQ11 ) = tpd_A0_DQ0;
        ( A18 => DQ12 ) = tpd_A0_DQ0;
        ( A18 => DQ13 ) = tpd_A0_DQ0;
        ( A18 => DQ14 ) = tpd_A0_DQ0;
        ( A18 => DQ15 ) = tpd_A0_DQ0;
        ( A18 => DQ16 ) = tpd_A0_DQ0;
        ( A18 => DQ17 ) = tpd_A0_DQ0;
        ( A18 => DQ18 ) = tpd_A0_DQ0;
        ( A18 => DQ19 ) = tpd_A0_DQ0;
        ( A18 => DQ20 ) = tpd_A0_DQ0;
        ( A18 => DQ21 ) = tpd_A0_DQ0;
        ( A18 => DQ22 ) = tpd_A0_DQ0;
        ( A18 => DQ23 ) = tpd_A0_DQ0;
        ( A18 => DQ24 ) = tpd_A0_DQ0;
        ( A18 => DQ25 ) = tpd_A0_DQ0;
        ( A18 => DQ26 ) = tpd_A0_DQ0;
        ( A18 => DQ27 ) = tpd_A0_DQ0;
        ( A18 => DQ28 ) = tpd_A0_DQ0;
        ( A18 => DQ29 ) = tpd_A0_DQ0;
        ( A18 => DQ30 ) = tpd_A0_DQ0;
        ( A18 => DQ31 ) = tpd_A0_DQ0;
        ( Am1 => DQ0 ) = tpd_A0_DQ0;
        ( Am1 => DQ1 ) = tpd_A0_DQ0;
        ( Am1 => DQ2 ) = tpd_A0_DQ0;
        ( Am1 => DQ3 ) = tpd_A0_DQ0;
        ( Am1 => DQ4 ) = tpd_A0_DQ0;
        ( Am1 => DQ5 ) = tpd_A0_DQ0;
        ( Am1 => DQ6 ) = tpd_A0_DQ0;
        ( Am1 => DQ7 ) = tpd_A0_DQ0;
        ( Am1 => DQ8 ) = tpd_A0_DQ0;
        ( Am1 => DQ9 ) = tpd_A0_DQ0;
        ( Am1 => DQ10 ) = tpd_A0_DQ0;
        ( Am1 => DQ11 ) = tpd_A0_DQ0;
        ( Am1 => DQ12 ) = tpd_A0_DQ0;
        ( Am1 => DQ13 ) = tpd_A0_DQ0;
        ( Am1 => DQ14 ) = tpd_A0_DQ0;
        ( Am1 => DQ15 ) = tpd_A0_DQ0;
        ( Am1 => DQ16 ) = tpd_A0_DQ0;
        ( Am1 => DQ17 ) = tpd_A0_DQ0;
        ( Am1 => DQ18 ) = tpd_A0_DQ0;
        ( Am1 => DQ19 ) = tpd_A0_DQ0;
        ( Am1 => DQ20 ) = tpd_A0_DQ0;
        ( Am1 => DQ21 ) = tpd_A0_DQ0;
        ( Am1 => DQ22 ) = tpd_A0_DQ0;
        ( Am1 => DQ23 ) = tpd_A0_DQ0;
        ( Am1 => DQ24 ) = tpd_A0_DQ0;
        ( Am1 => DQ25 ) = tpd_A0_DQ0;
        ( Am1 => DQ26 ) = tpd_A0_DQ0;
        ( Am1 => DQ27 ) = tpd_A0_DQ0;
        ( Am1 => DQ28 ) = tpd_A0_DQ0;
        ( Am1 => DQ29 ) = tpd_A0_DQ0;
        ( Am1 => DQ30 ) = tpd_A0_DQ0;
        ( Am1 => DQ31 ) = tpd_A0_DQ0;

    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ0 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ1 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ2 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ3 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ4 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ5 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ6 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ7 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ8 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ9 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ10 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ11 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ12 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ13 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ14 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ15 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ16 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ17 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ18 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ19 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ20 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ21 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ22 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ23 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ24 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ25 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ26 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ27 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ28 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ29 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ30 ) = tpd_CLK_DQ0;
    if (SYNC && ~OENeg && CLK)
        ( CLK => DQ31 ) = tpd_CLK_DQ0;

  if (~SWITCH || (SWITCH && FROMCE))
         (CENeg => INDNeg) = tpd_CENeg_INDNeg;
  if (~SWITCH || (SWITCH && FROMOE))
         (OENeg => INDNeg) = tpd_OENeg_INDNeg;
  if ( ~OENeg && SYNC && CLK ) ( CLK => INDNeg ) = tpd_CLK_INDNeg;

  (CENeg => RY) = tpd_CENeg_RY;
  (WENeg => RY) = tpd_WENeg_RY;

////////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                           //
////////////////////////////////////////////////////////////////////////////////

        $setup ( CENeg  , posedge CLK &&& SYNCn   , tsetup_CENeg_CLK   , Viol);
        $setup ( ADVNeg , posedge CLK &&& SYNCn   , tsetup_ADVNeg_CLK  , Viol);
        $setup ( WENeg  , posedge CLK &&& SYNCn   , tsetup_WENeg_CLK   , Viol);
        $setup ( WENeg  , negedge ADVNeg &&& SYNCn, tsetup_WENeg_ADVNeg, Viol);
        $setup ( WPNeg  , posedge WENeg , tsetup_WPNeg_WENeg , Viol);
        $setup ( WENeg  , negedge CENeg , tsetup_WENeg_CENeg , Viol);
        $setup ( CENeg  , negedge WENeg , tsetup_CENeg_WENeg , Viol);

        $setup ( Am1 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A0  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A1  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A2  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A3  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A4  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A5  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A6  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A7  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A8  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A9  , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A10 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A11 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A12 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A13 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A14 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A15 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A16 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A17 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( A18 , posedge CLK &&& SYNCn, tsetup_A0_CLK, Viol);
        $setup ( Am1 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A0  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A1  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A2  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A3  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A4  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A5  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A6  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A7  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A8  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A9  , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A10 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A11 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A12 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A13 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A14 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A15 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A16 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A17 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A18 , negedge WENeg,  tsetup_A0_WENeg, Viol);
        $setup ( Am1 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A0  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A1  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A2  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A3  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A4  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A5  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A6  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A7  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A8  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A9  , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A10 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A11 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A12 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A13 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A14 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A15 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A16 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A17 , negedge CENeg,  tsetup_A0_WENeg, Viol);
        $setup ( A18 , negedge CENeg,  tsetup_A0_WENeg, Viol);

        $setup ( DQ0  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ1  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ2  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ3  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ4  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ5  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ6  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ7  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ8  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ9  , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ10 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ11 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ12 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ13 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ14 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ15 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ16 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ17 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ18 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ19 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ20 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ21 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ22 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ23 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ24 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ25 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ26 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ27 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ28 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ29 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ30 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ31 , posedge CENeg &&& deg , tsetup_DQ0_WENeg, Viol);

        $setup ( DQ0  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ1  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ2  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ3  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ4  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ5  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ6  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ7  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ8  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ9  , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ10 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ11 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ12 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ13 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ14 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ15 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ16 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ17 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ18 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ19 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ20 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ21 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ22 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ23 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ24 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ25 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ26 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ27 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ28 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ29 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ30 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);
        $setup ( DQ31 , posedge WENeg &&& deg , tsetup_DQ0_WENeg, Viol);

        $hold ( posedge RESETNeg &&& (CENeg===1), CENeg , thold_CENeg_RESETNeg, Viol);
        $hold ( posedge RESETNeg &&& (WENeg===1), WENeg , thold_WENeg_RESETNeg, Viol);
        $hold ( posedge RESETNeg &&& (OENeg===1), OENeg , thold_OENeg_RESETNeg, Viol);
        $hold ( posedge CLK &&& SYNCn   , ADVNeg ,  thold_ADVNeg_CLK  , Viol);
        $hold ( negedge ADVNeg &&& SYNCn, WENeg  ,  thold_WENeg_ADVNeg, Viol);
        $hold ( posedge WENeg &&& deg, CENeg , thold_CENeg_WENeg, Viol);
        $hold ( posedge CENeg, WENeg , thold_WENeg_CENeg, Viol);
        $hold ( negedge WENeg, OENeg , thold_OENeg_WENeg, Viol);
        $hold ( negedge OENeg, WENeg , thold_WENeg_OENeg, Viol);

        $hold ( posedge CLK &&& SYNCn, Am1 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A0  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A1  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A2  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A3  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A4  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A5  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A6  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A7  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A8  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A9  , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A10 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A11 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A12 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A13 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A14 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A15 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A16 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A17 , thold_A0_CLK, Viol);
        $hold ( posedge CLK &&& SYNCn, A18 , thold_A0_CLK, Viol);
        $hold ( negedge CENeg &&& ~WENeg, Am1 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A0  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A1  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A2  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A3  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A4  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A5  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A6  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A7  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A8  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A9  , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A10 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A11 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A12 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A13 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A14 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A15 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A16 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A17 , thold_A0_WENeg, Viol);
        $hold ( negedge CENeg &&& ~WENeg, A18 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, Am1 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A0  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A1  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A2  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A3  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A4  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A5  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A6  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A7  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A8  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A9  , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A10 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A11 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A12 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A13 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A14 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A15 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A16 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A17 , thold_A0_WENeg, Viol);
        $hold ( negedge WENeg &&& ~CENeg, A18 , thold_A0_WENeg, Viol);

        $hold ( posedge CENeg &&& deg, DQ0  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ1  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ2  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ3  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ4  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ5  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ6  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ7  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ8  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ9  , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ10 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ11 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ12 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ13 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ14 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ15 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ16 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ17 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ18 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ19 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ20 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ21 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ22 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ23 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ24 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ25 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ26 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ27 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ28 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ29 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ30 , thold_DQ0_WENeg, Viol);
        $hold ( posedge CENeg &&& deg, DQ31 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ0  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ1  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ2  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ3  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ4  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ5  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ6  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ7  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ8  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ9  , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ10 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ11 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ12 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ13 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ14 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ15 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ16 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ17 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ18 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ19 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ20 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ21 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ22 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ23 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ24 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ25 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ26 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ27 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ28 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ29 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ30 , thold_DQ0_WENeg, Viol);
        $hold ( posedge WENeg &&& deg, DQ31 , thold_DQ0_WENeg, Viol);

        $width (negedge RESETNeg,tpw_RESETNeg_negedge);
        $width (posedge WENeg   ,tpw_WENeg_posedge);
        $width (negedge WENeg , tpw_WENeg_negedge);
        $width (posedge CENeg , tpw_CENeg_posedge);
        $width (negedge CENeg , tpw_CENeg_negedge);
        $width (posedge CLK   , tpw_CLK_posedge);
        $width (negedge CLK   , tpw_CLK_negedge);
        $width (negedge ADVNeg, tpw_ADVNeg_negedge);

        $recovery(posedge OENeg, negedge WENeg, trecovery_OENeg_WENeg);
        $recovery(posedge OENeg, negedge CENeg, trecovery_OENeg_CENeg);

        $period(posedge CLK, tperiod_CLK);
    endspecify

    assign SYNCn = SYNC;

    initial
    begin
          ConfReg = 16'b1001110011000100;
          StatusReg = 0;
          SyncData  = 0;

          DOut_zd   = {Zzz,Zzz};
          DOut_temp = {Zzz,Zzz};
          #100 PoweredUp = 1'b1;
    end

    always @(posedge PoweredUp)
    begin
       DOut_zd = {Zzz,Zzz};
       CommandCurrentState = INIT;
       CurrentState        = READ_ASYNC;
    end
    always @(DIn, DOut)
    begin
      if (DIn==DOut)
        deq=1'b1;
      else
        deq=1'b0;
    end
    assign deg = deq;

    initial
    begin
         // CFI Query identification string
            CFI_array[8'h10] = 8'h51;
            CFI_array[8'h11] = 8'h52;
            CFI_array[8'h12] = 8'h59;
            CFI_array[8'h13] = 8'h02;
            CFI_array[8'h14] = 8'h00;
            CFI_array[8'h15] = 8'h40;
            CFI_array[8'h16] = 8'h00;
            CFI_array[8'h17] = 8'h00;
            CFI_array[8'h18] = 8'h00;
            CFI_array[8'h19] = 8'h00;
            CFI_array[8'h1A] = 8'h00;
        // CFI system interface string
            CFI_array[8'h1B] = 8'h23;
            CFI_array[8'h1C] = 8'h27;
            CFI_array[8'h1D] = 8'h00;
            CFI_array[8'h1E] = 8'h00;
            CFI_array[8'h1F] = 8'h04;
            CFI_array[8'h20] = 8'h00;
            CFI_array[8'h21] = 8'h09;
            CFI_array[8'h22] = 8'h00;
            CFI_array[8'h23] = 8'h05;
            CFI_array[8'h24] = 8'h00;
            CFI_array[8'h25] = 8'h07;
            CFI_array[8'h26] = 8'h00;
        // Device Geometry definition
            CFI_array[8'h27] = 8'h15;
            CFI_array[8'h28] = 8'h05;
            CFI_array[8'h29] = 8'h00;
            CFI_array[8'h2A] = 8'h00;
            CFI_array[8'h2B] = 8'h00;
            CFI_array[8'h2C] = 8'h03;
            CFI_array[8'h2D] = 8'h07;
            CFI_array[8'h2E] = 8'h00;
            CFI_array[8'h2F] = 8'h20;
            CFI_array[8'h30] = 8'h00;
            CFI_array[8'h31] = 8'h1D;
            CFI_array[8'h32] = 8'h00;
            CFI_array[8'h33] = 8'h00;
            CFI_array[8'h34] = 8'h01;
            CFI_array[8'h35] = 8'h07;
            CFI_array[8'h36] = 8'h00;
            CFI_array[8'h37] = 8'h20;
            CFI_array[8'h38] = 8'h00;
            CFI_array[8'h39] = 8'h00;
            CFI_array[8'h3A] = 8'h00;
            CFI_array[8'h3B] = 8'h00;
            CFI_array[8'h3C] = 8'h00;

        // Primary vendor-specific extended query
            CFI_array[8'h40] = 8'h50;
            CFI_array[8'h41] = 8'h52;
            CFI_array[8'h42] = 8'h49;
            CFI_array[8'h43] = 8'h31;
            CFI_array[8'h44] = 8'h33;
            CFI_array[8'h45] = 8'h04;
            CFI_array[8'h46] = 8'h02;
            CFI_array[8'h47] = 8'h01;
            CFI_array[8'h48] = 8'h00;
            CFI_array[8'h49] = 8'h06;
            CFI_array[8'h4A] = 8'h1F;
            CFI_array[8'h4B] = 8'h01;
            CFI_array[8'h4C] = 8'h00;
            CFI_array[8'h4D] = 8'hB5;
            CFI_array[8'h4E] = 8'hC5;
            CFI_array[8'h4F] = 8'h01;
            CFI_array[8'h50] = 8'h01;
            CFI_array[8'h51] = 8'h00;
            CFI_array[8'h57] = 8'h02;
            CFI_array[8'h58] = 8'h0F;
            CFI_array[8'h59] = 8'h1F;
            CFI_array[8'h5A] = 8'h00;
            CFI_array[8'h5B] = 8'h00;

            ASEL_array[8'h00] = 8'h01;
            ASEL_array[8'h01] = 8'h7E;
            ASEL_array[8'h0E] = 8'h08;
            if (Top(0))
                 ASEL_array[8'h0F] = 8'h00;
            else ASEL_array[8'h0F] = 8'h01;
    end

    initial
    begin: InitMemory
    integer i,j;

    // 0..23 PPB array
    // 24 SecSi factory protected
    // 25 PPMLB
    // 26 SPMLB
    reg     PPB_preload[0:26];
    integer SecSi_preload[0:SecSiSize-1];


        if ( Top(0) )
        begin
           SecSiSector = 0;
           HWProtect1  = 44;
           HWProtect2  = 45;
        end
        else
        begin
           SecSiSector = 45;
           HWProtect1  = 0;
           HWProtect2  = 1;
        end
        for (i=0;i<=ADDRRange;i=i+1)
                   Flash[i] = MaxData;

        for (i=0;i<=26;i=i+1)
        begin
           PPB_preload[i]=0;
        end
        for (i=0;i<SecSiSize;i=i+1)
        begin
           SecSi_preload[i]=MaxData;
        end
        for (i=0;i<4;i=i+1)
           PasswordRegion[i] = 16'hFFFF;

        if (UserPreload && !( prot_file_name == "none"))
        begin
          //am29bdd160g_prot  sector protect file
          //   //       - comment
          //   @aa     - <aa> stands for sector group identification 0..23
          //   If nothing specified for sector group in
          //   this file the corresponding
          //   group will be unprotected ( default ).
          //   @18 line stands for SecSi.
          //   Followed by 0 if SecSi not factory protected.
          //   Followed by 1 if SecSi factory protected.
          //   @19 line stands for PPMLB
          //   @1A line stands for SPMLB
          $readmemb(prot_file_name,PPB_preload);
        end
        if (UserPreload && !( secsi_file_name == "none"))
        begin  //am29bdd_secsi memory file
          //   //      - comment
          //   @aa     - <aa> stands for address within SecSi sector
          //   dd      - <dd> is byte to be written at SecSi(aa++)
          //  (aa is incremented at every load)
           $readmemh(secsi_file_name,SecSi_preload);
        end
        if (UserPreload && !( mem_file_name == "none"))
        begin
           //am29bdd160g memory file
           //   //       - comment
           //   @aaaa   - <aaaa> stands for address
           //   dddd    - <dddd> is word to be written at Mem(aaaa++)
           //   (aaaa is incremented at every load)
           //
           //   32 words region for BURST mode testing starts at A0
           //   from each sector beginning address
           $readmemh(mem_file_name,Flash);
        end

        for (i=0;i<=SecNum;i=i+1)
        begin
            EraseSecFlag[i] = 0;
            DYB[i]=0;
        end
        for (i=0;i<=GroupNum;i=i+1)
        begin
           PPB[i] = PPB_preload[i];
        end
        SecSiPB            = PPB_preload[24];
        PasswordMODELock   = PPB_preload[25];
        PersistentMODELock = PPB_preload[26];


        for (i=0;i<SecSiSize;i=i+1)
        begin
             SecSiRegion[i] = SecSi_preload[i];
        end
     end

///////////////////////////////////////////////////////////////////
//                Pulse width protection                         //
///////////////////////////////////////////////////////////////////

always @(OENeg)
begin
     //if (OENeg)
     //   #5 OENeg_gl <= OENeg;
     //else  OENeg_gl <= OENeg;
     OENeg_gl <= OENeg;
end

always @(CENeg)
begin
     if (~CENeg)
        #5 CENeg_gl <= CENeg;
     else  CENeg_gl <= CENeg;
end

always @(WENeg)
begin
     if (~WENeg)
        #5 WENeg_gl <= WENeg;
     else  WENeg_gl <= WENeg;
end

///////////////////////////////////////////////////////////////////
//                       Command Detect                          //
///////////////////////////////////////////////////////////////////

    always @(ADVNeg)
    begin
         if ( SYNC && ~CENeg_gl && ADVNeg )       -> LatchNow_A;
         if ( ~ADVNeg ) latched = 1'b0;
    end

    always @(CLK)
    begin
         if ( SYNC && ~CENeg_gl && ~ADVNeg && CLK )-> LatchNow_A;
    end

    always @(WENeg_gl,CENeg_gl)
    begin
         if ( ~SYNC && ~WENeg_gl && ~CENeg_gl && OENeg_gl ) -> LatchNow_A;
    end

    always @(CENeg_gl)
    begin
         if ( OENeg_gl && CENeg_gl && ~WENeg_gl ) -> LatchNow_D;
    end

    always @(WENeg_gl)
    begin
         if ( OENeg_gl && WENeg_gl && ~CENeg_gl ) -> LatchNow_D;
    end

    always @(LatchNow_A)
    begin
         if ( ( ~latched && SYNC ) || ~SYNC )
         begin
           // address latched on rising clock edge while ADV# LOW
           // address latched on rising ADV#  edge
           // assumption : address kept stable for both these events !
           if ( SYNC ) latched = 1'b1;
           if ( WORDNeg )
               CommandRegAddr = A % 16'h1000;
           else
           begin
               CommandRegAddr = {A,Am1} % 16'h1000;
               LatchAddrLSB   = Am1;
           end
           LatchAddr = A;
           if ( SYNC && WENeg_gl )
             -> ReadAddrLatched;
         end
         else
            if ( SYNC ) latched = 1'b0;
    end

    always @(LatchNow_D)
    begin
         CommandRegData = DIn[7:0];
         LatchData = DIn;
         -> CommandDataLatched;
    end

    always @(negedge OENeg)
    begin : OE_burstF
        #OEDQ_01 OE_burst = 1'b0;
    end

    always @(posedge OENeg)
    begin : OE_burstR
        disable OE_burstF;
        OE_burst = 1'b1;
    end

    always @( RESETNeg )
    begin
         if ( ~RESETNeg )
             #499 RESET_D <= RESETNeg;
         else     RESET_D  = 1'b1;
    end

///////////////////////////////////////////////////////////////////
//                   READ operation Detect                       //
///////////////////////////////////////////////////////////////////

    always @(CENeg)
    begin
        CENeg_event = $time;
        if ( ~SYNC && ~CENeg && ~OENeg && WENeg && RESET_D )
        -> ReadNow;
    end

    always @(OENeg)
    begin
        OENeg_event = $time;
        if ( ~SYNC && ~CENeg && ~OENeg && WENeg && RESET_D )
        -> ReadNow;
    end

    always @(A,Am1)
    begin
        if ( ~SYNC && ~CENeg && ~OENeg && WENeg && RESET_D )
        -> ReadNow;
    end

    //always @(CENeg_gl, OENeg_gl, A, Am1 )
    //begin
    //    if ( ~SYNC && ~CENeg_gl && ~OENeg_gl && WENeg_gl && RESET_D )
    //    -> ReadNow;
    //end

    always @(ReadAddrLatched)
    begin
      if (SYNC)
        -> ReadNow;
    end

    always @(RESET_D)
    begin
      if ( ~RESET_D )
      begin

         for(i=0;i<=SecNum;i=i+1)
            DYB[i] = 1'b0;
         ConfReg = 16'b1001110011000100;
         SYNC    = 1'b0;
         SecSiENABLED  = 1'b0;
         FirstUnlockCycle = 2'd0;
         IrregularSeq  = 1'b0;
         PassORDER     = 1'b0;
         if ( PasswordMODELock )
            PPBLockBit = 1'b1;
         else
            PPBLockBit = 1'b0;
         disable TWPProgr;
         WPProg_in     = 1'b0;
         disable TPEraser;
         PErase_in     = 1'b0;
         disable TSUSr;
         SUS_in        = 1'b0;
         disable TCEraser;
         CErase_in     = 1'b0;
         disable TSAWindowr;
         SAWindow_in   = 1'b0;
         disable TNVProgr;
         NVProg_in     = 1'b0;
         disable TNVErsr;
         NVErs_in      = 1'b0;
         disable PassProgDoneP;
         PassProgDone  = 1'b0;
         disable PassWindowP;
         PassWindow    = 1'b0;
         UnlockPassOK  = 1'b1;
         disable ProgDoneP;
         ProgDone      = 1'b0;
         disable SEDoneP;
         SEDone        = 1'b0;
         BankE(1'b0);
         for(i=0;i<=SecNum;i=i+1)
             EraseSecFlag[i] = 1'b0;

         if ( CommandCurrentState == PROGRAM || CommandCurrentState == PROGRAM_E
            || CommandCurrentState == SE || CommandCurrentState == CE
            || CommandCurrentState == PROGRAM_NV )
         begin
            CommandCurrentState = DUMMY;
            CurrentState        = DUMMY;
            RESInterval_in = 1'b1;
         end
         else
         begin
            CommandCurrentState = INIT;
            CurrentState        = READ_ASYNC;
         end
      end
   end

   always @(RESInterval_out)
   begin
        if (RESInterval_out)
        begin
           RY_zd               = 1'b1;
           RESInterval_in      = 1'b0;
           CommandCurrentState = INIT;
           CurrentState        = READ_ASYNC;
        end
   end

   always @(SEDone)
   begin
        if (SEDone)
        begin
           RY_zd = 1'b1;

           for(i=0;i<=SecNum;i=i+1)
           begin

              if (~(SecSiENABLED && i==SecSiSector))
                if ( EraseSecFlag[i] )
                begin
                   AddrBORDERS(AddrLOW,AddrHIGH,i);
                   if (~ (DYB[i] || PPB[ReturnGroupID(i)] ||
                   (~WPNeg && (i == HWProtect1 || i == HWProtect2))))
                     for(j=AddrLOW;j<=AddrHIGH;j=j+1)
                       Flash[j] = MaxData;
                end
             EraseSecFlag[i]=1'b0;
           end
           BankE(1'b0);
           CommandCurrentState = INIT;
           CurrentState = READ_ASYNC + SYNC;

        end
   end

  always @(NVProg_out)
  begin
       if (NVProg_out)
       begin
            RY_zd     = 1'b1;
            NVProg_in = 1'b0;
            CommandCurrentState = BITOP;
            CurrentState        = CANNOTREAD;
            if (SecSiPBSequence == 1)
               SecSiPB = 1'b1;
            else if (PPMLBSequence == 1)
            begin
               if ( PersistentMODELock != 1'b1 )
               begin
               PasswordMODELock = 1'b1;
               PPBLockBit = 1'b1;
               end
            end
            else if (SPMLBSequence == 1)
            begin
               if ( PasswordMODELock != 1'b1 )
                   PersistentMODELock = 1'b1;
            end
            else if (PPBSequenceProg == 1)
               if ( PPBLockBit != 1'b1 )
                    PPB[GroupID] = 1'b1;
        end
   end

   always @(NVErs_out)
   begin
        if (NVErs_out)
        begin
             RY_zd    = 1'b1;
             NVErs_in = 1'b0;
             CommandCurrentState = BITOP;
             CurrentState        = CANNOTREAD;
             if ( PPBSequenceErase == 1 )
                if ( PPBLockBit == 1'b0 )
                     for(i=0;i<=GroupNum;i=i+1)
                        PPB[i] = 1'b0;
        end
   end

   always @( PassProgDone)
   begin

        if ( PassProgDone )
        begin
        RY_zd = 1'b1;
        if ( PassWORD )
             PasswordRegion[PassAddr] =
             PassData[15:0] & PasswordRegion[PassAddr];

        else
           if ( PassAddr < 2 )
           begin
             PasswordRegion[0] =
             PassData[15:0] & PasswordRegion[0];
             PasswordRegion[1] =
             PassData[31:16]& PasswordRegion[1];
           end
           else
           begin
             PasswordRegion[2] =
             PassData[15:0] & PasswordRegion[2];
             PasswordRegion[3] =
             PassData[31:16]& PasswordRegion[3];
           end


        CurrentState        = CANNOTREAD;
        CommandCurrentState = PASS_PROGRAM;

        end
   end

   always @(ProgDone)
   begin
     if ( ProgDone )
     begin
        if (SecSiENABLED && (SectorProg==SecSiSector))
        begin
            if (!Top(0))
                   AddrProg = AddrProg - 20'hFF000;

            if (~SecSiPB && (AddrProg<=12'h7FF))
            begin
               if (WORDProg)
               begin
                SecSiRegion[AddrProg] = DataProg[15:0] & SecSiRegion[AddrProg];

               end
               else
               begin
                SecSiRegion[AddrProg]   = DataProg[15:0]  & SecSiRegion[AddrProg];
                SecSiRegion[AddrProg+1] = DataProg[31:16] & SecSiRegion[AddrProg+1];

               end
            end

       end
       else
            if ( WORDProg )
            begin
                Flash[AddrProg] = DataProg[15:0] & Flash[AddrProg];

            end
            else
            begin
                Flash[AddrProg] = DataProg[15:0] & Flash[AddrProg];

                Flash[AddrProg+1] = DataProg[31:16] & Flash[AddrProg+1];

            end

      if (CommandCurrentState == PROGRAM_E)
           begin
             CommandCurrentState = ESP;
             CurrentState           = READ_ESP;
             SecSiEE = 0;
             ESPProg = 1'b0;
           end
           else
           begin
             if ( UNLOCKBYPASS )
             begin
                  CommandCurrentState = UBP;
                  CurrentState = CANNOTREAD;
             end
             else
             begin
                  CommandCurrentState = INIT;
                  CurrentState = READ_ASYNC + SYNC;
             end
           end
           RY_zd = 1'b1;
       end
      end

   always @(WPProg_out)
   begin
        if ( WPProg_out )
        begin
          RY_zd     = 1'b1;
          WPProg_in = 1'b0;
          if ( CurrentState == WRITESTATUS )
            if ( UNLOCKBYPASS )
            begin
                 CommandCurrentState = UBP;
                 CurrentState        = CANNOTREAD;
            end
            else
            begin
                 CommandCurrentState = INIT;
                 CurrentState = READ_ASYNC + SYNC;
            end
         else // WRITESTATUS_E
            begin
                 CommandCurrentState = ESP;
                 CurrentState        = READ_ESP;
                 SecSiEE = 0;
                 ESPProg = 1'b0;
            end
       end
   end

   always @(SAWindow_out)
   begin
        if ( SAWindow_out )
        begin
             SAWindow_in = 1'b0;
             if ( AllProtected )
             begin
                 CommandCurrentState = RESET_OR_IGNORE;
                 CurrentState        = SESTATUS;
                 PErase_in           = 1'b1;
                 RY_zd               = 1'b0;
             end
             else
             begin
                 CommandCurrentState = SE;
                 CurrentState        = SESTATUS;
                 SEStart = 1'b1;
                 RY_zd   = 1'b0;
                 #tcomm SEStart <= 1'b0;
             end
       end
   end

   always @(PassWindow)
   begin
        if (PassWindow)
        begin
             UnlockPassOK = 1'b1;
             RY_zd        = 1'b1;
             CommandCurrentState = PASS_UNLOCK;
             CurrentState        = CANNOTREAD;
             if ( PassWORD )
               if ((PassAddr == PassORDER)
                  && (PassData[15:0]==PasswordRegion[PassAddr]))
                  PassORDER = PassORDER + 1;
              else
                  PassORDER = 0;

            else
              if (((PassAddr < 2)
                  && ({PasswordRegion[1],PasswordRegion[0]}==PassData)
                   && PassORDER == 0)
              ||
              ((PassAddr >= 2)
                 && ({PasswordRegion[3],PasswordRegion[2]}==PassData)
                    && PassORDER ==2))
              begin
                 if ( PassORDER == 0 ) PassORDER = 2;
                 else PassORDER = 4;
              end
              else
              begin
                PassORDER = 0;
              end

            if ( PassORDER == 4 )
            begin
              PassORDER = 0;
              PPBLockBit = 1'b0;
            end
        end
   end

  always @(PErase_out)
  begin
       if ( PErase_out )
       begin
            RY_zd     = 1'b1;
            PErase_in = 1'b0;
            CommandCurrentState = INIT;
            CurrentState = READ_ASYNC + SYNC;
       end
  end

  always @(SUS_out)
  begin
       if (SUS_out)
       begin
            RY_zd   = 1'b1;
            SUS_in  = 1'b0;
            SecSiEE = 0;
            ESPProg = 1'b0;
            if ( CommandCurrentState == PROGRAM
               || CommandCurrentState == PROGRAM_UBP )
            begin
            CommandCurrentState = PSP;
            CurrentState        = READ_PSP;
            end
            if ( CommandCurrentState == SE )
            begin
            CommandCurrentState = ESP;
            CurrentState        = READ_ESP;
            end
            if ( CommandCurrentState == PROGRAM_E )
            begin
            CommandCurrentState = PSP_E;
            CurrentState        = READ_PSP_E;
            end
       end
  end

  always @(CErase_out)
  begin
       if ( CErase_out )
       begin
            RY_zd     = 1'b1;
            CErase_in = 1'b0;
            if ( UNLOCKBYPASS )
            begin
            CommandCurrentState = UBP;
            CurrentState        = CANNOTREAD;
            end
            else
            begin
            CommandCurrentState = INIT;
            CurrentState = READ_ASYNC + SYNC;
            end
            for(i=0;i<=SecNum;i=i+1)
            begin

              if (~(SecSiENABLED && i==SecSiSector ))
                   AddrBORDERS(AddrLOW,AddrHIGH,i);
                   if (~ (DYB[i] || PPB[ReturnGroupID(i)] ||
                   (~WPNeg && (i == HWProtect1 || i == HWProtect2)) ))
                     for(j=AddrLOW;j<=AddrHIGH;j=j+1)
                       Flash[j] = MaxData;
            end

      end
  end

    ////////////////////////////////////////////////////////////
   //                    WRITE CYCLES                        //
  ////////////////////////////////////////////////////////////

  always @(CommandDataLatched)
  begin
     UNLOCK_1 = (((CommandRegAddr == 12'h555)  && (WORDNeg))
                  || (( CommandRegAddr == 12'hAAA ) && (~WORDNeg)))
                   &&  (CommandRegData == 8'hAA);

     UNLOCK_2 = (((CommandRegAddr == 12'h2AA) && (WORDNeg))
                  || ((CommandRegAddr == 12'h555) && (~WORDNeg)))
                   && (CommandRegData == 8'h55);

     VALIDCYC = ((CommandRegAddr == 12'h555   && WORDNeg)
                  || (CommandRegAddr == 12'hAAA && ~WORDNeg));

     case ( CommandCurrentState )

     INIT :
     begin
     if ( RESET_D )
     begin
            IrregularSeq = 1'b0;
            // Detection of CFI Query, unable when SecSi enabled
        if (((((CommandRegAddr == 8'h55) && (WORDNeg))
            ||((CommandRegAddr == 8'hAA) && (~WORDNeg)))
            && (CommandRegData == 8'h98) && ~SecSiENABLED )
            && (CommandCurrentState != UBP) )
        begin
            CurrentState        = READ_CFI;
            CommandCurrentState = RESET_OR_IGNORE;
        end
        // Detection of first unlock cycle
        else if ( UNLOCK_1 && ~FirstUnlockCycle )
        begin
            FirstUnlockCycle = 1'b1;
            CurrentState     = CANNOTREAD;
        end
         // Detection of second unlock cycle
        else if ( UNLOCK_2 && FirstUnlockCycle )
        begin
            FirstUnlockCycle = 1'b0;
            // Two unlock cycles finished properly
            CommandCurrentState = TWO_UNLOCK;
        end
        else
        begin
            IrregularSeq = 1'b1;
            FirstUnlockCycle = 1'b0;
        end
     end
     end

     UBP :
     begin
        if (( CommandRegData == 8'hA0 )
            && ( CESeqUBP == 0 ) && ( RESSeqUBP == 0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState           = PROGCYC;
            CommandCurrentState    = WRITECYC;
        end
        else if (( CommandRegData == 8'h80 )
            && ( CESeqUBP == 0 ) && ( RESSeqUBP == 0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = CANNOTREAD;
            CESeqUBP = 1;
        end
        else if (( CommandRegData == 8'h10 )
            && ( CESeqUBP == 1 ) && ( RESSeqUBP == 0 ))
        begin
            IrregularSeq        = 1'b0;
            CurrentState        = CESTATUS;
            CommandCurrentState = CE;
            CErase_in           = 1'b1;
            RY_zd               = 1'b0;
            CESeqUBP            = 0;
        end
        else if (( CommandRegData == 8'h98)
        && ( RESSeqUBP == 0 ) && ( CESeqUBP == 0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState        = READ_CFI;
            CommandCurrentState = RESET_OR_IGNORE;
        end
        else if (( CommandRegData == 8'h90 )
            && ( RESSeqUBP == 0 ) && ( CESeqUBP == 0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = CANNOTREAD;
            RESSeqUBP = 1;
        end
        else if (( CommandRegData == 8'h00 )
            && ( RESSeqUBP == 1 ) && ( CESeqUBP == 0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = READ_ASYNC + SYNC;
            CommandCurrentState = INIT;
            RESSeqUBP           = 0;
            UNLOCKBYPASS        = 1'b0;
        end
        else
        begin
            CESeqUBP = 0;
            RESSeqUBP = 0;
            CurrentState = CANNOTREAD;
            CommandCurrentState = UBP;
        end
     end

     TWO_UNLOCK :
     begin
        IrregularSeq = 1'b1;
        // Detection of Program Command
        if ( VALIDCYC && (CommandRegData == 8'hA0))
        begin
            IrregularSeq = 1'b0;
            CurrentState = PROGCYC;
            CommandCurrentState = WRITECYC;
        end
        // Detection of Chip Erase command
        if ( VALIDCYC && ( CommandRegData == 8'h80 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = CANNOTREAD;
            CommandCurrentState = CERASESEQ;
            CESeq = 0;
        end
        // Detection of Configuration Register Verfiy
        if ((CommandRegAddr == 12'h555)
          && ( CommandRegData == 8'hC6 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = CRVERIFY;
            CommandCurrentState = RESET_OR_IGNORE;
            if ( ReturnBank(LatchAddr) == SMALL)
                 CRVerifySmallBank = 1'b1;
            else CRVerifySmallBank = 1'b0;
        end
        // Detection of Configuration Register Write
        if ( VALIDCYC && ( CommandRegData == 8'hD0 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = CRWRITE;
            CommandCurrentState = WRITECYC;
        end
        // Detection of Protection bits operation
        if ( VALIDCYC && ( CommandRegData == 8'h60 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = BITSTATUS;
            CommandCurrentState = BITOP;
            PPBSequenceProg  = 0;
            PPBSequenceErase = 0;
            SSBSequence      = 0;
            PPMLBSequence    = 0;
            SPMLBSequence    = 0;
            SecSiPBSequence  = 0;
        end
        // Detection of DYB Write or Erase
        if ( VALIDCYC && ( CommandRegData == 8'h48 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = DYB_WE;
            CommandCurrentState = WRITECYC;
        end
        // Detection of DYB/PPB Status
        if ( VALIDCYC && ( CommandRegData == 8'h58 ))
        begin
            IrregularSeq = 1'b0;
            BankDYBPPB = ReturnBank(LatchAddr);
            CurrentState = DYBPPBSTATUS;
            CommandCurrentState = RESET_OR_IGNORE;
        end
        // Detection of PPB Lock Bit Set
        if ( VALIDCYC && ( CommandRegData == 8'h78 ))
        begin
            IrregularSeq = 1'b0;
            CurrentState = READ_ASYNC + SYNC;
            CommandCurrentState = INIT;
            if ( PasswordMODELock == 1'b0 )
                 PPBLockBit = 1'b1;
        end
        // Detection of leading sequence of AUTOSELECT,
        // SecSi EXIT or PPB Lock bit Status
        if ( VALIDCYC && ( CommandRegData == 8'h90 ))
        begin
            IrregularSeq        = 1'b0;
            CurrentState        = ASEL;
            BankASEL            = ReturnBank(LatchAddr);
            CommandCurrentState = SecEXIT;
            ASELFlag            = 1'b0;
        end
        // Detection of UNLOCK BYPASS, not recognizeable when SecSi enabled
        if ( VALIDCYC && ( CommandRegData == 8'h20))
        begin
            IrregularSeq = 1'b0;
            // command ignored but not illegal
            if (~SecSiENABLED)
            begin
                 CurrentState        = CANNOTREAD;
                 CommandCurrentState = UBP;
                 CESeqUBP            = 0;
                 RESSeqUBP           = 0;
                 UNLOCKBYPASS        = 1'b1;
            end
        end
        // Detection of SecSi ENTRY
        if ( VALIDCYC && ( CommandRegData == 8'h88 ))
        begin
            IrregularSeq = 1'b0;
            SecSiENABLED = 1'b1;
            CurrentState = READ_ASYNC + SYNC;
            CommandCurrentState = INIT;
        end
        // Detection of Password Program command
        // not recognizeable if PPMLB set
        if ( VALIDCYC && (~PasswordMODELock) && (CommandRegData == 8'h38))
        begin
            IrregularSeq = 1'b0;
            CommandCurrentState = PASS_PROGRAM;
            CurrentState = CANNOTREAD;
            PassProgSequence = 3;
        end
        // Detection of Password Verify command
        if ( VALIDCYC && ( CommandRegData == 8'hC8 ))
        begin
            IrregularSeq = 1'b0;
            CommandCurrentState = RESET_OR_IGNORE;
            CurrentState = PASS_VERIFY;
        end
        // Detection of Password Unlock command
        if ( VALIDCYC && ( CommandRegData == 8'h28 ))
        begin
            IrregularSeq = 1'b0;
            PassUnlockSequence = 3;
            CommandCurrentState = PASS_UNLOCK;
            //PassWindow = 1'b1;
        end
     end

     SecEXIT :
     begin
        IrregularSeq = 1'b1;
        if ( CommandRegData == 8'h00 )
        begin
            SecSiENABLED = 1'b0;
            IrregularSeq = 1'b0;
            CommandCurrentState      = INIT;
            CurrentState = READ_ASYNC + SYNC;
        end
     end

     CERASESEQ :
     begin
        IrregularSeq = 1'b1;
        if ( UNLOCK_1 && ( CESeq == 0 ))
        begin
            IrregularSeq = 1'b0;
            CESeq = 1;
        end
        if ( UNLOCK_2 && ( CESeq == 1 ))
        begin
            IrregularSeq = 1'b0;
            CESeq = 2;
        end
        if ( VALIDCYC && ( CommandRegData == 8'h10 ) && ( CESeq == 2 ))
        begin
            IrregularSeq = 1'b0;
            CESeq = 0;
            CurrentState           = CESTATUS;
            CommandCurrentState = CE;
            CErase_in = 1'b1;
            RY_zd     = 1'b0;
        end
        if (( CommandRegData == 8'h30 ) && ( CESeq == 2 ))
        begin
            IrregularSeq = 1'b0;
            CESeq = 0;
            EraseSecFlag[ReturnSectorID(LatchAddr)] = 1'b1;
            AllProtected = ( DYB[ReturnSectorID(LatchAddr)]
            || PPB[ReturnGroupID(ReturnSectorID(LatchAddr))]
            || (~WPNeg && (ReturnSectorID(LatchAddr)==HWProtect1 ||
            ReturnSectorID(LatchAddr) == HWProtect2)));
            if ( AllProtected )
                 SETime = 0;
            else SETime = tdevice_SE;
            //BankErase = ReturnBank(LatchAddr);
            BankE(1'b1);

            CurrentState        = SESTATUS;
            CommandCurrentState = SETIMEOUT;
            SAWindow_in         = 1'b1;
        end
     end

     BITOP :
     begin
        IrregularSeq = 1'b1;
        if (CommandRegData == 8'h68 )
        begin
            if (((LatchAddr[5:0] == OW0)||(LatchAddr[5:0] == OW1))
              && (SecSiPBSequence == 0))
            begin
                // SecSi Protection bit program
                IrregularSeq = 1'b0;
                SecSiPBSequence = 1;
                CurrentState = NV_STATUS;
                CommandCurrentState = PROGRAM_NV;
                NVProg_in = 1'b1;
                RY_zd     = 1'b0;
            end
            if (((LatchAddr[5:0] == PL0)||(LatchAddr[5:0] == PL1))
               && (PPMLBSequence == 0))
            begin
                // PPMLB Program
                IrregularSeq = 1'b0;
                PPMLBSequence = 1;
                CurrentState = NV_STATUS;
                CommandCurrentState = PROGRAM_NV;
                // if SPMLB already set, mode permanently chosen
                // can't set PPMLB, time-out without programming
                NVProg_in  = 1'b1;
                RY_zd      = 1'b0;
            end
            if (((LatchAddr[5:0] == SL0) || (LatchAddr[5:0] == SL1))
               && (SPMLBSequence == 0))
            begin
                // SPMLB Program
                IrregularSeq = 1'b0;
                SPMLBSequence = 1;
                CurrentState = NV_STATUS;
                CommandCurrentState = PROGRAM_NV;
                NVProg_in  = 1'b1; // can be programmed
                RY_zd      = 1'b0;
            end
            if (((LatchAddr[5:0] == WP0) || (LatchAddr[5:0] == WP1))
               && (PPBSequenceProg == 0))
            begin
                // PPB Program, SA dependent
                IrregularSeq = 1'b0;
                PPBSequenceProg = 1;
                CurrentState = NV_STATUS;
                CommandCurrentState = PROGRAM_NV;
                GroupID = ReturnGroupID(ReturnSectorID(LatchAddr));
                NVProg_in  = 1'b1;
                RY_zd      = 1'b0;
            end
        end

        if (CommandRegData == 8'h48 )
        begin

            if (((LatchAddr[5:0] == OW0) || (LatchAddr[5:0] == OW1))
              && (SecSiPBSequence == 1))
            begin
                // SecSi Protection bit program
                IrregularSeq = 1'b0;
                SecSiPBSequence = 2;
                CurrentState = BITSTATUS;
                CommandCurrentState = IRREG;
            end
            if (((LatchAddr[5:0] == PL0) || (LatchAddr[5:0] == PL1))
              && (PPMLBSequence == 1))
            begin
                // PPMLB Program
                IrregularSeq = 1'b0;
                PPMLBSequence = 2;
                CurrentState = BITSTATUS;
                CommandCurrentState = IRREG;
            end
            if (((LatchAddr[5:0] == SL0) || (LatchAddr[5:0] == SL1))
              && (SPMLBSequence == 1))
            begin
                // SPMLB Program
                IrregularSeq = 1'b0;
                SPMLBSequence = 2;
                CurrentState = BITSTATUS;
                CommandCurrentState = IRREG;
            end
            if (((LatchAddr[5:0] == WP0) || (LatchAddr[5:0] == WP1))
              && (PPBSequenceProg == 1)
                && ( ReturnGroupID(ReturnSectorID(LatchAddr)) == GroupID ))
            begin
                 // PPB Program, SA dependent
                 IrregularSeq = 1'b0;
                 PPBSequenceProg = 2;
                 CurrentState = PPB_VERIFY;
                 CommandCurrentState = IRREG;
            end

        end
        // All PPB Erase
        if (((LatchAddr[5:0] == WP0) || (LatchAddr[5:0] == WP1))
          && (PPBSequenceErase == 0) && ( CommandRegData == 8'h60))
        begin
            IrregularSeq = 1'b0;
            PPBSequenceErase = 1;
            CurrentState = NV_STATUS;
            CommandCurrentState = PROGRAM_NV;
            NVErs_in  = 1'b1;
            RY_zd     = 1'b0;
        end
        if (((LatchAddr[5:0] == WP0) || (LatchAddr[5:0] == WP1))
          && (PPBSequenceErase == 1) && ( CommandRegData == 8'h40))
        begin
            IrregularSeq = 1'b0;
            PPBSequenceErase = 2;
            CurrentState = PPB_ALL_STATUS;
            CommandCurrentState = IRREG;
            SectorID = ReturnSectorID(LatchAddr);
        end
        if ( IrregularSeq )
        begin
            PPBSequenceProg  = 0;
            PPBSequenceErase = 0;
            SSBSequence      = 0;
            PPMLBSequence    = 0;
            SPMLBSequence    = 0;
            SecSiPBSequence  = 0;
        end
     end

     RESET_OR_IGNORE :
     begin
        if ( CommandRegData == 8'hF0 )
        begin
            if ( UNLOCKBYPASS )
            begin
                 CurrentState         = CANNOTREAD;
                 CommandCurrentState  = UBP;
            end
            else
            begin
                 CurrentState = READ_ASYNC + SYNC;
                 CommandCurrentState = INIT;
            end
        end
     end

     PROGRAM, PROGRAM_UBP, PROGRAM_E :
     begin
        // During EPA only Suspend command is valid
        // Suspend command not possible when SecSi enabled
        if ((CommandRegData == 8'hB0 ) && ~SecSiENABLED
          && (ReturnBank(LatchAddr) == BankProg ))
        begin
            SUS_in = 1'b1;
            ProgSuspend = 1'b1;
            #tcomm ProgSuspend <= 1'b0;
        end
     end

     SETIMEOUT :
     begin
        IrregularSeq = 1'b1;
        // New SA within 80us window
        if (CommandRegData == 8'h30) //&& ( ReturnBank(LatchAddr) == BankErase ))
        begin
            BankE(1'b1);
            IrregularSeq = 1'b0;
            EraseSecFlag[ReturnSectorID(LatchAddr)]=1'b1;
            SEProtected  = ( DYB[ReturnSectorID(LatchAddr)]
            || PPB[ReturnGroupID(ReturnSectorID(LatchAddr))]
            || (~WPNeg && (ReturnSectorID(LatchAddr)==HWProtect1 ||
            ReturnSectorID(LatchAddr) == HWProtect2)));
            AllProtected = AllProtected && SEProtected;
           if (~SEProtected) SETime = SETime + tdevice_SE;
               // Restart sector address window
           disable TSAWindowr;
           SAWindow_in    = 1'b0;
          #1 SAWindow_in <= 1'b1;
        end

        // Erase Suspend, Sector Erase not yet begun, suspension immediate
        // ignored if SecSi enabled
        if ((CommandRegData == 8'hB0) && BusyBankE(LatchAddr))
        begin
            // if SecSi not enabled, command is ignored, not illegal
            IrregularSeq = 1'b0;
            if (~SecSiENABLED)
            begin
               disable TSAWindowr;
               SAWindow_in    = 1'b0;
               SEStartSuspend = 1'b1;
               #tcomm SEStartSuspend <= 1'b0;
               CommandCurrentState   = ESP;
               SecSiEE      = 0;
               ESPProg      = 1'b0;
               CurrentState = READ_ESP;
             end
        end
        // additional activities in this case
        // excludes activities performed at the end of this process
        if ( IrregularSeq  )
        begin
            disable TSAWindowr;
            SAWindow_in = 1'b0;
            for(i=0;i<=SecNum;i=i+1)
              EraseSecFlag[i]=1'b0;
        end
     end
     SE :
     begin
        // Suspend command not possible when SecSi enabled
        if ((CommandRegData == 8'hB0) && ~SecSiENABLED && BusyBankE(LatchAddr))
        begin
            SUS_in = 1'b1;
            SESuspend   = 1'b1;
            #tcomm SESuspend   <= 1'b0;
        end
     end

     PSP, PSP_E :
     begin
        // Recognize SecSiEntry and SecSiExit
        if ( UNLOCK_1 && (SecSiEE==0))
            SecSiEE=1;
        else if ( UNLOCK_2 && (SecSiEE==1))
            SecSiEE = 2;
        else if ( VALIDCYC && (CommandRegData == 8'h88 ) && (SecSiEE==2))
        begin
            SecSiEE = 0;
            SecSiENABLED = 1'b1;
        end
        else if ( VALIDCYC && (CommandRegData == 8'h90 ) && (SecSiEE==2))
        begin
            SecSiEE = 3;
            CurrentState = ASEL;
            BankASEL     = ReturnBank(LatchAddr);
            ASELFlag     = 1'b0;
        end
        else if ((CommandRegData == 8'h00 ) && (SecSiEE==3))
        begin
            SecSiEE = 0;
            SecSiENABLED = 1'b0;
            if ( CommandCurrentState == PSP )
                 CurrentState = READ_PSP;
            else CurrentState = READ_PSP_E;
        end
        // Recognize Resume command
        else if (( CommandRegData == 8'h30 ) && ~SecSiENABLED
          && ( ReturnBank(LatchAddr) == BankProg ) && (SecSiEE == 0))
        begin
            if ( CommandCurrentState == PSP )
            begin
                  if ( UNLOCKBYPASS )
                       CommandCurrentState = PROGRAM_UBP;
                  else CommandCurrentState = PROGRAM;
                  CurrentState = WRITESTATUS;
            end
            else if ( CommandCurrentState == PSP_E )
            begin
                  CommandCurrentState = PROGRAM_E;
                  CurrentState        = WRITESTATUS_E;
            end
            ProgResume = 1'b1;
            RY_zd      = 1'b0;
            #tcomm ProgResume <= 1'b0;
        end
        // Recognize CFI query
        else if ( ( CommandRegData == 8'h98 ) && ~SecSiENABLED
          && (((CommandRegAddr == 8'hAA) && ~WORDNeg)
            || ((CommandRegAddr == 8'h55) && WORDNeg )) && (SecSiEE==0))
        begin
            if ( CommandCurrentState == PSP )
            begin
                  CommandCurrentState = PSP_CFI;
                  CurrentState        = READ_CFI;
            end
            else if ( CommandCurrentState == PSP_E )
            begin
                  CommandCurrentState = PSP_E_CFI;
                  CurrentState        = READ_CFI;
            end
        end
        else
        begin
            SecSiEE =0;
            CurrentState = READ_PSP;
            if ( CommandCurrentState == PSP_E )
                CurrentState = READ_PSP_E;
        end
     end

     PSP_CFI, PSP_E_CFI, PSP_ASEL, PSP_E_ASEL, ESP_CFI, ESP_ASEL :
     begin
        if ( CommandRegData == 8'hF0 )
            if ( CommandCurrentState == ESP_CFI
              || CommandCurrentState == ESP_ASEL )
            begin
                  CommandCurrentState = ESP;
                  CurrentState        = READ_ESP;
            end
            else
                  if ((CommandCurrentState == PSP_CFI)
                    || (CommandCurrentState == PSP_ASEL))
                  begin
                       CurrentState        = READ_PSP;
                       CommandCurrentState = PSP;
                  end
                  else
                  begin
                       CurrentState        = READ_PSP_E;
                       CommandCurrentState = PSP_E;
                  end

     end

     ESP :
     begin
        // Recognize SecSiEntry,SecSiExit and Program command
        if ( UNLOCK_1 && (SecSiEE==0) && ~ESPProg )
            SecSiEE=1;
        else if ( UNLOCK_2 && (SecSiEE==1) && ~ESPProg )
            SecSiEE = 2;
        else if ( VALIDCYC && (CommandRegData == 8'h88)
            && (SecSiEE==2) && ~ESPProg )
        begin
            SecSiEE = 0;
            SecSiENABLED = 1'b1;
        end
        else if ( VALIDCYC && (CommandRegData == 8'h90 )
                    && (SecSiEE==2) && ~ESPProg )
        begin
            SecSiEE = 3;
            CurrentState = ASEL;
            BankASEL     = ReturnBank(LatchAddr);
            ASELFlag     = 1'b0;
        end
        else if  ((CommandRegData == 8'h00 ) && (SecSiEE==3) && ~ESPProg )
        begin
            SecSiEE = 0;
            SecSiENABLED = 1'b0;
            CurrentState       = READ_ESP;
        end
        else if ( VALIDCYC && (CommandRegData == 8'hA0 )
            && (SecSiEE==2) && ~ESPProg )
        begin
            SecSiEE = 0;
            ESPProg= 1'b0;
            CommandCurrentState = WRITECYC;
            CurrentState        = PROGCYC_E;
        end
        // Recognize Resume command,ignore if SecSi enabled
        else if (( CommandRegData == 8'h30 ) && ~SecSiENABLED
        && BusyBankE(LatchAddr) && (SecSiEE == 0))
        begin
            CommandCurrentState = SE;
            CurrentState = SESTATUS;
            SEResume  = 1'b1;
            RY_zd     = 1'b0;
            #tcomm SEResume  <= 1'b0;
        end
        // Recognize CFI query
        else if (( CommandRegData == 8'h98 ) && ~SecSiENABLED
          && (((CommandRegAddr == 8'h55) && WORDNeg)
              ||((CommandRegAddr == 8'hAA) && ~WORDNeg)) && (SecSiEE == 0))
        begin
            CommandCurrentState = ESP_CFI;
            CurrentState        = READ_CFI;
        end
        else
        begin
            SecSiEE =0;
            ESPProg=1'b0;
            CurrentState = READ_ESP;
        end

     end
     PASS_PROGRAM:
     begin
        if ((PassProgSequence==0) && UNLOCK_1 )
            PassProgSequence = 1;
        else if ((PassProgSequence==1) && UNLOCK_2 )
            PassProgSequence = 2;
        else if ((PassProgSequence==2) && (CommandRegData == 8'h38)
            && VALIDCYC )
            PassProgSequence = 3;
        else if ( PasswordMODELock == 1'b0 && PassProgSequence == 3 )
        begin
            PassProgSequence = 0;
            if (~WORDNeg)
            begin
                 PassWORD     = 1'b1;
                 RY_zd        = 1'b0;
                 -> PassProgDoneE;
            end
            else
            begin
                 PassWORD     = 1'b0;
                 RY_zd        = 1'b0;
                 -> PassProgDoneE;
            end
            PassAddr = {LatchAddr[0],LatchAddrLSB};
            PassData = LatchData;
            StatusReg[7] = LatchData[7];
            CurrentState = PASS_PROGRAM_STATUS;
            CommandCurrentState = DUMMY;
        end
        else if ( CommandRegData == 8'hF0 )
        begin
            CurrentState = READ_ASYNC + SYNC;
            CommandCurrentState = INIT;
        end
        else PassProgSequence = 0;

     end

     PASS_UNLOCK:
     begin
        if   ((PassUnlockSequence==0) && UNLOCK_1)
            PassUnlockSequence = 1;
        else if ((PassUnlockSequence==1) && UNLOCK_2)
            PassUnlockSequence = 2;
        else if ((PassUnlockSequence==2) && ( CommandRegData == 8'h28 )
          && VALIDCYC )
            PassUnlockSequence = 3;
        else if ( PasswordMODELock == 1'b1 && PassUnlockSequence == 3 )
        begin
            PassUnlockSequence = 0;
           // if ( PassWindow == 1'b1 )
            if ( UnlockPassOK )
            begin
                 RY_zd      = 1'b0;
                 -> PassWindowE;
                 PassAddr = {LatchAddr[0],LatchAddrLSB};
                 PassData = LatchData;
                 StatusReg[7] = LatchData[7];
                 PassWORD = ~WORDNeg;
                 CurrentState = PASS_UNLOCK_STATUS;
                 CommandCurrentState = DUMMY;
           end
        end
        else if ( CommandRegData == 8'hF0 )
        begin
           CurrentState = READ_ASYNC + SYNC;
           CommandCurrentState = INIT;
        end
        else PassProgSequence = 0;
     end

     WRITECYC :
     begin
     case ( CurrentState )
     PROGCYC, PROGCYC_E :
     begin
              SectorProg = ReturnSectorID(LatchAddr);
              GroupProg  = ReturnGroupID(SectorProg);
              BankProg = ReturnBank(LatchAddr);
              StatusReg[7] = LatchData[7];
              DataProg[7]  = LatchData[7];
              if (( DYB[SectorProg] || PPB[GroupProg] )
                 // Programming a protected sector
                                    ||
                 ((( SectorProg == HWProtect2 ) || ( SectorProg == HWProtect1 )) &&  (~WPNeg) )
                 // Hardware protected
                                    ||
                 ( (SectorProg == SecSiSector) && SecSiENABLED && SecSiPB )
                  // SecSi overlays but can not be changed due to SecSi Protection bit status
                                    ||
                  ( (CurrentState == PROGCYC_E) && EraseSecFlag[SectorProg] )  )

              begin

                 // Status for 1us then return to initial state
                 WPProg_in = 1'b1;
                 RY_zd     = 1'b0;
                 CommandCurrentState = DUMMY;
                 if ( CurrentState == PROGCYC )
                      CurrentState      = WRITESTATUS;
                 else CurrentState      = WRITESTATUS_E; //progcyc_E

              end
              else
              begin
                   if ( ~WORDNeg )
                   begin
                      AddrProg = {LatchAddr[18:0],LatchAddrLSB};
                      DataProg[15:0] = LatchData[15:0];
                      WORDProg = 1'b1;
                   end
                   else
                   begin
                      AddrProg = {LatchAddr[18:0],1'b0};
                      DataProg = LatchData[31:0];
                      WORDProg = 1'b0;
                    end
                    ProgStart  = 1'b1;
                    RY_zd      = 1'b0;
                    #tcomm ProgStart  <= 1'b0;
                    if ( CurrentState == PROGCYC )
                    begin
                      if ( UNLOCKBYPASS )
                           CommandCurrentState = PROGRAM_UBP;
                      else CommandCurrentState = PROGRAM;
                      CurrentState                = WRITESTATUS;
                    end
                    else // progcyc_E
                    begin
                      CommandCurrentState = PROGRAM_E;
                      CurrentState        = WRITESTATUS_E;
                    end
             end
    end

    CRWRITE :
    begin
        ConfReg = LatchData[15:0];
        SYNC    = ( LatchData[15] == 1'b0 );
        if ( UNLOCKBYPASS )
        begin
         CommandCurrentState = UBP;
          CurrentState       = CANNOTREAD;
        end
        else
        begin
         CommandCurrentState = INIT;
         CurrentState = READ_ASYNC + SYNC;
        end
    end

    DYB_WE :
    begin
        if (((~SecSiENABLED) || ( SecSiENABLED &&
                                ( ReturnSectorID(LatchAddr) != SecSiSector )))
           && ( LatchData[7:0] <= 1 ))
             DYB[ReturnSectorID(LatchAddr)] = LatchData[0];
        if ( UNLOCKBYPASS )
        begin
         CommandCurrentState = UBP;
          CurrentState       = CANNOTREAD;
        end
        else
        begin
         CommandCurrentState = INIT;
         CurrentState = READ_ASYNC + SYNC;
        end
    end
  endcase
  end
 endcase

     if ( IrregularSeq )
     begin
     IrregularSeq = 1'b0;
     if ( UNLOCKBYPASS )
     begin
          CommandCurrentState = UBP;
          CurrentState = CANNOTREAD;
     end
     else
     begin
          CommandCurrentState = INIT;
          CurrentState = READ_ASYNC + SYNC;
     end
     end

  end

    ////////////////////////////////////////////////////////////
   //                    READ CYCLES                         //
  ////////////////////////////////////////////////////////////

  always @(ReadNow)
  begin
            FROMCE = 1'b0;
            FROMOE = 1'b0;

            if ( SYNC )
               SWITCH = 1'b0;
            else
            begin
               SWITCH = 1'b1;
               CEDQ_t = CENeg_event + CEDQ_01;
               OEDQ_t = OENeg_event + OEDQ_01;
               if ( OEDQ_t >= CEDQ_t )
                  FROMOE = 1'b1;
               else //if ( CEDQ_t >= OEDQ_t )
                  FROMCE = 1'b1;
            end

     if ( SYNC )
     begin
          RdA    = LatchAddr;
          RdAm1  = LatchAddrLSB;
     end
     else
     begin
          RdA    = A;
          RdAm1  = Am1;
     end
     if  (~SYNC && ~( CurrentState == DUMMY || CurrentState == CANNOTREAD ))
         INDNeg_zd = 1'b1;

     if (~WORDNeg)
         DOut_zd[31:16] = Zzz;

     case ( CurrentState )
     CANNOTREAD :
     begin
     end

     READ_SYNC :
     begin
               LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                          BurstBorder,BurstCount,BurstDelay,BurstInd);
               -> SYNC_T;
     end

     READ_ASYNC :
     begin
               READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
     end

     CRVERIFY :
     begin
        if (( CRVerifySmallBank && ( ReturnBank(RdA) == SMALL ))
         || (~CRVerifySmallBank && ( ReturnBank(RdA) == LARGE)))
         // Right bank addressed
           if ( SYNC )
           begin
                SyncData = {16'b0,ConfReg};
                BurstDelay = ConfReg[13:10] + 2;
                -> SYNCSTATUS_T;
           end
           else
           begin
                if ( WORDNeg )
                     DOut_zd[31:16] = 0;
                DOut_zd[15:0] = ConfReg;
                -> DUMMY_T;
           end

        else // Bank not addressed and this READ should return memory data
           if (~SYNC)
                READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
           else
           begin
                LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                  BurstBorder,BurstCount,BurstDelay,BurstInd);
                -> SYNC_T;
           end
      end

     BITSTATUS :
     begin
         // RD(0) is corresponding bit
         if ( WORDNeg && ~SYNC && ~OENeg && ~CENeg && WENeg )
              DOut_zd[31:16] = 0;

         if (( RdA[5:0] == OW0 ) || ( RdA[5:0] == OW1 ))
         begin
            if ( SYNC )
            begin
                 SyncData = 0;
                 SyncData[0] = SecSiPB;
                 BurstDelay  = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
            end
            else
            begin
                DOut_zd[15:0] = 0;
                DOut_zd[0]    = SecSiPB;
            end
            SecSiPBSequence = 0;
         end
         else if (( RdA[5:0] == PL0 ) || ( RdA[5:0] == PL1 ))
         begin
            if ( SYNC )
            begin
                 SyncData = 0;
                 SyncData[0] = PasswordMODELock;
                 BurstDelay  = ConfReg[13:10]+2;
                 -> SYNCSTATUS_T;
            end
            else
            begin
                DOut_zd[15:0] = 0;
                DOut_zd[0]    = PasswordMODELock;
            end
            PPMLBSequence = 0;
         end
         else if (( RdA[5:0] == SL0 ) || ( RdA[5:0] == SL1 ))
         begin
            if ( SYNC )
            begin
                 SyncData = 0;
                 SyncData[0] = PersistentMODELock;
                 BurstDelay  = ConfReg[13:10]+2;
                 -> SYNCSTATUS_T;
            end
            else
            begin
                DOut_zd[15:0] = 0;
                DOut_zd[0] = PersistentMODELock;
            end
            SPMLBSequence = 0;
         end
         else DOut_zd[16:0] = Zzz;
         // status can be read issuing subsequent READ commands until READ/RESET
         if (~SYNC)
             -> DUMMY_T;

     end

     PPB_VERIFY :
     begin
         if ( (RdA[5:0]==WP0 || RdA[5:0]==WP1)
              && (ReturnGroupID(ReturnSectorID(RdA))==GroupID))
         begin
          if (~SYNC)
          begin
            DOut_zd[15:0] = 0;
            DOut_zd[0] = PPB[GroupID];
          end
          else
          begin
            SyncData = 0;
            SyncData[0] = PPB[GroupID];
            BurstDelay  = ConfReg[13:10] + 2;
            -> SYNCSTATUS_T;
          end
          PPBSequenceProg = 0;
         end
         if (~SYNC)
             -> DUMMY_T;
     end

     PPB_ALL_STATUS :
     begin
         if ((( RdA[5:0] == WP0 ) || (RdA[5:0] == WP1 ))
             && (ReturnSectorID(RdA)==SectorID))
         begin
          if (~SYNC)
          begin
            DOut_zd[15:0] = 0;
            if (!(|PPB))
                 DOut_zd[0] = 1'b0;
            else DOut_zd[0] = 1'b1;
          end
          else
          begin
            SyncData = 0;
            if (!(|PPB))
                 SyncData[0] = 1'b0;
            else SyncData[0] = 1'b1;
            BurstDelay = ConfReg[13:10] + 2;
            -> SYNCSTATUS_T;
          end
         PPBSequenceErase = 0;
         end
         if (~SYNC)
             -> DUMMY_T;
     end

     DYBPPBSTATUS :
     begin
     if ( ReturnBank(RdA) == BankDYBPPB )
     begin
        if (~SYNC )
        begin
         if ( WORDNeg )
             DOut_zd = 0;
         else
             DOut_zd[15:0] = 0;
         DOut_zd[1] = PPBLockBit;
         DOut_zd[0] = DYB[ReturnSectorID(RdA)];
        end
        else
        begin
         SyncData = 0;
         SyncData[1] = PPBLockBit;
         SyncData[0] = DYB[ReturnSectorID(RdA)];
         BurstDelay  = ConfReg[13:10] + 2;
         -> SYNCSTATUS_T;
        end
     end
     else
     begin
        if (~SYNC)
            READPROC(DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
        else
        begin
            LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                             BurstBorder,BurstCount,BurstDelay,BurstInd);
            -> SYNC_T;
        end
     end
     end

    ASEL :
     begin

    if (ReturnBank(RdA) == BankASEL )
    begin // Autoselect bank addressed
      if ( ASELID(RdA[7:0],RdAm1,WORDNeg))

        if (~SYNC)
        begin
         DOut_zd = 0;
         if (~WORDNeg) DOut_zd[31:16] = Zzz;
         DOut_zd[7:0] = ASEL_array[RdA[7:0]];
        end
        else
        begin
         SyncData = 0;
         SyncData[7:0] = ASEL_array[RdA[7:0]];
         BurstDelay = ConfReg[13:10] + 2;
         -> SYNCSTATUS_T;
        end
      else if (RdA[7:0]==2)
        begin
         // PPB status
         if (~SYNC)
         begin
          DOut_zd[15:0] = 0;
          DOut_zd[0]    = ~PPB[ReturnGroupID(ReturnSectorID(RdA))];
         end
         else
         begin
          SyncData = 0;
          SyncData[0] = ~PPB[ReturnGroupID(ReturnSectorID(RdA))];
          BurstDelay  =  ConfReg[13:10] + 2;
          -> SYNCSTATUS_T;
         end
         PPBSequenceProg = 0;
        end

    end
    else
    begin
     // Autoselected bank not addressed and this READ should return
     // Flash memory data if not program suspend or programming sector addressed

            if ( CommandCurrentState == PSP
              || CommandCurrentState == PSP_ASEL
              || CommandCurrentState == PSP_E
              || CommandCurrentState == PSP_E_ASEL)
                 ReadOK = ( ReturnSectorID(RdA) != SectorProg );
            else ReadOK = 1'b1;


            if ( ReadOK )
            begin
              if ((  CommandCurrentState == ESP
                 || CommandCurrentState == ESP_ASEL
                 || CommandCurrentState == PSP_E
                 || CommandCurrentState == PSP_E_ASEL)
                 && EraseSecFlag[ReturnSectorID(RdA)])
                 begin
                    StatusReg[7] = 1'b1;
                    StatusReg[5] = 1'b0;
                    if (~SYNC)
                      if (~WORDNeg)
                          DOut_zd[15:0] = StatusReg[15:0];
                      else
                          DOut_zd = StatusReg;
                    else
                    begin
                      SyncData = StatusReg;
                      BurstDelay = ConfReg[13:10] + 2;
                      -> SYNCSTATUS_T;
                    end
                    StatusReg[2] = ~StatusReg[2];
                 end
                 else
                    if (~SYNC)
                       READPROC(DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
                    else
                    begin
                       LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                       -> SYNC_T;
                    end
            end //ReadOK
     end

     if (~SYNC && ~ASELFlag ) -> DUMMY_T;

    end

    READ_CFI :
    begin
           CFIIndex = ReturnCFIIndex(WORDNeg,RdA,RdAm1);
           if ( CFIIndex != 8'h77 )
             if (~SYNC)
             begin
               if (WORDNeg)
                   DOut_zd[31:16] = 0;
               DOut_zd[15:0] = CFI_array[CFIIndex];
             end
             else
             begin
               SyncData = 0;
               SyncData[15:0] = CFI_array[CFIIndex];
               BurstDelay  = ConfReg[13:10] + 2;
               -> SYNCSTATUS_T;
             end
     end

     WRITESTATUS, WRITESTATUS_E :
     begin
          if ( ReturnBank(RdA) == BankProg)
          //Programming bank addressed, returns status
          begin
             StatusReg[5] = 1'b0;
             if (~SYNC)
             begin
                 if (~WORDNeg)
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;
                 // While Programming DQ7 returns complement of DQ7 last programmed
                //DOut_zd[7] = ~StatusReg[7];
                 DOut_zd[7] = ~DataProg[7];
                 if ( ReturnSectorID(RdA) != SectorProg )
                     DOut_zd[7] = StatusReg[7];
             end
             else
             begin
                 SyncData = StatusReg;
                 //SyncData[7] = ~StatusReg[7];
                 SyncData[7] = ~DataProg[7];
                 if (ReturnSectorID(RdA) != SectorProg)
                     SyncData[7] = StatusReg[7];
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
             end
             // DQ6 toggles until programming completed or suspended.
             StatusReg[6] = ~StatusReg[6];
             //  DQ2 toggles depending on addressed sector
             if (EraseSecFlag[ReturnSectorID(RdA)] && CommandCurrentState == PROGRAM_E )
                 StatusReg[2] = ~StatusReg[2];
           end

           else if ( EraseSecFlag[ReturnSectorID(RdA)] && CurrentState == WRITESTATUS_E )
           begin
              StatusReg[7] = 1'b0;
              StatusReg[5] = 1'b0;
              StatusReg[3] = 1'b1;
              if (~SYNC)
              begin
                 if (~WORDNeg)
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;

              end
              else
              begin
                 SyncData = StatusReg;
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
              end
              StatusReg[6] = ~StatusReg[6];
              StatusReg[2] = ~StatusReg[2];

           end
           else
           begin

             if (~SYNC)
                  READPROC(DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
             else
             begin
                  LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                  -> SYNC_T;
             end
           end
      end

      CESTATUS :
      begin
             StatusReg[7] = 1'b0;
             StatusReg[5] = 1'b0;
             StatusReg[3] = 1'b1;
             if ( ~SYNC )
                 if (~WORDNeg)
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;
             else
             begin
                 SyncData = StatusReg;
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
             end
             StatusReg[6] = ~StatusReg[6];
             StatusReg[2] = ~StatusReg[2];
      end

      SESTATUS :
      begin
          if (BusyBankE(RdA))
          begin
             // Data poll on DQ7 must be preformed on an address that belongs
             // to a sector being erased
             if ( EraseSecFlag[ReturnSectorID(RdA)] )
             begin
                 if ( CommandCurrentState != SETIMEOUT )
                     StatusReg[7] = 1'b0;
                 else
                     StatusReg[7] = 1'b1;
             end
             StatusReg[5] = 1'b0;
             if ( CommandCurrentState != SETIMEOUT )
                  StatusReg[3] = 1'b1;
             else StatusReg[3] = 1'b0;

             if (~SYNC)
                 if (~WORDNeg)
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;
             else
             begin
                 SyncData = StatusReg;
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
             end

             if ( CommandCurrentState != SETIMEOUT )
             begin
                if ( EraseSecFlag[ReturnSectorID(RdA)] )
                       StatusReg[2] = ~StatusReg[2];
                StatusReg[6] = ~StatusReg[6];
             end

          end
          else // other bank addressed and data returned

             if (~SYNC)
             begin
                  READPROC(DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
             end
             else
             begin
                  LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                  -> SYNC_T;
             end
      end

      NV_STATUS :
      begin
          // non-volatile bit programming in progress
          // small bank returns status, large returns flash data
          if ( ReturnBank(RdA) == SMALL )
          begin
             if (~SYNC)
                 if (~WORDNeg)
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;
             else
             begin
                 SyncData = StatusReg;
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
             end
             StatusReg[6] = ~StatusReg[6];
          end
          else

            if (~SYNC)
             begin
                  READPROC(DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
             end
             else
             begin
                  LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                  -> SYNC_T;
             end
     end

     READ_PSP, READ_PSP_E :
     begin
          // Read within sector not being programmed

          if ( SecSiENABLED && ReturnBank(RdA) == SMALL )

            if (~SYNC)
              READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
            else
            begin
              LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                BurstBorder,BurstCount,BurstDelay,BurstInd);
              -> SYNC_T;
            end
          else
          begin
            if (( ReturnSectorID(RdA) != SectorProg ) &&
                ~(( CurrentState == READ_PSP_E )&&(EraseSecFlag[ReturnSectorID(RdA)])))
                      ReadOK = 1'b1;
            else
            begin
                ReadOK = 1'b0;
                if ((CurrentState == READ_PSP_E)&&(EraseSecFlag[ReturnSectorID(RdA)]))
                begin
                  StatusReg[7] = 1'b1;
                  StatusReg[5] = 1'b0;
                  StatusReg[3] = 1'b1;
                  if (~SYNC)
                      if (~WORDNeg)
                           DOut_zd[15:0] = StatusReg[15:0];
                      else DOut_zd = StatusReg;
                  else
                  begin
                      SyncData = StatusReg;
                      BurstDelay = ConfReg[13:10] + 2;
                      -> SYNCSTATUS_T;
                  end
                  StatusReg[2] = ~StatusReg[2];
                end
             end

            if ( ReadOK )
                if (~SYNC)
                   READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
                else
                begin
                   LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                   -> SYNC_T;
                end

           end
      end

      READ_ESP :
      begin


          if (SecSiENABLED && ( ReturnBank(RdA) == SMALL ))
               if (~SYNC)
                   READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
               else
               begin
                   LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                   -> SYNC_T;
               end
          else
          begin
             // Sector not being erased
          if ( ~EraseSecFlag[ReturnSectorID(RdA)])

               if (~SYNC)
                  READPROC( DOut_zd, RdAm1,WORDNeg,SecSiENABLED,RdA);
               else
               begin
                  LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                    BurstBorder,BurstCount,BurstDelay,BurstInd);
                  -> SYNC_T;
               end
          else // sector being erased returns erase suspend status
          begin
              StatusReg[7] = 1'b1;
              StatusReg[5] = 1'b0;
              StatusReg[3] = 1'b1;
              if (~SYNC)
                 if (~WORDNeg )
                      DOut_zd[15:0] = StatusReg[15:0];
                 else DOut_zd = StatusReg;
              else
              begin
                 SyncData = StatusReg;
                 BurstDelay = ConfReg[13:10] + 2;
                 -> SYNCSTATUS_T;
              end
              StatusReg[2] = ~StatusReg[2];
          end
          end

      end

      PASS_PROGRAM_STATUS :
      begin
        // while programming password simultaneous operation disabled,status returned
        StatusReg[5] = 1'b0;
        if (~SYNC)
        begin
            if (~WORDNeg)
                 DOut_zd[15:0] = StatusReg[15:0];
            else DOut_zd = StatusReg;
            DOut_zd[7] = ~StatusReg[7];
        end
        else
        begin
           SyncData = StatusReg;
           SyncData[7] = ~StatusReg[7];
           BurstDelay  = ConfReg[13:10] + 2;
           -> SYNCSTATUS_T;
        end
        // DQ6 toggles until programming completed
        StatusReg[6] = ~StatusReg[6];
      end

      PASS_VERIFY :
      begin
      // returns password portion no matter BA
       if ( PasswordMODELock )
       // device returns inavlid data, password locked
          if (~SYNC)
          begin
             if (WORDNeg)
                DOut_zd[31:16] = MaxData;
             DOut_zd[15:0] = MaxData;
          end
          else
          begin
             SyncData[31:16] = MaxData;
             SyncData[15:0]  = MaxData;
          end
       else
       begin
          AddrConv = {RdA[0],RdAm1};
          if (~WORDNeg)
              if ( ~SYNC )
              begin
                   DOut_zd = {Zzz,Zzz};
                   DOut_zd[15:0]  = PasswordRegion[AddrConv];
              end
              else SyncData[15:0] = PasswordRegion[AddrConv];
          else
              if (~SYNC)
                   if (AddrConv < 2)
                        DOut_zd = {PasswordRegion[1],PasswordRegion[0]};
                   else DOut_zd = {PasswordRegion[3],PasswordRegion[2]};
              else if ( AddrConv < 2 )
                        SyncData = {PasswordRegion[1],PasswordRegion[0]};
                   else SyncData = {PasswordRegion[3],PasswordRegion[2]};
       end

       if ( SYNC )
       begin
            BurstDelay = ConfReg[13:10] + 2;
            -> SYNCSTATUS_T;
       end
    end

    PASS_UNLOCK_STATUS :
    begin
        if (ReturnBank(RdA) == SMALL )
        begin // small bank addressed,return status
            StatusReg[5] = 1'b0;
            if (~SYNC)
                if (~WORDNeg)
                     DOut_zd[15:0] = StatusReg[15:0];
                else DOut_zd = StatusReg;
            else
            begin
                SyncData = StatusReg;
                BurstDelay = ConfReg[13:10] + 2;
                -> SYNCSTATUS_T;
            end
            StatusReg[6] = ~StatusReg[6];
        end
        else // large bank addressed, return data
        // No need to check if SecSi enabled, 75% bank
            if ( ~SYNC )
                if (~WORDNeg)
                     DOut_zd[15:0] = Flash[{RdA,RdAm1}];
                else DOut_zd = {Flash[{RdA,1'b0}], Flash[{RdA,1'b1}]};
            else
            begin
                LINEARACCESS_INIT(WORDNeg,LatchAddr,LatchAddrLSB,ConfReg,
                                  BurstBorder,BurstCount,BurstDelay,BurstInd);
                -> SYNC_T;
            end
    end
  endcase
  end

    ////////////////////////////////////////////////////////////
   //                    Sync Mode READ                      //
  ////////////////////////////////////////////////////////////

 // Detection of CLK rising edges, burst mode, sync reads
  always @(CLK)
  begin

    if (CLK && SYNC)
     case ( CurrentState )

     READ_BURST :
     begin

       if ( BurstDelay > 0 )
          BurstDelay = BurstDelay - 1;
       if ( BurstDelay == 0 )
       begin

          ReadOK = ( ~OE_burst  && ~CENeg_gl && WENeg_gl);

          if ( ReadOK  )
          begin
           if ( WrapArround(ConfReg[8],WORDNeg,BurstCount,BurstInd,BurstBorder) )
              INDNeg_zd = 1'b0;
           else
              INDNeg_zd = 1'b1;
          end
          else
          begin
              if ( !(OE_burst && ~OENeg) )
              begin
                  INDNeg_zd = 1'bz;
                  if ( DOut_zd != {Zzz,Zzz} )
                      DOut_zd  = {Zzz,Zzz};
              end
          end


          if ( SecSiENABLED && ReturnSectorID(BurstAddr[BurstCount]/2)==SecSiSector)

             if ( Top(0) )
             begin
                  ReadData[31:16] = SecSiRegion[BurstAddr[BurstCount+1]%SecSiSize];
                  ReadData[15:0]  = SecSiRegion[BurstAddr[BurstCount]  %SecSiSize];
             end
             else
             begin
                  ReadData[31:16] = SecSiRegion[(BurstAddr[BurstCount+1]-20'hFF000)%SecSiSize];
                  ReadData[15:0]  = SecSiRegion[(BurstAddr[BurstCount]-20'hFF000)  %SecSiSize];
             end

          else
          begin
                  ReadData[31:16] = Flash[BurstAddr[BurstCount+1]];
                  ReadData[15:0]  = Flash[BurstAddr[BurstCount]];
          end

          if (~WORDNeg)
          begin
              if ( ReadOK )
                   DOut_zd[15:0] = ReadData[15:0];
              BurstCount = BurstCount + 1;
          end
          else
          begin
              if ( ReadOK )
                   DOut_zd = ReadData;
              BurstCount = BurstCount + 2;
          end
           if ( ~ReadOK ) DOut_temp = ReadData;

           if ( BurstCount == BurstBorder )
                BurstCount =  0;
       end // BurstDelay==0
     end // READ_BURST

     STATUS_SYNC :
     begin
       // sync READ operation, does not iterate like BURST MODE
       // same data returned after initial delay

       if ( BurstDelay > 0 )
            BurstDelay = BurstDelay - 1;

       if ( BurstDelay == 0 )
       begin
          ReadOK = ( ~OENeg_gl && ~CENeg_gl && WENeg_gl );

          if ( ~ReadOK && DOut_zd != {Zzz,Zzz} )
          begin
                 DOut_temp = DOut_zd;
                 DOut_zd = {Zzz,Zzz};

          end
          if ( ~WORDNeg )
          begin
              if ( ReadOK )
                DOut_zd[15:0] = SyncData[15:0];
          end
          else
              if ( ReadOK )
                DOut_zd = SyncData;
       end

     end
   endcase
 end

  // Detection of BURST Halt
 always @(ADVNeg)
 begin
    if ( CurrentState == READ_BURST || CurrentState == STATUS_SYNC )
      if ( ~ADVNeg )
      begin
        -> SYNCBACK_T;
        if ( CurrentState == READ_BURST )
             INDNeg_zd = 1'b1;
      end
 end
 always @(CENeg_gl)
 begin
    if ( CurrentState == READ_BURST || CurrentState == STATUS_SYNC )
      if ( CENeg_gl )
      begin
        -> SYNCBACK_T;
        INDNeg_zd = 1'bz;
      end
 end
 always @(OENeg_gl)
 begin
    // do not halt, outputs HiZ
    if ( CurrentState == READ_BURST || CurrentState == STATUS_SYNC )
      if ( OENeg_gl )
        INDNeg_zd <= 1'bz;
 end

    ////////////////////////////////////////////////////////////
   //                    3State Outputs                      //
  ////////////////////////////////////////////////////////////

  always @(posedge CENeg_gl or posedge OENeg_gl)
  begin
     if ( WENeg_gl )
     begin

      if ( DOut_zd[0] !== 1'bz )
           DOut_temp = DOut_zd;
      SWITCH = 1'b0;
      DOut_zd   = {Zzz,Zzz};
      INDNeg_zd = 1'bz;
     end
  end

  always @(RESET_D)
  begin
    if (~RESET_D)
    begin
     if ( DOut_zd[15:0] != Zzz ) DOut_temp = DOut_zd;
     DOut_zd   = {Zzz,Zzz};
     INDNeg_zd = 1'bz;
     SWITCH = 1'b0;
    end
  end

  // for sync mode only
  always @(OENeg_gl,CENeg_gl)
  begin
     if ( SYNC && RESET_D && WENeg_gl && ~OENeg_gl && ~CENeg_gl )
     begin
          DOut_zd[15:0] = DOut_temp[15:0];
          if ( WORDNeg )
          begin
               DOut_zd = DOut_temp;
               if(DOut_temp[31]===1'bz)
                  DOut_zd[31:16] = 0;
          end
          INDNeg_zd = 1'b1;
     end
  end

    ////////////////////////////////////////////////////////////
   //             State Tranistions, Internal                //
  ////////////////////////////////////////////////////////////

  always @(SYNC_T)
  begin
             if ( CurrentState == ASEL && ~ASELFlag )
                 UPDATESTATES(SecSiEE,ASELFlag,CommandCurrentState,CommandBack);
             else
               CommandBack       = CommandCurrentState;

             CurrentBack         = CurrentState;
             CurrentState        = READ_BURST;
 	     CommandCurrentState = DUMMY;

  end

  always @(SYNCSTATUS_T)
  begin

 	     if ( CurrentState == ASEL && ~ASELFlag )
                 UPDATESTATES(SecSiEE,ASELFlag,CommandCurrentState,CommandBack);
             else
                  CommandBack    <= CommandCurrentState;
             if ( CurrentState == BITSTATUS  || CurrentState == PPB_ALL_STATUS
               || CurrentState == PPB_VERIFY || CurrentState == DYBPPBSTATUS )
             begin
                CommandCurrentState <= RESET_OR_IGNORE;
                CommandBack         <= RESET_OR_IGNORE;
             end
             CurrentBack    = CurrentState;
             CurrentState   = STATUS_SYNC;
  end

  always @(SYNCBACK_T)
  begin
             CurrentState        = CurrentBack;
 	     CommandCurrentState = CommandBack;
  end

  always @(DUMMY_T)
  begin
             if ( CurrentState == ASEL && ~ASELFlag )

                 UPDATESTATES(SecSiEE,ASELFlag,CommandCurrentState,CommandBack);
             else
                  CommandCurrentState = RESET_OR_IGNORE;
  end

    ////////////////////////////////////////////////////////////
   //                  Embedded Algorithms                   //
  ////////////////////////////////////////////////////////////

  always @( CErase_in, NVProg_in, NVErs_in,
            WPProg_in, PErase_in,// PassWindow,
            ProgStart, ProgResume,//PassProgDone,
            SEStart, SEResume )
  begin
   if ( CErase_in     || NVProg_in  || NVErs_in    ||
        WPProg_in     || PErase_in  ||// ~PassWindow ||
        ProgStart  || ProgResume  ||//~PassProgDone ||
        SEStart       || SEResume   )
        RY_zd = 1'b0;
  end

  always @(ProgStart)
  begin
   if (ProgStart)
   begin
        EPAStart = $time;
        if (~WORDNeg)
             EPAInterval = tdevice_EPA16;
        else EPAInterval = tdevice_EPA32;
        -> ProgDoneE;
  end
 end

 always @(ProgSuspend)
 begin
    if ( ProgSuspend )
    begin
        EPAInterval = EPAInterval - ( $time  - EPAStart );
        disable ProgDoneP;
        ProgDone = 1'b0;
   end
 end

 always @(ProgResume)
 begin
    if (ProgResume)
    begin
        -> ProgDoneE;
        EPAStart = $time;
    end
 end

 always @(SEStart)
 begin
    if (SEStart)
    begin
        SEInterval = SETime;
        SECEStart  = $time;
        -> SEDoneE;
    end
 end

 always @(SESuspend)
 begin
     if ( SESuspend )
     begin
        SEInterval = SEInterval - ( $time - SECEStart);
        disable SEDoneP;
        SEDone     = 1'b0;
     end
 end

 always @(SEStartSuspend)
 begin
     if (SEStartSuspend)
         SEInterval = SETime;
 end

 always @(SEResume)
 begin
    if ( SEResume )
    begin

        SECEStart = $time;
        -> SEDoneE;
    end
 end

    ////////////////////////////////////////////////////////////
   //                  Timing Control                        //
  ////////////////////////////////////////////////////////////

  always @(PassProgDoneE)
  begin : PassProgDoneP
          PassProgDone = 1'b0;
          if ( PassWORD )
              #tdevice_EPA16 PassProgDone = 1'b1;
          else
              #tdevice_EPA32 PassProgDone = 1'b1;

  end
  always @(PassWindowE)
  begin : PassWindowP
          PassWindow   = 1'b0;
          UnlockPassOK = 1'b0;
          #tdevice_UNLOCK PassWindow <= 1'b1;
  end
  always @(ProgDoneE)
  begin : ProgDoneP
          ProgDone = 1'b0;
          #EPAInterval ProgDone = 1'b1;

  end
  always @(SEDoneE)
  begin : SEDoneP
          SEDone     = 1'b0;
          #SEInterval SEDone = 1'b1;
  end

    ////////////////////////////////////////////////////////////
   //                  Internal Delays                       //
  ////////////////////////////////////////////////////////////

   always @(posedge WPProg_in)
   begin:TWPProgr
     #tdevice_WPProg WPProg_out = WPProg_in;
   end
   always @(negedge WPProg_in)
   begin:TWPProgf
     #1 WPProg_out = WPProg_in;
   end

   always @(posedge PErase_in)
   begin:TPEraser
     #tdevice_PErase PErase_out = PErase_in;
   end
   always @(negedge PErase_in)
   begin:TPErasef
     #1 PErase_out = PErase_in;
   end

   always @(posedge SUS_in)
   begin:TSUSr
     #tdevice_SUSPEND SUS_out = SUS_in;
   end
   always @(negedge SUS_in)
   begin:TSUSf
     #1 SUS_out = SUS_in;
   end

   always @(posedge CErase_in)
   begin:TCEraser
   time dur;
     dur = 0;
     for(i=0;i<SecNum;i=i+1)
         if ( !(SecSiENABLED && i == SecSiSector) &&
         ~DYB[i] && ~PPB[ReturnGroupID(i)] &&
         (!(~WPNeg && (i==HWProtect1 || i==HWProtect2))))
             dur = dur + tdevice_SE;
     #dur CErase_out = CErase_in;
   end
   always @(negedge CErase_in)
   begin:TCErasef
     #1 CErase_out = CErase_in;
   end

   always @(posedge SAWindow_in)
   begin:TSAWindowr
     #tdevice_SAWIN SAWindow_out = SAWindow_in;
   end
   always @(negedge SAWindow_in)
   begin:TSAWindowf
     #1 SAWindow_out = SAWindow_in;
   end

   always @(posedge RESInterval_in)
   begin:TRESIntervalr
     #(tdevice_RESEMB-500) RESInterval_out = RESInterval_in;
   end
   always @(negedge RESInterval_in)
   begin:TRESIntervalf
     #1 RESInterval_out = RESInterval_in;
   end

   always @(posedge NVProg_in)
   begin:TNVProgr
     #tdevice_NVPROG NVProg_out = NVProg_in;
   end
   always @(negedge NVProg_in)
   begin:TNVProgf
     #1 NVProg_out = NVProg_in;
   end

   always @(posedge NVErs_in)
   begin:TNVErsr
     #tdevice_NVERS NVErs_out = NVErs_in;
   end
   always @(negedge NVErs_in)
   begin:TNVErsf
     #1 NVErs_out = NVErs_in;
   end

    ////////////////////////////////////////////////////////////
   //                      Functions                         //
  ////////////////////////////////////////////////////////////

  function [5:0] ReturnSectorID;
  input [HiAddrBit:0] ADDR;
  integer addrsel;
  begin
        addrsel = ADDR[18:11];
       //SIMaddrsel = ADDR[14:7];
       ReturnSectorID = 0;
       if ( addrsel <= 8'h07 )
               ReturnSectorID = addrsel;
       else if (( addrsel >= 8'h08 ) && ( addrsel <= 8'hF0 ))
               ReturnSectorID = 7 + ( addrsel / 8'h08 );
       else if ( addrsel >= 8'hF8 )
               ReturnSectorID = 30 + ( addrsel % 8'hF0 );

  end
  endfunction

  function [4:0] ReturnGroupID;
  input [5:0] conv;
  begin
    ReturnGroupID = 0;
    if ( conv <= 7 )
          ReturnGroupID = conv;
    else if (( conv >= 8 ) && ( conv <= 10 ))
          ReturnGroupID = 8;
    else if (( conv >= 11) && ( conv <= 34 ))
          ReturnGroupID = 9 + ( ( conv - 11 ) / 4 );
    else if (( conv >= 35 ) && ( conv <= 37 ))
          ReturnGroupID = 15;
    else if (( conv >= 38 ) && ( conv <= 45 ))
          ReturnGroupID = conv - 22;
  end
  endfunction

 function ReturnBank;
 input[HiAddrBit:0] ADDR;
 begin
    if ( Top(0) )
    ReturnBank = !(ADDR[18:17]==0);
    else
    ReturnBank = !(ADDR[18]==1'b1 && ADDR[17]==1'b1);
    //SIM (ADDR[14:13]==0);
 end
 endfunction

 function BusyBankE;
 input[HiAddrBit:0] ADDR;
 begin
    BusyBankE = (((ReturnBank(ADDR) == SMALL) && EraseBankSMALL) ||
            ((ReturnBank(ADDR) == LARGE) && EraseBankLARGE));
 end
 endfunction

 function[7:0] ReturnCFIIndex;
 input WORDNeg;
 input[HiAddrBit:0] A;
 input Am1;
 begin
   if (~((( A[7:0] >= 8'h10 ) && ( A[7:0] <= 8'h51 )) ||
            (( A[7:0] >= 8'h57 ) && ( A[7:0] <= 8'h5B )))
       || ( ~WORDNeg && Am1)
       )
          ReturnCFIIndex = 8'h77;
   else
          ReturnCFIIndex = A[7:0];
 end
 endfunction

 function ASELID;
 input[HiAddrBit:0] LatchAddr;
 input LatchAddrLSB;
 input WORDNeg;
 begin
   ASELID = (((LatchAddr[7:0] == 0 ) || (LatchAddr[7:0] == 1)
             || (LatchAddr[7:0] == 14 ) || (LatchAddr[7:0] == 15))
               && ( WORDNeg || ( ~WORDNeg && ~LatchAddrLSB)));

 end
 endfunction


 function CheckAllPPBs;
 input[GroupNum:0] PPB;
 begin
     CheckAllPPBs = ~(|PPB);
 end
 endfunction

function WrapArround;
input CR8;
input WORDNeg;
input[4:0] BurstCount;
input[4:0] BurstInd;
input[4:0] BurstBorder;
begin
   if ( ~CR8 )
     if ( BurstInd != 0 )
         WrapArround = ((BurstCount == BurstInd-1 && ~WORDNeg)
                                      ||
                       (BurstCount == BurstInd-2 && WORDNeg));

     else
        WrapArround  = ((BurstCount == BurstBorder-1 && ~WORDNeg)
                                      ||
                       (BurstCount == BurstBorder-2 && WORDNeg));

   else
     if (( BurstInd > 1 ) && ~WORDNeg
         || (( BurstInd > 2 ) && WORDNeg ))
        WrapArround =  ((BurstCount == BurstInd-2 && ~WORDNeg)
                                      ||
                       (BurstCount == BurstInd-4 && WORDNeg));
     else
        WrapArround = ((BurstCount == BurstBorder-2+BurstInd && ~WORDNeg)
                                      ||
                      (BurstCount == BurstBorder-4+BurstInd && WORDNeg));
end
endfunction

function Top;
input DummyInput;
begin
        //TOP OR BOTTOM arch model is used
    //assumptions:
    //1. TimingModel has format as
    //"am29bdd160gt
    //it is important that 12-th character from first one is "t" or "b"

    //2. TimingModel does not have more then 20 characters
    found = 1'b0;
    tmp_timing = TimingModel;//copy of TimingModel
    i = 19;
    while ((i >= 0) && (found != 1'b1))//search for first non null character
    begin                              //i keeps position of first non null character
        j = 7;
        while ((j >= 0) && (found != 1'b1))
        begin
            if (tmp_timing[i*8+j] != 1'd0)
                found = 1'b1;
            else
                j = j-1;
        end
        i = i - 1;
     end

     if (found)//if non null character is found
     begin
        for (j=0;j<=7;j=j+1)
         begin
        tmp_char[j] = TimingModel[(i-10)*8+j];//bottom/top character is 11
        end                                  //characters right from first ("A")
     end
     Top = (tmp_char == "T");
end
endfunction

    ////////////////////////////////////////////////////////////
   //                         Tasks                          //
  ////////////////////////////////////////////////////////////

 task BankE;
 input   SetBankVars;
 begin
        if ( SetBankVars )
        begin
            if ( ReturnBank(LatchAddr) == LARGE )
                EraseBankLARGE = 1'b1;
            else
                EraseBankSMALL = 1'b1;
        end
        else
        begin
            EraseBankLARGE = 1'b0;
            EraseBankSMALL = 1'b0;
        end
 end
 endtask

 task AddrBORDERS;
 inout  AddrLOW;
 inout  AddrHIGH;
 input   SectorID;
 integer AddrLOW;
 integer AddrHIGH;
 integer SectorID;
 begin

  if    (SectorID <= 7)
  begin
     AddrLOW  = SectorID*16'h01000;
     AddrHIGH = SectorID*16'h01000 + 16'h00FFF;
  end
  else if ((SectorID > 7) && (SectorID <= 37))
  begin
     AddrLOW  = (SectorID-7)*20'h08000;
     AddrHIGH = (SectorID-7)*20'h08000+16'h07FFF;
  end
  else
  begin
     AddrLOW  = 20'h0F8000 + (SectorID-38)*16'h01000;
     AddrHIGH = 20'h0F8000 + (SectorID-38)*16'h01000 + 16'h00FFF;
  end
 end
 endtask

 task LINEARACCESS_INIT;
 input WORDNeg;
 input [HiAddrBit:0] LatchAddr;
 input LatchAddrLSB;
 input [15:0] CONF;
 //inout BurstAddr;
 inout BurstBorder;
 inout BurstCount;
 inout BurstDelay;
 inout BurstInd;

 //integer BurstAddr[31:0];
 integer BurstBorder;
 integer BurstCount;
 integer BurstDelay;
 integer BurstInd;
 integer AddrIter;
 begin

   BurstDelay = ConfReg[13:10]+2;

   if (~WORDNeg)
       case ( CONF[2:0] )

       1:   begin
            // four words
            AddrIter    = {LatchAddr[HiAddrBit:1],2'b0};
            BurstCount  = {LatchAddr[0],LatchAddrLSB};
            BurstBorder = 4;
            end
       2:   begin
            // eight words
            AddrIter    = {LatchAddr[HiAddrBit:2],3'b0};

            BurstCount  = {LatchAddr[1],LatchAddr[0],LatchAddrLSB};
            BurstBorder = 8;
            end
       3:   begin
            // sixteen words
            AddrIter     = {LatchAddr[HiAddrBit:3],4'b0};
            BurstCount   = {LatchAddr[2:0],LatchAddrLSB};
            BurstBorder  = 16;
            end
       4:   begin
            // thirty two words
            AddrIter     = {LatchAddr[HiAddrBit:4],5'b0};
            BurstCount   = {LatchAddr[3:0],LatchAddrLSB};
            BurstBorder  = 32;
            end
       endcase

    else
       case ( CONF[2:0] )
       1:   begin
            // two dwords
            AddrIter    = {LatchAddr[HiAddrBit:1],2'b0};
            BurstCount  = {LatchAddr[0],1'b0};
            // 2dwords~4words
            BurstBorder = 4;
            end
       2:   begin
            // four dwords
            AddrIter    = {LatchAddr[HiAddrBit:2],3'b0};
            BurstCount  = {LatchAddr[1],LatchAddr[0],1'b0};
            //eight words
            BurstBorder = 8;
            end
       3:   begin
            // eight dwords
            AddrIter    = {LatchAddr[HiAddrBit:3],4'b0};
            BurstCount  = {LatchAddr[2:0],1'b0};
            // 16 words
            BurstBorder = 16;
            end
       endcase

    for(i=0;i<=BurstBorder-1;i=i+1)
    begin
       BurstAddr[i] = AddrIter;
       AddrIter = AddrIter + 1;
    end
    BurstInd = BurstCount;
 end
 endtask

 task READPROC;
 inout[31:0] DOut_zd;
 input Am1;
 input WORDNeg;
 input SecSiENABLED;
 input[18:0] A;
 integer ADDR;
 begin
        if ( WORDNeg )
             ADDR  = {A,1'b0};
        else ADDR  = {A,Am1};

        R1 = Flash[{A,1'b1}];
        R2 = Flash[{A,1'b0}];
        FlashData = {R1,R2};

        if (~WORDNeg)
        begin
          //SIM
          if ( SecSiENABLED && ReturnSectorID(A)==SecSiSector)
              if ( Top(0) )
                      DOut_zd[15:0] = SecSiRegion[ADDR%SecSiSize];
              else
                      DOut_zd[15:0] = SecSiRegion[(ADDR-20'hFF000)%SecSiSize];

          else
                 if (~Am1)
                     DOut_zd[15:0]  = FlashData[15:0];
                 else
                     DOut_zd[15:0] =  FlashData[31:16];

        end
        else
        begin
           //SIM
           if ( SecSiENABLED && ReturnSectorID(A)==SecSiSector)
              if ( Top(0) )
              begin
                  DOut_zd[31:16] = SecSiRegion[(ADDR+1)%SecSiSize];
                  DOut_zd[15:0]  = SecSiRegion[ADDR%SecSiSize];
              end
              else
              begin
                  DOut_zd[31:16] = SecSiRegion[(ADDR+1-20'hFF000)%SecSiSize];
                  DOut_zd[15:0]  = SecSiRegion[(ADDR-20'hFF000)%SecSiSize];
              end

           else
              DOut_zd = FlashData;
       end
 end
 endtask

 task UPDATESTATES;
 inout   SecSiEE;
 inout   ASELFlag;
 inout[4:0]   CommandCurrentState;
 inout[4:0]   CommandBack;
 integer SecSiEE;
 begin
        ASELFlag = 1'b1;
        SecSiEE  = 0;
        case ( CommandCurrentState )
        PSP     :  begin
                   CommandCurrentState = PSP_ASEL;
                   CommandBack         = PSP_ASEL;
                   end
        PSP_E   :  begin
                   CommandCurrentState = PSP_E_ASEL;
                   CommandBack         = PSP_E_ASEL;
                   end
        ESP     :  begin
                   CommandCurrentState = ESP_ASEL;
                   CommandBack         = ESP_ASEL;
                   end
        default :  begin
                   CommandCurrentState = RESET_OR_IGNORE;
                   CommandBack         = RESET_OR_IGNORE;
                   end
        endcase
 end
 endtask
////////////////////////////////////////////////////////////////////
//              Path Delay Fetch from SDF                        //
///////////////////////////////////////////////////////////////////
    reg  BuffInOE, BuffInCE;
    wire BuffOutOE, BuffOutCE;

    BUFFER    BUFOE   (BuffOutOE, BuffInOE);
    BUFFER    BUFCE   (BuffOutCE, BuffInCE);

    initial
    begin
        BuffInOE   = 1'b1;
        BuffInCE   = 1'b1;
    end

    always @(posedge BuffOutOE)
    begin
        OEDQ_01 = $time;
    end
    always @(posedge BuffOutCE)
    begin
        CEDQ_01 = $time;
    end
endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
    buf   ( OUT, IN);
endmodule
