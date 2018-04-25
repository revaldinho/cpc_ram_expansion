# Amstrad CPC RAM Expansion

This is a small project aiming to create two different implementations for a 512KByte RAM expansion card for the Amstrad CPC computers.

The first implementation uses a Xilinx XC9572 CPLD to hold all the logic, producing a simple 2 chip solution with a static RAM.

The second implemention will replace the Xilinx CPLD with 8 or 9 74 series components, to make a simple kit which can be assembled with no need for any microcontroller or FPGA/CPLD programming at all. 

Unless otherwise noted, all files and the project are copyright by the contributors and licensed under the GPL. Contact us by raising an [issue on GitHub](https://github.com/revaldinho/cpc_ram_expansion/issues)

## Current status

### CPLD Version

Prototype version, V1.00 PCB with XC9572 CPLD and SRAM has been assembled and initial tests are working with my Amstrad CPC464.

Some BASIC and BCPL test code is available in the cpc/ subdirectory. These tests have been run successfully using an external PSU and all tests pass between 4.35V and 5.5V. Running at nominal 5V the board draws ~43mA. Swapping the link to the lower position and the board runs fine powered from the CPC edge connector instead.

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/protoboard.jpg" alt="Assembled V1.00 Prototype" width="640">

All CPLD code is included in this git repository and the original v1.00 board is available via OSHPark as an Eagle board file, or for ordering directly from OSHPark: [CPC 512K RAM](https://oshpark.com/shared_projects/UwZ7VwqU).

### 74XX Series Version

THe gate level netlist and PCB are both derived from the working CPLD code above, but not yet verified in simulation.

## Example PCB for XC9572 CPLD Version

 *NB This version has requires the IDC Connector to be mounted on the rear side of the card to be used with an MX4 board and requires then a non-keyed female connector on the board*
 
<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_Eagle_top_v1.00.png" alt="V1.00 PCB Image from Eagle" width="640">

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_top_v1.00.png" alt="V1.00 PCB Image" width="640">

This PCB is available as an Eagle board file, or for ordering directly from OSHPark: [CPC 512K RAM](https://oshpark.com/shared_projects/UwZ7VwqU)

A revised PCB layout is available here as V1.01. This is an autorouted version of the same V1.00 netlist with just the connector pins swapped over.

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_Eagle_top_v1.01.png" alt="V1.01 PCB Image from Eagle" width="640">

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_top_v1.01.png" alt="V1.01 PCB Image" width="640">

This PCB is also available on OSHPark: [CPC 512K RAM V1.01](https://oshpark.com/shared_projects/h3dN136P)


## Example PCB for 74 Series Version

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_SN74_Eagle_top_v2.00.png" alt="V2.00 PCB Image from Eagle" width="800">

<img src="https://github.com/revaldinho/cpc_ram_expansion/blob/master/img/CPC_512K_RAM_SN74_top_v2.00.png" alt="V2.00 PCB Image" width="800">


The 74 Series version here has the connector orientation correct for the MX4 boards, but is still work in progress as far as the netlist and layout go.
