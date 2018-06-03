module cpld_sixrom(dip, reset_b,adr15,adr14,adr13,ioreq_b,mreq_b,romen_b,wr_b,rd_b,data,romdis,rom01cs_b,rom23cs_b, rom45cs_b,  clk, romoe_b, roma14);


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
  output rom45cs_b;  
  output romoe_b;
  output roma14;
   
  
  reg       clken_lat_qb;
  reg [7:0] romsel_q;
  reg [5:0] rom16k_cs_r ;

  assign rom01cs_b = !(rom16k_cs_r[0] | rom16k_cs_r[1]) ;
  assign rom23cs_b = !(rom16k_cs_r[2] | rom16k_cs_r[3]) ;
  assign rom45cs_b = !(rom16k_cs_r[4] | rom16k_cs_r[5]) ;  
  assign roma14    =   rom16k_cs_r[1] | rom16k_cs_r[3] | rom16k_cs_r[5];

  assign romoe_b  = romen_b;
  assign romdis = | rom16k_cs_r ;

  // DIP switches and numbered 1-8 on the board, but 0-7 in the Verilog code  
  // DIP 0 = enable lower ROM SKT01
  // DIP 1 = enable upper ROM SKT01
  // DIP 2 = enable lower ROM SKT23    
  // DIP 3 = enable upper ROM SKT23
  // DIP 4 = enable lower ROM SKT45    
  // DIP 5 = enable upper ROM SKT45
  // DIP 6 =  0 : ROMS 1-6
  //       =  1 : ROMS 9-14
  // DIP 7 = unused.
  
  // Create neg edge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire      wclk    = !(clk|clken_lat_qb); 

  always @ ( clk )
    if ( clk )
      clken_lat_qb <= !(!ioreq_b && !wr_b && !adr13 && adr15 && adr14);

   
  always @ (negedge reset_b or posedge wclk )
    if ( !reset_b)
      romsel_q <= 8'b0;
    else
      romsel_q <= data; 

  always @ ( * ) 
    begin
      rom16k_cs_r = 6'b0;      
      if ( dip[6]== 1'b0 ) begin
        rom16k_cs_r[0] = dip[0] & ( romsel_q == 8'h1 ) ;
        rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'h2 ) ;
        rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'h3 ) ;
        rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'h4 ) ;
        rom16k_cs_r[4] = dip[4] & ( romsel_q == 8'h5 ) ;
        rom16k_cs_r[5] = dip[5] & ( romsel_q == 8'h6 ) ;        
      end
      else begin
        rom16k_cs_r[0] = dip[0] & ( romsel_q == 8'h9 ) ;
        rom16k_cs_r[1] = dip[1] & ( romsel_q == 8'hA ) ;
        rom16k_cs_r[2] = dip[2] & ( romsel_q == 8'hB ) ;
        rom16k_cs_r[3] = dip[3] & ( romsel_q == 8'hC ) ;
        rom16k_cs_r[4] = dip[4] & ( romsel_q == 8'hD ) ;
        rom16k_cs_r[5] = dip[5] & ( romsel_q == 8'hE ) ;                
      end
    end // always @ ( * )
  
          
  
endmodule


