



# make executable
cpc_512k_ram_tb.exe:	cpc_512k_ram_tb.v lib74.v libram.v 
	iverilog -DDELAY_SIM cpc_512k_ram_tb.v lib74.v libram.v
	mv a.out cpc_512k_ram_tb.exe

cpc_512k_ram_tb.vcd:	cpc_512k_ram_tb.exe
	./cpc_512k_ram_tb.exe | tee cpc_512k_ram_tb.log
	mv dump.vcd cpc_512k_ram_tb.vcd

clean:
	rm -f *vcd
	rm -f *exe

all:	cpc_512k_ram_tb.vcd
