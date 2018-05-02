// 
// (c) Revaldinho, 2018
//  
module cpc_buffer_board ();

  // wire declarations
  supply0 VSS;
  supply1 VDD_EXT;
  supply1 VDD_CPC;
  supply1 VDD;

  wire Sound;  
  wire A15,A14,A13,A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0 ;
  wire D7,D6,D5,D4,D3,D2,D1,D0 ;
  wire MREQ_B;  
  wire M1_B;
  wire RFSH_B;
  wire IOREQ_B;
  wire RD_B;
  wire WR_B;
  wire HALT_B;
  wire INT_B ;
  wire NMI_B ;
  wire BUSRQ_B;  
  wire BUSACK_B;
  wire READY;
  wire BUSRESET_B;
  wire RESET_B;
  wire ROMEN_B;
  wire ROMDIS ;
  wire RAMRD_B;
  wire RAMDIS;
  wire CURSOR;
  wire LPEN;
  wire EXP_B;
  wire CLK;
  wire RAMCS_B;
  wire HIADR4,HIADR3,HIADR2,HIADR1,HIADR0;

  wire RAMOE_B;
  wire RAMWE_B;
  

  wire TMS;
  wire TDI;
  wire TDO;
  wire TCK;
  
  // 3 pin header with link to use either CPC or external 5V power for the board
  hdr1x03      L1 (
                   .p1(VDD_CPC),
                   .p2(VDD),
                   .p3(VDD_EXT)
                   );

  // 3 pin Tabbed power connector for external 5V power
  powerheader3   CONN0 (
                        .vdd1(VDD_EXT),
                        .vdd2(VDD_EXT),
                        .gnd(VSS)
                        );

  // Radial electolytic, one per board on the main 5V supply
  cap22uf         CAP22UF(.minus(VSS),.plus(VDD));

  // Amstrad CPC Edge Connector
  //
  // NB Numbering is correct to get the rows the right way around to match the CPC edge connector
  //    either when plugging directly into the CPC or via the MX4 Motherboard.
  idc_hdr_50w  CONN1 (
                      .p49(Sound),   .p50(VSS),
                      .p47(A15),     .p48(A14),
                      .p45(A13),     .p46(A12),
                      .p43(A11),     .p44(A10),
                      .p41(A9),      .p42(A8)
                      .p39(A7),      .p40(A6),
                      .p37(A5),      .p38(A4),
                      .p35(A3),      .p36(A2),
                      .p33(A1),      .p34(A0),
                      .p31(D7),      .p32(D6)
                      .p29(D5),      .p30(D4),
                      .p27(D3),      .p28(D2),
                      .p25(D1),      .p26(D0),
                      .p23(VDD_CPC), .p24(MREQ_B),
                      .p21(M1_B),    .p22(RFSH_B),
                      .p19(IOREQ_B), .p20(RD_B),
                      .p17(WR_B),    .p18(HALT_B),
                      .p15(INT_B),   .p16(NMI_B),
                      .p13(BUSRQ_B), .p14(BUSACK_B),
                      .p11(READY),   .p12(BUSRESET_B),
                      .p9 (RESET_B), .p10(ROMEN_B),
                      .p7 (ROMDIS),  .p8 (RAMRD_B),
                      .p5 (RAMDIS),  .p6 (CURSOR),
                      .p3 (LPEN),    .p4 (EXP_B),
                      .p1 (VSS),     .p2 (CLK),
                      ) ;

  idc_hdr_50w  CONN2 (
                      .p49(Sound),   .p50(VSS),
                      .p47(BUF_A15),     .p48(BUF_A14),
                      .p45(BUF_A13),     .p46(BUF_A12),
                      .p43(BUF_A11),     .p44(BUF_A10),
                      .p41(BUF_A9),      .p42(BUF_A8)
                      .p39(BUF_A7),      .p40(BUF_A6),
                      .p37(BUF_A5),      .p38(BUF_A4),
                      .p35(BUF_A3),      .p36(BUF_A2),
                      .p33(BUF_A1),      .p34(BUF_A0),
                      .p31(D7),      .p32(D6)
                      .p29(D5),      .p30(D4),
                      .p27(D3),      .p28(D2),
                      .p25(D1),      .p26(D0),
                      .p23(VDD_CPC), .p24(MREQ_B),
                      .p21(M1_B),    .p22(RFSH_B),
                      .p19(IOREQ_B), .p20(RD_B),
                      .p17(WR_B),    .p18(HALT_B),
                      .p15(INT_B),   .p16(NMI_B),
                      .p13(BUSRQ_B), .p14(BUSACK_B),
                      .p11(READY),   .p12(BUSRESET_B),
                      .p9 (RESET_B), .p10(ROMEN_B),
                      .p7 (ROMDIS),  .p8 (RAMRD_B),
                      .p5 (RAMDIS),  .p6 (CURSOR),
                      .p3 (LPEN),    .p4 (EXP_B),
                      .p1 (VSS),     .p2 (CLK),
                      ) ;
  

   // Decoupling caps for CPLD and one for SRAM
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_3 (.p0( VSS ), .p1( VDD ));

endmodule
