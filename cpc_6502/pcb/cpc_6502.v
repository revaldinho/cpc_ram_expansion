// 
// cpc_6502 netlist
// 
// netlister.py format
// 
// (c) Revaldinho, 2018
// 
//  
module cpc_6502 ();

  // wire declarations
  supply0 VSS;
  supply1 VDD;
  supply1 VDD_3V3;
  supply1 VDD_IO;
  supply1 VDD_PI;    
  supply1 VDD_3V3_REG;
  supply1 VDD_3V3_EXT;      

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

  wire TMS;
  wire TDI;
  wire TDO;
  wire TCK;

  wire PMOD_GPIO_0;
  wire PMOD_GPIO_1;
  wire PMOD_GPIO_2;
  wire PMOD_GPIO_3;
  wire PMOD_GPIO_4;
  wire PMOD_GPIO_5;
  wire PMOD_GPIO_6;
  wire PMOD_GPIO_7;
  wire PI_GPIO_02;
  wire PI_GPIO_03;
  wire PI_GPIO_04;
  wire PI_GPIO_05;
  wire PI_GPIO_06;
  wire PI_GPIO_07;
  wire PI_GPIO_08;
  wire PI_GPIO_09;
  wire PI_GPIO_10;  
  wire PI_GPIO_11;
  wire PI_GPIO_12;
  wire PI_GPIO_13;
  wire PI_GPIO_14;
  wire PI_GPIO_15;
  wire PI_GPIO_16;
  wire PI_GPIO_17;
  wire PI_GPIO_18;
  wire PI_GPIO_19;
  wire PI_GPIO_20;
  wire PI_GPIO_21;
  wire PI_GPIO_22;
  wire PI_GPIO_23;
  wire PI_GPIO_24;
  wire PI_GPIO_25;
  wire PI_GPIO_26;
  wire PI_GPIO_27;


  
  // 3 pin header with link to use either regulator or external 3V3 power for the board
  hdr1x03      L1 (
                   .p1(VDD_3V3_REG),
                   .p2(VDD_3V3),
                   .p3(VDD_3V3_EXT)
                   );

  // Select 5V or 3V3 for CPLD IO voltage 
  hdr1x03      L2 (
                   .p1(VDD),
                   .p2(VDD_IO),
                   .p3(VDD_3V3)
                   );

  // 5V Power jumper for 40W socket
  hdr1x02      L3 (
                   .p1(VDD_PI),
                   .p2(VDD)
                   );


  MCP1700_3302E   REG3V3 (
                            .vin(VDD),
                            .gnd(VSS),
                            .vout(VDD_3V3_REG)
                            );

  // Radial electolytic, one each on the main 5V and incoming 3V3 supply
  cap22uf         CAP22UF_5V(.minus(VSS),.plus(VDD));
  cap22uf         CAP22UF_IO(.minus(VSS),.plus(VDD_3V3_EXT));

  // Two ceramic caps to be placed v. close to regulator pins
  cap1uf          reg_cap0 (.p0(VDD), .p1(VSS));
  cap1uf          reg_cap1 (.p0(VDD_3V3_REG), .p1(VSS));
  
  // Amstrad CPC Edge Connector
  //
  // V1.01 Corrected upper and lower rows

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

  // Standard layout JTAG port for programming the CPLD
  hdr8way JTAG (
                .p1(VSS),  .p2(VSS),
                .p3(TMS),  .p4(TDI),
                .p5(TDO),  .p6(TCK),
                .p7(VDD),  .p8(),
                );

  // 3 pin header for PI Debug UART pins
  hdr1x03  UART (
                 .p1(VSS),
                 .p2(PI_GPIO_14), // UART TX
                 .p3(PI_GPIO_15)  // UART RX
                 );

  // 12 pin PMOD port
  hdr2x06 PMOD0 (
                     .p1(VDD_IO), .p2(VDD_IO),
		     .p3(VSS), .p4(VSS),
		     .p5(PMOD_GPIO_6), .p6(PMOD_GPIO_7),
		     .p7(PMOD_GPIO_4), .p8(PMOD_GPIO_5),
		     .p9(PMOD_GPIO_2), .p10(PMOD_GPIO_3),
		     .p11(PMOD_GPIO_0), .p12(PMOD_GPIO_1)               
                     );
  
  
  hdr2x20 CONN2 (
                     .p1(VDD_3V3_EXT), .p2(VDD_PI),
                     .p3(PI_GPIO_02),  .p4(VDD_PI),
		     .p5(PI_GPIO_03),  .p6(VSS),
		     .p7(PI_GPIO_04),  .p8(PI_GPIO_14),
		     .p9(VSS),         .p10(PI_GPIO_15),
		     .p11(PI_GPIO_17), .p12(PI_GPIO_18),
		     .p13(PI_GPIO_27), .p14(VSS),
		     .p15(PI_GPIO_22), .p16(PI_GPIO_23),
		     .p17(VDD_3V3_EXT),.p18(PI_GPIO_24),
		     .p19(PI_GPIO_10), .p20(VSS),
		     .p21(PI_GPIO_09), .p22(PI_GPIO_25),
		     .p23(PI_GPIO_11), .p24(PI_GPIO_08),
		     .p25(VSS),        .p26(PI_GPIO_07),
		     .p27(),           .p28(),
		     .p29(PI_GPIO_05), .p30(VSS),
		     .p31(PI_GPIO_06), .p32(PI_GPIO_12),
		     .p33(PI_GPIO_13), .p34(VSS),
		     .p35(PI_GPIO_19), .p36(PI_GPIO_16),
		     .p37(PI_GPIO_26), .p38(PI_GPIO_20),
		     .p39(VSS),        .p40(PI_GPIO_21)
                     );
                  

  // 95108/72 CPLD - 5V core and switchable 5V or 3V3 IO
  xc95108_pc84  CPLD (
		     .p1(PI_GPIO_21),
		     .p2(PI_GPIO_20),
		     .p3(PI_GPIO_26),
		     .p4(PI_GPIO_16),
		     .p5(PI_GPIO_19),
		     .p6(PI_GPIO_13),
		     .p7(PI_GPIO_12),
		     .gnd1(VSS),
		     .gck1(CLK),
		     .gck2(PI_GPIO_06),
		     .p11(PI_GPIO_05),
		     .gck3(PI_GPIO_07),
		     .p13(PI_GPIO_08),
		     .p14(PI_GPIO_11),
		     .p15(PI_GPIO_25),
		     .gnd2(VSS),
		     .p17(PI_GPIO_09),
		     .p18(PI_GPIO_10),
		     .p19(PI_GPIO_24),
		     .p20(PI_GPIO_23),
		     .p21(PI_GPIO_22),
		     .vccio1(VDD_IO),
		     .p23(PI_GPIO_27),
		     .p24(PI_GPIO_18),
		     .p25(PI_GPIO_17),
		     .p26(PI_GPIO_15),
		     .gnd3(VSS),
		     .tdi(TDI),
		     .tms(TMS),
		     .tck(TCK),
		     .p31(PI_GPIO_14),
		     .p32(PI_GPIO_04),
		     .p33(PI_GPIO_03),
		     .p34(PI_GPIO_02),
		     .p35(PMOD_GPIO_7),
		     .p36(PMOD_GPIO_6),
		     .p37(PMOD_GPIO_5),
		     .vccint1(VDD),
		     .p39(PMOD_GPIO_4),
		     .p40(PMOD_GPIO_3),
		     .p41(PMOD_GPIO_2),
		     .gnd4(VSS),
		     .p43(PMOD_GPIO_1),
		     .p44(PMOD_GPIO_0),
		     .p45(A15),
		     .p46(A14),
		     .p47(A13),
		     .p48(A12),
		     .gnd5(VSS),
		     .p50(A11),
		     .p51(A10),
		     .p52(A9),
		     .p53(A8),
		     .p54(A7),
		     .p55(A6),
		     .p56(A5),
		     .p57(A4),
		     .p58(A3),
		     .tdo(TDO),
		     .gnd6(VSS),
		     .p61(A2),
		     .p62(A1),
		     .p63(A0),
		     .vccio2(VDD_IO),
		     .p65(D7),
		     .p66(D6),
		     .p67(D5),
		     .p68(D4),
		     .p69(D3),
		     .p70(D2),
		     .p71(D1),
		     .p72(D0),
		     .vccint2(VDD),
		     .gsr(RESET_B),
		     .p75(BUSRESET_B),
		     .gts1(IOREQ_B),
		     .gts2(RD_B),
		     .vccint3(VDD),
		     .p79(WR_B),
		     .p80(INT_B),
		     .p81(BUSRQ_B),
		     .p82(BUSACK_B),
		     .p83(READY),
		     .p84(EXP_B)
                     );
  
  // SMD caps on the back of the CPLD footprint 
   cap100nf_smd CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf_smd CAP100N_2 (.p0( VSS ), .p1( VDD_IO ));  
   cap100nf_smd CAP100N_3 (.p0( VSS ), .p1( VDD ));
   cap100nf_smd CAP100N_4 (.p0( VSS ), .p1( VDD_IO ));  
  
endmodule
