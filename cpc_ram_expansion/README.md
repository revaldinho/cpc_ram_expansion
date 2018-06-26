# Amstrad CPC 512KByte RAM Expansion Card

This is a small project which contains three different implementations of a DK'Tronics compatible 512K Byte RAM expansion card for the Amstrad CPC computers.

  1. A 74 Series based 'Old School' card intended for DIYers for the 6128 and Plus machines
  2. An XC9572/36 CPLD based version of 1 (the original prototype), also for the 6128 and Plus machines
  3. A slightly modified version of 2. with more limited compatibility but supporting the older 464 and 664 machines

All variants have been built and tested on either CPC464 or CPC6128 as appropriate.

## The 'Old School' 74 Series card

This board uses only standard 74 Series logic ICs and a single SRAM chip. There are no devices which need programming and all parts are in through-hole packages to make for board which is easily assembled even by a beginner.

This card supports all 6128, 464 Plus and 6128 Plus machines but is _not_ suitable for the older 464 and 664 computers. 

The card is available directly from me - pm me via the [CPC Wiki Forum](http://www.cpcwiki.eu/forum) - or directly from SeeedStudio via their [Seeed Gallery](https://www.seeedstudio.com/gallery-index.html) pages.

The card has a [Mother MX4](http://www.cpcwiki.eu/forum/amstrad-cpc-hardware/mother-x4-board/) standard box connector rather than an edge connector. So to use the board you will need a Mother X4 or compatible expansion card. One possibility is to use my own [CPC 3 slot expansion backplane](https://github.com/revaldinho/cpc_ram_expansion/blob/master/cpc_backplane/README.md): again it's easily assembled and the PCBs are available directly from me or via [Seeed's Gallery](https://www.seeedstudio.com/gallery-index.html). Other options are [CPCCONMX4](https://oshpark.com/shared_projects/3yA33GYO) - a single slot card which plugs directly into the CPC edge connector - or [LambdaMikel's Expansion](http://www.cpcwiki.eu/forum/amstrad-cpc-hardware/motherx4-alternative-for-cpc-464-users) - a 4 slot version which replicates the edge connector.

## DK'Tronics Compatibility

The board is fully compatible with the DK'Tronics/Amstrad bank switching schemes described in the [DK'Tronics Peripheral Technical Manual](http://www.cpcwiki.eu/imgs/8/83/DK%27Tronics_Peripheral_-_Technical_Manual_%28Edition_1%29.pdf).

In this scheme there are 8 possible 64K banks, and each bank is split into 4 16K blocks.

Selecting a 64K bank is done by writing to the Z80 IO address 0x7Fxx with an 8 bit dataword 0b11cccbbb, where

  * ccc - picks one of 8 possible 64K banks
  * bbb - selects a block switching scheme within the chosen bank

The bank switching schemes for the 6128 and Plus machines are illustrated in the table below, where

  * '-' indicates access to internal RAM
  * 0-3 indicate access to the relevant block in the selected external bank
  
  |  Address\bbb  | 000  |  001  |  010  |  011  |  100  |  101  |  110  |  011  |
  | ------------- | ---- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
  |  1100-1111    |  -   |   3   |   3   |   3   |   -   |   -   |   -   |   -   |
  |  1000-1011    |  -   |   -   |   2   |   -   |   -   |   -   |   -   |   -   |
  |  0100-0111    |  -   |   -   |   1   |  **   |   0   |   1   |   2   |   3   |
  |  0000-0011    |  -   |   -   |   0   |   -   |   -   |   -   |   -   |   -   |
 
Note that bank 0 would normally select the single 64K expansion bank already in a 6128, but when the card is attached this bank is disabled and the first bank in the external expansion is accessed instead. In any case the total memory available with the card fitted is 576KBytes: the 64K internal RAM and the 512K external.

In the special case '**' marked in column '011' internal memory at 0x4000-0x7FFF is remapped to 0xC000-0xFFFF. This is handled internally in the CPC6128 and plus machines. The 464 and 664 don't perform this remapping. Further, the 464 and 664 do not write protect internal RAM when external memory is accessed. On the original DK-Tronics expansions these two issues were handled by backdriving the A15 and MREQ* signals on the bus, overdriving the values from the Z80 CPU in an electrical conflict. The Old School card doesn't do this, in common with most of the modern RAM expansions. So the card is compatible only with 6128 and the later CPC Plus machines. See later for a special 464 (CPLD based) expansion card. 

## Testing on the 6128

Both the 'Old School' card and the CPLD based prototype have been tested on an Amstrad 6128 using a number of programs.

  * Amstrad bank manager
  * DK'Tronics Bank manager
  * DK'Tronics Sillicon Disk (in AMSDOS and CP/M)
  * CP/M+, CP/M 2.2
  * Batman Forever Demo
  * 128K games including Gryzor, Hard Drivin', Robocop
  * Board test programs written in BASIC and BCPL included in the cpc/ subdirectory of this project

For testing two 74 Series cards were assembled, one using all 74HCT family components and the other a mix of mainly AHCT and some HCT parts. These are low power CMOS parts but with input stages optimized to work with the TTL levels of the bipolar 74LS logic in the Amstrad. The AHCT parts are faster than HCT, but there's no noticeable benefit in this case. 

The cards have been tested using both an original (ToTO) MX4 Mother expansion with power taken from the CPC and my own backplane expansion with power supplied from the CPC and from a variable external supply. Using the latter the 74 Series card was found to be significantly more tolerant of VDD variation than was the original CPLD based prototype. The prototype card passed all tests with an external power supply set between 4.35V and 5.5V. The 74 series based cards were both good down to around 3.5V. Some other expansions have reported problems on the original MX4 card, probably due to the small schottky diode drop in the VDD line, but all cards tested here had no problems at all given the wide tolerance to VDD. 

## Building the RAM Card

To build the RAM card you will need only the most basic of equipment

  * soldering iron
  * solder
  * small wire cutters
  * small long nosed pliers

## Bill of Materials

PCBs are available directly from me - pm me via the (http://www.cpcwiki.eu/forum "CPC Wiki Forum") - or from SeeedStudio via their (https://www.seeedstudio.com/gallery-index.html "Seed Gallery") pages. 

The following is a complete bill of materials for all other components from the supplier DigiKey in the UK, all prices in GBP.


|Index	|Quantity |Part Number	 |Description	                   |Customer Reference	  |Unit Price|Extended Price|
|-------|---------|--------------|---------------------------------|----------------------|----------|--------------|
|1	|1	  |1450-1027-ND	 |IC SRAM 4M PARALLEL 32DIP	   |512K x 8 SRAM	  |3.6	     |3.6           |
|2	|1	  |P15803CT-ND	 |CAP ALUM 22UF 20% 25V RADIAL	   |Electolytic Cap	  |0.2	     |0.2           |
|3	|1	  |3M157291-ND	 |CONN HEADER 50POS DL R/A GOLD	   |Right Angle MX4 Conn. |0.82	     |0.82          |
|4	|1	  |296-2100-5-ND |IC FF D-TYPE SNGL 6BIT 16DIP	   |74HCT174	          |0.45	     |0.45          |
|5	|1	  |296-2136-5-ND |IC DUAL 2BIT BISTABLE LTCH 16DIP |74HCT75	          |0.76	     |0.76          |
|6	|3	  |296-1603-5-ND |IC GATE NAND 4CH 2-INP 14DIP	   |74HCT00	          |0.35	     |1.05          |
|7	|1	  |296-2086-5-ND |IC GATE NAND 3CH 3-INP 14DIP	   |74HCT10	          |0.43	     |0.43          |
|8	|1	  |296-8380-5-ND |IC GATE NOR 4CH 2-INP 14DIP	   |74HCT02	          |0.35	     |0.35          |
|9	|1	  |296-1615-5-ND |IC GATE OR 4CH 2-INP 14DIP	   |74HCT32	          |0.35	     |0.35          |
|10	|1	  |AE10354-ND	 |CONN IC DIP SOCKET 32POS TIN	   |SRAM Socket	          |0.35	     |0.35          |
|11	|6	  |609-4712-ND	 |CONN IC DIP SOCKET 14POS TIN	   |IC Sockets	          |0.2	     |1.2           |
|12	|2	  |609-4713-ND	 |CONN IC DIP SOCKET 16POS TIN	   |IC Sockets	          |0.22	     |0.44          |
|13	|7	  |BC1154CT-ND	 |CAP CER 0.1UF 25V Y5V RADIAL	   |Decoupling Caps	  |0.19	     |1.33          |
|       |         |              |                                 |                      |Total     |11.33         |


## The CPC464 RAM Expansion Card

A third variant of the card provides some support for the CPC464. This is basically the same CPLD based card used to prototype the CPC6128 version but with a different CPLD firmware.

The issues affecting the 464 and 664 are described above in the compatiblity section. It's not possible to work around the remapping of internal CPC RAM from block 2 to block 4 (video memory) without some motherboard modifications or backdriving signals against the Z80 CPU. So with this limitation in mind the 464 expansion can't support all modes perfectly.

The other issue affecting these older machines is that the internal RAM isn't write protected when external RAM is accessed. The 'RAMDIS' only controls the output enables of the internal RAM.

The CPC464 version of the card uses one 64K Bank of the expansion to provide a 'shadow' memory which all but replaces the CPC's internal memory.  Whenever internal RAM is written, the corresponding byte in the shadow area is written too. All memory read which would normally be from internal RAM are taken from the shadow RAM. So, normally corresponding internal memory and shadow memory locations will hold the same values. The difference comes when external RAM is accessed. When an external bank is accessed, the shadow memory contents are write protected while the actual internal memory becomes corrupt. Since all reads are now taken from the shadow RAM it doesn't usually matter that internal RAM has been altered. 

This scheme works well, providing a perfect implementation of the RAM banking schemes 4-7.

What works less well are the schemes 1-3. In these modes any writes to the external RAM banks in block 3 (0xC000-0xFFFF) overlay the internal screen memory. So, although it doesn't usually matter than internal RAM is corrupted now by external memory writes thanks to the shadow memory, in this case corruption can produce artifacts on screen. 

Note that in mode 3 the shadow memory does perform the expected remapping from block 1 to block 3.

So, a perfect implementation of modes 4-7 and imperfections in modes 1-3. How does this work in practice?

The following programs/features work perfectly

  * DK'Tronics silicon disk (in AMSDOS and CP/M 2.2)
  * DK'Tronics bank switching software
  * Robocop and ChaseHQ both run perfectly with digitized speech (normally a 6128 only feature)
  * A 6128 only version of Gryzor runs with music playing
  * Masterfile 128
  
These next few programs run, but with varying amounts of 'snow' on screen

  * CPM Plus (needing to use the DK'Tronics |Emulate RSX to get started)
  * CPM 2.2 with expanded TPA
  * Hard Drivin' detects the expanded memory, loads the 128K version and play music during the game but exhibits a small amount of snow.
  
The following programs don't run at all

  * Double Dragon produces garbage on screen and is unresponsive/crashed

All in all then a mixed result. Having the Silicon Disk in AMSDOS and particularly CP/M 2.2 though is possibly worth building the board for some.


## Images

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/protoboard.jpg" alt="Assembled V1.00 Prototype" width="640">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_Eagle_top_v1.00.png" alt="V1.00 PCB Image from Eagle" width="640">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_top_v1.00.png" alt="V1.00 PCB Image" width="640">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_Eagle_top_v1.01.png" alt="V1.01 PCB Image from Eagle" width="640">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_top_v1.01.png" alt="V1.01 PCB Image" width="640">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_SN74_Eagle_top_v2.01.png" alt="V2.01 PCB Image from Eagle" width="800">
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_SN74_top_v2.01.png" alt="V2.01 PCB Image" width="800">

