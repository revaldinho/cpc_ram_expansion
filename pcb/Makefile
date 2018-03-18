
netlister_dir ?= ~/Documents/Development/sockets/trunk/netlister

ALLLIBS ?= $(shell ls -1 ${netlister_dir}/lib/*.lib)

cpc_ram_board.net: cpc_ram_board.v ${ALLLIBS}
	netlister.py -i cpc_ram_board.v \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-o cpc_ram_board.net \
	-f net

cpc_ram_board.scr: cpc_ram_board.v ${ALLLIBS} cpc_ram_board.footer cpc_ram_board.header
	netlister.py \
	-i cpc_ram_board.v \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-o cpc_ram_board.scr \
	-f scr \
	-d cpc_ram_board.header \
	-t cpc_ram_board.footer


all: cpc_ram_board.scr cpc_ram_board.net

clean:
	rm -f *~ *scr *net
