module z80tube(
               // Host
               input CLK,
               input [15:0] ADR,
               input RD_B,
               input WR_B,               
               input IOREQ_B,
               input M1_B,                              
               input MREQ_B,
               input WAIT_B,
               
               inout [7:0] DATA,
               inout NMI_B,               
               inout INT_B,
               
               // Tube	
               input TUBE_INT_B,
               
               inout [7:0] TUBE_DATA,
               
               output [15:0] TUBE_ADR,
               output TUBE_RNW_B,
               output TUBE_PHI2,
               output TUBE_CS_B
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

reg	posen_q;
reg	negen_f_q;
reg [2:0] state_f_q;
reg [2:0] state_d;    
reg     wr_qb;
reg     wait_f_q;	

wire   chip_select ;

assign chip_select =  ( ADR[15:4] = 12'hFA8 ) ; 

// TUBE
assign TUBE_CS_B = !(!IOREQ_B & chip_select);
assign TUBE_PHI2 = negen_f_q | posen_q;
assign TUBE_ADR = ADR;
assign TUBE_RNW_B = IOREQ_B | WR_B;
assign TUBE_DATA = ( !wr_qb & ((state_f_q=S1)|(state_f_q=S2)) & posen_q ) ? DATA : 8'bz;

// MASTER - drive databus on reads
assign DATA = ( !IOREQ_B & chip_select & wr_qb & ((state_f_q=S1) | (state_f_q=S2)) & posen_q)? TUBE_DATA : 8'bz;
assign NMI = 1'bz;
assign INT = 1'bz;
    
always @ ( negedge CLK )
   case (state_f_q)
       IDLE:  state_d = ( !IOREQ_B) ? S0 : IDLE ;
       S0  :  state_d = (!WAIT_B) ? S1 : S0;
       S1  :  state_d = S2;
       S2  :  state_d = IDLE;
       default: state_d = IDLE;
   endcase	
           
 // PHI2 high must be glitchless - create it from just two FFs on clk/clkbar
 always @ (negedge clk ) begin
     if ( state_f_q=S0 )
         negen_f_q = 1'b1;
     else if ( state_f_q=S1)
         negen_f_q = 1'b0;                        
 end
 
 always @ (posedge clk ) begin
     posen_q <= negen_f_q;
     wr_qb   = wr_b;     
 end
    
endmodule
