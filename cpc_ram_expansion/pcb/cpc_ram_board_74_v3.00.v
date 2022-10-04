//
// cpc_ram_board netlist
//
// netlister.py format
//
// (c) Revaldinho, 2018, 2022
//
//
// revision v3.00
// - revised logic eliminates one IC, reduced load on CPU clock
// - match board size and power distribution with EightRom card
// - update layout/routing as required.


module cpc_ram_board ();

  // wire declarations
  supply0 VSS;
  supply1 VDD;

  special_wire IOREQ_B, WR_B, RESET_B;

  wire    Sound;
  wire    A15,A14,A13,A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0 ;
  wire    D7,D6,D5,D4,D3,D2,D1,D0 ;
  wire    MREQ_B;
  wire    M1_B;
  wire    RFSH_B;
  wire    RD_B;
  wire    HALT_B;
  wire    INT_B ;
  wire    NMI_B ;
  wire    BUSRQ_B;
  wire    BUSACK_B;
  wire    READY;
  wire    BUSRESET_B;
  wire    ROMEN_B;
  wire    ROMDIS ;
  wire    RAMRD_B;
  wire    RAMDIS;
  wire    CURSOR;
  wire    LPEN;
  wire    EXP_B;
  wire    CLK;
  wire    ramadrhi4,ramadrhi3,ramadrhi2,ramadrhi1,ramadrhi0;
  wire    ramblock_q2,ramblock_q1,ramblock_q0;
  wire    ramcs_b, extram_b;
  wire    wclk_b, n14;
  wire    n16, n17, n18, n19, n20, a15_b, n22, n23, n24, n25, n26, n27, n28;
  wire    n29, nn1;

  // Radial electolytic, one per board on the main 5V supply
  cap22uf         C22UF(.minus(VSS),.plus(VDD));

  // Amstrad CPC Edge Connector
  idc_hdr_50w  CONN1 (
                      .p50(Sound),   .p49(VSS),
                      .p48(A15),     .p47(A14),
                      .p46(A13),     .p45(A12),
                      .p44(A11),     .p43(A10),
                      .p42(A9),      .p41(A8)
                      .p40(A7),      .p39(A6),
                      .p38(A5),      .p37(A4),
                      .p36(A3),      .p35(A2),
                      .p34(A1),      .p33(A0),
                      .p32(D7),      .p31(D6)
                      .p30(D5),      .p29(D4),
                      .p28(D3),      .p27(D2),
                      .p26(D1),      .p25(D0),
                      .p24(VDD),     .p23(MREQ_B),
                      .p22(M1_B),    .p21(RFSH_B),
                      .p20(IOREQ_B), .p19(RD_B),
                      .p18(WR_B),    .p17(HALT_B),
                      .p16(INT_B),   .p15(NMI_B),
                      .p14(BUSRQ_B), .p13(BUSACK_B),
                      .p12(READY),   .p11(BUSRESET_B),
                      .p10(RESET_B), .p9 (ROMEN_B),
                      .p8 (ROMDIS),  .p7 (RAMRD_B),
                      .p6 (RAMDIS),  .p5 (CURSOR),
                      .p4 (LPEN),    .p3 (EXP_B),
                      .p2 (VSS),     .p1 (CLK),
                      ) ;

  // Quad OR2 74HCT32
  SN7432 U0 (
             .i0_0(ramblock_q0), .i0_1(ramblock_q1), .o0(n24),
             .i1_0(extram_b), .i1_1(MREQ_B), .o1(ramcs_b),
             .i2_0(IOREQ_B), .i2_1(WR_B), .o2(nn1),
             .i3_0(nn1), .i3_1(n14), .o3(wclk_b),
             .vdd(VDD), .vss(VSS));

  // Dual NOR2 74HCT02
  SN7402 U1 (
             .i0_0(VDD), .i0_1(VDD), .o0(),  // UNUSED
             .i1_0(ramblock_q0), .i1_1(ramblock_q0), .o1(n17),
             .i2_0(A15), .i2_1(A15), .o2(a15_b),
             .i3_0(extram_b), .i3_1(extram_b), .o3(RAMDIS),
             .vdd(VDD), .vss(VSS));

  // Triple NAND3 74HCT10
  SN7410 U2 (
             .i0_0(D6), .i0_1(D7), .i0_2(a15_b), .o0(n14),
             .i1_0(A14), .i1_1(ramblock_q1), .i1_2(n27), .o1(n16),
             .i2_0(ramblock_q2), .i2_1(ramblock_q2), .i2_2(ramblock_q2), .o2(n27),
             .vdd(VDD), .vss(VSS));

  // Quad NAND2 74HCT00
  SN7400 U3 (
             .i0_0(n17), .i0_1(n16), .o0(ramadrhi0),
             .i1_0(n20), .i1_1(n19), .o1(ramadrhi1),
             .i2_0(A14), .i2_1(a15_b), .o2(n22),
             .i3_0(A14), .i3_1(A15), .o3(n23),
             .vdd(VDD), .vss(VSS));

  // Quad NAND2 74HCT00
  SN7400 U4 (
             .i0_0(n27), .i0_1(ramblock_q0), .o0(n20),
             .i1_0(ramblock_q0), .i1_1(n23), .o1(n25),
             .i2_0(ramblock_q2), .i2_1(n22), .o2(n29),
             .i3_0(ramblock_q1), .i3_1(n18), .o3(n19),
             .vdd(VDD), .vss(VSS));

  // Quad NAND2 74HCT00
  SN7400 U5 (
             .i0_0(n25), .i0_1(n24), .o0(n26),
             .i1_0(n27), .i1_1(n26), .o1(n28),
             .i2_0(n29), .i2_1(n28), .o2(extram_b),
             .i3_0(n27), .i3_1(a15_b), .o3(n18),
             .vdd(VDD), .vss(VSS));

  // Hex posedge triggered D-FF with clear*
  SN74174 U6 (
              .clock(wclk_b),
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
              .q3(ramadrhi2),
              .q4(ramadrhi3),
              .q5(ramadrhi4),
              .vdd(VDD), .vss(VSS));

  // Alliance 512K x 8 SRAM - address pins wired to suit layout
  bs62lv4006  SRAM (
                    .a18(ramadrhi4),  .vcc(VDD),
                    .a16(ramadrhi2),  .a15(ramadrhi1),
                    .a14(ramadrhi0),  .a17(ramadrhi3),
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

   // Decoupling caps
   cap100nf C0 (.p0( VSS ), .p1( VDD ));
   cap100nf C1 (.p0( VSS ), .p1( VDD ));
   cap100nf C2 (.p0( VSS ), .p1( VDD ));
   cap100nf C3 (.p0( VSS ), .p1( VDD ));
   cap100nf C4 (.p0( VSS ), .p1( VDD ));
   cap100nf C5 (.p0( VSS ), .p1( VDD ));
   cap100nf C6 (.p0( VSS ), .p1( VDD ));

endmodule
