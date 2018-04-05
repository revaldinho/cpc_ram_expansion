// 
// cpc_ram_board netlist
// 
// netlister.py format
// 
// (c) Revaldinho, 2018
// 
//  
module cpc_ram_board ();

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
  wire ramcs_b;
  wire hiadr4,hiadr3,hiadr2,hiadr1,hiadr0;


  wire ramblock_q5,ramblock_q4,ramblock_q3,ramblock_q2,ramblock_q1,ramblock_q0;
  wire clken_lat_q, ramblock_q_2_, ramblock_q_1_, ramblock_q_0_, n17, n18,
       n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31, n32;
  wire nn1, nn2;
  
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



  // These are direct connections from CPC bus to SRAM IC
  //BUF U29 ( .i(wr_b), .o(ramwe_b) );
  //BUF U30 ( .i(ramrd_b), .o(ramoe_b) );

  // Quad NOR2 74HCT02
  SN7402 U0 ( 
              .i0_0(CLK), .i0_1(clken_lat_q), .o0(n17),
              .i1_0(n27), .i1_1(MREQ_B), .o1(n31),
              .i2_0(nn1), .i2_1(A15), .o2(nn2),
              .i3_0(VDD), .i3_1(VDD),              
              .vdd(VDD), .vss(VSS));

  // Triple NOR3 74HCT27
  SN7427 U1 ( 
              .i0_0(A15), .i0_1(IOREQ_B), .i0_2(WR_B), .o0(n19),
              .i1_0(ramblock_q0), .i1_1(ramblock_q2), .i1_2(ramblock_q1), .o1(n27),
              .i2_0(VDD), .i2_1(VDD), .i2_2(VDD), .o2(),
              .vdd(VDD), .vss(VSS));

  // Triple NAND3 74HCT10
  SN7410 U2 ( 
               .i0_0(D6), .i0_1(D7), .i0_2(n19), .o0(n18),
               .i1_0(A14), .i1_1(ramblock_q1), .i1_2(n22), .o1(n20),
               .i2_0(n32), .i2_1(n31), .i2_2(n30), .o2(ramcs_b),
               .vdd(VDD), .vss(VSS));               


  // Quad NAND2 74HCT00
  SN7400 U3 ( 
              .i0_0(n21), .i0_1(n20), .o0(hiadr0),
              .i1_0(n22), .i1_1(n28), .o1(n25),
              .i3_0(ramblock_q1), .i3_1(n25), .o3(n24),              
              .i2_0(ramblock_q0), .i2_1(n22), .o2(n23),
              .vdd(VDD), .vss(VSS));              

  // Quad NAND2 74HCT00
  SN7400 U4 ( 
              .i0_0(n24),   .i0_1(n23), .o0(hiadr1),
	      .i1_0(A14), .i1_1(n25), .o1(n26),
	      .i2_0(ramblock_q0), .i2_1(n26), .o2(n32),
	      .i3_0(ramblock_q2), .i3_1(n29), .o3(n30),
              .vdd(VDD), .vss(VSS));              

  // Hex INV 74HCT04
  SN7404 U5 ( .i0(ramcs_b), .o0(RAMDIS),
              .i1(A14), .o1(nn1),
              .i2(A15), .o2(n28),
              .i3(ramblock_q2), .o3(n22),
              .i4(ramblock_q0), .o4(n21),
              .i5(nn2), .o5(n29),
              .vdd(VDD), .vss(VSS));              
  
  //  ECO out this gate to reduce chip count
  //  NAND2 U43 ( .i0(adr14), .i1(n28), .o(n29) );

  // Quad latch 74HCT75
  SN7475 U6 ( .en01(CLK), .d0(n18), .q0(clken_lat_q), .qb0(),
                        .d1(VDD), .q1(), .qb1(),
            .en23(VSS), .d2(VDD), .q2(), .qb2(),
                        .d3(VDD), .q3(), .qb3(),
            .vdd(VDD), .vss(VSS));               

  // Hex posedge triggered D-FF with clear*
  SN74174 U7 (
              .clock(n17),
              .resetb(RESET_B),
              .d0(D0),
              .d1(D1),
              .d2(D2),
              .d3(D3),
              .d4(D4),
              .d5(D5),                            
              .q0(ramblock_q0),
              .q1(ramblock_q1),
              .q2(ramblock_q2),
              .q3(hiadr2),
              .q4(hiadr3),
              .q5(hiadr4),       
              .vdd(VDD), .vss(VSS));
  


  
  // Alliance 512K x 8 SRAM - address pins wired to suit layout
  bs62lv4006  SRAM (
                    .a18(hiadr4),  .vcc(VDD),
                    .a16(hiadr2),  .a15(hiadr1),
                    .a14(hiadr0),  .a17(hiadr3),
                    .a12(A5),  .web(WR_B),
                    .a7(A6),  .a13(A4),
                    .a6(A7),  .a8(A2),
                    .a5(A8),  .a9(A3),
                    .a4(A9),  .a11(A1),
                    .a3(A10),  .oeb(RAMRD_B),
                    .a2(A11),  .a10(A0),
                    .a1(A13),  .csb(ramcs_b),
                    .a0(A12),  .d7(D7),
                    .d0(D0),  .d6(D6),
                    .d1(D1),  .d5(D5),
                    .d2(D2),  .d4(D4),
                    .vss(VSS),  .d3(D3)
                    );

   // Decoupling caps for CPLD and one for SRAM
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_3 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_4 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_5 (.p0( VSS ), .p1( VDD ));

endmodule
