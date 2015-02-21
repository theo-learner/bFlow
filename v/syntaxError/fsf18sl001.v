//////////////////////////////////////////////////////////////////////////////
//  File name : fsf18sl001.v
//////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2006 Flasys
//
//  MODIFICATION HISTORY :
//
//  version: |  author:    | mod date:  | changes made:
//    V1.0     S.Gmitrovic   05 Nov 14    Initial release
//    V1.1     S.Gmitrovic   05 Nov 17    Changed signal names as in datasheet
//    V1.2     S.Gmitrovic   05 Nov 23    Changed signals to bus style
//    V1.3     S.Gmitrovic   05 Dec 02    fixed access address latch for CE
//    V1.4     S.Gmitrovic   05 Dec 06    fixed addresslatching when
//                                        successive read from different pages
//    V1.5     S.Gmitrovic   06 Jan 12    changed model to ps, model does not
//                                        register 100 ps address bounce,
//                                        data hold for rising WEB CEB fixed
//    V1.6     A.Anic        06 Sep 04    Update according new datasheet:
//                                        times for program and erase changed,
//                                        hard and soft protect removed
//    V1.7     A.Anic        06 Sep 08    Fixed bug:
//                                        autoselect read changed
//////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:        Flasys
//  Technology:     Flash Memory
//  Part:           FSF18SL001
//
//  Description:    1Mbit (64k x 16 bit) Flash Memory
//
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                       //
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ps/1 ps

module fsf18sl001
(
    A        ,

    DQ       ,

    CEB      ,
    OEB      ,
    WEB      ,
    RESETB   ,
    BYTEB
);

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////

    input  [15:0] A     ;

    inout  [15:0] DQ    ;

    input  CEB    ;
    input  OEB    ;
    input  WEB    ;
    input  RESETB ;
    input  BYTEB  ;

// interconnect path delay signals
    wire [15:0] Aipd;
    wire [15:0] A_ipd;
    assign Aipd = A_ipd;
    wire [15:0] DQ_ipd;

    wire [15:0] DIn;
    assign DIn = DQ_ipd;

    wire [15:0] DOut;
    assign DOut = DQ;

    wire  CEB_ipd    ;
    wire  OEB_ipd    ;
    wire  WEB_ipd    ;
    wire  RESETB_ipd ;
    wire  BYTEB_ipd  ;

//  internal delays
    reg READY_in     ;
    reg READY        ; // Device ready after reset

    wire  DQ15_Pass  ;
    wire  DQ14_Pass  ;
    wire  DQ13_Pass  ;
    wire  DQ12_Pass  ;
    wire  DQ11_Pass  ;
    wire  DQ10_Pass  ;
    wire  DQ9_Pass   ;
    wire  DQ8_Pass   ;
    wire  DQ7_Pass   ;
    wire  DQ6_Pass   ;
    wire  DQ5_Pass   ;
    wire  DQ4_Pass   ;
    wire  DQ3_Pass   ;
    wire  DQ2_Pass   ;
    wire  DQ1_Pass   ;
    wire  DQ0_Pass   ;

    reg [15 : 0] DOut_zd;
    reg [15 : 0] DOut_Pass;
    assign {DQ15_Pass,
            DQ14_Pass,
            DQ13_Pass,
            DQ12_Pass,
            DQ11_Pass,
            DQ10_Pass,
            DQ9_Pass,
            DQ8_Pass,
            DQ7_Pass,
            DQ6_Pass,
            DQ5_Pass,
            DQ4_Pass,
            DQ3_Pass,
            DQ2_Pass,
            DQ1_Pass,
            DQ0_Pass  } = DOut_Pass;

    parameter UserPreload     = 1'b0;
    parameter mem_file_name   = "none";//"fsf18sl001.mem";
    parameter otp_file_name   = "none";//"fsf18sl001_otp.mem";

    parameter TimingModel = "DefaultTimingModel";//"FSF18SL001-FC";

    parameter PartID = "FSF18SL001";
    parameter MaxData = 255; //FF
    parameter PageSize = 2047;  //7FF bytes
    parameter OTPSize = 63; //64 bytes(32 words)
    parameter PageNum = 63;
    parameter HiAddrBit = 15;
    parameter MemSize   = (PageNum + 1)*(PageSize + 1)-1;

    // powerup
    reg PoweredUp;

    //FSM control signals
    reg OTP_ACT  ; ////OTP access
    reg PSTART   ; ////Start Programming
    reg PDONE    ; ////Prog. Done
    reg AS_Exit  ; ///exit autoselect, security read, Soft protect
    reg AS_Ent   ; ///OTP read enter time 100 ns
    //Program location is in protected sector
    reg PERR     ;

    reg EDONE    ; ////Ers. Done
    reg ESTART   ; ////Start Erase
    //All pages selected for erasure are protected
    reg EERR     ;
    //Pages selected for erasure
    reg [PageNum:0] Ers_queue; // = PageNum'b0;

    //Command Register
    reg write ;
    reg read  ;

    //Sector Address
    integer PageAddr= 0;         // 0 - PageNum
    integer PA      = 0;         // 0 TO PageNum
    integer Address = 0;

    integer Addr ;

    //glitch protection
    wire gWE_n ;
    wire gCE_n ;
    wire gOE_n ;

    reg RST ;
    reg reseted ;
    //Sector Protection Status
    reg SEC_LOCK;
    integer OTP_GROUP;
    reg [3:0] OTP_Prot;

    // timing check violation
    reg Viol = 1'b0;

    integer Mem[0:MemSize];
    integer OTP[0:OTPSize];

    integer WBData[0:1];
    integer WBAddr[0:1];

    //Status reg.
    reg[7:0] Status = 8'b0;
    reg[7:0] dummyreadsts = 8'b0;
    reg readpolling; //for dummy reads

    reg[7:0]  old_bit, new_bit;
    integer old_int, new_int;
    integer wr_cnt;

    reg[7:0] temp;

    reg oe = 1'b0;
    event oe_event;
    event Address_event;
    reg add_lt;

    //TPD_XX_DATA
    time OEDQ_t;
    time CEDQ_t;
    time ADDRDQ_t;
    time OEB_event;
    time CEB_event;
    time ADDR_event;
    time ADDR_event2;
    reg FROMOE;
    reg FROMCE;
    reg FROMBYTE;
    reg FROMADDR;
    reg BuffInCE = 1'b0;
    reg BuffInOE = 1'b0;
    reg BuffInADDR = 1'b0;

    integer   OEDQ_01;
    integer   CEDQ_01;
    integer   ADDRDQ;
    reg[15:0] TempData;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////
    buf   (A_ipd[15], A[15]);
    buf   (A_ipd[14], A[14]);
    buf   (A_ipd[13], A[13]);
    buf   (A_ipd[12], A[12]);
    buf   (A_ipd[11], A[11]);
    buf   (A_ipd[10], A[10]);
    buf   (A_ipd[9], A[9]);
    buf   (A_ipd[8], A[8]);
    buf   (A_ipd[7], A[7]);
    buf   (A_ipd[6], A[6]);
    buf   (A_ipd[5], A[5]);
    buf   (A_ipd[4], A[4]);
    buf   (A_ipd[3], A[3]);
    buf   (A_ipd[2], A[2]);
    buf   (A_ipd[1], A[1]);
    buf   (A_ipd[0], A[0]);

    buf   (DQ_ipd[15], DQ[15]);
    buf   (DQ_ipd[14], DQ[14]);
    buf   (DQ_ipd[13], DQ[13]);
    buf   (DQ_ipd[12], DQ[12]);
    buf   (DQ_ipd[11], DQ[11]);
    buf   (DQ_ipd[10], DQ[10]);
    buf   (DQ_ipd[9] , DQ[9] );
    buf   (DQ_ipd[8] , DQ[8] );
    buf   (DQ_ipd[7] , DQ[7] );
    buf   (DQ_ipd[6] , DQ[6] );
    buf   (DQ_ipd[5] , DQ[5] );
    buf   (DQ_ipd[4] , DQ[4] );
    buf   (DQ_ipd[3] , DQ[3] );
    buf   (DQ_ipd[2] , DQ[2] );
    buf   (DQ_ipd[1] , DQ[1] );
    buf   (DQ_ipd[0] , DQ[0] );

    buf   (CEB_ipd    , CEB    );
    buf   (OEB_ipd    , OEB    );
    buf   (WEB_ipd    , WEB    );
    buf   (RESETB_ipd , RESETB );
    buf   (BYTEB_ipd  , BYTEB  );

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (DQ[15],   DQ15_Pass , 1);
    nmos   (DQ[14],   DQ14_Pass , 1);
    nmos   (DQ[13],   DQ13_Pass , 1);
    nmos   (DQ[12],   DQ12_Pass , 1);
    nmos   (DQ[11],   DQ11_Pass , 1);
    nmos   (DQ[10],   DQ10_Pass , 1);
    nmos   (DQ[9] ,   DQ9_Pass  , 1);
    nmos   (DQ[8] ,   DQ8_Pass  , 1);
    nmos   (DQ[7] ,   DQ7_Pass  , 1);
    nmos   (DQ[6] ,   DQ6_Pass  , 1);
    nmos   (DQ[5] ,   DQ5_Pass  , 1);
    nmos   (DQ[4] ,   DQ4_Pass  , 1);
    nmos   (DQ[3] ,   DQ3_Pass  , 1);
    nmos   (DQ[2] ,   DQ2_Pass  , 1);
    nmos   (DQ[1] ,   DQ1_Pass  , 1);
    nmos   (DQ[0] ,   DQ0_Pass  , 1);

    wire deg;

    //Check Enable Equivalents

    // Address setup/hold near WE# falling edge
    wire CheckEnable_A0_WE;
    assign CheckEnable_A0_WE = ~CEB && OEB;
    // Data setup/hold near WE# rising edge
    wire CheckEnable_DQ0_WE;
    assign CheckEnable_DQ0_WE = ~CEB && OEB && deg;
    // Address setup/hold near CE# falling edge
    wire CheckEnable_A0_CE;
    assign CheckEnable_A0_CE = ~WEB && OEB;
    // Data setup/hold near CE# rising edge
    wire CheckEnable_DQ0_CE;
    assign CheckEnable_DQ0_CE = ~WEB && OEB && deg;
    //WE# hold near OE# during read
    wire ReadProgress;
    assign ReadProgress = (( PDONE == 1 ) || ( EDONE == 1 ));
    //WE# hold near OE# during embd algs.
    wire EmbdProgress;
    assign EmbdProgress = (( PDONE == 0 ) || ( EDONE == 0 ));
    wire CERST;
    assign CERST =((CEB===1'b1) && (RST===1'b0));
    wire OERST;
    assign OERST =((OEB===1'b1) && (RST===1'b0));
    wire WERST;
    assign WERST =((WEB===1'b1) && (RST===1'b0));

 specify

        // tipd delays: interconnect path delays , mapped to input port delays.
        // In Verilog is not necessary to declare any tipd_ delay variables,
        // they can be taken from SDF file
        // With all the other delays real delays would be taken from SDF file

                        // tpd delays
    specparam           tpd_A0_DQ0            =1;
    specparam           tpd_CEB_DQ0           =1;
                      //(tCE,tCE,tCHZ,-,tCHZ,-)
    specparam           tpd_OEB_DQ0           =1;
                      //(tOE,tOE,tOHZ,-,tOHZ,-)
    specparam           tpd_RESETB_DQ0        =1;
                      //(-,-,0,-,0,-)
    specparam           tpd_BYTEB_DQ0         =1;
                      //(-,-,tBLQZ, tBHQV)

                        // tsetup values: setup time
    specparam           tsetup_A0_WEB         =1;   //tAS edge \
    specparam           tsetup_DQ0_WEB        =1;   //tDS edge /

                         // thold values: hold times
    specparam           thold_CEB_RESETB      =1; //tRH  edge /
    specparam           thold_A0_WEB          =1; //tAH  edge \
    specparam           thold_DQ0_CEB         =1; //tDH edge /
    specparam           thold_OEB_WEB         =1; //tOEH edge /
    specparam           thold_BYTEB_CEB       =1; //tCLBL, tCLBH
    specparam           thold_BYTEB_WEB       =1; //tBH

                        // tpw values: pulse width
    specparam           tpw_RESETB_negedge    =1; //tRP
    specparam           tpw_WEB_negedge       =1; //tWP
    specparam           tpw_WEB_posedge       =1; //tWPH
    specparam           tpw_CEB_negedge       =1; //tCP
    specparam           tpw_CEB_posedge       =1; //tCEPH
    specparam           tpw_A0_negedge        =1; //tRC
    specparam           tpw_A0_posedge        =1; //tRC
                        //period values
    specparam           tperiod_WEB_posedge   = 1; //tWC
    specparam           tperiod_CEB_posedge   = 1; //tR0C

                        // tdevice values: values for internal delays
           //Byte Program Operation  tBPGM
    specparam   tdevice_POB                     = 25000000; // 25 us TYP;
           //Program Operation WORD
    specparam   tdevice_POW                     = 25000000; // 25 us TYP;
           //Page Erase Operation    tPER
    specparam   tdevice_SEO                     = 10000000; // 10 ms TYP;
            //Chip Erase Time    tCER
    specparam   tdevice_CEO                     = 40000000; // 40 ms TYP;
           //Timing Limit Exceeded
    specparam   tdevice_HANG                    = 400000000; //400 ms;
           //device ready after Hardware reset(during embeded algorithm)
    specparam   tdevice_READY                   = 100050000; //tReady
                                                         //tRH + TRP
           //Internal information access and exit time
    specparam   tdevice_INTEXIT                 = 100000; //100 ns max
    //specparam   tdevice_INTEXIT                 = 90; //100 ns typ
    //specparam   tdevice_INTEXIT                 = 80; //100 ns min
///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////

    if (FROMCE) (CEB *> DQ) = tpd_CEB_DQ0;
    if (FROMOE) (OEB *> DQ) = tpd_OEB_DQ0;
    if (~RESETB) (RESETB *> DQ) = tpd_RESETB_DQ0;
    if (FROMADDR) (A *> DQ) = tpd_A0_DQ0;

    if (~BYTEB && FROMADDR)( DQ[15] => DQ[0] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[1] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[2] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[3] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[4] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[5] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[6] ) = tpd_A0_DQ0;
    if (~BYTEB && FROMADDR)( DQ[15] => DQ[7] ) = tpd_A0_DQ0;

    if (BYTEB)( BYTEB => DQ[0] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[1] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[2] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[3] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[4] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[5] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[6] ) = tpd_BYTEB_DQ0;
    if (BYTEB)( BYTEB => DQ[7] ) = tpd_BYTEB_DQ0;

        ( BYTEB => DQ[8] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[9] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[10] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[11] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[12] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[13] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[14] ) = tpd_BYTEB_DQ0;
        ( BYTEB => DQ[15] ) = tpd_BYTEB_DQ0;

////////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                           //
////////////////////////////////////////////////////////////////////////////////
    $setup ( A , negedge CEB &&& CheckEnable_A0_CE, tsetup_A0_WEB, Viol);
    $setup ( A , negedge WEB &&& CheckEnable_A0_WE, tsetup_A0_WEB, Viol);
    $setup ( DQ , posedge CEB &&& CheckEnable_DQ0_CE, tsetup_DQ0_WEB, Viol);
    $setup ( DQ , posedge WEB &&& CheckEnable_DQ0_WE, tsetup_DQ0_WEB, Viol);

    $hold ( posedge RESETB &&& CERST, negedge CEB , thold_CEB_RESETB, Viol);
    $hold ( posedge RESETB &&& OERST, negedge OEB , thold_CEB_RESETB, Viol);
    $hold ( posedge RESETB &&& WERST, negedge WEB , thold_CEB_RESETB, Viol);
    $hold ( posedge WEB, negedge OEB &&& EmbdProgress, thold_OEB_WEB, Viol);
    $hold ( posedge CEB, negedge OEB &&& EmbdProgress, thold_OEB_WEB, Viol);
    $hold ( negedge CEB, BYTEB, thold_BYTEB_CEB, Viol);
    $hold ( negedge WEB, BYTEB, thold_BYTEB_WEB, Viol);
    $hold ( negedge CEB &&& CheckEnable_A0_CE, A , thold_A0_WEB, Viol);
    $hold ( negedge WEB &&& CheckEnable_A0_WE, A , thold_A0_WEB, Viol);
    $hold ( posedge WEB &&& CheckEnable_DQ0_WE, DQ , thold_DQ0_CEB, Viol);
    $hold ( posedge CEB &&& CheckEnable_DQ0_CE, DQ ,  thold_DQ0_CEB, Viol);

    $width (negedge RESETB, tpw_RESETB_negedge);
    $width (posedge WEB&&&(CEB===0), tpw_WEB_posedge);
    $width (negedge WEB&&&(CEB===0), tpw_WEB_negedge);
    $width (posedge CEB, tpw_CEB_posedge);
    $width (negedge CEB, tpw_CEB_negedge);
    $width (negedge A, tpw_A0_negedge);
    $width (posedge A, tpw_A0_posedge);

    $period(posedge WEB, tperiod_WEB_posedge);
    $period(posedge CEB &&& EmbdProgress, tperiod_CEB_posedge);

    endspecify

////////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                        //
////////////////////////////////////////////////////////////////////////////////

// FSM states
    parameter RESET           =6'd0;
    parameter Z001            =6'd1;
    parameter PREL_SETBWB     =6'd2;
    parameter C8              =6'd3;
    parameter C8_Z001         =6'd4;
    parameter C8_PREL         =6'd5;
    parameter ERS             =6'd6;
    parameter SERS_EXEC       =6'd7;
    parameter AS              =6'd15;
    parameter AS_EXIT_01      =6'd16;
    parameter AS_EXIT_02      =6'd17;
    parameter A0SEEN          =6'd18;
    parameter PGMS            =6'd19;
    parameter OTP_READ        =6'd20;
    parameter OTP_EXIT_01     =6'd21;
    parameter OTP_EXIT_02     =6'd22;
    parameter OTP_WRITE       =6'd23;

    reg [5:0] current_state;
    reg [5:0] next_state;

    reg deq;

    always @(DIn, DOut)
    begin
        if (DIn==DOut)
            deq=1'b1;
        else
            deq=1'b0;
    end
    // chech when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    integer i,j;

    initial
    begin
    // initialize memory and load preoload files if any

        for (i=0;i<(PageSize+1)*(PageNum+1);i=i+1)
            Mem[i]=MaxData;
        for (i=0;i<=OTPSize;i=i+1)
            OTP[i]=MaxData;
        for (i=0;i<=3;i=i+1)
            OTP_Prot[i] = 1'b0;
        for (i=0;i<=PageNum;i=i+1)
        begin
            Ers_queue[i] = 1'b0;
        end

        if (UserPreload)
        begin
            // OTP Region preload
            // fsf18sl001_otp memory file
            //   //       - comment
            //   @aa     - <aa> stands for address within last defined sector
            //   dd      - <dd> is byte to be written at OTP(aa++)
            //  (aa is incremented at every load)
            if (otp_file_name != "none") $readmemh(otp_file_name,OTP);
            // Memory Preload
            // fsf18sl001.mem, memory preload file
            //  @aaaaa  - <aaaaa> stands for address within last defined sector
            //  dd      - <dd> is byte to be written at Mem(nn)(aaaa++)
            // (aaaa is incremented at every load)
            if (mem_file_name != "none") $readmemh(mem_file_name,Mem);
        end

        for (i=0;i<=1;i=i+1)
        begin
            WBData[i] = 0;
            WBAddr[i] = -1;
        end
    end

    //Power Up time 110 us;
    initial
    begin
        PoweredUp = 1'b0;
        #110000000 PoweredUp = 1'b1;   //tWDHPH + TRH
    end

    always @(RESETB)
    begin
        RST <= #49999 RESETB;
    end

    initial
    begin
        write    = 1'b0;
        read     = 1'b0;
        Addr     = 0;
        OTP_ACT  = 1'b0;
        PSTART   = 1'b0;
        PDONE    = 1'b1;
        PERR     = 1'b0;
        EDONE    = 1'b1;
        AS_Exit  = 1'b1;
        ESTART   = 1'b0;
        EERR     = 1'b0;
        READY_in = 1'b0;
        READY    = 1'b0;
        readpolling = 1'b1;
    end

    always @(posedge READY_in)
    begin:TREADYr
        #tdevice_READY READY = READY_in;
    end

    always @(negedge READY_in)
    begin:TREADYf
        #1 READY = READY_in;
    end

    ////////////////////////////////////////////////////////////////////////////
    ////     obtain 'LAST_EVENT information
    ////////////////////////////////////////////////////////////////////////////

    always @(negedge OEB)
    begin
        OEB_event = $time;
    end

    always @(negedge CEB)
    begin
        CEB_event = $time;
    end

    always @(Aipd)
    begin
        ADDR_event2 = $time;
    end

    always @(DIn[15])
    begin
        if (~BYTEB)
            ADDR_event2 = $time;
    end

    always @(posedge add_lt)
    begin
        ADDR_event = ADDR_event2;
    end

    ////////////////////////////////////////////////////////////////////////////
    //// sequential process for reset control and FSM state transition
    ////////////////////////////////////////////////////////////////////////////

    reg R;
    reg E;
    always @(RESETB)
    begin
        if (PoweredUp)
        begin
        //Hardware reset timing control
            if (~RESETB)   // if (RESETB)
            begin
                E = 1'b0;
                if (~PDONE || ~EDONE)
                begin
                    //if program or erase in progress
                    READY_in = 1'b1;
                    R = 1'b1;
                end
                else
                begin
                    READY_in = 1'b0;
                    R = 1'b0;         //prog or erase not in progress
                end
            end
            else if (RESETB && RST)
            begin
                //RESET# pulse < tRP
                READY_in = 1'b0;
                R = 1'b0;
                E = 1'b1;
            end
         end
    end

    always @(next_state or RESETB or CEB or RST or
        READY  or PoweredUp)   //or PDONE or  EDONE
    begin: StateTransition
        if (PoweredUp)
        begin
            if (RESETB && (~R || (R && READY)))
            begin
                current_state = next_state;
                READY_in = 1'b0;
                E = 1'b0;
                R = 1'b0;
                reseted = 1'b1;
            end
            else if ((~R && ~RESETB && ~RST) ||
                (R && ~RESETB && ~RST && ~READY) ||
                (R && RESETB && ~RST && ~READY))
            begin
                current_state = RESET;
                reseted       = 1'b0;
            end
        end
        else
        begin
            current_state = RESET;
            reseted       = 1'b0;
            E = 1'b0;
            R = 1'b0;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    //Glitch Protection: Inertial Delay does not propagate pulses <5ns
    ///////////////////////////////////////////////////////////////////////////
    assign #5000 gWE_n = WEB_ipd;
    assign #5000 gCE_n = CEB_ipd;
    assign #5000 gOE_n = OEB_ipd;

    //latch address on rising edge and data on falling edge  of write
    always @(gWE_n or gCE_n or gOE_n or RESETB)
    begin: write_dc
        if (RESETB!=1'b0)
        begin
            if (~gWE_n && ~gCE_n && gOE_n)
                write = 1'b1;
            else
                write = 1'b0;
        end
        if (gWE_n && ~gCE_n && ~gOE_n)
            read = 1'b1;
        else
            read = 1'b0;
    end

    ///////////////////////////////////////////////////////////////////////////
    //Process that reports warning when changes on signals WE#, CE#, OE# are
    //discarded
    ///////////////////////////////////////////////////////////////////////////
    always @(WEB)
    begin: PulseWatch1
        if (gWE_n == WEB) $display("Glitch on WE#");
    end
    always @(CEB)
    begin: PulseWatch
        if (gCE_n == CEB) $display("Glitch on CE#");
    end
    always @(OEB)
    begin: PulseWatch3
        if (gOE_n == OEB) $display("Glitch on OE#");
    end

    ///////////////////////////////////////////////////////////////////////////
    //Latch address on falling edge of WE# or CE# what ever comes later
    //Latches data on rising edge of WE# or CE# what ever comes first
    // also Write cycle decode
    ///////////////////////////////////////////////////////////////////////////
    integer A_tmp, A_tmp1;
    integer SA_tmp;
    reg [HiAddrBit:0] tmp;

   always @(WEB_ipd)
    begin
        if (reseted)
        begin
            if (~WEB_ipd && ~CEB_ipd && OEB_ipd )
            begin
                SA_tmp =  Aipd[HiAddrBit:10];
                tmp = Aipd;
                if (~BYTEB)
                begin
                    A_tmp1 = { Aipd[9:0],DIn[15] };
                    A_tmp = { Aipd[14:0],DIn[15] };
                end
                else
                begin
                    A_tmp1 = { Aipd[9:0],1'b0};
                    A_tmp = Aipd[14:0];
                end
            end
        end
    end

   always @(CEB_ipd)
    begin
        if (reseted)
        begin
            if (~CEB_ipd && (WEB_ipd != OEB_ipd) )
            begin
                SA_tmp =  Aipd[HiAddrBit:10];
                tmp = Aipd;
                if (~BYTEB)
                begin
                    A_tmp1 = { Aipd[9:0],DIn[15] };
                    A_tmp = { Aipd[14:0],DIn[15] };
                end
                else
                begin
                    A_tmp1 = { Aipd[9:0],1'b0};
                    A_tmp = Aipd[14:0];
                end
                PageAddr = SA_tmp;
                Address = A_tmp1;
                Addr   = A_tmp;
                OTP_GROUP = Aipd[4:3];
                SEC_LOCK = Aipd[5];
            end
        end
    end

    always @(negedge OEB_ipd)
    begin
        if (reseted)
        begin
            if (~OEB_ipd && WEB_ipd && ~CEB_ipd)
            begin
                SA_tmp =  Aipd[HiAddrBit:10];
                if (~BYTEB)
                begin
                    A_tmp1 = { Aipd[9:0],DIn[15] };
                    A_tmp = { Aipd[14:0],DIn[15] };
                end
                else
                begin
                    A_tmp1 = { Aipd[9:0],1'b0};
                    A_tmp = Aipd[14:0];
                end
                PageAddr = SA_tmp;
                Address = A_tmp1;
                Addr   = A_tmp;
                OTP_GROUP = Aipd[4:3];
                SEC_LOCK = Aipd[5];
            end
        end
    end

    always @(Aipd or BYTEB)
    begin
        if (reseted)
        begin
            if (WEB_ipd && ~CEB_ipd && ~OEB_ipd)
            begin
                SA_tmp =  Aipd[HiAddrBit:10];
                if (~BYTEB)
                begin
                    A_tmp1 = { Aipd[9:0],DIn[15] };
                    A_tmp = { Aipd[14:0],DIn[15] };
                end
                else
                begin
                    A_tmp1 = { Aipd[9:0],1'b0};
                    A_tmp = Aipd[14:0];
                end
                PageAddr = SA_tmp;
                Address = A_tmp1;
                Addr   = A_tmp;
                OTP_GROUP = Aipd[4:3];
                SEC_LOCK = Aipd[5];
            end
        end
    end

    always @(DIn)
    begin
        if (reseted)
        begin
            if (~BYTEB && WEB_ipd && ~CEB_ipd && ~OEB_ipd)
            begin
                SA_tmp =  Aipd[HiAddrBit:10];
                A_tmp1 = { Aipd[9:0],DIn[15] };
                A_tmp  = { Aipd[14:0],DIn[15] };
                PageAddr = SA_tmp;
                Address = A_tmp1;
                Addr   = A_tmp;
                OTP_GROUP = Aipd[4:3];
                SEC_LOCK = Aipd[5];
            end
        end
    end

    always @(posedge write)
    begin
       PageAddr = SA_tmp;
       Address = A_tmp1;
       Addr   = A_tmp;
       OTP_GROUP = tmp[4:3];
       SEC_LOCK = tmp[5];
    end

    ///////////////////////////////////////////////////////////////////////////
    // Timing control for the Program Operations
    ///////////////////////////////////////////////////////////////////////////

    time duration_write;
    event pdone_event;

    always @(posedge reseted)
    begin
        PDONE = 1'b1;
    end

    always @(reseted or PSTART)
    begin
        if (reseted)
        begin
            if (PSTART && PDONE)
            begin
                if ((~OTP_ACT) || ( ~OTP_Prot[OTP_GROUP] && OTP_ACT ))
                begin
                    if (BYTEB)
                        duration_write = tdevice_POW - 5000;
                    else
                        duration_write = tdevice_POB - 5000;
                    PDONE = 1'b0;
                    ->pdone_event;
                end
                else
                begin
                    PERR = 1'b1;
                    PERR <= #995000 1'b0;
                end
            end
        end
    end

    always @(pdone_event)
    begin: pdone_process
        PDONE = 1'b0;
        readpolling = 1'b0;
        #duration_write PDONE = 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////
    // Timing control for the Erase Operations
    ///////////////////////////////////////////////////////////////////////////
    integer cnt_erase = 0;
    time duration_erase;
    event edone_event;

    always @(posedge reseted)
    begin
        disable edone_process;
        EDONE = 1'b1;
    end

    always @(reseted or ESTART)
    begin: erase
    integer i;
        if (reseted)
        begin
            if (ESTART && EDONE)
            begin
                cnt_erase = 0;
                for (i=0;i<=PageNum;i=i+1)
                begin
                    if (Ers_queue[i]==1'b1)
                        cnt_erase = cnt_erase + 1;
                end
                if (cnt_erase>0)
                begin
                    if (next_state == SERS_EXEC)
                        duration_erase = tdevice_SEO*1000 - 5000;
                    else if (next_state == ERS)
                        duration_erase = tdevice_CEO*1000 - 5000;
                    ->edone_event;
                end
                else
                begin
                    EERR = 1'b1;
                    EERR <= #99995000  1'b0;
                end
            end
        end
    end

    always @(edone_event)
    begin : edone_process
        EDONE = 1'b0;
        readpolling = 1'b0;
        #duration_erase EDONE = 1'b1;

    end

    ///////////////////////////////////////////////////////////////////////////
    // Main Behavior Process
    // combinational process for next state generation
    ///////////////////////////////////////////////////////////////////////////
    reg PATTERN_1  = 1'b0;
    reg PATTERN_2  = 1'b0;
    reg A_PAT_1  = 1'b0;

    integer DataHi; //DATA  High Byte
    integer DataLo; //DATA Low Byte
    reg [15:0] Data_tmp; //temp latch

    always @(posedge WEB or posedge CEB)
    begin
        Data_tmp = DIn;
    end

    always @(negedge write)
    begin
        DataLo = Data_tmp[7:0];
        if (BYTEB)
        begin
            DataHi = Data_tmp[15:8];
            PATTERN_1 = (Addr==16'h5555) && (DataLo==8'hAA) &&
                        (Data_tmp[15:8]==8'h00);
            PATTERN_2 = (Addr==16'h2AAA) && (DataLo==8'h55) &&
                        (Data_tmp[15:8]==8'h00);
            A_PAT_1   = (Addr==16'h5555);
        end
        else
        begin
            DataHi = Data_tmp[15:8];
            PATTERN_1 = (Addr==16'hAAAA) && (DataLo==8'hAA);
            PATTERN_2 = (Addr==16'h5555) && (DataLo==8'h55);
            A_PAT_1   = (Addr==16'hAAAA);
        end
    end

    always @(negedge write or reseted)
    begin: StateGen1

        if (reseted!=1'b1)
            next_state = current_state;
        else
        case (current_state)

            RESET :
            begin
                if (~write)
                begin
                    if (PATTERN_1)
                        next_state = Z001;
                    else
                        next_state = RESET;
                end
            end

            Z001 :
            begin
                if (PATTERN_2)
                    next_state = PREL_SETBWB;
                else
                    next_state = RESET;
            end

            PREL_SETBWB :
            begin
                if  (A_PAT_1 && (DataLo==8'h90))
                    next_state = AS;
                else if (A_PAT_1 && (DataLo==8'hA0))
                    next_state = A0SEEN;
                else if (A_PAT_1 && (DataLo==8'h41))
                    next_state = OTP_WRITE;
                else if (A_PAT_1 && (DataLo==8'h40))
                    next_state = OTP_READ;
                else if (A_PAT_1 && (DataLo==8'h80))
                    next_state = C8;
                else
                    next_state = RESET;
            end

            AS :
            begin
                if (PATTERN_1)
                    next_state = AS_EXIT_01;
                else
                    next_state = AS;
            end

            AS_EXIT_01 :
            begin
                if (PATTERN_2)
                    next_state = AS_EXIT_02;
                else
                    next_state = AS;
            end

             AS_EXIT_02 :
             begin
                 if (~(A_PAT_1 && (DataLo==8'hF0)))
                     next_state = AS;
             end

            OTP_READ :
            begin
                if (DataLo==16'hF0)
                    next_state = RESET;
                else if (PATTERN_1)
                    next_state = OTP_EXIT_01;
                else
                    next_state = OTP_READ;
            end

            OTP_EXIT_01 :
            begin
                if (PATTERN_2)
                    next_state = OTP_EXIT_02;
                else
                    next_state = OTP_READ;
            end

            OTP_EXIT_02 :
            begin
                if (A_PAT_1 && (DataLo==8'hF0))
                    next_state = RESET;
                else
                    next_state = OTP_READ;
            end

            A0SEEN :
            begin
                next_state = PGMS;
            end

            OTP_WRITE :
            begin
                next_state = PGMS;
            end

            C8 :
            begin
                if (PATTERN_1)
                    next_state = C8_Z001;
                else
                    next_state = RESET;
            end

            C8_Z001 :
            begin
                if (PATTERN_2)
                    next_state = C8_PREL;
                else
                    next_state = RESET;
            end

            C8_PREL :
            begin
                if (A_PAT_1 && (DataLo==8'h10))
                    next_state = ERS;
                else if (DataLo==8'h30)
                    next_state = SERS_EXEC;
                else
                    next_state = RESET;
            end

        endcase

    end

    always @(posedge AS_Exit)
    begin: StateGen0
        if (reseted!=1'b1)
            next_state = current_state;
        else
        begin
            if ((current_state==AS_EXIT_02) || (current_state==AS))
                next_state = RESET;
        end
    end

    always @(posedge PDONE or negedge PERR)
    begin: StateGen6
        if (reseted!=1'b1)
            next_state = current_state;
        else
        begin
            if (current_state==PGMS)
                next_state = RESET;
        end
    end

    always @(posedge EDONE or negedge EERR)
    begin: StateGen2
        if (reseted!=1'b1)
            next_state = current_state;
        else
        begin
            if ((current_state==ERS) || (current_state==SERS_EXEC))
            begin
                if (EDONE)
                    next_state = RESET;
            end
        end
    end
    ///////////////////////////////////////////////////////////////////////////
    //FSM Output generation and general funcionality
    ///////////////////////////////////////////////////////////////////////////

    always @(posedge read)
    begin
      ->oe_event;
    end

    always @(Address or PageAddr)
    begin
    add_lt = 1'b0;
    disable AL;
    ->Address_event;
    end

    always @(Address_event)
    begin: AL
        add_lt <= #5000   1'b1;
    end
    always @(posedge add_lt)
    begin
      if (read)
      begin
        ->oe_event;
      end
    end

    always @(oe_event)
    begin
        if (reseted)
        begin
        case (current_state)

            RESET :
            begin
                if (readpolling == 1'b1)
                    MemRead(DOut_zd);
                else
                begin
                    DOut_zd = dummyreadsts;
                    readpolling = 1'b1;
                end
            end

            AS :
            begin
                if (AS_Ent == 1'b1)
                    ASRead(DOut_zd);
            end

            OTP_READ :
            begin
                if (AS_Ent == 1'b1)
                begin
                    if (SEC_LOCK == 1'b1)
                    begin
                        DOut_zd[3:0] = OTP_Prot;
                    end
                    else
                    begin
                        if (OTP[(Address % (OTPSize + 1))]==-1)
                            DOut_zd[7:0] = 8'bx;
                        else
                            DOut_zd[7:0] = OTP[(Address %
                                                            (OTPSize + 1))];
                        if (BYTEB)
                            if (OTP[(Address % (OTPSize + 1))+1]==-1)
                                DOut_zd[15:8]= 8'bx;
                            else
                                DOut_zd[15:8] = OTP[(Address %
                                                        (OTPSize + 1))+1];
                    end
                end
            end

            ERS :
            begin
                if (1)
                    begin
                        ////////////////////////////////////////////////////////
                        // read status / embeded erase algorithm - Chip Erase
                        ////////////////////////////////////////////////////////
                        Status[7] = 1'b0;
                        Status[6] = ~Status[6]; //toggle
                        DOut_zd[7:0] = Status;
                        readpolling = 1'b1;
                        dummyreadsts[7] = 1'b1;
                   end
            end

            SERS_EXEC:
            begin
                if (1)
                begin
                    ///////////////////////////////////////////////////
                    //read status erase
                    ///////////////////////////////////////////////////
                    //%el should never hang
                    Status[7] = 1'b0;
                    Status[6] = ~Status[6]; //toggle
                    DOut_zd[7:0] = Status;
                    readpolling = 1'b1;
                    dummyreadsts[7] = 1'b1;
                end
            end

            PGMS :
            begin
                if (1)
                begin
                    ///////////////////////////////////////////////////////////
                    //read status
                    ///////////////////////////////////////////////////////////
                    Status[6] = ~Status[6]; //toggle
                    if ((OTP_ACT && SEC_LOCK))
                        Status[7] = 1'b1;
                    DOut_zd[7:0] = Status;
                    readpolling = 1'b1;
                    dummyreadsts[7] = ~Status[7];
                end
            end

        endcase
        end
    end

    always @(negedge write or reseted)
    begin : Output_generation
        if (reseted)
        begin
        case (current_state)

            RESET :
            begin
                OTP_ACT   = 1'b0;
            end

            Z001 :
            begin
                readpolling = 1'b1;
            end

            PREL_SETBWB :
            begin
                begin
                    if (A_PAT_1 && (DataLo==8'h41))
                        OTP_ACT  = 1'b1;
                    else if ((A_PAT_1 && (DataLo==8'h90)) ||
                             (A_PAT_1 && (DataLo==8'h40)))
                    begin
                        AS_Ent = 1'b0;
                        #tdevice_INTEXIT AS_Ent = 1'b1;
                    end
                end
            end

            AS :
            begin
                if (DataLo==8'hF0)
                begin
                    AS_Exit = 1'b0;
                    #tdevice_INTEXIT AS_Exit = 1'b1;
                end
            end

            AS_EXIT_02 :
            begin
                if (A_PAT_1 && (DataLo==8'hF0))
                begin
                    AS_Exit = 1'b0;
                    #tdevice_INTEXIT AS_Exit = 1'b1;
                end
            end

            A0SEEN :
            begin
                begin
                    PSTART = 1'b1;
                    PSTART <= #1000 1'b0;
                    if (Viol!=1'b0)
                    begin
                        WBData[0] = -1;
                        WBData[1] = -1;
                        Viol=1'b0;
                    end
                    else
                    begin
                        WBData[0] = DataLo;
                        WBData[1] = DataHi;
                    end
                    WBAddr[0] = Address;
                    PA = PageAddr;
                    temp = DataLo;
                    Status[7] = ~temp[7];
                    if (BYTEB)
                        WBAddr[1] = WBAddr[0] +1;
                    else
                        WBAddr[1] = -1;
                end
            end

            OTP_WRITE :
            begin
                begin
                    OTP_ACT = 1'b1;
                    ///////////////////////////////////////////////////////////
                    //OTP programming
                    ///////////////////////////////////////////////////////////
                    PSTART = 1'b1;
                    PSTART <= #1000 1'b0;
                    if (Viol!=1'b0)
                    begin
                        WBData[0] = -1;
                        WBData[1] = -1;
                        Viol = 1'b0;
                    end
                    else
                    begin
                        WBData[0] = DataLo;
                        WBData[1] = DataHi;
                    end
                    WBAddr[0] = (Address % (OTPSize + 1)) ;
                    temp = DataLo;
                    Status[7] = ~temp[7];
                    if (BYTEB)
                        WBAddr[1] = WBAddr[0] +1;
                    else
                        WBAddr[1] = -1;
                end
            end

            C8 :
            begin
                if (PATTERN_1)
                    begin
                    end
            end

            C8_Z001 :
            begin
                if (PATTERN_2)
                    begin
                    end
            end

            C8_PREL :
            begin
                if (A_PAT_1 && (DataLo==8'h10))
                    begin
                        //Start Chip Erase
                        ESTART = 1'b1;
                        ESTART <= #1000 1'b0;
                        Ers_queue = ~(0);
                        Status = 8'b00000000;
                    end
                    else if (DataLo==8'h30)
                    begin
                        ESTART = 1'b1;
                        ESTART <= #1000 1'b0;
                        Ers_queue = 0;
                        Ers_queue[PageAddr] = 1'b1;
                        Status = 8'b00000000;
                    end
            end

        endcase
        end
    end

    always @(EERR or EDONE or current_state)
    begin : ERS2
    integer i,j;
        if (current_state==ERS)
        begin
            if (EERR!=1'b1)
                for (i=0;i<=PageNum;i=i+1)
                begin
                    for (j=0;j<=PageSize;j=j+1)
                        Mem[sa(i)+j] = -1;
                end
            if (EDONE)
                for (i=0;i<=PageNum;i=i+1)
                begin
                    for (j=0;j<=PageSize;j=j+1)
                        Mem[sa(i)+j] = MaxData;
                end
       end
    end

    always @(current_state or EERR or EDONE)
    begin: SERS_EXEC2
    integer i,j,k;

    if (current_state==SERS_EXEC)
        if (EERR!=1'b1)
        begin
            for (i=0;i<=PageNum;i=i+1)
            begin
                if (Ers_queue[i])
                    for (j=0;j<=PageSize;j=j+1)
                        Mem[sa(i)+j] = -1;
            end
            if (EDONE)
            begin
                for (i=0;i<=PageNum;i=i+1)
                begin
                    if (Ers_queue[i])
                        for (j=0;j<=PageSize;j=j+1)
                            Mem[sa(i)+j] = MaxData;
                end
            end
        end
    end

    always @(current_state or posedge PDONE) // or PERR or PDONE)
    begin: PGMS2
    integer i,j;
        if (current_state==PGMS)
        begin
            if (PERR!=1'b1)
            begin
                if ((OTP_ACT==1'b1) && (SEC_LOCK == 1'b1))
                begin
                    OTP_Prot[3:0] = DataLo;
                end
                else
                begin
                    if (WBAddr[1] < 0 )
                        wr_cnt = 0;
                    else
                        wr_cnt = 1;
                    for (i=wr_cnt;i>=0;i=i-1)
                    begin
                        new_int= WBData[i];
                        old_int = 0;
                        if (OTP_ACT!=1'b1)
                            old_int=Mem[PA*(PageSize+1)+WBAddr[i]];
                        else
                            old_int=OTP[WBAddr[i]];
                        if (new_int>-1)
                        begin
                            new_bit = new_int;
                            if (old_int>-1)
                            begin
                                old_bit = old_int;
                                for(j=0;j<=7;j=j+1)
                                    if (~old_bit[j])
                                        new_bit[j]=1'b0;
                                new_int=new_bit;
                            end
                            WBData[i]= new_int;
                        end
                        else
                            WBData[i]= -1;
                    end
                    for (i=wr_cnt;i>=0;i=i-1)
                    begin
                        if (OTP_ACT!=1'b1)   //mem write
                            Mem[PA*(PageSize+1)+WBAddr[i]] = -1;
                        else
                            OTP[WBAddr[i]]   = -1;
                    end
                    if (PDONE && ~PSTART)
                    for (i=wr_cnt;i>=0;i=i-1)
                        begin
                            if (WBAddr[i]> -1)
                                if (OTP_ACT!=1'b1)   //mem write
                                    Mem[PA*(PageSize+1)+WBAddr[i]] = WBData[i];
                                else //OTP write
                                    OTP[WBAddr[i]]   = WBData[i];
                            else
                                $display("Write Address error");
                            WBData[i]= -1;
                        end
                end
            end
        end
    end

    //Output timing control
    always @(DOut_zd)
    begin : OutputGen
        if (DOut_zd[0] !== 1'bz)
        begin
            CEDQ_t = CEB_event  + CEDQ_01;
            OEDQ_t = OEB_event  + OEDQ_01;
            ADDRDQ_t = ADDR_event + ADDRDQ;
            FROMCE = ((CEDQ_t >= OEDQ_t) && ( CEDQ_t >= $time));
            FROMOE = ((OEDQ_t >= CEDQ_t) && ( OEDQ_t >= $time));
            FROMADDR = 1'b1;
            if ((ADDRDQ_t > $time )&&
             (((ADDRDQ_t>OEDQ_t)&&FROMOE) ||
              ((ADDRDQ_t>CEDQ_t)&&FROMCE)))
            begin
                TempData = DOut_zd;
                FROMADDR = 1'b0;
                if (~BYTEB)
                    DOut_Pass[15:8] = 8'bz;
                else
                    DOut_Pass[15:8] = 8'bx;
                DOut_Pass[7:0] = 8'bx;
                DOut_Pass <= #(ADDRDQ_t - $time) TempData;
            end
            else
            begin
                DOut_Pass = DOut_zd;
            end
        end
    end

    always @(DOut_zd)
    begin
        if (DOut_zd[0] === 1'bz)
        begin
            disable OutputGen;
            FROMCE = 1'b1;
            FROMOE = 1'b1;
            FROMADDR = 1'b0;
            DOut_Pass = DOut_zd;
        end
    end

    always @(gOE_n or RESETB or RST or BYTEB or gCE_n)
    begin
        //Output Disable Control
        if (gOE_n || gCE_n || (~RESETB && ~RST))
            DOut_zd = 16'bZ;
        else
            if (~BYTEB)
                DOut_zd[15:8] = 8'bZ;
     end

    function integer sa;
    input sect;
    integer sect;
    begin
        sa = sect * (PageSize + 1);
    end
    endfunction

//////Read from memory
    task MemRead;
    inout [15:0] DOut_zd;
    begin
    if (Mem[(PageAddr*(PageSize+1))+Address]==-1)
        DOut_zd[7:0] = 8'bx;
    else
        DOut_zd[7:0] = Mem[(PageAddr*(PageSize+1))+Address];
    if (BYTEB)
        if (Mem[(PageAddr*(PageSize+1))+Address+1]==-1)
            DOut_zd[15:8]= 8'bx;
        else
            DOut_zd[15:8] = Mem[(PageAddr*(PageSize+1))+Address+1];
    end
    endtask

/////////////Read AS Code
    task  ASRead;
    inout [15:0] DOut_zd;
    integer AsAddress;
    begin
        if (BYTEB)
        begin
            AsAddress = Address[8:1];
            if (AsAddress == 0)
                DOut_zd[15:0] = 16'h7F7F;
            else if (AsAddress == 1)
                DOut_zd[15:0] = 16'h3944;
            else if (AsAddress == 4)
                DOut_zd[15:0] = 16'h7FA7;
        end
        else
        begin
            AsAddress = Address[7:0];
            if ((AsAddress == 0) || (AsAddress == 1))
                DOut_zd[7:0] = 8'h7F;
            else if (AsAddress == 8)
                DOut_zd[7:0] = 8'hA7;
            else if (AsAddress == 9)
                DOut_zd[7:0] = 8'h7F;
            else if (AsAddress == 2)
                DOut_zd[7:0] = 8'h44;
            else if (AsAddress == 3)
                DOut_zd[7:0] = 8'h39;
        end
    end
    endtask

    initial
    begin
//      BuffInOE  <= #4000 1'b1;  //uncomment for min times
//      BuffInOE  <= #7000 1'b1;  //uncomment for typ times
        BuffInOE   <= #10000 1'b1;
//      BuffInCE   <=  #10000 1'b1;  //uncomment for min times
//      BuffInCE   <=  #20000 1'b1;  //uncomment for typ times
        BuffInCE   <= #35000 1'b1;
//      BuffInADDR <=  #10000 1'b1;  //uncomment for min times
//      BuffInADDR <=  #20000 1'b1;  //uncomment for typ times
        BuffInADDR <= #35000 1'b1;
    end

    always @(posedge BuffInOE)
    begin
        OEDQ_01 = $time;
    end
    always @(posedge BuffInCE)
    begin
        CEDQ_01 = $time;
    end
    always @(posedge BuffInADDR)
    begin
        ADDRDQ = $time;
    end
endmodule 
