GTX_DIR = $(FPGA_FAMILY_DIR)/gtx

# Rules to fetch external files from EXT_FILE_DEPOT
# Each file, f, to be downloaded must have a corresponding f.remote file
# in REMOTE_SRC_DIRS and contain the following entry: SHA256 [SHA256 Sum]

# Defaults to HTTP server on local machine if not set externally
EXT_FILE_DEPOT ?= "http://localhost:8000"

REMOTE_SRC_DIRS = $(GTX_DIR)

REMOTE_TGTS = $(patsubst %.remote, %.v, $(foreach dir, $(REMOTE_SRC_DIRS), $(wildcard $(dir)/*.remote)))

vpath %.remote $(REMOTE_SRC_DIRS)

%.v: %.remote
	@wget $(EXT_FILE_DEPOT)/$(notdir $@)
	@touch $(notdir $@)
	@mv $(notdir $@) $(dir $<)/
	@grep -q SHA256 $< && cat $< | cut -d' ' -f2 | xargs -I {} echo "{} $(basename $<).v" | sha256sum -c

# Rules to produce macro-expanded q{0,1,2,3}_gtx_wrap components

vpath %.v $(GTX_DIR)
vpath %.vh $(GTX_DIR)

QGTX_D = $(QGTX_DEFS) # Accept extra defines from command line
QGTX_D += -DQ0_GT0_ENABLE -DQ1_GT0_ENABLE -DQ2_GT0_ENABLE -DQ3_GT0_ENABLE
QGTX_D += -DQ0_GT0_8B10B_EN

# Run through iverilog pre-processor and attempt to clean up newline chunks
qgtx_template : qgtx_wrap.v qgtx_wrap_stub.vh qgtx_wrap_pack.vh
	$(VERILOG) -I$(GTX_DIR) $(QGTX_D) -E $< -o - | grep "[^ ]" > $(basename $<).template.v


CLEAN += $(REMOTE_TGTS) $(GTX_DIR)/*.out

