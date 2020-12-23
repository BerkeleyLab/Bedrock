// TODO I don't like the fact that this code cannot
// be understood anymore without simulation

module spi_engine (
    input               clk,
    input               reset,
    input               wdata_val,
    input [31:0]        wdata,
    output              busy,

    output reg [31:0]   rdata,
    output              rdata_val,
    input [7:0]         cfg_sckhalfperiod,
    input [7:0]         cfg_scklen,
    input               cfg_cpol,
    input               cfg_cpha,
    input               cfg_lsb,

    (* mark_debug = "true" *) output reg cs,
    (* mark_debug = "true" *) output sck,
    (* mark_debug = "true" *) output copi,
    (* mark_debug = "true" *) input cipo
);

initial begin
    rdata = 0;
end

wire start = wdata_val;
reg start1 = 0;
wire trigger = start & ~start1;
reg [31:0] wdata_r = 0;
always @(posedge clk) begin
    start1 <= start;
end

localparam [2:0]
    IDLE = 3'd0,
    LOAD = 3'd1,
    SHIFT = 3'd2,
    DONE = 3'd3;

reg [4:0] cstate=0;
reg sck_en=0,
    done=0;

reg [15:0] clk_cnt = 0;
reg [7:0] sck_cnt = 0; // max 255 bits

reg [8:0] cfg_sckfullperiod_reg=4;
reg cfg_cpol_reg = 0;
reg cfg_cpha_reg = 1;
reg cfg_lsb_reg  = 0;
reg [7:0] cfg_scklen_reg = 8'd32;

wire sck_wtf = clk_cnt > cfg_sckfullperiod_reg[8:1];
reg sck1 = 0;
wire sck_rise = sck_wtf & ~sck1;
wire sck_fall = ~sck_wtf & sck1;
// data change at the opposite edge of sampling edge
wire sck_edge_copi = cfg_cpha_reg ? sck_rise : sck_fall; // Driving edge
wire sck_edge_cipo = cfg_cpha_reg ? sck_fall : sck_rise; // Sampling edge

initial cs = 1'b1;
reg [32:0] copi_sr = 0;
reg [31:0] rdata_sr = 0;

always @(posedge clk) begin
    sck1 <= sck_wtf;
    if (trigger) begin
        wdata_r <= wdata;
        cfg_sckfullperiod_reg <= cfg_sckhalfperiod << 1;
        cfg_cpol_reg <= cfg_cpol;
        cfg_cpha_reg <= cfg_cpha;
        cfg_lsb_reg  <= cfg_lsb;
        cfg_scklen_reg <= cfg_cpha ? cfg_scklen : cfg_scklen-1;
    end
    if (reset) cstate[IDLE] <= 1;
    cstate <= 0;
    case (1'b1)
        cstate[IDLE] : begin
            sck_en <= 1'b0;
            cs   <= 1'b1;
            done <= 1'b0;
            if (trigger) cstate[LOAD] <= 1;
            else cstate[IDLE] <= 1;
            sck_cnt <= 0;
            copi_sr <= 0;
            rdata_sr <= 0;
        end

        cstate[LOAD] : begin
            sck_en <= 1'b1;
            cs <= 1'b0;
            done <= 1'b0;
            cstate[SHIFT] <= 1;
            sck_cnt <= 0;
            // copi_sr <= cfg_cpha_reg ? {1'b0, wdata_r} : {wdata_r, 1'b0};
            // copi_sr <= wdata_r;
            // dirty trick ...
            copi_sr <= (cfg_lsb_reg && cfg_cpha_reg) ? {wdata_r, 1'b0} : {1'b0, wdata_r};
        end

        cstate[SHIFT] : begin
            cs <= 1'b0;
            done <= 1'b0;
            if (sck_edge_copi) begin
                sck_en <= (sck_cnt == cfg_scklen_reg) ? 0 : 1'b1;
                sck_cnt <= sck_cnt + 1'b1;
                if (cfg_lsb_reg)
                    copi_sr <= {1'b0, copi_sr[32:1]};
                else
                    copi_sr <= {copi_sr[31:0], 1'b0};
            end
            if (sck_edge_cipo) begin
                if (cfg_lsb_reg)
                    rdata_sr <= {cipo, rdata_sr[31:1]};
                else
                    rdata_sr <= {rdata_sr[30:0], cipo};
            end
            if (sck_edge_copi && sck_cnt == cfg_scklen_reg) cstate[DONE] <= 1;
            else cstate[SHIFT] <= 1;
        end

        cstate[DONE] : begin
            sck_en <= 1'b0;
            cs <= 1'b1;
            done <= 1'b1;
            cstate[IDLE] <= 1;
            sck_cnt <= 0;
            rdata <= rdata_sr;
        end

        default : begin
            {sck_en,done,cs} <= 3'b001;
            cstate[IDLE] <= 1;
            sck_cnt <= 0;
            copi_sr <= 0;
        end
    endcase
    clk_cnt <= cstate[IDLE] ? 1 : (clk_cnt == cfg_sckfullperiod_reg) ? 1 : clk_cnt + 1;
end

wire sck_out = sck_en & sck1;
// assign sck = cfg_cpol_reg ? ~sck_out: sck_out;
assign sck = cfg_cpol ? ~sck_out: sck_out;
assign copi = cfg_lsb_reg ? copi_sr[0] : copi_sr[cfg_scklen_reg];
assign busy = ~cstate[IDLE] | done;
assign rdata_val = done;

endmodule
