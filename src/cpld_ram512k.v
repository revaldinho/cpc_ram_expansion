
/* cpld_ram512K
 *
 * CPLD module to implement all logic for an Amstrad CPC 512K RAM extension card
 *
 * (c) 2018, Revaldinho
 *
 *  ---------+                                             +----------------+
 *   C P C   |                                             |   S R A M      |
 *       we* |------------*--------------------------------| wr*            |
 *    ramrd* |-----------*|--------------------------------| oe*            |
 *  adr[13:0]|===========||================================| adr[13:0]      |
 *  data[7:0]|==========*||================================| data[7:0]      |
 *           |          ||| +-------------------------+    |                |
 *           |          ||| |       C P L D           |    |                |
 *           |          ||`-| wr_b            ramadrhi|====| adr[18:14]     |
 *           |          |`--| ramrd_b          ramcs_b|----| cs*            |
 *           |          `===| datain[7:0]             |    |                |
 *     ioreq*|--------------| iorq_b                  |    +----------------+
 *      mreq*|--------------| mreq_b                  |
 * adr[15:14]|==============| adr15, adr14            |
 *           |              |                         |
 *    ramdis |--------------| ramdis                  |
 *    reset* |--------------| reset_b                 |
 *           |              +-------------------------+
 * ----------+
 *
 * Notes:
 * - we*, rd* connected directly to RAM, control provided via cs* pin from CPLD
 * - diode on RAMDIS forms wired OR with pull-down on CPC motherboard only if
 *   a ramdis is made a non-tristate output in the CPLD (and equivalent 74
 *   series implementation)
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
module cpld_ram512k(
                    adr15,
                    adr14,
                    clk,
                    ready,
                    iorq_b,
                    mreq_b,
                    ramrd_b,
                    reset_b,
                    wr_b,
                    rd_b,                    
                    data,
                    ramdis,
                    ramcs_b,
                    ramadrhi
                    );

  
    input           adr15;
    input           adr14;
    input           iorq_b;
    input           mreq_b;
    input           ramrd_b;
    input 	    reset_b;
    input           clk;
    input           ready;    
    input           wr_b;
    input           rd_b;  
    input [7:0]     data;

    output	    ramdis;
    output	    ramcs_b;
    output [4:0]    ramadrhi;

    reg [5:0]       ramblock_q;
    reg [4:0]	    ramadrhi_r;
    reg		    notextram_r;

    wire blocksel_w = (!iorq_b && !wr_b && !adr15 && data[7] && data[6] ) ;
    assign ramadrhi = ramadrhi_r ;
    assign ramcs_b  = notextram_r | mreq_b ;        // Select RAM for all memory accesses (write and read) with valid bank num
    assign ramdis   = ( !(notextram_r | mreq_b) ) ; // Disable internal RAM for all memory accesses (write and read) with valid bank num

    always @ (negedge reset_b or posedge blocksel_w )
        if (!reset_b)
            ramblock_q <= 5'b0;
        else
            ramblock_q <= data[5:0];

    always @ (ramblock_q, adr15, adr14 )
        case (ramblock_q[2:0])
            3'b000: {notextram_r, ramadrhi_r} = { 1'b1, 5'bx };
            3'b001: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : {1'b1, 5'bx} ;
            3'b010: {notextram_r, ramadrhi_r} = { 1'b0,ramblock_q[5:3],adr15,adr14} ;
            3'b011: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b0,ramblock_q[5:3],2'b11} : {1'b1, 5'bx} ;
            3'b100: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ;
            3'b101: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ;
            3'b110: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ;
            3'b111: {notextram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b0,ramblock_q[5:3],ramblock_q[1:0]} : {1'b1, 5'bx} ;
            default: {notextram_r, ramadrhi_r} = { 1'bx, 5'bx };
        endcase
endmodule
