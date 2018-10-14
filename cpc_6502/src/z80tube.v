module z80tube(
               // Host
               input         CLK,
               input [15:0]  ADR,
               input         RD_B,
               input         WR_B, 
               input         IOREQ_B,
               input         M1_B, 
               input         MREQ_B,
               input         WAIT_B,
               input         RESET_B,
               inout [7:0]   DATA,
               inout         NMI_B, 
               inout         INT_B,
               
               // Tube	
               input         TUBE_INT_B,
               
               inout [7:0]   TUBE_DATA,
               
               output [15:0] TUBE_ADR,
               output        TUBE_RNW_B,
               output        TUBE_PHI2,
               output        TUBE_CS_B
               );	

//      IDLE  .  S0     .   S0    .   S1    .    S2   .  IDLE  (negedge state)
//        ____      ____      ____      ____      ____      __
// CLK        \____/    \____/    \____/    \____/    \____/  
//      _ ________________________________________ ___________
// ADR  _X________________________________________X___________
//      _____                                 ________________
// IORQ*     \_______________________________/
//      _____                                _________________
// WR*       \______________________________/
//      _____________           ______________________________
// WAIT*     \_______\_________/                               Sampled on falling CLK by CPU
//                                 ______________
// DATA --------------------------X______________X----------
//                 :         :         :         :         :
//            .    :    .    :    .    :    .    :    .    :
//                       ___________________
// negen_f_q ___________/                   \_________________
//                            ___________________
// posen_f_q ________________/                   \____________
//                       ________________________
// phi2  _______________/                        \____________ 
//       _____                                 _______________
// CS*        \_______________________________/                Must assert in PHI1
//      __ _______________________________________ __________
// ADR  __X_______________________________________X__________ Pass-through of CPU ADR bus
//      ______                               ________________
// RnW*       \_____________________________/                 = (IORQ* | WR* ) 
//                                 ______________
// DATA --------------------------X______________X------------ 
//
    
    
  parameter IDLE=0,S0=1,S1=2,S2=3,S3=4;
  
  reg                 posen_q;
  reg                 negen_f_q;
  reg [2:0]           state_f_q;
  reg [2:0]           state_d;    
  reg                 wr_b_q;
  reg                 wait_f_q;	
  reg [7:0]           status_q;
  reg [7:0]           data_r;
  reg                 data_en_r;
  reg                 clken_lat_b_q;
  reg [1:0]           reset_b_q;
   
  wire                tube_chip_select ;
  wire                status_reg_select ;  
  wire                wclk;
  wire                reset_b_w;
               
  assign status_reg_select    =  ( ADR == 16'hFFF9 ) ; 
  assign tube_chip_select =  ( ADR[15:4] == 12'hFA8 ) ; 
  
  // TUBE
  assign TUBE_CS_B = !(!IOREQ_B & tube_chip_select);
  assign TUBE_PHI2 = negen_f_q | posen_q;
  assign TUBE_ADR = ADR;
  assign TUBE_RNW_B = IOREQ_B | WR_B;
  assign TUBE_DATA = ( !wr_b_q & ((state_f_q==S1)|(state_f_q==S2)) & posen_q ) ? DATA : 8'bz;
  
  // MASTER - drive databus on reads
  assign DATA = ( data_en_r ) ? data_r : 8'bzzzzzzzz ;
  assign NMI = 1'bz;
  assign INT = 1'bz;
  
  // Synchronized reset release to posedge of clock
  assign reset_b_w = RESET_B & reset_b_q[0];
 
  always @ ( negedge CLK )
    case (state_f_q)
      IDLE:  state_d = ( !IOREQ_B) ? S0 : IDLE ;
      S0  :  state_d = (!WAIT_B) ? S1 : S0;
      S1  :  state_d = S2;
      S2  :  state_d = IDLE;
      default: state_d = IDLE;
    endcase	

  // PHI2 high must be glitchless - create it from just two FFs on clk/clkbar
  always @ (negedge CLK ) begin
    if ( state_f_q==S0 )
      negen_f_q = 1'b1;
    else if ( state_f_q==S1)
      negen_f_q = 1'b0;                        
  end
  
  always @ (posedge CLK ) begin
    posen_q <= negen_f_q;
    wr_b_q   = WR_B;
    reset_b_q <= {RESET_B, reset_b_q[1]};    
  end

  // Data mux to service IO Reads by the CPC Z80 Host
  always @ ( * ) begin
    if ( !IOREQ_B & !RD_B) begin
      if ( status_reg_select )
        { data_en_r, data_r } = { 1'b1, status_q }   ; 
      else if ( tube_chip_select )
        { data_en_r, data_r } = { 1'b1, TUBE_DATA }   ;
      else
        { data_en_r, data_r } = { 1'b0, 8'bx } ;
    end  
    else
        { data_en_r, data_r } = { 1'b0, 8'bx } ;              
  end // always @ ( * )  
    
  // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  assign wclk    = !(CLK|clken_lat_b_q);
           
  always @ ( * )
    if ( CLK ) 
      clken_lat_b_q <= !(!IOREQ_B && !WR_B && status_reg_select );

  always @ (posedge wclk )
    if (!reset_b_w)
      status_q <= 8'b0;
    else
      status_q <= DATA[7:0];
  
endmodule
