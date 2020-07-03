// from 88E111 datasheet
`timescale 1ns / 1ns
module mdio_model #(
    parameter [4:0] ADDR=5'h10
) (
    input reset_b,
    input mdc,
    inout mdio
);

localparam [31:0] PRE = ~0;         // preamble
localparam [1:0] ST   = 2'b01;      // start of frame
localparam [1:0] OP_R = 2'b10;      // op: read
localparam [1:0] OP_W = 2'b01;      // op: write

localparam [2:0] idle = 0,
    start = 1,
    op = 2,
    write = 3,
    read = 4,
    preamble = 5;

reg mdio_wen = 0;
reg mdio_o_reg = 0;
assign mdio = mdio_wen ? mdio_o_reg : 1'bz;

reg [2:0] state_reg = idle;

reg [31:0] shift = 0;
wire ready = &shift;
wire [1:0] ops = shift[1:0];
reg [6:0] cnt = 0;
reg [4:0] phy_addr = 0;
reg [4:0] reg_addr = 0;
reg [15:0] reg_val = 0;
reg [15:0] reg_read = 0;
reg [15:0] mem [4:0];
always @(posedge mdc) begin
    shift <= {shift[30:0], mdio};
    case(state_reg)
        idle : begin
            // minimum 1 cycle of idle required
                state_reg <= preamble;
        end
        preamble: begin
            cnt <= cnt + 1'b1;
            if (ready && cnt==31) begin
                state_reg <= start;
                cnt <= 0;
            end
        end
        start : begin
            cnt <= ready ? 0 : cnt + 1'b1;
            if (cnt == 1) begin
                state_reg <= (ops == ST) ? op : idle;
            end
        end
        op : begin
            cnt <= cnt + 1'b1;
            if (cnt == 3) begin
                case(ops)
                    OP_R: state_reg <= read;
                    OP_W: state_reg <= write;
                    default: begin
                        state_reg <= idle;
                        cnt <= 0;
                    end
                endcase
            end
        end
        write : begin
            cnt <= cnt + 1'b1;
            if (cnt == 8) phy_addr <= shift[4:0];
            else if (cnt == 13) reg_addr <= shift[4:0];
            else if (cnt == 15 + 16) begin
                if (ADDR == phy_addr) reg_val = shift[15:0];
                state_reg <= idle;
                cnt <= 0;
                shift <=0;
                $display(
                    "write: phy_addr: 0x%x, reg_addr: 0x%x, reg_val: 0x%x",
                    phy_addr, reg_addr, reg_val);
                mem[reg_addr] <= shift[15:0];
            end
        end
        read : begin
            cnt <= cnt + 1'b1;
            if (cnt == 8) phy_addr <= shift[4:0];
            else if (cnt == 13) begin
                reg_addr <= shift[4:0];
                mdio_wen <= 1'b1;
                mdio_o_reg <= 1'b0;
            end else if (cnt == 14 && ADDR == phy_addr) begin
                reg_read = mem[reg_addr];
                #1000 mdio_o_reg <= reg_read[15];
                reg_read <= {reg_read[14:0], 1'b0};
                $display(
                    "read: phy_addr: 0x%x, reg_addr: 0x%x, reg_read: 0x%x",
                    phy_addr, reg_addr, mem[reg_addr]);
            end else if (cnt >= 15 && ADDR == phy_addr) begin
                #1000 mdio_o_reg <= reg_read[15];
                reg_read <= {reg_read[14:0], 1'b0};
            end else if (cnt == 14 + 16) begin
                mdio_wen <= 1'b0;
                state_reg <= idle;
                cnt <= 0;
                shift <=0;
            end
        end
        default : begin
            state_reg <= idle;
            cnt <= 0;
        end
    endcase
end

endmodule
