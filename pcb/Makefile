
netlister_dir ?= ~/Documents/Development/git/netlister

ALLLIBS ?= $(shell ls -1 ${netlister_dir}/lib/*.lib)

ARGS ?= 

%.v_cpp: %.v
	grep -v '^# ' $*.v | cpp -E ${ARGS} | grep -v '^# ' > $*.v_cpp

%.footer_cpp: %.footer
	grep -v '^# ' $*.footer | cpp -E ${ARGS} | grep -v '^# ' > $*.footer_cpp

%.net : %.v_cpp ${ALLLIBS}
	netlister.py -i $*.v_cpp \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-l ${netlister_dir}/lib/74series.lib \
	-o $*.net \
	-f net

%.scr : %.v_cpp ${ALLLIBS} %.footer_cpp common.header
	netlister.py \
	-i $*.v_cpp \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-l ${netlister_dir}/lib/74series.lib \
	-o $*.scr \
	-f scr \
	-d common.header \
	-t $*.footer_cpp


all: cpc_ram_board.scr cpc_ram_board.net cpc_ram_board_9572xl.scr  cpc_ram_board_9572xl.net

clean:
	rm -f *~ *scr *net *_cpp
