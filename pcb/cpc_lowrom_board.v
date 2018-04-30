// 
// cpc_lowrom_board netlist
// 
// netlister.py format
// 
// (c) Revaldinho, 2018
// 
//  
module cpc_lowrom_board ();

  // wire declarations
  supply0 VSS;
  supply1 VDD;

  wire    Sound;  
  wire    A15,A14,A13,A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0 ;
  wire    D7,D6,D5,D4,D3,D2,D1,D0 ;
  wire    MREQ_B;  
  wire    M1_B;
  wire    RFSH_B;
  wire    IOREQ_B;
  wire    RD_B;
  wire    WR_B;
  wire    HALT_B;
  wire    INT_B ;
  wire    NMI_B ;
  wire    BUSRQ_B;  
  wire    BUSACK_B;
  wire    READY;
  wire    BUSRESET_B;
  wire    RESET_B;
  wire    ROMEN_B;
  wire    ROMDIS ;
  wire    RAMRD_B;
  wire    RAMDIS;
  wire    CURSOR;
  wire    LPEN;
  wire    EXP_B;
  wire    CLK;
  wire    romcs_b;
  wire    n1, n2;
  wire    disable;
  

  // Radial electolytic, one per board on the main 5V supply
  cap22uf         CAP22UF(.minus(VSS),.plus(VDD));

  // Amstrad CPC Edge Connector
  //
  // Revised pin-out to allow direct connection from ribbon cable or MX4 to RA IDC box
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

  // 27128 and 28C256 compatible socket (16KByte addressable)
  xc28256 ROM0 (
                .a14(VSS),  .vcc(VDD),  
                .a12(A12),  .web(VDD),
                .a7(A7),    .a13(A13),
                .a6(A6),     .a8(A8),
                .a5(A5),     .a9(A9),
                .a4(A4),    .a11(A11),
                .a3(A3),    .oeb(ROMEN_B),
                .a2(A2),    .a10(A10),
                .a1(A1),    .csb(romcs_b),
                .a0(A0),     .d7(D7),
                .d0(D0),     .d6(D6),
                .d1(D1),     .d5(D5),
                .d2(D2),     .d4(D4),
                .vss(VSS),   .d3(D3),
                );

  // romcs_b              = active low  = !( !ROMEN_B & !A14 & !disable)  = (ROMEN_B + A14 + disable)
  // romdis  (via diode)  = active high = !A14 & !disable                 = !(A14 + disable)

  // Triple OR3 74HCT27
  SN7427 U0 (
             .i0_0(ROMEN_B), .i0_1(A14), .i0_2(disable), .o0(n1),
             .i1_0(disable), .i1_1(disable), ,i1_2(A14).o1(n2),
             .i2_0(n1), .i2_1(n1), .i2_2(n1), .o2(romcs_b),
             .vdd(VDD), .vss(VSS)
             );

  DIODE_1N4148 D0 (
                .A(n2),
                .C(ROMDIS)
                );

  // 3 pin header for link or switch to disable board
  hdr1x03  L1 (
               .p1(VDD),
               .p2(disable),
               .p3(VSS)
               );

   // Decoupling caps 
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD ));

endmodule
