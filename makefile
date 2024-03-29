BOARD		=	tangnano9k
FAMILY		=	GW1N-9C
DEVICE		=	GW1NR-LV9QN88PC6/I5
PORT		=	/dev/ttyUSB0
BUILD		=	build
PROJECT		=	lcd
MAIN_MODULE =	main

SOURCES		=	main.v \
				lcd_driver.v \

HEADERS		=	lcd_h.v

SIM_SOURCES	=	lcd_tb.v \
				lcd_driver.v

######################################################################

OUTPUT = ${BUILD}/${PROJECT}

all: load

# Synthesis
${OUTPUT}.json: ${SOURCES} ${HEADERS}
	yosys -p "read_verilog -sv ${SOURCES}; synth_gowin -top ${MAIN_MODULE} -json ${OUTPUT}.json"

# Place and Route
${OUTPUT}_pnr.json: ${OUTPUT}.json
	nextpnr-gowin --json ${OUTPUT}.json --freq 27 --write ${OUTPUT}_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
${OUTPUT}.fs: ${OUTPUT}_pnr.json
	gowin_pack -d ${FAMILY} -o ${OUTPUT}.fs ${OUTPUT}_pnr.json

# Program Board ram
load: ${OUTPUT}.fs
	openFPGALoader -b ${BOARD} ${OUTPUT}.fs -d ${PORT}

# Program Board flash
flash: ${OUTPUT}.fs
	openFPGALoader -b ${BOARD} -f ${OUTPUT}.fs -d ${PORT} -r

# Simulation
simulate: ${SIM_SOURCES} ${HEADERS}
	iverilog -o ${OUTPUT}.o -s test ${SIM_SOURCES}
	vvp ${OUTPUT}.o

.PHONY: load
.INTERMEDIATE: ${OUTPUT}_pnr.json ${OUTPUT}.json
