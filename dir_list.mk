MAKEF_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEF_DIR := $(dir $(MAKEF_PATH))

BEDROCK_DIR        = $(MAKEF_DIR)
BUILD_DIR          = $(BEDROCK_DIR)/build-tools
CORDIC_DIR         = $(BEDROCK_DIR)/cordic
DSP_DIR            = $(BEDROCK_DIR)/dsp
CMOC_DIR           = $(BEDROCK_DIR)/cmoc
RTSIM_DIR          = $(BEDROCK_DIR)/rtsim
BADGER_DIR         = $(BEDROCK_DIR)/badger
BOARD_SUPPORT_DIR  = $(BEDROCK_DIR)/board_support
HOMELESS_DIR       = $(BEDROCK_DIR)/homeless
FPGA_FAMILY_DIR    = $(BEDROCK_DIR)/fpga_family
PERIPH_DRIVERS_DIR = $(BEDROCK_DIR)/peripheral_drivers
PROJECTS_DIR       = $(BEDROCK_DIR)/projects
SERIAL_IO_DIR      = $(BEDROCK_DIR)/serial_io
