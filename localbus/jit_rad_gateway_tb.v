`timescale 1ns / 1ns

module jit_rad_gateway_tb;

reg lb_clk=0;
integer cc;
reg fail=0;
initial begin
        if ($test$plusargs("vcd")) begin
                $dumpfile("jit_rad_gateway.vcd");
                $dumpvars(5, jit_rad_gateway_tb);
        end
        for (cc=0; cc<2000; cc=cc+1) begin
                #10; lb_clk=1;
                #10; lb_clk=0;
        end
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) $stop(0);
	$finish(0);
end

// create dsp_clk: 91 MHz is good enough
reg app_clk=0;
always begin #6; app_clk=1; #5; app_clk=0; end

// hook to create packets
reg [7:0] net_idata=0;
reg rx_stb=0, rx_end=0;

// DUT
wire [7:0] net_odata;
wire tx_rdy, tx_end;
jit_rad_gateway_demo demo(.lb_clk(lb_clk), .app_clk(app_clk),
	.net_idata(net_idata), .rx_stb(rx_stb), .rx_end(rx_end),
	.net_odata(net_odata), .tx_rdy(tx_rdy), .tx_end(tx_end), .tx_stb(1'b1)
);

// packet geneartion logic
// No burst, especially since jxj_gate doesn't do that.
// This should be turned into a module so it can be shared
// with simulations of the non-QF2 configuration.
//
// packet contents:
//    8 byte header (nonce)
//    43 bus transactions (8 bytes each)
//       read 16 words from 0x60 through 0x6f
//       read 5 words from 0x00 through 0x04
//       write to 0x100 (lb_dynamic)
//       read 16 words from 0x60 through 0x6f
//       read 5 words from 0x00 through 0x04
reg p_running=0;
integer p_index=0, p_count=0;
integer word, slot, op, addr;
always @(posedge lb_clk) begin
	if ((cc%500)==20) begin
		p_running <= 1;
		p_count = p_count+1;
	end
	p_index <= p_running ? p_index + 1 : 0;
	rx_end <= 0;
	if (p_index == 352) begin  // 8 * (1+21+1+21)
		p_running <= 0;
		rx_end <= 1;
	end
	if (p_running) begin
		word = p_index / 8;
		slot = p_index % 8;
		op = (word == 22) ? 8'h00 : 8'h10;  // mostly read
		addr = 8'h60 + (word % 22) - 1;
		if (addr > 8'h6f) addr = addr - 8'h70;
		if (word == 22) addr = 9'h100;
		if (word == 0) begin
			net_idata <= p_index + 13;
		end else begin
			case (slot)
				0: net_idata <= op;
				1: net_idata <= 0;
				2: net_idata <= addr[15:8];
				3: net_idata <= addr[7:0];
				4: net_idata <= 8'h33;
				5: net_idata <= 8'h33;
				6: net_idata <= 8'h33;
				7: net_idata <= p_count;
			endcase
		end
	end
	rx_stb <= p_running;
end

// packet reception logic
reg [63:0] rx_cmd=0, rx_old=0, want=0;
reg [2:0] rx_slot=0;
reg [63:0] app_data[0:15];
integer rx_index=0, rx_pcount=1, jx;
reg rx_dynamic;
always @(posedge lb_clk) begin
	if (tx_rdy) begin
		rx_slot <= rx_slot+1;
		rx_cmd = {rx_cmd[55:0], net_odata};
		if (rx_slot == 7) begin
			// This is what should be routed to a
			// correctness checker.
			// $display("Rx %d %x", rx_index, rx_cmd);
			// Two times reading addresses 0x60 through 0x6f should yield the same answer
			if (rx_index > 0 && rx_index < 17) app_data[rx_index-1] = rx_cmd;
			if (rx_index > 22 && rx_index < 39 && app_data[rx_index-23] != rx_cmd) begin
				$display("Rx rep %d %x %x", rx_index, rx_cmd, app_data[rx_index-23]);
				fail = 1;
			end
			// Should get no errors, and a valid packet count, from reading 0x100
			if ((rx_index % 22) == 21) begin
				want = 64'h1000000400000000 + rx_pcount;
				if (want != rx_cmd) begin
					$display("Rx %d %d %x %x", rx_index, rx_pcount, rx_cmd, want);
					fail = 1;
				end
			end
			rx_index <= rx_index+1;
			rx_old <= rx_cmd;
			// Non-dynamic is by construction easy to check
			if (rx_index > 0 && rx_index < 17 && ~rx_dynamic) begin
				jx = rx_index-1;
				if ((rx_cmd & 32'hffffffff) != ((jx*32'h11111110) + (15-jx))) begin
					$display("Rx static %d, %x", rx_index, rx_cmd & 32'hffffffff);
					fail = 1;
				end
			end
			// The dynamic case is a bit harder, but we can definitely check some
			if (rx_index > 4 && rx_index < 17 && rx_dynamic) begin
				jx = rx_index-1;
				want = (rx_old*5 ^ jx) & 32'hffffff;
				if ((rx_cmd & 32'hffffff) != want) begin
					$display("Rx dynamic %d %x %x", rx_index, rx_cmd & 32'hffffff, want);
					fail = 1;
				end
			end
		end
	end
	if (tx_end) begin
		rx_index <= 0;
		rx_slot <= 0;
		rx_pcount <= rx_pcount + 1;
	end
	rx_dynamic <= ~rx_pcount[0];
end

endmodule
