LOGFILE=make.log
WAVEFORMAT=fst
SEED=1
TIMEOUT=50000
DUMP=0
VIVADO_VERSION=2020.2

ifeq ($(VIVADO_PATH),)
  ifeq ($(OS), Windows_NT)
    VIVADO_PATH=/mnt/c/Xilinx/Vivado/
  else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
      VIVADO_PATH=/tools/Xilinx/Vivado/
    endif
    ifeq ($(UNAME_S),Darwin)
      VIVADO_PATH=$(HOME)/tools/Xilinx/Vivado/
    endif
  endif
endif


all: compile run

lint:
	verilator --lint-only -Wall \
        --error-limit 0 \
        -Wno-PINCONNECTEMPTY \
        -Wno-ASSIGNDLY \
        -f cmdfile \
        -I../hdl/ \
        -D__ICARUS__ \
        -DNOXILINXFIFO \
        -DFASTFIFOSIM \
        -DLINT \
        --top-module cw341_top \
        2>&1 | tee lint.out \

compile:
	iverilog -ccmdfile \
	tb.v \
	hr_model.v \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-DHYPERRAM_MODEL \
	-I../hdl/ \
	-I. \
	-y/$(VIVADO_PATH)/$(VIVADO_VERSION)/ids_lite/ISE/verilog/src/unisims/ \
	-y/$(VIVADO_PATH)/$(VIVADO_VERSION)/data/verilog/src/unisims/ \
	$(VIVADO_PATH)/$(VIVADO_VERSION)/ids_lite/ISE/verilog/src/glbl.v \
	-DGOOGLE_VAULT_AES \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pTIMEOUT=$(TIMEOUT) \

run:
	vvp -l$(LOGFILE) a.out -$(WAVEFORMAT)

clean:
	rm -f a.out
