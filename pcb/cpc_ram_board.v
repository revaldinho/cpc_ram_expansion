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
  supply1 VDD3V3;

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

  MCP1700_3302E   REG3V3 (
                            .vin(VDD),
                            .gnd(VSS),
                            .vout(VDD3V3)
                            );


  // Radial electolytic, one per board on the main 5V supply
  cap22uf         CAP22UF(.minus(VSS),.plus(VDD));

  // Two ceramic caps to be placed v. close to regulator pins
  cap1uf          reg_cap0 (.p0(VDD), .p1(VSS));
  cap1uf          reg_cap1 (.p0(VDD3V3), .p1(VSS));

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

  // Standard layout JTAG port for programming the CPLD
  hdr8way JTAG (
                .p1(VSS),  .p2(VSS),
                .p3(TMS),  .p4(TDI),
                .p5(TDO),  .p6(TCK),
                .p7(VDD),  .p8(),
                );

  // 9572XL CPLD - 3.3V core, 5V IO
  xc9572pc44  CPLD (
                    .p1(MREQ_B),
	            .p2(IOREQ_B),
	            .p3(READY),
	            .p4(),
	            .gck1(CLK),
	            .gck2(),
	            .gck3(RD_B),
	            .p8(WR_B),
	            .p9(),
	            .gnd1(VSS),
	            .p11(),
	            .p12(),
	            .p13(HIADR4),
	            .p14(),
	            .tdi(TDI),
	            .tms(TMS),
	            .tck(TCK),
	            .p18(HIADR2),
	            .p19(HIADR1),
	            .p20(HIADR3),
	            .vccint1(VDD3V3),
	            .p22(RAMWE_B),
	            .gnd2(VSS),
	            .p24(HIADR0),
	            .p25(A15),
	            .p26(A14),
	            .p27(RAMOE_B),
	            .p28(RAMCS_B),
	            .p29(D7),
	            .tdo(TDO),
	            .gnd3(VSS),
	            .vccio(VDD3V3),
	            .p33(D6),
	            .p34(D5),
	            .p35(D4),
	            .p36(D3),
	            .p37(D2),
	            .p38(D1),
	            .gsr(RESET_B),
	            .gts2(BUSRESET_B),
	            .vccint2(VDD3V3),
	            .gts1(RAMDIS),
	            .p43(D0),
	            .p44(RAMRD_B),
                    );

  // Alliance 512K x 8 SRAM - address pins wired to suit layout
  bs62lv4006  SRAM (
                    .a18(HIADR4),  .vcc(VDD3V3),
                    .a16(HIADR2),  .a15(HIADR1),
                    .a14(HIADR0),  .a17(HIADR3),
                    .a12(A5),  .web(RAMWE_B),
                    .a7(A6),  .a13(A4),
                    .a6(A7),  .a8(A2),
                    .a5(A8),  .a9(A3),
                    .a4(A9),  .a11(A1),
                    .a3(A10),  .oeb(RAMOE_B),
                    .a2(A11),  .a10(A0),
                    .a1(A13),  .csb(RAMCS_B),
                    .a0(A12),  .d7(D7),
                    .d0(D0),  .d6(D6),
                    .d1(D1),  .d5(D5),
                    .d2(D2),  .d4(D4),
                    .vss(VSS),  .d3(D3)
                    );

   // Decoupling caps for CPLD and one for SRAM
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD3V3 ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD3V3 ));
   cap100nf CAP100N_3 (.p0( VSS ), .p1( VDD3V3 ));

endmodule
