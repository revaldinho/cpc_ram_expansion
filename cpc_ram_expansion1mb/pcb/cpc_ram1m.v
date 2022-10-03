//
// cpc_ram1m netlist
//
// netlister.py format
//
// (c) Revaldinho, 2018
//
// This code is part of the cpc_ram_expansion set of Amstrad CPC peripherals.
// https://github.com/revaldinho/cpc_ram_expansion
//
// Copyright (C) 2018 Revaldinho
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

module cpc_ram1m ();

  // wire declarations
  supply0 VSS;
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
  wire RAMCS0_B;
  wire RAMCS1_B;

  wire HIADR4,HIADR3,HIADR2,HIADR1,HIADR0;
  wire RAMOE_B;
  wire RAMWE_B;

  wire TMS;
  wire TDI;
  wire TDO;
  wire TCK;

  wire dip0, dip1, dip2, dip3;


  // Radial electolytic, one per board on the main 5V supply
  cap22uf         CAP22UF(.minus(VSS),.plus(VDD));

  // DIP8 switches for CPLD config
  DIP4        dipsw0(
                     .sw0_a(dip0), .sw0_b(VDD),
                     .sw1_a(dip1), .sw1_b(VDD),
                     .sw2_a(dip2), .sw2_b(VDD),
                     .sw3_a(dip3), .sw3_b(VDD),
                     );

  // High value pull down (>2K) to be overridden by pull up when switch closed
  r3k3_sil5   sil0 (
                    .common(VSS),
                    .p0(dip3),
                    .p1(dip2),
                    .p2(dip1),
                    .p3(dip0),
                    );

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

  // 9572 CPLD
  xc9572pc44  CPLD (
                    .p1(A14),
	            .p2(MREQ_B),
	            .p3(RAMDIS),
	            .p4(RFSH_B),
	            .gck1(CLK),
	            .gck2(RAMRD_B),
	            .gck3(dip3),
	            .p8(dip2),
	            .p9(dip1),
	            .gnd1(VSS),
	            .p11(dip0),
	            .p12(RAMOE_B),
	            .p13(HIADR3),
	            .p14(HIADR4),
	            .tdi(TDI),
	            .tms(TMS),
	            .tck(TCK),
	            .p18(HIADR2),
	            .p19(HIADR1),
	            .p20(A8),
	            .vccint1(VDD),
	            .p22(RAMWE_B),
	            .gnd2(VSS),
	            .p24(HIADR0),
	            .p25(RAMCS1_B),
	            .p26(RAMCS0_B),
	            .p27(D7),
	            .p28(D6),
	            .p29(D5),
	            .tdo(TDO),
	            .gnd3(VSS),
	            .vccio(VDD),
	            .p33(D4),
	            .p34(D3),
	            .p35(D2),
	            .p36(D1),
	            .p37(D0),
	            .p38(RD_B),
	            .gsr(BUSRESET_B),
	            .gts2(A15),
	            .vccint2(VDD),
	            .gts1(WR_B),
	            .p43(A15),
	            .p44(IOREQ_B),
                    );


  // Alliance 512K x 8 SRAM - address pins wired to suit layout
  bs62lv4006  SRAM0 (
                    .a18(HIADR4),  .vcc(VDD),
                    .a16(HIADR2),  .a15(HIADR1),
                    .a14(HIADR0),  .a17(HIADR3),
                    .a12(A5),  .web(RAMWE_B),
                    .a7(A6),  .a13(A4),
                    .a6(A7),  .a8(A2),
                    .a5(A8),  .a9(A3),
                    .a4(A9),  .a11(A1),
                    .a3(A10),  .oeb(RAMOE_B),
                    .a2(A11),  .a10(A0),
                    .a1(A13),  .csb(RAMCS0_B),
                    .a0(A12),  .d7(D7),
                    .d0(D0),  .d6(D6),
                    .d1(D1),  .d5(D5),
                    .d2(D2),  .d4(D4),
                    .vss(VSS),  .d3(D3)
                    );
  bs62lv4006  SRAM1 (
                    .a18(HIADR4),  .vcc(VDD),
                    .a16(HIADR2),  .a15(HIADR1),
                    .a14(HIADR0),  .a17(HIADR3),
                    .a12(A5),  .web(RAMWE_B),
                    .a7(A6),  .a13(A4),
                    .a6(A7),  .a8(A2),
                    .a5(A8),  .a9(A3),
                    .a4(A9),  .a11(A1),
                    .a3(A10),  .oeb(RAMOE_B),
                    .a2(A11),  .a10(A0),
                    .a1(A13),  .csb(RAMCS1_B),
                    .a0(A12),  .d7(D7),
                    .d0(D0),  .d6(D6),
                    .d1(D1),  .d5(D5),
                    .d2(D2),  .d4(D4),
                    .vss(VSS),  .d3(D3)
                    );

   // Decoupling caps for CPLD and one per SRAM
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_3 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_4 (.p0( VSS ), .p1( VDD ));

endmodule
