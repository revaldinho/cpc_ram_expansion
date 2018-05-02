module cpld_fourrom(dip, reset_b,adr15,adr14,adr13,ioreq_b,mreq_b,romen_b,wr_b,rd_b,data,romdis,rom01cs_b,rom23cs_b, clk, romoe_b, skt01p27, skt23p27, roma14);


  input [7:0] dip;  
  input reset_b;
  input adr15;
  input adr14;
  input adr13;
  input ioreq_b;
  input mreq_b;
  input romen_b;
  input wr_b;
  input rd_b;
  input [7:0] data;
  input  clk;
  output romdis;
  output rom01cs_b;
  output rom23cs_b;
  output romoe_b;
  output skt01p27;
  output skt23p27;
  output roma14;
   
  
  reg       clken_lat_qb;
  reg [7:0] romsel_q;
  reg [3:0] rom16k_cs_r ;

  assign rom01cs_b = !(rom16k_cs_r[0] | rom16k_cs_r[1]) ;
  assign rom23cs_b = !(rom16k_cs_r[2] | rom16k_cs_r[3]) ;
  assign roma14    =   rom16k_cs_r[1] | rom16k_cs_r[3];

  assign skt01p27  = (!dip[6])?1'b1: roma14; 
  assign skt23p27  = (!dip[7])?1'b1: roma14; 

  assign romoe_b  = romen_b;
  assign romdis = | rom16k_cs_r ;

  // DIP switches and numbered 1-8 on the board, but 0-7 in the Verilog code  
  // DIP 0 = enable lower ROM SKT01
  // DIP 1 = enable upper ROM SKT01
  // DIP 2 = enable lower ROM SKT23    
  // DIP 3 = enable upper ROM SKT23
  // DIP 54 =  00 : LOW ROM + ROMS 0-2
  // DIP 54 =  01 : ROMS 3-6
  // DIP 54 =  10 : ROMS 8-11
  // DIP 54 =  11 : ROMS 12-15
  // DIP 6  = select 32K EPROM in Skt01 - Care will wipe EEPROM if present 
  // DIP 7  = select 32K EPROM in Skt02 - Care will wipe EEPROM if present 
  
  // Create neg edge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire      wclk    = !(clk|clken_lat_qb); 

  always @ ( clk )
    if ( clk )
      clken_lat_qb <= !(!ioreq_b && !wr_b && !adr13);

   
  always @ (negedge reset_b or posedge wclk )
    if ( !reset_b)
      romsel_q <= 8'b0;
    else
      romsel_q <= data; 

  always @ ( * ) 
    begin
      rom16k_cs_r = 4'b0;
      
      if (!adr14)
        rom16k_cs_r[0] = ( dip[0] & (dip[5:4]==2'b0));
      else
        if ( dip[5:4]== 2'h0 ) begin
          rom16k_cs_r[0] = 1'b0;          
          rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'h0 ) ;
          rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'h1 ) ;
          rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'h2 ) ;
        end
        else if ( dip[5:4]== 2'h1 ) begin
          rom16k_cs_r[0] = dip[0] & ( romsel_q == 8'h3 ) ;
          rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'h4 ) ;
          rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'h5 ) ;
          rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'h6 ) ;
        end
        else if ( dip[5:4]== 2'h2 ) begin
          rom16k_cs_r[0] = dip[0] & ( romsel_q == 8'h8 ) ;
          rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'h9 ) ;
          rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'hA ) ;
          rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'hB ) ;
        end
        else if ( dip[5:4]== 2'h3 ) begin
          rom16k_cs_r[0] = dip[0] & ( romsel_q == 8'hC ) ;
          rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'hD ) ;
          rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'hE ) ;
          rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'hF ) ;
        end
    end // always @ ( * )
  
          
  
endmodule


