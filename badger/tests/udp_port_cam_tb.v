`timescale 1ns / 1ns

module udp_port_cam_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("udp_port_cam.vcd");
		$dumpvars(5,udp_port_cam_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

// Stimulus
reg [15:0] data16, data_check;
reg port_s=0;
always @(posedge clk) begin
	port_s <= 0;
	case(cc)
		3:   begin data16 <= 2000; port_s <= 1; end
		33:  begin data16 <= 1000; port_s <= 1; end
		63:  begin data16 <= 3512; port_s <= 1; end
		93:  begin data16 <=    7; port_s <= 1; end
		123: begin data16 <=    1; port_s <= 1; end
		153: begin data16 <= 1001; port_s <= 1; end
		183: begin data16 <= 1257; port_s <= 1; end
		213: begin data16 <=    0; port_s <= 1; end
		243: begin data16 <= 3000; port_s <= 1; end
		273: begin data16 <= 3001; port_s <= 1; end
		default: data16 <= {data16[7:0], 8'hxx};
	endcase
	if (port_s) data_check <= data16;
end
wire [7:0] data = data16[15:8];

// DUT
parameter naw=3;
wire [naw:0] pno_a;
reg [7:0] pno_d=0;
wire [naw-1:0] port_p;
wire port_h, port_v;
udp_port_cam #(.naw(naw)) dut(.clk(clk),
	.port_s(port_s), .data(data),
	.pno_a(pno_a), .pno_d(pno_d),
	.port_p(port_p), .port_h(port_h), .port_v(port_v)
);

// Memory for UDP port numbers
reg [7:0] number_mem[0:15];
always @(posedge clk) pno_d <= number_mem[pno_a];
initial begin
	number_mem[0] = 0;
	number_mem[1] = 7;  // 7
	number_mem[2] = 3;
	number_mem[3] = 232;  // 1000
	number_mem[4] = 7;
	number_mem[5] = 208;  // 2000
	number_mem[6] = 11;
	number_mem[7] = 184;  // 3000
	number_mem[8] = 12;
	number_mem[9] = 184;  // 3256
	number_mem[10] = 0;
	number_mem[11] = 0;
	number_mem[12] = 0;
	number_mem[13] = 0;
	number_mem[14] = 3;
	number_mem[15] = 233;  // 1001
end

// Cross-check
reg port_vd=0; always @(posedge clk) port_vd <= port_v;
integer ix, hx;
reg check;
always @(negedge clk) if (port_v & ~port_vd) begin
	hx=-1;
	for (ix=0; ix<8; ix=ix+1)
		if (number_mem[2*ix] * 256 + number_mem[2*ix+1] == data_check)
			hx=ix;
	if (port_h) begin
		check = port_p == hx;
		$display("%d:  found virtual %d  %s",
			 data_check, port_p, check ? "   OK" : "FAULT");
	end else begin
		check = -1 == hx;
		$display("%d:  found nothing    %s",
			 data_check, check ? "   OK" : "FAULT");
	end
	if (~check) fail=1;
end

endmodule
