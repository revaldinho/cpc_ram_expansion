setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc_ram_expansion/cpc_ram_expansion/releases/rc-7-gladiator/cpld_ram512k_v110_xc9536-10-PC44.jed"
Verify -p 1 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc_ram_expansion/cpc_ram_expansion/releases/rc-6-fighter/cpld_ram512k_v110_xc9536-10-PC44.jed"
Verify -p 1 
Erase -p 1 
ReadIdcode -p 1 
ReadIdcode -p 1 
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc_ram_expansion/cpc_ram_expansion/releases/rc-7-gladiator/cpld_ram512k_v110_xc9572-10-PC44.jed"
Program -p 1 -e -v 
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc-cplink/xilinx/cpld_fifo_xc9536-10-PC44.jed"
Program -p 1 -e -v 
Verify -p 1 
Verify -p 1 
Program -p 1 -e -v 
Identify -inferir 
identifyMPM 
Identify -inferir 
identifyMPM 
Identify -inferir 
identifyMPM 
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc-cplink/xilinx/cpld_fifo_xc9536-10-PC44.jed"
Program -p 1 -e -v 
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc_ram_expansion/cpc_ram_expansion/releases/rc-6-fighter/cpld_ram512k_v110_xc9536-10-PC44.jed"
Program -p 1 -e -v 
Program -p 1 -e -v 
assignFile -p 1 -file "/home/parallels/Documents/local_git/cpc_ram_expansion/cpc_ram_expansion/releases/rc-7-gladiator/cpld_ram512k_v110_xc9536-10-PC44.jed"
Program -p 1 -e -v 
setMode -bs
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
saveProjectFile -file "/home/parallels//auto_project.ipf"
setMode -bs
setMode -bs
deleteDevice -position 1
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
