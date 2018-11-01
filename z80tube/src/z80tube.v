// Reserve ports in range &FC10 - &FC1F
//
// PMOD and other CPLD registers start at &FC18
// Tube registers are &FC10-&FC17
//

`define PMOD_INPUT_REG      1 
// Upper 12 bits oply
`define PORT_ID_BASE 	   16'hFC10
`define PORT_ID_BASE_TOP12 16'hFC1
`define DATA_REG_ID  	    4'hE
`define DIR_REG_ID  	    4'hD
`define TUBE_REG0_ID	    4'h0
`define TUBE_REG1_ID	    4'h1
`define TUBE_REG2_ID	    4'h2
`define TUBE_REG3_ID	    4'h3
`define TUBE_REG4_ID	    4'h4
`define TUBE_REG5_ID	    4'h5
`define TUBE_REG6_ID	    4'h6
`define TUBE_REG7_ID	    4'h7

module z80tube(
               // Host
               input        CLK,
               input [15:0] ADR,
               input        RD_B,
               input        WR_B, 
               input        IOREQ_B,
               input        M1_B, 
               input        MREQ_B,
               input        WAIT_B,
               input        RESET_B,
               inout [7:0]  DATA,
               inout        NMI_B, 
               inout        INT_B,
               input        BUSRQ_B,
               input        BUSACK_B,
               input        READY,

               // PMOD Port
               inout [7:0]  PMOD_GPIO,

               // Tube	
               input        TUBE_INT_B,
               
               inout [7:0]  TUBE_DATA,
               
               output [2:0] TUBE_ADR,
               output       TUBE_RNW_B,
               output       TUBE_PHI2,
               output       TUBE_CS_B,
               output       TUBE_RST_B       
               );	

  //      IDLE  .  S0     .   S0    .   S1    .    S2   .  IDLE  (negedge state)
  //        ____      ____      ____      ____      ____      __
  // CLK        \____/    \____/    \____/    \____/    \____/  
  //      _ ________________________________________ ___________
  // ADR  _X________________________________________X___________
  //      _____                                 ________________
  // IORQ*     \_______________________________/
  //      _________________                    _________________
  // WR*                   \__________________/
  //      _____________           ______________________________
  // WAIT*     \_______\_________/                               Sampled on falling CLK by CPU
  //                                 ______________
  // DATA --------------------------X______________X----------
  //                 :         :         :         :         :
  //            .    :    .    :    .    :    .    :    .    :
  //                       ___________________
  // negen_f_q ___________/                   \_________________
  //                            ___________________
  // posen_q __________________/                   \____________
  //                       ________________________
  // phi2  _______________/                        \____________ 
  //       _____                                 _______________
  // CS*        \_______________________________/                Must assert in PHI1
  //      __ _______________________________________ __________
  // ADR  __X_______________________________________X__________ Pass-through of CPU ADR bus
  //      _________________                    ________________
  // RnW*                  \__________________/                 = (IORQ* | WR* ) 
  //                                 ______________
  // DATA --------------------------X______________X------------ 
  //
  parameter IDLE=0,S0=1,S1=2,S2=3,S3=4;
  
    
  reg                 posen_q;
  reg                 negen_f_q;
  reg [1:0]           state_f_q;
  reg [1:0]           state_d;    
  reg                 wr_b_q;
  reg                 rd_b_q;    
  reg [7:0]           pmod_dir_f_q;
  reg [7:0]           pmod_dout_f_q;
`ifdef PMOD_INPUT_REG  
  reg [7:0]           pmod_din_q;
`endif  
  reg [7:0]           data_r;
  reg                 data_en_r;
  reg [1:0]           reset_b_q;
  
  wire                port_select ;  
  wire                tube_reg_select;  
  wire                reset_b_w;
  
  // Check 12 upper bits of PORT ID register first
  assign port_select = (ADR[15:4] == `PORT_ID_BASE_TOP12) ;  
  // Port with bit3 addr clear provides 8 addresses for the tube
  assign tube_reg_select = port_select & !ADR[3] ; 
  
  // TUBE
  assign TUBE_CS_B = IOREQ_B | !tube_reg_select ;
  assign TUBE_PHI2 = negen_f_q | posen_q;
  assign TUBE_ADR = ADR[2:0];
  assign TUBE_RNW_B = IOREQ_B | WR_B;
  assign TUBE_DATA = ( !wr_b_q & ((state_f_q==S1)|(state_f_q==S2)) & posen_q ) ? DATA : 8'bz;

  // HOST - drive databus on reads
  assign DATA = ( data_en_r ) ? data_r : 8'bzzzzzzzz ;
  assign NMI = 1'bz;
  assign INT = 1'bz;
  
  // Synchronized reset release to posedge of clock
  assign reset_b_w = RESET_B & reset_b_q[0];

  assign PMOD_GPIO[7] = (pmod_dir_f_q[7]) ? pmod_dout_f_q[7] : 1'bz;
  assign PMOD_GPIO[6] = (pmod_dir_f_q[6]) ? pmod_dout_f_q[6] : 1'bz;
  assign PMOD_GPIO[5] = (pmod_dir_f_q[5]) ? pmod_dout_f_q[5] : 1'bz;
  assign PMOD_GPIO[4] = (pmod_dir_f_q[4]) ? pmod_dout_f_q[4] : 1'bz;
  assign PMOD_GPIO[3] = (pmod_dir_f_q[3]) ? pmod_dout_f_q[3] : 1'bz;
  assign PMOD_GPIO[2] = (pmod_dir_f_q[2]) ? pmod_dout_f_q[2] : 1'bz;
  assign PMOD_GPIO[1] = (pmod_dir_f_q[1]) ? pmod_dout_f_q[1] : 1'bz;
  assign PMOD_GPIO[0] = (pmod_dir_f_q[0]) ? pmod_dout_f_q[0] : 1'bz;
  
  
  // Data mux to service IO Reads by the CPC Z80 Host
  always @ ( * )
    if ( !IOREQ_B & !RD_B & port_select )
      case (ADR[3:0])
`ifdef PMOD_INPUT_REG        
        `DATA_REG_ID: { data_en_r, data_r } = { 1'b1, pmod_din_q } ;
`else        
        `DATA_REG_ID: { data_en_r, data_r } = { 1'b1, PMOD_GPIO } ;
`endif        

        `DIR_REG_ID: { data_en_r, data_r } = { 1'b1, pmod_dir_f_q } ;
        `TUBE_REG7_ID, 
        `TUBE_REG6_ID, 
        `TUBE_REG5_ID, 
        `TUBE_REG4_ID, 
        `TUBE_REG3_ID, 
        `TUBE_REG2_ID, 
        `TUBE_REG1_ID, 
        `TUBE_REG0_ID: { data_en_r, data_r } = { 1'b1, TUBE_DATA } ;
        default: { data_en_r, data_r } = { 1'b0, 8'bx } ;
      endcase
    else
      { data_en_r, data_r } = { 1'b0, 8'bx } ;              

  always @ ( negedge CLK )
    case (state_f_q)
      IDLE:  state_d = ( !IOREQ_B) ? S0 : IDLE ;
      S0  :  state_d = (!WAIT_B) ? S1 : S0;
      S1  :  state_d = S2;
      S2  :  state_d = IDLE;
      default: state_d = IDLE;
    endcase	

  always @ (negedge CLK ) begin
    if ( !reset_b_w ) begin
      state_f_q <= IDLE;
      negen_f_q <= 1'b0;
    end
    else begin
      state_f_q <= state_d;    
      negen_f_q <= (state_f_q==S0) ;
    end      
  end
  
  always @ (posedge CLK ) begin
`ifdef PMOD_INPUT_REG    
    if ( !IOREQ_B & !RD_B & rd_b_q) begin
      pmod_din_q <= PMOD_GPIO;
    end
`endif    
    posen_q <= negen_f_q;
    wr_b_q  <= WR_B;
    rd_b_q  <= RD_B; 
    reset_b_q <= {RESET_B, reset_b_q[1]};    
  end

  always @ (negedge CLK )
    if (!reset_b_w)
      pmod_dir_f_q <= 8'h00;
    else	
      if (!WR_B & !IOREQ_B & port_select)
        if (ADR[3:0] == `DATA_REG_ID)
          pmod_dout_f_q <= DATA[7:0];
        else if (ADR[3:0] == `DIR_REG_ID)
          pmod_dir_f_q <= DATA[7:0];

endmodule // z80tube
