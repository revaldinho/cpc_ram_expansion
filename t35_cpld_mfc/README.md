

```
 +-------------------+              +---+
 |  PC[7:0]/DOUT[7:0]|==============|245|==**====================== Data[7:0]
 |                   |           +--|oe |  ||
 |                   |           |+-|dir|  ||
 |                   |           || +---+  ||
 | PD[15:12]/DIN[3:0]|===========||========**
 |  PB[23:16]/A[15:0]|===========||========||======*=============== A[15:8]
 |     PD[7:0]/A[7:0]|===========||========||======*=============== A[7:0]
 |                   |           || 2      ||8     | 3
 |                   |    +---------------------------------+
 |                   |    |   oeb dir    D[7:0]  A[15,14,13]|
 |        PB[0]/gpio0|-**-| gpio0[romselwr]            mreqb|------ MREQB
 |        PB[1]/gpio1|-**-| gpio1[hiromrd]            ioreqb|------ IOREQB
 |        PB[2]/gpio2|-**-| gpio2[loromrd]               wrb|------ WRB
 |        PB[3]/gpio3|-**-| gpio3                        rdb|------ RDB
 |        PB[4]/gpio4|-**-| gpio4                      romen|------ ROMEN
 |        PB[5]/gpio5|-**-| gpio5                     romdis|--|>|- ROMDIS
 |        PC[8]/gpio6|-**-| gpio6[romvalid]            waitb|------ READY
 |        PC[9]/gpio7|-**-| gpio7                        clk|------ CLK
 |                   | || |                           resetb|------ RESETB 
 |                   | || |                              m1b|------ M1B   
 |                   | || |                           busreq|------ BUSREQ
 |                   | || |                           busack|------ BUSACK
 |                   | || |                             intb|------ INT   
 |                   | || |                                 |13
 |                   | || |                             JTAG|====== JTAG TDO/TMS/TDI/TCK
 |                   | || +---------------------------------+ 4
 |       PC[10]/gpio8| || 8          
 |       PC[11]/gpio9| ++========================================== Box conn 2: 10W (PMOD 12W ?)
 |      PB[10]/gpio10|    
 |      PB[11]/gpio11|                                             
 |      PD[10]/gpio12|============================================= Box conn 2: 10W (PMOD 12W ? )
 |      PD[11]/gpio13|         
 |      PE[10]/gpio14|                                             
 |      PE[11]/gpio14|                                             
 |                   |                                         
 |      PE[24]/gpio16|                                         
 |      PE[25]/gpio17|============================================= Conn 3: 4 pin I2C (PMOD 4W ?)
 |                   |                                      ___
 |              DAC0 |--o pin                             o|o_o|  L1 [5V_CPC vs 5V_EXT]                                           
 |              DAC1 |--o pin                             _____
 +-------------------+                                    o-o o  CONN0 5V_EXT     


Questions
---------

T35 RESET access ? Separate on off (use ext supply/link) ?

Notes
-----

- USB/VIN connection needs cutting on T35 to allow use with CPC 5V in
- 3V3 supply for 9572XL parts?
  o could be second link to use T25 3V3 output [250mA]?
  o need a second link for VDD_Core pins + separate decap          
- can remove '245 and short A-B if T35 can turnaround bus quickly enough

PMOD Specs
----------

https://www.digilentinc.com/Pmods/Digilent-Pmod_%20Interface_Specification.pdf

Also check BlackIce pin out


CPLD Notes

User IO Available = 34
CPLD Tot = 8 + 2 + 8 + 3 + 13 = 34

T35 Notes

Ports Available

B[5:0], [11,10], [23:16]
C[11:0]
D[9:0], [15:11]
E[10,11,24,25,26]

SW Notes
--------

CPLD can create easier conditions to deal with e.g.

ROMSEL_WR - !A13 & !IOREQB & !WRB

HIROM_RD  - !ROMENB & A14 & ROMVALID

LOROM_RD  - !ROMENB & !A14

CPLD output signals 

ROMDIS    - !ROMENB & (ROMVALID + !A14)

OEB       - !ROMDIS

DIR       - 1'b1 - always T34-> CPC in this application

Init
   ROMVALID = 0
   Tristate DOUT

On ROMSEL
   sample DATA
   save into ROMSEL
   set ROMVALID
   while ROMSEL {}

On HIROM_RD
   sample ADRHI
   sample ADRLO
   DOUT = rom[ROMSEL][ADR&0x3FFF]
   while HIROM_RD{}
   Tristate DOUT

On LOROM_RD
   sample ADRHI
   sample ADRLO
   DOUT = lorom[ADR&0x3FFF]
   while LOROM_RD{}
   Tristate DOUT
```