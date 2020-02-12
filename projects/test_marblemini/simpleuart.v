/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
/*
 *  simpleuart lightly modified by L. Doolittle from C. Wolf's original:
 *    cfg_divider is a direct input, rather than attaching to a host bus
 *    send_divcnt and recv_divcnt are now only 20 bits wide
 *    reg_dat_ names are shortened to b_
 *    actual data ports are now only 8 bits wide (not padded to 32)
 *    b_busy and b_dv are new outputs
 *    send_divcnt is now a down-counter with pipelined terminal count detect
 *
 *  Baud rate computation:
 *    One bit time is clk period * cfg_divider
 *    e.g., use cfg_divider = 13021 for 9600 baud with 125 MHz clk
 *    minimum valid value of cfg_divider is 2.
 */

// Should the 20-bit divider width be parameterized?
module simpleuart (
	input clk,
	input resetn,

	output ser_tx,
	input  ser_rx,

	input  [19:0] cfg_divider,

	input        b_we,
	input        b_re,
	input  [7:0] b_di,
	output [7:0] b_do,
	output       b_dv,
	output       b_busy
);

	reg [3:0] recv_state;
	reg [19:0] recv_divcnt;
	reg [7:0] recv_pattern;
	reg [7:0] recv_buf_data;
	reg recv_buf_valid;

	reg [9:0] send_pattern;
	reg [3:0] send_bitcnt;
	reg [19:0] send_divcnt;
	reg send_divcnt_done;
	reg send_dummy;


	assign b_busy = b_we && (send_bitcnt || send_dummy);
	assign b_do = recv_buf_valid ? recv_buf_data : ~0;
	assign b_dv = recv_buf_valid;

	always @(posedge clk) begin
		if (!resetn) begin
			recv_state <= 0;
			recv_divcnt <= 0;
			recv_pattern <= 0;
			recv_buf_data <= 0;
			recv_buf_valid <= 0;
		end else begin
			recv_divcnt <= recv_divcnt + 1;
			if (b_re)
				recv_buf_valid <= 0;
			case (recv_state)
				0: begin
					if (!ser_rx)
						recv_state <= 1;
					recv_divcnt <= 0;
				end
				1: begin
					if (2*recv_divcnt > cfg_divider) begin
						recv_state <= 2;
						recv_divcnt <= 0;
					end
				end
				10: begin
					if (recv_divcnt > cfg_divider) begin
						recv_buf_data <= recv_pattern;
						recv_buf_valid <= 1;
						recv_state <= 0;
					end
				end
				default: begin
					if (recv_divcnt > cfg_divider) begin
						recv_pattern <= {ser_rx, recv_pattern[7:1]};
						recv_state <= recv_state + 1;
						recv_divcnt <= 0;
					end
				end
			endcase
		end
	end

	assign ser_tx = send_pattern[0];

	always @(posedge clk) begin
		send_divcnt <= send_divcnt - 1;
		send_divcnt_done <= send_divcnt==2;
		if (!resetn) begin
			send_pattern <= ~0;
			send_bitcnt <= 0;
			send_divcnt <= cfg_divider;
			send_dummy <= 1;
		end else begin
			if (send_dummy && !send_bitcnt) begin
				send_pattern <= ~0;
				send_bitcnt <= 15;
				send_divcnt <= cfg_divider;
				send_dummy <= 0;
			end else
			if (b_we && !send_bitcnt) begin
				send_pattern <= {1'b1, b_di, 1'b0};
				send_bitcnt <= 10;
				send_divcnt <= cfg_divider;
			end else
			if (send_divcnt_done && send_bitcnt) begin
				send_pattern <= {1'b1, send_pattern[9:1]};
				send_bitcnt <= send_bitcnt - 1;
				send_divcnt <= cfg_divider;
			end
		end
	end
endmodule
