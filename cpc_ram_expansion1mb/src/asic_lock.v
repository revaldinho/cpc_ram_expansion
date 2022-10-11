/*
 * Amstrad Patent describes logic to lock/unlock ASIC features
 *
 * http://www.cpcwiki.eu/imgs/6/61/Patent_GB2243701A.pdf
 *
 * Description on Wiki here
 *
 * https://www.cpcwiki.eu/index.php/Arnold_V_Specs_Revised#Locking_of_enhanced_features
 *
 * Full Sequence:
 *
 * Presync  : Repeating PRBS
 * -2   -1  :  0   1   2   3   4   5   6   7   8   9  10  11  12  13  14
 * FF   00  : ff, 77, b3, 51, a8, d4, 62, 39, 9c, 46, 2b, 15, 8a, cd, ee, [ ff, 77, .. ]
 *                                                                  \  \
 *                                                                   \  \_____ unlock feature on next byte
 *                                                                    \_______ lock feature on next byte
 *
 * NB Patent says that sequence should unlock/lock on matching bytes 14/13, but
 * emulators say unlock/lock on matching bytes 13/12.
 *
 */

`define INIT 2'b00
`define NEXT 2'b01
`define RUN  2'b11

`ifdef PATENT_BEHAVIOUR
  `define LOCKBYTE 8'hCD
  `define UNLOCKBYTE 8'hEE
`else
  `define LOCKBYTE 8'h8A
  `define UNLOCKBYTE 8'hCD
`endif



module asic_lock(
                 input       clk,
                 input       reset_b,
                 input       ioreq_b,
                 input       wr_b,
                 input [7:0] data,
                 input       io_cs, // High when relevant IO address is decoded [ &BCxx]
                 output      enf
                 );


  reg                        enf_d, enf_q ;
  reg [7:0]                  prbs_d, prbs_q ;
  reg [1:0]                  fsm_q, fsm_d;

  wire                       valid_w = (fsm_q == `RUN);
  wire                       not_match  = !(data == prbs_q);

  assign enf = enf_q;

  always @ ( * ) begin
    fsm_d = fsm_q;
    case (fsm_q)
      `INIT: fsm_d = (data != 8'h00) ? `NEXT: `INIT;
      `NEXT: fsm_d = (data == 8'h00) ? `RUN : `INIT;
      `RUN : fsm_d = (!not_match) ? `RUN : (data!=8'h00)? `NEXT : `INIT;
      default: fsm_d = `INIT;
    endcase // case `INIT
  end


  always @ (* ) begin
    if ( prbs_q == `UNLOCKBYTE)
      enf_d = 1'b1;
    else if ( prbs_q == `LOCKBYTE)
      enf_d = 1'b0;
    else
      enf_d = enf_q;
  end

  always @ ( * ) begin
    prbs_d[7] <= not_match | ( prbs_q[7] ^ prbs_q[4] );
    prbs_d[6] <= not_match | prbs_q[7];
    prbs_d[5] <= not_match | prbs_q[6];
    prbs_d[4] <= not_match | prbs_q[5];
    prbs_d[3] <= not_match | ( prbs_q[1] ^ prbs_q[0] );
    prbs_d[2] <= not_match | prbs_q[3];
    prbs_d[1] <= not_match | prbs_q[2];
    prbs_d[0] <= not_match | prbs_q[1];
  end

  always @ ( posedge clk or negedge reset_b) begin
    if ( !reset_b ) begin
      enf_q  <= 1'b0;
      prbs_q <= 8'hFF;
      fsm_q <= `INIT;
    end
    else if ( !ioreq_b & !wr_b & io_cs & valid_w) begin
      prbs_q <= prbs_d;
      enf_q <= enf_d;
      fsm_q <= fsm_d;
    end
  end

endmodule
