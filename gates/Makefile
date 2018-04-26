



# make executable
cpc_512k_ram_tb.exe:	cpc_512k_ram_tb.v lib74.v libram.v
	iverilog cpc_512k_ram_tb.v lib74.v libram.v
	mv a.out cpc_512k_ram_tb.exe

cpc_512k_ram_tb.vcd:	cpc_512k_ram_tb.exe
	./cpc_512k_ram_tb.exe | tee cpc_512k_ram_tb.log
	mv dump.vcd cpc_512k_ram_tb.vcd

all:	cpc_512k_ram_tb.vcd
