CC = iverilog
SIM = vvp
VIEWER = gtkwave

CFLAGS = -g2012 -Wall

RTL_DIR = src/rtl
SIM_DIR = src/tb
BUILD_DIR = build

TB ?= cfi_fsm_tb

RTL_FILES = $(wildcard $(RTL_DIR)/*.sv)
SIM_FILE  = $(SIM_DIR)/$(TB).sv

OUT   = $(BUILD_DIR)/$(TB).vvp
WAVES = $(BUILD_DIR)/$(TB).vcd

all: compile
	$(SIM) $(OUT)
	$(VIEWER) $(WAVES) &

compile:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(OUT) $(RTL_FILES) $(SIM_FILE)

clean:
	rm -rf $(BUILD_DIR)