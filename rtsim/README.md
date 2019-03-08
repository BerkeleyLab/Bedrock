# full-speed full-featured cavity simulation, to exercise LLRF controls

### Larry Doolittle, LBNL, May-June 2014

*(work-in-progress)*

This code is supposed to be approachable.  There are 885 non-blank non-comment lines of *Verilog* (and references to a few other routines in `bedrock: cordicg complex_mul dpram reg_delay`), and 286 of those lines are in test benches.  That *Verilog* also has 432 lines with comments!

There are waveforms to view, and most importantly, it comes with unit tests that exercise the code under realistic conditions -- see below.

* Summary of the hierarchy, not including test benches:

> `vmod1`:             Full single-cavity physics module\
> > `resonator`:       Mechanical eigenmode state-space propagator\
> > `outer_prod`:     Scale a data stream vector by a scalar\
> > `tt800v`:          Pseudo-random number generator\
> > `adc_em`:         ADC emulator (noise, offset, delay)\
> > `cav_elec`:      Represents the electromagnetic component of a cavity\
> > > `pair_couple`:  Applies a pair of complex couplings to IQ data stream\
> > > `ph_gacc`:      Gated phase accumulator adapted from ph_acc.v\
> > > `dot_prod`:     Dot product of state vector to get freq perturbation\
> > > `cic_interp`:       Want smooth changes in frequency\
> > > `cav_mode`:    Represents a single cavity electromagnetic mode\
> > > > `lp_pair`:    Time-interleaved pair of low-pass filters\
> > > > `pair_couple`:  Applies a pair of complex couplings to an interleaved IQ data stream\
> > > > `cordicg`:     Bare CORDIC algorithm\
> > > > `complex_mul`:   Multiply two IQ streams\
> > > > `mag_square`: Magnitude-squared of an IQ stream

You can see some of this visually in the doc directory's `block.eps` and `block_mode.eps` (*xcircuit* files, that can be viewed with standard *PostScript* tools like *gv*).  The physical system that the Verilog attempts to model is described in `physics.tex`; convert that to PDF for viewing with "make physics.pdf".

#### Get started

Run the unit tests with

     make checks

Everything should print `PASS`. Of course, this assumes you try this on a reasonable Verilog development workstation, which I define as a vanilla \*nix platform with *Icarus Verilog*, *Octave*, and *gtkwave* installed.  I recommend *Debian Wheezy*, although other Linux systems and Mac OS X can also be made to work.

If you then run `python cav_mode_check.py`, you'll see a couple of plots of the emitted wave from a cavity.  Study the data file, the *$display* command in `cav_mode_tb.v` that generated it, and the curves extracted by `cav_mode_check.py`, and you should have a decent feeling for what's going on.

The nested decoding of host-writable registers is messy, as always. Note that the four configuration registers implemented in pair_couple will themselves get replicated three times: once in each of two `cav_mode` instantiations, and once more directly in `cav_elec`.

A mechanical resonance (state-space) processor is shown in `resonator.v`.  The regression test exercises a single mode's response to a step function, and a plot of that reponse can be seen from *Octave* by running `res_check` interactively.  This processor is instantiated in `cav_elec_tb`, but not `cav_elec`, for two reasons:

1. I don't categorize the mechanical resonator as an electromagnetic element, and
2. I'd like to be able to instantiate multiple `cav_elec` modules sharing a single resonator computation.

That would permit simulation of a single mechanical mode connecting multiple cavities, important for considering stability of the single-source multiple-cavity architecture, and could be used to model the phenomenon of cavity fratricide seen at Jefferson Lab.  The state-space processor is also instantiated in the single-cavity `vmod1`, but that module is just a stepping stone to what's possible with this code base.

I may want to move the squaring step out of `cav_mode.v`, since it's only used at the rate of the mechanical resonator computational engine.

It can be argued that I use twice as many multipliers as necessary in `dot_prod.v` and `outer_prod.v`, since only the low-pass term of the second-order filter is of interest.  So we should be able to zero out one of two drive terms, and one of two response terms, converting to and from eigen-space. But using half a multiplier requires some breakage to the modularity of this code, and using a whole multiplier gives flexibility in confirming that everything is phased correctly.  Also, I seem to be using up fabric faster than multipliers, at least in Xilinx 7 series chips, so I shouldn't fret excessively about multipliers.
