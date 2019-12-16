module ad5662 #(
	parameter nch=1  // number of channels (chips)
) (
	input clk,
	input tick,  // pacing gate
	// application (software at first)
	input [15:0] data,
	input [1:0] ctl,  // {PD1, PD0}, see fig. 34 of ad5662.pdf
	input [nch-1:0] sel,  // chip select
	input send,  // single-cycle gate
	output busy,
	// hardware pins
	output sclk,  // peak rate is half that of input tick
	output [nch-1:0] sync_,
	output sdo
);

// Primary persistent state is a simple counter
// send must be in clk domain
reg [5:0] count=0;
reg busy_r=0;
reg ending=0;
always @(posedge clk) begin
	if (send & ~busy) count <= 13;
	if (send) busy_r <= 1;
	if (ending) busy_r <= 0;
	if (tick & (count != 0)) count <= count+1;
	ending <= tick & (count==63);
end
assign busy = busy_r;

reg [nch-1:0] sel_r=0, sync_r=0;
always @(posedge clk) begin
	if (send) sel_r <= sel;
	if (count == 13) sync_r <= sel_r;
	if ((count == 61) && tick) sync_r <= {nch{1'b0}};
end

// Decode that state
reg sclk_r=0, shift=0;
wire running = (14 < count) && (count < 62);
always @(posedge clk) begin
	sclk_r <= ~running | ~count[0];
	shift <= tick & ~sclk_r;
end

// data path
reg [23:0] sr=0;
always @(posedge clk) begin
	if (send) sr <= {6'b0, ctl, data};
	if (shift) sr <= {sr[22:0], 1'b0};
end

// Output mapping
assign sclk = sclk_r;
assign sync_ = ~sync_r;
assign sdo = sr[23];

endmodule
