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
 * Notes
 * - ChaseHQ does not run when FutureOS ROMs are enabled. Issues CHASEHQ4.RAM not found message
 * 
 * Crib
 * 1. Keeping a net in synthesis
 * //synthesis attribute keep of input_a_reg is "true"
 * BUF mybuf (.I(input_a_reg),.O(comb));
 */


// Evaluate benefits of having full shadow mode only in synthesis
//`define FULL_SHADOW_ONLY 1
`define ENABLE_TURBO 1

module cpld_ram512k_v110(
  input       rfsh_b,
  inout       adr15,
  inout       adr15_aux, 
  input       adr14,
  input       adr8, 
  input       iorq_b,
  input       mreq_b,
  input       ramrd_b,
  input       reset_b,
  input       wr_b,
  inout       rd_b,
  inout       rd_b_aux, 
  input [7:0] data,
`ifdef ENABLE_TURBO
  inout       ready,                         
`else                         
  input       ready,
`endif                         
  input       clk,
  input       m1_b,
  input [1:0] dip,
    
  output      ramdis,
  output      ramcs_b,
  inout [4:0] ramadrhi, // bits 4,3 also connected to DIP switches 2,1 resp and read on startup
  output      ramoe_b,
  output      ramwe_b
);
  
  reg [5:0]        ramblock_q;
  reg [4:0]        ramadrhi_r;
  reg [3:0]        dip_q;
  reg              mode3_q;              
  reg              mwr_cyc_q;
  reg              mwr_cyc_f_q;  
  reg              ramcs_b_r;
  reg              clken_lat_qb;
  reg              adr15_q;
  reg              exp_ram_r;
  reg              mreq_b_q, mreq_b_f_q;
  wire             mwr_cyc_d;  
  wire             adr15_overdrive_w;
  wire             turbo_mode;
  wire             shadow_mode;
  wire             overdrive_mode;
  wire             full_shadow;
  wire [2:0]       shadow_bank;

/* 
 * D D D D  NB DIP Switches labelled 1-4 on the physical component on the board, but the
 * I I I I  DIP numbers run from 0-3 in the code.
 * P P P P
 * 1 2 3 4  Function settings                           Total Exp/SiDisc Compatibility
 * -----------------------------------------------------------------------------------------------------
 * 0 0 0 0  OD OFF, Shadow OFF, turbo OFF               512KB 256/256    6128/Plus
 *                                                            
 * 0 1 0 0  OD OFF, Shadow FULL, Bank LOW, turbo OFF    448KB 192/256    6128/Plus w. SiDisk [1]
 * 0 1 0 1  OD OFF, Shadow FULL, Bank HIGH, turbo OFF   448KB 448/0      6128/Plus [1]
 * 0 1 1 0  OD OFF, Shadow FULL, Bank LOW, turbo ON     448KB 192/256    6128/Plus w. SiDisk [1,2]
 * 0 1 1 1  OD OFF, Shadow FULL, Bank HIGH, turbo ON    448KB 448/0      6128/Plus [1,2]
 *                                                                         
 * 1 0 0 0  OD ON, Shadow OFF, turbo OFF                512KB 256/256    464 DK'T
 *                                                                         
 * 1 0 1 0  OD ON, Shadow PARTIAL, Bank LOW, turbo OFF  448KB 192/256    464 C3 (FutureOS) w. SiDisk
 * 1 0 1 1  OD ON, Shadow PARTIAL, Bank HIGH, turbo OFF 448KB 448/0      464 C3 (FutureOS) 
 *                                                                         
 * 1 1 0 0  OD ON, Shadow FULL, Bank LOW, turbo OFF     448KB 192/256    464 C3 (FutureOS) w. SiDisk
 * 1 1 0 1  OD ON, Shadow FULL, Bank HIGH, turbo OFF    448KB 448/0      464 C3 (FutureOS)
 * -----------------------------------------------------------------------------------------------------
 * Experimental code only - not enabled 
 * 1 1 1 0  OD ON, Shadow FULL, Bank LOW, turbo ON      448KB 192/256    464 C3 (FutureOS) w. SiDisk [2]
 * 1 1 1 1  OD ON, Shadow FULL, Bank HIGH, turbo ON     448KB 448/0      464 C3 (FutureOS) [2]
 * -----------------------------------------------------------------------------------------------------
 * 
 * [1] FULL shadow mode still not seen working on 6128
 * [2] Turbo mode needs to be tested for limitations - already know that
 *     use in all modes can cause video problems in CP/M and Phortem even
 *     when mode 3 specifically disabled.
 */

  assign overdrive_mode = dip[0];                  // ie DIP SW 1 
  assign shadow_mode = dip[1] | dip_q[2];        // ie DIP SW 2 OR DIP SW 3
  assign full_shadow = dip[1];                   // ie DIP SW 2
  assign shadow_bank = { dip_q[3], 2'b11 } ;       // ie DIP SW 4
  assign turbo_mode  = dip[1] & dip_q[2];        // ie DIP SW 2 AND DIP SW 3
  
  // Should be able to ignore waits on all reads from expansion RAM but CP/M shows some visible pixel
  // corruption in mode2 which can be eliminated by this additional term:  ({adr14,ramblock_q[2:0]}!=4'b1010)
`ifdef ENABLE_TURBO  
  assign ready =  (turbo_mode & ((!(|ramblock_q[1:0])|ramblock_q[2]) & !mwr_cyc_q & !ramrd_b & !mreq_b) ) ? 1'b1 : 1'bz;
`endif
  
  // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire             wclk    = !(clk|clken_lat_qb); 

  // Dont drive address outputs during reset due to overlay of DIP switches    
  assign ramadrhi = (reset_b) ? ramadrhi_r : {2'bzz, ramadrhi_r[2:0]} ; 
  assign ramwe_b  = wr_b ;
  // Combination of RAMCS and RAMRD determine whether RAM output is enabled 
  assign ramoe_b = ramrd_b ;
  
 // Memory Data Access
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
  // MWR_CYC    _______/    .    :    .    :    .    \______  FF'd Version 
  // State    _IDLE____X___T1____X____T1___X___T2____X_END__
  //
  
  // overdrive rd_b for all expansion write accesses only - extend overdrive to trailing edge following mreq going high
  assign { rd_b, rd_b_aux }    = ( overdrive_mode & exp_ram_r & (mwr_cyc_q|mwr_cyc_f_q)) ? 2'b00 : 2'bzz ;

  // Overdrive A15 for writes only in shadow modes (full and partial) but for all access types otherwise
  // Need to compute whether A15 will need to be driven before the first rising edge of the MREQ cycle for the
  // gate array to act on it. Cant wait to sample mwr_cyc_q after it has been set initially.
  assign mwr_cyc_d = (mreq_b_f_q | mreq_b_q) & !mreq_b & rfsh_b & rd_b & m1_b ;  
  assign adr15_overdrive_w   =  overdrive_mode & mode3_q & adr14 & rfsh_b & ((shadow_mode) ? (mwr_cyc_q|mwr_cyc_d): !mreq_b) ;
  assign { adr15, adr15_aux} = (adr15_overdrive_w  ) ? 2'b11 : 2'bzz; 

`ifdef FULL_SHADOW_ONLY
  // Never, ever use internal RAM for reads in full shadow mode  (but allow it in overdrive only)
  assign ramdis = (shadow_mode) ? 1'b1 :  !ramcs_b_r ;  
  // In full shadow mode SRAM is always enabled for all real memory accesses but dont clash with ROM access (ramrd_b will control oe_b)
  assign ramcs_b = mreq_b | !rfsh_b ;  
`else  
  // Never, ever use internal RAM for reads in full shadow mode  
  assign ramdis = (full_shadow) ? 1'b1 :  !ramcs_b_r ;  
  // In full shadow mode SRAM is always enabled for all real memory accesses but dont clash with ROM access (ramrd_b will control oe_b)
  assign ramcs_b = !( !ramcs_b_r | full_shadow) | mreq_b | !rfsh_b ;
`endif

  always @ (posedge clk)
    if ( !reset_b )
      mwr_cyc_q <= 1'b0;
    else begin
      if ( mwr_cyc_d ) 
        mwr_cyc_q <= 1'b1;
      else if (mreq_b)
        mwr_cyc_q <= 1'b0;
    end

  always @ (negedge clk)
    if ( !reset_b ) begin
      mreq_b_f_q = 1'b1;
      mwr_cyc_f_q <= 1'b0;      
    end     
    else begin
      mreq_b_f_q = mreq_b;
      mwr_cyc_f_q <= mwr_cyc_q;            
    end
  
  always @ (posedge clk)
    if ( !reset_b ) 
      mreq_b_q = 1'b1;
    else 
      mreq_b_q = mreq_b;
  
  always @ (negedge mreq_b ) 
    if ( !reset_b ) 
      adr15_q <= 1'b0;
    else
      adr15_q <= adr15;

  // Latch DIP switch settings on reset - need a CPC power down/up.
  always @ ( * )
    if ( !reset_b ) 
      dip_q <= { ramadrhi[4:3], dip[1:0] } ;
  
  always @ ( * )
    if ( clk ) 
      clken_lat_qb <= !(!iorq_b && !wr_b && !adr15 && data[6] && data[7]);
  
  // Pre-decode mode 3 setting and noodle shadow bank alias if required to save decode
  // time after the Q
  always @ (posedge wclk )
    if (!reset_b) begin
      ramblock_q <= 6'b0;
      mode3_q <= 1'b0;
    end        
    else begin
      if ( shadow_mode && (data[5:3]==shadow_bank) )
        ramblock_q <= {data[5:4],1'b0, data[2:0]};          
      else
        ramblock_q <= data[5:0] ;
      mode3_q <= (data[2:0] == 3'b011);
    end
  
  always @ ( * ) begin
    if ( shadow_mode )
      // FULL SHADOW MODE    - all CPU read accesses come from external memory (ramcs_b_r computed here is ignored)            
      // PARTIAL SHADOW MODE - all CPU write accesses go to shadow memory but only shadow block 3 is ever read in mode C3 at bank 0x4000 (remapped to 0xC000)
`ifdef FULL_SHADOW_ONLY
      // ramcs_b_r never used in this mode
      begin
        ramcs_b_r = 1'bx;        
	case (ramblock_q[2:0])
	  3'b000: {exp_ram_r, ramadrhi_r} = { 1'b0, shadow_bank, adr15,adr14 };
	  3'b001: {exp_ram_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b1, ramblock_q[5:3],2'b11} : { 1'b0, shadow_bank, adr15,adr14 };
	  3'b010: {exp_ram_r, ramadrhi_r} = { 1'b1, ramblock_q[5:3], adr15,adr14} ; 
	  3'b011: {exp_ram_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {1'b1,ramblock_q[5:3],2'b11} : ({adr15_q,adr14}==2'b01) ? {1'b0,shadow_bank,2'b11} : { 1'b0, shadow_bank, adr15,adr14 };
	  3'b100: {exp_ram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],2'b00} : { 1'b0, shadow_bank, adr15, adr14 };              
	  3'b101: {exp_ram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],2'b01} : { 1'b0, shadow_bank, adr15, adr14 };              
	  3'b110: {exp_ram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],2'b10} : { 1'b0, shadow_bank, adr15, adr14 };              
	  3'b111: {exp_ram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],2'b11} : { 1'b0, shadow_bank, adr15, adr14 };
	endcase // case (ramblock_q[2:0])
      end
`else      
      case (ramblock_q[2:0])
 	3'b000: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b001: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {2'b10, ramblock_q[5:3],2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b010: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 2'b10, ramblock_q[5:3], adr15,adr14} ; 
 	3'b011: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {2'b10,ramblock_q[5:3],2'b11} : ({adr15_q,adr14}==2'b01) ? {2'b00,shadow_bank,2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b100: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b00} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };              
 	3'b101: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b01} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };              
 	3'b110: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b10} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };              
 	3'b111: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };
      endcase // case (ramblock_q[2:0])
`endif    
    else
      // 6128 mode. In 464 mode (ie overdrive ON but no shadow memory) means that C3 is not fully supported for FutureOS etc, but other modes are ok
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
  
endmodule
