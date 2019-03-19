module ad9653_tb
(D0NA,D0NB,D0NC,D0ND,D0PA,D0PB,D0PC,D0PD,D1NA,D1NB,D1NC,D1ND,D1PA,D1PB,D1PC,D1PD,DCOP,DCON,FCOP,FCON,PDWN,SYNC,CSB,SCLK,SDIO
,dina
,dinb
,dinc
,dind
,clk4x
,clk
);
parameter DWIDTH=8;
parameter [DWIDTH-1:0] FLIP_D=0;
parameter FLIP_DCO=0;
function integer clog2;
	input integer value;
	begin
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
			value = value>>1;
	end
endfunction

output D0NA;
output D0NB;
output D0NC;
output D0ND;
output D0PA;
output D0PB;
output D0PC;
output D0PD;
output D1NA;
output D1NB;
output D1NC;
output D1ND;
output D1PA;
output D1PB;
output D1PC;
output D1PD;
output DCON;
output DCOP;
output FCON;
output FCOP;
input PDWN;
input SYNC;
output CSB;
output SCLK;
inout SDIO;
input [15:0] dina;
input [15:0] dinb;
input [15:0] dinc;
input [15:0] dind;
input clk4x;
input clk;
reg [15:0] offseta=-00;
reg [15:0] offsetb=-00;
reg [15:0] offsetc=-00;
reg [15:0] offsetd=-00;
reg [7:0] da0=0;
reg [7:0] db0=0;
reg [7:0] dc0=0;
reg [7:0] dd0=0;
reg [7:0] da1=0;
reg [7:0] db1=0;
reg [7:0] dc1=0;
reg [7:0] dd1=0;
reg [7:0] clk_d=0;
wire load=clk_d[3]&~clk_d[4];
always @(clk4x) begin
	clk_d<={clk_d[6:0],clk};
end
wire [15:0] dinasigned={~dina[15],dina[14:0]};
wire [15:0] dinbsigned={~dinb[15],dinb[14:0]};
wire [15:0] dincsigned={~dinc[15],dinc[14:0]};
wire [15:0] dindsigned={~dind[15],dind[14:0]};
parameter usesigned=1;
wire [15:0] dinause;
wire [15:0] dinbuse;
wire [15:0] dincuse;
wire [15:0] dinduse;
//assign {dinause[11:8],dinause[15:12],dinause[3:0],dinause[7:4]}
assign dinause=usesigned ? dinasigned+offseta : dina+offseta;
//assign {dinbuse[11:8],dinbuse[15:12],dinbuse[3:0],dinbuse[7:4]}
assign dinbuse=usesigned ? dinbsigned+offsetb : dinb+offsetb;
//assign {dincuse[11:8],dincuse[15:12],dincuse[3:0],dincuse[7:4]}
assign dincuse=usesigned ? dincsigned+offsetc : dinc+offsetc;
//assign {dinduse[11:8],dinduse[15:12],dinduse[3:0],dinduse[7:4]}
assign dinduse=usesigned ? dindsigned+offsetd : dind+offsetd;
always @(clk4x) begin
	da0 <= load ? (FLIP_D[0] ? ~dinause[ 7:0] : dinause[7:0]) : {da0[6:0],1'b0};
	da1 <= load ? (FLIP_D[1] ? ~dinause[15:8] : dinause[15:8]) : {da1[6:0],1'b0};
	db0 <= load ? (FLIP_D[2] ? ~dinbuse[ 7:0] : dinbuse[7:0]) : {db0[6:0],1'b0};
	db1 <= load ? (FLIP_D[3] ? ~dinbuse[15:8] : dinbuse[15:8]) : {db1[6:0],1'b0};
	dc0 <= load ? (FLIP_D[4] ? ~dincuse[ 7:0] : dincuse[7:0]) : {dc0[6:0],1'b0};
	dc1 <= load ? (FLIP_D[5] ? ~dincuse[15:8] : dincuse[15:8]) : {dc1[6:0],1'b0};
	dd0 <= load ? (FLIP_D[6] ? ~dinduse[ 7:0] : dinduse[7:0]) : {dd0[6:0],1'b0};
	dd1 <= load ? (FLIP_D[7] ? ~dinduse[15:8] : dinduse[15:8]) : {dd1[6:0],1'b0};
end
wire fco=clk_d[3];
assign DCOP=FLIP_DCO ? ~clk4x : clk4x;
assign DCON=FLIP_DCO ? clk4x :~clk4x;
assign FCOP=fco;
assign FCON=~fco;
assign D0PA= FLIP_D[0]?~da0[7]:da0[7];
assign D0NA=~FLIP_D[0]?~da0[7]:da0[7];
assign D1PA= FLIP_D[1]?~da1[7]:da1[7];
assign D1NA=~FLIP_D[1]?~da1[7]:da1[7];
assign D0PB= FLIP_D[2]?~db0[7]:db0[7];
assign D0NB=~FLIP_D[2]?~db0[7]:db0[7];
assign D1PB= FLIP_D[3]?~db1[7]:db1[7];
assign D1NB=~FLIP_D[3]?~db1[7]:db1[7];
assign D0PC= FLIP_D[4]?~dc0[7]:dc0[7];
assign D0NC=~FLIP_D[4]?~dc0[7]:dc0[7];
assign D1PC= FLIP_D[5]?~dc1[7]:dc1[7];
assign D1NC=~FLIP_D[5]?~dc1[7]:dc1[7];
assign D0PD= FLIP_D[6]?~dd0[7]:dd0[7];
assign D0ND=~FLIP_D[6]?~dd0[7]:dd0[7];
assign D1PD= FLIP_D[7]?~dd1[7]:dd1[7];
assign D1ND=~FLIP_D[7]?~dd1[7]:dd1[7];
//assign D0PA= da0[7];
//assign D0NA=~da0[7];
//assign D1PA= da1[7];
//assign D1NA=~da1[7];
//assign D0PB= db0[7];
//assign D0NB=~db0[7];
//assign D1PB= db1[7];
//assign D1NB=~db1[7];
//assign D0PC= dc0[7];
//assign D0NC=~dc0[7];
//assign D1PC= dc1[7];
//assign D1NC=~dc1[7];
//assign D0PD= dd0[7];
//assign D0ND=~dd0[7];
//assign D1PD= dd1[7];
//assign D1ND=~dd1[7];
endmodule
