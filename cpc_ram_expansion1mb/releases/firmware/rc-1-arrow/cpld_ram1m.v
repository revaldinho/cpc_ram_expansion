/*
 * This code is part of the cpc_ram_expansion set of Amstrad CPC peripherals.
 * https://github.com/revaldinho/cpc_ram_expansion
 *
 * Copyright (C) 2018,2019 Revaldinho
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
/*
 * Crib
 * 1. Keeping a net in synthesis
 * //synthesis attribute keep of input_a_reg is "true"
 * BUF mybuf (.I(input_a_reg),.O(comb));
 *
 */

`define FIT_XC9536 1

`ifdef FIT_XC9536
  // Disable resynchronisation of reset
  `define DISABLE_RESET_RESYNC 1
  `define FULL_SHADOW_ONLY 1
`endif


module cpld_ram1m(
  input        rfsh_b,
  inout        adr15,
  inout        adr15_aux,
  input        adr14,
  input        adr8,
  input        iorq_b,
  input        mreq_b,
  input        reset_b,
  inout        wr_b,
  inout        rd_b,
  input [7:0]  data,
  input        clk,
  input [3:0]  dip,
  input        ramrd_b,
  inout        ramdis,
  output       ramcs0_b,
  output       ramcs1_b,                  
  inout [4:0]  ramadrhi, // bits 4,3 also connected to DIP switches 2,1 resp and read on startup
  output       ramoe_b,
  output       ramwe_b
);

  reg [5:0]        ramblock_q;
  reg [4:0]        ramadrhi_r;
  reg              low_not_high_ram_q;    
  wire             cardsel_w;  
  reg              mode3_q;
  reg              mwr_cyc_q;
  reg              mwr_cyc_f_q;
  reg              ramcs_b_r;
  reg              adr15_q;
  reg              exp_ram_r;
`ifndef DISABLE_RESET_RESYNC 
  reg              reset_b_q;
  reg              reset1_b_q;
`endif
  reg              exp_ram_q;
  reg 	           urom_disable_q;
  reg 	           lrom_disable_q;
  reg              int_ramrd_r ;    // compute local ramrd signal rather than wait on one from ULA

  wire             ram_ctrl_select_w;
  wire             rom_ctrl_select_w;
  wire [2:0]       shadow_bank;
  wire             full_shadow;
  wire             overdrive_mode;
  wire             mwr_cyc_d;
  wire             adr15_overdrive_w;
  wire             ram64kb_mode;  
  wire             ram1mb_mode;            
  wire             reset_b_w;
  wire             shadow_write;
  

  /*
   * DIP Switch Settings
   * ===================
   * 
   * NB DIPs are numbered 1-4 on the physical component and in the table  here, but 0..3 in Verilog
   * 
   * ---------+----------------------------------------- 
   * DIP1 DIP2|  Mode selection
   * ---------+----------------------------------------- 
   *  OFF  OFF|  6128 Mode
   *  OFF   ON|  DK'Tronics Mode
   *   ON  OFF|  Shadow mode
   *   ON   ON|  Full shadow mode
   * ---------+-----------------------------------------
   * DIP3 DIP4|  RAM size selection
   * ---------+-----------------------------------------
   *  OFF OFF |  Card Disabled     
   * ---------+-----------------------------------------
   *  OFF  ON |  64K mode (Max 6128 compatibility)
   *   ON OFF |  512K Mode
   *   ON  ON |  1MB mode
   * ---------+-----------------------------------------
   */

  assign overdrive_mode= dip[0] | dip[1];
`ifdef FULL_SHADOW_ONLY
  assign full_shadow   = dip[1] | dip[0];  
`else  
  assign full_shadow   = dip[1] & dip[0];
`endif  
  assign shadow_mode   = dip[1] | dip[0];
  assign shadow_bank   = {3'b111};  // Shadow bank always high bank in 7FFE RAM (SRAM0)
  assign ram64kb_mode  = !dip[2] & dip[3];
  assign ram1mb_mode   = dip[2] & dip[3];  
  assign cardsel_w     = dip[2] | dip[3];
  
  
  // Dont drive address outputs during reset due to overlay of DIP switches
  assign ramadrhi =  ( !reset_b_w ) ? 5'bzzzzz : ramadrhi_r[4:0];
  assign ram_ctrl_select_w = (!iorq_b && !wr_b && !adr15 && data[6] && data[7] );
  assign rom_ctrl_select_w = (!iorq_b && !wr_b && !adr15 && !data[6] && data[7] );

`ifdef DISABLE_RESET_RESYNC
  assign reset_b_w = reset_b;  
`else
  assign reset_b_w = reset1_b_q & reset_b & reset_b_q;
`endif
  
  // NB mode 3 DK'T 0x4000 -> remapped to 0xC000, wil
  // l overlap ROM - so check adr15 and overdrive state
  always @ ( * ) begin
    int_ramrd_r = 1'b0 ; 	 // default disable RAM accesses
    if ( rfsh_b & !mreq_b )
      if ( (adr15_q|adr15_overdrive_w) != adr14 )
        int_ramrd_r = 1'b1; // RAM in range 0x4000 - 0xBFFF never overlapped by ROM
      else if ( urom_disable_q & ( {(adr15_q|adr15_overdrive_w),adr14} == 2'b11 ))
        int_ramrd_r = 1'b1; // RAM read in 0xC000 - 0xFFFF only if UROM disabled
      else if ( lrom_disable_q & ( {(adr15_q|adr15_overdrive_w),adr14} == 2'b00 ))
        int_ramrd_r = 1'b1; // RAM read in 0x0000 - 0x3FFF only if LROM disabled
  end

  // Remember that wr_b is overdrive for first high phase of clock for M4 compatibility so don't write ;
  assign ramwe_b = ! ( !wr_b & mwr_cyc_q & mwr_cyc_f_q );
  assign ramoe_b = (!int_ramrd_r) | rd_b ;
  
//  assign ramoe_b = ramrd_b ;

  /* Memory Data Access
   *          ____      ____      ____      ____      ____
   * CLK     /    \____/    \____/    \____/    \____/    \_
   *         _____     :    .    :    .    :    .   ________
   * MREQ*        \________________________________/ :    .
   *         _______________________________________________
   * RFSH*   1         :    .    :    .    :    .    :    .
   *         _________________   :    .    :    .  _________
   * WR*               :    . \___________________/  :    .
   *         _____________       ___________________________
   * READY             :  \_____/
   *                   :    .    :    .    :    .    :    .
   *                   :_____________________________:    .
   * MWR_CYC    _______/    .    :    .    :    .    \______  FF'd Version
   * State    _IDLE____X___T1____X____T1___X___T2____X_END__
   */


  // M4 Compatibility: overdrive wr_b for the first high phase of CLK 
  // of an expansion RAM write to fool the M4 card
  assign wr_b = ( overdrive_mode & exp_ram_q & (mwr_cyc_q & !mwr_cyc_f_q)) ? 1'b0 : 1'bz;

  assign rd_b = ( overdrive_mode & exp_ram_q & (mwr_cyc_q|mwr_cyc_f_q)) ? 1'b0 : 1'bz ;

  // Overdrive A15 for writes only in shadow modes (full and partial) but for all 
  // access types otherwise. Need to compute whether A15 will need to be driven 
  // before the first rising edge of the MREQ cycle for the gate array to act on 
  // it. Cant wait to sample mwr_cyc_q after it has been set initially.
  assign mwr_cyc_d = !mreq_b & rd_b;
  assign adr15_overdrive_w = overdrive_mode & mode3_q & adr14 & ((shadow_mode) ? (mwr_cyc_q|mwr_cyc_d): !mreq_b) ;
  assign { adr15, adr15_aux} = (adr15_overdrive_w  ) ? 2'b11 : 2'bzz;
  assign shadow_write = shadow_mode & !exp_ram_r &  mwr_cyc_q; 
  
`ifdef FULL_SHADOW_ONLY
  // Never, ever use internal RAM for reads in full shadow mode 
  assign ramdis = (shadow_mode & cardsel_w)? 1'b1 : 1'bz;
  assign shadow_read  = shadow_mode & !exp_ram_r & !mwr_cyc_q;  // All non-exp RAM reads are serviced from Shadow RAM
`else
  // Never, ever use internal RAM for reads in full shadow mode 
  assign ramdis = (cardsel_w & (full_shadow | !ramcs_b_r)) ? 1'b1 : 1'bz;  
  assign shadow_read  = shadow_mode & !exp_ram_r & !mwr_cyc_q & (full_shadow|(mode3_q&{adr15_q,adr14}==2'b01));
`endif

  // Low RAM is enabled for all shadow writes, shadow reads and when selected by 0x7Fex  
  assign ramcs0_b = !( (!ramcs_b_r) & cardsel_w & (low_not_high_ram_q | (shadow_read|shadow_write))) | mreq_b | !rfsh_b ;
  // High RAM is enabled only for expansion RAM accesses
  // assign ramcs1_b = !( (!ramcs_b_r) & cardsel_w & !low_not_high_ram_q & !shadow_read) | mreq_b | !rfsh_b ;
  assign ramcs1_b = !( (!ramcs_b_r) & cardsel_w & !low_not_high_ram_q & exp_ram_r) | mreq_b | !rfsh_b ;  
  
  always @ (posedge clk)
    if ( mwr_cyc_d )
      mwr_cyc_q <= 1'b1;
    else if (mreq_b)
      mwr_cyc_q <= 1'b0;

  always @ (negedge clk or negedge reset_b_w)
    if ( !reset_b_w )
      mwr_cyc_f_q <= 1'b0;
    else
      mwr_cyc_f_q <= mwr_cyc_q;

  always @ (posedge clk or negedge reset_b_w)
     if ( !reset_b_w ) begin
      exp_ram_q = 1'b0;
    end
    else begin
      exp_ram_q = exp_ram_r;
    end

`ifndef DISABLE_RESET_RESYNC
   always @ (posedge clk or negedge reset_b)
     if ( !reset_b )
       {reset1_b_q, reset_b_q}  = 2'b00;
     else
       {reset1_b_q, reset_b_q}  = {reset_b_q, reset_b};
`endif
  
  always @ (negedge clk or negedge reset_b_w )
    if ( !reset_b_w )
      adr15_q <= 1'b0;
    else
      adr15_q <= (mreq_b) ? adr15 : adr15_q;

  // Pre-decode mode 3 setting and <noodle shadow bank alias if required to save decode
  // time after the Q
  always @ (negedge clk or negedge reset_b_w)
    if (!reset_b_w) begin
      ramblock_q <= 6'b0;
      mode3_q <= 1'b0;
      low_not_high_ram_q <= 1'b0;      
      urom_disable_q <= 1'b0;
      lrom_disable_q <= 1'b0;
    end
    else begin
       if ( ram_ctrl_select_w ) begin
         // In 64KB mode force all expansion accesses to bank 0 of upper RAM
         // In shadow mode any accesses to the (always odd) shadow bank get aliassed to the even bank below
         if ( shadow_mode && (data[5:3]==shadow_bank) )
           ramblock_q <= {((ram64kb_mode)?2'b0:data[5:4]),1'b0, data[2:0]};
         else
           ramblock_q <= (ram64kb_mode)?3'b0:data[5:3];
         // Use IO Port 7Fxx or 7Exx depending on ram1mb_mode
         low_not_high_ram_q <= (ram1mb_mode)? !adr8: 1'b0;  // 7Exx goes to low RAM, 7Fxx everywhere else, disable low ram in 64K/512KB mode
         mode3_q <= (data[2:0] == 3'b011);
       end
       else if ( rom_ctrl_select_w ) begin
          { urom_disable_q, lrom_disable_q } <= data[3:2];
       end
    end

  always @ ( * ) begin
    if ( shadow_mode )
      // FULL SHADOW MODE    - all CPU read accesses come from external memory (ramcs_b_r computed here is ignored)
      // PARTIAL SHADOW MODE - all CPU write accesses go to shadow memory but only shadow block 3 is ever read in mode C3 at bank 0x4000 (remapped to 0xC000)
      case (ramblock_q[2:0])
 	3'b000: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b001: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {2'b10, ramblock_q[5:3],2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b010: {exp_ram_r, ramcs_b_r, ramadrhi_r} = { 2'b10, ramblock_q[5:3], adr15,adr14} ;
 	3'b011: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14}==2'b11 ) ? {2'b10,ramblock_q[5:3],2'b11} : ({adr15_q,adr14}==2'b01) ? {2'b00,shadow_bank,2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15,adr14 };
 	3'b100: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b00} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };
 	3'b101: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b01} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };
 	3'b110: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b10} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };
 	3'b111: {exp_ram_r, ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {2'b10,ramblock_q[5:3],2'b11} : { 1'b0, !mwr_cyc_q , shadow_bank, adr15, adr14 };
      endcase
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
