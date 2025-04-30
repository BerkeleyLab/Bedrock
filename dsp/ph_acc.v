`timescale 1ns / 1ns

// Phase accumulator, to act as basis for DDS (direct digital synthesizer).
// Tuned to allow 32-bit control, divided 20-bit high and 12-bit low,
// which gets merged to 32-bit binary when modulo is zero.
// But also supports non-binary frequencies: see the modulo input port.

// Note that phase_step_h and phase_step_l combined fit in a 32-bit word.
// This is intentional, to allow atomic updates of the two controls
// in 32-bit systems.  Indeed, when modulo==0, those 32 bits can be considered
// a single phase step increment

// The phase generation algorithm
// 0. The phase increments for dds are generated using a technique described
// in these 2 places:
// Section: PROGRAMMABLE MODULUS MODE in:
//  https://www.analog.com/media/en/technical-documentation/data-sheets/ad9915.pdf
//  (AND) https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
//  Basically, increment the phase step at a coarse resolution, accumulate the
//  error on the side, and when that error accumulates to the lowest bit of
//  the coarse counter, add an extra 1 to the following phase step.
// 1. phase_step_h is the coarse (20 bit) integer truncated phase increment for
//  the cordic. There is a 1-bit increment of phase that comes from
//  accumulating residue phase.
// 2. This residue phase is accumulating in steps of phase_step_l, in a 12-bit
//  counter.
// 3. However, there will be an extra residue even for this 12-bit counter,
// which is the modulus, and this added as an offset when the counter crosses 0

// 12-bit modulo supports largest known periodicity in a suggested LLRF system,
// 1427 for JLab.  For more normal periodicities, use a multiple to get finer
// granularity.
// Note that the downloaded modulo control is the 2's complement of the
// mathematical modulus.
// e.g., SSRF IF/F_s ratio 8/11, use
//     modulo = 4096 - 372*11 = 4
//     phase_step_h = 2^20*8/11 = 762600
//     phase_step_l = (2^20*8%11)*372 = 2976
// e.g., Argonne RIA test IF/F_s ratio 9/13, use
//     modulo = 4096 - 315*13 = 1
//     phase_step_h = 2^20*9/13 = 725937
//     phase_step_l = (2^20*9%13)*315 = 945

module ph_acc(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input reset,  // Active high, synchronous with clk
	input en,   // Enable
	output [18:0] phase_acc,  // Output phase word
	input [19:0] phase_step_h,  // High order (coarse, binary) phase step
	input [11:0] phase_step_l,  // Low order (fine, possibly non-binary) phase step
	input [11:0] modulo  // Encoding of non-binary modulus; 0 means binary
);

reg carry=0, reset1=0;
reg [19:0] phase_h=0, phase_step_hp=0;
reg [11:0] phase_l=0;
always @(posedge clk) if (en) begin
	{carry, phase_l} <= reset ? 13'b0 : ((carry ? modulo : 12'b0) + phase_l + phase_step_l);
	phase_step_hp <= phase_step_h;
	reset1 <= reset;
	phase_h <= reset1 ? 20'b0 : (phase_h + phase_step_hp + carry);
end
assign phase_acc=phase_h[19:1];

endmodule
