/* cpld_ram512K_v110
 * 
 * ==============================================================================
 * Only to be used with v1.10 CPLD board
 * ==============================================================================
 * 
 * CPLD module to implement all logic for an Amstrad CPC 512K RAM extension card
 *
 * (c) 2018, Revaldinho
 *
 * Select RAM bank scheme by writing to 0x7FXX with 0b11cccbbb, where:
 * 
 * ccc - picks one of 8 possible 64K banks
 * bbb - selects a block switching scheme within the chosen bank
 *       the actual block used for a RAM access is then selected by the top 2 addr bits for that access.
 *
 * 128K RAM Expansion Mapping Example...
 *
 * In the table below '-' indicates use of CPC internal RAM rather than the RAM expansion
 * -------------------------------------------------------------------------------------------------------------------------------
 * Address\cccbbb 000000 000001 000010 000011 000100 000101 000110 000011 001000 001001 001010 001011 001100 001101 001110 001111
 * -------------------------------------------------------------------------------------------------------------------------------
 * 1100-1111       -       3      3      3      -      -      -      -      -      7       7      7     -      -      -      -
 * 1000-1011       -       -      2      -      -      -      -      -      -      -       6      -     -      -      -      -
 * 0100-0111       -       -      1      **     0      1       2      3     -      -       5      -     4      5      6      7
 * 0000-0011       -       -      0      -      -      -      -      -      -      -       4      -     -      -      -      -
 * -------------------------------------------------------------------------------------------------------------------------------
 * 
 * Check-in Status table - 464 Mode
 * ================================
 * 
 *  Always write all blocks in shadow bank even if only block3 is ever read.
 * 
 * 464 Serial Number    : 
 * Overdrive Mode       : ON/RD_B + ADR15
 * Shadow Mode          : ON/Partial
 * Write cycle control  : State Machine
 * A15_Q                : Latched (not Flopped)
 * 
 *                     |   OVERDRIVE ONLY                                             |   OVERDRIVE + Partial SHADOW                                 
 *                     |Result| Notes                                                 |Result| Notes                                                 
 * --------------------+------+-------------------------------------------------------+------+-------------------------------------------------------
 * Tests/Voltage       |5.00V |                                                       |5.00V |                                                       
 * --------------------+------+-------------------------------------------------------+------+-------------------------------------------------------
 * Test Programs       |      |                                                       |      |                                                       
 *  o test.bin         |      |                                                       | PASS |
 *  o ramtest.bin      |      |                                                       | PASS |                                                       
 * Apps                |      |                                                       |      |                                                       
 *  o CP/M+ TurboPascal|      |                                                       | PASS | Edit/Compile/Run ..                                                               
 *  o CP/M+ BBC BASIC  |      |                                                       | FAIL | Cannot Load Program                                                      
 *  o CP/M+ WordStar   |      |                                                       |      |                                                       
 *  o FutureOS Desktop |      |                                                       | PASS |                                                       
 *  o Amstrad Bankman  |      |                                                       |      |                                                       
 *  o DK'T Bankman     | //   |                                                       | PASS |                                                       
 *  o DK'T SiDisc      | //   |                                                       | PASS |                                                       
 * Demos               |      |                                                       |      |                                                       
 *  o Phortem          |      |                                                       |      |                                                       
 *  o Batman           | NA   | wrong type of CRTC                                    | NA   | wrong type of CRTC                                    
 * Other               |      |                                                       |      |                                                       
 *  o Chase HQ         |      |                                                       | PASS |                                                       
 *  o ZapTBalls        |      |                                                       | PASS |                                                       
 *  o Double Dragon    |      |                                                       | FAIL | Loading screen corruption/game play ok                                                       
 *  o P47              |      |                                                       | FAIL | Boot screens ok, blank screen/hang on starting game                                                      
 *  o HardDrivin'      |      |                                                       | 
 *  o Prehistorik 2    |      |                                                       | PASS |                                                       
 *  o RoboCop          |      |                                                       | PASS |                                                       
 *  o Gryzor           |      |                                                       | PASS |                                                       
 *  o R-Type           |      |                                                       | PASS |                                                       
 * --------------------+------+-------------------------------------------------------+------+-------------------------------------------------------
 *
 * Notes
 * - ChaseHQ does not run when FutureOS ROMs are enabled. Issues CHASEHQ4.RAM not found message
 */


// Conditional compilation options
`define STATE_MACHINE        1 // Use state machine to compute end of write cycle rather than sensing via mreq/m1/rfsh etc.
//`define FULL_SHADOW_MODE     1 // Always prefer shadow RAM for reads to base RAM, all blocks. Otherwise a partial shadow scheme is used.
`define DRIVE_ADR_AUX 1
`define DRIVE_RDB_AUX 1
`define LATCH_ADR15   1

module cpld_ram512k_v110(
  input        rfsh_b,
  inout        adr15,
  inout        adr15_aux, 
  input        adr14,
  input        adr8, 
  input        iorq_b,
  input        mreq_b,
  input        ramrd_b,
  input        reset_b,
  input        wr_b,
  inout        rd_b,
  inout        rd_b_aux, 
  input [7:0]  data,
  input        ready,
  input        clk,
  input        m1_b,
  input [1:0]  dip,
    
  output       ramdis,
  output       ramcs_b,
  output [4:0] ramadrhi,
  output       ramoe_b,
  output       ramwe_b
);
  
  reg [5:0]        ramblock_q;
  reg [2:0]        hibit_tmp_r;  
  reg [4:0]        ramadrhi_r;
  reg [1:0]        state_q;
  reg              ready_f_q;              
  reg              ramcs_b_r;
  reg              clken_lat_qb;
  reg              adr15_q;
  reg              mreq_b_q;
  reg              mwr_cyc_q, mwr_cyc_f_q;
  reg              exp_ram_r;
  reg              shadow_en_b_r;              
  reg              adr15_overdrive_r;
  wire             mwr_cyc_w;
  
  wire             overdrive_mode = dip[0];                  // AKA 464 mode
  wire             shadow_mode = dip[1]  ;                   // Only valid in overdrive mode              
  wire [2:0]       shadow_bank = 3'b111;                     // use 3'b111 or 3'b011

  // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire             wclk    = !(clk|clken_lat_qb); 

  assign ramadrhi = ramadrhi_r ;
  assign ramwe_b = wr_b ;
  // Combination of RAMCS and RAMRD determine whether RAM output is enabled 
  assign ramoe_b = ramrd_b ; //| (overdrive_mode & mwr_cyc_w ) ;

  //          ____      ____      ____      ____      ____  
  // CLK     /    \____/    \____/    \____/    \____/    \_
  //         _____     :    .    :    .    :    .   ________
  // MREQ*        \________________________________/ :    .
  //         _______________________________________________
  // RFSH*   1         :    .    :    .    :    .    :    .
  //         _________________   :    .    :    .  _________
  // WR*               :    . \___________________/  :    .    
  //         _____________       ___________________________
  // READY             :  \_____/      
  //                   :    .    :    .    :    .    :    .
  //                   :_____________________________:    .        
  // MWR_CYC    _______/    .    :    .    :    .    \______
  //          _________:_________:_________:_________:______
  // State    _IDLE____X___T1____X____T1___X___T2____X_END__
  // 
  // overdrive rd_b for all expansion write accesses only - need to keep overdriving beyond mreq_b rising edge

`ifdef DRIVE_RDB_AUX  
  assign { rd_b, rd_b_aux }    = ( overdrive_mode ) ? ( exp_ram_r & mwr_cyc_w ) ? 2'b00 : 2'bzz : 2'bzz;
`else  
  assign { rd_b, rd_b_aux }    = ( overdrive_mode ) ? ( exp_ram_r & mwr_cyc_w ) ? 2'b0z : 2'bzz : 2'bzz;
`endif  

`ifdef DRIVE_ADR_AUX 
  assign { adr15, adr15_aux}   = ( overdrive_mode ) ? ( adr15_overdrive_r ) ? 2'b11 : 2'bzz : 2'bzz ;   
`else  
  assign { adr15, adr15_aux}   = ( overdrive_mode ) ? ( adr15_overdrive_r ) ? 2'b1z : 2'bzz : 2'bzz ;
`endif 
  
`ifdef FULL_SHADOW_MODE  
  // Never, ever use internal RAM for reads in full shadow mode
  assign ramdis = (shadow_mode) ? 1'b1 :  !ramcs_b_r ;  
  // In full shadow mode SRAM is always enabled for all real RAM accesses
  assign ramcs_b = (shadow_mode ) ? (mreq_b | !rfsh_b) : ramcs_b_r | mreq_b | !rfsh_b ;
`else // PARTIAL_SHADOW_MODE or no shadow mode
  assign ramdis  = !ramcs_b_r  ;
  assign ramcs_b = ramcs_b_r | mreq_b | !rfsh_b ;
`endif

  
`ifdef STATE_MACHINE    
  parameter IDLE=2'b00, T1=2'b01, T2=2'b11, END=2'b10;  
  // alternative calculation of mwr_cyc_w once a write event is triggered    
  assign mwr_cyc_w = (state_q==T1)|(state_q==T2) ;  
  always @ (negedge reset_b or posedge clk)
    if ( !reset_b )
      state_q <= IDLE;
    else
      case ( state_q ) 
        IDLE: state_q <= (!mreq_b & rfsh_b & rd_b ) ? T1 : IDLE ;
        T1:   state_q <= (ready_f_q) ? T2: T1;
        T2:   state_q <= IDLE;
        default: state_q <= IDLE;        
      endcase
  
  always @ ( negedge reset_b or negedge clk)
    if ( !reset_b )
      ready_f_q = 1'b1;
    else
      ready_f_q = ready;
`else
  assign mwr_cyc_w = mwr_cyc_q;

  always @ ( negedge reset_b or posedge clk )
    if ( !reset_b)
      mwr_cyc_q <= 1'b0;
    else
      if ( !mreq_b & mreq_b_q & rfsh_b & rd_b )
        mwr_cyc_q <= 1'b1;
      else if ( mreq_b | !rfsh_b )
        mwr_cyc_q <= 1'b0;

  always @ ( negedge reset_b or posedge clk )
      if ( !reset_b)
          mreq_b_q <= 1'b1;                                      
      else
          mreq_b_q <= mreq_b;                                     

`endif                      

  
  always @ ( negedge reset_b or negedge clk )
    if ( !reset_b)
      mwr_cyc_f_q <= 1'b0;
    else
      mwr_cyc_f_q <= mwr_cyc_q;

`ifdef LATCH_ADR15
   // Use a latch to release adr15_q as soon as mreq_b is high but lock it on mreq_b going low
   always @ ( * ) 
     if ( mreq_b ) 
       adr15_q <= adr15;
`else
   always @ (negedge reset_b or negedge mreq_b ) 
     if ( !reset_b ) 
       adr15_q <= 1'b0;
     else
       adr15_q <= adr15;
`endif 
    
  always @ (*) begin
    if ( shadow_mode )
      // Restrict overdrive of A15 to writes as read will be remapped from shadow RAM
      adr15_overdrive_r = (ramblock_q[2:0]==3'b011) & adr14 & mwr_cyc_w ;
    else
      // Need to overdrive A15 for both reads and writes if shadow RAM not enabled
      adr15_overdrive_r = (ramblock_q[2:0]==3'b011) & adr14 & !mreq_b ; //  ?? (!mreq_b|!ram_rd|mwr_cyc_w) ;
  end

  always @ ( * )
    if ( clk ) 
      clken_lat_qb <= !(!iorq_b && !wr_b && !adr15 && data[6] && data[7]);
  
  always @ (negedge reset_b or posedge wclk )
    if (!reset_b)
      ramblock_q <= 6'b0;
    else
      ramblock_q <= data[5:0];

  
  always @ ( * ) begin
    if ( shadow_mode ) begin
      hibit_tmp_r = ramblock_q[5:3] ;        
      if ( hibit_tmp_r == shadow_bank ) begin 
        hibit_tmp_r[0] = 1'b0; // alias the even bank below shadow bank to the shadow bank
      end
`ifdef FULL_SHADOW_MODE
      // FULL SHADOW MODE - all read accesses come from shadow bank except for CRTC accesses to internal memory  
      case (ramblock_q[2:0])
 	3'b000: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 2'b00, shadow_bank, adr15,adr14 };
 	3'b001: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15,adr14}==2'b11) ? {2'b10, hibit_tmp_r,adr15,adr14} : { 2'b00, shadow_bank, adr15, adr14 };
 	3'b010: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 1'b1, 1'b0,hibit_tmp_r,adr15,adr14} ; 
 	3'b011: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15_q,adr14}==2'b11) ? {2'b10,hibit_tmp_r,2'b11} : { 2'b00, shadow_bank, (adr15_q|adr14), adr14 };              
 	3'b100: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15,adr14}==2'b01) ? {2'b10,hibit_tmp_r,2'b00} : { 2'b00, shadow_bank, adr15, adr14 };              
 	3'b101: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15,adr14}==2'b01) ? {2'b10,hibit_tmp_r,2'b01} : { 2'b00, shadow_bank, adr15, adr14 };              
 	3'b110: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15,adr14}==2'b01) ? {2'b10,hibit_tmp_r,2'b10} : { 2'b00, shadow_bank, adr15, adr14 };              
 	3'b111: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ({adr15,adr14}==2'b01) ? {2'b10,hibit_tmp_r,2'b11} : { 2'b00, shadow_bank, adr15, adr14 };
      endcase // case (hibit_tmp_r[2:0])
`else 
      // PARTIAL SHADOW MODE - all write accesses go to shadow memory but only shadow block 3 is ever read in mode C3 at bank 0x4000 (remapped to 0xC000)
      shadow_en_b_r = wr_b;       
      case (ramblock_q[2:0])
 	3'b000: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 1'b0, shadow_en_b_r , shadow_bank, adr15,adr14 };
 	3'b001: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b1, 1'b0, hibit_tmp_r,2'b11} : { 1'b0, shadow_en_b_r , shadow_bank, adr15,adr14 };
 	3'b010: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 1'b1, 1'b0,hibit_tmp_r, adr15,adr14} ; 
 	3'b011: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {2'b10,hibit_tmp_r,2'b11} : ({adr15_q,adr14}==2'b01) ? {2'b00,shadow_bank,2'b11} : { 1'b0, shadow_en_b_r , shadow_bank, adr15,adr14 };
 	3'b100: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,hibit_tmp_r,2'b00} : { 1'b0, shadow_en_b_r , shadow_bank, adr15, adr14 };              
 	3'b101: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,hibit_tmp_r,2'b01} : { 1'b0, shadow_en_b_r , shadow_bank, adr15, adr14 };              
 	3'b110: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,hibit_tmp_r,2'b10} : { 1'b0, shadow_en_b_r , shadow_bank, adr15, adr14 };              
 	3'b111: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,hibit_tmp_r,2'b11} : { 1'b0, shadow_en_b_r , shadow_bank, adr15, adr14 };
      endcase // case (hibit_tmp_r[2:0])
`endif
    end
    else begin
      case (ramblock_q[2:0])
 	3'b000: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 2'b01, 5'bxxxxx };
 	3'b001: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {2'b10,ramblock_q[5:3],2'b11} : {2'b01, 5'bxxxxx};
 	3'b010: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 2'b10,ramblock_q[5:3],adr15,adr14} ; 
 	3'b011: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {2'b10,ramblock_q[5:3],2'b11} : {2'b01, 5'bxxxxx }; 
 	3'b100: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b00} : {2'b01, 5'bxxxxx };              
 	3'b101: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b01} : {2'b01, 5'bxxxxx };              
 	3'b110: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b10} : {2'b01, 5'bxxxxx };              
 	3'b111: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b11} : {2'b01, 5'bxxxxx };
      endcase 
    end	    
  end
  
endmodule
