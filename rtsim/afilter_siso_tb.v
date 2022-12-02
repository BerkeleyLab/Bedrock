`timescale 1ns / 1ns

`define LB_DECODE_afilter_siso_tb
`include "afilter_siso_tb_auto.vh"

module afilter_siso_tb;

reg clk;
wire lb_clk = clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
                $dumpfile("afilter_siso.vcd");
                $dumpvars(5, afilter_siso_tb);
        end
        for (cc=0; cc<400; cc=cc+1) begin
                clk=0; #4;
                clk=1; #4;
        end
        $display("WARNING: Not a self-checking testbench. Will always PASS. Relies on external post-processing.");
        $display("PASS");
end

// Local bus
reg [31:0] lb_data=0;
reg [14:0] lb_addr=0;
reg lb_write=0;

`AUTOMATIC_decode

// DSP trigger
reg run_filter=0;
always @(posedge clk) run_filter <= (cc%20 == 3) && (cc > 50);

reg signed [17:0] u_in=0;
always @(posedge clk) if (cc>60) u_in <= 30000;
// always @(posedge clk) u_in <= 9000+cc;

// Device Under Test
wire filter_done, res_clip;
wire signed [17:0] y_out;
afilter_siso afilter_siso // auto
	(.clk(clk), .reset(1'b0), .run_filter(run_filter),
	.u_in(u_in),
	.y_out(y_out), .filter_done(filter_done), .res_clip(res_clip),
	`AUTOMATIC_afilter_siso
);

// Read localbus commands from external file
reg [255:0] file1_name;
integer file1;
initial begin
	if (!$value$plusargs("dfile=%s", file1_name)) file1_name="afilter_siso_in.dat";
	file1 = $fopen(file1_name,"r");
end

integer rc=2;
integer ca, cd;
integer control_cnt=0;
integer wait_horizon=5;
always @(posedge clk) begin
	lb_write <= 0;
	lb_data <= 32'bx;
	lb_addr <= 15'bx;
	control_cnt <= control_cnt+1;
	if (control_cnt > wait_horizon && control_cnt%3==1 && rc==2) begin
		rc = $fscanf(file1, "%d %x\n", ca, cd);
		if (rc==2) begin
			// https://en.wikipedia.org/wiki/555_timer_IC
			if (ca == 555) begin
				$display("stall %d cycles",cd);
				wait_horizon = control_cnt + cd;
			end else begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				lb_addr <= ca;
				lb_data <= cd;
				lb_write <= 1;
			end
		end
	end
end

always @(negedge clk) if (filter_done) $display("output %d %d", $time, y_out);

endmodule
