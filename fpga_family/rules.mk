# Rules to fetch external files from EXT_FILE_DEPOT
# Each file, f, to be downloaded must have a corresponding f.remote file
# in REMOTE_SRC_DIRS and contain the following entry: SHA256 [SHA256 Sum]

# Defaults to HTTP server on local machine if not set externally
EXT_FILE_DEPOT ?= "http://localhost:8000"

REMOTE_SRC_DIRS = $(FPGA_FAMILY_DIR)/gtx

REMOTE_TGTS = $(patsubst %.remote, %.v, $(foreach dir, $(REMOTE_SRC_DIRS), $(wildcard $(dir)/*.remote)))

vpath %.remote $(REMOTE_SRC_DIRS)

%.v: %.remote
	@wget $(EXT_FILE_DEPOT)/$(notdir $@)
	@touch $(notdir $@)
	@mv $(notdir $@) $(dir $<)/
	@grep -q SHA256 $< && cat $< | cut -d' ' -f2 | xargs -I {} echo "{} $(basename $<).v" | sha256sum -c

CLEAN += $(REMOTE_TGTS)

