/* cpld_ram512K
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
 * 0100-0111       -       -      1      -      0      1       2      3     -      -       5      -     4      5      6      7
 * 0000-0011       -       -      0      -      -      -      -      -      -      -       4      -     -      -      -      -
 * -------------------------------------------------------------------------------------------------------------------------------
 *
 */

`define OVERDRIVE 1



module cpld_ram512k_overdrive(rfsh_b,adr15,adr14,iorq_b,mreq_b,ramrd_b,reset_b,wr_b,rd_b,data,ramdis,ramcs_b,ramadrhi,ready, clk, ramoe_b, ramwe_b, adr15_out, mreq_b_out);
  input            rfsh_b;
  inout            adr15;    
  input            adr14;
  input            iorq_b;
  input            mreq_b;
  input            ramrd_b;
  input            reset_b;
  input            wr_b;
  inout            rd_b;    
  input [7:0]      data;
  input            ready;
  input            clk;
  
  
  output           ramdis;
  output           ramcs_b;
  output [4:0]     ramadrhi;
  output           ramoe_b;
  output           ramwe_b;
  inout [1:0]      adr15_out;
  inout [2:0]      mreq_b_out;  
  
  reg [5:0]        ramblock_q;
  reg [4:0]        ramadrhi_r;
  reg              ramcs_b_r;
  reg              clken_lat_qb;
  reg              adr15_q;
  reg              mreq_b_q;
  reg [1:0]        state_q;	
  reg              mwr_cyc_q;
  reg              mrd_cyc_q;  

  wire             mode464_q = 1'b1;
  wire             overdrive_q = 1'b1;  

  parameter IDLE=2'b00, WM0=2'b11, WM1=2'b10, END=2'b01;
  // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire             wclk    = !(clk|clken_lat_qb); 
  // Combination of RAMCS and RAMRD determine whether RAM output is enabled
  assign ramoe_b = ramrd_b ;		
  assign ramdis  = !ramcs_b_r &  (!mreq_b|(state_q==END));    
  assign ramadrhi = ramadrhi_r ;

  //          ____      ____      ____      ____      ____  
  // CLK     /    \____/    \____/    \____/    \____/    \_
  //         _____     :    .         .         .   ________
  // MREQ*        \________________________________/ :    .
  //         _______________________________________________
  // RFSH*   1         :    .         .         .    :    .
  //         _________________        .         .  _________
  // WR*               :    . \___________________/  :    .    
  //         _____________       ___________________________
  // READY             :  \_____/      
  //                   :    .         .         .    :    .
  //                   :_____________________________:    .        
  // MWR_CYC    _______/    .         .         .    \______
  //         _____ _________._________._________._________.
  // STATE   IDLE_X__IDLE___X__WM0____X__WM1____X_END____X
  //        
  // MREQ_OD  zzzzzzzzz11111111111111111111111111111111111111111zzzzzz
  // 
  // Notes
  // - 1 wait state shown above (WM0->WM0)
   
  assign ramcs_b = ramcs_b_r  | mreq_b ;  
  assign ramwe_b = wr_b ;
  // overdrive A15 HIGH only in mode 3 when address is 0x4000-0x0x7FFF and valid mcycle
  assign adr15 = (mode464_q & overdrive_q ) ? (((ramblock_q[2:0]==3'b011) & !adr15_q & adr14 & (!mreq_b | state_q==END) ) ? 1'b1 : 1'bz ): 1'bz;
  // Gate array does not use the mreq signal but instead uses rd_b as a read-not-write signal, so overdrive this to protect internal RAM !
  assign rd_b  = (mode464_q & overdrive_q ) ? ( !ramcs_b_r &  (!mreq_b|mwr_cyc_q)  ) ? 1'b0 : 1'bz : 1'bz;
  assign { mreq_b_out }  = 3'bzzz;  
  assign { adr15_out}  = 2'bzz; 
  
  always @ ( negedge reset_b or negedge clk) 
    if (!reset_b)
      state_q <= IDLE;
    else
      case ( state_q )
        END:  state_q <= ( mwr_cyc_q | mrd_cyc_q) ? ((ready) ? WM1 : WM0 ) : IDLE; // intentional half-cycle path from mwr_cyc_q        
        IDLE: state_q <= ( mwr_cyc_q | mrd_cyc_q) ? ((ready) ? WM1 : WM0 ) : IDLE; // intentional half-cycle path from mwr_cyc_q
        WM0:  state_q <= ( ready ) ? WM1 : WM0;      // -ve edge FSM can sample 'ready' directly
        WM1:  state_q <=  END ;
        default: state_q <= IDLE;
      endcase
  
  always @ ( negedge reset_b or posedge clk) 
    if (!reset_b) begin
      mreq_b_q <= 1'b1;
      mwr_cyc_q <= 1'b0;
      mrd_cyc_q <= 1'b0;      
    end 
    else begin    
      mreq_b_q <= mreq_b;
      if ( !mreq_b & mreq_b_q & rfsh_b & iorq_b ) begin
        mwr_cyc_q <= rd_b;
        mrd_cyc_q <= !rd_b;        
      end
      else if ( state_q == END) begin
          mwr_cyc_q <= 1'b0;
          mrd_cyc_q <= 1'b0;
      end
    end // else: !if(!reset_b)
  
  //   // Pin straps read on startup to set appropriate modes and can be used out of reset as GPIO
  //   assign dip   = (!reset_b) ? 4'bz: 4'bz; 
  //   always @ ( posedge reset_b )
  //     {mode464_q, overdrive_q, ram_id0_q, ram_id1_q} < = dip;
  //     
  always @ (negedge reset_b or negedge mreq_b ) 
    if ( !reset_b ) 
      adr15_q <= 1'b0;
    else
      adr15_q <= adr15;
  
  always @ ( * )
    if ( clk ) 
      clken_lat_qb <= !(!iorq_b && !wr_b && !adr15 && data[6] && data[7]);
  
  always @ (negedge reset_b or posedge wclk )
    if (!reset_b)
      ramblock_q <= 6'b0;
    else
      ramblock_q <= data[5:0];
  
  always @ ( * )
    if ( !mwr_cyc_q && !mrd_cyc_q)
      {ramcs_b_r, ramadrhi_r} = { 1'b1, 5'bxxxxx };
    else
      case (ramblock_q[2:0])
        3'b000: {ramcs_b_r, ramadrhi_r} = { 1'b1, 5'bxxxxx };
        3'b001: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : { 1'b1, 5'bxxxxx};
        3'b010: {ramcs_b_r, ramadrhi_r} = { 1'b0,ramblock_q[5:3],adr15_q,adr14} ; 
        3'b011: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : {1'b1, 5'bxxxxx };
        3'b100: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],2'b00} : {1'b1, 5'bxxxxx };              
        3'b101: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],2'b01} : {1'b1, 5'bxxxxx };              
        3'b110: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],2'b10} : {1'b1, 5'bxxxxx };              
        3'b111: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],2'b11} : {1'b1, 5'bxxxxx };
      endcase // case (ramblock_q[2:0])
  
    
endmodule
