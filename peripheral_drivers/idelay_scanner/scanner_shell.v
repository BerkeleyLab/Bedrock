// Instantiates idelay_scanner at the interior of an FPGA fabric,
// with not too many I/O pins, and no way for the synthesizer
// to optimize anything away.  The point is to evaluate idelay_scanner
// for synthesizability, size, and speed.  It would be useless
// to actually run this on hardware.
module scanner_shell(
	input clk,  // timespec 6.1 ns
	input [11:0] lb_addr,
	input lb_write,
	input [31:0] lb_data,
	output [7:0] odata,
	output [7:0] mask_out,
	output [3:0] hw_addr,
	output [4:0] hw_data,
	output hw_strobe
);

// IOB latches on inputs
reg [11:0] addr=0, addr_d=0;
reg write=0;
reg [31:0] data=0;
always @(posedge clk) begin
	addr <= lb_addr;
	addr_d <= addr;
	write <= lb_write;
	data <= lb_data;
end

// Host writes
reg prng_run=0;
reg [7:0] banyan_mask_host=0;
reg scan_trigger=0;
wire init_1 = write & (addr==1);
always @(posedge clk) scan_trigger <= write & (addr==4);
always @(posedge clk) if (write & (addr==5)) banyan_mask_host <= data;
always @(posedge clk) if (write & (addr==7)) prng_run <= data;
wire lb_id_write = write & (addr[11:4]==1);  // 16 through 31

// 32 bits of pseudo-randomness
wire [31:0] random1;
tt800 r1(.clk(clk), .en(prng_run|init_1), .init(init_1), .initv(data), .y(random1));
wire [15:0] fake_adc = random1;

// Device under test .. or not
wire [7:0] banyan_mask_scanner;
wire [6:0] mirror_val;
wire [7:0] result_val;
wire scan_running;
//`define BASELINE
`ifdef BASELINE
assign result_val = fake_adc[7:0];
assign mirror_val = 0;
assign hw_addr = random1[11:8];
assign hw_data = random1[16:12];
assign hw_strobe = random1[17];
`else
idelay_scanner scanner(.lb_clk(clk),
	.lb_addr(addr[3:0]), .lb_data(data[4:0]), .lb_id_write(lb_id_write),
	.scan_trigger(scan_trigger), .autoset_enable(1'b1),
	.ro_clk(clk), .ro_addr(lb_addr[10:0]),
	.mirror_val(mirror_val), .result_val(result_val),
	.scan_running(scan_running),
	.debug_sel(1'b0), .debug_addr(4'b0),
	.hw_addr(hw_addr), .hw_data(hw_data), .hw_strobe(hw_strobe),
	.banyan_mask(banyan_mask_scanner),
	.adc_clk(clk), .adc_val(fake_adc)
);
`endif

// Banyan mask multiplexer
reg [7:0] banyan_mask=0;
always @(posedge clk) begin
	banyan_mask <= scan_running ?  banyan_mask_scanner : banyan_mask_host;
end
assign mask_out = banyan_mask;

// Host reads
reg [7:0] odata_r=0;
always @(posedge clk) casex (addr_d)
	12'b1xxx_xxxx_xxxx: odata_r <= result_val;
	12'b0000_0001_xxxx: odata_r <= mirror_val;
	12'b0000_0000_0100: odata_r <= scan_running;
	default: odata_r <= 8'h55;
endcase
assign odata = odata_r;

endmodule
