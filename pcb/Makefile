
netlister_dir ?= ~/Documents/Development/git/netlister

ALLLIBS ?= $(shell ls -1 ${netlister_dir}/lib/*.lib)


%.net : %.v ${ALLLIBS}
	netlister.py -i $*.v \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-o $*.net \
	-f net

%.scr : %.v ${ALLLIBS} %.footer common.header
	netlister.py \
	-i $*.v \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-o $*.scr \
	-f scr \
	-d common.header \
	-t $*.footer


all: cpc_ram_board.scr cpc_ram_board.net cpc_ram_board_9572xl.scr  cpc_ram_board_9572xl.net

clean:
	rm -f *~ *scr *net
