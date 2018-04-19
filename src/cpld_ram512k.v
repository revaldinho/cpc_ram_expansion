
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

module cpld_ram512k(busreset_b,adr15,adr14,iorq_b,mreq_b,ramrd_b,reset_b,wr_b,rd_b,data,ramdis,ramcs_b,ramadrhi,ready, clk, ramoe_b, ramwe_b);
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
   
   output	    ramdis;
   output	    ramcs_b;
   output [4:0]     ramadrhi;
   output           ramoe_b;
   output           ramwe_b;
   
   reg [5:0]        ramblock_q;
   reg [4:0]        ramadrhi_r;
   reg		    ramcs_b_r;
   
   reg              clken_lat_qb;
   
   // Create clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
   // but if the pulse is allowed through use the trailing (rising) edge to capture data
   wire             wclk    = (clk|clken_lat_qb); 
   
   // Combination of RAMCS and RAMRD determine whether RAM output is enabled
   assign ramoe_b = ramrd_b;		
   assign ramwe_b = wr_b | mreq_b;     
   assign ramcs_b = ramcs_b_r;
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
   
   always @ (ramblock_q, adr15, adr14 )
     case (ramblock_q[2:0])
       3'b000: {ramcs_b_r, ramadrhi_r} = { 1'b1, 5'bx };               
       3'b001: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],{1'b1,ramblock_q[0]}} : {1'b1, 5'bx} ; 
       3'b010: {ramcs_b_r, ramadrhi_r} = { 1'b0,ramblock_q[5:3],adr15,adr14} ;    
       3'b011: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ; 
       3'b100: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ; 
       3'b101: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ; 
       3'b110: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ; 
       3'b111: {ramcs_b_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ; 
     endcase
   
endmodule


