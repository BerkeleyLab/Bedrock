`timescale 1ns / 1ns

// Based on, and mostly compatible with, OpenCores (Rudolf Usselmann)
// generic_fifo_dc_gray (Universal FIFO Dual Clock, gray encoded),
// downloaded from:
//    http://www.opencores.org/cores/generic_fifos/
// This version drops the rst and clr inputs, as befits my FPGA needs,
// and neglects to provide wr_level and rd_level outputs.  It is also
// coded in a more compact style.
//
// This file counts as a derivative work, and as such Mr. Usselmann's
// copyright notice and the associated disclaimer is shown here:
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

module fifo_2c #(
    parameter dw = 16,
    parameter aw = 8
) (
    input wr_clk,
    input we,
    input [dw-1:0] din,
    output reg [aw:0] wr_count,
    output reg full,

    input rd_clk,
    input re,
    output[dw-1:0] dout,
    output reg [aw:0] rd_count,
    output reg empty
);

// Logic for write pointer -- very simple
reg  [aw:0] wp_bin=0, wp_gray=0;
wire [aw:0] wp_bin_next  = wp_bin + 1'b1;
wire [aw:0] wp_gray_next = wp_bin_next ^ {1'b0, wp_bin_next[aw:1]};
always @(posedge wr_clk) if (we) begin
	wp_bin  <= wp_bin_next;
	wp_gray <= wp_gray_next;
end

// Logic for read pointer -- very simple
reg  [aw:0] rp_bin=0, rp_gray=0;
wire [aw:0] rp_bin_next  = rp_bin + 1'b1;
wire [aw:0] rp_gray_next = rp_bin_next ^ {1'b0, rp_bin_next[aw:1]};
always @(posedge rd_clk) if (re) begin
	rp_bin  <= rp_bin_next;
	rp_gray <= rp_gray_next;
end

// Instantiate actual memory
dpram #(.aw(aw), .dw(dw)) mem(
	.clkb(rd_clk), .addrb(rp_bin[aw-1:0]), .doutb(dout),
	.clka(wr_clk), .addra(wp_bin[aw-1:0]), .dina(din), .wena(we));

// Send read pointer to write clock domain
reg [aw:0] rp_s; always @(posedge wr_clk) rp_s <= rp_gray;
wire [aw:0] rp_bin_x = rp_s ^ {1'b0, rp_bin_x[aw:1]};  // convert gray to binary

// Send write pointer to read clock domain
reg [aw:0] wp_s; always @(posedge rd_clk) wp_s <= wp_gray;
wire [aw:0] wp_bin_x = wp_s ^ {1'b0, wp_bin_x[aw:1]};  // convert gray to binary

// Finally can compute the hard part, the status flags
wire [aw:0] block = {1'b1, {aw{1'b0}}};
always @(posedge rd_clk) empty <=
	(wp_s == rp_gray) | (re & (wp_s == rp_gray_next));
always @(posedge wr_clk) full <=
	(wp_bin == (rp_bin_x ^ block)) |
	(we & (wp_bin_next == (rp_bin_x ^ block)));

// Calculate number of words in both domains
always @(posedge rd_clk) rd_count <=
    wp_bin_x - rp_bin;
always @(posedge wr_clk) wr_count <=
    wp_bin - rp_bin_x;

endmodule
