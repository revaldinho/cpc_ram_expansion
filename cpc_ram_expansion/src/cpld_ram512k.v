
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

`define DEFAULT_BANK 3'b011

//`define one of these only
`define X64   1
//`define X128  1
//`define UNIV    1


module cpld_ram512k(busreset_b,adr15,adr14,iorq_b,mreq_b,ramrd_b,reset_b,wr_b,rd_b,data,ramdis,ramcs_b,ramadrhi,ready, clk, ramoe_b, ramwe_b
`ifdef UNIV
,mode464
`endif

);
   input            busreset_b;
   input            adr15;    
   input            adr14;
   input            iorq_b;
   input            mreq_b;
   input            ramrd_b;
   input 	    reset_b;
   input            wr_b;
   input            rd_b;    
   input [7:0]      data;
   input	    ready;
   input 	    clk;

`ifdef UNIV    
    input 	    mode464;
`endif

   output	    ramdis;
   output	    ramcs_b;
   output [4:0]     ramadrhi;
   output           ramoe_b;
   output           ramwe_b;
   reg [5:0]        ramblock_q;
   reg [4:0]        ramadrhi_r;
   reg		    ramcs_b_r;
   reg              clken_lat_qb;
   reg [5:0]        hibit_tmp_r;
  
   // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
   // but if the pulse is allowed through use the trailing (rising) edge to capture data
   wire             wclk    = !(clk|clken_lat_qb); 
   // Combination of RAMCS and RAMRD determine whether RAM output is enabled
   assign ramoe_b = ramrd_b;		
   assign ramwe_b = wr_b ;     
   assign ramcs_b = ramcs_b_r | mreq_b;
   assign ramdis  = !ramcs_b_r;    
   assign ramadrhi = ramadrhi_r ;        
   always @ ( clk )
     if ( clk )
       clken_lat_qb <= !(!iorq_b && !wr_b && !adr15 && data[6] && data[7]);
   always @ (negedge reset_b or posedge wclk )
     if (!reset_b)
       ramblock_q <= 6'b0;
     else
       ramblock_q <= data[5:0];

`ifdef X64
  wire              mode464 = 1'b1;  
`endif    
    
        
`ifndef X128
   always @ (ramblock_q, adr15, adr14 )
     begin
       hibit_tmp_r = ramblock_q;
       // pretend some banks aren't present and are aliased to others
       if (ramblock_q[5:3] == 3'b011 )
         hibit_tmp_r[5:3] = 3'b010;         
       case (hibit_tmp_r[2:0])
	  3'b000: {ramcs_b_r, ramadrhi_r} = { !mode464, `DEFAULT_BANK, adr15, adr14 };
	  3'b001: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,hibit_tmp_r[5:3],2'b11} : { !mode464, `DEFAULT_BANK, adr15, adr14 };
	  3'b010: {ramcs_b_r, ramadrhi_r} = { 1'b0,hibit_tmp_r[5:3],adr15,adr14} ; 
	  // Mode 3: Map 0b1100 to New 0b1100 _and_ 0b0100 to 0b1100 but in 'default' bank only (can't affect internal RAM without backdriving ADR15)
	  3'b011: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,hibit_tmp_r[5:3],2'b11} : {!mode464, `DEFAULT_BANK, (adr15|adr14), adr14 };
	  3'b100: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],hibit_tmp_r[1:0]} : {!mode464, `DEFAULT_BANK, adr15, adr14 };              
	  3'b101: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],hibit_tmp_r[1:0]} : {!mode464, `DEFAULT_BANK, adr15, adr14 };              
	  3'b110: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],hibit_tmp_r[1:0]} : {!mode464, `DEFAULT_BANK, adr15, adr14 };              
	  3'b111: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],hibit_tmp_r[1:0]} : {!mode464, `DEFAULT_BANK, adr15, adr14 };
       endcase // case (hibit_tmp_r[2:0])
     end // always @ (hibit_tmp_r, adr15, adr14 )
`else
    always @ (ramblock_q, adr15, adr14 )
     begin
       case (ramblock_q[2:0])
	   3'b000: {ramcs_b_r, ramadrhi_r} = { 1'b1, 5'bxxxxx };
	   3'b001: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : { 1'b1, 5'bxxxxx};
	   3'b010: {ramcs_b_r, ramadrhi_r} = { 1'b0,ramblock_q[5:3],adr15,adr14} ; 
	   3'b011: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : {1'b1, 5'bxxxxx };
	   3'b100: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bxxxxx };              
	   3'b101: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bxxxxx };              
	   3'b110: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bxxxxx };              
	   3'b111: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bxxxxx };
       endcase // case (ramblock_q[2:0])
     end // always @ (ramblock_q, adr15, adr14 )    
`endif
    
endmodule
