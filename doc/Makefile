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
# convert is an imagemagick program; apt-get install imagemagick
CONVERT       = convert
# convert in Debian stretch gives unreproducible output
# the following doesn't help
# CONVERT = SOURCE_DATE_EPOCH=$(DATE_HACK) convert
# DATE_HACK := $(shell stat -c %Y README)

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
   cordic_mux.v \
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
   iq_trace.v \
   isqrt.v \
   ll_prop.v \
   lpass1.v \
   lp_notch.v \
   lp.v \
   minmax.v \
   mixer.v \
   mon_2chan.v \
   mon_2chiq.v \
   mon_chans.v \
   mp_proc.v \
   multiply_accumulate.v \
   multi_sampler.v \
   non_iq_interleaved_piloop.v \
   pdetect.v \
   ph_acc.v \
   phase_diff.v \
   phaset.v \
   phasex.v \
   reg_delay.v \
   rot_dds.v \
   rr_arb.v \
   sat_add.v \
   saturateMath.v \
   second_if_out.v \
   serializer_multichannel.v \
   serialize.v \
   shortfifo.v \
   ssb_out.v \
   timestamp.v \
   tt800.v \
   upconv.v \
   xy_pi_clip.v
   #via.v # not properly formatted for portfind.py

vpath %.v $(TOP)/dsp

_RST       = $(SRC:.v=.rst)
RST        = $(addprefix $(GEN_DIR)/, $(_RST))
_BLOCK_EPS = $(SRC:.v=_block.eps)
BLOCK_EPS  = $(addprefix $(GEN_DIR)/, $(_BLOCK_EPS))
_BLOCK_PNG = $(SRC:.v=_block.png)
BLOCK_PNG  = $(addprefix $(GEN_DIR)/, $(_BLOCK_PNG))

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help images Makefile gen_dir rst block_png block_eps

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
html: images Makefile rst block_png
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

$(GEN_DIR)/%.rst: %.v
	$(PYTHON) $(TOP)/build-tools/portfind.py --gen-rst $< > $@

$(GEN_DIR)/%_block.eps: %.v
	$(PYTHON) $(TOP)/build-tools/portfind.py --gen-eps $< > $@

$(GEN_DIR)/%.png: $(GEN_DIR)/%.eps
	$(CONVERT) $< $@

images::
	if [ -d images ]; then $(MAKE) -C images || exit 1; fi

rst: gen_dir $(RST)

block_eps: gen_dir $(BLOCK_EPS)

block_png: gen_dir $(BLOCK_PNG)

gen_dir:
	mkdir -p $(GEN_DIR)

clean:
	if [ -d images ]; then $(MAKE) -C images clean || exit 1; fi
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
	rm -f $(RST) $(BLOCK_EPS) $(BLOCK_PNG)
	if [ -d $(GEN_DIR) ]; then rmdir $(GEN_DIR); fi
