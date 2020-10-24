#FIRMWARE
FIRM_ADDR_W ?=14

#SRAM
SRAM_ADDR_W ?=14

#DDR
USE_DDR ?=1
RUN_DDR ?=1

HW_DDR_ADDR_W:=30
CACHE_ADDR_W:=24

#ROM
BOOTROM_ADDR_W:=12

#Init memory (only works in simulation or in FPGA)
INIT_MEM ?=1

#Peripheral list (must match respective submodule or folder name in the submodules directory)
PERIPHERALS:=UART
#PERIPHERALS:=UART TIMER

#
#SIMULATION
#
SIMULATOR ?=icarus
SIM_LIST:=icarus ncsim
LOCAL_SIM_LIST ?=icarus

ifeq ($(SIMULATOR),ncsim)
	SIM_SERVER=micro7.lx.it.pt
	SIM_USER=user19
endif

#
#FPGA COMPILATION
#
FPGA=AES-KU040-DB-G
#LOCAL_FPGA_LIST=CYCLONEV-GT-DK AES-KU040-DB-G

#set according to FPGA
ifeq ($(FPGA),AES-KU040-DB-G)
	FPGA_SERVER=pudim-flan.iobundle.com
	FPGA_USER=$(USER)
	FPGA_OBJ=synth_system.bit
else ifeq ($(FPGA),CYCLONEV-GT-DK)
	FPGA_SERVER=pudim-flan.iobundle.com
	FPGA_USER=$(USER)
	FPGA_OBJ=output_files/top_system.sof
endif

#BOARD TEST
BOARD_LIST?=AES-KU040-DB-G 
#BOARD EXECUTION
BOARD=AES-KU040-DB-G
LOCAL_BOARD_LIST=CYCLONEV-GT-DK
#LOCAL_BOARD_LIST=AES-KU040-DB-G

#set according to FPGA
ifeq ($(BOARD),AES-KU040-DB-G)
	BOARD_SERVER=baba-de-camelo.iobundle.com
	BOARD_USER=$(USER)
	FPGA_OBJ=synth_system.bit
else ifeq ($(BOARD),CYCLONEV-GT-DK)
	BOARD_SERVER=pudim-flan.iobundle.com
	BOARD_USER=$(USER)
	FPGA_OBJ=output_files/top_system.sof
endif

#ROOT DIR ON REMOTE MACHINES
REMOTE_ROOT_DIR=./sandbox/iob-soc

#ASIC
ASIC_NODE:=umc130

#DOC_TYPE
#DOC_TYPE:=presentation
DOC_TYPE:=pb


#############################################################
#DO NOT EDIT BEYOND THIS POINT
#############################################################

#object directories
HW_DIR:=$(ROOT_DIR)/hardware
SIM_DIR=$(HW_DIR)/simulation/$(SIMULATOR)
FPGA_DIR=$(HW_DIR)/fpga/$(BOARD)
ASIC_DIR=$(HW_DIR)/asic/$(ASIC_NODE)

SW_DIR:=$(ROOT_DIR)/software
FIRM_DIR:=$(SW_DIR)/firmware
BOOT_DIR:=$(SW_DIR)/bootloader
CONSOLE_DIR:=$(SW_DIR)/console
PYTHON_DIR:=$(SW_DIR)/python

DOC_DIR:=$(ROOT_DIR)/document/$(DOC_TYPE)

#submodule paths
SUBMODULES_DIR:=$(ROOT_DIR)/submodules
SUBMODULES=CPU CACHE $(PERIPHERALS)
$(foreach p, $(SUBMODULES), $(eval $p_DIR:=$(SUBMODULES_DIR)/$p))

#defmacros
DEFINE+=$(defmacro)BOOTROM_ADDR_W=$(BOOTROM_ADDR_W)
DEFINE+=$(defmacro)SRAM_ADDR_W=$(SRAM_ADDR_W)
DEFINE+=$(defmacro)FIRM_ADDR_W=$(FIRM_ADDR_W)
DEFINE+=$(defmacro)CACHE_ADDR_W=$(CACHE_ADDR_W)

SIM_DDR_ADDR_W=24
ifeq ($(word 1, $(MAKECMDGOALS)),fpga)
DDR_ADDR_W:=$(HW_DDR_ADDR_W)
else
DDR_ADDR_W:=$(SIM_DDR_ADDR_W)
endif

ifeq ($(USE_DDR),1)
DEFINE+=$(defmacro)USE_DDR
DEFINE+=$(defmacro)DDR_ADDR_W=$(DDR_ADDR_W)
ifeq ($(RUN_DDR),1)
DEFINE+=$(defmacro)RUN_DDR
endif
endif
ifeq ($(INIT_MEM),1)
DEFINE+=$(defmacro)INIT_MEM
endif
DEFINE+=$(defmacro)N_SLAVES=$(N_SLAVES)

#address selection bits
E:=31 #extra memory bit
ifeq ($(USE_DDR),1)
P:=30 #periphs
B:=29 #boot controller
else
P:=31
B:=30
endif

DEFINE+=$(defmacro)E=$E
DEFINE+=$(defmacro)P=$P
DEFINE+=$(defmacro)B=$B

SIM_BAUD:=10000000
HW_BAUD:=115200


ifeq ($(word 1, $(MAKECMDGOALS)),fpga)
BAUD:=$(HW_BAUD)
else
BAUD:=$(SIM_BAUD)
endif


DEFINE+=$(defmacro)BAUD=$(BAUD)

ifeq ($(FREQ),)
DEFINE+=$(defmacro)FREQ=100000000
else
DEFINE+=$(defmacro)FREQ=$(FREQ)
endif


all: usage

usage:
	@echo "INFO: Top target must me defined so that target \"run\" can be found"
	@echo "      For example, \"make sim INIT_MEM=0\"."
	@echo "Usage: make target [parameters]"

#create periph indices and directories
N_SLAVES:=0
$(foreach p, $(PERIPHERALS), $(eval $p=$(N_SLAVES)) $(eval N_SLAVES:=$(shell expr $(N_SLAVES) \+ 1)))
$(foreach p, $(PERIPHERALS), $(eval DEFINE+=$(defmacro)$p=$($p)))

#test log
ifneq ($(TEST_LOG),)
LOG=>test.log
endif

gen-clean:
	@rm -f *# *~

.PHONY: all
