# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = BEDROCK
SOURCEDIR     = .
BUILDDIR      = _build
MAKE          = make

include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

# convert is an imagemagick program; apt-get install imagemagick
# convert in Debian stretch gives unreproducible output
# the following doesn't help
# CONVERT = SOURCE_DATE_EPOCH=$(DATE_HACK) convert
# DATE_HACK := $(shell stat -c %Y README)
CONVERT       = convert
# apt-get install xvfb
# maybe OK to blank out XVFB if you don't have xvfb-run and don't mind pop-ups
XVFB           = xvfb-run -a -s "-screen 0 1440x900x24"

GEN_DIR = _gen_rst
GEN_MD_DIR = _gen_md
GEN_SRC_DIR = _gen_src_rst

# No need to specify directory for each of these, thanks to the magic of make's vpath.
SRC = \
   afterburner.v \
   async_to_sync_reset_shift.v \
   banyan_mem.v \
   banyan.v \
   biquad.v \
   ccfilt.v \
   cic_interp.v \
   cic_multichannel.v \
   cic_simple_us.v \
   cic_wave_recorder.v \
   cim_12x.v \
   circle_buf_serial.v \
   circle_buf.v \
   complex_freq.v \
   complex_freq_wrap.v \
   complex_mul_flat.v \
   complex_mul.v \
   cpxmul_fullspeed.v \
   data_xdomain.v \
   demand_gpt.v \
   doublediff1.v \
   doublediff.v \
   double_inte_smp.v \
   double_inte.v \
   dpram.v \
   fchan_subset.v \
   fdownconvert.v \
   fifo.v \
   fiq_interp.v \
   flag_xdomain.v \
   flevel_set.v \
   freq_count.v \
   fwashout.v \
   half_filt.v \
   host_averager.v \
   iirFilter.v \
   interp1.v \
   iq_chain4.v \
   iq_deinterleaver_multichannel.v \
   iq_deinterleaver.v \
   iq_double_inte.v \
   iq_inter.v \
   iq_intrp4.v \
   iq_mixer_multichannel.v \
   iq_modulator.v \
   isqrt.v \
   ll_prop.v \
   lpass1.v \
   minmax.v \
   mixer.v \
   mon_2chan.v \
   mon_2chiq.v \
   mon_chans.v \
   multiply_accumulate.v \
   multi_counter.v \
   multi_sampler.v \
   pdetect.v \
   ph_acc.v \
   phase_diff.v \
   phaset.v \
   phasex.v \
   reg_delay.v \
   rr_arb.v \
   sat_add.v \
   saturateMath.v \
   serializer_multichannel.v \
   serialize.v \
   shortfifo.v \
   timestamp.v \
   tt800.v \
   upconv.v \
   xy_pi_clip.v \
   ssb_out.v \
   rot_dds.v  \
   iq_trace.v \
   cordic_mux.v
   # second_if_out.v # needs extra rules to build cordic
   # non_iq_interleaved_piloop.v # ascii diagram does not render properly with RST
   # lp_notch.v  # must generate _auto files
   # lp.v # must generate _auto files
   # mp_proc.v # must generate _auto files
   # via.v # not properly formatted for portfind.py

STATIC_RST = \
   rtsim-module.rst \
   dsp-digaree-module.rst

SRC_MD = \
   CONTRIBUTING.md \
   soc/picorv32/README.md \
   soc/picorv32/test/badger_lwip/README.md \
   soc/picorv32/test/lb_bridge/README.md \
   soc/picorv32/test/fv/README.md \
   peripheral_drivers/idelay_scanner/README.md \
   peripheral_drivers/i2cbridge/README.md \
   serial_io/chitchat/README.md \
   serial_io/chitchat/chitchat_txrx_wrap.md \
   projects/test_marble_family/README.md \
   projects/test_marble_family/i2c/README.md \
   projects/common/README.md \
   projects/oscope/marble_family/README.md \
   projects/oscope/bmb7_cu/README.md \
   projects/comms_top/README.md \
   guidelines/rtl_guidelines.md \
   badger/README.md \
   badger/status.md \
   badger/doc/README.md \
   badger/mem_gate.md \
   build-tools/makefile.md \
   rtsim/README.md \
   dsp/README.md \
   board_support/zest/README.md \
   board_support/bmb7_kintex/README.md \
   localbus/README.md \
   localbus/jit_rad.md \
   fpga_family/xilinx/README.md \
   build-tools/cdc_snitch.md \
   build-tools/newad.md

SRC_SVG = \
  badger/doc/rtefi.svg \
  badger/doc/clients.svg \
  badger/doc/mem_gateway.svg \
  badger/doc/tx_path.svg \
  badger/doc/precog_upg.svg \
  peripheral_drivers/i2cbridge/i2c_chunk.svg \
  peripheral_drivers/i2cbridge/blocks.svg \
  build-tools/cdc_BAD.svg \
  build-tools/cdc_OK1.svg \
  build-tools/cdc_OKX.svg

DIRS       = $(DSP_DIR) $(BADGER_DIR) $(CORDIC_DIR) $(PICORV_DIR) $(HOMELESS_DIR)
VFLAGS     += -y. -I. $(addprefix -y, $(DIRS)) $(addprefix -I, $(DIRS)) -y$(AUTOGEN_DIR)

vpath %.v $(DIRS)
vpath %.md $(MAKEF_DIR)
vpath %.gtkw $(DIRS)
vpath %.svg $(MAKEF_DIR)

_SRC_RST   = $(SRC:.v=_source.rst)
SRC_RST    = $(addprefix $(GEN_SRC_DIR)/, $(_SRC_RST))
_RST       = $(SRC:.v=.rst)
RST        = $(addprefix $(GEN_DIR)/, $(_RST))
_MD_RST    = $(SRC_MD:.md=_md.rst)
MD_RST     = $(addprefix $(GEN_MD_DIR)/, $(_MD_RST))
_BLOCK_EPS = $(SRC:.v=_block.eps)
BLOCK_EPS  = $(addprefix $(GEN_DIR)/, $(_BLOCK_EPS))
_BLOCK_PNG = $(SRC:.v=_block.png)
BLOCK_PNG  = $(addprefix $(GEN_DIR)/, $(_BLOCK_PNG))
_MAYBE_TB  = $(SRC:.v=_tb.v)
MAYBE_TB   = $(foreach dir, $(DIRS), $(addprefix $(dir)/, $(_MAYBE_TB)))
# Get only existing testbench files
TB         = $(notdir $(wildcard $(MAYBE_TB)))
# Get only existing gtkwave files from the valid _tb.v
GTKW       = $(notdir $(wildcard $(patsubst %_tb.v, %.gtkw, $(wildcard $(MAYBE_TB)))))
# Get, now, only the valid _tb.v that have a accompanying .gtkw
TB_PNG     = $(GTKW:.gtkw=_tb.v)
# Generate timing diagrams if testbench and gtkwave files exist
_TIMING_PNG = $(TB_PNG:_tb.v=_timing.png)
TIMING_PNG  = $(addprefix $(GEN_DIR)/, $(_TIMING_PNG))
SVG         = $(addprefix $(GEN_MD_DIR)/, $(SRC_SVG))

# For cleaning
GEN_TB     = $(addprefix $(GEN_DIR)/, $(basename $(TB)))
DEP_TB     = $(addsuffix .d, $(GEN_TB))
VCD        = $(addprefix $(GEN_DIR)/, $(notdir $(SRC:.v=.vcd)))

# CORDIC rules
include $(CORDIC_DIR)/rules.mk

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile gen_dir src_rst rst md pdf block_png block_eps timing svg

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
#
# rst should be last as this targets checks some files to change
# the way it generates its output
html: Makefile block_png timing svg src_rst rst md pdf static_rst
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

$(GEN_SRC_DIR)/%_source.rst: %.v
	$(PYTHON) $(BUILD_DIR)/portfind.py --gen-src-rst $< > $@

$(GEN_DIR)/%.rst: %.v
	if [ -f $(GEN_DIR)/$*_timing.png ]; then \
		$(PYTHON) $(BUILD_DIR)/portfind.py --gen-rst --rst-with-timing $< > $@; \
	else \
		$(PYTHON) $(BUILD_DIR)/portfind.py --gen-rst $< > $@; \
	fi

# The result of the --filter "" is complex to understand. Basically, given a
# .md filepath it creates the title with:
# <last directory name of the file> <filename>
#
# If "last directory name of the file" is $(GEN_MD_DIR), discard it
$(GEN_MD_DIR)/%_md.rst: %.md
	mkdir -p $(dir $@)
	$(PYTHON) $(BUILD_DIR)/genrststub.py --gen-md-include \
		--title "$(filter-out $(GEN_MD_DIR),$(notdir $(patsubst %/,%,$(dir $@)))) $(patsubst %_md,%,$(basename $(notdir $@)))" \
		$< > $@

$(GEN_DIR)/%_block.eps: %.v
	$(PYTHON) $(BUILD_DIR)/portfind.py --gen-eps $< > $@

$(GEN_DIR)/%.png: $(GEN_DIR)/%.eps
	$(CONVERT) $< $@

# Expect the magic numbers 229 and 68 to be gtkwave-version-dependent.
# Note that gtkwave must be run from a session with X enabled.
# The xvfb setup creates that independent of what's going on with
# the environment of the process running this script.
$(GEN_DIR)/%_timing.png: %.vcd %.gtkw
	$(XVFB) $(GTKWAVE) $^ -r gtkwave_nosplash.rc -S fancy.tcl && mv $*_timing.png $@
	$(CONVERT) -crop 1200x1000+229+68 $@ foo.$$$$ && mv foo.$$$$ $@

$(GEN_MD_DIR)/%.svg: %.svg
	mkdir -p $(dir $@)
	cp $< $(dir $@)

# Special additional prerequisites as iverilog does not catch them
biquad_tb: ../dsp/saturateMath.v
iirFilter_tb: ../dsp/saturateMath.v

# Special additional prerequisites for CORDIC generation
rot_dds_tb: cordicg_b22.v
mon_12_tb: cordicg_b22.v
ssb_out_tb: cordicg_b22.v
cordic_mux_tb: cordicg_b22.v
fdbk_core_tb: cordicg_b22.v

src_rst: gen_dir $(SRC_RST)

rst: gen_dir $(RST)

md: gen_md_dir $(MD_RST)

pdf: gen_rtsim_pdf gen_digaree_pdf

block_eps: gen_dir $(BLOCK_EPS)

block_png: gen_dir $(BLOCK_PNG)

timing: gen_dir $(TIMING_PNG)

svg: gen_dir $(SVG)

gen_dir:
	mkdir -p $(GEN_DIR) $(GEN_SRC_DIR)

gen_md_dir:
	mkdir -p $(GEN_MD_DIR)

gen_rtsim_pdf:
	make -C $(RTSIM_DIR)/doc
	cp $(RTSIM_DIR)/doc/*.pdf .

gen_digaree_pdf:
	make -C $(DSP_DIR)/digaree tuning_dsp4.pdf
	cp $(DSP_DIR)/digaree/*.pdf .

static_rst:
	cp $(STATIC_RST) $(GEN_DIR)/

clean::
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

include $(BUILD_DIR)/bottom_rules.mk

CLEAN += $(SRC_RST) $(RST) $(BLOCK_EPS) $(BLOCK_PNG) $(TIMING_PNG) $(GEN_TB) $(addsuffix *, $(DEP_TB)) $(VCD) \
		 cordicg_b22.v *_tb *.out
CLEAN_DIRS += $(GEN_DIR) $(GEN_SRC_DIR) $(GEN_MD_DIR)
