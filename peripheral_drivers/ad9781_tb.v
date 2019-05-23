module ad9781_tb (input  CSB
,input  D0N
,input  D0P
,input  D10N
,input  D10P
,input  D11N
,input  D11P
,input  D12N
,input  D12P
,input  D13N
,input  D13P
,input  D1N
,input  D1P
,input  D2N
,input  D2P
,input  D3N
,input  D3P
,input  D4N
,input  D4P
,input  D5N
,input  D5P
,input  D6N
,input  D6P
,input  D7N
,input  D7P
,input  D8N
,input  D8P
,input  D9N
,input  D9P
,input  DCIN
,input  DCIP
,output  DCON
,output  DCOP
,input  RESET
,input  SCLK
,inout  SDIO
,output  SDO
,output [13:0] data_i
,output [13:0] data_q
,input clk
);

localparam width=14;
wire [width-1:0] d_p,d_n;
assign d_p={D13P,D12P,D11P,D10P,D9P,D8P,D7P,D6P,D5P,D4P,D3P,D2P,D1P,D0P};
assign d_n={D13N,D12N,D11N,D10N,D9N,D8N,D7N,D6N,D5N,D4N,D3N,D2N,D1N,D0N};
wire dco_p,dco_n;
assign DCOP=clk;
assign DCON=~clk;
reg [13:0] data_ir=0;
reg [13:0] data_qr=0;
reg [13:0] data_ir_d=0;
reg [13:0] data_qr_d=0;

always @(posedge clk) begin
	data_qr<=d_p;
	data_qr_d <=data_qr;
	data_ir_d <= data_ir;
end
always @(negedge clk) begin
	data_ir<=d_p;
end
assign data_i=data_ir_d;
assign data_q=data_qr_d;
assign SDO=0;
endmodule

