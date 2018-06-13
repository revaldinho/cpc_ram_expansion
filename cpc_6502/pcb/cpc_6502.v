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

  wire T_UART_RX;
  wire T_UART_TX;  
  wire T_HA0;
  wire T_HA1 ;
  wire T_HA2 ;
  wire T_HRST_B ;
  wire T_HCS_B ;
  wire T_RNW;
  wire T_HD7;
  wire T_HD6;
  wire T_HD5;
  wire T_HD4;
  wire T_HD3;
  wire T_HD2;
  wire T_HD1;
  wire T_HD0;
  wire T_PHI2 ;
  wire T_HIRQ_B ;
  wire buf_oe_b ;
  wire buf_atob ;

  
  // 3 pin header with link to use either regulator or external 3V3 power for the board
  hdr1x03      L1 (
                   .p1(VDD_3V3_REG),
                   .p2(VDD_3V3),
                   .p3(VDD_3V3_EXT)
                   );


  MCP1700_3302E   REG3V3 (
                            .vin(VDD),
                            .gnd(VSS),
                            .vout(VDD_3V3_REG)
                            );


  // Radial electolytic, one per board on the main 5V supply
  cap22uf         CAP22UF(.minus(VSS),.plus(VDD));

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
                 .p2(T_UART_RX),
                 .p3(T_UART_TX)
                 );
  
 idc_hdr_40w CONN2 ( 
		     .p1(VDD_3V3_EXT),  .p2(VDD),
		     .p3(T_HA1),        .p4(VDD),
		     .p5(T_HA2),        .p6(VSS),
		     .p7(T_HRST_B),     .p8(T_UART_TX),
		     .p9(VSS),          .p10(T_UART_RX),
		     .p11(T_HCS_B),     .p12(T_RNW),
		     .p13(T_HA0),       .p14(VSS),
		     .p15(T_HD4),       .p16(T_HD5),
		     .p17(VDD_3V3_EXT), .p18(T_HD6),
		     .p19(T_HD2),       .p20(VSS),
		     .p21(T_HD1),       .p22(T_HD7),
		     .p23(T_HD3),       .p24(T_HD0),
		     .p25(VSS),         .p26(T_PHI2),
                     .p27(),            .p28(),
		     .p29(T_HIRQ_B),     .p30(VSS),
                     .p31(),            .p32(),
		     .p33(),            .p34(VSS),
		     .p35(),            .p36(),
                     .p37(),            .p38(),
		     .p39(VSS),         .p40(),
                     );

  // Pull up the host IRQ in case not connected externally (e.g. PTD)
  r10k        res0 ( .p0(T_HIRQ_B), .p1(VDD_3V3));
  
  
  // 9572 CPLD - 5V core and IO
  xc9572pc44  CPLD (
	            .p1(buf_oe_b),                    
	            .p2(buf_atob),
                    .p3(T_HIRQ_B),                    
	            .p4(MREQ_B),
	            .gck1(CLK),
	            .gck2(T_HCS_B),
	            .gck3(T_HA0),
	            .p8(T_RNW),
	            .p9(T_HRST_B),
	            .gnd1(VSS),
	            .p11(T_HA1),
	            .p12(T_PHI2),
	            .p13(T_HA2),
	            .p14(A15),
	            .tdi(TDI),
	            .tms(TMS),
	            .tck(TCK),
	            .p18(A14),
	            .p19(A13),
	            .p20(A12),
	            .vccint1(VDD),
	            .p22(A11),
	            .gnd2(VSS),
	            .p24(A10),
	            .p25(A9),
	            .p26(A8),
	            .p27(A7),
	            .p28(A6),
	            .p29(A5),
	            .tdo(TDO),
	            .gnd3(VSS),
	            .vccio(VDD_3V3),
	            .p33(A4),
	            .p34(A3),
	            .p35(A2),
	            .p36(A1),
	            .p37(A0),
	            .p38(INT_B),
	            .gsr(RESET_B),
	            .gts2(IOREQ_B),
	            .vccint2(VDD),
	            .gts1(WR_B),
	            .p43(RD_B),            
	            .p44(M1_B),
                    );

  // Use LVC245 for both instances for level shifting
  SN74245 U0 (
             .dir(buf_atob), .vdd(VDD_3V3),
             .a0(D6),     .gb(buf_oe_b),
             .a1(D7),     .b0(T_HD6),
             .a2(D4),     .b1(T_HD7),
             .a3(D5),     .b2(T_HD4),
             .a4(D2),     .b3(T_HD5),
             .a5(D3),     .b4(T_HD2),
             .a6(D0),     .b5(T_HD3),
             .a7(D1),     .b6(T_HD0),
             .vss(VSS),   .b7(T_HD1)
              );


   // Decoupling caps
   cap100nf CAP100N_0 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD_3V3 ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD_3V3 ));

endmodule
