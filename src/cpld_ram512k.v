module cpld_ram512k(
            adr15,
            adr14,
            iorq_b,
            mreq_b,
            ramrd_b,
            reset_b,
            wr_b,
            
            datain,
            
            ramdis,
            ramcs_b,
            ramoe_b,
            ramwe_b,                
            ramadrhi            
            );
    input            adr15;
    input            adr14;
    input            iorq_b;
    input            mreq_b;
    input            ramrd_b;
    input            reset_b;
    input            wr_b;
    input[7:0]       datain; 

`ifdef TRISTATERAMDIS
    inout           ramdis;    
`else    
    output          ramdis;
`endif
    
    output          ramcs_b;
    output          ramoe_b;
    output          ramwe_b;            
    output [4:0]    ramadrhi;

    reg [5:0]       ramblock_q;
    reg [4:0]       ramadrhi_r;
    reg             extram_r;
    
    wire ramrd_w = extram_r & !ramrd_b;
    wire ramwr_w = extram_r && (!wr_b) && (!mreq_b);
    wire blocksel_w  = (!iorq_b && !wr_b && !adr15 && datain[7] && datain[6] ) ;  
        
    assign ramcs_b  = !(ramrd_w | ramwr_w) ;
    assign ramoe_b  = !ramrd_w ;
`ifdef TRISTATERAMDIS    
    assign ramdis   = (ramrd_w) ? 1'b1 : 1'bz;
`else    
    assign ramdis   = ramrd_w ;
`endif    
    assign ramwe_b  = !ramwr_w ;
    assign ramadrhi = ramadrhi_r ;
                  
    always @ (negedge reset_b or posedge blocksel_w )
        if (!reset_b)
            ramblock_q <= 5'b0;
        else
            ramblock_q <= datain[5:0];

    // -------------------------------------------------------------------------------------------------------------------------------
    //
    // ccc - picks one of 8 possible 64K banks
    // bbb - selects a block switching scheme within the chosen bank
    //       the actual block used for a RAM access is then selected by the top 2 addr bits for that access.
    //
    //     
    // 128K RAM Expansion Mapping Example...
    //
    // In the table below '-' indicates use of CPC internal RAM rather than the RAM expansion
    // -------------------------------------------------------------------------------------------------------------------------------
    // Address\cccbbb 000000 000001 000010 000011 000100 000101 000110 000011 001000 001001 001010 001011 001100 001101 001110 001111 
    // -------------------------------------------------------------------------------------------------------------------------------
    // 1100-1111       -       3      3      3      -      -      -      -      -      7       7      7     -      -      -      -    
    // 1000-1011       -       -      2      -      -      -      -      -      -      -       6      -     -      -      -      -    
    // 0100-0111       -       -      1      -      0      1       2      3     -      -       5      -     4      5      6      7    
    // 0000-0011       -       -      0      -      -      -      -      -      -      -       4      -     -      -      -      -    
    // -------------------------------------------------------------------------------------------------------------------------------
       
    always @ (ramblock_q, adr15, adr14 )
        begin   
            case (ramblock_q[2:0])
                3'b000: {extram_r, ramadrhi_r} = { 1'b0, 5'bx };
                3'b001: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b1,ramblock_q[5:3],2'b11} : {1'b0, 5'bx} ; 
                3'b010: {extram_r, ramadrhi_r} = { 1'b1,ramblock_q[5:3],adr15,adr14} ;    
                3'b011: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b11 ) ? {1'b1,ramblock_q[5:3],ramblock_q[1:0]} : {1'b0, 5'bx} ; 
                3'b100: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],ramblock_q[1:0]} : {1'b0, 5'bx} ; 
                3'b101: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],ramblock_q[1:0]} : {1'b0, 5'bx} ; 
                3'b110: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],ramblock_q[1:0]} : {1'b0, 5'bx} ; 
                3'b111: {extram_r, ramadrhi_r} = ( {adr15,adr14}==2'b01 ) ? {1'b1,ramblock_q[5:3],ramblock_q[1:0]} : {1'b0, 5'bx} ; 
                default: {extram_r, ramadrhi_r} = { 1'b0, 5'bx };
            endcase
        end
endmodule
