# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = BEDROCK
SOURCEDIR     = .
BUILDDIR      = _build
MAKE          = make
PYTHON        = python3
VERILOG       = iverilog$(ICARUS_SUFFIX) -Wall -DSIMULATE
VVP           = vvp$(ICARUS_SUFFIX) -n
GTKWAVE       = gtkwave
# convert is an imagemagick program; apt-get install imagemagick
CONVERT       = convert
# convert in Debian stretch gives unreproducible output
# the following doesn't help
# CONVERT = SOURCE_DATE_EPOCH=$(DATE_HACK) convert
# DATE_HACK := $(shell stat -c %Y README)
V_TB 	       = -Wno-timescale
# apt-get install xvfb
# maybe OK to blank out XVFB if you don't have xvfb-run and don't mind pop-ups
XVFB           = xvfb-run -a -s "-screen 0 1440x900x24"
# Get verilog sources dependencies
MAKEDEP        = $(VERILOG) $(V_TB) -o /dev/null -M$@.$$$$ $<

TOP = ..
GEN_DIR = gen

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
   multi_sampler.v \
   non_iq_interleaved_piloop.v \
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
   xy_pi_clip.v
   # ssb_out.v # needs extra rules to build cordic
   # second_if_out.v # needs extra rules to build cordic
   # rot_dds.v  # needs extra rules to build cordic
   # iq_trace.v # needs extra rules to build cordic
   # cordic_mux.v # needs extra rules to build cordic
   # lp_notch.v  # must generate _auto files
   # lp.v # must generate _auto files
   # mp_proc.v # must generate _auto files
   #via.v # not properly formatted for portfind.py

DIRS       = $(TOP)/dsp $(TOP)/badger $(TOP)/cordic
VFLAGS_DEP = -y. -I. $(addprefix -y, $(DIRS)) $(addprefix -I, $(DIRS))

vpath %.v $(DIRS)
vpath %.gtkw $(DIRS)

_RST       = $(SRC:.v=.rst)
RST        = $(addprefix $(GEN_DIR)/, $(_RST))
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

# For cleaning
GEN_TB     = $(addprefix $(GEN_DIR)/, $(basename $(TB)))
DEP_TB     = $(addsuffix .d, $(GEN_TB))
VCD        = $(addprefix $(GEN_DIR)/, $(notdir $(SRC:.v=.vcd)))

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help images Makefile gen_dir rst block_png block_eps timing

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
#
# rst should be last as this targets checks some files to change
# the way it generates its output
html: images Makefile block_png timing rst
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

$(GEN_DIR)/%.rst: %.v
	if [ -f $(GEN_DIR)/$*_timing.png ]; then \
		$(PYTHON) $(TOP)/build-tools/portfind.py --gen-rst --rst-with-timing $< > $@; \
	else \
		$(PYTHON) $(TOP)/build-tools/portfind.py --gen-rst $< > $@; \
	fi

$(GEN_DIR)/%_block.eps: %.v
	$(PYTHON) $(TOP)/build-tools/portfind.py --gen-eps $< > $@

$(GEN_DIR)/%.png: $(GEN_DIR)/%.eps
	$(CONVERT) $< $@

$(GEN_DIR)/%.vcd: $(GEN_DIR)/%_tb
	$(VVP) $< $(VVP_FLAGS) +vcd $(VCD_ARGS) && mv $(notdir $@) $@

$(GEN_DIR)/%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} $(VFLAGS_DEP) $(VFLAGS) -o $@ $(filter %.v, $^)

# Expect the magic numbers 229 and 68 to be gtkwave-version-dependent.
# Note that gtkwave must be run from a session with X enabled.
# The xvfb setup creates that independent of what's going on with
# the environment of the process running this script.
$(GEN_DIR)/%_timing.png: $(GEN_DIR)/%.vcd %.gtkw
	$(XVFB) $(GTKWAVE) $^ -r gtkwave_nosplash.rc -S fancy.tcl
	$(CONVERT) -crop 1200x1000+229+68 $@ foo.$$$$ && mv foo.$$$$ $@

# Generate list of dependencies for each top/testbench verilog module
$(GEN_DIR)/%_tb.d: %_tb.v
	set -e
	mkdir -p $(GEN_DIR)
	($(MAKEDEP) ${VFLAGS_$@} $(VFLAGS_DEP) && \
		( printf "$(GEN_DIR)/$*_tb $@: "; sort -u $@.$$$$ | tr '\n' ' '; printf "\n" ) > $@ && \
		rm -f $@.$$$$) || true

# Include testbench dependencies *.d file target
-include $(GEN_TB:_tb=_tb.d)

# Special additional prerequisites as iverilog does not catch them
$(GEN_DIR)/biquad_tb: ../dsp/saturateMath.v
$(GEN_DIR)/iirFilter_tb: ../dsp/saturateMath.v

images::
	if [ -d images ]; then $(MAKE) -C images || exit 1; fi

rst: gen_dir $(RST)

block_eps: gen_dir $(BLOCK_EPS)

block_png: gen_dir $(BLOCK_PNG)

timing: gen_dir $(TIMING_PNG)

gen_dir:
	mkdir -p $(GEN_DIR)

clean:
	if [ -d images ]; then $(MAKE) -C images clean || exit 1; fi
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
	rm -f $(RST) $(BLOCK_EPS) $(BLOCK_PNG) $(TIMING_PNG) $(GEN_TB) $(addsuffix *, $(DEP_TB)) $(VCD)
	if [ -d $(GEN_DIR) ]; then rmdir $(GEN_DIR); fi
