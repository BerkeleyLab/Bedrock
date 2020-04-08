`timescale 1ns / 1ns

// Specific to LCLS-II LLRF Digitizer board
// See hardware.txt
// Synthesizes to 50 LUTs on Spartan-6, has no trouble making 190 MHz there,
// Artix or Kintex should be even better.
module llspi #(
	parameter dbg = "false",
	parameter pace_set = 6,   // Can override to 2 or 3 for testing
	parameter infifo_aw=5
) (
	input clk,  // timespec 5.3 ns
	// Physical FMC pins connected to digitizer board
	(* mark_debug = dbg *) output reg P2_SCLK,
	(* mark_debug = dbg *) output reg P2_SDI,
	(* mark_debug = dbg *) output reg P2_LMK_LEuWire,
	(* mark_debug = dbg *) inout      P2_ADC_SDIO,
	(* mark_debug = dbg *) output reg P2_ADC_SDIO_DIR,
	(* mark_debug = dbg *) output reg P2_ADC_CSB_0,
	(* mark_debug = dbg *) output reg P2_ADC_CSB_1,
	(* mark_debug = dbg *) input      P2_DAC_SDO,
	(* mark_debug = dbg *) output reg P2_DAC_CSB,
	// Note that the SPI pins for the AMC7823/AD7794 are totally
	// divorced from the LMK10801/AD9853/AD9781.
	// This is for electrical isolation reasons, so we can keep running
	// the AMC7823/AD7794 chips without compromising the SNR of the ADC
	// and DAC.  This also means that if there were good reason, they
	// could be handled by two totally distinct drivers in the FPGA.
	output reg P2_POLL_SCLK,
	output reg P2_POLL_MOSI,
	output reg P2_AMC7823_SPI_SS,
	output reg P2_AD7794_CSb,
	input P2_AMC7823_SPI_MISO,
	input P2_AD7794_DOUT,
	// Host write port
	input [8:0] host_din,
	input host_we,
	// Status made available to host
	output [7:0] status,
	// Host read port
	input result_re,
	output reg [7:0] host_result=8'hcc,
	input sdi,
	output sdo,
	output sdio_as_i
);

initial begin
	P2_SCLK=0;
	P2_SDI=0;
	P2_LMK_LEuWire=0;
	P2_ADC_SDIO_DIR=0;
	P2_ADC_CSB_0=1;
	P2_ADC_CSB_1=1;
	P2_DAC_CSB=0;
	P2_POLL_SCLK=0;
	P2_POLL_MOSI=0;
	P2_AMC7823_SPI_SS=1;
	P2_AD7794_CSb=1;
end

// Tri-state IOB for P2_ADC_SDIO pin
reg adc_sdio_iob=0, adc_sdio_drive=0;
//assign P2_ADC_SDIO = adc_sdio_drive ? adc_sdio_iob : 1'bz;
wire adcsdio_asi;// = adc_sdio_drive ? 1'b0 : P2_ADC_SDIO;
assign sdo=adc_sdio_iob;
assign adcsdio_asi=sdi;
assign sdio_as_i=adc_sdio_drive;
//IOBUF IOBUF(.O(adcsdio_asi), .T(~adc_sdio_drive),.I(adc_sdio_iob),.IO(P2_ADC_SDIO));
// ctl_bits[5]  unused
// ctl_bits[4]  ADC SDIO pin direction, set high for ADC read
// ctl_bits[3]  unused
// ctl_bits[2:0] == 0  nothing selected
// ctl_bits[2:0] == 1  LMK01801 (U1)
// ctl_bits[2:0] == 2  AD9653 0 (U2)
// ctl_bits[2:0] == 3  AD9653 1 (U3)
// ctl_bits[2:0] == 4  AD9781   (U4)
// ctl_bits[2:0] == 5  AD9653 0 and 1 together for reset prnd to test synchronization
// ctl_bits[2:0] == 6  AMC7823  (U15)
// ctl_bits[2:0] == 7  AD9974   (U16)

// XXX doesn't park P2_LMK_LEuWire low the way the data sheet describes.
wire sclk, mosi;
reg miso;
wire [5:0] ctl_bits;
reg P2_adc_grab=0, P2_dac_grab=0, P2_amc_grab=0, P2_sdc_grab=0;
wire adc_sel = ctl_bits[2:1]==1;
wire poll_sel = ctl_bits[2:1]==3;
always @(posedge clk) begin
	P2_SCLK        <= sclk & ~poll_sel;
	P2_SDI         <= mosi & ~poll_sel; // & ~adc_sel;
	P2_POLL_SCLK   <= sclk & poll_sel;
	P2_POLL_MOSI   <= mosi & poll_sel;
	P2_ADC_SDIO_DIR <= ctl_bits[4];
	P2_adc_grab <= adcsdio_asi;
	P2_dac_grab <= P2_DAC_SDO;
	adc_sdio_iob <= mosi & adc_sel;
	adc_sdio_drive <= ~ctl_bits[4];
	P2_LMK_LEuWire <= ctl_bits[2:0] != 1;
	P2_ADC_CSB_0   <= (ctl_bits[2:0] != 2) & (ctl_bits[2:0] !=5);
	P2_ADC_CSB_1   <= (ctl_bits[2:0] != 3) & (ctl_bits[2:0] !=5);
	P2_DAC_CSB     <= ctl_bits[2:0] != 4;
	P2_AMC7823_SPI_SS <= ctl_bits[2:0] != 6;
	P2_AD7794_CSb  <= ctl_bits[2:0] != 7;
	P2_amc_grab    <= P2_AMC7823_SPI_MISO;
	P2_sdc_grab    <= P2_AD7794_DOUT;
end

always @(*) case(ctl_bits[2:0])
	2: miso = P2_adc_grab;
	3: miso = P2_adc_grab;
	4: miso = P2_dac_grab;
	6: miso = P2_amc_grab;
	7: miso = P2_sdc_grab;
	default: miso = 0;
endcase

// Pace generated here at least for now
reg [pace_set-1:0] pace_cnt=0;
always @(posedge clk) pace_cnt <= pace_cnt + 1;
wire pace = pace_cnt[pace_set-1];

// FIFO of commands from host
wire full, empty, pull_fifo;
wire [8:0] fdata;

shortfifo #(.dw(9), .aw(infifo_aw)) input_fifo(.clk(clk),
	.full(full), .empty(empty),
	.we(host_we), .din(host_din),
	.re(pull_fifo), .dout(fdata));

// Actual SPI serialization logic, pulls instructions from FIFO
wire [7:0] result;
wire result_we;
spi_eater eater(.clk(clk), .pace(pace), .empty(empty),
	.pull_fifo(pull_fifo), .fdata(fdata),
	.result_we(result_we), .result(result),
	.sclk(sclk), .mosi(mosi), .miso(miso), .ctl_bits(ctl_bits));

// Read results get pushed into this FIFO
wire [7:0] result_unlatched;
wire [3:0] result_count;
shortfifo #(.dw(8), .aw(4)) output_fifo(.clk(clk),
	.we(result_we), .din(result),
	.re(result_re), .dout(result_unlatched),
	.count(result_count));

always @(posedge clk) if (result_re) host_result <= result_unlatched;

// Status register available for host polling
assign status = {3'b0, empty, result_count};

endmodule
