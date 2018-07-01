# CPC 512K RAM Expansion

This is a small project which contains three different implementations of a DK'Tronics compatible 512K Byte RAM expansion card for the Amstrad CPC computers.

  1. A 74 Series based 'Old School' card intended for DIYers for the 6128 and Plus machines
  2. An XC9572/36 CPLD based version of 1 (the original prototype), also for the 6128 and Plus machines
  3. A slightly modified version of 2. with more limited compatibility but supporting the older 464 and 664 machines

All variants have been built and tested on either CPC464 or CPC6128 as appropriate.

Project files are split into 6 directories

  * cpc/ - collection of RAM test programs in BASIC and BCPL to run on the Amstrad and utilities for converting files to/from MacOS text formats
  * gates/ - Verilog testbench and libraries for simulation
  * misc/ - miscellaneous files
  * pcb/ - all PCB netlist and layout script source files (building PCBs requires installation of my other netlister.py project)
  * src/ - Verilog source code for the CPLD versions of the boards
  * xc9572/ - Xilinx ISE project and Makefiles for the CPLD versions of the boards

NB  In the pcb directory there are two versions of the 74 Series Board. Both have been tested with the CPC6128 and show no real difference in operation.

  * v2.01 - the orignal 74 series board with IC footprint corrections
  * v2.10 - a revised design which prefers to use the 6128 internal expansion for bank 1 rather than the one on the expansion card.

Both designs have been tested on a 6128 and both work well, so since the v2.01 is slightly simpler and has 1 fewer IC, that is considered the
'production' version.

Full information on the project are on the [Project Wiki Page](https://github.com/revaldinho/cpc_ram_expansion/wiki/CPC-512K-RAM-Expansion)


