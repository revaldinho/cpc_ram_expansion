netlister_dir ?= ../../../netlister

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
	-l ${netlister_dir}/lib/diode.lib \
	-l ${netlister_dir}/lib/74series.lib \
	-l ${netlister_dir}/lib/74series_soic.lib \
	-l ${netlister_dir}/lib/switches.lib \
	-l ${netlister_dir}/lib/i2c.lib \
	-o $*.net \
	-f net

%.scr : %.v_cpp ${ALLLIBS} %.footer_cpp ../../common_pcb/common.header
	netlister.py \
	-i $*.v_cpp \
	-l ${netlister_dir}/lib/memory.lib \
	-l ${netlister_dir}/lib/idc_connectors.lib \
	-l ${netlister_dir}/lib/l1a-custom.lib \
	-l ${netlister_dir}/lib/xilinx.lib \
	-l ${netlister_dir}/lib/rcl.lib \
	-l ${netlister_dir}/lib/triac.lib \
	-l ${netlister_dir}/lib/diode.lib \
	-l ${netlister_dir}/lib/74series.lib \
	-l ${netlister_dir}/lib/74series_soic.lib \
	-l ${netlister_dir}/lib/switches.lib \
	-l ${netlister_dir}/lib/i2c.lib \
	-o $*.scr \
	-f scr \
	-u \
	-d ../../common_pcb/common.header \
	-t $*.footer_cpp



clean:
	rm -f *~ *scr *net *_cpp
