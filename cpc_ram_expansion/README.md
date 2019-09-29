# CPC 512K RAM Expansion

This is a small project which contains three different implementations of a DK'Tronics compatible 512K Byte RAM expansion card for the Amstrad CPC computers.

  1. A 74 Series based 'Old School' card intended for DIYers for the 6128 and Plus machines
  2. An XC9572/36 CPLD based universal card which is fully compatible with all CPC machines, including the older 464/664

All variants have been built and tested on either CPC464 and/or CPC6128 as appropriate.

Project files are split into 6 directories

  * cpc/ - collection of RAM test programs in BASIC and BCPL to run on the Amstrad and utilities for converting files to/from MacOS text formats
  * gates/ - Verilog testbench and libraries for simulation
  * misc/ - miscellaneous files
  * pcb/ - all PCB netlist and layout script source files (building PCBs requires installation of my other netlister.py project)
  * src/ - Verilog source code for the CPLD versions of the boards
  * xc9572/ - Xilinx ISE project and Makefiles for the CPLD versions of the boards

Full information on the project are on the [Project Wiki Page](https://github.com/revaldinho/cpc_ram_expansion/wiki/CPC-512K-RAM-Expansion)


