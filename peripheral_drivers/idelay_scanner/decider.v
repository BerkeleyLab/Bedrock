// Goes with idelay_scanner.v
module decider(
	input clk,
	input [10:0] addr,  // 4+5+2
	input [7:0] lane_data,
	input strobe,
	output [4:0] idelay_opt,
	output good_enough
);

// valid words depend on addr[7], see prc.py self.valid_pattern
// {0x43:1, 0x0d:1, 0x34:1, 0xd0:1},{0x39:1, 0xe4:1, 0x93:1, 0x4e:1}
wire odd = addr[7];
reg valid=0;
always @(posedge clk) begin
	if (~odd) case (lane_data)
		8'h43: valid <= 1;
		8'h0d: valid <= 1;
		8'h34: valid <= 1;
		8'hd0: valid <= 1;
		default: valid <= 0;
	endcase else case (lane_data)
		8'h39: valid <= 1;
		8'he4: valid <= 1;
		8'h93: valid <= 1;
		8'h4e: valid <= 1;
		default: valid <= 0;
	endcase
end

// Pull apart the 4 + 5 + 2 bit address
wire [4:0] idelay = addr[6:2];
wire [1:0] micro  = addr[1:0];

// Pretty much the same algorithm as in prc.py top2idelay()
reg [7:0] goodness=0, best=0, center=0;
reg strobe_d=0, good_enough_r=0;
always @(posedge clk) begin
	strobe_d <= strobe;
	if (strobe) goodness <= valid ? (goodness+1) : 0;
	if (strobe & (idelay==0)) begin
		best <= 0;
		center <= 0;
		good_enough_r <= 0;
	end
	if (strobe_d & (goodness > best)) begin
		best <= goodness;
		if (goodness > 30) begin
			center <= idelay - (goodness>>3);
			good_enough_r <= 1;
		end
	end
end
assign idelay_opt = center;
assign good_enough = good_enough_r;

endmodule
