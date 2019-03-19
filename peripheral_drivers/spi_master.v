module spi_master
(clk,spi_start,spi_read,spi_addr,spi_data,cs,sck,sdi,sdo,sdo_addr,spi_rdbk,spi_ready,sdio_as_sdo);
parameter TSCKHALF=10;
parameter ADDR_WIDTH=16;
parameter DATA_WIDTH=8;
parameter SCKCNT_WIDTH = clog2(ADDR_WIDTH+DATA_WIDTH+1);
parameter TSCKW= clog2(TSCKHALF)+1; //tsck is 2^5 time ts
parameter DEBUG="false";
function integer clog2;
    input integer value;
    begin
        value = value-1;
        for (clog2=0; value>0; clog2=clog2+1)
            value = value>>1;
    end
endfunction
parameter SCK_RISING_SHIFT=1;
input clk;
input spi_start;
input spi_read;
(* mark_debug = DEBUG *)
input [ADDR_WIDTH-1:0] spi_addr;
(* mark_debug = DEBUG *)
input [DATA_WIDTH-1:0] spi_data;
(* mark_debug = DEBUG *)
output cs;
(* mark_debug = DEBUG *)
output sck;
(* mark_debug = DEBUG *)
output sdi;
(* mark_debug = DEBUG *)
input sdo;
output reg [ADDR_WIDTH-1:0] sdo_addr;
output reg [DATA_WIDTH-1:0] spi_rdbk;
output spi_ready;
output sdio_as_sdo;

reg cs_r=0,cs_r_d=0;
reg [TSCKW-1:0] tckcnt=0;
reg sck_r=0;
reg [SCKCNT_WIDTH-1:0] sck_cnt=0;//{SCKCNT_WIDTH{1'b1}};
reg sck_r_d=0;
reg sck_r_d2=0;
reg spi_read_r=0;
reg spi_start_r=0;
reg [ADDR_WIDTH-1:0] sdi_addr=0;
always @(posedge clk) begin
	tckcnt <= (tckcnt==0) ? TSCKHALF : tckcnt-1'b1;
	if (tckcnt==0 || (spi_start & ~cs_r)) sck_r <= cs_r ? ~sck_r : 1'b0 ; //tckcnt[TSCKW-1];
	sck_r_d <= sck_r;
	sck_r_d2 <= sck_r_d;
	spi_start_r <= spi_start;
	if (spi_start&~spi_start_r)
		cs_r <= 1'b1;
	else if (sck_cnt==ADDR_WIDTH+DATA_WIDTH & ~|tckcnt & ~sck_r )
		cs_r <= 1'b0;

	if (spi_start&~spi_start_r) begin
		spi_read_r <= spi_read;
		sdi_addr <= spi_addr;
	end
	if (sck_r & ~sck_r_d) begin
		sck_cnt <= sck_cnt+cs_r ;
	end else begin
		sck_cnt <= cs_r ? sck_cnt : 1'b0;//(SCKCNT_WIDTH{1'b1}};// 5'h1f;
	end
		cs_r_d <= cs_r;
end
wire sck_in_cs=sck_r_d2&cs_r_d;
assign cs=~cs_r_d;
assign sck= SCK_RISING_SHIFT ? sck_in_cs : ~sck_in_cs;

wire cs_falling_edge=~cs_r&cs_r_d;
reg [ADDR_WIDTH+DATA_WIDTH-1:0] sdi_value=0;
reg [DATA_WIDTH-1:0] sdo_rdbk_sr=0;
reg temp_rdbk=0;
always @(posedge clk) begin
		//if (~cs_r) begin
		//if (spi_start&~spi_start_r) begin
		if (cs_r&~cs_r_d) begin
			sdi_value <= {spi_addr,spi_data};//spi_read_r?{DATA_WIDTH{1'b0}}:spi_data};
		end else begin
			if (sck_r&~sck_r_d & |sck_cnt) begin
				sdi_value <= {sdi_value[ADDR_WIDTH+DATA_WIDTH-2:0],1'b0};
			end
		end
end
reg [3:0] sr_switch=0;
assign sdio_as_sdo=sr_switch[0];
always @(posedge clk) begin
	if (~sck_r&sck_r_d) begin
		if (sck_cnt >= ADDR_WIDTH & sck_cnt <= ADDR_WIDTH+DATA_WIDTH) begin
			sdo_rdbk_sr <= {sdo_rdbk_sr[DATA_WIDTH-2:0],sdo};
		end
	end
end
always @(posedge clk) begin
	if (sck_cnt >= ADDR_WIDTH & sck_cnt <= ADDR_WIDTH+DATA_WIDTH ) begin
		if (sck_r_d & ~sck_r) begin
			sr_switch <= {sr_switch[2:0],spi_read_r};
		end
	end
	else begin
		sr_switch <= {sr_switch[2:0],1'b0};
	end
end
reg spi_ready_r=0;
always @(posedge clk) begin
	if (cs_falling_edge&spi_read_r) begin
		sdo_addr <= sdi_addr;
		spi_rdbk <= sdo_rdbk_sr;
		spi_ready_r <= 1;
	end
	else
		spi_ready_r <=0;
end
assign sdi= sdi_value[ADDR_WIDTH+DATA_WIDTH-1];
assign spi_ready = spi_ready_r;

endmodule
